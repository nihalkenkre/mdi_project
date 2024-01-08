section .text

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

    sub esp, 8                  ; free local variable space
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
    sub esp, 16                     ; allocate local variable space

    mov dword [ebp - 4], -1         ; cRet
    mov [ebp - 16], ebx             ; save ebx

    sub esp, 4
    mov eax, [ebp + 8]              ; str
    mov [esp], eax                  ; str
    call strlen

    mov [ebp - 8], eax              ; strlen

    mov dword [ebp - 12], 0         ; c = 0
    .loop:
        mov edx, [ebp + 8]          ; str
        mov ebx, [ebp - 12]         ; c

        movzx ecx, byte [edx + ebx] ; str[c]

        cmp cl, [ebp + 12]          ; str[c] == chr ?
        je .equal

        inc dword [ebp - 12]        ; ++c
        mov eax, [ebp - 8]          ; strlen
        cmp [ebp - 12], eax         ; c < strlen

        jne .loop
        jmp .shutdown

        .equal:
            add edx, ebx            ; str + c
            mov [ebp - 4], edx      ; cRet = str + c

            jmp .shutdown

.shutdown:
    mov eax, [ebp - 4]          ; return value
    mov ebx, [ebp - 16]         ; restore ebx

    add esp, 16                 ; free local variable space
    add esp, 8                  ; free arg stack

    leave
    ret

; arg0: data            [ebp + 8]
; arg1: data_len        [ebp + 12]
; arg2: key             [ebp + 16]
; arg3: key_len         [ebp + 20]
my_xor:
    push ebp
    mov ebp, esp

    ; [ebp - 4] = return value
    ; [ebp - 8] = i
    ; [ebp - 12] = j
    ; [ebp - 16] = bInput
    ; [ebp - 20] = b
    ; [ebp - 24] = data_bit_i
    ; [ebp - 28] = key_bit_j
    ; [ebp - 32] = bit_xor
    ; [ebp - 36] = ebx
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

    sub esp, 16                                 ; allocate arg stack
    mov dword [esp], kernel32_xor
    mov dword [esp + 4], kernel32_xor.len
    mov dword [esp + 8], xor_key
    mov dword [esp + 12], xor_key.len
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

        sub esp, 12
        mov dword [esp], kernel32_xor
        mov eax, [eax]
        mov [esp + 4], eax                      ; BaseDLLName.Buffer
        mov dword [esp + 8], kernel32_xor.len
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
    sub esp, 300                                ; allocate local variable space

    mov dword [ebp - 4], 0                      ; return value
    mov [ebp - 300], ebx                        ; save ebx
   
    mov ebx, [ebp + 16]         ; base addr
    add ebx, 0x3c               ; *e_lfa_new

    movzx ecx, word [ebx]       ; e_lfanew

    mov eax, [ebp + 16]         ; base addr
    add eax, ecx                ; nt header

    mov [ebp - 16], eax         ; nt header

    add eax, 24                 ; optional header
    add eax, 112                ; export data directory

    mov [ebp - 24], eax         ; export data directory

    mov eax, [ebp + 16]         ; base addr
    mov ecx, [ebp - 24]         ; export data directory
    mov ebx, [ecx]
    add eax, ebx                ; export directory

    mov [ebp - 32], eax         ; export directory

    add eax, 28                 ; address of functions rva
    mov eax, [eax]              ; rva in eax
    add eax, [ebp + 16]         ; base addr + address of function rva

    mov [ebp - 40], eax         ; address of functions

    mov eax, [ebp - 32]         ; export directory
    add eax, 32                 ; address of names rva
    mov eax, [eax]              ; rva in eax
    add eax, [ebp + 16]         ; base addr + address of names rva

    mov [ebp - 48], eax         ; address of names

    mov eax, [ebp - 32]         ; export directory
    add eax, 36                 ; address of name ordinals
    mov eax, [eax]              ; rva in eax
    add eax, [ebp + 16]         ; base addr + address of name ordinals

    mov [ebp - 56], eax         ; address of name ordinals

    mov r10, [ebp - 32]         ; export directory
    add r10, 24                 ; number of names
    mov r10d, [r10]             ; number of names in r10

    xor r11, r11
.loop_func_names:
    ; to index into an array, we multiply the size of each element with the 
    ; current index and add it to the base addr of the array
    mov dword eax, 4            ; size of dword
    mul r11                     ; size * index
    mov ebx, [ebp - 48]         ; address of names
    add ebx, eax                ; address of names + n
    mov ebx, [ebx]              ; address of names [n]

    add ebx, [ebp +  16]        ; base addr + address of names [n]

    mov ecx, [ebp + 24]         ; proc name
    mov edx, ebx
    mov r8, [ebp + 32]          ; proc name len
    call strcmpiAA

    cmp eax, 1                  ; are strings equal
    je .function_found

    inc r11
    cmp r11, r10
    jne .loop_func_names

    jmp .shutdown

.function_found:
    mov eax, 2
    mul r11                     ; index * size of element of addrees of name ordinals(word)
    add eax, [ebp - 56]         ; address of name ordinals + n
    movzx eax, word [eax]       ; address of name ordinals [n]; index into address of functions

    mov ebx, 4                  ; size of element of address of functions(dword)
    mul ebx                     ; index * size of element
    add eax, [ebp - 40]         ; address of functions + index
    mov eax, dword [eax]        ; address of functions [index]

    add eax, [ebp + 16]         ; base addr + address of functions [index]

    mov [ebp - 8], eax          ; return value

    ; check if the function is forwarded
    mov r8, [ebp + 16]          ; base addr
    mov eax, [ebp - 24]         ; export data directory
    mov eax, [eax]              ; export data directory virtual address
    add r8, eax                 ; base addr + virtual addr

    mov r9, r8
    mov eax, [ebp - 24]         ; export data directory
    add eax, 4                  ; export data directory size
    mov eax, [eax]              ; export data directory size
    add r9, eax                 ; base addr + virtual addr + size

    cmp [ebp - 8], r8           ; below the start of the export directory
    jl .shutdown                ; not forwarded
                                ; or
    cmp [ebp - 8], r9           ; above the end of the export directory
    jg .shutdown                ; not forwarded

    ; make a copy of the string of the forwarded dll
    mov ecx, ebp
    sub ecx, 312
    mov edx, [ebp - 8]
    call strcpy

    ; find the position of the '.' which separates the dll name and function name
    mov ecx, ebp
    sub ecx, 312
    mov edx, '.'
    call strchr                 ; ptr to chr in eax
    
    mov byte [eax], 0
    inc eax

    mov [ebp - 320], eax        ; forwarded function name

    mov ecx, ebp
    sub ecx, 312
    call [loadlibrary]     ; library addr

    mov [ebp - 328], eax        ; library addr

    sub rsp, 32
    mov ecx, [ebp - 320]
    call strlen                 ; strlen in eax
    add rsp, 32

    mov [ebp - 336], eax        ; function name strlen

    mov ecx, [ebp - 328]
    mov edx, [ebp - 320]
    mov r8, [ebp - 336]
    call get_proc_address_by_name       ; proc addr

    mov [ebp - 8], eax          ; proc addr

.shutdown:
    mov ebx, [ebp - 300]                        ; restore ebx
    mov eax, [ebp - 4]                          ; return value

    add esp, 300                                ; free local variable space
    add esp, 12                                 ; free arg stack

    leave
    ret