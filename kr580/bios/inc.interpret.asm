
; ----------------------------------------------------------------------
; Модуль интерпретатора строк из HL
; Разбор и встраивание новой строки в программу
; Запуск строки, исполнение
; ----------------------------------------------------------------------

ip_ptr:     defw    0

            ; Отсеять пробелы и цифры вначале
interpret:  ld      a, (hl)
            inc     hl
            cp      ' '
            jr      z, interpret        ; Пробел
            cp      '0'
            jr      c, ipshl            ; Если A < '0' Продолжить
            cp      '9'+1
            jr      c, interpret        ; Если A = 0..9 Пропуск

; ----------------------------------------------------------------------
; РЕАЛЬНОЕ ИСПОЛНЕНИЕ КОМАНД
; ----------------------------------------------------------------------

            ; Откатить символ обратно
ipshl:      dec     hl

            ; Запуск поиска команд
runline:    ld      a, (hl)
            inc     hl
            cp      ':'
            jr      z, runline      ; Найден разделитель операторов
            cp      ' '
            jr      z, runline      ; Не учитывать пробел в начале
            and     a
            ret     z               ; Команда завершена

            ; Начать поиск
            dec     hl
            ld      de, statements

ipnx:       ; Искать следуюшую команду
            ld      a, (de)
            and     a
            jr      z, next_1       ; Команда не была найдена?
            ld      b, a            ; B=длина команды

            push    hl
            push    de
            inc     de              ; Перейти к тексту команды
ipcp:       ld      a, (de)         ; Следующая буква команды
            ld      c, a            ; Будет в C
            ld      a, (hl)         ; Проверить на конец строки
            and     a
            jr      z, ipn          ; Это конец строки
            inc     hl
            inc     de              ; Сдвинуть строки
            cp      c               ; Тест на соответствие A=C
            jr      nz, ipn         ; Если тест не пройден, ошибка
            djnz    ipcp

            ; Команда действительно закончена?
            ld      a, (hl)
            cp      'A'
            jr      c, ipcmok
            cp      'Z'+1
            jr      nc, ipcmok

            ; Команда не подошла (был A-Z)
ipn:        pop     de
            call    ipnexde
            pop     hl
            jr      ipnx

            ; Вычислить адрес команды и вызвать
ipcmok:     ld      (ip_ptr), hl    ; Сохранить позицию в буфере
            pop     de
            pop     hl
            call    ipnexde
            dec     de
            dec     de              ; DE -= 2
            ld      a, (de)
            ld      c, a
            inc     de
            ld      a, (de)         ; LD DE, (DE)
            ld      d, a
            ld      e, c            ; DE-процедура
            ex      de, hl
            jp      (hl)            ; DE-указатель на аргументы

            ; Вычисление следующей табличной команды DE -> DE
ipnexde:    ld      a, (de)
            add     3
            ld      h, 0
            ld      l, a
            add     hl, de
            ex      de, hl          ; DE = DE + size + 3
            ret

            ; После исполнения CMD_* перейти сюда
nextline:   ld      hl, (ip_ptr)
            jp      runline

; ----------------------------------------------------------------------
; Найти выражение VAR = EXPR
; ----------------------------------------------------------------------

next_1:     halt
            jr      $
