; ----------------------------------------------------------------------
; Пропечатка в буфер integer 16 битного
; Вход:  DE-входящие данные
; Выход: DE-указатель на полученную строку
; ----------------------------------------------------------------------

; Переменные
itoa_dt:    defb 6,5,5,3,5,0

; Процедура
itoa:       push    bc
            push    hl
            ld      hl, itoa_dt+4       ; Последний символ
            ld      bc, 10
itoal:      push    hl
            call    div16u              ; Разделить число на 10
            ld      a, l                ; Записать остаток в A
            add     a, '0'
            pop     hl
            ld      (hl), a             ; Запись числа '0'..'9' ASCII
            dec     hl
            ld      a, d
            or      e
            jr      nz, itoal           ; Повторять пока не будет 0
            inc     hl                  ; Восстановить указатель
            ex      de, hl              ; Поместить HL -> DE
            pop     hl
            pop     bc
            ret

; ----------------------------------------------------------------------
; Конвертация HL строки в DE данные; HL будет находится после последнего
; разобранного символа
; ----------------------------------------------------------------------

atoi:       push    af
            push    bc
            ld      de, $0000
atoil:      ld      a, (hl)
            sub     '0'
            jr      c, atoie
            cp      10
            jr      nc, atoie       ; '0' <= Acc <= '9'
            inc     hl
            push    hl
            ld      bc, 10
            call    mul16u          ; DE *= 10
            ex      de, hl
            ld      b, 0
            ld      c, a
            add     hl, bc
            ex      de, hl          ; DE = DE*10 + A
            pop     hl
            jr      atoil
atoie:      pop     bc
            pop     af
            ret

; ----------------------------------------------------------------------
; Чтение нажатия символа с ожиданием и выдача его в A
; ----------------------------------------------------------------------

getch:      push    bc
            push    hl

            ld      hl, keyb_spec
            in      a, ($ff)
            ld      b, a

            ; Ждать нажатия клавиши
getchl:     in      a, ($ff)
            cp      b
            jr      z, getchl
            ld      b, a

            ; Обработка нажатия клавиш
            in      a, ($fe)        ; Полученный символ
            cp      $11
            jr      nz, $+6         ; (skip 2 instr)
            set     0, (hl)         ; Левый SHIFT нажат
            jr      getchl

            cp      $11 + $80
            jr      nz, $+6         ; (skip 2 instr)
            res     0, (hl)         ; Левый SHIFT отпущен
            jr      getchl

            cp      $80
            jr      nc, getchl      ; Отпущенная клавиша не интересует

            ; Если SHIFT отпущен
            bit     0, (hl)
            jr      nz, getch1      ; Если SHIFT отпущен => AZ -> az
            cp      'A'
            jr      c, getch1       ; Acc < 'A', пропуск
            cp      'Z'+1
            jr      nc, getch1      ; Acc > 'Z', пропуск
            add     'a'-'A'         ; Коррекция Acc

            ; Если SHIFT зажат
getch1:     bit     0, (hl)
            jr      z, getch2

            ; Поиск символа с нажатым SHIFT (Z=0)
            ;
            ; hl = (uint8_t*) getchtrn;
            ; while (m = *hl) {
            ;   if (m == a) return *(hl+1);
            ;   hl += 2;
            ; }
            ; return a;

            ld      hl, getchtrn
getch3:     ld      c, a
            ld      a, (hl)
            and     a
            ld      b, a
            ld      a, c
            jr      z, getch2       ; Протестировать на конец таблицы
            inc     hl
            ld      c, (hl)
            inc     hl              ; Прочитать пару B -> C
            cp      b
            jr      nz, getch3      ; Повторить, пока не совпадёт
            ld      a, c

getch2:     pop     hl
            pop     bc
            ret

; Таблица трансляции SHIFT
getchtrn:   defb    '`', '~'
            defb    ',', '<'
            defb    '.', '>'
            defb    '/', '?'
            defb    ';', ':'
            defb    $27, '"'
            defb    '\\', '|'
            defb    '[', '{'
            defb    ']', '}'
            defb    '-', '_'
            defb    '=', '+'
            defb    '0', ')'
            defb    '1', '!'
            defb    '2', '@'
            defb    '3', '#'
            defb    '4', '$'
            defb    '5', '%'
            defb    '6', '^'
            defb    '7', '&'
            defb    '8', '*'
            defb    '9', '('
            defb    0
