@echo off

nasm -f bin sniff.asm -o sniff.x64.bin
python ../../../maldev_tools/transform/transform_file.py -i sniff.x64.bin -o ../helper/sniff.x64.bin.h -vn sniff_x64
python ../../../maldev_tools/transform/transform_file.py -i sniff.x64.bin -o ../migrate/sniff.x64.bin.asm -vn sniff_x64

nasm -f bin sniff_hooked_func.asm -o sniff_hooked_func.x64.bin
python ../../../maldev_tools/transform/transform_file.py -i sniff_hooked_func.x64.bin -o ../helper/sniff_hooked_func.x64.bin.h -vn sniff_hooked_func_x64
python ../../../maldev_tools/transform/transform_file.py -i sniff_hooked_func.x64.bin -o ../migrate/sniff_hooked_func.x64.bin.asm -vn sniff_hooked_func_x64