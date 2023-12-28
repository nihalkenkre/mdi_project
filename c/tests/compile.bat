@echo off

cl /nologo /W0 /MT /Ox /DNDEBUG /GS- /DWIN32_LEAN_AND_MEAN inject_vcsniff.c /link /subsystem:console /out:inject_vcsniff.exe

del *.obj *.exp *.lib