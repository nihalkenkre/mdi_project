default rel

section .text
global main

%include '..\utils_64_text.asm'

extern WideCharToMultiByte

func:
    push rbx
    push rbp
    mov rbp, rsp

    push rcx
    pop rcx

    leave
    pop rbx
    ret

main:
    push rbp
    mov rbp, rsp

    sub rsp, 32         ; allocate shadow space

    call get_kernel_module_handle       ; kernel handle

    mov rcx, rax
    call populate_kernel_function_ptrs_by_name

    mov rsi, 0xdeadbabe
    mov rdi, 0xdeadbabe
    mov rbx, 0xdeadbabe

    mov rcx, test_str1_xor
    mov rdx, test_str2_xor
    mov r8, test_str1_xor.len
    call strcmpAA

    mov rcx, boomlade_xor
    mov rdx, boomlade_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    mov rcx, sleep_xor
    call [output_debug_string_a]

    sub rsp, 32
    mov rcx, 0xfde9
    xor rdx, rdx
    mov r8, wide_char_str
    mov r9, wide_char_str.len
    mov qword [rsp + 32], multi_byte_str
    mov qword [rsp + 40], multi_byte_str.len
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    call WideCharToMultiByte
    add rsp, 32

    mov rcx, wide_char_str
    mov rdx, multi_byte_str
    call wstrcpy

    mov rcx, veracrypt
    mov rdx, veracrypt.len
    call find_target_process_id

    mov rcx, veracrypt
    mov rdx, '.'
    call strchr

    add rsp, 32         ; free shadow space

.shutdown:
    leave
    ret

section .data
test_str1_xor: db 'wide_char_str', 0
.len equ $ - test_str1_xor

test_str2_xor: db 'wide_char_str', 0
.len equ $ - test_str2_xor

boomlade_xor: db 0x52, 0x5f, 0x5f, 0x5d, 0x5c, 0x51, 0x54, 0x55, 0
.len equ $ - boomlade_xor - 1 

wide_char_str: dw __utf16__ ('wide_char_str'), 0
.len equ $ - wide_char_str

veracrypt: db 'VeraCrypt.exe', 0
.len equ $ - veracrypt

%include '..\utils_64_data.asm'

section .bss
multi_byte_str: resb 128
.len equ $ - multi_byte_str