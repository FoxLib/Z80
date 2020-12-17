;
; ВИДЕОСЕРВИС DOS
; ----------------------------------------------------------------------
; Управление пикселями, рисование, очистка экрана и пр.
;
        push    af
        push    bc
        push    de
        push    hl

        ; ..

        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; ОЧИСТКА ЭКРАНА
; @param    A   атрибут очистки
; ----------------------------------------------------------------------

; @todo переделать на ldir

CLRSCR:

        push    hl
        push    bc
        push    de
        push    af

        ; Очистка области рисования
        xor     a   
        ld      hl, $4000
        ld      (hl), a
        ld      de, $4001
        ld      bc, $17FF
        ldir

        ; Установка атрибутов
        pop     af
        ld      h, d
        ld      l, e
        ld      (hl), a
        inc     de
        ld      bc, $2FF
        ldir

        pop     de
        pop     bc
        pop     hl
        ret

; Установить курсор на позицию B(y), C(x)
; ----------------------------------------------------------------------

CURSOR_SET:

        call    BLINK_HIDE
        ld      a, b
        ld      (TPCHRY), a
        ld      a, c
        ld      (TPCHRX), a
        call    BLINK_SHOW
        ret

; Обратить Blink в позиции TPCHRX и TPCHRY
; ----------------------------------------------------------------------

BLINK_TOGGLE:

        ld      a, (CURSOR_BLINKED)
        xor     1
BT1W:   ld      (CURSOR_BLINKED), a
        call    DO_BLINK_TOGGLE
        ret

; Скрыть курсор
; ----------------------------------------------------------------------

BLINK_HIDE:

        push    af
        xor     a
        ld      (TIMER_BLINK), a
        ld      a, (CURSOR_BLINKED)
        and     1
        jr      z, BLKAF    ; Если курсор уже исчез, ничего не делать
        xor     a
BLKEXT: call    BT1W        ; Иначе запись нового значения
BLKAF:  pop     af
        ret

; Показать курсор
; ----------------------------------------------------------------------

BLINK_SHOW:

        push    af
        ld      a, 12
        ld      (TIMER_BLINK), a
        ld      a, (CURSOR_BLINKED)
        and     1
        jr      nz,BLKAF    ; Если курсор уже показан, ничего не делать
        ld      a, 1
        jr      BLKEXT

; Выполнить XOR $F0 или $0F
; ----------------------------------------------------------------------

DO_BLINK_TOGGLE:

        call    CALC_CHAR_HL
        ld      b, 8
BT0R:   ld      a, (TPCHRX)
        and     1
        ld      a, $0F
        jr      nz, BT0Z
        ld      a, $F0
BT0Z:   xor     (hl)
        ld      (hl), a
        inc     h
        djnz    BT0R
        ret
