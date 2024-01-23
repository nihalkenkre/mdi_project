@echo off
nasm migrate.asm -i ../../../asm_utils -f Win32 -o migrate.obj
link /nologo migrate.obj /DLL /entry:DllMain /machine:x86 /out:migrate.dll
del *.lib *.exp *.obj