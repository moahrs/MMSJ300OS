5 HOME 
10 PRINT TAB(9);"CODICO DE DISTANCIA": PRINT 
20 PRINT TAB(14);"CUIDADO": PRINT 
30 PRINT TAB(7);"SEM ESPACOs ENTRE PALAVRAS" 
40 PRINT : PRINT 
50 PRINT "QUAL A SUA MENSAGEM ": INPUT A$ 
60 FOR J=1 TO 600:NEXT J:HOME 
70 FOR I = 1 TO LEN(A$) 
80 B$ = MID$ (A$,I,1)
90 V = ASC(B$) - 45 
100 IF V <= 32 THEN PRINT TAB(V);"*": GOTO 130 
110 V=V-26 
120 PRINT TAB(V);"*" 
130 NEXT I 