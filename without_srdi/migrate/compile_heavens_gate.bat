@echo off
nasm -f win32 heavens_gate.asm -o heavens_gate.obj
link /nologo heavens_gate.obj /entry:main /machine:x86 /out:heavens_gate.exe