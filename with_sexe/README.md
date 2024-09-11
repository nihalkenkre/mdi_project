# With SEXE

The `sniff` and `migrate` modules are implemented as a [sexe](https://medium.com/@nihal.kenkre/sexe-small-exe-e2f8b9acc805) file.

The `helper` module is implemented as a `C` executable, which loads the migrate sexe file in its memory and executes it in a separate thread.