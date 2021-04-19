
        ld      ($1234), hl
L1:
        dec     (hl)
        jr      L1
        halt
