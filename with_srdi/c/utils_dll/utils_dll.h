#ifndef UTILS_DLL_H
#define UTILS_DLL_H

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>

ULONG_PTR GetKernelAddr(void);
ULONG_PTR GetProcAddressAddr(ULONG_PTR ulModuleAddr);

#endif