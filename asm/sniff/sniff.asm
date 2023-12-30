section .text
global DllMain

%include '..\utils_64_text.asm'

; arg0: hInstance       rcx
; arg1: dwReason        rdx
; arg2: reserved        r8
;
; return: BOOL          rax
DllMain:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx
    mov [rbp + 24], rdx
    mov [rbp + 32], r8

    mov rax, 1

    leave
    ret

global main
main:
    push rbp
    mov rbp, rsp

    sub rsp, 32
    call get_kernel_module_handle       ; kernel module handle in rax
    add rsp, 32

    sub rsp, 32
    mov rcx, rax
    mov rdx, loadlibrary_str
    call get_proc_address_by_name
    add rsp, 32

    leave
    ret

section .data
%include '../utils_64_data.asm'

kernel32_xor: db 0x5b, 0x55, 0x42, 0x5e, 0x55, 0x5c, 0x3, 0x2, 0x1e, 0x54, 0x5c, 0x5c, 0
.len equ $ - kernel32_xor - 1

loadlibrary_str: db 'LoadLibraryA', 0
.len equ $ - loadlibrary_str
