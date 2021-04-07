5 CLS: LET h=75: LET cx=0: LET cy=-1.5: LET cz=3: LET al=2.5
10 DATA -1,1,1, 1,1,1, 1,-1,1, -1,-1,1, -1,1,-1, 1,1,-1, 1,-1,-1, -1,-1,-1
20 DATA 2,1,4,3, 5,6,7,8, 1,2,6,5, 3,4,8,7, 6,2,3,7, 1,5,8,4
25 LET ca=COS(al): LET sa=SIN(al): RESTORE 10
30 DIM v(8,3): DIM f(6,4): DIM w(4,2)
40 FOR i=1 TO 8: READ v(i,1),v(i,2),v(i,3): NEXT i
50 FOR i=1 TO 6: READ f(i,1),f(i,2),f(i,3),f(i,4): NEXT i
55 CLS
60 FOR i=1 TO 6
65 FOR j=1 TO 4
70 LET x=v(f(i,j),1): LET y=v(f(i,j),2): LET z=v(f(i,j),3)
73 LET x2=x*ca-z*sa: LET z2=z*ca+x*sa
75 LET x=cx+x2: LET y=cy+y: LET z=cz+z2
80 LET w(j,1)=128+h*x/z: LET w(j,2)=140+h*y/z
100 NEXT j
110 FOR j=1 TO 4
120 LET ABx=w(2,1)-w(1,1): LET ABy=w(2,2)-w(1,2)
130 LET ACx=w(3,1)-w(1,1): LET ACy=w(3,2)-w(1,2)
140 IF ACx*ABy<ACy*ABx THEN GO TO 170
150 LET n=j+1: IF n=5 THEN LET n=1
160 PLOT w(j,1), w(j,2): DRAW w(n,1)-w(j,1),w(n,2)-w(j,2)
170 NEXT j
180 NEXT i
190 PAUSE 50
200 LET al=al+1: GO TO 25
