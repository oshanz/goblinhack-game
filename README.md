<pre>
  ____       _     _ _         _   _            _    
 / ___| ___ | |__ | (_)_ __   | | | | __ _  ___| | __
| |  _ / _ \| '_ \| | | '_ \  | |_| |/ _` |/ __| |/ /
| |_| | (_) | |_) | | | | | | |  _  | (_| | (__|   + 
 \____|\___/|_.__/|_|_|_| |_| |_| |_|\__,_|\___|_|\_\

</pre>

A 2d smooth scrolling ascii dungeon romp 

This game is no longer actively developed, but I try to keep it compiling.

## Running the macOS release

The macOS release is ad-hoc signed but not notarized, so Gatekeeper reports "Apple could not verify "ghack" is free of malware" on first launch. Clear the quarantine flag on the extracted folder, then run the game:

    tar xzf goblinhack-2.0-macos-arm64.tar.gz
    xattr -dr com.apple.quarantine goblinhack-2.0-macos-arm64
    cd goblinhack-2.0-macos-arm64 && ./ghack

Alternatives:

- If it is already blocked, open System Settings > Privacy & Security and click "Open Anyway" next to the ghack message. The bundled `lib/*.dylib` files may need the same, so the `xattr` command is simpler.
- Double clicking `GoblinHack.command` clears the flag on the rest of the folder, but the first launch needs right click > Open because the `.command` file is quarantined too.
- Downloading with `curl` or `gh release download` does not set the quarantine flag.

## Building

Needs a C++ compiler, `autoconf`, `makedepend`, SDL2, SDL2_image, SDL2_mixer and OpenGL. Tested on macOS (Apple Silicon) and openSUSE Tumbleweed; Ubuntu and Windows are untested with SDL2.

    # macOS
    brew install autoconf automake makedepend sdl2 sdl2_image sdl2_mixer
    # Ubuntu / Debian
    sudo apt-get install make autoconf automake g++ xutils-dev \
        libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libgl1-mesa-dev libglu1-mesa-dev

    ./RUNME
    ./ghack

On macOS, if the compiler cannot find `<string>`, run `xcode-select --install`.

You might also enjoy my other game (actively developed and work in progress)
[Zorbash](https://github.com/goblinhack/zorbash)

![Alt text](screenshot.1.png?raw=true "")
![Alt text](screenshot.2.png?raw=true "")
![Alt text](screenshot.3.png?raw=true "")
![Alt text](screenshot.4.png?raw=true "")
![Alt text](screenshot.5.png?raw=true "")
