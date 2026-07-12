# foo_sc68 for macOS

macOS (arm64) build of the SC68 (Atari ST / Amiga music) decoder for
foobar2000. Built with a plain Makefile + clang, not Xcode -- no project
file to open, just run `make`.

## Prerequisite

Unpack the foobar2000 SDK next to this folder, i.e. `../SDK-2025-03-07`
(sibling of `sc68-fb2k-mac/`, same level as `sc68-fb2k/`). Get it from
https://www.foobar2000.org/SDK. It's not committed to this repo (see
`.gitignore`) -- this Makefile compiles the SDK's pfc/SDK/helpers/shared
sources directly instead of linking prebuilt libraries, so the folder must
be present, but any recent SDK release with the same internal layout works.

## Build

```sh
make            # build/foo_sc68.component
make package    # ^ plus build/foo_sc68.fb2k-component (the distributable zip)
make install    # ^ plus copies it into ~/Library/foobar2000-v2/user-components/foo_sc68/
make clean      # wipe build/
```

## Notes

- **arm64 only**.
- The Preferences page (`pref_sc68_mac.mm`) is a native `NSViewController`
  built entirely in code (no `.xib`), applying each change immediately
  instead of Windows' separate Apply/Reset step.
- `sc68-fb2k/foo_sc68/*.cpp` (the plugin logic) is shared with the Windows
  build; only `pref_sc68_mac.mm` and the shim header under `shim/` are
  mac-only.
