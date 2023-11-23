@echo off

cl /nologo /W0 /MT /Ox /DNDEBUG /GS- /DWIN32_LEAN_AND_MEAN vcsniff.c /link libucrt.lib /entry:DllMain /DLL /subsystem:console /out:vcsniff.dll

del *.obj *.exp *.lib