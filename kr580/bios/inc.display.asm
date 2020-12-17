
; ----------------------------------------------------------------------
; Процедура очистки экрана, в регистре A атрибут
; ----------------------------------------------------------------------

cls:        ld      hl, $0000
            ld      (cursor_xy), hl
            call    setcursor
            ld      h, $40
            ld      b, l
            ld      c, a
            ld      (cursor_attr), a
clsm1:      ld      (hl), b
            inc     l
            jr      nz, clsm1
            inc     h
            ld      a, h
            cp      $5B
            jr      z, clsm2
            cp      $58
            jr      nz, clsm1
            ld      b, c
            jr      clsm1
clsm2:      call    setcursor
            ret

; ----------------------------------------------------------------------
; Печать символа A, позиция B=Y, C=X
; ----------------------------------------------------------------------

prn:        push    hl
            push    de
            push    bc

            ; Вычисление позиции символа в таблице символов
            sub     a, $20
            ld      h, 0
            ld      l, a
            add     hl, hl
            add     hl, hl
            add     hl, hl
            ld      de, fonts
            add     hl, de
            ex      de, hl

            ; Расчет позиции HL
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

            ; Рисование
            ld      b, 8
p2m1:       ld      a, (de)
            ld      (hl), a
            inc     de
            inc     h
            djnz    p2m1

            ; Восстановление
            pop     bc
            pop     de
            pop     hl
            ret

; ----------------------------------------------------------------------
; Вычисление 32*Y + X -> HL
; ----------------------------------------------------------------------

attrpl:     push    de
            push    af
            ld      hl, (cursor_xy)
            ld      e, l
            ld      l, h
            ld      d, 0
            ld      h, 0
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl
            add     hl, hl      ; 32*Y
            add     hl, de      ; HL = 32*Y + X
            ld      a, h
            add     $58
            ld      h, a
            pop     af
            pop     de
            ret

; ----------------------------------------------------------------------
; Ставится атрибут в позицию курсора
; ----------------------------------------------------------------------

setat:      push    af
            push    hl
            call    attrpl
            ld      a, (cursor_attr)
            ld      (hl), a
            pop     hl
            pop     af
            ret

; ----------------------------------------------------------------------
; Установка мигающего курсора в (cursor_attr) и снятие старой позиции
; ----------------------------------------------------------------------

clrcursor:  push    hl                  ; Снять старую позицию
            ld      hl, (cursor_old)
            res     7, (hl)
            pop     hl
            ret

setcursor:  push    hl
            call    attrpl
            ld      (cursor_old), hl
            set     7, (hl)             ; Установить новую
            pop     hl
            ret

; ----------------------------------------------------------------------
; Печать символа A в режиме телетайпа с прокруткой вверх
; ----------------------------------------------------------------------

prnc:       push    bc
            push    de
            push    hl

            ; Текущая позиция курсора
            ld      hl, (cursor_xy) ; Текущий курсор -> BC
            call    clrcursor       ; Убрать старый курсор
            ld      b, h
            ld      c, l
            cp      13              ; ENTER?
            jr      z, p3m2

            call    setat           ; Установка атрибута
            call    prn             ; Печать символа

            inc     l
            ld      a, l
            cp      $20
            jr      nz, p3m1        ; Достиг правого края
p3m2:       ld      l, $00
            inc     h
            ld      a, h
            cp      $18             ; Достиг нижней границы
            jr      nz, p3m1
            call    scrollup        ; Скроллинг экрана наверх
            ld      h, $17          ; Курсор установить в конце
p3m1:       ld      (cursor_xy), hl
            call    setcursor
            pop     hl
            pop     de
            pop     bc
            ret

; ----------------------------------------------------------------------
; Скроллинг экрана наверх
; ----------------------------------------------------------------------

scrollup:   ; Сохранить регистры
            push    bc
            push    de
            push    hl

            ; Перемотка блока наверх
            ld      de, $4000
            ld      hl, $4020
            ld      b, 3

            ; Повторить перемотку для 3-х частей экрана
SL2:        push    hl
            push    de
            push    bc
            ld      c,  $e0
            push    bc          ; Сохранить B -> B'
            exx
            pop     bc
            exx

            ; Сдвинуть первые 7 линии
            call    SLCP
            ld      a, d
            sub     a, 8
            ld      d, a

            exx
            ld      a, b
            cp      1
            exx                 ; Проверить на B=1
            jr      z, SL7      ; Если так, то не поднимать строку

            ; 8-я линия
            ld      e, $e0
            ld      c, $20
            ld      l, b
            call    SLCP

SL7:        pop     bc
            pop     de
            pop     hl

            ; К следующей странице
            ld      a, h
            add     8
            ld      h, a
            ld      d, h
            djnz    SL2

            ; Сдвиг вверх атрибутов с очисткой
            ld      bc, 768-32
            ldir
            ld      b, 32
            ld      a, (cursor_attr)
SL3:        ld      (de), a
            inc     de
            djnz    SL3

            ; Очистка нижней строки (8 линии)
            xor     a
            ld      c, $08      ; Количество линии
            ld      h, $50      ; Номер банка памяти
SL5:        ld      b, $20      ; 32 символа
            ld      l, $e0      ; Начинается на 7-й строке
SL4:        ld      (hl), a     ; Обнулить
            inc     hl
            djnz    SL4
            dec     c
            jr      nz, SL5

            ; Восстановить регистры
            pop     hl
            pop     de
            pop     bc
            ret

; Скроллинг нескольких линий
SLCP:       ld      a, 8
            ld      b, 0
SL6:        push    hl
            push    de
            push    bc
            ldir
            pop     bc
            pop     de
            pop     hl
            inc     d
            inc     h
            dec     a
            jr      nz, SL6
            ret

; ----------------------------------------------------------------------
; Печать строки из DE в режиме телетайпа
; ----------------------------------------------------------------------

print:      ld      a, (de)
            inc     de
            and     a
            ret     z
            call    prnc
            jr      print

; ШРИФТЫ
fonts:      incbin  "font.fnt"

; Псевдографика
defb        $00, $00, $ff, $00, $ff, $00, $00, $00 ; $80 =
defb        $28, $28, $28, $28, $28, $28, $28, $28 ; $81 |
defb        $00, $00, $3f, $20, $2f, $28, $28, $28 ; $82 |-
defb        $00, $00, $f8, $08, $e8, $28, $28, $28 ; $83 -|
defb        $28, $28, $2f, $20, $3f, $00, $00, $00 ; $84 |-
defb        $28, $28, $e8, $08, $f8, $00, $00, $00 ; $85 -|
