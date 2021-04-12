
        org     8000h
        ld      b, 64
        ld      a, 0x21
L1:     push    af
        rst     $10
        pop     af
        inc     a
        djnz    L1
        jr      $+0
