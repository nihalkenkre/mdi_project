@echo off
nasm helper.asm -i ../../../asm_utils -f Win64 -o helper.obj
link /nologo helper.obj /machine:x64 /entry:WinMain /largeaddressaware:no /subsystem:windows

del *.obj *.lib *.exp