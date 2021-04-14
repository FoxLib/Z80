10 BORDER 0: INK 7: PAPER 0: CLS
11 LET o=0.7: LET camx=0: LET camz=2.5
20 DEF FN m(a)=a-4*(a=5)
21 DEF FN x(a,b)=128+88*a/b
22 DEF FN y(a,b)=88+88*a/b
30 DIM w(8,2): DIM g(6,4): DIM u(6,16): DIM s(6)
40 DATA 2,1,4,3, 5,6,7,8, 1,2,6,5, 3,4,8,7, 6,2,3,7, 1,5,8,4
50 DATA -1,1,1, 1,1,1, 1,-1,1, -1,-1,1, -1,1,-1, 1,1,-1, 1,-1,-1, -1,-1,-1
60 FOR i=1 TO 6: READ g(i,1),g(i,2),g(i,3),g(i,4): NEXT i
70 RESTORE 50
80 LET ca=COS(o): LET sa=SIN(o)
90 FOR i=1 TO 8: READ a,b,c
100 LET ap=a*ca-c*sa+camx
110 LET cp=c*ca+a*sa+camz
120 LET w(i,1)=FN x(ap,cp):
130 LET w(i,2)=FN y(b,cp)
140 NEXT i
150 FOR i=1 TO 6
160 FOR j=1 TO 4
170 LET n=FN m((j+1))
180 LET u(i,4*j-3)=w(g(i,j),1)
190 LET u(i,4*j-2)=w(g(i,j),2)
200 LET u(i,4*j-1)=w(g(i,n),1)-u(i,4*j-3)
210 LET u(i,4*j-0)=w(g(i,n),2)-u(i,4*j-2)
220 NEXT j
225 LET x=u(i,4*1-3): LET y=u(i,4*1-2)
230 LET ABx=u(i,4*2-3)-x: LET ABy=u(i,4*2-2)-y
240 LET ACx=u(i,4*3-3)-x: LET ACy=u(i,4*3-2)-y
250 LET s(i)=ACx*ABy<ACy*ABx
260 NEXT i
265 CLS
270 FOR i=1 TO 6
280 IF s(i)>0 THEN GO TO 230
290 FOR j=1 TO 4
300 PLOT u(i,4*j-3),u(i,4*j-2): DRAW u(i,4*j-1), u(i,4*j)
310 NEXT j
320 NEXT i
330 LET o=o+0.1: GO TO 70
