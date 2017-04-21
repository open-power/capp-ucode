This is the CAPP microcode for POWER8 and POWER9 systems.

This needs to be loaded into the CAPP unit on a POWER8 or POWER9 using
skiboot for a system to use CAPI.

Build script here formats the different ucodes into the hostboot SBE
format so that skiboot can parse them.

To build, do:

   ./build.sh

Which will create a single file cappucode.bin.
