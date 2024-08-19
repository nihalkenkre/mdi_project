@echo off

cl /nologo /W3 /MT /O2 /DNDEBUG helper.c /link kernel32.lib /out:helper.exe

del *.obj