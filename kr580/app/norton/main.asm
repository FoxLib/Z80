
            org     $5B00

; ========== NORTON COMMANDER ======

            ; Перерисовать панели
            ld      hl, $8283
            ld      d,  $80
            call    bar

            ld      b, 44
M3:         ld      a, $81
            rst     $08

            ld      a, $00  ; Передвинуть курсор
            rst     $10
            ld      a, l
            add     14
            ld      l, a
            ld      a, 1
            rst     $10

            ld      a, $81
            rst     $08
            djnz    M3

            ld      hl, $8485
            ld      d,  $80
            call    bar
            jr      $

; -------------------
bar:        push    bc
            ld      c, 2
M2:         ld      a, h ; 0x82
            rst     $08
            ld      b, 14
            ld      a, d ; 0x80
M1:         rst     $08
            djnz    M1
            ld      a, l ; 0x83
            rst     $08
            dec     c
            jr      nz, M2
            pop     bc
            ret
