@echo off
nasm -f Win64 inject.asm -o inject.obj
@REM cl /nologo /c /W0 /MT /Ox /DNDEBUG /GS- /DWIN32_LEAN_AND_MEAN inject.c
link /nologo inject.obj kernel32.lib /machine:x64 /largeaddressaware:no /entry:main /out:inject.exe
del *.obj *.lib *.exp