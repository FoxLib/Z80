
        ld      a, $ff
        push    af
        ret
        ld      hl, $5800
        xor     a
L2:     dec     a
        ld      (hl), a
        inc     hl
        jr      nz, L2
        halt
