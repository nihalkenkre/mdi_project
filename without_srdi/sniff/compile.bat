@echo off

cl /nologo /MT /Od /W0 /GS- sniff.c /link /entry:main /machine:x64 /out:sniff.exe

del *.obj *.exp *.lib