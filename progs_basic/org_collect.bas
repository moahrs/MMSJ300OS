10 R=0:U=0:V=1
20 TEXT : D$ = CHR$ (4)
25 ONERR GOTO 11000
30 HOME : VTAB 1: HTAB 6: INVERSE : PRINT " MENU PRINCIPAL ": NORMAL
40 VTAB 5: HTAB 10: PRINT "1:- ABRIR UM ARQUIVO"
50 PRINT : HTAB 10: PRINT "2:- ENTRADA DE REGISTROS"
60 PRINT : HTAB 10: PRINT "3:- LISTAR REGISTROS"
70 PRINT : HTAB 10: PRINT "4:- BUSCA DE INFORMACOES"
80 PRINT : HTAB 10: PRINT "5:- GRAVAR O ARQUIVO"
90 PRINT : HTAB 10: PRINT "6:- CARREGAR UM ARQUIVO"
100 PRINT : HTAB 10: PRINT "7:- FIM DE PROGRAMA"
110 VTAB 20: HTAB 15: PRINT "OPCAO? ";
120 GET K$
130 IF K$ < "1" OR K$ > "7" THEN GOTO 120
135 IF R = 0 AND (K$ <> "1" AND (K$ <> "6" AND K$ <> "7")) THEN GOTO 120
140 PRINT CHR$(7):HOME:OP% = VAL(K$)
150 ON OP% GOSUB 1000,2000,6000,5000,7000,8000,6520
160 GOTO 30
1000 HTAB 8: INVERSE : PRINT "MONTAR UM NOVO ARQUIVO ": VTAB 15: HTAB 10: PRINT " VOCE CONFIRMA? (S/N) ";
1005 NORMAL
1007 get in$
1010 if IN$ <> "s" AND IN$ <> "n" THEN goto 1007
1020 IF IN$ <> "s" THEN RETURN
1025 rem if R>0 then clear
1030 if R>0 then D$ = CHRS (4):IN = 1: HOME : GOTO 150
1040 HOME : HTAB 8: INVERSE : PRINT " MONTAR UM NOVO ARQUIVO": NORMAL
1050 VTAB 3: HTAB 5: PRINT "NUMERO DE CAMPOS (1-8): ";: INPUT A%
1060 IF A% > 8 OR A% < 1 THEN 1050
1070 DIM C%(A%): DIM N$(A%)
1080 VTAB 7
1085 FOR J= 1 TO A%
1090 PRINT "NOME DO CAMPO ";int(J);" ";: INPUT N$(J):N$(J) = LEFT$(N$(J),10)
1100 PRINT "TAMANHO DO CAMPO ";int(J);" ";: INPUT C%(J):C%(J) = ABS(INT(C%(J)))
1110 IF C%(J) < 1 OR C%(J) > 25 THEN goto 1100
1120 TS% = 0: TS% = TS% + C%(N$): PRINT
1130 NEXT J
1033 REM R% = INT (( FRE (0) - 5000) / (TS% + 2 * A%)): IF R% > 4000 THEN R% = 4000
1135 R% = 3: REM RETIRAR ESTA LINHA!
1140 PRINT : PRINT "NUMERO MAXIMO DE REGISTROS: ";R%
1150 DIM A$(R%,A%): FOR I% = 1 TO 2000: NEXT : RETURN

11000 print d$;"CLOSE";goto 20