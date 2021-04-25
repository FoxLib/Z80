1 REM di        f3      243
2 REM ld a, $c0 3e c0   62, 192
3 REM ld i, a   ed 47   237, 71
4 REM im2       ed 5e   237, 94
5 REM ei        fb      251
6 REM ret       c9      201
7 PRINT "DO:";
10 DATA 243,62,192,237,71,237,94,251,201
20 FOR i=0 TO 8: READ a: POKE 32768+i,a: NEXT i
30 FOR i=0 TO 257: POKE 49152+i,204: PRINT "."; : NEXT i: REM $cc
40 DATA 62,34,207,201
50 FOR i=0 TO 3: READ a: POKE 52428+i,a: NEXT i
60 RANDOMIZE USR 32768
