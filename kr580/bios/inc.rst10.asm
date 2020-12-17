
; ----------------------------------------------------------------------
; Обработчик прерывания RST #10
; ----------------------------------------------------------------------

rst10:      ; Сохранение регистров A,BC,DE,HL
            ld      (reg_a),  a
            ex      (sp), hl            ; HL-адрес возврата
            ld      a, (hl)             ; Прочесть следующий байт за RST
            inc     hl                  ; Новый адрес возврата
            ex      (sp), hl
            push    de                  ; Сохранить DE
            ld      h, 0
            ld      l, a                ; Вычислить адрес перехода
            add     hl, hl
            ld      de, r10_lookup
            add     hl, de
            ld      e, (hl)
            inc     hl
            ld      d, (hl)
            ex      de, hl
            pop     de
            ld      a, (reg_a)          ; Сохранены A, BC, DE (кроме HL)
            jp      (hl)

; ----------------------------------------------------------------------
; Таблица переходов для API процедур (defines.asm)
; ----------------------------------------------------------------------

r10_lookup: defw    r10_getxy
            defw    r10_setxy
            defw    cls
            defw    print
            defw    itoa
            defw    r10_read
            defw    r10_write
            defw    div16u
            defw    r10_setatr
            defw    scrollup

; ----------------------------------------------------------------------

r10_getxy:  ld      hl, (cursor_xy)
            ret

r10_setxy:  ld      hl, (reg_hl)
            ld      (cursor_xy), hl
            call    clrcursor
            call    setcursor
            ret

r10_read:   ld      hl, (reg_hl)
            call    read
            ret

r10_write:  ld      hl, (reg_hl)
            call    write
            ret

r10_setatr: ld      (cursor_attr), a
            ret
