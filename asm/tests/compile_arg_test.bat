@echo off
nasm -f Win64 arg_test.asm -o arg_test.obj
link /nologo arg_test.obj /entry:main /out:arg_test.exe