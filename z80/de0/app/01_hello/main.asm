
        org     $0000

        ; ------------------
RST_00: di                  ; 1
        xor     a           ; 1
        ld      hl, $ffff   ; 3
        jp      _start      ; 3
RST_08: defb    0,0,0,0,0,0,0,0
RST_10: defb    0,0,0,0,0,0,0,0
RST_18: defb    0,0,0,0,0,0,0,0
RST_20: defb    0,0,0,0,0,0,0,0
RST_28: defb    0,0,0,0,0,0,0,0
RST_30: defb    0,0,0,0,0,0,0,0

; RST #38 Пока что ничего не делает
; -----------------------------------------------------------------------

RST_38: ei
        ret

; -----------------------------------------------------------------------
_start:

        ld      a, $5B
        ld      hl, $5800
bb:     ld      (hl), $38
        inc     hl
        cp      h
        jr      nz, bb

        ld      bc, $0000
ab:     call    GET_GRAPHICS_ADDRESS
        ld      (hl), $FF
        inc     bc         
        jr      ab

; B  - Y=0..23, C - X=0..31 (вход) ==> HL (выход)
GET_GRAPHICS_ADDRESS:

        ld      a, c
        and     0x1F    ; L[0..4] = X >> 3
        ld      l, a    ; Y[0..2]
        ld      a, b
        and     0x07
        ld      h, a    ; Установка => H[0..2]
        ld      a, b    ; Y[3..5]
        and     0x38
        rlca
        rlca
        or      l
        ld      l, a    ; Ставится в L[5..7]
        ld      a, b
        and     0xC0
        rrca
        rrca
        rrca
        or      h
        or      0x40    ; H устанавливается на видеопамять
        ld      h, a    ; Y[6..7] ставится в H[3..4]
        ret

