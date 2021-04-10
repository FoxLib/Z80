const char* ds_mnemonics[256] = {

    /* 00 */    "nop",  "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "rlca",
    /* 08 */    "ex",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "rrca",
    /* 10 */    "djnz", "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "rla",
    /* 18 */    "jr",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "rra",
    /* 20 */    "jr",   "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "daa",
    /* 28 */    "jr",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "cpl",
    /* 30 */    "jr",   "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "scf",
    /* 38 */    "jr",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "cpl",

    /* 40 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 48 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 50 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 58 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 60 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 68 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 70 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "halt",  "ld",
    /* 78 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",

    /* 80 */    "add",  "add",  "add",  "add",  "add",  "add",  "add",  "add",
    /* 88 */    "adc",  "adc",  "adc",  "adc",  "adc",  "adc",  "adc",  "adc",
    /* 90 */    "sub",  "sub",  "sub",  "sub",  "sub",  "sub",  "sub",  "sub",
    /* 98 */    "sbc",  "sbc",  "sbc",  "sbc",  "sbc",  "sbc",  "sbc",  "sbc",
    /* A0 */    "and",  "and",  "and",  "and",  "and",  "and",  "and",  "and",
    /* A8 */    "xor",  "xor",  "xor",  "xor",  "xor",  "xor",  "xor",  "xor",
    /* B0 */    "or",   "or",   "or",   "or",   "or",   "or",   "or",   "or",
    /* B8 */    "cp",   "cp",   "cp",   "cp",   "cp",   "cp",   "cp",   "cp",

    /* C0 */    "ret",   "pop", "jp",   "jp",   "call", "push", "add",  "rst",
    /* C8 */    "ret",   "ret", "jp",   "$",    "call", "call", "adc",  "rst",
    /* D0 */    "ret",   "pop", "jp",   "out",  "call", "push", "sub",  "rst",
    /* D8 */    "ret",   "exx", "jp",   "in",   "call", "$",    "sbc",  "rst",
    /* E0 */    "ret",   "pop", "jp",   "ex",   "call", "push", "and",  "rst",
    /* E8 */    "ret",   "jp",  "jp",   "ex",   "call", "$",    "xor",  "rst",
    /* F0 */    "ret",   "pop", "jp",   "di",   "call", "push", "or",   "rst",
    /* F8 */    "ret",   "ld",  "jp",   "ei",   "call", "$",    "cp",   "rst"
};

const char* ds_reg8[3*8] = {
    "b", "c", "d", "e", "h",   "l",   "(hl)", "a",
    "b", "c", "d", "e", "ixh", "ixl", "$",    "a",
    "b", "c", "d", "e", "iyh", "iyl", "$",    "a"
};

const char* ds_reg16[3*4] = {

    "bc", "de", "hl", "sp",
    "bc", "de", "ix", "sp",
    "bc", "de", "iy", "sp"
};

const char* ds_reg16af[3*4] = {

    "bc", "de", "hl", "af",
    "bc", "de", "ix", "af",
    "bc", "de", "iy", "af"
};

const char* ds_cc[8] = {

    "nz", "z", "nc", "c",
    "po", "pe", "p", "m"
};

const char* ds_bits[8] = {

    "rlc", "rrc", "rl", "rr",
    "sla", "sra", "sll", "srl",
};

const int ds_im[8] = {0, 0, 1, 2, 0, 0, 1, 2};
