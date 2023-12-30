section .data
STD_HANDLE_ENUM equ -11
INVALID_HANDLE_VALUE equ -1

xor_key: db '00000', 0
.len equ $ - xor_key - 1

kernel32_xor: db 0x5b, 0x55, 0x42, 0x5e, 0x55, 0x5c, 0x3, 0x2, 0x1e, 0x54, 0x5c, 0x5c, 0
.len equ $ - kernel32_xor - 1