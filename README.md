# PulseMini-MD
A Sound Driver for Genesis / MegaDrive using the Z80 CPU

NOTE: this source code is actually a sound tester, the Z80 code is located at /system/md/sound/z80.asm

# Features
- All 10 channels: FM and PSG
- FM key bits, AMS, FMS...
- FM3: Special mode support (only frequency changes)
- A single pitch/note-controlled PCM Sample with frequency up to -crunchy- 22100Hz (but quality will still get affected if you use DMA)
- Sample files are autobanked, you can put them anywhere in the ROM area ($000000-$3FFFFF) with no filesize restriction, but the track is still limited to single ROM banks
- Can change modes on the fly for FM channels 3 and 6 (between Normal mode and Special mode for FM3, Normal channel and Sample channel for FM6)
- PSG instruments (not just a single beep), NOISE channel auto-mute detection for Tone3 mode
- Channels effects currently supported: Volume Slide (Dxx), Portametro (Exx) (Fxx) and Panning (Xxx)

The assembler used here is a custom version of AS Micro Assembler (both executables for Linux and Windows), the original was made by Alfred Arnold, coding is done on Linux so I haven't checked if it compiles on Windows...

# Scripts
This source uses Python3 scripts as file convertors for the following things:
- AS .p to BIN
- ImpulseTracker files to a custom format used by this driver
- .tga files to the Genesis palette and graphics (optional)

Documentation is not done yet, but if you are still interested on using it on a big project, contact me (at)_gf64 on Twitter
