# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

GoblinHack: a 2D smooth-scrolling ASCII roguelike in C++ (~72k LOC) on SDL 1.2 + OpenGL. No longer actively developed upstream; the goal is to keep it compiling on current Ubuntu/Linux. Version lives in `build/etc/VERSION`. There is no test suite or linter (`src/test/` only holds a fractal demo program).

## Build and run

Autoconf + recursive hand-written makefiles, driven by `./RUNME`:

- `./RUNME` — full build: regenerates `src/include/gh_version.h` from `build/etc/VERSION`, runs `autoconf`/`configure` in `build/`, then `make clean`, `make depend`, `make all`, builds the installer tarball, symlinks `./ghack -> src/ghack`, and regenerates `README` from `src/resources/txt/help.txt`. Note it does `make clean` first, so it is a full rebuild every time.
- `./RUNME -n` — configure only, no make.
- After configure, incremental builds: `make` at top level (or `cd src/<module> && make`). Binary is `src/ghack`.
- `make depend` uses `makedepend` (`build/sh/makedep.sh`); `make clean` also deletes `src/resources/game.gz`, saved games and hiscores; `make clobber` removes generated config.
- Deps: g++, autoconf, makedepend, libsdl1.2-dev, libsdl-mixer1.2-dev, libsdl-image1.2-dev, libsdl-net1.2-dev.
- Run `./ghack` from the repo root (it reads `src/resources/...` relative to the working dir). It redirects stdout/stderr to `stdout.txt`/`stderr.txt`; check those for crashes (`bin/traceback` helps decode backtraces). Flags: `-f/--fullscreen`, `-w/--window`, `-h`.

Generated/untracked files (`Makefile`, `build/mk/{config,library,program,rules}`, `*.o`, `configure`, `README`, `ghack`) are build artifacts; the tracked sources are the `*.in` templates. Edit `Makefile.in`, not `Makefile`.

## Architecture

All C++ sources are in `src/<module>/`, with every header in the flat `src/include/` directory (`gh_*.h`, included as `<gh_thing.h>`). Modules: `main` (entry, global config, updater), `game`, `levels`, `map` (procedural generators: cave, maze, forest, hell, fractal, shop, void, landscape...), `rooms` (room parsing), `things`, `player`, `ui` (menus/choosers), `sdl` (video, audio, input, GL), `term` (console/figlet text rendering), `io` (zip/gz, dir, parse), `math`, `misc`, `debug`, `web`/`net`.

Key points that span files:

- **Per-directory object lists are manual.** Each module's `Makefile.in` lists its objects in `OBJS = ...`, and `src/Makefile.in` lists every `.o` again in `OBJS_SUBDIRS` and the `SUBDIRS` order. Adding a `.cpp` means updating both, then re-running `./RUNME -n` (or at least regenerating the Makefile) and `make depend`.
- **`gh_thing` is the central entity** (`src/include/gh_thing.h`, ~2000 lines; implementation split across the many files in `src/things/`, each one a facet: attack, hit, bravery, the various `*_proof.cpp`, followers, etc.). Players, monsters, items, doors and walls are all things.
- **Data-driven content.** Things, rooms and levels are defined as text files under `src/resources/things/<category>/...`, `src/resources/rooms`, `src/resources/levels`, parsed by `gh_parse`/`gh_stream` (`src/io/io.cpp`, `gh_stream.h`) and loaded zipped/gz'd. Adding a monster is mostly a new resource directory, not code. Serialization of game state also goes through `gh_stream` (`gh_write_file(game, "", "game.gz")`, `src/game/save.cpp`/`load.cpp`).
- **Startup flow** (`src/main/main.cpp`): installer check/update, redirect stdio, parse args, load config (`gh_global`), then loop through UI choosers (`src/ui/`) into the game loop (`src/game/loop.cpp`, `src/player/loop.cpp`). On quit the game state is written to `game.gz`.
- Instrumentation macros `GH_FUNCTION()`, `GH_LOG()`, `GH_THROW()` and custom allocation tracking (`src/debug/dmalloc.cpp`) are used throughout; follow that style in new code.
- Windows support is retained (`src/*.dll`, `installer/*.nsi`, `contrib/mingw`).

## Notes

- `CODE_REVIEW.md` (untracked) lists known bugs and UB, e.g. a double free of `game` in `main.cpp`'s loop, `reserve` vs `resize` in `gh_parse::alloc`, `new[]`/`delete` mismatch in `io.cpp`, throws in `gh_thing::~gh_thing`, and an infinite loop in `string_replace`. Check it before touching those areas.
- Code style: 4-space indentation mixed with tabs, `gh_` prefix on types and headers, old C++98-era idioms.
