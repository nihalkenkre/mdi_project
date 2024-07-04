@echo off

cl /nologo /W0 /MT /Ox /GS- /DNDEBUG /DWIN32_LEAN_AND_MEAN helper.c /link /entry:WinMain /subsystem:windows /out:helper.exe
del *.obj