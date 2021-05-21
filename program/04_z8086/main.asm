
            ; Эмулятор, понимаешь
            org     8000h-3
            jp      START

; ======================================================================
VECTABLE:   defb    0
MODRM:      defb    0
; ======================================================================

START:      ld      de, PROGRAM
            ld      c, $20

fetch_opcode:

            ; 37T
            ld      l, a            ; 4
            ld      h, VECTABLE/256 ; 7
            ld      c, (hl)         ; 7
            inc     h               ; 4
            ld      h, (hl)         ; 7
            ld      l, c            ; 4
            jp      (hl)            ; 4

PROGRAM:    defb    $00,$c0,$03
