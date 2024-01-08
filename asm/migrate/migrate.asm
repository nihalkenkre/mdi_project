section .text
global DllMain
export DllMain

global migrate
export migrate

%include '..\utils_32_text.asm'

; arg0: hInstance       rcx
; arg1: dwReason        rdx
; arg2: reserved        r8
;
; return: BOOL          rax
DllMain:
    push ebp
    mov ebp, esp

.shutdown:
    mov eax, 1

    leave
    ret


section .data

%include '../utils_32_data.asm'

section .bss