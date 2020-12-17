
; СЕРВИСНОЕ ПРЕРЫВАНИЕ ДОС ДЛЯ ЧТЕНИЯ С КЛАВИАТУРЫ
; ----------------------------------------------------------------------

            push    bc
            push    de
            push    hl
            and     a
            jr      z, KBD_WAIT_GET
            jr      KBD_EXIT

; ----------------------------------------------------------------------

KBD_WAIT_GET:

            ld      hl, KEYB_BUFFER
            ld      a, (KEYB_NUMKEY)
            ld      b, a
K1R:        dec     b
            jp      m, KBD_WAIT_GET    
            ld      a, (hl)         ; Посмотреть символ
            cp      $80
            jr      c, K2S          ; Клавиша уже обработана        
            and     $7F             ; Сброс флага new=1
            ld      (hl), a        
            cp      10              ; Нажат ENTER
            jr      z, KBD_FN        
            cp      $20             ; Нажат символ
            jr      nc, KBD_EXIT
K2S:        inc     hl
            inc     hl
            jr      K1R        
            jr      KBD_WAIT_GET    ; Ожидание приема сигнала

; ----------------------------------------------------------------------

KBD_EXIT:   ld      d, a            ; Сохранить код, чтобы не потерять
            ld      bc, $7FFE       ; Тест клавиши (SYM SHIFT)
            in      a, (c)
            bit     1, a
            jr      z, KBD_SYM        
            ld      bc, $FEFE       ; Проверка (CAPS SHIFT)
            in      a, (c)
            bit     0, a
            ld      a, d        
            jr      nz, KBD_FN      ; Клавиша CAPS не нажата, пропуск        
            call    KBD_SS          ; Спецсимвол на 0-9
            jr      nc, KBD_FN
            cp      $20             ; Пробел не менять
            jr      z, KBD_FN        
            sub     a, $20          ; Обычный символ A-Z
KBD_FN:     pop     hl
            pop     de
            pop     bc
            ret

; Нажата клавиша SYMBOL SHIFT
; ----------------------------------------------------------------------

KBD_SYM:    ld      b, $FE
            in      a, (c)
            bit     0, a
            ld      a, d
            ld      hl, KGA_SU
            call    z, KBD_SYM_FIND        ; CAPS нажат
            ld      hl, KGA_SS
            call    nz, KBD_SYM_FIND       ; Не зажат CAPS
            ld      a, d
            jr      KBD_FN

; Поиск нужного символа в SYMBOL SHIFT (при caps / CAPS)
; ----------------------------------------------------------------------

KBD_SYM_FIND:

            push    af
            ld      b, 14

KBD_SYM_REP:

            cp      (hl)
            jr      z, KBD_MATCH
            inc     hl
            inc     hl
            djnz    KBD_SYM_REP ; Повторять, пока не найдется
            jr      KBD_RETAF   ; Ничего не найдено, выход
KBD_MATCH:  inc     hl          ; Найден
            ld      a, (hl)
            ld      d, a
KBD_RETAF:  pop     af
            ret

; Тест на подъем специальных символов
; ----------------------------------------------------------------------

KBD_SS:     cp      '0'
            jr      c, KBD_RT
            cp      '9' + 1
            jr      nc, KBD_RC
            ld      de, KGA_SYM
            sub     '0'
            ld      h, 0
            ld      l, a
            add     hl, de
            ld      a, (hl)
            scf
KBD_RC:     ccf
KBD_RT:     ret

; ----------------------------------------------------------------------

KGA_SYM:    ;     0    1    2    3    4    5    6    7    8    9
            defb ')', '!', '@', '#', '$', '%', '^', '&', '*', '('

KGA_SS:     ; Клавиши при нажатом Symbol Shift
            defb 'n', ','
            defb 'm', '.'
            defb 'b', '/'
            defb 'k', ';'
            defb 'l', $27 ; '
            defb 'y', '-'
            defb 'u', '='
            defb 'i', $5C ; обратный слеш
            defb 'o', '['
            defb 'p', ']'
            defb 'q', '`'
            defb 'w', $09 ; tab
            defb 'e', $08 ; del

KGA_SU:     ; Клавиши при нажатом Symbol Shift + CAPS
            defb 'n', '<'
            defb 'm', '>'
            defb 'b', '?'
            defb 'k', ':'
            defb 'l', '"'
            defb 'y', '_'
            defb 'u', '+'
            defb 'i', '|'
            defb 'o', '{'
            defb 'p', '}'
            defb 'q', '~'
            defb 'w', $09
            defb 'e', $08 ; del

KGA_ROWS:   ;     $01  $02  $04  $08  $10
            defb   1,  'z', 'x', 'c', 'v'       ; A8   FE 1111:1110
            defb  'a', 's', 'd', 'f', 'g'       ; A9   FD 1111:1101
            defb  'q', 'w', 'e', 'r', 't'       ; A10  FB 1111:1011
            defb  '1', '2', '3', '4', '5'       ; A11  F7 1111:0111
            defb  '0', '9', '8', '7', '6'       ; A12  EF 1110:1111
            defb  'p', 'o', 'i', 'u', 'y'       ; A13  DF 1101:1111
            defb  10,  'l', 'k', 'j', 'h'       ; A14  BF 1011:1111
            defb  ' ',  2,  'm', 'n', 'b'       ; A15  7F 0111:1111

