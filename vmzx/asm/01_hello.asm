    org 8001h
    di
L1:
    inc a
    and 7
    out (254),a
    halt
    jr  L1
