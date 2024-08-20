@echo off
nasm -f bin migrate.asm -o migrate.bin
python ../../../maldev_tools/transform/transform_file.py -i migrate.bin -o ../helper/migrate.bin.h -vn migrate