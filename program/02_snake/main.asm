
            org     6000h
 TIMINGS:   equ     20

            ; Создание таблицы векторов прерываний $fdfd
            di
            ld      a, 1
            out     ($fe), a
            ld      sp, $ff04
            ld      hl, $fdfd
            ld      b, 129
mkim2:      push    hl
            push    hl
            djnz    mkim2

            ; Очистка атрибутов
            ld      sp, $5b00
            ld      hl, $0707
            ld      b, 192
clsh:       push    hl
            push    hl
            djnz    clsh

            ; Очистка бинарной области
            ld      hl, $0000
            ld      bc, $000c
clsl:       push    hl
            djnz    clsl
            dec     c
            jr      nz, clsl

            ; Назначение обработчика прерываний
            ld      a, $c3
            ld      ($fdfd), a
            ld      hl, irq
            ld      ($fdfe), hl

            ; Координата змеи [y,x]
            ld      hl, $0808
            ld      (snakedata), hl

            ; Включение прерывания
            ld      a, $fe
            ld      i, a
            ld      sp, 0
            im      2
            ei

            ; Вечный цикл
            jr      $

; ----------------------------------------------------------------------
drawchar:   ; A - рисовать символ в позиции BC
            sub     0x20
            ld      h, 0
            ld      l, a
            add     hl, hl
            add     hl, hl
            add     hl, hl
            ld      a, h
            add     0x3d
            ld      h, a
            ex      de, hl
            ld      a, c
            and     0x1F
            ld      l, a
            ld      a, b
            and     0x07
            rrca
            rrca
            rrca
            or      l
            ld      l, a
            ld      a, b
            and     0x18
            or      0x40
            ld      h, a
            ld      b, 8
drawchar2:  ld      a, (de)
            ld      (hl), a
            inc     h
            inc     de
            djnz    drawchar2
            ret

; ----------------------------------------------------------------------
; Главный обработчик прерывания 50 герц
; ----------------------------------------------------------------------

irq:
            ; Срабатывает не сразу
            ld      hl, sn_dec
            dec     (hl)
            jr      nz, irq_exit
            ld      a, TIMINGS
            ld      (hl), a

            ; Удаление хвоста
            ld      hl, (idx_tail)      ; Индекс хвоста [0..767]
            ld      c, (hl)
            inc     hl
            ld      b, (hl)             ; bc=snake[idx_tail]
            inc     hl
            ; --- проверка на превышение
            ld      (idx_tail), hl      ; idx_tail++
            ld      a, ' '
            call    drawchar            ; Удалить хвост

            ld      hl, (idx_begin)     ; Индекс головы [0..767]
            ld      e, (hl)
            inc     hl
            ld      d, (hl)             ; de=snake[idx_begin]
            inc     hl
            ; -- проверка на превышение?
            ld      (idx_begin), hl     ; idx_begin++
            ld      hl, (sn_dir)
            add     hl, de              ; К следующему
            ; --- тест на превышение
            ex      de, hl
            ld      hl, (idx_begin)
            ld      (hl), e
            inc     hl
            ld      (hl), d             ; Записать новый адрес
            ld      b, d
            ld      c, e
            ld      a, 0x7f
            call    drawchar            ; Нарисовать на новом месте

irq_exit:
            ei
            ret

sn_dec:     defb    1
idx_tail:   defw    snakedata
idx_begin:  defw    snakedata
sn_dir:     defw    0x0001

snakedata:
