@echo off

cl /nologo /W0 /Ox /GS- /MT /DNDEBUG /DWIN32_LEAN_AND_MEAN vcmigrate.c /link /DLL /entry:DllMain /subsystem:console /out:vcmigrate.dll
@REM cl /nologo /W0 /Ox /GS- /MT /DNDEBUG /DWIN32_LEAN_AND_MEAN vcmigrate.c /link /entry:main /subsystem:console /out:vcmigrate.exe

del *.exp *.obj *.lib