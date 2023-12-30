section .data
STD_HANDLE_ENUM equ -11
INVALID_HANDLE_VALUE equ -1

xor_key: db '00000', 0
.len equ $ - xor_key - 1