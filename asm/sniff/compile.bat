@echo off
nasm -f Win64 sniff.asm -o sniff.obj
@REM link /nologo sniff.obj /machine:X64 /entry:main /largeaddressaware:no /subsystem:console
link /nologo sniff.obj /machine:X64 /entry:DllMain /DLL

del *.obj *.lib *.exp