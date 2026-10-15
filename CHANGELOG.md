# Changelog

Notable changes to GoblinHack, newest first. Version is tracked in `build/etc/VERSION` (currently 2.0).

## 2.0 (2026-10-15)

Major release: the game now builds against SDL2 and SDL 1.2 is no longer supported.

### Changed
- Ported video, input and build config from SDL 1.2 to SDL2 (SDL 1.2 is no longer supported).
- Handle `SDL_QUIT` and actually install the SDL event filter.
- Disabled the auto-updater.
- `GH_WARN`, `GH_THROW` and `GH_ERR` are now wrapped in `do { } while (0)`.
- Simplified `erase_dups`.
- Updated README with supported platforms and build instructions, then trimmed it.
- Added `CLAUDE.md` with build and architecture notes, and updated it for SDL2.
- Added a `.gitignore` for build output, generated files and runtime artifacts.

### Fixed
- Stopped SDL2 text input so an IME on Linux no longer swallows key events.
- Use-after-free and double delete of `game` on config change.
- `gh_parse` node vector is sized with `resize()` instead of `reserve()`.
- gz read buffer is freed with `delete[]` to match `new[]`.
- `string_replace` no longer loops forever when the replacement contains the pattern.
- Save/load pointer translation table uses `uintptr_t`.
- `~gh_thing` logs instead of throwing when `prev`/`limb_prev` are still set.
- `gh_audio` now frees its SDL_mixer chunk on destruction.
- SIGINT handler is now signal-safe.
- `GH_FUNCTION` trace arrays are bounded and the backtrace indent is clamped.

## Previous versions (original game, 2006-2009)

The release notes below come from the version history bundled in the game's own help text (`src/resources/txt/help.txt`). The upstream repository (goblinhack/goblinhack-game) has no tags or releases. The help text has no notes for 1.12, 1.14, 1.16-1.18 or 1.20. Releases from late 2008 onwards are dated but not numbered there. The help screen's "what's new" section is headed 1.19, and `build/etc/VERSION` read 1.20 before this release.

### 1.19 (what's new in the help screen)
- Added: percentage-based fire/cold proofing, fractal landscapes, 2.5D walls on some levels, deep and dwarve lords, a tutorial level, insulting monsters, suffocation attacks, a base-health power-up, the cursed spell of zippiness, auto rage at 1/3 HP, and monsters and players slowing down when badly injured.
- Changed: fate points recover only half your health, less with each use; trolls have fewer fate points; return exits take longer to appear; the screen shake on self-teleport is lessened; summon monster considers monster uniqueness.
- Fixed: fire proofing and the other proofings, the cursed spell of lightness, the screen dump option not saving a `.gz` filename, the Compiz full screen mode, the start menu shortcut and `make install`.
- Also: configuration menu, quit confirmation (Q for hard quit), the binary updater retries only randomly, and a tidier hiscore table.

### Unnumbered releases, 2008-2009 (between 1.15 and 1.19)
- **2009-03-24:** treasure and weapon hoards for some monsters, the Minotaur and Civil ward soldier classes, the musket and warhammers, and new monsters (squarm, smurlinger, morhock, lich, galump). Removed the dexterity requirement on swords and axes. Fixed crashes on alien generators and item drops, and a Windows install failure when the path had no `/`.
- **2009-01-08:** more troll, goblin and orc types, a new orc class, moving walls made more dangerous, sleeping mines, an impenetrable level edge, and faster centipedes. Fixed shop bugs, yellow ghosts that could not move, and orc generators that did not attack.
- **2008-12-21:** a large release with music by Pascal Provost, level shake, floor tiles, monster AI decision making, bones files, smoother scrolling, an auto-updater, shortcut keys, secret walls, amulets and named monsters. Also many new spells (summon monster, living wall, invisibility, raise dead, polymorph and others), monsters (hydra, mind flayer, medusa, death knight and others), weapons, levels (caves, hell, forest, the void, bonus levels, end game) and fixes.

### 1.15 (2008-02-02)
- Added the dig wand, poison arrows, teletrap, vampire knights, rock and lava outside the level, and poison zombies.
- Vampire bites now take fate points.
- Fixed bravery point bugs and patricia's pantry. Hard monsters are less frequent and there is less treasure.

### 1.13 (2008-01-23)
- Added bravery points, power-ups, black widow, goliath and wandering spiders, trapdoor spiders, bat caves, character classes (sorcerer, barbarian, warrior and others), pet vampires, elves and dwarves, sound effects, spinning swords and explosions that bounce.
- Added crash recovery (auto save), shields on teleport, and starting backpacks of items. Stealing is punished more, and the main loop is threaded.
- Renamed the source prefix `zx` to `gh`.

### 1.11 (2007-08-27)
- Added animated dragons, multi-layer ASCII, molds, lakes, acid/fire/water/cold-proof armour types, and orc and goblin types.

### 1.1 (2007-04-08)
- Added spells for items, a treasure chest, warp and exploding exits, and spying. Fixed a many-keys bug.

### 1.0 (2007-03-22)
- Added the gun, karma counter, and spells including remove curse, slow/fast, fireball, iceball, starburst, warp, blind and eagle vision. Exploding potions are faster.

### 0.99 (2007-02-25)
- Added armour (including ice, liquid and dragon types) and an armoury, cell doors, rifts, tar, mini lasers, a high score table, and stealing from shopkeepers. Levels play faster.

### 0.97 (2007-01-20)
- Added imps, white witches, moving walls, fairies, food shops, corpses and treasure stealing. Graphics are faster, and shop and save/load bugs were fixed.

### 0.94, 0.93 and 0.92 (2006-12-31)
- 0.94: moon, night, Friday 13th and midnight effects.
- 0.93: four bug fixes.
- 0.92: lavaball and demons, fixes for 64-bit builds, and a slower light flicker.

### 0.9 (2006-12-20) and 0.8 (2006-11-27)
- 0.9: save/load.
- 0.8: shops, carrying multiple weapons, and police for those who steal from shopkeepers.

### 0.7 (2006-11-20) and 0.6 (2006-10-22)
- 0.7: graveyards, dragon's lairs, electro doors, and more treasure and monsters.
- 0.6: Halloween edition with magic potions, spider webs, ghosts, knights, killer bees, skeleton keys and a MacOS port.

### 0.5 (2006-09-23), 0.4 (2006-09-17), 0.3 and 0.2 (2006-08)
- 0.5: pause button and help screen, no more exits next to doors, and no shooting through open doors.
- 0.4: ASCII snakes (anacondas and copperheads), a flying witch, giant bat graphics, dollar bill treasure, and fixes for gcc 4.1.1 and the flicker bug.
- 0.3: bats that turn into vampires, monster clusters, keypad movement, `make install`, a FreeBSD port, and no firing through walls.
- 0.2: Windows version, fireball, iceball and plasmaball shots, ogres, beholders, lighting and shot damage fixes.

## 2021-09-22 to 2021-09-26

### Changed
- Builds on Ubuntu 21.03.
- Code clean-up, notes, version bump, advertising and todo updates.

## 2019-11-30

### Added
- Screenshots.

### Fixed
- macOS build fixes.

## 2013-09-21 to 2015-10-22

- Initial commit (2013-09-21) and ongoing development, with later work in progress commits in 2013 and 2015.
