# foo_sc68

SC68 (Atari ST / Amiga music) decoder component for foobar2000, based on the
[sc68 r599](https://sourceforge.net/p/sc68/code/HEAD/tree) SVN version
(2015-09-13) -- the best version for emulation quality in testing.

## Changes

1. Move configuration from right-click menu to Preferences->Playback->Decoding->SC68 and fixed the issue that the change in config can't be applied at meanwhile.

2. Added seeking function. Now you can drag the playback progress bar!

3. Added a macOS version of the foobar2000 component (Apple Silicon / arm64).

   - The Windows build links prebuilt foobar2000 SDK `.lib` files checked
     into `sc68-fb2k/lib/`, but no equivalent prebuilt libraries exist for
     mac, so `sc68-fb2k-mac/Makefile` compiles `file68`/`libsc68`/`unice68`
     and the foobar2000 SDK sources directly instead (bypassing autotools
     the same way `sc68-msvc` bypasses it with a hand-written `config.h`).
   - Run `make package` in `sc68-fb2k-mac/` to produce a distributable
     `foo_sc68.fb2k-component`; see that Makefile's header comment for the
     one prerequisite (an unpacked copy of the foobar2000 SDK next to the
     `sc68-fb2k-mac/` folder).
   - The Preferences -> Playback -> Decoding -> SC68 page is reimplemented
     for mac as a native `NSViewController` built entirely in code (no
     `.xib`), exposing the same settings as the Windows dialog: sampling
     rate, default track length, aSIDifier, YM engine/filter/volume model,
     L/R blend, and the Amiga low-pass filter. Unlike the Windows dialog
     there's no separate Apply/Reset step -- each control applies
     immediately, matching how foobar2000's own sample component behaves
     on mac.

4. Fixed the "Default length (s)" setting having no effect (a pre-existing
   bug in libsc68, fixed on both platforms).
