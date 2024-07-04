@echo off 

cl /nologo /MT /Ox /W3 /DNDEBUG /GS- utils_dll.c /link /entry:DllMain /DLL /SUBSYSTEM:CONSOLE /out:utils_dll.dll