section .text

global main

jmp main


; arg0: src         rcx
; arg1: dst         rdx
; arg2: nBytes      r8
memcpy:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; src
    mov [rbp + 24], rdx             ; dst
    mov [rbp + 32], r8              ; nBytes

    ; rbp - 8 = return value
    ; rbp - 16 = rsi
    ; rbp - 24 = rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; src
    mov rdi, [rbp + 24]             ; dst
    mov rcx, [rbp + 32]             ; nBytes

    rep movsb                       ; move from rsi to rdi until rcx == 0

    mov rdi, [rbp - 24]             ; save rdi
    mov rsi, [rbp - 16]             ; save rsi
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: str             rcx
; arg1: wstr            rdx
;
; ret: 1 if equal       rax
strcmpiAW:
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
strcmpiAA:
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

; arg0: base addr           rcx
; arg1: proc name           rdx
;
; return: proc addr         rax
get_proc_address_by_name:
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
        call strcmpiAA

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

    .shutdown:
        leave
        ret

; ret: kernel handle        rax
get_kernel_module_handle:

    push rbp
    mov rbp, rsp

    ; rbp - 8 = First List Entry
    ; rbp - 16 = Current List Entry
    ; rbp - 24 = Table Entry
    ; rbp - 32 = return addr
    ; rbp - 56 = kernel32.dll str
    ; rbp - 64 = padding
    sub rsp, 64                         ; allocate local variable space
    sub rsp, 32                         ; allocate shadow space

    ; kernel32 str
    mov rax, 'kernel32'
    mov [rbp - 56], rax

    mov eax, '.dll'
    mov [rbp - 48], eax
    mov byte [rbp - 44], 0

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
        sub rcx, 56
        mov rdx, [rax]
        call strcmpiAW

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

hook_iat:
        push rbp
        mov rbp, rsp

        ; rbp - 8 = kernel32 handle
        ; rbp - 16 = GetProcAddress addr
        ; rbp - 24 = LoadLibraryA addr
        ; rbp - 32 = GetModuleHandleA addr
        ; rbp - 40 = DbgHelp addr
        ; rbp - 48 = ImageDirectoryEntryToDataEx addr
        ; rbp - 64 = GetProcAddress str
        ; rbp - 80 = LoadLibraryA str
        ; rbp - 104 = GetModuleHandleA str
        ; rbp - 120 = DbgHelp str
        ; rbp - 152 = ImageDirectoryEntryToDataEx str
        ; rbp - 176 = WideCharToMultiByte str 

        sub rsp, 1024               ; local variable space
        sub rsp, 32                 ; shadow space

        ; GetProcAddress str
        mov rax, 'GetProcA' 
        mov [rbp - 64], rax

        mov rax, 'ddress'
        mov [rbp - 56], rax
        mov byte [rbp - 48], 0

        ; LoadLibraryA str
        mov rax, 'LoadLibr'
        mov [rbp - 80], rax

        mov rax, 'aryA'
        mov [rbp - 72], rax
        mov byte [rbp - 68], 0

        ; GetmoduleHandleA str
        mov rax, 'GetModul'
        mov [rbp - 104], rax

        mov rax, 'eHandleA'
        mov [rbp - 96], rax
        mov byte [rbp - 88], 0

        ; DbgHelp str
        mov rax, 'DbgHelp'
        mov [rbp - 120], rax
        mov byte [rbp - 113], 0

        ; ImageDirectoryEntryToDataEx str
        mov rax, 'ImageDir'
        mov [rbp - 152], rax

        mov rax, 'ectoryEn'
        mov [rbp - 144], rax

        mov rax, 'tryToDat'
        mov [rbp - 136], rax

        mov rax, 'aEx'
        mov [rbp - 128], rax
        mov byte [rbp - 125], 0

        ; WideCharToMultiByte str
        mov rax, 'WideChar'
        mov [rbp - 176], rax

        mov rax, 'ToMultiB'
        mov [rbp - 168], rax

        mov rax, 'yte'
        mov [rbp - 160], rax
        mov byte [rbp - 157], 0

        ; Get kernel32 handle
        call get_kernel_module_handle

        test eax, eax               ; did function fail?
        je .shutdown

        mov [rbp - 8], rax          ; kernel32 addr

        ; GetProcAddress addr
        mov rcx, [rbp - 8]          ; kernel32 addr
        mov rdx, rbp
        sub rdx, 64                 ; GetProcAddress str
        call get_proc_address_by_name

        test eax, eax               ; did function fail?
        je .shutdown

        mov [rbp - 16], rax         ; GetProcAddress addr

        ; LoadLibraryA addr
        mov rcx, [rbp - 8]          ; kernel32 addr
        mov rdx, rbp
        sub rdx, 80                 ; LoadLibraryA str
        call [rbp - 16]             ; GetProcAddress

        test eax, eax
        je .shutdown

        mov [rbp - 24], rax         ; LoadLibraryA addr

        ; GetModuleHandleA addr
        mov rcx, [rbp - 8]          ; kernel32 addr
        mov rdx, rbp
        sub rdx, 104                ; GetModuleHandleA str
        call [rbp - 16]              ; GetProcAddress

        test eax, eax
        je .shutdown

        mov [rbp - 32], rax         ; GetModuleHandleA addr

        ; DbgHelp addr
        mov rcx, rbp
        sub rcx, 120
        call [rbp - 24]             ; LoadLibraryA

        test eax, eax
        je .shutdown

        mov [rbp - 40], rax         ; DbgHelp addr

        ; ImageDirectoryEntryToDataEx addr
        mov rcx, [rbp - 40]         ; DbgHelp addr
        mov rdx, rbp
        sub rdx, 152                ; ImageDirectoryEntryToDataEx str
        call [rbp - 16]             ; GetProcAddress

        test eax, eax
        je .shutdown

        mov [rbp - 48], rax         ; ImageDirectoryEntryToDataEx addr

        ; WideCharToMultiByte addr
        mov rcx, [rbp - 8]          ; kernel32 addr
        mov rdx, rbp
        sub rdx, 176                ; WideCharToMultiByte str
        call [rbp - 16]             ; GetProcAddress

        test eax, eax
        je .shutdown

        mov r15, rax                ; WideCharToMultiByte addr
    
    .shutdown:

        leave
        ret

main:
        push rbp
        mov rbp, rsp
    
        sub rsp, 32                 ; shadow space

        call hook_iat

    .shutdown:
        leave
        ret