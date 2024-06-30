@echo off
nasm sniff.asm -f Win64 -o sniff.obj
link /nologo sniff.obj /machine:X64 /entry:DllMain /DLL

del *.obj *.lib *.exp