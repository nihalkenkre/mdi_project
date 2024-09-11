# MDI project - Sektor7
## Aim

This is targeted at `Veracrypt`, and the aim to get the password of the encrypted volume as the users enters it to mount the volume.
It consists of an excutable which looks for a running OneDrive/Notepad(32 bit) process and injects the migrate payload into the process. This payload migrates from the 32 bit OneDrive/Notepad process to the 64 bit VeraCrypt and injects the hooking payload into the `VeraCrypt.exe` process.

## Modules
### Hook (sniff)
The `WideCharToMultiByte` function called by VeraCrypt is hooked into either by Inline Patching or by hooking into the Import Address Table.

### Migrate (32 bit to 64 bit) (migrate)
Migrate the operation from the 32bit OneDrive/Notepad to the 64 bit VeraCrypt process by going through the "Heaven's Gate", and inject the hooking implant into VeraCrypt

### Persistance (helper)
An executable which looks for the OneDrive/Notepad(32 bit) process periodically, and when found injects the migration implant into the memory.

The project is created using [sRDI](https://github.com/monoxgas/sRDI) and without sRDI, using C, ASM and Go, and using [sexe](https://medium.com/@nihal.kenkre/sexe-small-exe-e2f8b9acc805).