section .text
global DllMain

%include '..\utils_64_text.asm'

hook_iat:
    push rbp
    mov rbp, rsp

    leave
    ret

hook_inline_patch:
    push rbp
    mov rbp, rsp

    leave
    ret

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


; global main
; main:
;     push rbp
;     mov rbp, rsp

;     ; [rbp - 8] = return value
;     ; [rbp - 16] = kernel addr
;     sub rsp, 16                         ; allocate local variables space

;     sub rsp, 32
;     call get_kernel_module_handle       ; kernel module handle in rax
;     add rsp, 32

;     mov [rbp - 16], rax                 ; kernel module addr

;     sub rsp, 32
;     mov rcx, [rbp - 16]
;     mov rdx, loadlibrary_str
;     mov r8, loadlibrary_str.len
;     call get_proc_address_by_name       ; proc addr in rax
;     add rsp, 32

;     mov [loadlibrary_addr], rax

;     sub rsp, 32
;     mov rcx, [rbp - 16]
;     mov rdx, test_str
;     mov r8, test_str.len
;     call get_proc_address_by_name       ; proc addr in rax
;     add rsp, 32

;     add rsp, 16                         ; free local variables space

;     leave
;     ret

section .data
virtualalloc_str: db 'VirtualAlloc', 0
.len equ $ - virtualalloc_str

test_str: db 'AddVectoredContinueHandler', 0
.len equ $ - test_str

%include '../utils_64_data.asm'