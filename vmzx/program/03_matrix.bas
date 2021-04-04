5 CLEAR 49151: POKE 23606,0: POKE 23607,60
10 FOR n=1 TO 704: PRINT CHR$ (INT (RND*96)+32);: NEXT n
25 DATA 4,4,68,68,68,68,7,71
30 FOR n=49152 TO 49663: POKE n,0: NEXT n
40 FOR n=0 TO 512 STEP 34: RESTORE 25: FOR w=0 TO 7: READ a: POKE n+w+49152,a: NEXT w: NEXT n
45 BORDER 0: LET a$="": LET b$="": LET c$="": LET d$="": FOR n=0 TO 31: LET w=32+4*INT (RND*16): LET a$=a$+CHR$ w: LET b$=b$+CHR$ (w+1): LET c$=c$+CHR$ (w+2): LET d$=d$+CHR$ (w+3): NEXT n
46 FOR n=7 TO 0 STEP -1
50 POKE 23607,191: POKE 23606,n: POKE 23681,88: LPRINT b$: POKE 23681,89: LPRINT c$: POKE 23681,90: LPRINT d$: NEXT n: LET e$=d$: LET d$=c$: LET c$=b$: LET b$=a$: LET a$=e$: GO TO 46

https://worldofspectrum.org/files/download/dbdb35d34a82a78