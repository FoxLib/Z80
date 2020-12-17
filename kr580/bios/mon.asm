; RST #00   Сброс
            di
            ld      sp, $0000
            jp      start
reg_a:      defb    0

; RST #08   Печать символа A в режиме телетайпа
            push    af
            call    prnc
            pop     af
            ret
cursor_xy:  defw    0

; RST #10   Управление вводом-выводом, рисование и прочее
            ld      (reg_hl), hl
            jp      rst10
reg_hl:     defw    0

; RST #18   Чтение символа с клавиатуры (A=0 ожидать, A<>0 не ждать)
            jp      getch
cursor_old: defw    $5800           ; Старая позиция курсора
cursor_attr:defb    0               ; Текущий цветовой атрибут
keyb_spec:  defb    0               ; Нажатые клавиши shift/ctrl/alt
csym:       defb    0               ; Текущий интерпретируемый символ

; RST #20
; RST #28
; RST #30
; RST #38   Вызов вертикальной синхронизации 60 раз в секунду

; ----------------------------------------------------------------------
; Модули ядра
; ----------------------------------------------------------------------

            include "defines.asm"
            include "inc.rst10.asm"
            include "inc.display.asm"
            include "inc.math.asm"
            include "inc.stdio.asm"
            include "inc.spi.asm"
            include "inc.interpret.asm"
            include "inc.expr.asm"
            include "inc.basic.asm"
