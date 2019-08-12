clear
echo "** MEGA DRIVE **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/rom_md.lst -A -L
python tools/p2bin.py main.p out/rom_md.bin
rm main.p
rm main.h
