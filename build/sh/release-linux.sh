#!/bin/bash
#
# Build a Linux release tarball and publish it as a GitHub release.
#
# usage: build/sh/release-linux.sh [options]
#
#   --local          build with the host toolchain instead of a container
#   --image IMAGE    container image used for the build (default: ubuntu:22.04)
#   --no-upload      build and package only; do not tag or touch GitHub
#   --draft          create the GitHub release as a draft
#   --repo OWNER/NAME  GitHub repository (default: taken from the origin remote)
#
# By default the build runs in an old Ubuntu container so the binary links
# against an old glibc and runs on current distributions. A build with
# --local links against whatever glibc the host has, which may be too new
# for other machines.
#
# The version comes from build/etc/VERSION and the release tag is v<version>.
# The release notes are the matching section of CHANGELOG.md.
#
set -euo pipefail

IMAGE=ubuntu:22.04
LOCAL=0
UPLOAD=1
DRAFT=0
REPO=

while [ $# -gt 0 ]; do
    case "$1" in
    --local)     LOCAL=1 ;;
    --image)     IMAGE=${2:?--image needs a value}; shift ;;
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

TOP=$(cd "$(dirname "$0")/../.." && pwd)
cd "$TOP"

VERSION=$(tr -d '[:space:]' < build/etc/VERSION)
[ -n "$VERSION" ] || die "build/etc/VERSION is empty"
TAG=v$VERSION
ARCH=$(uname -m)
NAME=goblinhack-$VERSION-linux-$ARCH
DIST=$TOP/dist
TARBALL=$DIST/$NAME.tar.gz

# git tracks the version header, so make sure it matches VERSION before building
HEADER_VERSION=$(sed -n 's/^#define GH_VERSION "\(.*\)"/\1/p' src/include/gh_version.h)
[ "$HEADER_VERSION" = "$VERSION" ] ||
    die "src/include/gh_version.h says $HEADER_VERSION but VERSION says $VERSION; run ./RUNME -n"

if [ $UPLOAD -eq 1 ]; then
    command -v gh >/dev/null || die "gh is not installed"
    gh auth status >/dev/null 2>&1 || die "gh is not logged in; run: gh auth login"
    [ -z "$(git status --porcelain)" ] || die "working tree is not clean; commit or stash first"
    if [ -z "$REPO" ]; then
        REPO=$(git remote get-url origin | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')
    fi
    git fetch -q origin
    [ -n "$(git branch -r --contains HEAD)" ] || die "HEAD is not pushed; run: git push"
    if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
        [ "$(git rev-parse "$TAG^{commit}")" = "$(git rev-parse HEAD)" ] ||
            die "tag $TAG already exists on a different commit than HEAD"
    fi
fi

WORK=$(mktemp -d)
cleanup() {
    # container builds leave root-owned files behind if they were interrupted
    rm -rf "$WORK" 2>/dev/null || true
}
trap cleanup EXIT

# Always build from the committed tree, not from whatever is lying around
log "Exporting HEAD ($(git rev-parse --short HEAD))"
mkdir "$WORK/src" "$WORK/out"
git archive HEAD | tar -x -C "$WORK/src"

if [ $LOCAL -eq 1 ]; then
    log "Building on the host"
    (
        cd "$WORK/src"
        ./RUNME -n
        make depend 2>/dev/null || true
        make all
    )
    cp "$WORK/src/src/ghack" "$WORK/out/ghack"
else
    command -v docker >/dev/null || die "docker is not installed; use --local"
    log "Building in $IMAGE"
    docker run --rm \
        -v "$WORK/src:/build" -v "$WORK/out:/out" -w /build \
        -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
        "$IMAGE" bash -euo pipefail -c '
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq --no-install-recommends \
                g++ make autoconf automake xutils-dev pkg-config ca-certificates \
                libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev \
                libgl1-mesa-dev libglu1-mesa-dev zlib1g-dev >/dev/null
            ./RUNME -n
            make depend 2>/dev/null || true
            make all
            cp src/ghack /out/ghack
            chown -R "$HOST_UID:$HOST_GID" /build /out
        '
fi

[ -x "$WORK/out/ghack" ] || die "build did not produce a ghack binary"
strip "$WORK/out/ghack"

log "Packaging $NAME"
PKG=$WORK/pkg/$NAME
mkdir -p "$PKG"
git archive HEAD src/resources | tar -x -C "$PKG"
find "$PKG" -name 'Makefile*' -delete
cp "$WORK/out/ghack" "$PKG/ghack"
cp LICENSE README.md CHANGELOG.md "$PKG/"

mkdir -p "$DIST"
tar -C "$WORK/pkg" -czf "$TARBALL" "$NAME"
(cd "$DIST" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256")

# Check the shipped binary links, and that it starts if there is a display
log "Checking the package"
CHECK=$WORK/check
mkdir "$CHECK"
tar -C "$CHECK" -xzf "$TARBALL"
if ldd "$CHECK/$NAME/ghack" | grep -q 'not found'; then
    ldd "$CHECK/$NAME/ghack" | grep 'not found' >&2
    die "the binary has unresolved libraries on this machine"
fi
echo "glibc needed: $(objdump -T "$CHECK/$NAME/ghack" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)"
if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    (cd "$CHECK/$NAME" && timeout 10 ./ghack -w >/dev/null 2>&1 || true)
    grep -q 'Starting game loop' "$CHECK/$NAME/stdout.txt" ||
        die "smoke test failed; see $CHECK/$NAME/stdout.txt and stderr.txt"
    echo "smoke test passed"
else
    echo "no display, skipping the smoke test"
fi

log "Built $TARBALL ($(du -h "$TARBALL" | cut -f1))"

if [ $UPLOAD -eq 0 ]; then
    exit 0
fi

# Release notes are the "## <version>" section of the changelog
NOTES=$WORK/notes.md
awk -v v="$VERSION" '
    /^## / { if (on) exit; if ($2 == v) { on = 1; next } }
    on
' CHANGELOG.md > "$NOTES"
[ -s "$NOTES" ] || die "CHANGELOG.md has no '## $VERSION' section"
printf '\nSee [CHANGELOG.md](CHANGELOG.md) for the full history.\n' >> "$NOTES"

if ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    log "Tagging $TAG"
    git tag -a "$TAG" -m "GoblinHack $VERSION"
fi
git push -q origin "refs/tags/$TAG"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    log "Release $TAG exists; replacing its Linux assets"
    gh release upload "$TAG" --repo "$REPO" --clobber \
        "$TARBALL" "$TARBALL.sha256"
else
    log "Creating release $TAG"
    ARGS=()
    [ $DRAFT -eq 1 ] && ARGS+=(--draft)
    gh release create "$TAG" --repo "$REPO" --verify-tag \
        --title "GoblinHack $VERSION" --notes-file "$NOTES" ${ARGS[@]+"${ARGS[@]}"} \
        "$TARBALL" "$TARBALL.sha256"
fi

log "Done: https://github.com/$REPO/releases/tag/$TAG"
