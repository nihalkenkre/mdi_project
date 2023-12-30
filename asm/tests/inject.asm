section .text
global main

extern LoadLibraryA

main:
    push rbp
    mov rbp, rsp

    sub rsp, 32
    mov rcx, sniff
    call LoadLibraryA
    add rsp, 32

    xor rax, rax

    leave
    ret

section .data
sniff: db 'sniff.dll', 0