
        ld      hl, $5aff
        ld      a, $38
L2:
        ld      (hl), a
        jr      L2

        ld      c, $57
L1:     ld      (hl), a
        dec     l
        jr      nz, L1
        dec     h
        ;ld      b, a
        ;cp      a, c
        ;ld      a, b
        jr      nz, L1
        halt
