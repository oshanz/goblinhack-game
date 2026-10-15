#!/bin/bash
#
# Build a macOS release tarball and publish it as a GitHub release asset.
#
# usage: build/sh/release-macos.sh [options]
#
#   --no-upload      build and package only; do not tag or touch GitHub
#   --draft          create the GitHub release as a draft (if it must be created)
#   --repo OWNER/NAME  GitHub repository (default: taken from the origin remote)
#
# Needs the build dependencies from CLAUDE.md (brew install autoconf automake
# makedepend sdl2 sdl2_image sdl2_mixer) and, to upload, an authenticated gh.
#
# The Homebrew dylibs the binary links against are copied next to it in
# lib/ and their install names rewritten to @loader_path, so the package runs
# on a Mac without Homebrew. The result is ad-hoc signed (required on Apple
# silicon) but not notarized: users must clear the quarantine flag, for example
# with: xattr -dr com.apple.quarantine goblinhack-<version>-macos-<arch>
# The package is only as portable as the machine that built it: it runs on the
# macOS version of the build machine and newer.
#
# The version comes from build/etc/VERSION and the release tag is v<version>.
# If that tag already exists the release is built from the tag, otherwise from
# HEAD, which is then tagged. If the GitHub release already exists the macOS
# assets are added to it (replacing old ones); otherwise it is created with the
# matching CHANGELOG.md section as the notes.
#
set -euo pipefail

UPLOAD=1
DRAFT=0
REPO=

while [ $# -gt 0 ]; do
    case "$1" in
    --no-upload) UPLOAD=0 ;;
    --draft)     DRAFT=1 ;;
    --repo)      REPO=${2:?--repo needs a value}; shift ;;
    -h|--help)   sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *)           echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

[ "$(uname -s)" = Darwin ] || die "this script must run on macOS"

TOP=$(cd "$(dirname "$0")/../.." && pwd)
cd "$TOP"

VERSION=$(tr -d '[:space:]' < build/etc/VERSION)
[ -n "$VERSION" ] || die "build/etc/VERSION is empty"
TAG=v$VERSION
ARCH=$(uname -m)
NAME=goblinhack-$VERSION-macos-$ARCH
DIST=$TOP/dist
TARBALL=$DIST/$NAME.tar.gz

for tool in autoconf makedepend otool install_name_tool codesign shasum; do
    command -v $tool >/dev/null || die "$tool not found; see the dependencies in CLAUDE.md"
done

# Build from the release tag if it exists, so a rebuild always ships exactly
# the tagged code. Otherwise build HEAD and tag it once the build succeeds.
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    REF=$TAG
else
    REF=HEAD
fi

# git tracks the version header, so make sure it matches VERSION before building
HEADER_VERSION=$(git show "$REF:src/include/gh_version.h" |
    sed -n 's/^#define GH_VERSION "\(.*\)"/\1/p')
[ "$HEADER_VERSION" = "$VERSION" ] ||
    die "src/include/gh_version.h at $REF says $HEADER_VERSION but VERSION says $VERSION; run ./RUNME -n"

if [ $UPLOAD -eq 1 ]; then
    command -v gh >/dev/null || die "gh is not installed"
    gh auth status >/dev/null 2>&1 || die "gh is not logged in; run: gh auth login"
    [ -z "$(git status --porcelain)" ] || die "working tree is not clean; commit or stash first"
    if [ -z "$REPO" ]; then
        REPO=$(git remote get-url origin | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')
    fi
    git fetch -q origin
    [ -n "$(git branch -r --contains "$REF")" ] || die "$REF is not pushed; run: git push"
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Always build from the committed tree, not from whatever is lying around
log "Exporting $REF ($(git rev-parse --short "$REF^{commit}"))"
mkdir "$WORK/src"
git archive "$REF" | tar -x -C "$WORK/src"

log "Building"
(
    cd "$WORK/src"
    ./RUNME -n
    make depend 2>/dev/null || true
    make all
)
BIN=$WORK/src/src/ghack
[ -x "$BIN" ] || die "build did not produce a ghack binary"

log "Packaging $NAME"
PKG=$WORK/pkg/$NAME
mkdir -p "$PKG/lib"
git archive "$REF" src/resources | tar -x -C "$PKG"
find "$PKG" -name 'Makefile*' -delete
cp "$BIN" "$PKG/ghack"
strip -x "$PKG/ghack"
cp "$WORK/src/LICENSE" "$WORK/src/README.md" "$WORK/src/CHANGELOG.md" "$PKG/"

# Third-party (non-system) libraries a Mach-O file links against
third_party_deps() {
    otool -L "$1" | tail -n +2 | awk '{print $1}' |
        grep -v -e '^/usr/lib/' -e '^/System/' -e '^@loader_path' -e '^@executable_path' || true
}

# Absolute path of a dependency named by third_party_deps; @rpath names are
# looked up beside the library that references them, then in Homebrew
resolve() {
    local dep=$1 from=$2 dir
    case "$dep" in
    @rpath/*)
        for dir in "$(dirname "$from")" /opt/homebrew/lib /usr/local/lib; do
            [ -e "$dir/${dep#@rpath/}" ] && { echo "$dir/${dep#@rpath/}"; return; }
        done
        die "cannot find $dep needed by $from" ;;
    *) echo "$dep" ;;
    esac
}

# Copy a dylib into lib/ (once), then recurse into its own dependencies
bundle() {
    local src=$1 base
    base=$(basename "$src")
    [ -e "$PKG/lib/$base" ] && return 0
    cp "$src" "$PKG/lib/$base"
    chmod u+w "$PKG/lib/$base"
    install_name_tool -id "@loader_path/$base" "$PKG/lib/$base"
    local dep
    for dep in $(third_party_deps "$src"); do
        bundle "$(resolve "$dep" "$src")"
        install_name_tool -change "$dep" "@loader_path/$(basename "$dep")" "$PKG/lib/$base"
    done
}

for dep in $(third_party_deps "$PKG/ghack"); do
    bundle "$(resolve "$dep" "$BIN")"
    install_name_tool -change "$dep" "@executable_path/lib/$(basename "$dep")" "$PKG/ghack"
done

# Homebrew's sdl2 may be sdl2-compat, which loads SDL3 with dlopen at runtime
# and so does not show up in otool. Ship SDL3 beside it if that is the case.
if grep -aq 'libSDL3' "$PKG"/lib/libSDL2-*.dylib 2>/dev/null; then
    SDL3=$(brew --prefix sdl3 2>/dev/null || true)
    [ -n "$SDL3" ] && [ -d "$SDL3/lib" ] ||
        die "the SDL2 in use is sdl2-compat but sdl3 was not found; run: brew install sdl3"
    log "Bundling SDL3 for sdl2-compat"
    bundle "$(cd "$SDL3/lib" && pwd -P)/libSDL3.0.dylib"
    # sdl2-compat looks for this exact name beside itself
    ln -s libSDL3.0.dylib "$PKG/lib/libSDL3.dylib"
fi

# Anything still pointing outside the package would break on other machines
LEAKS=$(for f in "$PKG/ghack" $(find "$PKG/lib" -type f -name '*.dylib'); do
    third_party_deps "$f" | sed "s#^#$(basename "$f"): #"
done)
[ -z "$LEAKS" ] || { echo "$LEAKS" >&2; die "the package still links to libraries outside itself"; }

# Rewriting install names invalidates signatures; arm64 refuses unsigned code
for f in $(find "$PKG/lib" -type f -name '*.dylib') "$PKG/ghack"; do
    codesign --force --sign - "$f" 2>/dev/null
done

# The game reads src/resources relative to the working directory, so give
# users something to double click that runs it from the right place
cat > "$PKG/GoblinHack.command" <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
xattr -dr com.apple.quarantine . 2>/dev/null
exec ./ghack "$@"
EOF
chmod +x "$PKG/GoblinHack.command"

mkdir -p "$DIST"
tar -C "$WORK/pkg" -czf "$TARBALL" "$NAME"
(cd "$DIST" && shasum -a 256 "$NAME.tar.gz" > "$NAME.tar.gz.sha256")

# Check that the extracted package starts, with Homebrew's libraries hidden
# from it by running it in a minimal environment
log "Checking the package"
CHECK=$WORK/check
mkdir "$CHECK"
tar -C "$CHECK" -xzf "$TARBALL"
(
    cd "$CHECK/$NAME"
    env -i HOME="$HOME" PATH=/usr/bin:/bin ./ghack -w >/dev/null 2>&1 &
    pid=$!
    sleep 10
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
)
grep -q 'Starting game loop' "$CHECK/$NAME/stdout.txt" 2>/dev/null ||
    die "smoke test failed; see $CHECK/$NAME/stdout.txt and stderr.txt"
echo "smoke test passed"

log "Built $TARBALL ($(du -h "$TARBALL" | cut -f1))"

if [ $UPLOAD -eq 0 ]; then
    exit 0
fi

if [ "$REF" = HEAD ]; then
    log "Tagging $TAG"
    git tag -a "$TAG" -m "GoblinHack $VERSION"
fi
git push -q origin "refs/tags/$TAG"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    log "Release $TAG exists; replacing its macOS $ARCH assets"
    gh release upload "$TAG" --repo "$REPO" --clobber \
        "$TARBALL" "$TARBALL.sha256"
else
    # Release notes are the "## <version>" section of the changelog
    NOTES=$WORK/notes.md
    awk -v v="$VERSION" '
        /^## / { if (on) exit; if ($2 == v) { on = 1; next } }
        on
    ' "$WORK/src/CHANGELOG.md" > "$NOTES"
    [ -s "$NOTES" ] || die "CHANGELOG.md has no '## $VERSION' section"
    printf '\nSee [CHANGELOG.md](CHANGELOG.md) for the full history.\n' >> "$NOTES"

    log "Creating release $TAG"
    ARGS=()
    [ $DRAFT -eq 1 ] && ARGS+=(--draft)
    gh release create "$TAG" --repo "$REPO" --verify-tag \
        --title "GoblinHack $VERSION" --notes-file "$NOTES" ${ARGS[@]+"${ARGS[@]}"} \
        "$TARBALL" "$TARBALL.sha256"
fi

log "Done: https://github.com/$REPO/releases/tag/$TAG"
