;
; СЕРВИСНОЕ ПРЕРЫВАНИЕ ДЛЯ ПЕЧАТИ СИМВОЛА
; ----------------------------------------------------------------------
; ВХОД: A - Символ для печати
;
        push    bc
        push    de
        push    hl
        push    af

        cp      $0A                 ; Перевод каретки вниз
        jp      z, CARETS
        call    PRNCHR              ; Печать символа A
        ld      a, (TPCHRX)         ; X++
        inc     a
        cp      $40
        jr      nz, PC0E            ; К следующей X

CARETS: ld      a, (TPCHRY)         ; Y++
        inc     a
        cp      $18
        call    z, SCROLL           ; Скроллинг вниз
        ld      (TPCHRY), a         ; Y = Y < $18 ? Y + 1 : $17
        xor     a                   ; X = 0
PC0E:   ld      (TPCHRX), a

        pop     af
        pop     hl
        pop     de
        pop     bc
        ret

; ПРОПЕЧАТКА СИМВОЛА
; ----------------------------------------------------------------------

PRNCHR:

        ld      c, a                ; Сохранить символ A в C
        call    CALC_CHAR_HL

        ; Расчет позиции символа
        ; DE = 8 * (C >> 1) + ANSI_offset
        ; ------------------------------

        push    hl
        ld      a, c
        and     a                   ; CF=0
        rra
        ld      h, 0
        ld      l, a
        ld      de, ansi - 128      ; Чтобы смещение было правильное
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, de              ; Рассчитать смещение
        ex      de, hl
        pop     hl

        ; Вывод символа (DE источник HL указатель на видеопамять)
        ld      b, 8
P0X:    ld      a, (TPCHRX)
        and     $01
        ld      a, (hl)
        jr      z, P1L

        ; Случай 1: x % 2 == 1
        and     $F0
        ld      (hl), a
        call    P2LR
        jr      P2E

        ; Случай 2: x % 2 == 0
P1L:    and     $0F
        ld      (hl), a
        call    P2LR
        rla
        rla
        rla
        rla

        ; Смешивание масок, запись в память
P2E:    or      (hl)
        ld      (hl), a
        inc     de
        inc     h
        djnz    P0X

        ret

; ----------------------------------------------------------------------
; LD A, (DE) и потом, в зависимости от C & 1, запись его
; в левый или правый ниббл

P2LR:   ld      a, c
        rra
        ld      a, (de)
        jr      nc, P2LR0
        and     $0F             ; c & 1 = 0, берем нижние биты
        ret
P2LR0:  and     $F0             ; c & 1 = 1, берем старшие биты
        rra
        rra
        rra
        rra
        ret

; СКРОЛЛИНГ ЭКРАНА НА 1 ПОЗИЦИЮ ВНИЗ
; ----------------------------------------------------------------------

SCROLL:

        push    hl
        push    de
        push    bc

        ; Первая половина
        ld      hl, $4020
        ld      de, $4000
        ld      bc, $0800
        push    bc
        ldir
        ld      hl, $40E0
        call    SC2R
        pop     bc

        ; Вторая половина
        ld      de, $4800
        ld      hl, $4820
        push    bc
        ldir
        ld      hl, $48E0
        call    SC2R

        ; Убрать знакоместа с первой строки
        xor     a
        ld      ($5800), a
        ld      bc, $1F
        ld      de, $5801
        ld      hl, $5800
        ldir

        ; Третья половина
        pop     bc
        ld      de, $5000
        ld      hl, $5020
        ldir

        ; Сдвиг знакомест
        ld      hl, $5820
        ld      bc, 768 - $20
        ldir

        ; Очистка нижнего блока
        ld      l, $E0
S5X:    ld      h, $50
S5Y:    xor     a
        ld      (hl), a
        inc     h
        ld      a, h
        cp      $58
        jr      nz, S5Y
        inc     l
        jr      nz, S5X

        ; Возврат к программе
        pop     bc
        pop     de
        pop     hl

        ld      a, $17
        ret

; ----------------------------------------------------------------------
; Сдвиг 1 строки, DE -> HL
SC2R:   ld      c, $20
SC1B:   push    hl
        push    de
        ld      b, 8
SC1A:   ld      a, (de)
        ld      (hl), a
        inc     h
        inc     d
        djnz    SC1A
        pop     de
        pop     hl
        inc     l
        inc     e
        dec     c
        jr      nz, SC1B
        ret

; Расчет позиции HL по TPCHRY и TPCHRX
; @affect A, HL
; ----------------------------------------------------------------------

CALC_CHAR_HL:

        ; Вычисление позиции Y
        ; ------------------------------

        ld      a, (TPCHRY)
        ld      h, a
        and     $07
        rrca
        rrca
        rrca
        ld      l, a                ; L = (Y & $07) << 5
        ld      a, h
        and     $38
        or      $40
        ld      h, a                ; H = (Y & $38) | $40

        ; Расчет позиции X
        ; ------------------------------

        ld      a, (TPCHRX)
        and     $3F
        rra
        or      l
        ld      l, a                ; L |= ((X & $3F) >> 1)
        ret
