section .text
global main

arg_test:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx
    mov [rbp + 24], rdx
    mov [rbp + 32], r8
    mov [rbp + 40], r9

    mov rax, [rbp + 16]
    mov rax, [rbp + 24]
    mov rax, [rbp + 32]
    mov rax, [rbp + 40]
    mov rax, [rbp + 48]
    mov rax, [rbp + 56]
    mov rax, [rbp + 64]

    leave
    ret

main:

    sub rsp, 64
    mov rcx, 0xaa
    mov rdx, 0xbb
    mov r8, 0xcc
    mov r9, 0xdd
    mov qword [rsp + 32], 0xee
    mov qword [rsp + 40], 0xff
    mov qword [rsp + 48], 0xdead
    call arg_test
    add rsp, 64

    ret
