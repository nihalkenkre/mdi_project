@echo off
nasm utils_test.asm -f Win64 -o utils_test.obj
link utils_test.obj /nologo kernel32.lib /largeaddressaware:no /entry:main /out:utils_test.exe
