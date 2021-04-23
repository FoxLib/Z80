    org 8000h
    di
L1:
halt
    inc a
    and 7
    out (254),a
    jr  L1
