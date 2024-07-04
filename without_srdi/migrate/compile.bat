@echo off

nasm -f win32 heavens_gate.asm -o heavens_gate.obj
cl /nologo /MT /Od /W0 /GS- /DNDEBUG migrate.c /link heavens_gate.obj /entry:main /machine:x86 /out:migrate.exe

del *.obj *.exp *.lib *.pdb *.ilk