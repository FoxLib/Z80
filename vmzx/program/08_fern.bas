10 CLS: LET x=0: LET y=0
20 LET c=RND
30 IF c<0.01 THEN LET nx=0: LET ny=0.16*y: GO TO 70
40 IF c<0.08 THEN LET nx=0.2*x-.26*y: LET ny=0.23*x+0.22*y+ 1.6: GO TO 70
50 IF c<0.15 THEN LET nx=-0.15*x+.28*y: LET ny=0.26*x+0.24*y+0.44: GO TO 70
60 LET nx=0.85*x+0.04*y: LET ny=-0.04*x+0.85*y+1.6
70 LET x=nx: LET y=ny: PLOT 128+x*16,y*16: GO TO 20
