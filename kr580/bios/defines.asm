; ----------------------------------------------------------------------
; Список запросов к RST #10
;
;   rst     $10
;   defb    <номер функции>
; ----------------------------------------------------------------------
api_getcursor:      equ $00 ; Чтение положения курсора в HL
api_setcursor:      equ $01 ; Установка курсора из HL
api_cls:            equ $02 ; Очистка экрана в цвет A
api_print:          equ $03 ; Печать строки DE
api_itoa:           equ $04 ; Конвертация числа DE -> DE
api_read:           equ $05 ; Чтение сектора HL:DE -> BC
api_write:          equ $06 ; Запись сектора из BC в HL:DE
api_div16u:         equ $07 ; Деление, DE=DE / BC, HL=DE % BC
api_setattr:        equ $08 ; Установка текущего атрибута A
api_scrollup:       equ $09 ; Перемотка наверх

; Цветовая палитра
; ----------------------------------------------------------------------
CLR_LINE:           equ     3           ; Номер линии
CLR_SYMB:           equ     7+$40       ; Буквы не в кавычках
CLR_NUMBER:         equ     5           ; Цифры
CLR_QUOTE:          equ     4           ; Цвет в кавычках
CLR_DFLT:           equ     7           ; Цвет по умолчанию

; Буферы
; ----------------------------------------------------------------------
buffer:             equ     $5B00       ; Исходный код (32b)
variable:           equ     $5B20       ; Описатели переменных A-Z (2x26)
progmem:            equ     $5B60       ; Память программы

; Макросы
; ----------------------------------------------------------------------
pusha:      macro           ; Сохранение регистров
            push    hl
            push    de
            push    bc
            endm
popa:       macro           ; Восстановление регистров
            pop     bc
            pop     de
            pop     hl
            endm
apic:       macro   arg     ; Вызов API-функции
            rst     $10
            defb    arg
            endm

; ----------------------------------------------------------------------
; Система команд Бейсика
; ----------------------------------------------------------------------

statements:
            defb    5,"PRINT"
            defw    CMD_PRINT
            defb    3,"CLS"
            defw    CMD_CLS

            ;defb  3,"NEW"
            ;defb  3,"RUN"
            ;defb    5,"INPUT"
            ;defb    3,"FOR"
            ;defb    4,"NEXT"
            ;defb    5,"PAPER"
            ;defb    6,"BORDER"
            ;defb    3,"INK"
            ;defb    6,"LOCATE"
            ;defb    1,"?"
            ;defb    4, "POKE"
            ;defb    4, "PEEK"

            defb    0
