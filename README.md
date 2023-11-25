# Malware Development
## Aim

This is targeted at `Veracrypt`, and the aim to get the password of the encrypted volume as the users enters it to mount the volume. 
It consists of an excutable which looks for a running OneDrive process and injects the migrate payload into the process. This payload migrates from the 32 bit process OneDrive process to the 64 bit VeraCrypt and injects the hooking payload into the VeraCrypt process.

## Sub modules
### Hook (vcsniff)
The `WideCharToMultiByte` function called by VeraCrypt is  hooked into either by Inline Patching or by hooking the Import Address Table.

### Migrate (32 bit to 64 bit) (vcmigrate)
Migrate the operation from the 32bit OneDrive to the 64 bit VeraCrypt process by going through the "Heaven's Gate", and inject the hooking implant into VeraCrypt

### Persistance (vchelper)
An executable whichs looks for the OneDrive process periodically, and when found injects the migration implant into the memory.

The `vcsniff` and `vcmigrate` modules are dlls compiled from C source and then converted into position independent shell code using the [sRDI](https://github.com/monoxgas/sRDI) project.