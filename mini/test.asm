
            ld  hl, $0000
            ld  a, $12
            ld  (hl), a
            add (hl)
            ld  (hl), $55
            inc hl
