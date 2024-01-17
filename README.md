# MDI project - Sektor7
## Aim

This is targeted at `Veracrypt`, and the aim to get the password of the encrypted volume as the users enters it to mount the volume. 
It consists of an excutable which looks for a running OneDrive/Notepad(32 bit) process and injects the migrate payload into the process. This payload migrates from the 32 bit OneDrive/Notepad process to the 64 bit VeraCrypt and injects the hooking payload into the VeraCrypt.exe process.

## Sub modules
### Hook (vcsniff)
The `WideCharToMultiByte` function called by VeraCrypt is hooked into either by Inline Patching or by hooking into the Import Address Table.

### Migrate (32 bit to 64 bit) (vcmigrate)
Migrate the operation from the 32bit OneDrive/Notepad to the 64 bit VeraCrypt process by going through the "Heaven's Gate", and inject the hooking implant into VeraCrypt

### Persistance (vchelper)
An executable which looks for the OneDrive/Notepad(32 bit) process periodically, and when found injects the migration implant into the memory.

The `sniff` and `migrate` modules are dlls compiled from the source code and converted into position independent shell code using the [sRDI](https://github.com/monoxgas/sRDI) project.