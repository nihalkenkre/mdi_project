package main

import (
	"fmt"
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

func main() {
	kernel32_xor := []byte{0x5b, 0x55, 0x42, 0x5e, 0x55, 0x5c, 0x3, 0x2, 0x1e, 0x54, 0x5c, 0x5c, 0x0}
	xor_key := []byte{0x30, 0x30, 0x30, 0x30, 0x30}

	MyXor(&kernel32_xor, uint64(len(kernel32_xor)-1), &xor_key, uint64(len(xor_key)))
}
