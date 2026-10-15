# GoblinHack Code Review

Remaining issues only; everything else from the original review (October 12, 2026) has been fixed.

## Open

### Early return in `~gh_thing` (`src/things/thing.cpp:1035`)
`if (isref(GH_THING_REF_LAST)) return;` aborts destruction part-way. It looks like a deliberate "temporary last ref" guard, so changing it needs care. The throws in the same destructor are already logged instead.

### `using namespace std;` in `src/include/gh_sys.h:48`
Pollutes every translation unit, and fixed-width types are `#define`d rather than taken from `<cstdint>`. Removing it touches most of the ~72k lines, so it is likely not worth doing.

### `gh_thing` is a god object
`gh_thing.h` is ~2000 lines and `copy()` copies ~100 fields by hand. A refactor to components is out of scope for a keep-it-compiling goal.
