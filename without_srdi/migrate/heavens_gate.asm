section .text

global _ExecuteRemoteThread64

jmp _ExecuteRemoteThread64

; Not using retn since the C compiler will add 'add esp, nBytes' after the function call. 
; /Od flag to get code into on section.

[bits 64]
; arg0: str             rcx
; ret: num chars        rax
strlen_hg:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                 ; str

    ; rbp - 8 = output strlen
    ; rbp - 16 = rsi
    sub rsp, 16                         ; allocate local variable space
    
    mov qword [rbp - 8], 0              ; strlen = 0
    mov [rbp - 16], rsi                 ; save rsi

    mov rsi, [rbp + 16]                 ; str

    jmp .while_condition
    .loop:
         inc qword [rbp - 8]            ; ++strlen

        .while_condition:
            lodsb                       ; load from mem to al

            cmp al, 0                   ; end of string ?
            jne .loop
    
    mov rsi, [rbp - 16]                 ; restore rsi 
    mov rax, [rbp - 8]                  ; strlen in rax

    leave
    ret

; arg0: str             rcx
; arg1: wstr            rdx
;
; ret: 1 if equal       rax
strcmpiAW_hg:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str
    mov [rbp + 24], rdx             ; wstr

    ; rbp - 8 = return value
    ; rbp - 16 = rsi
    ; rbp - 24 = rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; str
    mov rdi, [rbp + 24]             ; wstr

.loop:
    movzx eax, byte [rsi]
    movzx edx, byte [rdi]

    cmp al, dl

    jg .al_more_than_dl
    jl .al_less_than_dl

.continue_loop:
    cmp al, 0                       ; end of string ?
    je .loop_end_equal

    inc rsi
    add rdi, 2

    jmp .loop

    .al_more_than_dl:
        add dl, 32
        cmp al, dl

        jne .loop_end_not_equal
        jmp .continue_loop

    .al_less_than_dl:
        add al, 32
        cmp al, dl

        jne .loop_end_not_equal
        jmp .continue_loop

.loop_end_not_equal:
    mov qword [rbp - 8], 0          ; return value
    jmp .shutdown

.loop_end_equal:
    mov qword [rbp - 8], 1          ; return value
    jmp .shutdown

.shutdown:
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: str                     rcx
; arg1: wstr                    rdx
;
; ret: 1 if equal               rax
strcmpiAA_hg:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str
    mov [rbp + 24], rdx             ; wstr

    ; rbp - 8 = return value
    ; rbp - 16 = rsi
    ; rbp - 24 = rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; str
    mov rdi, [rbp + 24]             ; wstr

.loop:
    movzx eax, byte [rsi]
    movzx edx, byte [rdi]

    cmp al, dl
    jg .al_more_than_dl
    jl .al_less_than_dl

.continue_loop:
    cmp al, 0                       ; end of string ?
    je .loop_end_equal

    inc rsi
    inc rdi

    jnz .loop

    .al_more_than_dl:
        add dl, 32
        cmp al, dl

        jne .loop_end_not_equal
        jmp .continue_loop

    .al_less_than_dl:
        add al, 32
        cmp al, dl

        jne .loop_end_not_equal
        jmp .continue_loop

.loop_end_not_equal:
    mov qword [rbp - 8], 0          ; return value
    jmp .shutdown

.loop_end_equal:
    mov qword [rbp - 8], 1          ; return value
    jmp .shutdown

.shutdown:
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: str                     rcx
; arg1: chr                     rdx
;
; return: ptr to chr            rax
strchr_hg:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str 
    mov [rbp + 24], rdx             ; chr

    ; rbp - 8 = cRet
    ; rbp - 16 = strlen
    ; rbp - 24 = c
    ; rbp - 32 = rbx
    sub rsp, 32                     ; allocate local variable space
    sub rsp, 32                     ; allocate shadow space

    mov qword [rbp - 8], -1         ; cRet = 0
    mov [rbp - 32], rbx             ; save rbx

    mov rcx, [rbp + 16]             ; str
    call strlen_hg                  ; strlen

    mov [rbp - 16], rax             ; strlen

    mov qword [rbp - 24], 0         ; c = 0
    .loop:
        mov rdx, [rbp + 16]         ; str in rdx     
        mov rbx, [rbp - 24]         ; c in rbx

        movzx ecx, byte [rdx + rbx] ; sStr[c]

        cmp cl, [rbp + 24]          ; sStr[c] == chr ?

        je .equal

        inc qword [rbp - 24]        ; ++c
        mov rax, [rbp - 16]         ; strlen in rax
        cmp [rbp - 24], rax         ; c < strlen ?

        jne .loop
        jmp .shutdown

        .equal:
            add rdx, rbx
            mov [rbp - 8], rdx      ; cRet = str + c

            jmp .shutdown

.shutdown:
    mov rbx, [rbp - 32]             ; restore rbx
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: base addr           rcx
; arg1: proc name           rdx
;
; return: proc addr         rax
get_proc_address_by_name_hg:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; base addr
    mov [rbp + 24], rdx                     ; proc name

    ; rbp - 8 = return value
    ; rbp - 16 = nt headers
    ; rbp - 24 = export data directory
    ; rbp - 32 = export directory
    ; rbp - 40 = address of functions
    ; rbp - 48 = address of names
    ; rbp - 56 = address of name ordinals
    ; rbp - 312 = forwarded dll.function name - 256 bytes
    ; rbp - 320 = function name
    ; rbp - 328 = loaded forwarded library addr
    ; rbp - 336 = function name strlen
    ; rbp - 344 = rbx
    ; rbp - 472 = dll name with extension -> not used, dll name used as is without .dll ext
    ; ebp - 480 = 8 bytes padding
    sub rsp, 480                            ; allocate local variable space
    sub rsp, 32                             ; allocate shadow space

    mov qword [rbp - 8], 0                  ; return value
    mov [rbp - 344], rbx                    ; save rbx

    mov rbx, [rbp + 16]                     ; base addr
    add rbx, 0x3c                           ; *e_lfa_new

    movzx ecx, word [rbx]                   ; e_lfanew

    mov rax, [rbp + 16]                     ; base addr
    add rax, rcx                            ; nt header

    mov [rbp - 16], rax                     ; nt header

    add rax, 24                             ; optional header
    add rax, 112                            ; export data directory

    mov [rbp - 24], rax                     ; export data directory

    mov rax, [rbp + 16]                     ; base addr
    mov rcx, [rbp - 24]                     ; export data directory
    mov ebx, [rcx]
    add rax, rbx                            ; export directory

    mov [rbp - 32], rax                     ; export directory

    add rax, 28                             ; address of functions rva
    mov eax, [rax]                          ; rva in rax
    add rax, [rbp + 16]                     ; base addr + address of function rva

    mov [rbp - 40], rax                     ; address of functions

    mov rax, [rbp - 32]                     ; export directory
    add rax, 32                             ; address of names rva
    mov eax, [rax]                          ; rva in rax
    add rax, [rbp + 16]                     ; base addr + address of names rva

    mov [rbp - 48], rax                     ; address of names

    mov rax, [rbp - 32]                     ; export directory
    add rax, 36                             ; address of name ordinals
    mov eax, [rax]                          ; rva in rax
    add rax, [rbp + 16]                     ; base addr + address of name ordinals

    mov [rbp - 56], rax                     ; address of name ordinals

    mov r10, [rbp - 32]                     ; export directory
    add r10, 24                             ; number of names
    mov r10d, [r10]                         ; number of names in r10

    xor r11, r11
.loop_func_names:
    ; to index into an array, we multiply the size of each element with the 
    ; current index and add it to the base addr of the array
    mov dword eax, 4                        ; size of dword
    mul r11                                 ; size * index
    mov rbx, [rbp - 48]                     ; address of names
    add rbx, rax                            ; address of names + n
    mov ebx, [rbx]                          ; address of names [n]

    add rbx, [rbp +  16]                    ; base addr + address of names [n]

    mov rcx, [rbp + 24]                     ; proc name
    mov rdx, rbx
    call strcmpiAA_hg

    cmp rax, 1                              ; are strings equal
    je .function_found

    inc r11
    cmp r11, r10
    jne .loop_func_names

    jmp .shutdown

.function_found:
    mov rax, 2                              ; size of ordinal value
    mul r11                                 ; index * size of element of addrees of name ordinals(word)
    add rax, [rbp - 56]                     ; address of name ordinals + n
    movzx eax, word [rax]                   ; address of name ordinals [n]; index into address of functions

    mov rbx, 4                              ; size of element of address of functions(dword)
    mul rbx                                 ; index * size of element
    add rax, [rbp - 40]                     ; address of functions + index
    mov eax, dword [rax]                    ; address of functions [index]

    add rax, [rbp + 16]                     ; base addr + address of functions [index]

    mov [rbp - 8], rax                      ; return value

.shutdown:
    mov rbx, [rbp - 344]                    ; restore rbx
    mov rax, [rbp - 8]                      ; return value

    leave
    ret

get_ntdll_module_handle_hg:

    push rbp
    mov rbp, rsp

    ; rbp - 8 = First List Entry
    ; rbp - 16 = Current List Entry
    ; rbp - 24 = Table Entry
    ; rbp - 32 = return addr
    ; rbp - 56 = ntdll string
    ; rbp - 64 = padding bytes
    sub rsp, 64                         ; allocate local variable space
    sub rsp, 32                         ; allocate shadow space

    mov rax, 'ntdll.dl'
    mov [rbp - 56], rax
    mov rax, 'l'
    mov [rbp - 48], rax

    mov rax, gs:[0x60]                  ; peb
    add rax, 0x18                       ; *ldr
    mov rax, [rax]                      ; ldr
    add rax, 0x20                       ; InMemoryOrderModuleList

    mov [rbp - 8], rax                  ; *FirstModule
    mov rax, [rax]
    mov [rbp - 16], rax                 ; CurrentModule
    mov qword [rbp - 32], 0             ; return code

.loop:
    cmp rax, [rbp - 8]                  ; CurrentModule == FirstModule ?
    je .loop_end_equal
        sub rax, 16                     ; *TableEntry
        mov [rbp - 24], rax             ; *TableEntry

        add rax, 0x58                   ; *BaseDLLName
        add rax, 0x8                    ; BaseDLLName.Buffer

        mov rcx, rbp
        sub rcx, 56                     ; ntdll string
        mov rdx, [rax]
        call strcmpiAW_hg

        cmp rax, 1                      ; strings match
        je .module_found

        mov rax, [rbp - 16]             ; CurrentModule
        mov rax, [rax]                  ; CurrentModule = CurrentModule->Flink
        mov [rbp - 16], rax             ; CurrentModule

        jmp .loop

.module_found:
    mov rax, [rbp - 24]                 ; *TableEntry
    add rax, 0x30                       ; TableEntry->DllBase
    mov rax, [rax]
    mov [rbp - 32], rax

    jmp .shutdown

.loop_end_equal:

.shutdown:
    mov rax, [rbp - 32]                 ; return code

    leave
    ret

[bits 32]
go_to_64_bit:
    retf

[bits 64]
go_to_32_bit:
    retfq

[bits 32]

; arg0: remote target handle    ebp + 8
; arg1: ptr to remote mem       ebp + 12
; arg2: out ptr to hThread      ebp + 16
_ExecuteRemoteThread64:
        push ebp
        mov ebp, esp

        ; ebp - 8  return value
        ; ebp - 32 = RtlCreateUserThread str
        ; ebp - 40 = RtlCreateUserThread addr
        ; ebp - 48 = ntdll addr
        sub esp, 48                             ; local space
        sub esp, 80                             ; shadow space
        
        mov dword [ebp - 8], 0

        ; RtlCreateUserThread str
        mov eax, 'RtlC'
        mov [ebp - 32], eax

        mov eax, 'reat'
        mov [ebp - 28], eax

        mov eax, 'eUse'
        mov [ebp - 24], eax

        mov eax, 'rThr'
        mov [ebp - 20], eax

        mov eax, 'ead'
        mov [ebp - 16], eax
        mov byte [ebp - 13], 0

        push dword 0x33
        call go_to_64_bit

    [bits 64]

        call get_ntdll_module_handle_hg

        mov [ebp - 48], rax                 ; ntdll add

        mov rcx, [ebp - 48]                 ; ntdll addr
        mov rdx, rbp
        sub rdx, 32                         ; RtlCreateUserThread str
        call get_proc_address_by_name_hg

        mov [rbp - 40], rax                 ; RtlCreateUserThread addr

        mov ecx, [rbp + 8]                  ; target handle
        xor edx, edx
        xor r8d, r8d
        xor r9d, r9d
        mov qword [rsp + 32], 0
        mov qword [rsp + 40], 0
        mov eax, [rbp + 12]                 ; ptr to remote mem
        mov qword [rsp + 48], rax
        mov qword [rsp + 56], 0
        mov eax, [rbp + 16]
        mov qword [rsp + 64], rax           ; out ptr to thread
        mov qword [rsp + 72], 0
        
        call [rbp - 40]                     ; RtlCreateUserThread

        push qword 0x23
        call go_to_32_bit

    [bits 32]

        mov eax, [ebp - 8]                  ; return value

        leave
        ret