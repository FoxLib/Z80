
; ----------------------------------------------------------------------
; Вычисление выражения HL => DE-результат
; AFFECTED: AF, BC
; ----------------------------------------------------------------------

; Уровень 1: Минус, плюс, логические операции
; ----------------------------------------------------------------------
stack_expr: defw    0                   ; Для быстрого возврата ERROR
expr_errno: defb    0                   ; Код ошибки
expr_init:  ld      de, 0
            push    hl
            ld      h, e
            ld      l, e
            ld      a, e
            add     hl, sp
            ld      (stack_expr), hl    ; Сохранить указатель стека
            ld      (expr_errno), a
            pop     hl

; Начать вычисления
; -----------------------------------------------------------------------
expr:       call    expr1               ; Левая часть
expr_n:     ld      a, (hl)
            cp      '+'
            jr      z, e_plus
            cp      '-'
            jr      z, e_minus
            cp      '|'
            ;jr     z, e_or
            cp      '&'
            ;jr     z, e_and
            cp      '#'
            ;jr     z, e_xor
            cp      '>'             ; Сравнить A < B -> 0 или 1
            cp      '<'
            cp      '='
            ret                     ; Завершение разбора

; Операция сложения
e_plus:     call    e_commom
            ex      de, hl
            add     hl, bc
            ex      de, hl          ; DE = left + right
            jr      expr_n          ; К следующей части

; Операция вычитания
e_minus:    call    e_commom        ; DE -> BC, DE - 2-й операнд
            push    hl
            push    bc
            pop     hl              ; HL=BC
            xor     a
            sbc     hl, de
            ex      de, hl
            pop     hl              ; DE=BC-DE
            jr      expr_n

; Вычисление правой части
e_commom:   inc     hl
            push    de
            call    expr1
            pop     bc
            ret

; Уровень 2: Умножение, деление, модуль
; ----------------------------------------------------------------------

expr1:      call    expr2           ; Левая часть
expr1_n:    ld      a, (hl)
            cp      '*'
            jr      z, e1_mul
            cp      '/'
            jr      z, e1_div
            cp      '%'
            jr      z, e1_mod
            cp      '^'
            ; jr z,     e1_pow
            ret                     ; Операторы не обнаружены

; Деление с получением целого
e1_div:     call    e1_divmod
            push    hl
            call    div16u
            pop     hl
            jr      expr1_n

; Деление и получение модуля
e1_mod:     call    e1_divmod
            push    hl
            call    div16u
            ex      de, hl
            pop     hl
            jr      expr1_n

; Умножение
e1_mul:     inc     hl
            push    de
            call    expr2           ; DE-умножатор
            pop     bc
            push    hl
            call    mul16u          ; DE = DE*BC
            pop     hl
            jr      expr1_n

; Общая процедура для деления и модуля
e1_divmod:  inc     hl
            push    de
            call    expr2
            push    de
            pop     bc
            pop     de              ; SWAP BC, DE
            ret

; Уровень 3
; ----------------------------------------------------------------------

expr2:      call    spaces          ; Убрать лидирующие пробелы
            ld      a, (hl)
            inc     hl
            cp      '('
            jr      nz, expr2_1     ; Это открытая скобка?
            call    expr            ; Если скобка открыта, выполнить
            ld      a, (hl)
            cp      ')'
            jr      nz, expr_err1   ; Ошибка завершения скобок!
            inc     hl
            jr      spaces          ; Удалить пробелы и выйти с 3-уровня

            ; Проверка на VAR|DIGIT
expr2_1:    cp      '-'
            jr      z, expr2_1m     ; Отрицательное число
            ; cp      '$'   hex
            ; jr      z, expr2_1h
            cp      'A'
            jr      c, expr2_1n     ; Не принадлежит A..Z
            cp      'Z'+1
            jr      c, expr2_1v     ; Принадлежит A..Z
expr2_1n:   cp      '0'
            jr      c, expr_err2    ; Неизвестно что это
            cp      '9'+1
            jr      nc, expr_err2
            dec     hl
            call    atoi            ; Это число --> DE
            jr      spaces          ; Убрать пробелы и выйти из процедуры

expr2_1v:   ; @TODO поиск переменной или функции
            halt
            jr      spaces

            ; Это отрицательное число
expr2_1m:   ld      de, 0
            dec     hl
            ret

; Пропуск пробелов во входящей строке
spaces:     ld      a, (hl)
            cp      ' '
            ret     nz
            inc     hl
            jr      spaces

; Запись ошибки выражения и возврат стека
; ----------------------------------------------------------------------
expr_err1:  ld      a, 1                ; Ошибка закрытия скобки
            jr      expr_error
expr_err2:  ld      a, 2                ; Неизвестный символ
expr_error: ld      (expr_errno), a
            ld      hl, (stack_expr)
            ld      sp, hl

            ret
