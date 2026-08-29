A foobar2000 input decodes `.sc68`, `.sndh`, `.snd` format.

Based on https://sourceforge.net/p/sc68/code/HEAD/tree r600 version (2015-11-28)

(Since I think this is the best version for emul effect through my test)

## Changes I made:

1. Move configuration from **right-click menu** to **Preferences → Playback → Decoding → SC68 input** and fixed the issue that the change in config can't be applied immediately.

2. Added seeking function. Now you can seeking sc68 songs!

3. Upagrade the project compatibility to MSVC 2022 C++ 17 standard and foobarSDK-2025-03-07. Use project references instead of static library to link. 

4. Fixed address loading issues for some replayers

5. Merged SNDH Database of r713 to this version 

## Compatibility
- foobar2000 **v2.0 or newer**, Windows, 32-bit **ONLY**.
- Built against the foobar2000 SDK (2025-03-07).

## Building from source

### Prerequisites
- Visual Studio 2022 with the **Desktop development with C++** workload (and a Windows 10/11 SDK).
- The official **foobar2000 SDK (2025-03-07 or compatible)**.
- **WTL 10** (Windows Template Library).

### Directory layout
The project files reference the SDK with system environment variable `FB2KSDK`. So, you just need to add the variable with SDK loacation to your system then the project will recognize it. 

WTL **MUST** be placed as below:

```
├─ Foobar2000SDK-2025\
│  ├─ foobar2000\
│  │  ├─ SDK\
│  │  ├─ helpers\
│  │  ├─ shared\
│  │  └─ foobar2000_component_client\
│  ├─ libPPUI\
│  ├─ pfc\
│  └─ WTL10_01_Release\Include\        <- WTL goes here
```
### Build steps
1. Open `sc68-fb2k.sln`.
2. Add all .vcxproj in foobar2000SDK (except `foo_sample`) and `sc68-msvc\zlib\zlib.vcxporj` to the solution. Then add all these as references to `foo_sc68`.
3. Build **Release | Win32** and the post event will pack dll to .fb2k-component automatically

