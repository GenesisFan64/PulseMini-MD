@echo off
cls
echo ** MEGA DRIVE **
"tools\AS\win32\asw" main.asm -q -xx -c -A -olist out/rom_md.lst -A -L
C:\Python30\python tools\p2bin.py main.p out\rom_md.bin
del main.p
del main.h
pause