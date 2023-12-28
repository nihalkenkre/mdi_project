@echo off

cl /nologo /W0 /MT /Ox /GS- /DNDEBUG /DWIN32_LEAN_AND_MEAN vchelper.c /link /entry:WinMain /subsystem:windows /out:vchelper.exe
del *.obj