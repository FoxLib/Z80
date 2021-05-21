
            org     $6600       ; Начало после Бейсик-программы
DECOMP:     equ     $5b00       ; Буфер A28h (2600) байт для распаковки экрана

; Карта памяти
; ----------------------------------------------------------------------
; 4000-5aff Видео-область
; 5b00-65ff Временный буфер 2816 для распаковки кадров [заменить]
; 6600-xxxx Программа и данные
; FDFD-FF00 IM2 прерывание (260 байт)
; FF01-FFFF Стек (254 байта)
; ----------------------------------------------------------------------

            di
            ld      b, 192
            ld      sp, $5b00
            ld      hl, $4747       ; Очистка области атрибутов
Cls1:       push    hl
            push    hl
            djnz    Cls1
            ld      hl, $0000       ; Очистка области данных
            ld      bc, $000c
Cls2:       push    hl
            djnz    Cls2
            dec     c
            jr      nz, Cls2

; Создание 258-байтной таблицы $FDFD
; ----------------------------------------------------------------------

            ld      b, 129
            ld      sp, $ff02
            ld      hl, $fdfd
Im2Vect:    push    hl
            djnz    Im2Vect

            ; Команда JP IM2
            ld      a, $c3
            ld      ($fdfd), a
            ld      hl, IM2
            ld      ($fdfe), hl

            ; Установка прерывания IM2
            ld      a, $fe
            ld      i, a
            ld      sp, $0
            im      2

; Первичная отрисовка
; ----------------------------------------------------------------------

            call    AYINIT
            call    NEXTSCR         ; Загрузить следующий экран
            xor     a
            call    DRAWBG          ; Чтобы затереть белые атрибуты
            ld      a, (DithV)
            ld      hl, DECOMP
            call    REDRAW          ; "Невидимое" рисование
            ld      a, $30
            call    DRAWBG          ; Сверхскоростное появление на экране

; Ожидание появления события
; ----------------------------------------------------------------------

MAIN:       ei
            ld      a, r
            and     $80
            jr      z, MAIN
            ld      a, r
            and     $7f
            ld      r, a

            ; -------------------------------
            ; Обновление, загрузка данных
            ; -------------------------------

            ld      a, (DithV)
            cp      $ff
            jr      nz, DRAWS
            call    NEXTSCR         ; Декомпрессия нового экрана
            jr      MAIN
DRAWS:      ld      hl, DECOMP
            call    REDRAW
            jr      MAIN

; ----------------------------------------------------------------------
; Обработчики и данные
; ----------------------------------------------------------------------

            ; Обработчики
            include "routines.asm"

            ; Декомпрессор
            include "dzx0_standard.asm"

            ; Список строк
STRG:       include "data/string.asm"

            ; Список событий
EVTLST:     include "data/events.asm"

YTABLE:     incbin  "data/ytable.bin"
DMASK0:     incbin  "data/dither.bin"
FONTS:      incbin  "data/fonts.bin"

            ; Компрессированные данные со скринами (около 12 кб)
SCR1:       incbin  "screen/screen1.bin"
SCR2:       incbin  "screen/screen2.bin"
SCR3:       incbin  "screen/screen3.bin"
SCR4:       incbin  "screen/screen4.bin"
SCR5:       incbin  "screen/screen5.bin"
SCR6:       incbin  "screen/screen6.bin"
SCR7:       incbin  "screen/screen7.bin"
SCR8:       incbin  "screen/screen8.bin"
SCR9:       incbin  "screen/screen9.bin"

; ----------------------------------------------------------------------
; Данные
; ----------------------------------------------------------------------

IYhold:     defw    0           ; Временное значение для IY (дизеринг)
DithV:      defb    0           ; Текущее значение затемнения (от 0 до 8)
EVAddr:     defw    EVTLST      ; Адрес последнего байта события в потоке

; Таблица с экранами
SCRPTR:     defw    SCRLST
SCRLST:     defw    SCR1, SCR2, SCR3, SCR4, SCR5, SCR6, SCR7, SCR8, SCR9
NEXTSYM:    defw    str0        ; Адрес печатаемого символа
NEXTPOS:    defw    $5004       ; Первая позиция текста

; ----------------------------------------------------------------------
; Типы событий
; ----------------------------------------------------------------------
; 1 DELAY   Когда должно наступить следующее событие. Если =0, то прямо сейчас
; 1 TYPE    Тип события
; x PARAM   Параметры события
; ----------------------------------------------------------------------
; 00 Ничего не делать
; 01 Печать следующей буквы
; 02 Перерисовка экрана с новыми дизерингом (параметр)
; 03 К следующему экрану
; 04 CRLF (с отступом)
; 05 Очистка текста
; xx Окончание потока
; ----------------------------------------------------------------------

; Текущее событие
KEvent:     defb    0           ; Время (1/50 сек) до следующего события