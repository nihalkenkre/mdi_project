# Without sRDI

The `sniff` and `migrate` modules are exe compiled from the source code. The source code is arranged in a way that all the compiled code in in the text section, which can then be extracted into shellcode.

The modules source code make use of the [c_utils](https://github.com/nihalkenkre/c_utils) project.

The compiled code is then converted to shellcode and then to a C include file using the scripts in the [maldev_tools](https:github.com/nihalkenkre/maldev_tools.git).

Using folded hash values for string comparisons.

Heaven's Gate source code is compiled as an object file, and an `ExecuteRemoteThread` function is available to call from the C code.