10 HGR : HCOLOR=15
20 MX = INT(256/8)-8 : MY = INT(192/8)-8
30 LET X = INT(256/2) : Y = INT(192/2) : C = 5
35 DX=8 : DY=0
40 GET K$
42 A = ASC(k$)
45 GOSUB 200
50 GOTO 40
60 END
200 REM check if UP, DOWN, LEFT or RIGHT key is pressed
210 HCOLOR=1
220 GOSUB 400
225 HCOLOR=C
230 IF A=19 THEN DY = 8 : DX = 0
240 IF A=17 THEN DY = -8 : DX = 0
250 IF A=18 THEN DX = -8 : DY = 0
260 IF A=20 THEN DX = 8 : DY = 0
265 X = X + DX : Y = Y + DY
266 IF Y > 180 THEN Y = 180 : DX = 8 : DY = 0 : IF X >= 245 THEN DX = -8
267 IF Y < 1 THEN Y = 1 : DX = 8 : DY = 0 : IF X >= 245 THEN DX = -8
268 IF X < 1 THEN X = 1 : DX = 0 : DY = 8 : IF Y >= 180 THEN DY = -8
269 IF X > 245 THEN X = 245 : DX = 0 : DY = 8 : IF Y >= 180 THEN DY = -8
280 GOSUB 400
295 LET C = C + 1
296 IF C > 15 THEN C = 5
298 HCOLOR=C 
300 RETURN
400 LET XP = X : LET YP = Y
410 HPLOT XP, YP TO XP+7, YP
420 HPLOT TO XP+7, YP+7
430 HPLOT TO XP, YP+7
440 HPLOT TO XP, YP
450 RETURN

