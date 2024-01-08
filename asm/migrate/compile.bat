@echo off
nasm migrate.asm -f Win32 -o migrate.obj
link /nologo migrate.obj /entry:DllMain /machine:x86 /out:migrate.dll