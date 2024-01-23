@echo off
nasm sniff.asm -i ../../../asm_utils -f Win64 -o sniff.obj
link /nologo sniff.obj /machine:X64 /entry:DllMain /DLL

del *.obj *.lib *.exp