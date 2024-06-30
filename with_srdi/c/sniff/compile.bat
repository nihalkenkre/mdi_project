@echo off

cl /nologo /W0 /MT /Ox /DNDEBUG /GS- /DWIN32_LEAN_AND_MEAN sniff.c /link libucrt.lib /entry:DllMain /DLL /subsystem:console /out:sniff.dll

del *.obj *.exp *.lib