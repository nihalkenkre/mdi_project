@echo off

cl /nologo /W0 /Ox /GS- /MT /DNDEBUG /DWIN32_LEAN_AND_MEAN migrate.c /link /DLL /entry:DllMain /subsystem:console /out:migrate.dll

del *.exp *.obj *.lib