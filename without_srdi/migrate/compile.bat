@echo off

cl /nologo /MT /Od /W0 /GS- /DNDEBUG migrate.c /link /entry:main /machine:x86 /out:migrate.exe

del *.obj *.exp *.lib