#include <stdio.h>
#include <Windows.h>

int main()
{
    HMODULE hSniff = LoadLibraryA("sniff.dll");

    printf("%p %d\n", hSniff, GetLastError());

    return 0;
}