#include "utils_dll.h"

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <winternl.h>

typedef struct _peb_ldr_data
{
    BYTE Dummy[32];
    LIST_ENTRY InMemoryOrderModuleList;
} MY_PEB_LDR_DATA;

typedef struct _peb
{
    BYTE Dummy[16];
    PVOID64 ImageBaseAddress;
    MY_PEB_LDR_DATA *Ldr;
} MY_PEB;

typedef struct _unicode_string
{
    USHORT Length;
    USHORT MaxLength;
    PWSTR Buffer;
} MY_UNICODE_STRING, *PMY_UNICODE_STRING;

typedef struct _ldr_data_table_entry
{
#ifdef _M_X64
    BYTE Dummy[48];
    PVOID64 pvDllBase;
    PVOID64 EntryPoint;
    DWORD64 SizeOfImage;
#else
    BYTE Dummy[24];
    PVOID pvDllBase;
    PVOID EntryPoint;
    DWORD32 SizeOfImage;
#endif
    MY_UNICODE_STRING FullDllName;
    MY_UNICODE_STRING BaseDllName;
} MY_LDR_DATA_TABLE_ENTRY;

size_t MyStrLen(CHAR *str)
{
    size_t strlen = 0;
    while (*str++ != 0)
    {
        ++strlen;
    }

    return strlen;
}

void MyXor(BYTE *data, SIZE_T data_len, BYTE *key, SIZE_T key_len)
{
    DWORD32 j = 0;

    for (SIZE_T i = 0; i < data_len; ++i)
    {
        if (j == key_len)
            j = 0;

        BYTE bInput = 0;

        for (BYTE b = 0; b < 8; ++b)
        {
            BYTE data_bit_i = _bittest((LONG *)&data[i], b);
            BYTE key_bit_j = _bittest((LONG *)&key[j], b);

            BYTE bit_xor = (data_bit_i != key_bit_j) << b;

            bInput |= bit_xor;
        }

        data[i] = bInput;

        ++j;
    }
}

BOOL MyStrCmpiAA(CHAR *sStr1, CHAR *sStr2)
{
    BOOL bAreEqual = TRUE;

    size_t sStr1Len = MyStrLen(sStr1);
    size_t sStr2Len = MyStrLen(sStr2);

    if (sStr1Len > sStr2Len)
    {
        for (size_t c = 0; c < MyStrLen(sStr1); ++c)
        {
            if (sStr1[c] != sStr2[c])
            {
                if (sStr1[c] < sStr2[c])
                {
                    if ((sStr1[c] + 32) != sStr2[c])
                    {
                        bAreEqual = FALSE;
                        break;
                    }
                }
                else if (sStr2[c] < sStr1[c])
                {
                    if ((sStr2[c] + 32) != sStr1[c])
                    {
                        bAreEqual = FALSE;
                        break;
                    }
                }
            }
        }
    }
    else
    {
        for (size_t c = 0; c < MyStrLen(sStr2); ++c)
        {
            if (sStr1[c] != sStr2[c])
            {
                if (sStr1[c] < sStr2[c])
                {
                    if ((sStr1[c] + 32) != sStr2[c])
                    {
                        bAreEqual = FALSE;
                        break;
                    }
                }
                else if (sStr2[c] < sStr1[c])
                {
                    if ((sStr2[c] + 32) != sStr1[c])
                    {
                        bAreEqual = FALSE;
                        break;
                    }
                }
            }
        }
    }

    return bAreEqual;
}

BOOL MyStrCmpiAW(CHAR *sStr1, WCHAR *sStr2)
{
    BOOL bAreEqual = TRUE;

    for (size_t c = 0; c < MyStrLen(sStr1); ++c)
    {
        if (sStr1[c] != sStr2[c])
        {
            if (sStr1[c] < sStr2[c])
            {
                if ((sStr1[c] + 32) != sStr2[c])
                {
                    bAreEqual = FALSE;
                    break;
                }
            }
            else if (sStr2[c] < sStr2[c])
            {
                if ((sStr2[c] + 32) != sStr1[c])
                {
                    bAreEqual = FALSE;
                    break;
                }
            }
        }
    }

    return bAreEqual;
}

ULONG_PTR GetKernelAddr(void)
{
#ifdef _M_X64
    PEB *pPeb = (PEB *)__readgsqword(0x60);
#else
    PEB *pPeb = (PEB *)__readfsdword(0x30);
#endif

    LIST_ENTRY *FirstListEntry = &pPeb->Ldr->InMemoryOrderModuleList;
    LIST_ENTRY *CurrentListEntry = FirstListEntry->Flink;

    CHAR *key = "00000";
    short key_len = 5;

    BYTE cKernelDLL[] = {0x5b, 0x55, 0x42, 0x5e, 0x55, 0x5c, 0x3, 0x2, 0x1e, 0x54, 0x5c, 0x5c, 0};
    MyXor(cKernelDLL, 12, (BYTE *)key, key_len);

    while (CurrentListEntry != FirstListEntry)
    {
        MY_LDR_DATA_TABLE_ENTRY *TableEntry = (MY_LDR_DATA_TABLE_ENTRY *)((ULONG_PTR)CurrentListEntry - sizeof(LIST_ENTRY));

        if (MyStrCmpiAW((CHAR *)cKernelDLL, TableEntry->BaseDllName.Buffer))
        {
            return (ULONG_PTR)TableEntry->pvDllBase;
        }

        CurrentListEntry = CurrentListEntry->Flink;
    }

    return 0;
}

ULONG_PTR GetProcAddressAddr(ULONG_PTR ulModuleAddr)
{
    char *key = "00000";
    short key_len = 5;

    char sProcName[] = {0x77, 0x55, 0x44, 0x60, 0x42, 0x5f, 0x53, 0x71, 0x54, 0x54, 0x42, 0x55, 0x43, 0x43, 0};
    MyXor(sProcName, 14, key, key_len);

    IMAGE_DOS_HEADER *DosHeader = (IMAGE_DOS_HEADER *)ulModuleAddr;
    IMAGE_NT_HEADERS *NTHeaders = (IMAGE_NT_HEADERS *)(ulModuleAddr + DosHeader->e_lfanew);

    IMAGE_DATA_DIRECTORY ExportDataDirectory = NTHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT];
    IMAGE_EXPORT_DIRECTORY *ExportDirectory = (IMAGE_EXPORT_DIRECTORY *)(ulModuleAddr + ExportDataDirectory.VirtualAddress);

    DWORD *AddressOfFunctions = (DWORD *)(ulModuleAddr + ExportDirectory->AddressOfFunctions);
    DWORD *AddressOfNames = (DWORD *)(ulModuleAddr + ExportDirectory->AddressOfNames);
    WORD *AddressOfNameOridinals = (WORD *)(ulModuleAddr + ExportDirectory->AddressOfNameOrdinals);

    ULONG_PTR lpvProcAddr = 0;

    for (DWORD n = 0; n < ExportDirectory->NumberOfNames; ++n)
    {
        if (MyStrCmpiAA(sProcName, (CHAR *)(ulModuleAddr + AddressOfNames[n])))
        {
            lpvProcAddr = (ulModuleAddr + AddressOfFunctions[AddressOfNameOridinals[n]]);
            break;
        }
    }

    return lpvProcAddr;
}
