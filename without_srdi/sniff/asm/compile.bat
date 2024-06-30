@echo off
nasm -f Win64 sniff.asm -o sniff.obj
link /nologo sniff.obj /entry:main /out:sniff.exe

del *.obj