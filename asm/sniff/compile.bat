@echo off
nasm -f Win64 sniff.asm -o sniff.obj
link /nologo sniff.obj /machine:X64 /entry:main /subsystem:console
@REM link /nologo sniff.obj /machine:X64 /entry:DllMain /DLL

del *.obj *.lib *.exp