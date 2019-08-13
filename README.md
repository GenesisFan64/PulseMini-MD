# PulseMini-MD
A Sound Driver for Genesis / MegaDrive using the Z80 CPU

NOTE: this source code is actually a sound tester, the Z80 code is located at /system/md/z80.asm

# Features
- All 10 channels: FM and PSG
- Minimal FM3 Special mode support
- A single pitch/note-controlled PCM Sample with frequency up to -crunchy- 22100Hz (but quality will still get affected if you use DMA)
- Sample files are autobanked, they can be anywhere in the ROM (but the music data is still limited to single ROM banks)

The assembler used here is a custom version of AS Micro Assembler (both executables for Linux and Windows), the original was made by Alfred Arnold, coding is done on Linux so I haven't checked if it compiles on Windows...

# Scripts
This source uses Python3 scripts for the following things:
- For converting the output ROM file to BIN
- Converting the ImpulseTracker files to a custom format used by this driver
- Converting .tga files to the Genesis palette and graphics (optional)

Documentation is not done yet, but if you are still interested on using it on a big project contact me (at)_gf64 on Twitter
