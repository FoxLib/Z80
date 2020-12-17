
dw_cursor:      equ $5B00

; ----------------------------------------------------------------------
; Сброс процессора
; ----------------------------------------------------------------------

RST_00: di
        ld      a, 0x07
        jp      _start

; ----------------------------------------------------------------------
; Вычисление видеоадреса
; ----------------------------------------------------------------------

getTextCursor:

        ld      a, c
        and     0x1F
        ld      l, a    ; L = X & 31
        ld      a, b
        and     0x07    ; Нужно ограничить 3 битами
        rrca            ; Легче дойти с [0..2] до позиции [5..7]
        rrca            ; Если вращать направо
        rrca            ; ... три раза
        or      l       ; Объединив с 0..4 уже готовыми ранее
        ld      l, a    ; Загрузить новый результат в L
        ld      a, b    ; Т.к. Y[3..5] уже на месте
        and     0x18    ; Его двигать даже не надо
        or      0x40    ; Ставим видеоадрес $4000
        ld      h, a    ; И загружаем результат
        ret

; ----------------------------------------------------------------------
; Печать символа на экране
; Вход: B(y=0..23), C(x=0..31) A(символ)
; ----------------------------------------------------------------------

printChar:

        push    bc
        push    de
        push    hl
        sub     0x20        ; A = Sym - 0x20
        ld      h, 0        ; HL = A
        ld      l, a
        add     hl, hl
        add     hl, hl
        add     hl, hl      ; HL = A << 3
        ld      a, h
        add     0x3D
        ld      h, a        ; HL += 0x3D00
        ex      de, hl        ; DE теперь тут
        call    getTextCursor ; HL=Адрес видеопамяти
        ld      B, 8          ; Повторить 8 раз
PC1:    ld      A, (de)     ; Прочитать 8 бит
        ld      (hl), A     ; Записать 8 бит
        inc     h           ; Y = Y + 1 согласно модели памяти
        inc     de          ; К следующему байту
        djnz    PC1         ; Рисовать 8 строк
        pop     hl
        pop     de
        pop     bc
        ret

; ----------------------------------------------------------------------
; Прерывание RST #38
; ----------------------------------------------------------------------

RST_38: push    af
        push    bc
        push    de
        push    hl
        ; Ничего не происходит здесь
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        ret

; ----------------------------------------------------------------------
; Старт программы
; ----------------------------------------------------------------------

_start:

        ld      a, 0x38
        ld      bc, 0x02FF
        ld      hl, 0x5800  ; Отсюда копировать
        ld      de, 0x5801  ; Сюда
        ld      (hl), a     ; Байт инициализации
        ldir                ; Копировать из (HL) -> (DE), HL++, DE++
        xor     a
        ld      hl, 0x4000
        ld      de, 0x4001
        ld      bc, 0x17FF
        ldir                ; Очистить графическую область

        ld      bc, $0000
        ld      (dw_cursor), bc

        ; Печать строки
        ld      hl, ds_alu_test
        call    printStringTeletype

        call    ALU_test

        jr      $

; ----------------------------------------------------------------------
; Печать в телетайповом режиме
; HL - строка
; ----------------------------------------------------------------------

printStringTeletype:

PST1:   ld      a, (hl)
        inc     hl
        and     a
        ret     z
        call    printCharTeletype
        jr      PST1

; ----------------------------------------------------------------------
; Печать символа в режиме телетайпа
; A - вход
; ----------------------------------------------------------------------

printCharTeletype:

        ld      bc, (dw_cursor)
        cp      $0A
        jr      z, PCTNL
        call    printChar
        inc     c
        ld      a, c
        cp      $20
        jr      nz, PCT1
PCTNL:  ld      c, 0
        inc     b
        ld      a, b
        cp      $18
        jr      nz, PCT1
        ld      b, $17
        call    doScrollUp
PCT1:   ld      (dw_cursor), bc
        ret

; ----------------------------------------------------------------------
; СКРОЛЛИНГ ЭКРАНА НА 1 ПОЗИЦИЮ ВНИЗ
; ----------------------------------------------------------------------

doScrollUp:

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
        ret

; ------------------------
; Сдвиг 1 строки, DE -> HL
; ------------------------

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

; ----------------------------------------------------------------------
; ТЕСТ АЛУ ИНСТРУКЦИИ
; ----------------------------------------------------------------------
ALU_test:

        ld      hl, ALU_testcase
        ld      b, (hl)
        inc     hl

ALU_test_loop:

        call    ALU_test_next

        ; Исполнимая тестовая инструкция в данный момент
        add     c

        push    af
        pop     de
        ld      a, d
        cp      (hl)
        jr      nz, ALU_test_fail
        inc     hl
        ld      a, e
        cp      (hl)
        jr      nz, ALU_test_fail
        inc     hl
        djnz    ALU_test_loop
        ld      hl, ds_OK

ALU_test_end:

        call    printStringTeletype
        ret

ALU_test_fail:

        ld      hl, ds_FAIL
        jr      ALU_test_end

; Извлечь следующий набор для теста
ALU_test_next:

        ld      d, (hl)
        inc     hl
        ld      e, (hl)
        inc     hl
        push    de
        pop     af
        ld      c, (hl)
        inc     hl
        ret

ALU_testcase:

        defb    3

        ;       A     F     Op    A'    F'
        defb    0x44, 0x23, 0x80, 0xC4, 0x80
        defb    0xAE, 0xFE, 0x12, 0xC0, 0x90
        defb    0x7F, 0xFA, 0x02, 0x81, 0x94

; ----------------------------------------------------------------------
; Строки
; ----------------------------------------------------------------------

ds_alu_test: defb "ALU instructions... ", 0
ds_OK:       defb "OK-3", 10, 0
ds_FAIL:     defb "FAIL", 10, 0
