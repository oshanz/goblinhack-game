<pre>
  ____       _     _ _         _   _            _    
 / ___| ___ | |__ | (_)_ __   | | | | __ _  ___| | __
| |  _ / _ \| '_ \| | | '_ \  | |_| |/ _` |/ __| |/ /
| |_| | (_) | |_) | | | | | | |  _  | (_| | (__|   + 
 \____|\___/|_.__/|_|_|_| |_| |_| |_|\__,_|\___|_|\_\

</pre>

A 2d smooth scrolling ascii dungeon romp 

This game is no longer actively developed, but I try to keep it compiling.

## Supported platforms

The game uses SDL2 (SDL2, SDL2_image and SDL2_mixer) and OpenGL. SDL 1.2 is no longer supported.

| OS | Status |
| --- | --- |
| macOS (Apple Silicon) | Builds and runs. Tested with the Homebrew SDL2 packages. |
| openSUSE Tumbleweed | Builds and runs with SDL2. |
| Ubuntu / other Linux | Last known to compile with SDL 1.2 on Ubuntu 21.04. The SDL2 port has not been tested on Ubuntu yet. |
| Windows | Installer and MinGW files are still in the tree, but have not been updated or tested for SDL2. |

## Building

You need a C++ compiler, `autoconf`, `makedepend` and the SDL2 libraries.

macOS:

    brew install autoconf automake makedepend sdl2 sdl2_image sdl2_mixer

Ubuntu / Debian:

    sudo apt-get install make autoconf automake g++ xutils-dev \
        libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libgl1-mesa-dev libglu1-mesa-dev

Then build and run from the top of the tree:

    ./RUNME
    ./ghack

If the compiler cannot find `<string>` on macOS, your Command Line Tools install is missing its libc++ headers. Reinstall it with `xcode-select --install`, or point the compiler at the SDK copy:

    export CPLUS_INCLUDE_PATH=$(xcrun --show-sdk-path)/usr/include/c++/v1

You might also enjoy my other game (actively developed and work in progress)
[Zorbash](https://github.com/goblinhack/zorbash)

![Alt text](screenshot.1.png?raw=true "")
![Alt text](screenshot.2.png?raw=true "")
![Alt text](screenshot.3.png?raw=true "")
![Alt text](screenshot.4.png?raw=true "")
![Alt text](screenshot.5.png?raw=true "")
