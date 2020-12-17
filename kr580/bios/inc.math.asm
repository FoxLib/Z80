; ----------------------------------------------------------------------
; Деление DE на BC (16 bit)
; DE-результат | HL-остаток
; ----------------------------------------------------------------------

div16u:     push    af
            push    de
            exx
            pop     hl
            exx
            ld      hl, $0000
            ld      d, h
            ld      e, l
            ld      a, 16
div16ul:    push    af
            exx
            add     hl, hl
            exx
            adc     hl, hl
            sla     e                   ; Сдвиг DE (результата)
            rl      d
            inc     e                   ; Выставить 1 по умолчанию
            xor     a                   ; CF = 0
            sbc     hl, bc              ; HL = HL - BC
            jr      nc, div16us         ; HL < BC ? Если нет, пропуск
            add     hl, bc              ; Восстановить HL
            dec     e                   ; Убрать 1 -> 0
div16us:    pop     af
            dec     a
            jr      nz, div16ul
            pop     af
            ret

; ----------------------------------------------------------------------
; Перевод unsigned int HL -> float DE:BC
; ----------------------------------------------------------------------

uitof:      ld      a, h
            or      l
            jr      z, uitofz   ; Проверка на ноль
            push    hl
            ld      de, $7e00
            ld      bc, $0000
uitofl:     srl     h           ; Заполнение мантиссы
            rr      l
            rr      e
            rr      b
            rr      c           ; e:b:с мантисса
            inc     d           ; Увеличение порядка
            ld      a, h
            or      l
            jr      nz, uitofl
            ld      a, e        ; Компоновка экспоненты
            and     $7f         ; Срезать скрытый бит
            srl     d           ; Сдвинуть направо
            jr      nc, $+4     ; CF=0, E[7]=0
            or      $80         ; CF=1, E[7]=1
            ld      e, a
            pop     hl
            ret
uitofz:     ld      d, a        ; Обнуление float
            ld      e, a
            ld      b, a
            ld      c, a
            ret

; ----------------------------------------------------------------------
; DE:BC (float) -> HL (uint) Беззнаковый
; В DE:BC остается дробная часть
; ----------------------------------------------------------------------

uftoi:      ld      hl, $0000   ; Результат
            ld      a, e
            add     a           ; Сдвиг E, чтобы получить D
            rl      d           ; D-экспонента
            set     7, e        ; Восстановить скрытый бит
uftoil:     ld      a, d
            cp      $7f
            ret     c           ; Это значение меньше 1, HL=0
            sla     c
            rl      b
            rl      e
            rl      l
            rl      h
            dec     d
            jr      uftoil      ; Повторять пока e >= $7F

; ----------------------------------------------------------------------
; Преобразовать число HL в негативное (HL=-HL), AF=0
; ----------------------------------------------------------------------

negate:     push    de
            ex      de, hl
            xor     a
            ld      h, a
            ld      l, a
            sbc     hl, de
            pop     de
            ret

; ----------------------------------------------------------------------
; Умножение DE на BC (16 bit)
; HL:DE-результат
; ----------------------------------------------------------------------

mult32r:    defw    0, 0

mul16u:     push    bc
            push    af

            ld      a, 16
            ld      hl, $0000
            ld      (mult32r), hl
            ld      (mult32r+2), hl

            ; Пересчитать 16 бит (максимум)
mul16ul:    push    af
            ld      a, b
            or      c
            jr      z, mul16ule     ; Не считать старшие незначимые разряды

            ; Проверка следующего бита
            srl     b
            rr      c
            jr      nc, mul16us

            ; Сложить RES32 += HL:DE
            push    bc
            push    de
            push    hl
            ex      de, hl
            ld      bc, (mult32r)
            add     hl, bc
            ld      bc, (mult32r+2)
            ex      de, hl
            adc     hl, bc
            ld      (mult32r), de
            ld      (mult32r+2), hl
            pop     hl
            pop     de
            pop     bc

            ; Умножение HL:DE на 2
mul16us:    sla     e
            rl      d
            adc     hl, hl
            pop     af
            dec     a
            jr      nz, mul16ul

            ; Выгрузка результата
mul16uls:   ld      hl, (mult32r+2)
            ld      de, (mult32r)
            pop     af
            pop     bc
            ret

mul16ule:   pop     af
            jr      mul16uls
