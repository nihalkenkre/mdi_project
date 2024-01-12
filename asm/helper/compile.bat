@echo off
nasm -f Win64 helper.asm -o helper.obj
link /nologo helper.obj /machine:x64 /entry:WinMain /largeaddressaware:no /subsystem:windows

del *.obj *.lib *.exp