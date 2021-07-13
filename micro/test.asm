
            inc     de
            ld      l, $fa
            ld      a, $AF
            ld      hl, $1234


            ld      bc, $4233
            ld      de, $FABA
            ld      sp, $BA40

            ld      (hl), a
            add     (hl)
            ld      (hl), $55
            inc     hl
