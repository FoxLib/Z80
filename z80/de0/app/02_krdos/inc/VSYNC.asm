
; 50/60 Hz VSync Retrace
; ----------------------------------------------------------------------

        push    ix
        push    iy
        push    af
        push    bc
        push    de
        push    hl

        ; Инкрементировать глобальный таймер
        ld      ix, TIMER_TICK
        inc     (ix + 0)
        jr      nz, VS0
        inc     (ix + 1)

        ; Инкрементировать BLINK-таймер [0..49] для курсора
        ; -------------------------------

VS0:    ld      a, (ix + 2)
        inc     a
        cp      25
        jr      nz, VS1

        ; Выполнить Blink Toggle
        ; -------------------------------

        call    BLINK_TOGGLE
        xor     a
VS1:    ld      (ix + 2), a

        ; Прочитать состояние 8 строк клавиш
        ; И сравнить с предыдущим их состоянием
        ; -------------------------------

        ld      bc, $FEFE       ; Исходный порт
        ld      hl, KEYB_STATUS ; Таблица статусов
        ld      ix, KGA_ROWS    ; Таблица символов ASCII
VS2:    in      a, (c)          ; Прочитать порт
        xor     $FF             ; Обратить биты с 1 до 0
        ld      d, (hl)         ; Получить предыдущее значение
        ld      (hl), a         ; Сохранить текущее
        xor     d               ; Определить, какие биты поменялись
        ld      e, 5            ; Проверить эти 5 битов
VS3RP:  srl     a               ; Проверить бит на наличие 1
        jr      nc, VS3NC       ; Если 0, то клавиша не была изменена
        srl     d               ; Проверить предыдущую клавишу
        call    c,  KEYB_DEL    ; Была раньше нажата
        call    nc, KEYB_ADD    ; Была отпущена
        jr      VS3CX           ; Перейти к следующему символу
VS3NC:  srl     d               ; Сдвиг на 1 бит
VS3CX:  inc     ix
        dec     e
        jr      nz, VS3RP       ; И так проверить 5 раз
        inc     hl              ; Перейти к следующей строке
        rlc     b
        jr      c, VS2

        ; Выполнить декремент t в буфере
        ; -------------------------------

        ld      ix, KEYB_BUFFER
        ld      a, (KEYB_NUMKEY)
        ld      b, a

VS4L:   dec     b
        jp      m, VS4E

        ; Уменьшение на 1 всех
        ld      a, (ix + 1)
        and     a
        jr      nz, VS4R

        ; Установка статуса new=1
        ld      a, (ix + 0)
        or      $80
        ld      (ix + 0), a
        ld      a, KBD_REPEAT_SECOND

        ; Декремент
VS4R:   dec     a
        ld      (ix + 1), a
        inc     ix
        inc     ix
        jr      VS4L

VS4E:   ; Восстановление регистров и флагов
        pop     hl
        pop     de
        pop     bc
        pop     af
        pop     iy
        pop     ix
        ei
        ret

; Клавиша A была нажата, добавить в буфер или обновить
; ----------------------------------------------------------------------

KEYB_ADD:

        push    af
        push    hl
        push    bc
        call    KEYB_REQ            ; Запоминаем клавишу
KA1RE:  dec     b
        jp      m, KA1EX            ; Очередь закончилась
        ld      a, (hl)             ; ID клавиши    
        and     $7F
        cp      c                   ; Сравним текущую клавишу с буфером
        jr      z, KA1NU            ; Такая клавиша есть, обновить NEW и Timer
        inc     hl
        inc     hl
        jr      KA1RE
KA1EX:  ld      a, (KEYB_NUMKEY)    ; Добавить новую клавишу в буфер
        inc     a
        ld      (KEYB_NUMKEY), a
KA1NU:  ld      a, c                ; Добавить или обновить (hl)
        or      $80                 ; ascii + флаг new=1
        ld      (hl), a             ; Сохранить его в буфере        
        inc     hl                  ; Подвинуть +1 чтобы сохранить
        ld      a, KBD_REPEAT_FIRST ; там время повтора (первый повтор)
        ld      (hl), a             ; для клавиши, если она зажата постоянно
        pop     bc                  ; Выход
        pop     hl
        pop     af
        ret

; Клавиша A была отпущена, удалить из буфера
; ----------------------------------------------------------------------

KEYB_DEL:

        push    af
        push    hl
        push    de
        push    bc
        call    KEYB_REQ            ; Запоминаем клавишу
KD1R:   dec     b                   ; Если b=0, то...
        jp      m, KD1F             ; ... завершить проверки
        ld      a, (hl)             ; Получить номер клавиши в буфере
        and     $7F                 ; Убрать new=0/1 (7-й бит)
        ld      d, h                ; Сохранить DE = HL
        ld      e, l                ; Может потребоваться, чтобы удалить
        inc     hl                  ; HL += 2 для следующей итерации
        inc     hl
        cp      c                   ; Сравнить клавишу A == С
        jr      nz, KD1E            ; Клавиша не совпала, пропуск удаления
        push    bc                  ; Сохраним важные регистры в стеке
        push    hl
        ld      a, b                ; Удалить символ из буфера (позиция DE)
        inc     a
        add     a
        ld      b, 0
        ld      c, a                ; Здесь bc = 2*b
        ldir
        ld      a, (KEYB_NUMKEY)    ; Декремент количества символов в буфере
        dec     a
        ld      (KEYB_NUMKEY), a
        pop     hl
        pop     bc
KD1E:   jr      KD1R                ; Проверка следующей клавиши
KD1F:   pop     bc                  ; Выход из цикла
        pop     de
        pop     hl
        pop     af
        ret

; Запрос данных для KEYB_ADD / KEYB_DEL
; ----------------------------------------------------------------------
KEYB_REQ:

        ld      hl, KEYB_BUFFER
        ld      a, (ix + 0)
        ld      c, a
        ld      a, (KEYB_NUMKEY)
        ld      b, a
        ret
