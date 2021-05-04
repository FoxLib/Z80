
; ----------------------------------------------------------------------
; Обработка события IM 2
; ----------------------------------------------------------------------

IM2:
            push    hl
            push    de
            push    bc
            push    af

            ; Переработать длительность и тип
IM2LOOP:    ld      a, (KEvent)         ; Время до окончания ожидания
            and     a
            jr      nz, IM2NEXT         ; Все еще есть ожидание события?

            ; Извлечь следующее событие из потока
            ld      hl, (EVAddr)
            ld      a, (hl)
            inc     hl
            ld      (KEvent), a         ; Запись нового Delay

            ld      a, (hl)
            inc     hl
            ld      (EVAddr), hl        ; Сохранить новый указатель

            and     a
            jr      z, IM2LOOP          ; 00 Ничего не делать
            cp      $01
            jr      z, IM2WRCHR         ; 01 Печать символа
            cp      $02
            jr      z, IM2REDRAW        ; 02 Запрос на перерисовку
            cp      $03
            jr      z, IM2NEXTSCR       ; 03 Новый экран
            cp      $04
            jr      z, IM2CRLF          ; 04 CRLF
            cp      $05
            jr      z, IM2CLST          ; 05 Очистка текста
            cp      $06
            jr      z, IM2AY            ; 06 Отослать в регистр значение
            jr      $                   ; Любое нераспознанное событие: остановка

            ; Отсчет до следующего события
IM2NEXT:    dec     a
            ld      (KEvent), a

            ; Завершение обработки события
IM2END:     pop     af
            pop     bc
            pop     de
            pop     hl
            ei
            ret

            ; Поднять флаг r[7]
IM2RSET:    ld      a, r
            or      $80
            ld      r, a
            jr      IM2END

; ----------------------------------------------------------------------
; 01: Пропечатать символ
; ----------------------------------------------------------------------

IM2WRCHR:   ld      hl, (NEXTSYM)       ; Извлечь следующий символ
            ld      a, (hl)
            inc     hl
            ld      (NEXTSYM), hl
            ld      hl, (NEXTPOS)       ; Следующая позиция
            cp      $00
            jr      z, IM2WRCHRn

            push    de
            ld      de, 0x0d00
            call    AYREG               ; Обновить огибающую шума
            pop     de
IM2WRCHRn:
            call    PRN
            ld      (NEXTPOS), hl
            jr      IM2LOOP

; ----------------------------------------------------------------------
; 02|03: Перерисовка экрана | Следующий экран
; ----------------------------------------------------------------------

IM2REDRAW:  ld      a, (hl)
            inc     hl
            ld      (EVAddr), hl
            ld      (DithV), a
            jr      IM2RSET
IM2NEXTSCR: ld      a, 0xff         ; Распаковка нового экрана
            ld      (DithV), a
            jr      IM2RSET

; ----------------------------------------------------------------------
; 04: Перенести на другую строку
; ----------------------------------------------------------------------

IM2CRLF:    ld      b, (hl)         ; Отступ обычно 04h
            inc     hl
            ld      (EVAddr), hl
            ld      hl, (NEXTPOS)
            ld      a, l
            and     $e0
            or      b
            ld      l, a
            add     $60
            ld      l, a
            jr      nc, IM2CRLF_n
            ld      a, h
            add     $08
            ld      h, a
IM2CRLF_n:  ld      (NEXTPOS), hl
            jp      IM2LOOP

; ----------------------------------------------------------------------
; 05: Очистка текста
; ----------------------------------------------------------------------

IM2CLST:    ld      hl, $5000
            ld      de, $5001
            ld      bc, $07ff
            xor     a
            ld      (hl), a
            ldir
            ld      hl, $5004
            ld      (NEXTPOS), hl
            jr      IM2END

; ----------------------------------------------------------------------
; 06: Отослать в регистр N значение V
; ----------------------------------------------------------------------
IM2AY:      ld      d, (hl)
            inc     hl
            ld      e, (hl)
            inc     hl
            ld      (EVAddr), hl
            call    AYREG
            jp      IM2LOOP

; ----------------------------------------------------------------------
; Декомпрессия следующей картинки
; ----------------------------------------------------------------------

NEXTSCR:    ld      hl, (SCRPTR)        ; Получить указатель в таблице
            ld      e, (hl)
            inc     hl
            ld      d, (hl)
            inc     hl                  ; DE=адрес, где лежит картинка
            ld      (SCRPTR), hl        ; К следующему указателю
            ex      de, hl              ; Теперь адрес находится в HL
            ld      de, DECOMP          ; Адрес декомпрессии в DE
            call    dzx0
            ret

; ----------------------------------------------------------------------
; Печать одного символа A в режиме телетайпа -> HL
; ----------------------------------------------------------------------

PRN:        push    hl
            push    de
            push    bc
            ex      de, hl          ; Сохранить HL
            ld      bc, FONTS
            ld      l, a
            ld      h, 0
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, bc
            ex      de, hl          ; DE = 16*A + FONTS
            ld      c, 2
PRN2:       ld      b, 8
PRN1:       ld      a, (de)         ; Нарисовать половину символа
            ld      (hl), a
            inc     de
            inc     h
            djnz    PRN1
            ld      a, h            ; Вернуть H на место
            sub     $08
            ld      h, a
            ld      a, l
            add     $20             ; Проверка на превышение L
            jr      nc, PRN3
            ex      af, af'
            ld      a, h
            add     $08             ; Перенос к следующему блоку
            ld      h, a
            ex      af, af'
PRN3:       ld      l, a
            dec     c
            jr      nz, PRN2
            pop     bc
            pop     de
            pop     hl
            inc     l
            ret

; ----------------------------------------------------------------------
; Отрисовка картинки HL, A-затемнение [0..8]
; ----------------------------------------------------------------------

REDRAW:     push    hl              ; Сохранить для повторного использования
            push    af
            ld      iyl, a
            ld      iyh, 0
            ld      bc, DMASK0
            add     iy, iy
            add     iy, iy
            add     iy, iy
            add     iy, bc          ; IX = DMASK0 + 8*A
            ld      c, 104          ; 104 строки
            ld      (IYhold), iy    ; Сохранение указателя дизеринга
            ld      ix, YTABLE      ; Предвычисленная таблица Y-позиции
            ld      a, 8            ; Для циклического вращения IY
            ex      af, af'
DRAW2:      ld      d, (ix+1)       ; Следующий табличный адрес [0..103]
            ld      e, (ix+0)
            inc     ix
            inc     ix
            ld      a, (iy+0)       ; Маска дизеринга для затемнения
            ld      (MODIF+1), a    ; Модифицировать код для наложения маски
            ld      b, 25           ; 25 x 8 = 200 пикселей
; --- 1145T Рисование одной линии -----
DRAW1:      ld      a, (hl)         ; 7T Основной цикл рисования
MODIF:      or      $00             ; 7T Самомодицифирующийся код
            ld      (de), a         ; 7T
            inc     de              ; 6T
            inc     hl              ; 6T
            djnz    DRAW1           ; 13T/8T
; -------------------------------------
            inc     iy              ; К следующему циклу
            ex      af, af'
            dec     a
            jr      nz, DRAW3       ; Проверить, что не достигло 0
            ld      iy, (IYhold)    ; Восстановить IY
            ld      a, 8            ; Восстановить счетчик
DRAW3:      ex      af, af'
            dec     c               ; К следующей линии
            jr      nz, DRAW2
            pop     af
            pop     hl
            ret

; ----------------------------------------------------------------------
; Заливка области картинки (A-цвет $30)
; ----------------------------------------------------------------------

DRAWBG:     ld      hl, $5803
            ld      de, 7
            ld      c, 13
LINE2:      ld      b, 25
LINE1:      ld      (hl), a
            inc     hl
            djnz    LINE1
            add     hl, de
            dec     c
            jr      nz, LINE2
            ret

; ----------------------------------------------------------------------
; AY-инициализация
; ----------------------------------------------------------------------

AYINIT:     ; Включение AY
            ld      bc, $243B
            ld      a, 9
            out     (c), a
            ld      b, $25
            in      a, (c)
            and     $fc
            or      $01
            out     (c), a

            ; Инициализировать регистры
            ld      hl, AYDefRegs
            ld      d, 0
            ld      e, 13
AYINITn:    ld      bc, $fffd
            out     (c), d
            ld      b, $bf
            ld      a, (hl)
            out     (c), a
            inc     hl
            inc     d
            dec     e
            jr      nz, AYINITn
            ret

; Запись значения E в регистр D
AYREG:      push    bc
            push    af
            ld      bc, $fffd
            out     (c), d
            ld      b, $bf
            out     (c), e
            pop     af
            pop     bc
            ret

; Значения по умолчанию
AYDefRegs:  defb    0x00, 0x01  ; 0,1 A тон (saw)
            defb    0x00, 0x04  ; 2,3 B тон (отключен)
            defb    0x00, 0x08  ; 4,5 C тон (square)
            defb    0x02        ; 6   Период шума 15 из 32
            defb    11101111b   ; 7   Активация
            defb    0x0f        ; 8   A vol & env
            defb    0x18        ; 9   B vol & env
            defb    0x0a        ; A   C vol & env
            defb    0x80, 0x00  ; B,C Период огибающей
