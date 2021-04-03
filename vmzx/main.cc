#include <stdio.h>

#include "z80.cc"
#include "machine.cc"

int main(int argc, char* argv[]) {

    Z80Spectrum speccy(1);

    speccy.args(argc, argv);
    speccy.main();

    return 0;
}
