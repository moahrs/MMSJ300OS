; D:\PROJETOS\MMSJ300\PROGS_MONITOR\BASIC.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J.Fondse
; /********************************************************************************
; *    Programa    : basic.c
; *    Objetivo    : MMSJ-Basic para o MMSJ300
; *    Criado em   : 10/10/2022
; *    Programador : Moacir Jr.
; *--------------------------------------------------------------------------------
; * Data        Versao  Responsavel  Motivo
; * 10/10/2022  0.1     Moacir Jr.   Criacao Versao Beta
; * 26/06/2023  0.4     Moacir Jr.   Simplificacoes e ajustres
; * 27/06/2023  0.4a    Moacir Jr.   Adaptar processos de for-next e if-then-else
; * 01/07/2023  0.4b    Moacir Jr.   Ajuste de Bugs
; * 03/07/2023  0.5     Moacir Jr.   Colocar Logica Ponto Flutuante
; * 10/07/2023  0.5a    Moacir Jr.   Colocar Funcoes Graficas
; * 11/07/2023  0.5b    Moacir Jr.   Colocar DATA-READ
; * 20/07/2023  1.0     Moacir Jr.   Versao para publicacao
; * 21/07/2023  1.0a    Moacir Jr.   Ajustes de memoria e bugs
; * 23/07/2023  1.0b    Moacir Jr.   Ajustes bugs no for...next e if...then
; * 24/07/2023  1.0c    Moacir Jr.   Retirada "BYE" message. Ajustes de bugs no gosub...return
; * 25/07/2023  1.0d    Moacir Jr.   Ajuste no basInputGet, quando Get, mandar 1 pro inputLine e sem manipulacoa cursor
; * 20/01/2024  1.0e    Moacir Jr.   Colocar para iniciar direto no Basic
; *--------------------------------------------------------------------------------
; * Variables Simples: start at 00800000
; *   --------------------------------------------------------
; *   Type ($ = String, # = Real, % = Integer)
; *   Name (2 Bytes, 1st and 2nd letters of the name)
; *   --------------- --------------- ------------------------
; *   Integer         Real            String
; *   --------------- --------------- ------------------------
; *   0x00            0x00            Length
; *   Value MSB       Value MSB       Pointer to String (High)
; *   Value           Value           Pointer to String
; *   Value           Value           Pointer to String
; *   Value LSB       Value LSB       Pointer to String (Low)
; *   --------------- --------------- ------------------------
; *   Total: 8 Bytes
; *--------------------------------------------------------------------------------
; *
; *--------------------------------------------------------------------------------
; * To do
; *
; *--------------------------------------------------------------------------------
; *
; *********************************************************************************/
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "../mmsj300api.h"
; #include "../monitor.h"
; #include "basic.h"
; #define versionBasic "1.0e"
; //#define __TESTE_TOKENIZE__ 1
; //-----------------------------------------------------------------------------
; // Principal
; //-----------------------------------------------------------------------------
; void main(void)
; {
       section   code
       xdef      _main
_main:
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _printText.L,A2
       lea       _pProcess.L,A3
       lea       _pTypeLine.L,A4
       lea       _vbuf.L,A5
; unsigned char vRetInput;
; // Timer para o Random
; *(vmfp + Reg_TADR) = 0xF5;  // 245
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    #245,0(A0,D0.L)
; *(vmfp + Reg_TACR) = 0x02;  // prescaler de 10. total 2,4576Mhz/10*245 = 1003KHz
       move.l    _vmfp.L,A0
       move.w    _Reg_TACR.L,D0
       and.l     #65535,D0
       move.b    #2,0(A0,D0.L)
; if (!*startBasic)
       move.l    _startBasic.L,A0
       tst.w     (A0)
       bne.s     main_1
; clearScr();
       jsr       _clearScr
main_1:
; printText("MMSJ-BASIC v"versionBasic);
       pea       @basic_95.L
       jsr       (A2)
       addq.w    #4,A7
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       (A2)
       addq.w    #4,A7
; if (!*startBasic)
       move.l    _startBasic.L,A0
       tst.w     (A0)
       bne.s     main_3
; printText("Utility (c) 2022-2024\r\n\0");
       pea       @basic_97.L
       jsr       (A2)
       addq.w    #4,A7
main_3:
; printText("OK\r\n\0");
       pea       @basic_98.L
       jsr       (A2)
       addq.w    #4,A7
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; *vbuf = '\0';
       move.l    (A5),A0
       clr.b     (A0)
; *pProcess = 0x01;
       move.l    (A3),A0
       move.b    #1,(A0)
; *pTypeLine = 0x00;
       move.l    (A4),A0
       clr.b     (A0)
; *nextAddrLine = pStartProg;
       move.l    _nextAddrLine.L,A0
       move.l    _pStartProg.L,(A0)
; *firstLineNumber = 0;
       move.l    _firstLineNumber.L,A0
       clr.w     (A0)
; *addrFirstLineNumber = 0;
       move.l    _addrFirstLineNumber.L,A0
       clr.l     (A0)
; *traceOn = 0;
       move.l    _traceOn.L,A0
       clr.b     (A0)
; *lastHgrX = 0;
       move.l    _lastHgrX.L,A0
       clr.b     (A0)
; *lastHgrY = 0;
       move.l    _lastHgrY.L,A0
       clr.b     (A0)
; *fgcolorAnt = *fgcolor;
       move.l    _fgcolor.L,A0
       move.l    _fgcolorAnt.L,A1
       move.b    (A0),(A1)
; *bgcolorAnt = *bgcolor;
       move.l    _bgcolor.L,A0
       move.l    _bgcolorAnt.L,A1
       move.b    (A0),(A1)
; while (*pProcess)
main_5:
       move.l    (A3),A0
       tst.b     (A0)
       beq       main_7
; {
; vRetInput = inputLine(128,'$');
       pea       36
       pea       128
       jsr       _inputLine
       addq.w    #8,A7
       move.b    D0,D2
; if (*vbuf != 0x00 && (vRetInput == 0x0D || vRetInput == 0x0A))
       move.l    (A5),A0
       move.b    (A0),D0
       beq       main_8
       cmp.b     #13,D2
       beq.s     main_10
       cmp.b     #10,D2
       bne       main_8
main_10:
; {
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       (A2)
       addq.w    #4,A7
; processLine();
       jsr       _processLine
; if (!*pTypeLine && *pProcess)
       move.l    (A4),A0
       tst.b     (A0)
       bne.s     main_11
       move.l    (A3),A0
       tst.b     (A0)
       beq.s     main_11
; printText("\r\nOK\0");
       pea       @basic_99.L
       jsr       (A2)
       addq.w    #4,A7
main_11:
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; *vbuf = '\0';
       move.l    (A5),A0
       clr.b     (A0)
; if (!*pTypeLine && *pProcess)
       move.l    (A4),A0
       tst.b     (A0)
       bne.s     main_13
       move.l    (A3),A0
       tst.b     (A0)
       beq.s     main_13
; printText("\r\n\0");   // printText("\r\n>\0");
       pea       @basic_96.L
       jsr       (A2)
       addq.w    #4,A7
main_13:
       bra.s     main_15
main_8:
; }
; else if (vRetInput != 0x1B)
       cmp.b     #27,D2
       beq.s     main_15
; {
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       (A2)
       addq.w    #4,A7
main_15:
       bra       main_5
main_7:
; }
; }
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/A2/A3/A4/A5
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; void processLine(void)
; {
       xdef      _processLine
_processLine:
       link      A6,#-616
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -614(A6),A2
       lea       -570(A6),A3
       lea       _comandLineTokenized.L,A4
       lea       _strcmp.L,A5
; unsigned char linhacomando[32], vloop, vToken;
; unsigned char *blin = vbuf;
       move.l    _vbuf.L,D4
; unsigned short varg = 0;
       clr.w     -580(A6)
; unsigned short ix, iy, iz, ikk, kt;
; unsigned short vbytepic = 0, vrecfim;
       clr.w     -576(A6)
; unsigned char cuntam, vLinhaArg[255], vparam2[16], vpicret;
; char vSpace = 0;
       clr.b     -297(A6)
; int vReta;
; typeInf vRetInf;
; unsigned short vTam = 0;
       clr.w     D5
; unsigned char *pSave = *nextAddrLine;
       move.l    _nextAddrLine.L,A0
       move.l    (A0),-34(A6)
; unsigned long vNextAddr = 0;
       clr.l     -30(A6)
; unsigned char vTimer;
; unsigned char vBuffer[20];
; unsigned char *vTempPointer;
; // Separar linha entre comando e argumento
; linhacomando[0] = '\0';
       clr.b     (A2)
; vLinhaArg[0] = '\0';
       clr.b     (A3)
; ix = 0;
       clr.w     D3
; iy = 0;
       clr.w     D2
; while (*blin)
processLine_1:
       move.l    D4,A0
       tst.b     (A0)
       beq       processLine_3
; {
; if (!varg && *blin >= 0x20 && *blin <= 0x2F)
       tst.w     -580(A6)
       bne.s     processLine_6
       moveq     #1,D0
       bra.s     processLine_7
processLine_6:
       clr.l     D0
processLine_7:
       and.l     #65535,D0
       beq       processLine_4
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       blo       processLine_4
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #47,D0
       bhi       processLine_4
; {
; varg = 0x01;
       move.w    #1,-580(A6)
; linhacomando[ix] = '\0';
       and.l     #65535,D3
       clr.b     0(A2,D3.L)
; iy = ix;
       move.w    D3,D2
; ix = 0;
       clr.w     D3
; if (*blin != 0x20)
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       beq.s     processLine_8
; vLinhaArg[ix++] = *blin;
       move.l    D4,A0
       move.w    D3,D0
       addq.w    #1,D3
       and.l     #65535,D0
       move.b    (A0),0(A3,D0.L)
       bra.s     processLine_9
processLine_8:
; else
; vSpace = 1;
       move.b    #1,-297(A6)
processLine_9:
       bra.s     processLine_5
processLine_4:
; }
; else
; {
; if (!varg)
       tst.w     -580(A6)
       bne.s     processLine_10
; linhacomando[ix] = *blin;
       move.l    D4,A0
       and.l     #65535,D3
       move.b    (A0),0(A2,D3.L)
       bra.s     processLine_11
processLine_10:
; else
; vLinhaArg[ix] = *blin;
       move.l    D4,A0
       and.l     #65535,D3
       move.b    (A0),0(A3,D3.L)
processLine_11:
; ix++;
       addq.w    #1,D3
processLine_5:
; }
; *blin++;
       move.l    D4,A0
       addq.l    #1,D4
       bra       processLine_1
processLine_3:
; }
; if (!varg)
       tst.w     -580(A6)
       bne.s     processLine_12
; {
; linhacomando[ix] = '\0';
       and.l     #65535,D3
       clr.b     0(A2,D3.L)
; iy = ix;
       move.w    D3,D2
       bra.s     processLine_13
processLine_12:
; }
; else
; vLinhaArg[ix] = '\0';
       and.l     #65535,D3
       clr.b     0(A3,D3.L)
processLine_13:
; vpicret = 0;
       clr.b     -298(A6)
; // Processar e definir o que fazer
; if (linhacomando[0] != 0)
       move.b    (A2),D0
       beq       processLine_54
; {
; // Se for numero o inicio da linha, eh entrada de programa, senao eh comando direto
; if (linhacomando[0] >= 0x31 && linhacomando[0] <= 0x39) // 0 nao é um numero de linha valida
       move.b    (A2),D0
       cmp.b     #49,D0
       blo.s     processLine_16
       move.b    (A2),D0
       cmp.b     #57,D0
       bhi.s     processLine_16
; {
; *pTypeLine = 0x01;
       move.l    _pTypeLine.L,A0
       move.b    #1,(A0)
; // Entrada de programa
; tokenizeLine(vLinhaArg);
       move.l    A3,-(A7)
       jsr       _tokenizeLine
       addq.w    #4,A7
; saveLine(linhacomando, vLinhaArg);
       move.l    A3,-(A7)
       move.l    A2,-(A7)
       jsr       _saveLine
       addq.w    #8,A7
       bra       processLine_54
processLine_16:
; }
; else
; {
; *pTypeLine = 0x00;
       move.l    _pTypeLine.L,A0
       clr.b     (A0)
; for (iz = 0; iz < iy; iz++)
       moveq     #0,D7
processLine_18:
       cmp.w     D2,D7
       bhs.s     processLine_20
; linhacomando[iz] = toupper(linhacomando[iz]);
       and.l     #65535,D7
       move.b    0(A2,D7.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       and.l     #65535,D7
       move.b    D0,0(A2,D7.L)
       addq.w    #1,D7
       bra       processLine_18
processLine_20:
; // Comando Direto
; if (!strcmp(linhacomando,"HOME") && iy == 4)
       pea       @basic_48.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_21
       cmp.w     #4,D2
       bne.s     processLine_21
; {
; clearScr();
       jsr       _clearScr
       bra       processLine_54
processLine_21:
; }
; else if (!strcmp(linhacomando,"NEW") && iy == 3)
       pea       @basic_100.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_23
       cmp.w     #3,D2
       bne.s     processLine_23
; {
; *pStartProg = 0x00;
       move.l    _pStartProg.L,A0
       clr.b     (A0)
; *(pStartProg + 1) = 0x00;
       move.l    _pStartProg.L,A0
       clr.b     1(A0)
; *(pStartProg + 2) = 0x00;
       move.l    _pStartProg.L,A0
       clr.b     2(A0)
; *nextAddrLine = pStartProg;
       move.l    _nextAddrLine.L,A0
       move.l    _pStartProg.L,(A0)
; *firstLineNumber = 0;
       move.l    _firstLineNumber.L,A0
       clr.w     (A0)
; *addrFirstLineNumber = 0;
       move.l    _addrFirstLineNumber.L,A0
       clr.l     (A0)
       bra       processLine_54
processLine_23:
; }
; else if (!strcmp(linhacomando,"EDIT") && iy == 4)
       pea       @basic_101.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_25
       cmp.w     #4,D2
       bne.s     processLine_25
; {
; editLine(vLinhaArg);
       move.l    A3,-(A7)
       jsr       _editLine
       addq.w    #4,A7
       bra       processLine_54
processLine_25:
; }
; else if (!strcmp(linhacomando,"LIST") && iy == 4)
       pea       @basic_102.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_27
       cmp.w     #4,D2
       bne.s     processLine_27
; {
; listProg(vLinhaArg, 0);
       clr.l     -(A7)
       move.l    A3,-(A7)
       jsr       _listProg
       addq.w    #8,A7
       bra       processLine_54
processLine_27:
; }
; else if (!strcmp(linhacomando,"LISTP") && iy == 5)
       pea       @basic_103.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_29
       cmp.w     #5,D2
       bne.s     processLine_29
; {
; listProg(vLinhaArg, 1);
       pea       1
       move.l    A3,-(A7)
       jsr       _listProg
       addq.w    #8,A7
       bra       processLine_54
processLine_29:
; }
; else if (!strcmp(linhacomando,"RUN") && iy == 3)
       pea       @basic_104.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_31
       cmp.w     #3,D2
       bne.s     processLine_31
; {
; runProg(vLinhaArg);
       move.l    A3,-(A7)
       jsr       _runProg
       addq.w    #4,A7
       bra       processLine_54
processLine_31:
; }
; else if (!strcmp(linhacomando,"DEL") && iy == 3)
       pea       @basic_105.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_33
       cmp.w     #3,D2
       bne.s     processLine_33
; {
; delLine(vLinhaArg);
       move.l    A3,-(A7)
       jsr       _delLine
       addq.w    #4,A7
       bra       processLine_54
processLine_33:
; }
; else if (!strcmp(linhacomando,"XLOAD") && iy == 5)
       pea       @basic_106.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_35
       cmp.w     #5,D2
       bne.s     processLine_35
; {
; basXBasLoad();
       jsr       _basXBasLoad
       bra       processLine_54
processLine_35:
; }
; else if (!strcmp(linhacomando,"TIMER") && iy == 5)
       pea       @basic_107.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne       processLine_37
       cmp.w     #5,D2
       bne       processLine_37
; {
; // Ler contador A do 68901
; vTimer = *(vmfp + Reg_TADR);
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),-25(A6)
; // Devolve pra tela
; itoa(vTimer,vBuffer,10);
       pea       10
       pea       -24(A6)
       move.b    -25(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; printText("Timer: ");
       pea       @basic_108.L
       jsr       _printText
       addq.w    #4,A7
; printText(vBuffer);
       pea       -24(A6)
       jsr       _printText
       addq.w    #4,A7
; printText("ms\r\n\0");
       pea       @basic_109.L
       jsr       _printText
       addq.w    #4,A7
       bra       processLine_54
processLine_37:
; }
; else if (!strcmp(linhacomando,"TRACE") && iy == 5)
       pea       @basic_110.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_39
       cmp.w     #5,D2
       bne.s     processLine_39
; {
; *traceOn = 1;
       move.l    _traceOn.L,A0
       move.b    #1,(A0)
       bra       processLine_54
processLine_39:
; }
; else if (!strcmp(linhacomando,"NOTRACE") && iy == 7)
       pea       @basic_111.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_41
       cmp.w     #7,D2
       bne.s     processLine_41
; {
; *traceOn = 0;
       move.l    _traceOn.L,A0
       clr.b     (A0)
       bra       processLine_54
processLine_41:
; }
; // *************************************************
; // ESSE COMANDO NAO VAI EXISTIR QUANDO FOR PRA BIOS
; // *************************************************
; else if (!strcmp(linhacomando,"QUIT") && iy == 4)
       pea       @basic_112.L
       move.l    A2,-(A7)
       jsr       (A5)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processLine_43
       cmp.w     #4,D2
       bne.s     processLine_43
; {
; *pProcess = 0x00;
       move.l    _pProcess.L,A0
       clr.b     (A0)
       bra       processLine_54
processLine_43:
; }
; // *************************************************
; // *************************************************
; // *************************************************
; else
; {
; // Tokeniza a linha toda
; strcpy(vRetInf.tString, linhacomando);
       move.l    A2,-(A7)
       lea       -292(A6),A0
       move.l    A0,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; if (vSpace)
       tst.b     -297(A6)
       beq.s     processLine_45
; strcat(vRetInf.tString, " ");
       pea       @basic_113.L
       lea       -292(A6),A0
       move.l    A0,-(A7)
       jsr       _strcat
       addq.w    #8,A7
processLine_45:
; strcat(vRetInf.tString, vLinhaArg);
       move.l    A3,-(A7)
       lea       -292(A6),A0
       move.l    A0,-(A7)
       jsr       _strcat
       addq.w    #8,A7
; tokenizeLine(vRetInf.tString);
       lea       -292(A6),A0
       move.l    A0,-(A7)
       jsr       _tokenizeLine
       addq.w    #4,A7
; strcpy(vLinhaArg, vRetInf.tString);
       lea       -292(A6),A0
       move.l    A0,-(A7)
       move.l    A3,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; // Salva a linha pra ser interpretada
; vTam = strlen(vLinhaArg);
       move.l    A3,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.w    D0,D5
; vNextAddr = comandLineTokenized + (vTam + 6);
       move.l    (A4),D0
       move.w    D5,D1
       addq.w    #6,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-30(A6)
; *comandLineTokenized = ((vNextAddr & 0xFF0000) >> 16);
       move.l    -30(A6),D0
       and.l     #16711680,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.l    (A4),A0
       move.b    D0,(A0)
; *(comandLineTokenized + 1) = ((vNextAddr & 0xFF00) >> 8);
       move.l    -30(A6),D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.l    (A4),A0
       move.b    D0,1(A0)
; *(comandLineTokenized + 2) =  (vNextAddr & 0xFF);
       move.l    -30(A6),D0
       and.l     #255,D0
       move.l    (A4),A0
       move.b    D0,2(A0)
; // Grava numero da linha
; *(comandLineTokenized + 3) = 0xFF;
       move.l    (A4),A0
       move.b    #255,3(A0)
; *(comandLineTokenized + 4) = 0xFF;
       move.l    (A4),A0
       move.b    #255,4(A0)
; // Grava linha tokenizada
; for(kt = 0; kt < vTam; kt++)
       clr.w     D6
processLine_47:
       cmp.w     D5,D6
       bhs.s     processLine_49
; *(comandLineTokenized + (kt + 5)) = vLinhaArg[kt];
       and.l     #65535,D6
       move.l    (A4),A0
       move.w    D6,D0
       addq.w    #5,D0
       and.l     #65535,D0
       move.b    0(A3,D6.L),0(A0,D0.L)
       addq.w    #1,D6
       bra       processLine_47
processLine_49:
; // Grava final linha 0x00
; *(comandLineTokenized + (vTam + 5)) = 0x00;
       move.l    (A4),A0
       move.w    D5,D0
       addq.w    #5,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(comandLineTokenized + (vTam + 6)) = 0x00;
       move.l    (A4),A0
       move.w    D5,D0
       addq.w    #6,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(comandLineTokenized + (vTam + 7)) = 0x00;
       move.l    (A4),A0
       move.w    D5,D0
       addq.w    #7,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(comandLineTokenized + (vTam + 8)) = 0x00;
       move.l    (A4),A0
       move.w    D5,D0
       addq.w    #8,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *nextAddrSimpVar = pStartSimpVar;
       move.l    _nextAddrSimpVar.L,A0
       move.l    _pStartSimpVar.L,(A0)
; *nextAddrArrayVar = pStartArrayVar;
       move.l    _nextAddrArrayVar.L,A0
       move.l    _pStartArrayVar.L,(A0)
; *nextAddrString = pStartString;
       move.l    _nextAddrString.L,A0
       move.l    _pStartString.L,(A0)
; *vMaisTokens = 0;
       move.l    _vMaisTokens.L,A0
       clr.b     (A0)
; *vParenteses = 0x00;
       move.l    _vParenteses.L,A0
       clr.b     (A0)
; *vTemIf = 0x00;
       move.l    _vTemIf.L,A0
       clr.b     (A0)
; *vTemThen = 0;
       move.l    _vTemThen.L,A0
       clr.b     (A0)
; *vTemElse = 0;
       move.l    _vTemElse.L,A0
       clr.b     (A0)
; *vTemIfAndOr = 0x00;
       move.l    _vTemIfAndOr.L,A0
       clr.b     (A0)
; *pointerRunProg = comandLineTokenized + 5;
       move.l    (A4),D0
       addq.l    #5,D0
       move.l    _pointerRunProg.L,A0
       move.l    D0,(A0)
; vRetInf.tString[0] = 0x00;
       lea       -292(A6),A0
       clr.b     (A0)
; *ftos=0;
       move.l    _ftos.L,A0
       clr.l     (A0)
; *gtos=0;
       move.l    _gtos.L,A0
       clr.l     (A0)
; *vErroProc = 0;
       move.l    _vErroProc.L,A0
       clr.w     (A0)
; *randSeed = *(vmfp + Reg_TADR);
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.l     #255,D0
       move.l    _randSeed.L,A0
       move.l    D0,(A0)
; do
; {
processLine_50:
; *doisPontos = 0;
       move.l    _doisPontos.L,A0
       clr.b     (A0)
; *vInicioSentenca = 1;
       move.l    _vInicioSentenca.L,A0
       move.b    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),-4(A6)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
; vReta = executeToken(*vTempPointer);
       move.l    -4(A6),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _executeToken
       addq.w    #4,A7
       move.l    D0,-296(A6)
       move.l    _doisPontos.L,A0
       tst.b     (A0)
       bne       processLine_50
; } while (*doisPontos);
; #ifndef __TESTE_TOKENIZE__
; if (*vdp_mode != VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     processLine_52
; basText();
       jsr       _basText
processLine_52:
; #endif
; if (*vErroProc)
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     processLine_54
; {
; showErrorMessage(*vErroProc, 0);
       clr.l     -(A7)
       move.l    _vErroProc.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _showErrorMessage
       addq.w    #8,A7
processLine_54:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; }
; }
; }
; //-----------------------------------------------------------------------------
; // Transforma linha em tokens, se existirem
; //-----------------------------------------------------------------------------
; void tokenizeLine(unsigned char *pTokenized)
; {
       xdef      _tokenizeLine
_tokenizeLine:
       link      A6,#-828
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -828(A6),A2
       lea       -310(A6),A3
       lea       @basic_keywords.L,A4
       lea       -572(A6),A5
; unsigned char vLido[255], vLidoCaps[255], vAspas, vAchou = 0;
       clr.b     -315(A6)
; unsigned char *blin = pTokenized;
       move.l    8(A6),D3
; unsigned short ix, iy, kt, iz, iw;
; unsigned char vToken, vLinhaArg[255], vparam2[16], vpicret;
; char vbuffer [sizeof(long)*8+1];
; char vFirstComp = 0;
       moveq     #0,D7
; char isToken;
; char vTemRem = 0;
       clr.b     -1(A6)
; //    unsigned char sqtdtam[20];
; // Separar linha entre comando e argumento
; vLinhaArg[0] = '\0';
       clr.b     (A3)
; vLido[0]  = '\0';
       clr.b     (A2)
; ix = 0;
       clr.w     D4
; iy = 0;
       clr.w     D5
; vAspas = 0;
       clr.b     -316(A6)
; while (1)
tokenizeLine_1:
; {
; vLido[ix] = '\0';
       and.l     #65535,D4
       clr.b     0(A2,D4.L)
; if (*blin == 0x22)
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #34,D0
       bne.s     tokenizeLine_4
; vAspas = !vAspas;
       tst.b     -316(A6)
       bne.s     tokenizeLine_6
       moveq     #1,D0
       bra.s     tokenizeLine_7
tokenizeLine_6:
       clr.l     D0
tokenizeLine_7:
       move.b    D0,-316(A6)
tokenizeLine_4:
; // Se for quebrador sequencia, verifica se é um token
; if ((!vTemRem && !vAspas && strchr(" ;,+-<>()/*^=:",*blin)) || !*blin)
       tst.b     -1(A6)
       bne.s     tokenizeLine_12
       moveq     #1,D0
       bra.s     tokenizeLine_13
tokenizeLine_12:
       clr.l     D0
tokenizeLine_13:
       tst.b     D0
       beq.s     tokenizeLine_11
       tst.b     -316(A6)
       bne.s     tokenizeLine_11
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @basic_114.L
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       bne.s     tokenizeLine_10
tokenizeLine_11:
       move.l    D3,A0
       tst.b     (A0)
       bne.s     tokenizeLine_14
       moveq     #1,D0
       bra.s     tokenizeLine_15
tokenizeLine_14:
       clr.l     D0
tokenizeLine_15:
       and.l     #255,D0
       beq       tokenizeLine_8
tokenizeLine_10:
; {
; // Montar comparacoes "<>", ">=" e "<="
; if (((*blin == 0x3C || *blin == 0x3E) && (!vFirstComp && (*(blin + 1) == 0x3E || *(blin + 1) == 0x3D))) || (vFirstComp && *blin == 0x3D) || (vFirstComp && *blin == 0x3E))
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #60,D0
       beq.s     tokenizeLine_20
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #62,D0
       bne       tokenizeLine_21
tokenizeLine_20:
       tst.b     D7
       bne.s     tokenizeLine_22
       moveq     #1,D0
       bra.s     tokenizeLine_23
tokenizeLine_22:
       clr.l     D0
tokenizeLine_23:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq.s     tokenizeLine_21
       move.l    D3,A0
       move.b    1(A0),D0
       cmp.b     #62,D0
       beq       tokenizeLine_18
       move.l    D3,A0
       move.b    1(A0),D0
       cmp.b     #61,D0
       beq       tokenizeLine_18
tokenizeLine_21:
       ext.w     D7
       ext.l     D7
       tst.l     D7
       beq.s     tokenizeLine_24
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #61,D0
       beq.s     tokenizeLine_18
tokenizeLine_24:
       ext.w     D7
       ext.l     D7
       tst.l     D7
       beq       tokenizeLine_16
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #62,D0
       bne       tokenizeLine_16
tokenizeLine_18:
; {
; if (!vFirstComp)
       tst.b     D7
       bne.s     tokenizeLine_25
; {
; for(kt = 0; kt < ix; kt++)
       clr.w     D2
tokenizeLine_27:
       cmp.w     D4,D2
       bhs.s     tokenizeLine_29
; vLinhaArg[iy++] = vLido[kt];
       and.l     #65535,D2
       move.w    D5,D0
       addq.w    #1,D5
       and.l     #65535,D0
       move.b    0(A2,D2.L),0(A3,D0.L)
       addq.w    #1,D2
       bra       tokenizeLine_27
tokenizeLine_29:
; vLido[0] = 0x00;
       clr.b     (A2)
; ix = 0;
       clr.w     D4
; vFirstComp = 1;
       moveq     #1,D7
tokenizeLine_25:
; }
; vLido[ix++] = *blin;
       move.l    D3,A0
       move.w    D4,D0
       addq.w    #1,D4
       and.l     #65535,D0
       move.b    (A0),0(A2,D0.L)
; if (ix < 2)
       cmp.w     #2,D4
       bhs.s     tokenizeLine_30
; {
; blin++;
       addq.l    #1,D3
; continue;
       bra       tokenizeLine_2
tokenizeLine_30:
; }
; vFirstComp = 0;
       moveq     #0,D7
tokenizeLine_16:
; }
; if (vLido[0])
       tst.b     (A2)
       beq       tokenizeLine_32
; {
; vToken = 0;
       clr.b     D6
; /*writeLongSerial("Aqui 332.666.2-[");
; itoa(ix,sqtdtam,10);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*blin,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]\r\n");*/
; if (ix > 1)
       cmp.w     #1,D4
       bls       tokenizeLine_41
; {
; // Transforma em Caps pra comparar com os tokens
; for (kt = 0; kt < ix; kt++)
       clr.w     D2
tokenizeLine_36:
       cmp.w     D4,D2
       bhs.s     tokenizeLine_38
; vLidoCaps[kt] = toupper(vLido[kt]);
       and.l     #65535,D2
       move.b    0(A2,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       and.l     #65535,D2
       move.b    D0,0(A5,D2.L)
       addq.w    #1,D2
       bra       tokenizeLine_36
tokenizeLine_38:
; vLidoCaps[ix] = 0x00;
       and.l     #65535,D4
       clr.b     0(A5,D4.L)
; iz = strlen(vLidoCaps);
       move.l    A5,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.w    D0,-314(A6)
; // Compara pra ver se é um token
; for(kt = 0; kt < keywords_count; kt++)
       clr.w     D2
tokenizeLine_39:
       and.l     #65535,D2
       cmp.l     _keywords_count.L,D2
       bhs       tokenizeLine_41
; {
; iw = strlen(keywords[kt].keyword);
       and.l     #65535,D2
       move.l    D2,D1
       lsl.l     #3,D1
       move.l    0(A4,D1.L),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.w    D0,-312(A6)
; if (iw == 2 && iz == iw)
       move.w    -312(A6),D0
       cmp.w     #2,D0
       bne       tokenizeLine_42
       move.w    -314(A6),D0
       cmp.w     -312(A6),D0
       bne       tokenizeLine_42
; {
; if (vLidoCaps[0] == keywords[kt].keyword[0] && vLidoCaps[1] == keywords[kt].keyword[1])
       and.l     #65535,D2
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    0(A4,D0.L),A0
       move.b    (A5),D0
       cmp.b     (A0),D0
       bne.s     tokenizeLine_44
       and.l     #65535,D2
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    0(A4,D0.L),A0
       move.b    1(A5),D0
       cmp.b     1(A0),D0
       bne.s     tokenizeLine_44
; {
; vToken = keywords[kt].token;
       and.l     #65535,D2
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A4,D0.L),A0
       move.l    4(A0),D0
       move.b    D0,D6
; break;
       bra       tokenizeLine_41
tokenizeLine_44:
       bra       tokenizeLine_48
tokenizeLine_42:
; }
; }
; else if (iz==iw)
       move.w    -314(A6),D0
       cmp.w     -312(A6),D0
       bne       tokenizeLine_48
; {
; if (strncmp(vLidoCaps, keywords[kt].keyword, iw) == 0)
       move.w    -312(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       and.l     #65535,D2
       move.l    D2,D1
       lsl.l     #3,D1
       move.l    0(A4,D1.L),-(A7)
       move.l    A5,-(A7)
       jsr       _strncmp
       add.w     #12,A7
       tst.l     D0
       bne.s     tokenizeLine_48
; {
; vToken = keywords[kt].token;
       and.l     #65535,D2
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A4,D0.L),A0
       move.l    4(A0),D0
       move.b    D0,D6
; break;
       bra.s     tokenizeLine_41
tokenizeLine_48:
       addq.w    #1,D2
       bra       tokenizeLine_39
tokenizeLine_41:
; }
; }
; }
; }
; if (vToken)
       tst.b     D6
       beq       tokenizeLine_50
; {
; if (vToken == 0x8C) // REM
       and.w     #255,D6
       cmp.w     #140,D6
       bne.s     tokenizeLine_52
; vTemRem = 1;
       move.b    #1,-1(A6)
tokenizeLine_52:
; vLinhaArg[iy++] = vToken;
       move.w    D5,D0
       addq.w    #1,D5
       and.l     #65535,D0
       move.b    D6,0(A3,D0.L)
; //if (*blin == 0x28 || *blin == 0x29)
; //    vLinhaArg[iy++] = *blin;
; //if (*blin == 0x3A)  // :
; if (*blin && *blin != 0x20 && vToken < 0xF0 && !vTemRem)
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       beq       tokenizeLine_54
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       beq       tokenizeLine_54
       and.w     #255,D6
       cmp.w     #240,D6
       bhs       tokenizeLine_54
       tst.b     -1(A6)
       bne.s     tokenizeLine_56
       moveq     #1,D0
       bra.s     tokenizeLine_57
tokenizeLine_56:
       clr.l     D0
tokenizeLine_57:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq.s     tokenizeLine_54
; vLinhaArg[iy++] = toupper(*blin);
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.w    D5,D1
       addq.w    #1,D5
       and.l     #65535,D1
       move.b    D0,0(A3,D1.L)
tokenizeLine_54:
       bra       tokenizeLine_61
tokenizeLine_50:
; }
; else
; {
; for(kt = 0; kt < ix; kt++)
       clr.w     D2
tokenizeLine_58:
       cmp.w     D4,D2
       bhs.s     tokenizeLine_60
; vLinhaArg[iy++] = vLido[kt];
       and.l     #65535,D2
       move.w    D5,D0
       addq.w    #1,D5
       and.l     #65535,D0
       move.b    0(A2,D2.L),0(A3,D0.L)
       addq.w    #1,D2
       bra       tokenizeLine_58
tokenizeLine_60:
; if (*blin && *blin != 0x20)
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       beq.s     tokenizeLine_61
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       beq.s     tokenizeLine_61
; vLinhaArg[iy++] = toupper(*blin);
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.w    D5,D1
       addq.w    #1,D5
       and.l     #65535,D1
       move.b    D0,0(A3,D1.L)
tokenizeLine_61:
       bra       tokenizeLine_63
tokenizeLine_32:
; }
; }
; else
; {
; if (*blin && *blin != 0x20)
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       beq.s     tokenizeLine_63
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       beq.s     tokenizeLine_63
; vLinhaArg[iy++] = toupper(*blin);
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.w    D5,D1
       addq.w    #1,D5
       and.l     #65535,D1
       move.b    D0,0(A3,D1.L)
tokenizeLine_63:
; }
; if (!*blin)
       move.l    D3,A0
       tst.b     (A0)
       bne.s     tokenizeLine_65
; break;
       bra       tokenizeLine_3
tokenizeLine_65:
; vLido[0] = '\0';
       clr.b     (A2)
; ix = 0;
       clr.w     D4
       bra       tokenizeLine_68
tokenizeLine_8:
; }
; else
; {
; if (!vAspas && !vTemRem)
       tst.b     -316(A6)
       bne       tokenizeLine_67
       tst.b     -1(A6)
       bne.s     tokenizeLine_69
       moveq     #1,D0
       bra.s     tokenizeLine_70
tokenizeLine_69:
       clr.l     D0
tokenizeLine_70:
       tst.b     D0
       beq.s     tokenizeLine_67
; vLido[ix++] = toupper(*blin);
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.w    D4,D1
       addq.w    #1,D4
       and.l     #65535,D1
       move.b    D0,0(A2,D1.L)
       bra.s     tokenizeLine_68
tokenizeLine_67:
; else
; vLido[ix++] = *blin;
       move.l    D3,A0
       move.w    D4,D0
       addq.w    #1,D4
       and.l     #65535,D0
       move.b    (A0),0(A2,D0.L)
tokenizeLine_68:
; }
; blin++;
       addq.l    #1,D3
tokenizeLine_2:
       bra       tokenizeLine_1
tokenizeLine_3:
; }
; vLinhaArg[iy] = 0x00;
       and.l     #65535,D5
       clr.b     0(A3,D5.L)
; for(kt = 0; kt < iy; kt++)
       clr.w     D2
tokenizeLine_71:
       cmp.w     D5,D2
       bhs.s     tokenizeLine_73
; pTokenized[kt] = vLinhaArg[kt];
       and.l     #65535,D2
       move.l    8(A6),A0
       and.l     #65535,D2
       move.b    0(A3,D2.L),0(A0,D2.L)
       addq.w    #1,D2
       bra       tokenizeLine_71
tokenizeLine_73:
; pTokenized[iy] = 0x00;
       move.l    8(A6),A0
       and.l     #65535,D5
       clr.b     0(A0,D5.L)
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Salva a linha no formato:
; // NN NN NN LL LL xxxxxxxxxxxx 00
; // onde:
; //      NN NN NN         = endereco da proxima linha
; //      LL LL            = Numero da linha
; //      xxxxxxxxxxxxxx   = Linha Tokenizada
; //      00               = Indica fim da linha
; //-----------------------------------------------------------------------------
; void saveLine(unsigned char *pNumber, unsigned char *pTokenized)
; {
       xdef      _saveLine
_saveLine:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _nextAddrLine.L,A2
       lea       _firstLineNumber.L,A5
; unsigned short vTam = 0, kt;
       move.w    #0,A3
; unsigned char *pSave = *nextAddrLine;
       move.l    (A2),A0
       move.l    (A0),D5
; unsigned long vNextAddr = 0, vAntAddr = 0, vNextAddr2 = 0;
       clr.l     D4
       moveq     #0,D7
       move.w    #0,A4
; unsigned short vNumLin = 0;
       clr.w     D3
; unsigned char *pAtu = *nextAddrLine, *pLast = *nextAddrLine;
       move.l    (A2),A0
       move.l    (A0),D2
       move.l    (A2),A0
       move.l    (A0),D6
; vNumLin = atoi(pNumber);
       move.l    8(A6),-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,D3
; if (*firstLineNumber == 0)
       move.l    (A5),A0
       move.w    (A0),D0
       bne.s     saveLine_1
; {
; *firstLineNumber = vNumLin;
       move.l    (A5),A0
       move.w    D3,(A0)
; *addrFirstLineNumber = pStartProg;
       move.l    _addrFirstLineNumber.L,A0
       move.l    _pStartProg.L,(A0)
       bra       saveLine_3
saveLine_1:
; }
; else
; {
; vNextAddr = findNumberLine(vNumLin, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       and.l     #65535,D3
       move.l    D3,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D4
; if (vNextAddr > 0)
       cmp.l     #0,D4
       bls       saveLine_3
; {
; pAtu = vNextAddr;
       move.l    D4,D2
; if (((*(pAtu + 3) << 8) | *(pAtu + 4)) == vNumLin)
       move.l    D2,A0
       move.b    3(A0),D0
       lsl.b     #8,D0
       move.l    D2,A0
       or.b      4(A0),D0
       and.w     #255,D0
       cmp.w     D3,D0
       bne.s     saveLine_5
; {
; printText("Line number already exists\r\n\0");
       pea       @basic_115.L
       jsr       _printText
       addq.w    #4,A7
; return;
       bra       saveLine_8
saveLine_5:
; }
; vAntAddr = findNumberLine(vNumLin, 1, 0);
       clr.l     -(A7)
       pea       1
       and.l     #65535,D3
       move.l    D3,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D7
saveLine_3:
; }
; }
; vTam = strlen(pTokenized);
       move.l    12(A6),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.w    D0,A3
; if (vTam)
       move.w    A3,D0
       beq       saveLine_8
; {
; // Calcula nova posicao da proxima linha
; if (vNextAddr == 0)
       tst.l     D4
       bne.s     saveLine_10
; {
; *nextAddrLine += (vTam + 6);
       move.l    (A2),A0
       move.l    A3,D0
       addq.l    #6,D0
       add.l     D0,(A0)
; vNextAddr = *nextAddrLine;
       move.l    (A2),A0
       move.l    (A0),D4
; *addrLastLineNumber = pSave;
       move.l    _addrLastLineNumber.L,A0
       move.l    D5,(A0)
       bra       saveLine_11
saveLine_10:
; }
; else
; {
; if (*firstLineNumber > vNumLin)
       move.l    (A5),A0
       cmp.w     (A0),D3
       bhs.s     saveLine_12
; {
; *firstLineNumber = vNumLin;
       move.l    (A5),A0
       move.w    D3,(A0)
; *addrFirstLineNumber = *nextAddrLine;
       move.l    (A2),A0
       move.l    _addrFirstLineNumber.L,A1
       move.l    (A0),(A1)
saveLine_12:
; }
; *nextAddrLine += (vTam + 6);
       move.l    (A2),A0
       move.l    A3,D0
       addq.l    #6,D0
       add.l     D0,(A0)
; vNextAddr2 = *nextAddrLine;
       move.l    (A2),A0
       move.l    (A0),A4
; if (vAntAddr != vNextAddr)
       cmp.l     D4,D7
       beq       saveLine_14
; {
; pLast = vAntAddr;
       move.l    D7,D6
; vAntAddr = pSave;
       move.l    D5,D7
; *pLast       = ((vAntAddr & 0xFF0000) >> 16);
       move.l    D7,D0
       and.l     #16711680,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.l    D6,A0
       move.b    D0,(A0)
; *(pLast + 1) = ((vAntAddr & 0xFF00) >> 8);
       move.l    D7,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.l    D6,A0
       move.b    D0,1(A0)
; *(pLast + 2) =  (vAntAddr & 0xFF);
       move.l    D7,D0
       and.l     #255,D0
       move.l    D6,A0
       move.b    D0,2(A0)
saveLine_14:
; }
; pLast = *addrLastLineNumber;
       move.l    _addrLastLineNumber.L,A0
       move.l    (A0),D6
; *pLast       = ((vNextAddr2 & 0xFF0000) >> 16);
       move.l    A4,D0
       and.l     #16711680,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.l    D6,A0
       move.b    D0,(A0)
; *(pLast + 1) = ((vNextAddr2 & 0xFF00) >> 8);
       move.l    A4,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.l    D6,A0
       move.b    D0,1(A0)
; *(pLast + 2) =  (vNextAddr2 & 0xFF);
       move.l    A4,D0
       and.l     #255,D0
       move.l    D6,A0
       move.b    D0,2(A0)
saveLine_11:
; }
; pAtu = *nextAddrLine;
       move.l    (A2),A0
       move.l    (A0),D2
; *pAtu       = 0x00;
       move.l    D2,A0
       clr.b     (A0)
; *(pAtu + 1) = 0x00;
       move.l    D2,A0
       clr.b     1(A0)
; *(pAtu + 2) = 0x00;
       move.l    D2,A0
       clr.b     2(A0)
; *(pAtu + 3) = 0x00;
       move.l    D2,A0
       clr.b     3(A0)
; *(pAtu + 4) = 0x00;
       move.l    D2,A0
       clr.b     4(A0)
; // Grava endereco proxima linha
; *pSave++ = ((vNextAddr & 0xFF0000) >> 16);
       move.l    D4,D0
       and.l     #16711680,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.l    D5,A0
       addq.l    #1,D5
       move.b    D0,(A0)
; *pSave++ = ((vNextAddr & 0xFF00) >> 8);
       move.l    D4,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.l    D5,A0
       addq.l    #1,D5
       move.b    D0,(A0)
; *pSave++ =  (vNextAddr & 0xFF);
       move.l    D4,D0
       and.l     #255,D0
       move.l    D5,A0
       addq.l    #1,D5
       move.b    D0,(A0)
; // Grava numero da linha
; *pSave++ = ((vNumLin & 0xFF00) >> 8);
       move.w    D3,D0
       and.w     #65280,D0
       lsr.w     #8,D0
       move.l    D5,A0
       addq.l    #1,D5
       move.b    D0,(A0)
; *pSave++ = (vNumLin & 0xFF);
       move.w    D3,D0
       and.w     #255,D0
       move.l    D5,A0
       addq.l    #1,D5
       move.b    D0,(A0)
; // Grava linha tokenizada
; for(kt = 0; kt < vTam; kt++)
       clr.w     -2(A6)
saveLine_16:
       move.w    A3,D0
       cmp.w     -2(A6),D0
       bls.s     saveLine_18
; *pSave++ = *pTokenized++;
       move.l    12(A6),A0
       addq.l    #1,12(A6)
       move.l    D5,A1
       addq.l    #1,D5
       move.b    (A0),(A1)
       addq.w    #1,-2(A6)
       bra       saveLine_16
saveLine_18:
; // Grava final linha 0x00
; *pSave = 0x00;
       move.l    D5,A0
       clr.b     (A0)
saveLine_8:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // Sintaxe:
; //      LIST                : lista tudo
; //      LIST <num>          : lista só a linha <num>
; //      LIST <num>-         : lista a partir da linha <num>
; //      LIST <numA>-<numB>  : lista o intervalo de <numA> até <numB>, inclusive
; //
; //      LISTP : mesmo que LIST, mas com pausa a cada scroll
; //-----------------------------------------------------------------------------
; void listProg(unsigned char *pArg, unsigned short pPause)
; {
       xdef      _listProg
_listProg:
       link      A6,#-300
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -270(A6),A2
       move.l    8(A6),D5
       lea       -14(A6),A3
; // Default listar tudo
; unsigned short pIni = 0, pFim = 0xFFFF;
       clr.w     -298(A6)
       move.w    #65535,A5
; unsigned char *vStartList = pStartProg;
       move.l    _pStartProg.L,D3
; unsigned long vNextList;
; unsigned short vNumLin;
; char sNumLin [sizeof(short)*8+1], vFirstByte;
; unsigned char vtec;
; unsigned char vLinhaList[255], sNumPar[10], vToken;
; int iw, ix, iy, iz, vPauseRowCounter;
; //    unsigned char sqtdtam[20];
; if (pArg[0] != 0x00 && strchr(pArg,'-') != 0x00)
       move.l    D5,A0
       move.b    (A0),D0
       beq       listProg_1
       pea       45
       move.l    D5,-(A7)
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       beq       listProg_1
; {
; ix = 0;
       clr.l     D2
; iy = 0;
       clr.l     D4
; // listar intervalo
; while (pArg[ix] != '-')
listProg_3:
       move.l    D5,A0
       move.b    0(A0,D2.L),D0
       cmp.b     #45,D0
       beq.s     listProg_5
; sNumPar[iy++] = pArg[ix++];
       move.l    D5,A0
       move.l    D2,D0
       addq.l    #1,D2
       move.l    D4,D1
       addq.l    #1,D4
       move.b    0(A0,D0.L),0(A3,D1.L)
       bra       listProg_3
listProg_5:
; sNumPar[iy] = 0x00;
       clr.b     0(A3,D4.L)
; pIni = atoi(sNumPar);
       move.l    A3,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,-298(A6)
; iy = 0;
       clr.l     D4
; ix++;
       addq.l    #1,D2
; while (pArg[ix])
listProg_6:
       move.l    D5,A0
       tst.b     0(A0,D2.L)
       beq.s     listProg_8
; sNumPar[iy++] = pArg[ix++];
       move.l    D5,A0
       move.l    D2,D0
       addq.l    #1,D2
       move.l    D4,D1
       addq.l    #1,D4
       move.b    0(A0,D0.L),0(A3,D1.L)
       bra       listProg_6
listProg_8:
; sNumPar[iy] = 0x00;
       clr.b     0(A3,D4.L)
; if (sNumPar[0])
       tst.b     (A3)
       beq.s     listProg_9
; pFim = atoi(sNumPar);
       move.l    A3,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,A5
       bra.s     listProg_10
listProg_9:
; else
; pFim = 0xFFFF;
       move.w    #65535,A5
listProg_10:
       bra.s     listProg_11
listProg_1:
; }
; else if (pArg[0] != 0x00)
       move.l    D5,A0
       move.b    (A0),D0
       beq.s     listProg_11
; {
; // listar 1 linha
; pIni = atoi(pArg);
       move.l    D5,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,-298(A6)
; pFim = pIni;
       move.w    -298(A6),A5
listProg_11:
; }
; vStartList = findNumberLine(pIni, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.w    -298(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D3
; // Nao achou numero de linha inicial
; if (!vStartList)
       tst.l     D3
       bne.s     listProg_13
; {
; printText("Non-existent line number\r\n\0");
       pea       @basic_116.L
       jsr       _printText
       addq.w    #4,A7
; return;
       bra       listProg_18
listProg_13:
; }
; vNextList = vStartList;
       move.l    D3,-296(A6)
; vPauseRowCounter = 0;
       move.w    #0,A4
; while (1)
listProg_16:
; {
; // Guarda proxima posicao
; vNextList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    D3,A0
       move.b    1(A0),D1
       and.l     #255,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D3,A0
       move.b    2(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,-296(A6)
; if (vNextList)
       tst.l     -296(A6)
       beq       listProg_19
; {
; // Pega numero da linha
; vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);
       move.l    D3,A0
       move.b    3(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    D3,A0
       move.b    4(A0),D1
       and.w     #255,D1
       or.w      D1,D0
       move.w    D0,-292(A6)
; if (vNumLin > pFim)
       move.w    A5,D0
       cmp.w     -292(A6),D0
       bhs.s     listProg_21
; break;
       bra       listProg_18
listProg_21:
; vStartList += 5;
       addq.l    #5,D3
; ix = 0;
       clr.l     D2
; // Coloca numero da linha na listagem
; itoa(vNumLin, sNumLin, 10);
       pea       10
       pea       -290(A6)
       move.w    -292(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; iz = 0;
       moveq     #0,D7
; while (sNumLin[iz])
listProg_23:
       lea       -290(A6),A0
       tst.b     0(A0,D7.L)
       beq.s     listProg_25
; {
; vLinhaList[ix++] = sNumLin[iz++];
       move.l    D7,D0
       addq.l    #1,D7
       lea       -290(A6),A0
       move.l    D2,D1
       addq.l    #1,D2
       move.b    0(A0,D0.L),0(A2,D1.L)
       bra       listProg_23
listProg_25:
; }
; vLinhaList[ix++] = 0x20;
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #32,0(A2,D0.L)
; vFirstByte = 1;
       move.b    #1,-272(A6)
; // Pega caracter a caracter da linha
; while (*vStartList)
listProg_26:
       move.l    D3,A0
       tst.b     (A0)
       beq       listProg_28
; {
; vToken = *vStartList++;
       move.l    D3,A0
       addq.l    #1,D3
       move.b    (A0),D6
; // Verifica se é token, se for, muda pra escrito
; if (vToken >= 0x80)
       and.w     #255,D6
       cmp.w     #128,D6
       blo       listProg_29
; {
; // Procura token na lista
; iy = findToken(vToken);
       and.l     #255,D6
       move.l    D6,-(A7)
       jsr       _findToken
       addq.w    #4,A7
       move.l    D0,D4
; iz = 0;
       moveq     #0,D7
; if (!vFirstByte)
       tst.b     -272(A6)
       bne       listProg_31
; {
; if (isalphas(*(vStartList - 2)) || isdigitus(*(vStartList - 2)) || *(vStartList - 2) == ')')
       move.l    D3,D1
       subq.l    #2,D1
       move.l    D1,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne       listProg_35
       move.l    D3,D1
       subq.l    #2,D1
       move.l    D1,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isdigitus
       addq.w    #4,A7
       tst.l     D0
       bne.s     listProg_35
       move.l    D3,D0
       subq.l    #2,D0
       move.l    D0,A0
       move.b    (A0),D0
       cmp.b     #41,D0
       bne.s     listProg_33
listProg_35:
; vLinhaList[ix++] = 0x20;
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #32,0(A2,D0.L)
listProg_33:
       bra.s     listProg_32
listProg_31:
; }
; else
; vFirstByte = 0;
       clr.b     -272(A6)
listProg_32:
; while (keywords[iy].keyword[iz])
listProg_36:
       move.l    D4,D0
       lsl.l     #3,D0
       lea       @basic_keywords.L,A0
       move.l    0(A0,D0.L),A0
       tst.b     0(A0,D7.L)
       beq.s     listProg_38
; {
; vLinhaList[ix++] = keywords[iy].keyword[iz++];
       move.l    D4,D0
       lsl.l     #3,D0
       lea       @basic_keywords.L,A0
       move.l    0(A0,D0.L),A0
       move.l    D7,D0
       addq.l    #1,D7
       move.l    D2,D1
       addq.l    #1,D2
       move.b    0(A0,D0.L),0(A2,D1.L)
       bra       listProg_36
listProg_38:
; }
; // Se nao for intervalo de funcao, coloca espaço depois do comando
; if (*vStartList != '=' && (vToken < 0xC0 || vToken > 0xEF))
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #61,D0
       beq.s     listProg_39
       and.w     #255,D6
       cmp.w     #192,D6
       blo.s     listProg_41
       and.w     #255,D6
       cmp.w     #239,D6
       bls.s     listProg_39
listProg_41:
; vLinhaList[ix++] = 0x20;
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #32,0(A2,D0.L)
listProg_39:
       bra.s     listProg_42
listProg_29:
; /*                    if (*vStartList != 0x28)
; vLinhaList[ix++] = 0x20;*/
; }
; else
; {
; // Apenas inclui na listagem
; //if (strchr("+-*^/=;:><", *vTempPointer) || *vTempPointer >= 0xF0)
; vLinhaList[ix++] = vToken;
       move.l    D2,D0
       addq.l    #1,D2
       move.b    D6,0(A2,D0.L)
; // Se nao for aspas e o proximo for um token, inclui um espaço
; if (vToken == 0x22 && *vStartList >=0x80)
       cmp.b     #34,D6
       bne.s     listProg_42
       move.l    D3,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #128,D0
       blo.s     listProg_42
; vLinhaList[ix++] = 0x20;
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #32,0(A2,D0.L)
listProg_42:
       bra       listProg_26
listProg_28:
; /*if (isdigitus(vToken) && *vStartList!=')' && *vStartList!='.' && *vStartList!='"' && !isdigitus(*vStartList))
; vLinhaList[ix++] = 0x20;*/
; }
; }
; vLinhaList[ix] = '\0';
       clr.b     0(A2,D2.L)
; iw = strlen(vLinhaList) / 40;
       move.l    A2,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,-(A7)
       pea       40
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-4(A6)
; vLinhaList[ix++] = '\r';
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #13,0(A2,D0.L)
; vLinhaList[ix++] = '\n';
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #10,0(A2,D0.L)
; vLinhaList[ix++] = '\0';
       move.l    D2,D0
       addq.l    #1,D2
       clr.b     0(A2,D0.L)
; printText(vLinhaList);
       move.l    A2,-(A7)
       jsr       _printText
       addq.w    #4,A7
; vPauseRowCounter = vPauseRowCounter + 1 + iw;
       move.l    A4,D0
       addq.l    #1,D0
       add.l     -4(A6),D0
       move.l    D0,A4
; /*writeLongSerial("Aqui 332.666.0-[");
; itoa(pPause,sqtdtam,10);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(vPauseRowCounter,sqtdtam,10);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(iw,sqtdtam,10);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*videoCursorPosRowY,sqtdtam,10);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*videoCursorPosRow,sqtdtam,10);
; writeLongSerial(sqtdtam);
; writeLongSerial("]\r\n");*/
; if (pPause && vPauseRowCounter >= *vdpMaxRows)
       move.w    14(A6),D0
       and.l     #65535,D0
       beq       listProg_46
       move.l    _vdpMaxRows.L,A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    A4,D1
       cmp.l     D0,D1
       blo       listProg_46
; {
; printText("press any key to continue\0");
       pea       @basic_117.L
       jsr       _printText
       addq.w    #4,A7
; vtec = inputLine(1,"@");
       pea       @basic_118.L
       pea       1
       jsr       _inputLine
       addq.w    #8,A7
       move.b    D0,-271(A6)
; vPauseRowCounter = 0;
       move.w    #0,A4
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       _printText
       addq.w    #4,A7
; if (vtec == 0x1B)   // ESC
       move.b    -271(A6),D0
       cmp.b     #27,D0
       bne.s     listProg_46
; break;
       bra.s     listProg_18
listProg_46:
; }
; vStartList = vNextList;
       move.l    -296(A6),D3
       bra.s     listProg_20
listProg_19:
; }
; else
; break;
       bra.s     listProg_18
listProg_20:
       bra       listProg_16
listProg_18:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // Sintaxe:
; //      DEL <num>          : apaga só a linha <num>
; //      DEL <num>-         : apaga a partir da linha <num> até o fim
; //      DEL <numA>-<numB>  : apaga o intervalo de <numA> até <numB>, inclusive
; //-----------------------------------------------------------------------------
; void delLine(unsigned char *pArg)
; {
       xdef      _delLine
_delLine:
       link      A6,#-300
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    8(A6),D4
       lea       -16(A6),A2
       lea       _pStartProg.L,A3
; unsigned short pIni = 0, pFim = 0xFFFF;
       move.w    #0,A5
       move.w    #65535,A4
; unsigned char *vStartList = pStartProg;
       move.l    (A3),D2
; unsigned long vDelAddr, vAntAddr, vNewAddr;
; unsigned short vNumLin;
; char sNumLin [sizeof(short)*8+1];
; unsigned char vLinhaList[255], sNumPar[10], vToken;
; int ix, iy, iz;
; if (pArg[0] != 0x00 && strchr(pArg,'-') != 0x00)
       move.l    D4,A0
       move.b    (A0),D0
       beq       delLine_1
       pea       45
       move.l    D4,-(A7)
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       beq       delLine_1
; {
; ix = 0;
       moveq     #0,D7
; iy = 0;
       clr.l     D6
; // listar intervalo
; while (pArg[ix] != '-')
delLine_3:
       move.l    D4,A0
       move.b    0(A0,D7.L),D0
       cmp.b     #45,D0
       beq.s     delLine_5
; sNumPar[iy++] = pArg[ix++];
       move.l    D4,A0
       move.l    D7,D0
       addq.l    #1,D7
       move.l    D6,D1
       addq.l    #1,D6
       move.b    0(A0,D0.L),0(A2,D1.L)
       bra       delLine_3
delLine_5:
; sNumPar[iy] = 0x00;
       clr.b     0(A2,D6.L)
; pIni = atoi(sNumPar);
       move.l    A2,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,A5
; iy = 0;
       clr.l     D6
; ix++;
       addq.l    #1,D7
; while (pArg[ix])
delLine_6:
       move.l    D4,A0
       tst.b     0(A0,D7.L)
       beq.s     delLine_8
; sNumPar[iy++] = pArg[ix++];
       move.l    D4,A0
       move.l    D7,D0
       addq.l    #1,D7
       move.l    D6,D1
       addq.l    #1,D6
       move.b    0(A0,D0.L),0(A2,D1.L)
       bra       delLine_6
delLine_8:
; sNumPar[iy] = 0x00;
       clr.b     0(A2,D6.L)
; if (sNumPar[0])
       tst.b     (A2)
       beq.s     delLine_9
; pFim = atoi(sNumPar);
       move.l    A2,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,A4
       bra.s     delLine_10
delLine_9:
; else
; pFim = 0xFFFF;
       move.w    #65535,A4
delLine_10:
       bra.s     delLine_12
delLine_1:
; }
; else if (pArg[0] != 0x00)
       move.l    D4,A0
       move.b    (A0),D0
       beq.s     delLine_11
; {
; pIni = atoi(pArg);
       move.l    D4,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.w    D0,A5
; pFim = pIni;
       move.w    A5,A4
       bra.s     delLine_12
delLine_11:
; }
; else
; {
; printText("Syntax Error !");
       pea       @basic_119.L
       jsr       _printText
       addq.w    #4,A7
; return;
       bra       delLine_18
delLine_12:
; }
; vDelAddr = findNumberLine(pIni, 0, 1);
       pea       1
       clr.l     -(A7)
       move.l    A5,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,-298(A6)
; if (!vDelAddr)
       tst.l     -298(A6)
       bne.s     delLine_14
; {
; printText("Non-existent line number\r\n\0");
       pea       @basic_116.L
       jsr       _printText
       addq.w    #4,A7
; return;
       bra       delLine_18
delLine_14:
; }
; while (1)
delLine_16:
; {
; vStartList = vDelAddr;
       move.l    -298(A6),D2
; // Guarda proxima posicao
; vNewAddr = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D2,A0
       move.b    2(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D3
; if (!vNewAddr)
       tst.l     D3
       bne.s     delLine_19
; break;
       bra       delLine_18
delLine_19:
; // Pega numero da linha
; vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);
       move.l    D2,A0
       move.b    3(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.w     #255,D1
       or.w      D1,D0
       move.w    D0,D5
; if (vNumLin > pFim)
       cmp.w     A4,D5
       bls.s     delLine_21
; break;
       bra       delLine_18
delLine_21:
; vAntAddr = findNumberLine(vNumLin, 1, 1);
       pea       1
       pea       1
       and.l     #65535,D5
       move.l    D5,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,-294(A6)
; // Apaga a linha atual
; *vStartList       = 0x00;
       move.l    D2,A0
       clr.b     (A0)
; *(vStartList + 1) = 0x00;
       move.l    D2,A0
       clr.b     1(A0)
; *(vStartList + 2) = 0x00;
       move.l    D2,A0
       clr.b     2(A0)
; *(vStartList + 3) = 0x00;
       move.l    D2,A0
       clr.b     3(A0)
; *(vStartList + 4) = 0x00;
       move.l    D2,A0
       clr.b     4(A0)
; vStartList += 5;
       addq.l    #5,D2
; while (*vStartList)
delLine_23:
       move.l    D2,A0
       tst.b     (A0)
       beq.s     delLine_25
; *vStartList++ = 0x00;
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
       bra       delLine_23
delLine_25:
; vStartList = vAntAddr;
       move.l    -294(A6),D2
; *vStartList++ = ((vNewAddr & 0xFF0000) >> 16);
       move.l    D3,D0
       and.l     #16711680,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
; *vStartList++ = ((vNewAddr & 0xFF00) >> 8);
       move.l    D3,D0
       and.l     #65280,D0
       lsr.l     #8,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
; *vStartList++ =  (vNewAddr & 0xFF);
       move.l    D3,D0
       and.l     #255,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
; // Se for a primeira linha, reposiciona na proxima
; if (*firstLineNumber == vNumLin)
       move.l    _firstLineNumber.L,A0
       cmp.w     (A0),D5
       bne       delLine_29
; {
; if (vNewAddr)
       tst.l     D3
       beq.s     delLine_28
; {
; vStartList = vNewAddr;
       move.l    D3,D2
; // Pega numero da linha
; vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);
       move.l    D2,A0
       move.b    3(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.w     #255,D1
       or.w      D1,D0
       move.w    D0,D5
; *firstLineNumber = vNumLin;
       move.l    _firstLineNumber.L,A0
       move.w    D5,(A0)
; *addrFirstLineNumber = vNewAddr;
       move.l    _addrFirstLineNumber.L,A0
       move.l    D3,(A0)
       bra.s     delLine_29
delLine_28:
; }
; else
; {
; *pStartProg = 0x00;
       move.l    (A3),A0
       clr.b     (A0)
; *(pStartProg + 1) = 0x00;
       move.l    (A3),A0
       clr.b     1(A0)
; *(pStartProg + 2) = 0x00;
       move.l    (A3),A0
       clr.b     2(A0)
; *nextAddrLine = pStartProg;
       move.l    _nextAddrLine.L,A0
       move.l    (A3),(A0)
; *firstLineNumber = 0;
       move.l    _firstLineNumber.L,A0
       clr.w     (A0)
; *addrFirstLineNumber = 0;
       move.l    _addrFirstLineNumber.L,A0
       clr.l     (A0)
delLine_29:
; }
; }
; if (!vNewAddr)
       tst.l     D3
       bne.s     delLine_30
; break;
       bra.s     delLine_18
delLine_30:
; vDelAddr = vNewAddr;
       move.l    D3,-298(A6)
       bra       delLine_16
delLine_18:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // Sintaxe:
; //      EDIT <num>          : Edita conteudo da linha <num>
; //-----------------------------------------------------------------------------
; void editLine(unsigned char *pNumber)
; {
       xdef      _editLine
_editLine:
       link      A6,#-304
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vbuf.L,A2
       lea       -266(A6),A3
       lea       _printText.L,A4
; int pIni = 0, ix, iy, iz, iw, ivv, vNumLin, pFim;
       clr.l     -304(A6)
; unsigned char *vStartList = pStartProg, *vNextList;
       move.l    _pStartProg.L,D2
; unsigned char vRetInput;
; char sNumLin [sizeof(short)*8+1], vFirstByte;
; unsigned char vLinhaList[255], sNumPar[10], vToken;
; if (pNumber[0] != 0x00)
       move.l    8(A6),A0
       move.b    (A0),D0
       beq.s     editLine_1
; {
; // rodar desde uma linha especifica
; pIni = atoi(pNumber);
       move.l    8(A6),-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,-304(A6)
       bra.s     editLine_2
editLine_1:
; }
; else
; {
; printText("Syntax Error !");
       pea       @basic_119.L
       jsr       (A4)
       addq.w    #4,A7
; return;
       bra       editLine_38
editLine_2:
; }
; vStartList = findNumberLine(pIni, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    -304(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D2
; // Nao achou numero de linha inicial
; if (!vStartList)
       tst.l     D2
       bne.s     editLine_4
; {
; printText("Non-existent line number\r\n\0");
       pea       @basic_116.L
       jsr       (A4)
       addq.w    #4,A7
; return;
       bra       editLine_38
editLine_4:
; }
; // Carrega a linha no buffer
; // Guarda proxima posicao
; vNextList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D2,A0
       move.b    2(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,-288(A6)
; ix = 0;
       clr.l     D5
; ivv = 0;
       clr.l     D4
; if (vNextList)
       tst.l     -288(A6)
       beq       editLine_13
; {
; // Pega numero da linha
; vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,-296(A6)
; vStartList += 5;
       addq.l    #5,D2
; // Coloca numero da linha na listagem
; itoa(vNumLin, sNumLin, 10);
       pea       10
       pea       -284(A6)
       move.l    -296(A6),-(A7)
       jsr       _itoa
       add.w     #12,A7
; iz = 0;
       clr.l     D3
; while (sNumLin[iz++])
editLine_8:
       move.l    D3,D0
       addq.l    #1,D3
       lea       -284(A6),A0
       tst.b     0(A0,D0.L)
       beq.s     editLine_10
; {
; vLinhaList[ivv] = sNumLin[ivv];
       lea       -284(A6),A0
       move.b    0(A0,D4.L),0(A3,D4.L)
; ivv++;
       addq.l    #1,D4
       bra       editLine_8
editLine_10:
; }
; vLinhaList[ivv] = '\r';
       move.b    #13,0(A3,D4.L)
; vLinhaList[ivv + 1] = '\n';
       move.l    D4,A0
       move.b    #10,1(A0,A3.L)
; vLinhaList[ivv + 2] = '\0';
       move.l    D4,A0
       clr.b     2(A0,A3.L)
; printText(vLinhaList);
       move.l    A3,-(A7)
       jsr       (A4)
       addq.w    #4,A7
; vFirstByte = 1;
       move.b    #1,-267(A6)
; vbuf[ix] = 0x00;
       move.l    (A2),A0
       clr.b     0(A0,D5.L)
; ix = 0;
       clr.l     D5
; // Pega caracter a caracter da linha
; while (*vStartList)
editLine_11:
       move.l    D2,A0
       tst.b     (A0)
       beq       editLine_13
; {
; vToken = *vStartList++;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A0),D6
; // Verifica se é token, se for, muda pra escrito
; if (vToken >= 0x80)
       and.w     #255,D6
       cmp.w     #128,D6
       blo       editLine_14
; {
; // Procura token na lista
; iy = findToken(vToken);
       and.l     #255,D6
       move.l    D6,-(A7)
       jsr       _findToken
       addq.w    #4,A7
       move.l    D0,A5
; iz = 0;
       clr.l     D3
; if (!vFirstByte)
       tst.b     -267(A6)
       bne       editLine_16
; {
; if (isalphas(*(vStartList - 2)) || isdigitus(*(vStartList - 2)) || *(vStartList - 2) == ')')
       move.l    D2,D1
       subq.l    #2,D1
       move.l    D1,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne       editLine_20
       move.l    D2,D1
       subq.l    #2,D1
       move.l    D1,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isdigitus
       addq.w    #4,A7
       tst.l     D0
       bne.s     editLine_20
       move.l    D2,D0
       subq.l    #2,D0
       move.l    D0,A0
       move.b    (A0),D0
       cmp.b     #41,D0
       bne.s     editLine_18
editLine_20:
; vbuf[ix++] = 0x20;
       move.l    (A2),A0
       move.l    D5,D0
       addq.l    #1,D5
       move.b    #32,0(A0,D0.L)
editLine_18:
       bra.s     editLine_17
editLine_16:
; }
; else
; vFirstByte = 0;
       clr.b     -267(A6)
editLine_17:
; while (keywords[iy].keyword[iz])
editLine_21:
       move.l    A5,D0
       lsl.l     #3,D0
       lea       @basic_keywords.L,A0
       move.l    0(A0,D0.L),A0
       tst.b     0(A0,D3.L)
       beq.s     editLine_23
; {
; vbuf[ix++] = keywords[iy].keyword[iz++];
       move.l    A5,D0
       lsl.l     #3,D0
       lea       @basic_keywords.L,A0
       move.l    0(A0,D0.L),A0
       move.l    D3,D0
       addq.l    #1,D3
       move.l    (A2),A1
       move.l    D5,D1
       addq.l    #1,D5
       move.b    0(A0,D0.L),0(A1,D1.L)
       bra       editLine_21
editLine_23:
; }
; // Se nao for intervalo de funcao, coloca espaço depois do comando
; if (*vStartList != '=' && (vToken < 0xC0 || vToken > 0xEF))
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #61,D0
       beq.s     editLine_24
       and.w     #255,D6
       cmp.w     #192,D6
       blo.s     editLine_26
       and.w     #255,D6
       cmp.w     #239,D6
       bls.s     editLine_24
editLine_26:
; vbuf[ix++] = 0x20;
       move.l    (A2),A0
       move.l    D5,D0
       addq.l    #1,D5
       move.b    #32,0(A0,D0.L)
editLine_24:
       bra.s     editLine_27
editLine_14:
; }
; else
; {
; vbuf[ix++] = vToken;
       move.l    (A2),A0
       move.l    D5,D0
       addq.l    #1,D5
       move.b    D6,0(A0,D0.L)
; // Se nao for aspas e o proximo for um token, inclui um espaço
; if (vToken == 0x22 && *vStartList >=0x80)
       cmp.b     #34,D6
       bne.s     editLine_27
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #128,D0
       blo.s     editLine_27
; vbuf[ix++] = 0x20;            }
       move.l    (A2),A0
       move.l    D5,D0
       addq.l    #1,D5
       move.b    #32,0(A0,D0.L)
editLine_27:
       bra       editLine_11
editLine_13:
; }
; }
; vbuf[ix] = '\0';
       move.l    (A2),A0
       clr.b     0(A0,D5.L)
; // Edita a linha no buffer, usando o inputLine do monitor.c
; vRetInput = inputLine(128,'S'); // S - String Linha Editavel
       pea       83
       pea       128
       jsr       _inputLine
       addq.w    #8,A7
       move.b    D0,D7
; if (*vbuf != 0x00 && (vRetInput == 0x0D || vRetInput == 0x0A))
       move.l    (A2),A0
       move.b    (A0),D0
       beq       editLine_29
       cmp.b     #13,D7
       beq.s     editLine_31
       cmp.b     #10,D7
       bne       editLine_29
editLine_31:
; {
; vLinhaList[ivv++] = 0x20;
       move.l    D4,D0
       addq.l    #1,D4
       move.b    #32,0(A3,D0.L)
; ix = strlen(vbuf);
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D5
; for(iz = 0; iz <= ix; iz++)
       clr.l     D3
editLine_32:
       cmp.l     D5,D3
       bgt.s     editLine_34
; vLinhaList[ivv++] = vbuf[iz];
       move.l    (A2),A0
       move.l    D4,D0
       addq.l    #1,D4
       move.b    0(A0,D3.L),0(A3,D0.L)
       addq.l    #1,D3
       bra       editLine_32
editLine_34:
; vLinhaList[ivv] = 0x00;
       clr.b     0(A3,D4.L)
; for(iz = 0; iz <= ivv; iz++)
       clr.l     D3
editLine_35:
       cmp.l     D4,D3
       bgt.s     editLine_37
; vbuf[iz] = vLinhaList[iz];
       move.l    (A2),A0
       move.b    0(A3,D3.L),0(A0,D3.L)
       addq.l    #1,D3
       bra       editLine_35
editLine_37:
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       (A4)
       addq.w    #4,A7
; // Apaga a linha atual
; delLine(pNumber);
       move.l    8(A6),-(A7)
       jsr       _delLine
       addq.w    #4,A7
; // Reinsere a linha editada
; processLine();
       jsr       _processLine
; printText("\r\nOK\0");
       pea       @basic_99.L
       jsr       (A4)
       addq.w    #4,A7
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; *vbuf = '\0';
       move.l    (A2),A0
       clr.b     (A0)
; printText("\r\n\0");
       pea       @basic_96.L
       jsr       (A4)
       addq.w    #4,A7
       bra.s     editLine_38
editLine_29:
; }
; else if (vRetInput != 0x1B)
       cmp.b     #27,D7
       beq.s     editLine_38
; {
; printText("\r\nAborted !!!\r\n\0");
       pea       @basic_120.L
       jsr       (A4)
       addq.w    #4,A7
editLine_38:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // Sintaxe:
; //      RUN                : Executa o programa a partir da primeira linha do prog
; //      RUN <num>          : Executa a partir da linha <num>
; //-----------------------------------------------------------------------------
; void runProg(unsigned char *pNumber)
; {
       xdef      _runProg
_runProg:
       link      A6,#-608
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _changedPointer.L,A2
       lea       _printText.L,A3
       lea       _vErroProc.L,A4
       lea       _pointerRunProg.L,A5
; // Default rodar desde a primeira linha
; int pIni = 0, ix;
       moveq     #0,D7
; unsigned char *vStartList = pStartProg;
       move.l    _pStartProg.L,D2
; unsigned long vNextList;
; unsigned short vNumLin;
; unsigned int vInt;
; unsigned char vString[255], vTipoRet;
; unsigned long vReal;
; typeInf vRetInf;
; unsigned int vReta;
; char sNumLin [sizeof(short)*8+1];
; char vbuffer [sizeof(long)*8+1];
; unsigned char *vPointerChangedPointer;
; unsigned char *pForStack = forStack;
       move.l    _forStack.L,-24(A6)
; unsigned char sqtdtam[20];
; unsigned char *vTempPointer;
; *nextAddrSimpVar = pStartSimpVar;
       move.l    _nextAddrSimpVar.L,A0
       move.l    _pStartSimpVar.L,(A0)
; *nextAddrArrayVar = pStartArrayVar;
       move.l    _nextAddrArrayVar.L,A0
       move.l    _pStartArrayVar.L,(A0)
; *nextAddrString = pStartString;
       move.l    _nextAddrString.L,A0
       move.l    _pStartString.L,(A0)
; for (ix = 0; ix < 0x2000; ix++)
       clr.l     D3
runProg_1:
       cmp.l     #8192,D3
       bge.s     runProg_3
; *(pStartSimpVar + ix) = 0x00;
       move.l    _pStartSimpVar.L,A0
       clr.b     0(A0,D3.L)
       addq.l    #1,D3
       bra       runProg_1
runProg_3:
; for (ix = 0; ix < 0x6000; ix++)
       clr.l     D3
runProg_4:
       cmp.l     #24576,D3
       bge.s     runProg_6
; *(pStartArrayVar + ix) = 0x00;
       move.l    _pStartArrayVar.L,A0
       clr.b     0(A0,D3.L)
       addq.l    #1,D3
       bra       runProg_4
runProg_6:
; for (ix = 0; ix < 0x800; ix++)
       clr.l     D3
runProg_7:
       cmp.l     #2048,D3
       bge.s     runProg_9
; *(pForStack + ix) = 0x00;
       move.l    -24(A6),A0
       clr.b     0(A0,D3.L)
       addq.l    #1,D3
       bra       runProg_7
runProg_9:
; if (pNumber[0] != 0x00)
       move.l    8(A6),A0
       move.b    (A0),D0
       beq.s     runProg_10
; {
; // rodar desde uma linha especifica
; pIni = atoi(pNumber);
       move.l    8(A6),-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,D7
runProg_10:
; }
; vStartList = findNumberLine(pIni, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       and.l     #65535,D7
       move.l    D7,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D2
; // Nao achou numero de linha inicial
; if (!vStartList)
       tst.l     D2
       bne.s     runProg_12
; {
; printText("Non-existent line number\r\n\0");
       pea       @basic_116.L
       jsr       (A3)
       addq.w    #4,A7
; return;
       bra       runProg_52
runProg_12:
; }
; vNextList = vStartList;
       move.l    D2,D5
; *ftos=0;
       move.l    _ftos.L,A0
       clr.l     (A0)
; *gtos=0;
       move.l    _gtos.L,A0
       clr.l     (A0)
; *changedPointer = 0;
       move.l    (A2),A0
       clr.l     (A0)
; *vDataPointer = 0;
       move.l    _vDataPointer.L,A0
       clr.l     (A0)
; *randSeed = *(vmfp + Reg_TADR);
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.l     #255,D0
       move.l    _randSeed.L,A0
       move.l    D0,(A0)
; *onErrGoto = 0;
       move.l    _onErrGoto.L,A0
       clr.l     (A0)
; while (1)
runProg_15:
; {
; if (*changedPointer!=0)
       move.l    (A2),A0
       move.l    (A0),D0
       beq.s     runProg_18
; vStartList = *changedPointer;
       move.l    (A2),A0
       move.l    (A0),D2
runProg_18:
; // Guarda proxima posicao
; vNextList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D2,A0
       move.b    2(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D5
; *nextAddr = vNextList;
       move.l    _nextAddr.L,A0
       move.l    D5,(A0)
; if (vNextList)
       tst.l     D5
       beq       runProg_20
; {
; // Pega numero da linha
; vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);
       move.l    D2,A0
       move.b    3(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.w     #255,D1
       or.w      D1,D0
       move.w    D0,D6
; vStartList += 5;
       addq.l    #5,D2
; // Pega caracter a caracter da linha
; *changedPointer = 0;
       move.l    (A2),A0
       clr.l     (A0)
; *vMaisTokens = 0;
       move.l    _vMaisTokens.L,A0
       clr.b     (A0)
; *vParenteses = 0x00;
       move.l    _vParenteses.L,A0
       clr.b     (A0)
; *vTemIf = 0x00;
       move.l    _vTemIf.L,A0
       clr.b     (A0)
; *vTemThen = 0;
       move.l    _vTemThen.L,A0
       clr.b     (A0)
; *vTemElse = 0;
       move.l    _vTemElse.L,A0
       clr.b     (A0)
; *vTemIfAndOr = 0x00;
       move.l    _vTemIfAndOr.L,A0
       clr.b     (A0)
; vRetInf.tString[0] = 0x00;
       lea       -342(A6),A0
       clr.b     (A0)
; *pointerRunProg = vStartList;
       move.l    (A5),A0
       move.l    D2,(A0)
; *vErroProc = 0;
       move.l    (A4),A0
       clr.w     (A0)
; do
; {
runProg_22:
; readChar();
       jsr       _readChar
; if (*vBufReceived==27)
       move.l    _vBufReceived.L,A0
       move.b    (A0),D0
       cmp.b     #27,D0
       bne       runProg_24
; {
; // volta para modo texto
; #ifndef __TESTE_TOKENIZE__
; if (*vdp_mode != VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     runProg_26
; basText();
       jsr       _basText
runProg_26:
; #endif
; // mostra mensagem de para subita
; printText("\r\nStopped at ");
       pea       @basic_121.L
       jsr       (A3)
       addq.w    #4,A7
; itoa(vNumLin, sNumLin, 10);
       pea       10
       pea       -80(A6)
       and.l     #65535,D6
       move.l    D6,-(A7)
       jsr       _itoa
       add.w     #12,A7
; printText(sNumLin);
       pea       -80(A6)
       jsr       (A3)
       addq.w    #4,A7
; printText("\r\n");
       pea       @basic_96.L
       jsr       (A3)
       addq.w    #4,A7
; // sai do laço
; *nextAddr = 0;
       move.l    _nextAddr.L,A0
       clr.l     (A0)
; break;
       bra       runProg_23
runProg_24:
; }
; *doisPontos = 0;
       move.l    _doisPontos.L,A0
       clr.b     (A0)
; *vParenteses = 0x00;
       move.l    _vParenteses.L,A0
       clr.b     (A0)
; *vInicioSentenca = 1;
       move.l    _vInicioSentenca.L,A0
       move.b    #1,(A0)
; if (*traceOn)
       move.l    _traceOn.L,A0
       tst.b     (A0)
       beq.s     runProg_28
; {
; printText("\r\nExecuting at ");
       pea       @basic_122.L
       jsr       (A3)
       addq.w    #4,A7
; itoa(vNumLin, sNumLin, 10);
       pea       10
       pea       -80(A6)
       and.l     #65535,D6
       move.l    D6,-(A7)
       jsr       _itoa
       add.w     #12,A7
; printText(sNumLin);
       pea       -80(A6)
       jsr       (A3)
       addq.w    #4,A7
; printText("\r\n");
       pea       @basic_96.L
       jsr       (A3)
       addq.w    #4,A7
runProg_28:
; }
; vTempPointer = *pointerRunProg;
       move.l    (A5),A0
       move.l    (A0),D4
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A5),A0
       addq.l    #1,(A0)
; vReta = executeToken(*vTempPointer);
       move.l    D4,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _executeToken
       addq.w    #4,A7
       move.l    D0,-84(A6)
; if (*vErroProc)
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     runProg_30
; {
; if (*onErrGoto == 0)
       move.l    _onErrGoto.L,A0
       move.l    (A0),D0
       bne.s     runProg_32
; break;
       bra       runProg_23
runProg_32:
; *vErroProc = 0;
       move.l    (A4),A0
       clr.w     (A0)
; *changedPointer = *onErrGoto;
       move.l    _onErrGoto.L,A0
       move.l    (A2),A1
       move.l    (A0),(A1)
runProg_30:
; }
; if (*changedPointer!=0)
       move.l    (A2),A0
       move.l    (A0),D0
       beq.s     runProg_36
; {
; vPointerChangedPointer = *changedPointer;
       move.l    (A2),A0
       move.l    (A0),-28(A6)
; if (*vPointerChangedPointer == 0x3A)
       move.l    -28(A6),A0
       move.b    (A0),D0
       cmp.b     #58,D0
       bne.s     runProg_36
; {
; *pointerRunProg = *changedPointer;
       move.l    (A2),A0
       move.l    (A5),A1
       move.l    (A0),(A1)
; *changedPointer = 0;
       move.l    (A2),A0
       clr.l     (A0)
runProg_36:
; }
; }
; vTempPointer = *pointerRunProg;
       move.l    (A5),A0
       move.l    (A0),D4
; if (*vTempPointer != 0x00)
       move.l    D4,A0
       move.b    (A0),D0
       beq       runProg_44
; {
; if (*vTempPointer == 0x3A)
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #58,D0
       bne.s     runProg_40
; {
; *doisPontos = 1;
       move.l    _doisPontos.L,A0
       move.b    #1,(A0)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A5),A0
       addq.l    #1,(A0)
       bra.s     runProg_44
runProg_40:
; }
; else
; {
; if (*doisPontos && *vTempPointer <= 0x80)
       move.l    _doisPontos.L,A0
       move.b    (A0),D0
       and.l     #255,D0
       beq.s     runProg_42
       move.l    D4,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #128,D0
       bhi.s     runProg_42
; {
; // nao faz nada
; }
       bra.s     runProg_44
runProg_42:
; else
; {
; nextToken();
       jsr       _nextToken
; if (*vErroProc) break;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     runProg_44
       bra.s     runProg_23
runProg_44:
       move.l    _doisPontos.L,A0
       tst.b     (A0)
       bne       runProg_22
runProg_23:
; }
; }
; }
; } while (*doisPontos);
; if (*vErroProc)
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     runProg_46
; {
; #ifndef __TESTE_TOKENIZE__
; if (*vdp_mode != VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     runProg_48
; basText();
       jsr       _basText
runProg_48:
; #endif
; showErrorMessage(*vErroProc, vNumLin);
       and.l     #65535,D6
       move.l    D6,-(A7)
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _showErrorMessage
       addq.w    #8,A7
; break;
       bra.s     runProg_17
runProg_46:
; }
; if (*nextAddr == 0)
       move.l    _nextAddr.L,A0
       move.l    (A0),D0
       bne.s     runProg_50
; break;
       bra.s     runProg_17
runProg_50:
; vNextList = *nextAddr;
       move.l    _nextAddr.L,A0
       move.l    (A0),D5
; vStartList = vNextList;
       move.l    D5,D2
       bra.s     runProg_21
runProg_20:
; }
; else
; break;
       bra.s     runProg_17
runProg_21:
       bra       runProg_15
runProg_17:
; }
; #ifndef __TESTE_TOKENIZE__
; if (*vdp_mode != VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     runProg_52
; basText();
       jsr       _basText
runProg_52:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; #endif
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; void showErrorMessage(unsigned int pError, unsigned int pNumLine)
; {
       xdef      _showErrorMessage
_showErrorMessage:
       link      A6,#-20
       move.l    A2,-(A7)
       lea       _printText.L,A2
; char sNumLin [sizeof(short)*8+1];
; printText("\r\n");
       pea       @basic_96.L
       jsr       (A2)
       addq.w    #4,A7
; printText(listError[pError]);
       move.l    8(A6),D1
       lsl.l     #2,D1
       lea       @basic_listError.L,A0
       move.l    0(A0,D1.L),-(A7)
       jsr       (A2)
       addq.w    #4,A7
; if (pNumLine > 0)
       move.l    12(A6),D0
       cmp.l     #0,D0
       bls.s     showErrorMessage_1
; {
; itoa(pNumLine, sNumLin, 10);
       pea       10
       pea       -18(A6)
       move.l    12(A6),-(A7)
       jsr       _itoa
       add.w     #12,A7
; printText(" at ");
       pea       @basic_123.L
       jsr       (A2)
       addq.w    #4,A7
; printText(sNumLin);
       pea       -18(A6)
       jsr       (A2)
       addq.w    #4,A7
showErrorMessage_1:
; }
; printText(" !\r\n\0");
       pea       @basic_124.L
       jsr       (A2)
       addq.w    #4,A7
; *vErroProc = 0;
       move.l    _vErroProc.L,A0
       clr.w     (A0)
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; int executeToken(unsigned char pToken)
; {
       xdef      _executeToken
_executeToken:
       link      A6,#-24
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _basTrig.L,A2
       lea       _basLeftRightMid.L,A3
; char vReta = 0;
       clr.b     D2
; #ifndef __TESTE_TOKENIZE__
; unsigned char *pForStack = forStack;
       move.l    _forStack.L,-24(A6)
; int ix;
; unsigned char sqtdtam[20];
; switch (pToken)
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #178,D0
       beq       executeToken_34
       bhi       executeToken_67
       cmp.l     #143,D0
       beq       executeToken_18
       bhi       executeToken_68
       cmp.l     #135,D0
       beq       executeToken_10
       bhi       executeToken_69
       cmp.l     #130,D0
       beq       executeToken_6
       bhi.s     executeToken_70
       cmp.l     #128,D0
       beq       executeToken_4
       bhi.s     executeToken_71
       tst.l     D0
       beq       executeToken_3
       bra       executeToken_1
executeToken_71:
       cmp.l     #129,D0
       beq       executeToken_5
       bra       executeToken_1
executeToken_70:
       cmp.l     #133,D0
       beq       executeToken_8
       bhi.s     executeToken_72
       cmp.l     #131,D0
       beq       executeToken_7
       bra       executeToken_1
executeToken_72:
       cmp.l     #134,D0
       beq       executeToken_9
       bra       executeToken_1
executeToken_69:
       cmp.l     #139,D0
       beq       executeToken_14
       bhi.s     executeToken_73
       cmp.l     #137,D0
       beq       executeToken_12
       bhi.s     executeToken_74
       cmp.l     #136,D0
       beq       executeToken_11
       bra       executeToken_1
executeToken_74:
       cmp.l     #138,D0
       beq       executeToken_13
       bra       executeToken_1
executeToken_73:
       cmp.l     #141,D0
       beq       executeToken_16
       bhi.s     executeToken_75
       cmp.l     #140,D0
       beq       executeToken_15
       bra       executeToken_1
executeToken_75:
       cmp.l     #142,D0
       beq       executeToken_17
       bra       executeToken_1
executeToken_68:
       cmp.l     #151,D0
       beq       executeToken_26
       bhi       executeToken_76
       cmp.l     #147,D0
       beq       executeToken_22
       bhi.s     executeToken_77
       cmp.l     #145,D0
       beq       executeToken_20
       bhi.s     executeToken_78
       cmp.l     #144,D0
       beq       executeToken_19
       bra       executeToken_1
executeToken_78:
       cmp.l     #146,D0
       beq       executeToken_21
       bra       executeToken_1
executeToken_77:
       cmp.l     #149,D0
       beq       executeToken_24
       bhi.s     executeToken_79
       cmp.l     #148,D0
       beq       executeToken_23
       bra       executeToken_1
executeToken_79:
       cmp.l     #150,D0
       beq       executeToken_25
       bra       executeToken_1
executeToken_76:
       cmp.l     #158,D0
       beq       executeToken_30
       bhi.s     executeToken_80
       cmp.l     #153,D0
       beq       executeToken_28
       bhi.s     executeToken_81
       cmp.l     #152,D0
       beq       executeToken_27
       bra       executeToken_1
executeToken_81:
       cmp.l     #154,D0
       beq       executeToken_29
       bra       executeToken_1
executeToken_80:
       cmp.l     #176,D0
       beq       executeToken_32
       bhi.s     executeToken_82
       cmp.l     #159,D0
       beq       executeToken_31
       bra       executeToken_1
executeToken_82:
       cmp.l     #177,D0
       beq       executeToken_33
       bra       executeToken_1
executeToken_67:
       cmp.l     #224,D0
       beq       executeToken_50
       bhi       executeToken_83
       cmp.l     #187,D0
       beq       executeToken_42
       bhi       executeToken_84
       cmp.l     #182,D0
       beq       executeToken_38
       bhi.s     executeToken_85
       cmp.l     #180,D0
       beq       executeToken_36
       bhi.s     executeToken_86
       cmp.l     #179,D0
       beq       executeToken_35
       bra       executeToken_1
executeToken_86:
       cmp.l     #181,D0
       beq       executeToken_37
       bra       executeToken_1
executeToken_85:
       cmp.l     #185,D0
       beq       executeToken_40
       bhi.s     executeToken_87
       cmp.l     #184,D0
       beq       executeToken_39
       bra       executeToken_1
executeToken_87:
       cmp.l     #186,D0
       beq       executeToken_41
       bra       executeToken_1
executeToken_84:
       cmp.l     #209,D0
       beq       executeToken_46
       bhi.s     executeToken_88
       cmp.l     #205,D0
       beq       executeToken_44
       bhi.s     executeToken_89
       cmp.l     #196,D0
       beq       executeToken_43
       bra       executeToken_1
executeToken_89:
       cmp.l     #206,D0
       beq       executeToken_45
       bra       executeToken_1
executeToken_88:
       cmp.l     #220,D0
       beq       executeToken_48
       bhi.s     executeToken_90
       cmp.l     #219,D0
       beq       executeToken_47
       bra       executeToken_1
executeToken_90:
       cmp.l     #221,D0
       beq       executeToken_49
       bra       executeToken_1
executeToken_83:
       cmp.l     #232,D0
       beq       executeToken_58
       bhi       executeToken_91
       cmp.l     #228,D0
       beq       executeToken_54
       bhi.s     executeToken_92
       cmp.l     #226,D0
       beq       executeToken_52
       bhi.s     executeToken_93
       cmp.l     #225,D0
       beq       executeToken_51
       bra       executeToken_1
executeToken_93:
       cmp.l     #227,D0
       beq       executeToken_53
       bra       executeToken_1
executeToken_92:
       cmp.l     #230,D0
       beq       executeToken_56
       bhi.s     executeToken_94
       cmp.l     #229,D0
       beq       executeToken_55
       bra       executeToken_1
executeToken_94:
       cmp.l     #231,D0
       beq       executeToken_57
       bra       executeToken_1
executeToken_91:
       cmp.l     #236,D0
       beq       executeToken_62
       bhi.s     executeToken_95
       cmp.l     #234,D0
       beq       executeToken_60
       bhi.s     executeToken_96
       cmp.l     #233,D0
       beq       executeToken_59
       bra       executeToken_1
executeToken_96:
       cmp.l     #235,D0
       beq       executeToken_61
       bra       executeToken_1
executeToken_95:
       cmp.l     #238,D0
       beq       executeToken_64
       bhi.s     executeToken_97
       cmp.l     #237,D0
       beq       executeToken_63
       bra       executeToken_1
executeToken_97:
       cmp.l     #239,D0
       beq       executeToken_65
       bra       executeToken_1
executeToken_3:
; {
; case 0x00:  // End of Line
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_4:
; case 0x80:  // Let
; vReta = basLet();
       jsr       _basLet
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_5:
; case 0x81:  // Print
; vReta = basPrint();
       jsr       _basPrint
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_6:
; case 0x82:  // IF
; vReta = basIf();
       jsr       _basIf
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_7:
; case 0x83:  // THEN - nao faz nada
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_8:
; case 0x85:  // FOR
; vReta = basFor();
       jsr       _basFor
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_9:
; case 0x86:  // TO - nao faz nada
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_10:
; case 0x87:  // NEXT
; vReta = basNext();
       jsr       _basNext
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_11:
; case 0x88:  // STEP - nao faz nada
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_12:
; case 0x89:  // GOTO
; vReta = basGoto();
       jsr       _basGoto
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_13:
; case 0x8A:  // GOSUB
; vReta = basGosub();
       jsr       _basGosub
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_14:
; case 0x8B:  // RETURN
; vReta = basReturn();
       jsr       _basReturn
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_15:
; case 0x8C:  // REM - Ignora todas a linha depois dele
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_16:
; case 0x8D:  // INVERSE
; vReta = basInverse();
       jsr       _basInverse
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_17:
; case 0x8E:  // NORMAL
; vReta = basNormal();
       jsr       _basNormal
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_18:
; case 0x8F:  // DIM
; vReta = basDim();
       jsr       _basDim
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_19:
; case 0x90:  // Nao fax nada, soh teste, pode ser retirado
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_20:
; case 0x91:  // DIM
; vReta = basOnVar();
       jsr       _basOnVar
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_21:
; case 0x92:  // Input
; vReta = basInputGet(250);
       pea       250
       jsr       _basInputGet
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_22:
; case 0x93:  // Get
; vReta = basInputGet(1);
       pea       1
       jsr       _basInputGet
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_23:
; case 0x94:  // vTAB
; vReta = basVtab();
       jsr       _basVtab
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_24:
; case 0x95:  // HTAB
; vReta = basHtab();
       jsr       _basHtab
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_25:
; case 0x96:  // Home
; clearScr();
       jsr       _clearScr
; break;
       bra       executeToken_108
executeToken_26:
; case 0x97:  // CLEAR - Clear all variables
; for (ix = 0; ix < 0x2000; ix++)
       clr.l     D3
executeToken_98:
       cmp.l     #8192,D3
       bge.s     executeToken_100
; *(pStartSimpVar + ix) = 0x00;
       move.l    _pStartSimpVar.L,A0
       clr.b     0(A0,D3.L)
       addq.l    #1,D3
       bra       executeToken_98
executeToken_100:
; for (ix = 0; ix < 0x6000; ix++)
       clr.l     D3
executeToken_101:
       cmp.l     #24576,D3
       bge.s     executeToken_103
; *(pStartArrayVar + ix) = 0x00;
       move.l    _pStartArrayVar.L,A0
       clr.b     0(A0,D3.L)
       addq.l    #1,D3
       bra       executeToken_101
executeToken_103:
; for (ix = 0; ix < 0x800; ix++)
       clr.l     D3
executeToken_104:
       cmp.l     #2048,D3
       bge.s     executeToken_106
; *(pForStack + ix) = 0x00;
       move.l    -24(A6),A0
       clr.b     0(A0,D3.L)
       addq.l    #1,D3
       bra       executeToken_104
executeToken_106:
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_27:
; case 0x98:  // DATA - Ignora toda a linha depois dele, READ vai ler essa linha
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_28:
; case 0x99:  // Read
; vReta = basRead();
       jsr       _basRead
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_29:
; case 0x9A:  // Restore
; vReta = basRestore();
       jsr       _basRestore
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_30:
; case 0x9E:  // END
; vReta = basEnd();
       jsr       _basEnd
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_31:
; case 0x9F:  // STOP
; vReta = basStop();
       jsr       _basStop
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_32:
; case 0xB0:  // TEXT
; vReta = basText();
       jsr       _basText
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_33:
; case 0xB1:  // GR
; vReta = basGr();
       jsr       _basGr
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_34:
; case 0xB2:  // HGR
; vReta = basHgr();
       jsr       _basHgr
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_35:
; case 0xB3:  // COLOR
; vReta = basColor();
       jsr       _basColor
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_36:
; case 0xB4:  // PLOT
; vReta = basPlot();
       jsr       _basPlot
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_37:
; case 0xB5:  // HLIN
; vReta = basHVlin(1);
       pea       1
       jsr       _basHVlin
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_38:
; case 0xB6:  // VLIN
; vReta = basHVlin(2);
       pea       2
       jsr       _basHVlin
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_39:
; case 0xB8:  // HCOLOR
; vReta = basHcolor();
       jsr       _basHcolor
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_40:
; case 0xB9:  // HPLOT
; vReta = basHplot();
       jsr       _basHplot
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_41:
; case 0xBA:  // AT - Nao faz nada
; vReta = 0;
       clr.b     D2
; break;
       bra       executeToken_108
executeToken_42:
; case 0xBB:  // ONERR
; vReta = basOnErr();
       jsr       _basOnErr
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_43:
; case 0xC4:  // ASC
; vReta = basAsc();
       jsr       _basAsc
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_44:
; case 0xCD:  // PEEK
; vReta = basPeekPoke('R');
       pea       82
       jsr       _basPeekPoke
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_45:
; case 0xCE:  // POKE
; vReta = basPeekPoke('W');
       pea       87
       jsr       _basPeekPoke
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_46:
; case 0xD1:  // RND
; vReta = basRnd();
       jsr       _basRnd
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_47:
; case 0xDB:  // Len
; vReta = basLen();
       jsr       _basLen
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_48:
; case 0xDC:  // Val
; vReta = basVal();
       jsr       _basVal
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_49:
; case 0xDD:  // Str$
; vReta = basStr();
       jsr       _basStr
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_50:
; case 0xE0:  // SCRN
; vReta = basScrn();
       jsr       _basScrn
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_51:
; case 0xE1:  // Chr$
; vReta = basChr();
       jsr       _basChr
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_52:
; case 0xE2:  // Fre(0)
; vReta = basFre();
       jsr       _basFre
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_53:
; case 0xE3:  // Sqrt
; vReta = basTrig(6);
       pea       6
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_54:
; case 0xE4:  // Sin
; vReta = basTrig(1);
       pea       1
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_55:
; case 0xE5:  // Cos
; vReta = basTrig(2);
       pea       2
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_56:
; case 0xE6:  // Tan
; vReta = basTrig(3);
       pea       3
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_57:
; case 0xE7:  // Log
; vReta = basTrig(4);
       pea       4
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_58:
; case 0xE8:  // Exp
; vReta = basTrig(5);
       pea       5
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_59:
; case 0xE9:  // SPC
; vReta = basSpc();
       jsr       _basSpc
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_60:
; case 0xEA:  // Tab
; vReta = basTab();
       jsr       _basTab
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_61:
; case 0xEB:  // Mid$
; vReta = basLeftRightMid('M');
       pea       77
       jsr       (A3)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_62:
; case 0xEC:  // Right$
; vReta = basLeftRightMid('R');
       pea       82
       jsr       (A3)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_63:
; case 0xED:  // Left$
; vReta = basLeftRightMid('L');
       pea       76
       jsr       (A3)
       addq.w    #4,A7
       move.b    D0,D2
; break;
       bra       executeToken_108
executeToken_64:
; case 0xEE:  // INT
; vReta = basInt();
       jsr       _basInt
       move.b    D0,D2
; break;
       bra.s     executeToken_108
executeToken_65:
; case 0xEF:  // ABS
; vReta = basAbs();
       jsr       _basAbs
       move.b    D0,D2
; break;
       bra.s     executeToken_108
executeToken_1:
; default:
; if (pToken < 0x80)  // variavel sem LET
       move.b    11(A6),D0
       and.w     #255,D0
       cmp.w     #128,D0
       bhs.s     executeToken_107
; {
; *pointerRunProg = *pointerRunProg - 1;
       move.l    _pointerRunProg.L,A0
       subq.l    #1,(A0)
; vReta = basLet();
       jsr       _basLet
       move.b    D0,D2
       bra.s     executeToken_108
executeToken_107:
; }
; else // Nao forem operadores logicos
; {
; *vErroProc = 14;
       move.l    _vErroProc.L,A0
       move.w    #14,(A0)
; vReta = 14;
       moveq     #14,D2
executeToken_108:
; }
; }
; #endif
; return vReta;
       ext.w     D2
       ext.l     D2
       move.l    D2,D0
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; int nextToken(void)
; {
       xdef      _nextToken
_nextToken:
       link      A6,#-28
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _token_type.L,A2
       lea       _pointerRunProg.L,A3
       lea       _token.L,A4
       lea       _tok.L,A5
; unsigned char *temp;
; int vRet, ccc;
; unsigned char sqtdtam[20];
; unsigned char *vTempPointer;
; *token_type = 0;
       move.l    (A2),A0
       clr.b     (A0)
; *tok = 0;
       move.l    (A5),A0
       clr.b     (A0)
; temp = token;
       move.l    (A4),D3
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
; if (*vTempPointer >= 0x80 && *vTempPointer < 0xF0)   // is a command
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #128,D0
       blo       nextToken_1
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #240,D0
       bhs.s     nextToken_1
; {
; *tok = *vTempPointer;
       move.l    D2,A0
       move.l    (A5),A1
       move.b    (A0),(A1)
; *token_type = COMMAND;
       move.l    (A2),A0
       move.b    #4,(A0)
; *token = *vTempPointer;
       move.l    D2,A0
       move.l    (A4),A1
       move.b    (A0),(A1)
; *(token + 1) = 0x00;
       move.l    (A4),A0
       clr.b     1(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_1:
; }
; if (*vTempPointer == '\0') { // end of file
       move.l    D2,A0
       move.b    (A0),D0
       bne.s     nextToken_4
; *token = 0;
       move.l    (A4),A0
       clr.b     (A0)
; *tok = FINISHED;
       move.l    (A5),A0
       move.b    #224,(A0)
; *token_type = DELIMITER;
       move.l    (A2),A0
       move.b    #1,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_4:
; }
; while(iswhite(*vTempPointer)) // skip over white space
nextToken_6:
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _iswhite
       addq.w    #4,A7
       tst.l     D0
       beq.s     nextToken_8
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
       bra       nextToken_6
nextToken_8:
; }
; if (*vTempPointer == '\r') { // crlf
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #13,D0
       bne       nextToken_9
; *pointerRunProg = *pointerRunProg + 2;
       move.l    (A3),A0
       addq.l    #2,(A0)
; *tok = EOL;
       move.l    (A5),A0
       move.b    #226,(A0)
; *token = '\r';
       move.l    (A4),A0
       move.b    #13,(A0)
; *(token + 1) = '\n';
       move.l    (A4),A0
       move.b    #10,1(A0)
; *(token + 2) = 0;
       move.l    (A4),A0
       clr.b     2(A0)
; *token_type = DELIMITER;
       move.l    (A2),A0
       move.b    #1,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_9:
; }
; if (strchr("+-*^/=;:,><", *vTempPointer) || *vTempPointer >= 0xF0) { // delimiter
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @basic_125.L
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       bne.s     nextToken_13
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #240,D0
       blo.s     nextToken_14
       moveq     #1,D0
       bra.s     nextToken_15
nextToken_14:
       clr.l     D0
nextToken_15:
       ext.l     D0
       tst.l     D0
       beq.s     nextToken_11
nextToken_13:
; *temp = *vTempPointer;
       move.l    D2,A0
       move.l    D3,A1
       move.b    (A0),(A1)
; *pointerRunProg = *pointerRunProg + 1; // advance to next position
       move.l    (A3),A0
       addq.l    #1,(A0)
; temp++;
       addq.l    #1,D3
; *temp = 0;
       move.l    D3,A0
       clr.b     (A0)
; *token_type = DELIMITER;
       move.l    (A2),A0
       move.b    #1,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_11:
; }
; if (*vTempPointer == 0x28 || *vTempPointer == 0x29)
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #40,D0
       beq.s     nextToken_18
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #41,D0
       bne       nextToken_16
nextToken_18:
; {
; if (*vTempPointer == 0x28)
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #40,D0
       bne.s     nextToken_19
; *token_type = OPENPARENT;
       move.l    (A2),A0
       move.b    #8,(A0)
       bra.s     nextToken_20
nextToken_19:
; else
; *token_type = CLOSEPARENT;
       move.l    (A2),A0
       move.b    #9,(A0)
nextToken_20:
; *token = *vTempPointer;
       move.l    D2,A0
       move.l    (A4),A1
       move.b    (A0),(A1)
; *(token + 1) = 0x00;
       move.l    (A4),A0
       clr.b     1(A0)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_16:
; }
; if (*vTempPointer == ":")
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       lea       @basic_126.L,A0
       cmp.l     A0,D0
       bne.s     nextToken_21
; {
; *doisPontos = 1;
       move.l    _doisPontos.L,A0
       move.b    #1,(A0)
; *token_type = DOISPONTOS;
       move.l    (A2),A0
       move.b    #7,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_21:
; }
; if (*vTempPointer == '"') { // quoted string
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #34,D0
       bne       nextToken_23
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
; while(*vTempPointer != '"'&& *vTempPointer != '\r')
nextToken_25:
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #34,D0
       beq.s     nextToken_27
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #13,D0
       beq.s     nextToken_27
; {
; *temp++ = *vTempPointer;
       move.l    D2,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    (A0),(A1)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
       bra       nextToken_25
nextToken_27:
; }
; if (*vTempPointer == '\r')
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #13,D0
       bne.s     nextToken_28
; {
; *vErroProc = 14;
       move.l    _vErroProc.L,A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       nextToken_3
nextToken_28:
; }
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; *temp = 0;
       move.l    D3,A0
       clr.b     (A0)
; *token_type = QUOTE;
       move.l    (A2),A0
       move.b    #6,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_23:
; }
; if (isdigitus(*vTempPointer)) { // number
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isdigitus
       addq.w    #4,A7
       tst.l     D0
       beq       nextToken_30
; while(!isdelim(*vTempPointer) && (*vTempPointer < 0x80 || *vTempPointer >= 0xF0))
nextToken_32:
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isdelim
       addq.w    #4,A7
       tst.l     D0
       bne       nextToken_34
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #128,D0
       blo.s     nextToken_35
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #240,D0
       blo.s     nextToken_34
nextToken_35:
; {
; *temp++ = *vTempPointer;
       move.l    D2,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    (A0),(A1)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
       bra       nextToken_32
nextToken_34:
; }
; *temp = '\0';
       move.l    D3,A0
       clr.b     (A0)
; *token_type = NUMBER;
       move.l    (A2),A0
       move.b    #3,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra       nextToken_3
nextToken_30:
; }
; if (isalphas(*vTempPointer)) { // var or command
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq       nextToken_36
; while(!isdelim(*vTempPointer) && (*vTempPointer < 0x80 || *vTempPointer >= 0xF0))
nextToken_38:
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isdelim
       addq.w    #4,A7
       tst.l     D0
       bne       nextToken_40
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #128,D0
       blo.s     nextToken_41
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #240,D0
       blo.s     nextToken_40
nextToken_41:
; {
; *temp++ = *vTempPointer;
       move.l    D2,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    (A0),(A1)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
       bra       nextToken_38
nextToken_40:
; }
; *temp = '\0';
       move.l    D3,A0
       clr.b     (A0)
; *token_type = VARIABLE;
       move.l    (A2),A0
       move.b    #2,(A0)
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
       bra.s     nextToken_3
nextToken_36:
; }
; *temp = '\0';
       move.l    D3,A0
       clr.b     (A0)
; // see if a string is a command or a variable
; if (*token_type == STRING) {
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #5,D0
       bne.s     nextToken_42
; *token_type = VARIABLE;
       move.l    (A2),A0
       move.b    #2,(A0)
nextToken_42:
; }
; return *token_type;
       move.l    (A2),A0
       move.b    (A0),D0
       and.l     #255,D0
nextToken_3:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; int findToken(unsigned char pToken)
; {
       xdef      _findToken
_findToken:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char kt;
; // Procura o Token na lista e devolve a posicao
; for(kt = 0; kt < keywords_count; kt++)
       clr.b     D2
findToken_1:
       and.l     #255,D2
       cmp.l     _keywords_count.L,D2
       bhs.s     findToken_3
; {
; if (keywords[kt].token == pToken)
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #3,D0
       lea       @basic_keywords.L,A0
       add.l     D0,A0
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     4(A0),D0
       bne.s     findToken_4
; return kt;
       and.l     #255,D2
       move.l    D2,D0
       bra.s     findToken_6
findToken_4:
       addq.b    #1,D2
       bra       findToken_1
findToken_3:
; }
; // Procura o Token nas operacões de 1 char
; /*for(kt = 0; kt < keywordsUnique_count; kt++)
; {
; if (keywordsUnique[kt].token == pToken)
; return (kt + 0x80);
; }*/
; return 14;
       moveq     #14,D0
findToken_6:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; unsigned long findNumberLine(unsigned short pNumber, unsigned char pTipoRet, unsigned char pTipoFind)
; {
       xdef      _findNumberLine
_findNumberLine:
       link      A6,#-36
       movem.l   D2/D3/D4/D5,-(A7)
       move.w    10(A6),D4
       and.l     #65535,D4
; unsigned char *vStartList = *addrFirstLineNumber;
       move.l    _addrFirstLineNumber.L,A0
       move.l    (A0),D2
; unsigned char *vLastList = *addrFirstLineNumber;
       move.l    _addrFirstLineNumber.L,A0
       move.l    (A0),D5
; unsigned short vNumber = 0;
       clr.w     D3
; char vbuffer [sizeof(long)*8+1];
; if (pNumber)
       tst.w     D4
       beq       findNumberLine_5
; {
; while(vStartList)
findNumberLine_3:
       tst.l     D2
       beq       findNumberLine_5
; {
; vNumber = ((*(vStartList + 3) << 8) | *(vStartList + 4));
       move.l    D2,A0
       move.b    3(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.w     #255,D1
       or.w      D1,D0
       move.w    D0,D3
; if ((!pTipoFind && vNumber < pNumber) || (pTipoFind && vNumber != pNumber))
       tst.b     19(A6)
       bne.s     findNumberLine_10
       moveq     #1,D0
       bra.s     findNumberLine_11
findNumberLine_10:
       clr.l     D0
findNumberLine_11:
       and.l     #255,D0
       beq.s     findNumberLine_9
       cmp.w     D4,D3
       blo.s     findNumberLine_8
findNumberLine_9:
       move.b    19(A6),D0
       and.l     #255,D0
       beq       findNumberLine_6
       cmp.w     D4,D3
       beq       findNumberLine_6
findNumberLine_8:
; {
; vLastList = vStartList;
       move.l    D2,D5
; vStartList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D2,A0
       move.b    2(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
       bra.s     findNumberLine_7
findNumberLine_6:
; }
; else
; break;
       bra.s     findNumberLine_5
findNumberLine_7:
       bra       findNumberLine_3
findNumberLine_5:
; }
; }
; if (!pTipoRet)
       tst.b     15(A6)
       bne.s     findNumberLine_12
; return vStartList;
       move.l    D2,D0
       bra.s     findNumberLine_14
findNumberLine_12:
; else
; return vLastList;
       move.l    D5,D0
findNumberLine_14:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Return true if c is a alphabetical (A-Z or a-z).
; //--------------------------------------------------------------------------------------
; int isalphas(unsigned char c)
; {
       xdef      _isalphas
_isalphas:
       link      A6,#0
       move.l    D2,-(A7)
       move.b    11(A6),D2
       and.l     #255,D2
; if ((c>0x40 && c<0x5B) || (c>0x60 && c<0x7B))
       cmp.b     #64,D2
       bls.s     isalphas_4
       cmp.b     #91,D2
       blo.s     isalphas_3
isalphas_4:
       cmp.b     #96,D2
       bls.s     isalphas_1
       cmp.b     #123,D2
       bhs.s     isalphas_1
isalphas_3:
; return 1;
       moveq     #1,D0
       bra.s     isalphas_5
isalphas_1:
; return 0;
       clr.l     D0
isalphas_5:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Return true if c is a number (0-9).
; //--------------------------------------------------------------------------------------
; int isdigitus(unsigned char c)
; {
       xdef      _isdigitus
_isdigitus:
       link      A6,#0
; if (c>0x2F && c<0x3A)
       move.b    11(A6),D0
       cmp.b     #47,D0
       bls.s     isdigitus_1
       move.b    11(A6),D0
       cmp.b     #58,D0
       bhs.s     isdigitus_1
; return 1;
       moveq     #1,D0
       bra.s     isdigitus_3
isdigitus_1:
; return 0;
       clr.l     D0
isdigitus_3:
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Return true if c is a delimiter.
; //--------------------------------------------------------------------------------------
; int isdelim(unsigned char c)
; {
       xdef      _isdelim
_isdelim:
       link      A6,#0
       move.l    D2,-(A7)
       move.b    11(A6),D2
       and.l     #255,D2
; if (strchr(" ;,+-<>()/*^=:", c) || c==9 || c=='\r' || c==0 || c>=0xF0)
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @basic_114.L
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       bne       isdelim_3
       cmp.b     #9,D2
       bne.s     isdelim_4
       moveq     #1,D0
       bra.s     isdelim_5
isdelim_4:
       clr.l     D0
isdelim_5:
       and.l     #255,D0
       bne       isdelim_3
       cmp.b     #13,D2
       bne.s     isdelim_6
       moveq     #1,D0
       bra.s     isdelim_7
isdelim_6:
       clr.l     D0
isdelim_7:
       and.l     #255,D0
       bne       isdelim_3
       tst.b     D2
       bne.s     isdelim_8
       moveq     #1,D0
       bra.s     isdelim_9
isdelim_8:
       clr.l     D0
isdelim_9:
       and.l     #255,D0
       bne.s     isdelim_3
       and.w     #255,D2
       cmp.w     #240,D2
       blo.s     isdelim_10
       moveq     #1,D0
       bra.s     isdelim_11
isdelim_10:
       clr.l     D0
isdelim_11:
       ext.l     D0
       tst.l     D0
       beq.s     isdelim_1
isdelim_3:
; return 1;
       moveq     #1,D0
       bra.s     isdelim_12
isdelim_1:
; return 0;
       clr.l     D0
isdelim_12:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Return 1 if c is space or tab.
; //--------------------------------------------------------------------------------------
; int iswhite(unsigned char c)
; {
       xdef      _iswhite
_iswhite:
       link      A6,#0
; if (c==' ' || c=='\t')
       move.b    11(A6),D0
       cmp.b     #32,D0
       beq.s     iswhite_3
       move.b    11(A6),D0
       cmp.b     #9,D0
       bne.s     iswhite_1
iswhite_3:
; return 1;
       moveq     #1,D0
       bra.s     iswhite_4
iswhite_1:
; return 0;
       clr.l     D0
iswhite_4:
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Load basic program in memory, throught xmodem protocol
; // Syntaxe:
; //          XBASLOAD
; //--------------------------------------------------------------------------------------
; int basXBasLoad(void)
; {
       xdef      _basXBasLoad
_basXBasLoad:
       movem.l   D2/D3/D4/D5/A2,-(A7)
       lea       _printText.L,A2
; unsigned char vRet = 0;
       clr.b     D4
; unsigned char vByte = 0;
       clr.b     D2
; unsigned char *vTemp = pStartXBasLoad;
       move.l    _pStartXBasLoad.L,D5
; unsigned char *vBufptr = vbuf;
       move.l    _vbuf.L,D3
; printText("Loading Basic Program...\r\n");
       pea       @basic_127.L
       jsr       (A2)
       addq.w    #4,A7
; // Carrega programa em outro ponto da memoria
; vRet = loadSerialToMem("880000",0);
       clr.l     -(A7)
       pea       @basic_128.L
       jsr       _loadSerialToMem
       addq.w    #8,A7
       move.b    D0,D4
; // Se tudo OK, tokeniza como se estivesse sendo digitado
; if (!vRet)
       tst.b     D4
       bne       basXBasLoad_1
; {
; printText("Done.\r\n");
       pea       @basic_129.L
       jsr       (A2)
       addq.w    #4,A7
; printText("Processing...\r\n");
       pea       @basic_130.L
       jsr       (A2)
       addq.w    #4,A7
; while (1)
basXBasLoad_3:
; {
; vByte = *vTemp++;
       move.l    D5,A0
       addq.l    #1,D5
       move.b    (A0),D2
; if (vByte != 0x1A)
       cmp.b     #26,D2
       beq.s     basXBasLoad_6
; {
; if (vByte != 0xD && vByte != 0x0A)
       cmp.b     #13,D2
       beq.s     basXBasLoad_8
       cmp.b     #10,D2
       beq.s     basXBasLoad_8
; *vBufptr++ = vByte;
       move.l    D3,A0
       addq.l    #1,D3
       move.b    D2,(A0)
       bra.s     basXBasLoad_9
basXBasLoad_8:
; else
; {
; vTemp++;
       addq.l    #1,D5
; *vBufptr = 0x00;
       move.l    D3,A0
       clr.b     (A0)
; vBufptr = vbuf;
       move.l    _vbuf.L,D3
; processLine();
       jsr       _processLine
basXBasLoad_9:
       bra.s     basXBasLoad_7
basXBasLoad_6:
; }
; }
; else
; break;
       bra.s     basXBasLoad_5
basXBasLoad_7:
       bra       basXBasLoad_3
basXBasLoad_5:
; }
; printText("Done.\r\n");
       pea       @basic_129.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     basXBasLoad_11
basXBasLoad_1:
; }
; else
; {
; if (vRet == 0xFE)
       and.w     #255,D4
       cmp.w     #254,D4
       bne.s     basXBasLoad_10
; *vErroProc = 19;
       move.l    _vErroProc.L,A0
       move.w    #19,(A0)
       bra.s     basXBasLoad_11
basXBasLoad_10:
; else
; *vErroProc = 20;
       move.l    _vErroProc.L,A0
       move.w    #20,(A0)
basXBasLoad_11:
; }
; return 0;
       clr.l     D0
       movem.l   (A7)+,D2/D3/D4/D5/A2
       rts
; }
; #ifndef __TESTE_TOKENIZE__
; //-----------------------------------------------------------------------------
; // Retornos: -1 - Erro, 0 - Nao Existe, 1 - eh um valor numeral
; //           [endereco > 1] - Endereco da variavel
; //
; //           se retorno > 1: pVariable vai conter o valor numeral (qdo 1) ou
; //                           o conteudo da variavel (qdo endereco)
; //-----------------------------------------------------------------------------
; long findVariable(unsigned char* pVariable)
; {
       xdef      _findVariable
_findVariable:
       link      A6,#-448
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _writeLongSerial.L,A2
       lea       -374(A6),A3
       lea       _itoa.L,A4
       move.l    8(A6),D4
       lea       _vErroProc.L,A5
; unsigned char* vLista = pStartSimpVar;
       move.l    _pStartSimpVar.L,D2
; unsigned char* vTemp = pStartSimpVar;
       move.l    _pStartSimpVar.L,-448(A6)
; unsigned char* vListaAtu;
; long vEnder = 0, vVal = 0, vVal1 = 0, vVal2 = 0, vVal3 = 0, vVal4 = 0;
       clr.l     -440(A6)
       clr.l     -436(A6)
       clr.l     -432(A6)
       clr.l     -428(A6)
       clr.l     -424(A6)
       clr.l     -420(A6)
; int ix = 0, iy = 0, iz = 0;
       clr.l     D5
       clr.l     -416(A6)
       clr.l     -412(A6)
; char vbuffer [sizeof(long)*8+1];
; unsigned char sqtdtam[10];
; unsigned int vDim[88];
; int ixDim = 0;
       clr.l     D6
; unsigned char vArray = 0;
       moveq     #0,D7
; unsigned long vPosNextVar = 0;
       clr.l     -12(A6)
; unsigned char* vPosValueVar = 0;
       clr.l     D3
; unsigned char vTamValue = 4;
       move.b    #4,-7(A6)
; unsigned char *vTempPointer;
; unsigned short iDim = 0;
       clr.w     -2(A6)
; // Verifica se eh array (tem parenteses logo depois do nome da variavel)
; writeLongSerial("Aqui 444.666.0-[");
       pea       @basic_131.L
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial(pVariable);
       move.l    D4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),-6(A6)
; if (*vTempPointer == 0x28)
       move.l    -6(A6),A0
       move.b    (A0),D0
       cmp.b     #40,D0
       bne       findVariable_27
; {
; // Define que eh array
; vArray = 1;
       moveq     #1,D7
; // Procura as dimensoes
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     findVariable_3
       clr.l     D0
       bra       findVariable_5
findVariable_3:
; // Erro, primeiro caracter depois da variavel, deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     findVariable_8
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     findVariable_8
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     findVariable_6
findVariable_8:
; {
; *vErroProc = 15;
       move.l    (A5),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_6:
; }
; do
; {
findVariable_9:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     findVariable_11
       clr.l     D0
       bra       findVariable_5
findVariable_11:
; if (*token_type == QUOTE) { // is string, error
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     findVariable_13
; *vErroProc = 16;
       move.l    (A5),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_13:
; }
; else { // is expression
; putback();
       jsr       _putback
; getExp(&vDim[ixDim]);
       lea       -364(A6),A0
       move.l    D6,D1
       lsl.l     #2,D1
       add.l     D1,A0
       move.l    A0,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     findVariable_15
       clr.l     D0
       bra       findVariable_5
findVariable_15:
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     findVariable_17
; {
; *vErroProc = 16;
       move.l    (A5),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_17:
; }
; if (*value_type == '#')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     findVariable_19
; {
; vDim[ixDim] = fppInt(vDim[ixDim]);
       move.l    D6,D1
       lsl.l     #2,D1
       lea       -364(A6),A0
       move.l    0(A0,D1.L),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D6,D1
       lsl.l     #2,D1
       lea       -364(A6),A0
       move.l    D0,0(A0,D1.L)
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
findVariable_19:
; }
; ixDim++;
       addq.l    #1,D6
; }
; if (*token == ',')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #44,D0
       bne.s     findVariable_21
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),-6(A6)
       bra.s     findVariable_22
findVariable_21:
; }
; else
; break;
       bra.s     findVariable_10
findVariable_22:
       bra       findVariable_9
findVariable_10:
; } while(1);
; // Deve ter pelo menos 1 elemento
; if (ixDim < 1)
       cmp.l     #1,D6
       bge.s     findVariable_23
; {
; *vErroProc = 21;
       move.l    (A5),A0
       move.w    #21,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_23:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     findVariable_25
       clr.l     D0
       bra       findVariable_5
findVariable_25:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     findVariable_27
; {
; *vErroProc = 15;
       move.l    (A5),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_27:
; }
; }
; // Procura na lista geral de variaveis simples
; if (vArray)
       tst.b     D7
       beq.s     findVariable_29
; vLista = pStartArrayVar;
       move.l    _pStartArrayVar.L,D2
       bra.s     findVariable_30
findVariable_29:
; else
; vLista = pStartSimpVar;
       move.l    _pStartSimpVar.L,D2
findVariable_30:
; while(1)
findVariable_31:
; {
; writeLongSerial("Aqui 444.666.1-[");
       pea       @basic_133.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(*(vLista + 3),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,A0
       move.b    3(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(*(vLista + 4),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(*(vLista + 5),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,A0
       move.b    5(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(*(vLista + 6),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,A0
       move.b    6(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; vPosNextVar  = (((unsigned long)*(vLista + 3) << 24) & 0xFF000000);
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       and.l     #-16777216,D0
       move.l    D0,-12(A6)
; vPosNextVar |= (((unsigned long)*(vLista + 4) << 16) & 0x00FF0000);
       move.l    D2,A0
       move.b    4(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       and.l     #16711680,D0
       or.l      D0,-12(A6)
; vPosNextVar |= (((unsigned long)*(vLista + 5) << 8) & 0x0000FF00);
       move.l    D2,A0
       move.b    5(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       and.l     #65280,D0
       or.l      D0,-12(A6)
; vPosNextVar |= ((unsigned long)*(vLista + 6) & 0x000000FF);
       move.l    D2,A0
       move.b    6(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       or.l      D0,-12(A6)
; *value_type = *vLista;
       move.l    D2,A0
       move.l    _value_type.L,A1
       move.b    (A0),(A1)
; writeLongSerial("Aqui 444.666.2-[");
       pea       @basic_135.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vLista,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vPosNextVar,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    -12(A6),-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pVariable[0],sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D4,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pVariable[1],sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D4,A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; if (*(vLista + 1) == pVariable[0] && *(vLista + 2) ==  pVariable[1])
       move.l    D2,A0
       move.l    D4,A1
       move.b    1(A0),D0
       cmp.b     (A1),D0
       bne       findVariable_34
       move.l    D2,A0
       move.l    D4,A1
       move.b    2(A0),D0
       cmp.b     1(A1),D0
       bne       findVariable_34
; {
; writeLongSerial("Aqui 444.666.3-[");
       pea       @basic_136.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(*(vLista + 1),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(*(vLista + 2),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,A0
       move.b    2(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(ixDim,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D6,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; // Pega endereco da variavel pra delvover
; if (vArray)
       tst.b     D7
       beq       findVariable_36
; {
; if (*vLista == '$')
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     findVariable_38
; vTamValue = 5;
       move.b    #5,-7(A6)
findVariable_38:
; // Verifica se os tamanhos da dimensao informada e da variavel sao iguais
; if (ixDim != vLista[7])
       move.l    D2,A0
       move.b    7(A0),D0
       and.l     #255,D0
       cmp.l     D0,D6
       beq.s     findVariable_40
; {
; *vErroProc = 21;
       move.l    (A5),A0
       move.w    #21,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_40:
; }
; // Verifica se as posicoes informadas sao iguais ou menores que as da variavel, e ja calcula a nova posicao
; for (ix = ((ixDim - 1) * 2); ix >= 0; ix -= 2)
       move.l    D6,D0
       subq.l    #1,D0
       move.l    D0,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D5
findVariable_42:
       cmp.l     #0,D5
       blt       findVariable_44
; {
; // Verifica tamanho posicao
; iDim = ((vLista[ix + 8] << 8) | vLista[ix + 9]);
       move.l    D2,A0
       move.l    D5,A1
       move.b    8(A1,A0.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    D2,A0
       move.l    D5,A1
       move.b    9(A1,A0.L),D1
       and.w     #255,D1
       or.w      D1,D0
       move.w    D0,-2(A6)
; if ((vDim[ix] + 1) > iDim)
       move.l    D5,D0
       lsl.l     #2,D0
       lea       -364(A6),A0
       move.l    0(A0,D0.L),D0
       addq.l    #1,D0
       move.w    -2(A6),D1
       and.l     #65535,D1
       cmp.l     D1,D0
       bls.s     findVariable_45
; {
; *vErroProc = 21;
       move.l    (A5),A0
       move.w    #21,(A0)
; return 0;
       clr.l     D0
       bra       findVariable_5
findVariable_45:
; }
; // Calcular a posicao do conteudo da variavel
; if (!*vPosValueVar)
       move.l    D3,A0
       tst.b     (A0)
       bne.s     findVariable_47
; vPosValueVar = vDim[ix] * vTamValue;
       move.l    D5,D0
       lsl.l     #2,D0
       lea       -364(A6),A0
       move.b    -7(A6),D1
       and.l     #255,D1
       move.l    0(A0,D0.L),-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D3
       bra.s     findVariable_48
findVariable_47:
; else
; vPosValueVar = vPosValueVar * vDim[ix];
       move.l    D5,D0
       lsl.l     #2,D0
       lea       -364(A6),A0
       move.l    D3,-(A7)
       move.l    0(A0,D0.L),-(A7)
       jsr       ULMUL
       move.l    (A7),D3
       addq.w    #8,A7
findVariable_48:
       subq.l    #2,D5
       bra       findVariable_42
findVariable_44:
; }
; writeLongSerial("Aqui 444.666.4-[");
       pea       @basic_137.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vLista,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D2,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa((ixDim * 2),sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D6,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vPosValueVar,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; vPosValueVar = vLista + 8 + (ixDim * 2) + vPosValueVar;
       move.l    D2,D0
       addq.l    #8,D0
       move.l    D6,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       add.l     D3,D0
       move.l    D0,D3
; vEnder = vPosValueVar;
       move.l    D3,-440(A6)
       bra.s     findVariable_37
findVariable_36:
; }
; else
; {
; vPosValueVar = vLista + 3;
       move.l    D2,D0
       addq.l    #3,D0
       move.l    D0,D3
; vEnder = vLista;
       move.l    D2,-440(A6)
findVariable_37:
; }
; // Pelo tipo da variavel, ja retorna na variavel de nome o conteudo da variavel
; if (*vLista == '$')
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne       findVariable_49
; {
; vTemp  = (((unsigned long)*(vPosValueVar + 1) << 24) & 0xFF000000);
       move.l    D3,A0
       move.b    1(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       and.l     #-16777216,D0
       move.l    D0,-448(A6)
; vTemp |= (((unsigned long)*(vPosValueVar + 2) << 16) & 0x00FF0000);
       move.l    D3,A0
       move.b    2(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       and.l     #16711680,D0
       or.l      D0,-448(A6)
; vTemp |= (((unsigned long)*(vPosValueVar + 3) << 8) & 0x0000FF00);
       move.l    D3,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       and.l     #65280,D0
       or.l      D0,-448(A6)
; vTemp |= ((unsigned long)*(vPosValueVar + 4) & 0x000000FF);
       move.l    D3,A0
       move.b    4(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       or.l      D0,-448(A6)
; iy = *vPosValueVar;
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    D0,-416(A6)
; iz = 0;
       clr.l     -412(A6)
; for (ix = 0; ix < iy; ix++)
       clr.l     D5
findVariable_51:
       cmp.l     -416(A6),D5
       bge.s     findVariable_53
; {
; pVariable[iz++] = *(vTemp + ix); // Numero gerado
       move.l    -448(A6),A0
       move.l    D4,A1
       move.l    -412(A6),D0
       addq.l    #1,-412(A6)
       move.b    0(A0,D5.L),0(A1,D0.L)
; pVariable[iz] = 0x00;
       move.l    D4,A0
       move.l    -412(A6),D0
       clr.b     0(A0,D0.L)
       addq.l    #1,D5
       bra       findVariable_51
findVariable_53:
; }
; pVariable[iz++] = 0x00;
       move.l    D4,A0
       move.l    -412(A6),D0
       addq.l    #1,-412(A6)
       clr.b     0(A0,D0.L)
       bra       findVariable_50
findVariable_49:
; }
; else
; {
; if (!vArray)
       tst.b     D7
       bne.s     findVariable_54
; vPosValueVar++;
       addq.l    #1,D3
findVariable_54:
; pVariable[0] = *(vPosValueVar);
       move.l    D3,A0
       move.l    D4,A1
       move.b    (A0),(A1)
; pVariable[1] = *(vPosValueVar + 1);
       move.l    D3,A0
       move.l    D4,A1
       move.b    1(A0),1(A1)
; pVariable[2] = *(vPosValueVar + 2);
       move.l    D3,A0
       move.l    D4,A1
       move.b    2(A0),2(A1)
; pVariable[3] = *(vPosValueVar + 3);
       move.l    D3,A0
       move.l    D4,A1
       move.b    3(A0),3(A1)
; pVariable[4] = 0x00;
       move.l    D4,A0
       clr.b     4(A0)
findVariable_50:
; }
; return vEnder;
       move.l    -440(A6),D0
       bra       findVariable_5
findVariable_34:
; }
; if (vArray)
       tst.b     D7
       beq.s     findVariable_56
; vLista = vPosNextVar;
       move.l    -12(A6),D2
       bra.s     findVariable_57
findVariable_56:
; else
; vLista += 8;
       addq.l    #8,D2
findVariable_57:
; if ((!vArray && vLista >= pStartArrayVar) || (vArray && vLista >= pStartProg) || *vLista == 0x00)
       tst.b     D7
       bne.s     findVariable_62
       moveq     #1,D0
       bra.s     findVariable_63
findVariable_62:
       clr.l     D0
findVariable_63:
       and.l     #255,D0
       beq.s     findVariable_61
       cmp.l     _pStartArrayVar.L,D2
       bhs.s     findVariable_60
findVariable_61:
       and.l     #255,D7
       beq.s     findVariable_64
       cmp.l     _pStartProg.L,D2
       bhs.s     findVariable_60
findVariable_64:
       move.l    D2,A0
       move.b    (A0),D0
       bne.s     findVariable_58
findVariable_60:
; break;
       bra.s     findVariable_33
findVariable_58:
       bra       findVariable_31
findVariable_33:
; }
; return 0;
       clr.l     D0
findVariable_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; char createVariable(unsigned char* pVariable, unsigned char* pValor, char pType)
; {
       xdef      _createVariable
_createVariable:
       link      A6,#-40
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    8(A6),D3
       lea       _nextAddrSimpVar.L,A2
; char vRet = 0;
       clr.b     D4
; long vTemp = 0;
       clr.l     -38(A6)
; char vbuffer [sizeof(long)*8+1];
; unsigned char* vNextSimpVar;
; char vLenVar = 0;
       clr.b     -1(A6)
; vTemp = *nextAddrSimpVar;
       move.l    (A2),A0
       move.l    (A0),-38(A6)
; vNextSimpVar = *nextAddrSimpVar;
       move.l    (A2),A0
       move.l    (A0),D2
; vLenVar = strlen(pVariable);
       move.l    D3,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.b    D0,-1(A6)
; *vNextSimpVar++ = pType;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    19(A6),(A0)
; *vNextSimpVar++ = pVariable[0];
       move.l    D3,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
; *vNextSimpVar++ = pVariable[1];
       move.l    D3,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    1(A0),(A1)
; vRet = updateVariable(vNextSimpVar, pValor, pType, 0);
       clr.l     -(A7)
       move.b    19(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    12(A6),-(A7)
       move.l    D2,-(A7)
       jsr       _updateVariable
       add.w     #16,A7
       move.b    D0,D4
; *nextAddrSimpVar += 8;
       move.l    (A2),A0
       addq.l    #8,(A0)
; return vRet;
       move.b    D4,D0
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; char updateVariable(unsigned long* pVariable, unsigned char* pValor, char pType, char pOper)
; {
       xdef      _updateVariable
_updateVariable:
       link      A6,#-116
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _writeLongSerial.L,A2
       lea       -80(A6),A3
       move.l    12(A6),D4
       lea       _itoa.L,A4
       lea       _nextAddrString.L,A5
; int vNumVal = 0;
       clr.l     D5
; int ix, iz = 0;
       clr.l     D6
; char vbuffer [sizeof(long)*8+1];
; unsigned char* vNextSimpVar;
; unsigned char* vNextString;
; unsigned char* sqtdtam[20];
; vNextSimpVar = pVariable;
       move.l    8(A6),D2
; *atuVarAddr = pVariable;
       move.l    _atuVarAddr.L,A0
       move.l    8(A6),(A0)
; writeLongSerial("Aqui 333.666.0-[");
       pea       @basic_138.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pVariable,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    8(A6),-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pValor,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pType,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.b    19(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; if (pType == '#' || pType == '%')   // Real ou Inteiro
       move.b    19(A6),D0
       cmp.b     #35,D0
       beq.s     updateVariable_3
       move.b    19(A6),D0
       cmp.b     #37,D0
       bne       updateVariable_1
updateVariable_3:
; {
; if (vNextSimpVar < 0x00802000)
       cmp.l     #8396800,D2
       bhs.s     updateVariable_4
; *vNextSimpVar++ = 0x00;
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
updateVariable_4:
; *vNextSimpVar++ = pValor[0];
       move.l    D4,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
; *vNextSimpVar++ = pValor[1];
       move.l    D4,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    1(A0),(A1)
; *vNextSimpVar++ = pValor[2];
       move.l    D4,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    2(A0),(A1)
; *vNextSimpVar++ = pValor[3];
       move.l    D4,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    3(A0),(A1)
       bra       updateVariable_2
updateVariable_1:
; }
; else // String
; {
; iz = strlen(pValor);    // Tamanho da strings
       move.l    D4,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; // Se for o mesmo tamanho ou menor, usa a mesma posicao
; if (*vNextSimpVar <= iz && pOper)
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       cmp.l     D6,D0
       bhi       updateVariable_6
       move.b    23(A6),D0
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq       updateVariable_6
; {
; vNextString  = (((unsigned long)*(vNextSimpVar + 1) << 24) & 0xFF000000);
       move.l    D2,A0
       move.b    1(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       and.l     #-16777216,D0
       move.l    D0,D3
; vNextString |= (((unsigned long)*(vNextSimpVar + 2) << 16) & 0x00FF0000);
       move.l    D2,A0
       move.b    2(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       and.l     #16711680,D0
       or.l      D0,D3
; vNextString |= (((unsigned long)*(vNextSimpVar + 3) << 8) & 0x0000FF00);
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       and.l     #65280,D0
       or.l      D0,D3
; vNextString |= ((unsigned long)*(vNextSimpVar + 4) & 0x000000FF);
       move.l    D2,A0
       move.b    4(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       or.l      D0,D3
       bra.s     updateVariable_7
updateVariable_6:
; }
; else
; vNextString = *nextAddrString;
       move.l    (A5),A0
       move.l    (A0),D3
updateVariable_7:
; vNumVal = vNextString;
       move.l    D3,D5
; for (ix = 0; ix < iz; ix++)
       moveq     #0,D7
updateVariable_8:
       cmp.l     D6,D7
       bge.s     updateVariable_10
; {
; *vNextString++ = pValor[ix];
       move.l    D4,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    0(A0,D7.L),(A1)
       addq.l    #1,D7
       bra       updateVariable_8
updateVariable_10:
; }
; writeLongSerial("Aqui 333.666.1-[");
       pea       @basic_139.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(nextAddrString,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    (A5),-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vNextString,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[");
       pea       @basic_134.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vNumVal,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D5,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @basic_132.L
       jsr       (A2)
       addq.w    #4,A7
; if (*vNextSimpVar > iz || !pOper)
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       cmp.l     D6,D0
       bhi.s     updateVariable_13
       tst.b     23(A6)
       bne.s     updateVariable_14
       moveq     #1,D0
       bra.s     updateVariable_15
updateVariable_14:
       clr.l     D0
updateVariable_15:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq.s     updateVariable_11
updateVariable_13:
; *nextAddrString = vNextString;
       move.l    (A5),A0
       move.l    D3,(A0)
updateVariable_11:
; *vNextSimpVar++ = iz;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D6,(A0)
; *vNextSimpVar++ = ((vNumVal & 0xFF000000) >>24);
       move.l    D5,D0
       and.l     #-16777216,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
; *vNextSimpVar++ = ((vNumVal & 0x00FF0000) >>16);
       move.l    D5,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
; *vNextSimpVar++ = ((vNumVal & 0x0000FF00) >>8);
       move.l    D5,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
; *vNextSimpVar++ = (vNumVal & 0x000000FF);
       move.l    D5,D0
       and.l     #255,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D0,(A0)
updateVariable_2:
; }
; /*    *(vNextSimpVar + 1) = 0x00;
; *(vNextSimpVar + 2) = 0x00;
; *(vNextSimpVar + 3) = 0x00;
; *(vNextSimpVar + 4) = 0x00;*/
; return 0;
       clr.b     D0
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; char createVariableArray(unsigned char* pVariable, char pType, unsigned int pNumDim, unsigned int *pDim)
; {
       xdef      _createVariableArray
_createVariableArray:
       link      A6,#-64
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3,-(A7)
       move.l    20(A6),D5
       move.l    16(A6),D6
       lea       _nextAddrArrayVar.L,A2
       move.l    8(A6),A3
; char vRet = 0;
       clr.b     -63(A6)
; long vTemp = 0;
       clr.l     -62(A6)
; unsigned char* vTempC = &vTemp;
       lea       -62(A6),A0
       move.l    A0,D7
; char vbuffer [sizeof(long)*8+1];
; unsigned char* vNextArrayVar;
; char vLenVar = 0;
       clr.b     -25(A6)
; int ix, vTam, vAreaFree = (pStartString - *nextAddrArrayVar);
       move.l    _pStartString.L,D0
       move.l    (A2),A0
       sub.l     (A0),D0
       move.l    D0,-24(A6)
; unsigned char sqtdtam[20];
; vTemp = *nextAddrArrayVar;
       move.l    (A2),A0
       move.l    (A0),-62(A6)
; vNextArrayVar = *nextAddrArrayVar;
       move.l    (A2),A0
       move.l    (A0),D3
; vLenVar = strlen(pVariable);
       move.l    A3,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.b    D0,-25(A6)
; *vNextArrayVar++ = pType;
       move.l    D3,A0
       addq.l    #1,D3
       move.b    15(A6),(A0)
; *vNextArrayVar++ = pVariable[0];
       move.l    D3,A0
       addq.l    #1,D3
       move.b    (A3),(A0)
; *vNextArrayVar++ = pVariable[1];
       move.l    D3,A0
       addq.l    #1,D3
       move.b    1(A3),(A0)
; vTam = 0;
       clr.l     D4
; for (ix = 0; ix < pNumDim; ix++)
       clr.l     D2
createVariableArray_1:
       cmp.l     D6,D2
       bhs       createVariableArray_3
; {
; // Somando mais 1, porque 0 = 1 em quantidade e e em posicao (igual ao c)
; pDim[ix] = pDim[ix] + 1;
       move.l    D5,A0
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A0,D0.L),D0
       addq.l    #1,D0
       move.l    D5,A0
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    D0,0(A0,D1.L)
; // Definir o tamanho do campo de dados do array
; if (vTam == 0)
       tst.l     D4
       bne.s     createVariableArray_4
; vTam = pDim[ix];
       move.l    D5,A0
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A0,D0.L),D4
       bra.s     createVariableArray_5
createVariableArray_4:
; else
; vTam = vTam * pDim[ix];
       move.l    D5,A0
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    D4,-(A7)
       move.l    0(A0,D0.L),-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D4
createVariableArray_5:
       addq.l    #1,D2
       bra       createVariableArray_1
createVariableArray_3:
; }
; if (pType == '$')
       move.b    15(A6),D0
       cmp.b     #36,D0
       bne.s     createVariableArray_6
; vTam = vTam * 5;
       move.l    D4,-(A7)
       pea       5
       jsr       LMUL
       move.l    (A7),D4
       addq.w    #8,A7
       bra.s     createVariableArray_7
createVariableArray_6:
; else
; vTam = vTam * 4;
       move.l    D4,-(A7)
       pea       4
       jsr       LMUL
       move.l    (A7),D4
       addq.w    #8,A7
createVariableArray_7:
; if ((vTam + 8 + (pNumDim *2)) > vAreaFree)
       move.l    D4,D0
       addq.l    #8,D0
       move.l    D6,-(A7)
       pea       2
       jsr       ULMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       cmp.l     -24(A6),D0
       bls.s     createVariableArray_8
; {
; *vErroProc = 22;
       move.l    _vErroProc.L,A0
       move.w    #22,(A0)
; return 0;
       clr.b     D0
       bra       createVariableArray_10
createVariableArray_8:
; }
; // Coloca setup do array
; vTemp = vTemp + vTam + 8 + (pNumDim * 2);
       move.l    -62(A6),D0
       add.l     D4,D0
       addq.l    #8,D0
       move.l    D6,-(A7)
       pea       2
       jsr       ULMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.l    D0,-62(A6)
; *vNextArrayVar++ = vTempC[0];
       move.l    D7,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    (A0),(A1)
; *vNextArrayVar++ = vTempC[1];
       move.l    D7,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    1(A0),(A1)
; *vNextArrayVar++ = vTempC[2];
       move.l    D7,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    2(A0),(A1)
; *vNextArrayVar++ = vTempC[3];
       move.l    D7,A0
       move.l    D3,A1
       addq.l    #1,D3
       move.b    3(A0),(A1)
; *vNextArrayVar++ = pNumDim;
       move.l    D3,A0
       addq.l    #1,D3
       move.b    D6,(A0)
; for (ix = 0; ix < pNumDim; ix++)
       clr.l     D2
createVariableArray_11:
       cmp.l     D6,D2
       bhs       createVariableArray_13
; {
; *vNextArrayVar++ = (pDim[ix] >> 8);
       move.l    D5,A0
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A0,D0.L),D0
       lsr.l     #8,D0
       move.l    D3,A0
       addq.l    #1,D3
       move.b    D0,(A0)
; *vNextArrayVar++ = (pDim[ix] & 0xFF);
       move.l    D5,A0
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A0,D0.L),D0
       and.l     #255,D0
       move.l    D3,A0
       addq.l    #1,D3
       move.b    D0,(A0)
       addq.l    #1,D2
       bra       createVariableArray_11
createVariableArray_13:
; }
; // Limpa area de dados (zera)
; for (ix = 0; ix < vTam; ix++)
       clr.l     D2
createVariableArray_14:
       cmp.l     D4,D2
       bge.s     createVariableArray_16
; *(vNextArrayVar + ix) = 0x00;
       move.l    D3,A0
       clr.b     0(A0,D2.L)
       addq.l    #1,D2
       bra       createVariableArray_14
createVariableArray_16:
; *nextAddrArrayVar = vTemp;
       move.l    (A2),A0
       move.l    -62(A6),(A0)
; return 0;
       clr.b     D0
createVariableArray_10:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Return a token to input stream.
; //--------------------------------------------------------------------------------------
; void putback(void)
; {
       xdef      _putback
_putback:
       link      A6,#-4
; unsigned char *t;
; if (*token_type==COMMAND)    // comando nao faz isso
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #4,D0
       bne.s     putback_1
; return;
       bra.s     putback_6
putback_1:
; t = token;
       move.l    _token.L,-4(A6)
; while (*t++)
putback_4:
       move.l    -4(A6),A0
       addq.l    #1,-4(A6)
       tst.b     (A0)
       beq.s     putback_6
; *pointerRunProg = *pointerRunProg - 1;
       move.l    _pointerRunProg.L,A0
       subq.l    #1,(A0)
       bra       putback_4
putback_6:
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Return compara 2 strings
; //--------------------------------------------------------------------------------------
; int ustrcmp(char *X, char *Y)
; {
       xdef      _ustrcmp
_ustrcmp:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D2
       move.l    12(A6),D3
; while (*X)
ustrcmp_1:
       move.l    D2,A0
       tst.b     (A0)
       beq.s     ustrcmp_3
; {
; // if characters differ, or end of the second string is reached
; if (*X != *Y) {
       move.l    D2,A0
       move.l    D3,A1
       move.b    (A0),D0
       cmp.b     (A1),D0
       beq.s     ustrcmp_4
; break;
       bra.s     ustrcmp_3
ustrcmp_4:
; }
; // move to the next pair of characters
; X++;
       addq.l    #1,D2
; Y++;
       addq.l    #1,D3
       bra       ustrcmp_1
ustrcmp_3:
; }
; // return the ASCII difference after converting `char*` to `unsigned char*`
; return *(unsigned char*)X - *(unsigned char*)Y;
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       sub.l     D1,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Entry point into parser.
; //--------------------------------------------------------------------------------------
; void getExp(unsigned char *result)
; {
       xdef      _getExp
_getExp:
       link      A6,#-12
       move.l    A2,-(A7)
       lea       _vErroProc.L,A2
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     getExp_1
       bra.s     getExp_3
getExp_1:
; if (!*token) {
       move.l    _token.L,A0
       tst.b     (A0)
       bne.s     getExp_4
; *vErroProc = 2;
       move.l    (A2),A0
       move.w    #2,(A0)
; return;
       bra.s     getExp_3
getExp_4:
; }
; level2(result);
       move.l    8(A6),-(A7)
       jsr       _level2
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     getExp_6
       bra.s     getExp_3
getExp_6:
; putback(); // return last token read to input stream
       jsr       _putback
; return;
getExp_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //  Add or subtract two terms real/int or string.
; //--------------------------------------------------------------------------------------
; void level2(unsigned char *result)
; {
       xdef      _level2
_level2:
       link      A6,#-92
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4,-(A7)
       lea       _value_type.L,A2
       lea       _vErroProc.L,A3
       lea       -90(A6),A4
       move.l    8(A6),D4
; char  op;
; unsigned char hold[50];
; unsigned char valueTypeAnt;
; unsigned int *lresult = result;
       move.l    D4,D6
; unsigned int *lhold = hold;
       move.l    A4,D5
; unsigned char* sqtdtam[10];
; level3(result);
       move.l    D4,-(A7)
       jsr       _level3
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level2_1
       bra       level2_3
level2_1:
; op = *token;
       move.l    _token.L,A0
       move.b    (A0),D2
; while(op == '+' || op == '-') {
level2_4:
       cmp.b     #43,D2
       beq.s     level2_7
       cmp.b     #45,D2
       bne       level2_6
level2_7:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level2_8
       bra       level2_3
level2_8:
; valueTypeAnt = *value_type;
       move.l    (A2),A0
       move.b    (A0),D3
; level3(&hold);
       move.l    A4,-(A7)
       jsr       _level3
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level2_10
       bra       level2_3
level2_10:
; if (*value_type != valueTypeAnt)
       move.l    (A2),A0
       cmp.b     (A0),D3
       beq.s     level2_14
; {
; if (*value_type == '$' || valueTypeAnt == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     level2_16
       cmp.b     #36,D3
       bne.s     level2_14
level2_16:
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level2_3
level2_14:
; }
; }
; // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
; if (*value_type == '$' && valueTypeAnt == '$' && op == '+')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level2_17
       cmp.b     #36,D3
       bne.s     level2_17
       cmp.b     #43,D2
       bne.s     level2_17
; strcat(result,&hold);
       move.l    A4,-(A7)
       move.l    D4,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       bra       level2_30
level2_17:
; else if ((*value_type == '$' || valueTypeAnt == '$') && op == '-')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     level2_21
       cmp.b     #36,D3
       bne.s     level2_19
level2_21:
       cmp.b     #45,D2
       bne.s     level2_19
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level2_3
level2_19:
; }
; else
; {
; if (*value_type != valueTypeAnt)
       move.l    (A2),A0
       cmp.b     (A0),D3
       beq       level2_28
; {
; if (*value_type == '$' || valueTypeAnt == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     level2_26
       cmp.b     #36,D3
       bne.s     level2_24
level2_26:
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level2_3
level2_24:
; }
; else if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level2_27
; {
; *lresult = fppReal(*lresult);
       move.l    D6,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D6,A0
       move.l    D0,(A0)
       bra.s     level2_28
level2_27:
; }
; else
; {
; *lhold = fppReal(*lhold);
       move.l    D5,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D5,A0
       move.l    D0,(A0)
; *value_type = '#';
       move.l    (A2),A0
       move.b    #35,(A0)
level2_28:
; }
; }
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level2_29
; arithReal(op, result, &hold);
       move.l    A4,-(A7)
       move.l    D4,-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _arithReal
       add.w     #12,A7
       bra.s     level2_30
level2_29:
; else
; arithInt(op, result, &hold);
       move.l    A4,-(A7)
       move.l    D4,-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _arithInt
       add.w     #12,A7
level2_30:
; }
; op = *token;
       move.l    _token.L,A0
       move.b    (A0),D2
       bra       level2_4
level2_6:
; }
; return;
level2_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Multiply or divide two factors real/int.
; //--------------------------------------------------------------------------------------
; void level3(unsigned char *result)
; {
       xdef      _level3
_level3:
       link      A6,#-92
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4/A5,-(A7)
       lea       _value_type.L,A2
       lea       _vErroProc.L,A3
       lea       _fppReal.L,A4
       lea       _token.L,A5
       move.l    8(A6),D6
; char  op;
; unsigned char hold[50];
; unsigned int *lresult = result;
       move.l    D6,D4
; unsigned int *lhold = hold;
       lea       -90(A6),A0
       move.l    A0,D3
; char value_type_ant=0;
       clr.b     D5
; unsigned char* sqtdtam[10];
; do
; {
level3_1:
; level30(result);
       move.l    D6,-(A7)
       jsr       _level30
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level3_3
       bra       level3_5
level3_3:
; if (*token==0xF3||*token==0xF4)
       move.l    (A5),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #243,D0
       beq.s     level3_8
       move.l    (A5),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #244,D0
       bne.s     level3_6
level3_8:
; {
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level3_9
       bra       level3_5
level3_9:
       bra.s     level3_7
level3_6:
; }
; else
; break;
       bra.s     level3_2
level3_7:
       bra       level3_1
level3_2:
; }
; while (1);
; op = *token;
       move.l    (A5),A0
       move.b    (A0),D2
; while(op == '*' || op == '/' || op == '%') {
level3_11:
       cmp.b     #42,D2
       beq.s     level3_14
       cmp.b     #47,D2
       beq.s     level3_14
       cmp.b     #37,D2
       bne       level3_13
level3_14:
; if (*value_type == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level3_15
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level3_5
level3_15:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level3_17
       bra       level3_5
level3_17:
; value_type_ant = *value_type;
       move.l    (A2),A0
       move.b    (A0),D5
; level4(&hold);
       pea       -90(A6)
       jsr       _level4
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level3_19
       bra       level3_5
level3_19:
; // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
; if (*value_type == '$' || value_type_ant == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     level3_23
       cmp.b     #36,D5
       bne.s     level3_21
level3_23:
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level3_5
level3_21:
; }
; if (*value_type != value_type_ant)
       move.l    (A2),A0
       cmp.b     (A0),D5
       beq       level3_27
; {
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level3_26
; {
; *lresult = fppReal(*lresult);
       move.l    D4,A0
       move.l    (A0),-(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D4,A0
       move.l    D0,(A0)
       bra.s     level3_27
level3_26:
; }
; else
; {
; *lhold = fppReal(*lhold);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '#';
       move.l    (A2),A0
       move.b    #35,(A0)
level3_27:
; }
; }
; // se valor inteiro e for divisao, obrigatoriamente devolve valor real
; if (*value_type == '%' && op == '/')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #37,D0
       bne       level3_28
       cmp.b     #47,D2
       bne.s     level3_28
; {
; *lresult = fppReal(*lresult);
       move.l    D4,A0
       move.l    (A0),-(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D4,A0
       move.l    D0,(A0)
; *lhold = fppReal(*lhold);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '#';
       move.l    (A2),A0
       move.b    #35,(A0)
level3_28:
; }
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level3_30
; arithReal(op, result, &hold);
       pea       -90(A6)
       move.l    D6,-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _arithReal
       add.w     #12,A7
       bra.s     level3_31
level3_30:
; else
; arithInt(op, result, &hold);
       pea       -90(A6)
       move.l    D6,-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _arithInt
       add.w     #12,A7
level3_31:
; op = *token;
       move.l    (A5),A0
       move.b    (A0),D2
       bra       level3_11
level3_13:
; }
; return;
level3_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Is a NOT
; //--------------------------------------------------------------------------------------
; void level30(unsigned char *result)
; {
       xdef      _level30
_level30:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _vErroProc.L,A2
; char  op;
; int *iLog = result;
       move.l    8(A6),D3
; op = 0;
       clr.b     D2
; if (*token == 0xF8) // NOT
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #248,D0
       bne.s     level30_3
; {
; op = *token;
       move.l    _token.L,A0
       move.b    (A0),D2
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level30_3
       bra       level30_5
level30_3:
; }
; level31(result);
       move.l    8(A6),-(A7)
       jsr       _level31
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level30_6
       bra       level30_5
level30_6:
; if (op)
       tst.b     D2
       beq       level30_8
; {
; if (*value_type == '$' || *value_type == '#')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     level30_12
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level30_10
level30_12:
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return;
       bra.s     level30_5
level30_10:
; }
; *iLog = !*iLog;
       move.l    D3,A0
       tst.l     (A0)
       bne.s     level30_13
       moveq     #1,D0
       bra.s     level30_14
level30_13:
       clr.l     D0
level30_14:
       move.l    D3,A0
       move.l    D0,(A0)
level30_8:
; }
; return;
level30_5:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Process logic conditions
; //--------------------------------------------------------------------------------------
; void level31(unsigned char *result)
; {
       xdef      _level31
_level31:
       link      A6,#-92
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _vErroProc.L,A2
; unsigned char  op;
; unsigned char hold[50];
; char value_type_ant=0;
       clr.b     -41(A6)
; int *rVal = result;
       move.l    8(A6),D2
; int *hVal = hold;
       lea       -92(A6),A0
       move.l    A0,D4
; unsigned char* sqtdtam[10];
; level32(result);
       move.l    8(A6),-(A7)
       jsr       _level32
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level31_1
       bra       level31_3
level31_1:
; op = *token;
       move.l    _token.L,A0
       move.b    (A0),D3
; if (op==0xF3 /* AND */|| op==0xF4 /* OR */) {
       and.w     #255,D3
       cmp.w     #243,D3
       beq.s     level31_6
       and.w     #255,D3
       cmp.w     #244,D3
       bne       level31_12
level31_6:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level31_7
       bra       level31_3
level31_7:
; level32(&hold);
       pea       -92(A6)
       jsr       _level32
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level31_9
       bra       level31_3
level31_9:
; /*writeLongSerial("Aqui 333.666.0-[");
; itoa(op,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*rVal,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*hVal,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]\r\n");*/
; if (op==0xF3)
       and.w     #255,D3
       cmp.w     #243,D3
       bne.s     level31_11
; *rVal = (*rVal && *hVal);
       move.l    D2,A0
       tst.l     (A0)
       beq.s     level31_13
       move.l    D4,A0
       tst.l     (A0)
       beq.s     level31_13
       moveq     #1,D0
       bra.s     level31_14
level31_13:
       clr.l     D0
level31_14:
       move.l    D2,A0
       move.l    D0,(A0)
       bra.s     level31_12
level31_11:
; else
; *rVal = (*rVal || *hVal);
       move.l    D2,A0
       tst.l     (A0)
       bne.s     level31_17
       move.l    D4,A0
       tst.l     (A0)
       beq.s     level31_15
level31_17:
       moveq     #1,D0
       bra.s     level31_16
level31_15:
       clr.l     D0
level31_16:
       move.l    D2,A0
       move.l    D0,(A0)
level31_12:
; /*riteLongSerial("Aqui 333.666.1-[");
; itoa(op,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*rVal,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]\r\n");*/
; }
; return;
level31_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Process logic conditions
; //--------------------------------------------------------------------------------------
; void level32(unsigned char *result)
; {
       xdef      _level32
_level32:
       link      A6,#-72
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4,-(A7)
       lea       _value_type.L,A2
       lea       -70(A6),A3
       move.l    8(A6),D3
       lea       _vErroProc.L,A4
; unsigned char  op;
; unsigned char hold[50];
; unsigned char value_type_ant=0;
       clr.b     D4
; unsigned int *lresult = result;
       move.l    D3,D6
; unsigned int *lhold = hold;
       move.l    A3,D5
; unsigned char sqtdtam[20];
; level4(result);
       move.l    D3,-(A7)
       jsr       _level4
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     level32_1
       bra       level32_3
level32_1:
; op = *token;
       move.l    _token.L,A0
       move.b    (A0),D2
; if (op=='=' || op=='<' || op=='>' || op==0xF5 /* >= */ || op==0xF6 /* <= */|| op==0xF7 /* <> */) {
       cmp.b     #61,D2
       beq.s     level32_6
       cmp.b     #60,D2
       beq.s     level32_6
       cmp.b     #62,D2
       beq.s     level32_6
       and.w     #255,D2
       cmp.w     #245,D2
       beq.s     level32_6
       and.w     #255,D2
       cmp.w     #246,D2
       beq.s     level32_6
       and.w     #255,D2
       cmp.w     #247,D2
       bne       level32_22
level32_6:
; //        if (op==0xF5 /* >= */ || op==0xF6 /* <= */|| op==0xF7)
; //            pointerRunProg++;
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     level32_7
       bra       level32_3
level32_7:
; value_type_ant = *value_type;
       move.l    (A2),A0
       move.b    (A0),D4
; level4(&hold);
       move.l    A3,-(A7)
       jsr       _level4
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     level32_9
       bra       level32_3
level32_9:
; if ((value_type_ant=='$' && *value_type!='$') || (value_type_ant != '$' && *value_type == '$'))
       cmp.b     #36,D4
       bne.s     level32_14
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level32_13
level32_14:
       cmp.b     #36,D4
       beq.s     level32_11
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level32_11
level32_13:
; {
; *vErroProc = 16;
       move.l    (A4),A0
       move.w    #16,(A0)
; return;
       bra       level32_3
level32_11:
; }
; // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
; if (*value_type != value_type_ant)
       move.l    (A2),A0
       cmp.b     (A0),D4
       beq       level32_18
; {
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level32_17
; {
; *lresult = fppReal(*lresult);
       move.l    D6,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D6,A0
       move.l    D0,(A0)
       bra.s     level32_18
level32_17:
; }
; else
; {
; *lhold = fppReal(*lhold);
       move.l    D5,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D5,A0
       move.l    D0,(A0)
; *value_type = '#';
       move.l    (A2),A0
       move.b    #35,(A0)
level32_18:
; }
; }
; if (*value_type == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level32_19
; logicalString(op, result, &hold);
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _logicalString
       add.w     #12,A7
       bra       level32_22
level32_19:
; else if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level32_21
; logicalNumericFloat(op, result, &hold);
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _logicalNumericFloat
       add.w     #12,A7
       bra.s     level32_22
level32_21:
; else
; logicalNumericInt(op, result, &hold);
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _logicalNumericInt
       add.w     #12,A7
level32_22:
; }
; return;
level32_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Process integer exponent real/int.
; //--------------------------------------------------------------------------------------
; void level4(unsigned char *result)
; {
       xdef      _level4
_level4:
       link      A6,#-52
       movem.l   D2/D3/D4/D5/A2/A3/A4,-(A7)
       lea       _value_type.L,A2
       lea       _vErroProc.L,A3
       lea       -50(A6),A4
       move.l    8(A6),D2
; unsigned char hold[50];
; unsigned int *lresult = result;
       move.l    D2,D5
; unsigned int *lhold = hold;
       move.l    A4,D4
; char value_type_ant=0;
       clr.b     D3
; level5(result);
       move.l    D2,-(A7)
       jsr       _level5
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level4_1
       bra       level4_3
level4_1:
; if (*token== '^') {
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #94,D0
       bne       level4_19
; if (*value_type == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level4_6
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level4_3
level4_6:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level4_8
       bra       level4_3
level4_8:
; value_type_ant = *value_type;
       move.l    (A2),A0
       move.b    (A0),D3
; level4(&hold);
       move.l    A4,-(A7)
       jsr       _level4
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     level4_10
       bra       level4_3
level4_10:
; if (*value_type == '$')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level4_12
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return;
       bra       level4_3
level4_12:
; }
; // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
; if (*value_type != value_type_ant)
       move.l    (A2),A0
       cmp.b     (A0),D3
       beq       level4_17
; {
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level4_16
; {
; *lresult = fppReal(*lresult);
       move.l    D5,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D5,A0
       move.l    D0,(A0)
       bra.s     level4_17
level4_16:
; }
; else
; {
; *lhold = fppReal(*lhold);
       move.l    D4,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D4,A0
       move.l    D0,(A0)
; *value_type = '#';
       move.l    (A2),A0
       move.b    #35,(A0)
level4_17:
; }
; }
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level4_18
; arithReal('^', result, &hold);
       move.l    A4,-(A7)
       move.l    D2,-(A7)
       pea       94
       jsr       _arithReal
       add.w     #12,A7
       bra.s     level4_19
level4_18:
; else
; arithInt('^', result, &hold);
       move.l    A4,-(A7)
       move.l    D2,-(A7)
       pea       94
       jsr       _arithInt
       add.w     #12,A7
level4_19:
; }
; return;
level4_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Is a unary + or -.
; //--------------------------------------------------------------------------------------
; void level5(unsigned char *result)
; {
       xdef      _level5
_level5:
       link      A6,#0
       movem.l   D2/D3/A2/A3,-(A7)
       move.l    8(A6),D3
       lea       _vErroProc.L,A2
       lea       _token.L,A3
; char  op;
; op = 0;
       clr.b     D2
; if (*token_type==DELIMITER && (*token=='+' || *token=='-')) {
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       bne.s     level5_4
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #43,D0
       beq.s     level5_3
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #45,D0
       bne.s     level5_4
level5_3:
; op = *token;
       move.l    (A3),A0
       move.b    (A0),D2
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level5_4
       bra       level5_6
level5_4:
; }
; level6(result);
       move.l    D3,-(A7)
       jsr       _level6
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level5_7
       bra       level5_6
level5_7:
; if (op)
       tst.b     D2
       beq       level5_14
; {
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     level5_11
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return;
       bra       level5_6
level5_11:
; }
; if (*value_type == '#')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     level5_13
; unaryReal(op, result);
       move.l    D3,-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _unaryReal
       addq.w    #8,A7
       bra.s     level5_14
level5_13:
; else
; unaryInt(op, result);
       move.l    D3,-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _unaryInt
       addq.w    #8,A7
level5_14:
; }
; return;
level5_6:
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Process parenthesized expression real/int/string or function.
; //--------------------------------------------------------------------------------------
; void level6(unsigned char *result)
; {
       xdef      _level6
_level6:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _vErroProc.L,A2
; if ((*token == '(') && (*token_type == OPENPARENT)) {
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #40,D0
       bne       level6_1
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       bne       level6_1
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level6_3
       bra       level6_5
level6_3:
; level2(result);
       move.l    8(A6),-(A7)
       jsr       _level2
       addq.w    #4,A7
; if (*token != ')')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #41,D0
       beq.s     level6_6
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return;
       bra.s     level6_5
level6_6:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     level6_8
       bra.s     level6_5
level6_8:
       bra.s     level6_2
level6_1:
; }
; else
; {
; primitive(result);
       move.l    8(A6),-(A7)
       jsr       _primitive
       addq.w    #4,A7
; return;
       bra       level6_5
level6_2:
; }
; return;
level6_5:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Find value of number or variable.
; //--------------------------------------------------------------------------------------
; void primitive(unsigned char *result)
; {
       xdef      _primitive
_primitive:
       link      A6,#-16
       movem.l   D2/D3/D4/D5/A2/A3/A4/A5,-(A7)
       lea       _token.L,A2
       move.l    8(A6),D2
       lea       _vErroProc.L,A3
       lea       _value_type.L,A4
       lea       _nextToken.L,A5
; unsigned long ix;
; unsigned char* vix = &ix;
       lea       -14(A6),A0
       move.l    A0,D3
; unsigned char* vRet;
; unsigned char sqtdtam[10];
; unsigned char *vTempPointer;
; switch(*token_type) {
       move.l    _token_type.L,A0
       move.b    (A0),D0
       and.l     #255,D0
       subq.l    #2,D0
       blo       primitive_1
       cmp.l     #5,D0
       bhs       primitive_1
       asl.l     #1,D0
       move.w    primitive_3(PC,D0.L),D0
       jmp       primitive_3(PC,D0.W)
primitive_3:
       dc.w      primitive_4-primitive_3
       dc.w      primitive_6-primitive_3
       dc.w      primitive_7-primitive_3
       dc.w      primitive_1-primitive_3
       dc.w      primitive_5-primitive_3
primitive_4:
; case VARIABLE:
; if (strlen(token) < 3)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #3,D0
       bge.s     primitive_9
; {
; *value_type=VARTYPEDEFAULT;
       move.l    (A4),A0
       move.b    #35,(A0)
; if (strlen(token) == 2 && *(token + 1) < 0x30)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     primitive_11
       move.l    (A2),A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bhs.s     primitive_11
; *value_type = *(token + 1);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    1(A0),(A1)
primitive_11:
       bra.s     primitive_10
primitive_9:
; }
; else
; {
; *value_type = *(token + 2);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    2(A0),(A1)
primitive_10:
; }
; vRet = find_var(token);
       move.l    (A2),-(A7)
       jsr       _find_var
       addq.w    #4,A7
       move.l    D0,D5
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_13
       bra       primitive_15
primitive_13:
; if (*value_type == '$')  // Tipo da variavel
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     primitive_16
; strcpy(result,vRet);
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
       bra.s     primitive_20
primitive_16:
; else
; {
; for (ix = 0;ix < 5;ix++)
       clr.l     -14(A6)
primitive_18:
       move.l    -14(A6),D0
       cmp.l     #5,D0
       bhs.s     primitive_20
; result[ix] = vRet[ix];
       move.l    D5,A0
       move.l    -14(A6),D0
       move.l    D2,A1
       move.l    -14(A6),D1
       move.b    0(A0,D0.L),0(A1,D1.L)
       addq.l    #1,-14(A6)
       bra       primitive_18
primitive_20:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_21
       bra       primitive_15
primitive_21:
; return;
       bra       primitive_15
primitive_5:
; case QUOTE:
; *value_type='$';
       move.l    (A4),A0
       move.b    #36,(A0)
; strcpy(result,token);
       move.l    (A2),-(A7)
       move.l    D2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; nextToken();
       jsr       (A5)
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_23
       bra       primitive_15
primitive_23:
; return;
       bra       primitive_15
primitive_6:
; case NUMBER:
; if (strchr(token,'.'))  // verifica se eh numero inteiro ou real
       pea       46
       move.l    (A2),-(A7)
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       beq.s     primitive_25
; {
; *value_type='#'; // Real
       move.l    (A4),A0
       move.b    #35,(A0)
; ix=floatStringToFpp(token);
       move.l    (A2),-(A7)
       jsr       _floatStringToFpp
       addq.w    #4,A7
       move.l    D0,-14(A6)
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_27
       bra       primitive_15
primitive_27:
       bra.s     primitive_26
primitive_25:
; }
; else
; {
; *value_type='%'; // Inteiro
       move.l    (A4),A0
       move.b    #37,(A0)
; ix=atoi(token);
       move.l    (A2),-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,-14(A6)
primitive_26:
; }
; vix = &ix;
       lea       -14(A6),A0
       move.l    A0,D3
; result[0] = vix[0];
       move.l    D3,A0
       move.l    D2,A1
       move.b    (A0),(A1)
; result[1] = vix[1];
       move.l    D3,A0
       move.l    D2,A1
       move.b    1(A0),1(A1)
; result[2] = vix[2];
       move.l    D3,A0
       move.l    D2,A1
       move.b    2(A0),2(A1)
; result[3] = vix[3];
       move.l    D3,A0
       move.l    D2,A1
       move.b    3(A0),3(A1)
; nextToken();
       jsr       (A5)
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_29
       bra       primitive_15
primitive_29:
; return;
       bra       primitive_15
primitive_7:
; case COMMAND:
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),D4
; *token = *vTempPointer;
       move.l    D4,A0
       move.l    (A2),A1
       move.b    (A0),(A1)
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
; executeToken(*vTempPointer);  // Retorno do resultado da funcao deve voltar pela variavel token. *value_type tera o tipo de retorno
       move.l    D4,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _executeToken
       addq.w    #4,A7
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_31
       bra       primitive_15
primitive_31:
; if (*value_type == '$')  // Tipo do retorno
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     primitive_33
; strcpy(result,token);
       move.l    (A2),-(A7)
       move.l    D2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
       bra.s     primitive_37
primitive_33:
; else
; {
; for (ix = 0; ix < 4; ix++)
       clr.l     -14(A6)
primitive_35:
       move.l    -14(A6),D0
       cmp.l     #4,D0
       bhs.s     primitive_37
; {
; result[ix] = *(token + ix);
       move.l    (A2),A0
       move.l    -14(A6),D0
       move.l    D2,A1
       move.l    -14(A6),D1
       move.b    0(A0,D0.L),0(A1,D1.L)
       addq.l    #1,-14(A6)
       bra       primitive_35
primitive_37:
; }
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     primitive_38
       bra.s     primitive_15
primitive_38:
; return;
       bra.s     primitive_15
primitive_1:
; default:
; *vErroProc = 14;
       move.l    (A3),A0
       move.w    #14,(A0)
; return;
primitive_15:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4/A5
       unlk      A6
       rts
; }
; return;
; }
; //--------------------------------------------------------------------------------------
; // Perform the specified arithmetic inteiro.
; //--------------------------------------------------------------------------------------
; void arithInt(char o, char *r, char *h)
; {
       xdef      _arithInt
_arithInt:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6,-(A7)
       move.l    12(A6),D5
; int t, ex;
; int *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
       move.l    D5,D2
; int *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
       move.l    16(A6),D3
; char* vRval = rVal;
       move.l    D2,D4
; switch(o) {
       move.b    11(A6),D0
       ext.w     D0
       ext.l     D0
       cmp.l     #45,D0
       beq.s     arithInt_3
       bgt.s     arithInt_8
       cmp.l     #43,D0
       beq.s     arithInt_4
       bgt       arithInt_2
       cmp.l     #42,D0
       beq       arithInt_5
       bra       arithInt_2
arithInt_8:
       cmp.l     #94,D0
       beq       arithInt_7
       bgt       arithInt_2
       cmp.l     #47,D0
       beq       arithInt_6
       bra       arithInt_2
arithInt_3:
; case '-':
; *rVal = *rVal - *hVal;
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A1),D0
       sub.l     D0,(A0)
; break;
       bra       arithInt_2
arithInt_4:
; case '+':
; *rVal = *rVal + *hVal;
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A1),D0
       add.l     D0,(A0)
; break;
       bra       arithInt_2
arithInt_5:
; case '*':
; *rVal = *rVal * *hVal;
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),-(A7)
       move.l    (A1),-(A7)
       jsr       LMUL
       move.l    (A7),(A0)
       addq.w    #8,A7
; break;
       bra       arithInt_2
arithInt_6:
; case '/':
; *rVal = (*rVal)/(*hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),-(A7)
       move.l    (A1),-(A7)
       jsr       LDIV
       move.l    (A7),(A0)
       addq.w    #8,A7
; break;
       bra       arithInt_2
arithInt_7:
; case '^':
; ex = *rVal;
       move.l    D2,A0
       move.l    (A0),D6
; if (*hVal==0) {
       move.l    D3,A0
       move.l    (A0),D0
       bne.s     arithInt_9
; *rVal = 1;
       move.l    D2,A0
       move.l    #1,(A0)
; break;
       bra.s     arithInt_2
arithInt_9:
; }
; ex = powNum(*rVal,*hVal);
       move.l    D3,A0
       move.l    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _powNum
       addq.w    #8,A7
       move.l    D0,D6
; *rVal = ex;
       move.l    D2,A0
       move.l    D6,(A0)
; break;
arithInt_2:
; }
; r[0] = vRval[0];
       move.l    D4,A0
       move.l    D5,A1
       move.b    (A0),(A1)
; r[1] = vRval[1];
       move.l    D4,A0
       move.l    D5,A1
       move.b    1(A0),1(A1)
; r[2] = vRval[2];
       move.l    D4,A0
       move.l    D5,A1
       move.b    2(A0),2(A1)
; r[3] = vRval[3];
       move.l    D4,A0
       move.l    D5,A1
       move.b    3(A0),3(A1)
       movem.l   (A7)+,D2/D3/D4/D5/D6
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Perform the specified arithmetic real.
; //--------------------------------------------------------------------------------------
; void arithReal(char o, char *r, char *h)
; {
       xdef      _arithReal
_arithReal:
       link      A6,#-12
       movem.l   D2/D3,-(A7)
; int t, ex;
; unsigned long *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
       move.l    12(A6),D2
; unsigned long *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
       move.l    16(A6),D3
; char* vRval = rVal;
       move.l    D2,-4(A6)
; switch(o) {
       move.b    11(A6),D0
       ext.w     D0
       ext.l     D0
       cmp.l     #45,D0
       beq.s     arithReal_3
       bgt.s     arithReal_8
       cmp.l     #43,D0
       beq       arithReal_4
       bgt       arithReal_2
       cmp.l     #42,D0
       beq       arithReal_5
       bra       arithReal_2
arithReal_8:
       cmp.l     #94,D0
       beq       arithReal_7
       bgt       arithReal_2
       cmp.l     #47,D0
       beq       arithReal_6
       bra       arithReal_2
arithReal_3:
; case '-':
; *rVal = fppSub(*rVal, *hVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppSub
       addq.w    #8,A7
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       arithReal_2
arithReal_4:
; case '+':
; *rVal = fppSum(*rVal, *hVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppSum
       addq.w    #8,A7
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       arithReal_2
arithReal_5:
; case '*':
; *rVal = fppMul(*rVal, *hVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppMul
       addq.w    #8,A7
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       arithReal_2
arithReal_6:
; case '/':
; *rVal = fppDiv(*rVal, *hVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppDiv
       addq.w    #8,A7
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra.s     arithReal_2
arithReal_7:
; case '^':
; *rVal = fppPwr(*rVal, *hVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppPwr
       addq.w    #8,A7
       move.l    D2,A0
       move.l    D0,(A0)
; break;
arithReal_2:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; void logicalNumericFloat(unsigned char o, char *r, char *h)
; {
       xdef      _logicalNumericFloat
_logicalNumericFloat:
       link      A6,#-12
       movem.l   D2/D3,-(A7)
; int t, ex;
; unsigned long *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
       move.l    12(A6),D3
; unsigned long *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
       move.l    16(A6),-4(A6)
; unsigned long oCCR = 0;
       clr.l     D2
; oCCR = fppComp(*rVal, *hVal);
       move.l    -4(A6),A0
       move.l    (A0),-(A7)
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       _fppComp
       addq.w    #8,A7
       move.l    D0,D2
; *rVal = 0;
       move.l    D3,A0
       clr.l     (A0)
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
; switch(o) {
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #245,D0
       beq       logicalNumericFloat_6
       bhi.s     logicalNumericFloat_9
       cmp.l     #61,D0
       beq.s     logicalNumericFloat_3
       bhi.s     logicalNumericFloat_10
       cmp.l     #60,D0
       beq       logicalNumericFloat_5
       bra       logicalNumericFloat_2
logicalNumericFloat_10:
       cmp.l     #62,D0
       beq.s     logicalNumericFloat_4
       bra       logicalNumericFloat_2
logicalNumericFloat_9:
       cmp.l     #247,D0
       beq       logicalNumericFloat_8
       bhi       logicalNumericFloat_2
       cmp.l     #246,D0
       beq       logicalNumericFloat_7
       bra       logicalNumericFloat_2
logicalNumericFloat_3:
; case '=':
; if (oCCR & 0x04)    // Z=1
       move.l    D2,D0
       and.l     #4,D0
       beq.s     logicalNumericFloat_11
; *rVal = 1;
       move.l    D3,A0
       move.l    #1,(A0)
logicalNumericFloat_11:
; break;
       bra       logicalNumericFloat_2
logicalNumericFloat_4:
; case '>':
; if (!(oCCR & 0x08) && !(oCCR & 0x04))   // N=0 e Z=0
       move.l    D2,D0
       and.l     #8,D0
       bne.s     logicalNumericFloat_13
       move.l    D2,D0
       and.l     #4,D0
       bne.s     logicalNumericFloat_13
; *rVal = 1;
       move.l    D3,A0
       move.l    #1,(A0)
logicalNumericFloat_13:
; break;
       bra       logicalNumericFloat_2
logicalNumericFloat_5:
; case '<':
; if ((oCCR & 0x08) && !(oCCR & 0x04))   // N=1 e Z=0
       move.l    D2,D0
       and.l     #8,D0
       beq.s     logicalNumericFloat_15
       move.l    D2,D0
       and.l     #4,D0
       bne.s     logicalNumericFloat_15
; *rVal = 1;
       move.l    D3,A0
       move.l    #1,(A0)
logicalNumericFloat_15:
; break;
       bra       logicalNumericFloat_2
logicalNumericFloat_6:
; case 0xF5:  // >=
; if (!(oCCR & 0x08) || (oCCR & 0x04))   // N=0 ou Z=1
       move.l    D2,D0
       and.l     #8,D0
       beq.s     logicalNumericFloat_19
       move.l    D2,D0
       and.l     #4,D0
       beq.s     logicalNumericFloat_17
logicalNumericFloat_19:
; *rVal = 1;
       move.l    D3,A0
       move.l    #1,(A0)
logicalNumericFloat_17:
; break;
       bra.s     logicalNumericFloat_2
logicalNumericFloat_7:
; case 0xF6:  // <=
; if ((oCCR & 0x08) || (oCCR & 0x04))   // N=1 ou Z=1
       move.l    D2,D0
       and.l     #8,D0
       bne.s     logicalNumericFloat_22
       move.l    D2,D0
       and.l     #4,D0
       beq.s     logicalNumericFloat_20
logicalNumericFloat_22:
; *rVal = 1;
       move.l    D3,A0
       move.l    #1,(A0)
logicalNumericFloat_20:
; break;
       bra.s     logicalNumericFloat_2
logicalNumericFloat_8:
; case 0xF7:  // <>
; if (!(oCCR & 0x04)) // z=0
       move.l    D2,D0
       and.l     #4,D0
       bne.s     logicalNumericFloat_23
; *rVal = 1;
       move.l    D3,A0
       move.l    #1,(A0)
logicalNumericFloat_23:
; break;
logicalNumericFloat_2:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; char logicalNumericFloatLong(unsigned char o, long r, long h)
; {
       xdef      _logicalNumericFloatLong
_logicalNumericFloatLong:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; char ex = 0;
       clr.b     D3
; unsigned long oCCR = 0;
       clr.l     D2
; oCCR = fppComp(r, h);
       move.l    16(A6),-(A7)
       move.l    12(A6),-(A7)
       jsr       _fppComp
       addq.w    #8,A7
       move.l    D0,D2
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
; switch(o) {
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #245,D0
       beq       logicalNumericFloatLong_6
       bhi.s     logicalNumericFloatLong_9
       cmp.l     #61,D0
       beq.s     logicalNumericFloatLong_3
       bhi.s     logicalNumericFloatLong_10
       cmp.l     #60,D0
       beq       logicalNumericFloatLong_5
       bra       logicalNumericFloatLong_2
logicalNumericFloatLong_10:
       cmp.l     #62,D0
       beq.s     logicalNumericFloatLong_4
       bra       logicalNumericFloatLong_2
logicalNumericFloatLong_9:
       cmp.l     #247,D0
       beq       logicalNumericFloatLong_8
       bhi       logicalNumericFloatLong_2
       cmp.l     #246,D0
       beq       logicalNumericFloatLong_7
       bra       logicalNumericFloatLong_2
logicalNumericFloatLong_3:
; case '=':
; if (oCCR & 0x04)    // Z=1
       move.l    D2,D0
       and.l     #4,D0
       beq.s     logicalNumericFloatLong_11
; ex = 1;
       moveq     #1,D3
logicalNumericFloatLong_11:
; break;
       bra       logicalNumericFloatLong_2
logicalNumericFloatLong_4:
; case '>':
; if (!(oCCR & 0x08) && !(oCCR & 0x04))   // N=0 e Z=0
       move.l    D2,D0
       and.l     #8,D0
       bne.s     logicalNumericFloatLong_13
       move.l    D2,D0
       and.l     #4,D0
       bne.s     logicalNumericFloatLong_13
; ex = 1;
       moveq     #1,D3
logicalNumericFloatLong_13:
; break;
       bra       logicalNumericFloatLong_2
logicalNumericFloatLong_5:
; case '<':
; if ((oCCR & 0x08) && !(oCCR & 0x04))   // N=1 e Z=0
       move.l    D2,D0
       and.l     #8,D0
       beq.s     logicalNumericFloatLong_15
       move.l    D2,D0
       and.l     #4,D0
       bne.s     logicalNumericFloatLong_15
; ex = 1;
       moveq     #1,D3
logicalNumericFloatLong_15:
; break;
       bra       logicalNumericFloatLong_2
logicalNumericFloatLong_6:
; case 0xF5:  // >=
; if (!(oCCR & 0x08) || (oCCR & 0x04))   // N=0 ou Z=1
       move.l    D2,D0
       and.l     #8,D0
       beq.s     logicalNumericFloatLong_19
       move.l    D2,D0
       and.l     #4,D0
       beq.s     logicalNumericFloatLong_17
logicalNumericFloatLong_19:
; ex = 1;
       moveq     #1,D3
logicalNumericFloatLong_17:
; break;
       bra.s     logicalNumericFloatLong_2
logicalNumericFloatLong_7:
; case 0xF6:  // <=
; if ((oCCR & 0x08) || (oCCR & 0x04))   // N=1 ou Z=1
       move.l    D2,D0
       and.l     #8,D0
       bne.s     logicalNumericFloatLong_22
       move.l    D2,D0
       and.l     #4,D0
       beq.s     logicalNumericFloatLong_20
logicalNumericFloatLong_22:
; ex = 1;
       moveq     #1,D3
logicalNumericFloatLong_20:
; break;
       bra.s     logicalNumericFloatLong_2
logicalNumericFloatLong_8:
; case 0xF7:  // <>
; if (!(oCCR & 0x04)) // z=0
       move.l    D2,D0
       and.l     #4,D0
       bne.s     logicalNumericFloatLong_23
; ex = 1;
       moveq     #1,D3
logicalNumericFloatLong_23:
; break;
logicalNumericFloatLong_2:
; }
; return ex;
       move.b    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; void logicalNumericInt(unsigned char o, char *r, char *h)
; {
       xdef      _logicalNumericInt
_logicalNumericInt:
       link      A6,#-8
       movem.l   D2/D3,-(A7)
; int t, ex;
; int *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
       move.l    12(A6),D2
; int *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
       move.l    16(A6),D3
; switch(o) {
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #245,D0
       beq       logicalNumericInt_6
       bhi.s     logicalNumericInt_9
       cmp.l     #61,D0
       beq.s     logicalNumericInt_3
       bhi.s     logicalNumericInt_10
       cmp.l     #60,D0
       beq       logicalNumericInt_5
       bra       logicalNumericInt_2
logicalNumericInt_10:
       cmp.l     #62,D0
       beq       logicalNumericInt_4
       bra       logicalNumericInt_2
logicalNumericInt_9:
       cmp.l     #247,D0
       beq       logicalNumericInt_8
       bhi       logicalNumericInt_2
       cmp.l     #246,D0
       beq       logicalNumericInt_7
       bra       logicalNumericInt_2
logicalNumericInt_3:
; case '=':
; *rVal = (*rVal == *hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),D0
       cmp.l     (A1),D0
       bne.s     logicalNumericInt_11
       moveq     #1,D0
       bra.s     logicalNumericInt_12
logicalNumericInt_11:
       clr.l     D0
logicalNumericInt_12:
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       logicalNumericInt_2
logicalNumericInt_4:
; case '>':
; *rVal = (*rVal > *hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),D0
       cmp.l     (A1),D0
       ble.s     logicalNumericInt_13
       moveq     #1,D0
       bra.s     logicalNumericInt_14
logicalNumericInt_13:
       clr.l     D0
logicalNumericInt_14:
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       logicalNumericInt_2
logicalNumericInt_5:
; case '<':
; *rVal = (*rVal < *hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),D0
       cmp.l     (A1),D0
       bge.s     logicalNumericInt_15
       moveq     #1,D0
       bra.s     logicalNumericInt_16
logicalNumericInt_15:
       clr.l     D0
logicalNumericInt_16:
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       logicalNumericInt_2
logicalNumericInt_6:
; case 0xF5:
; *rVal = (*rVal >= *hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),D0
       cmp.l     (A1),D0
       blt.s     logicalNumericInt_17
       moveq     #1,D0
       bra.s     logicalNumericInt_18
logicalNumericInt_17:
       clr.l     D0
logicalNumericInt_18:
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra       logicalNumericInt_2
logicalNumericInt_7:
; case 0xF6:
; *rVal = (*rVal <= *hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),D0
       cmp.l     (A1),D0
       bgt.s     logicalNumericInt_19
       moveq     #1,D0
       bra.s     logicalNumericInt_20
logicalNumericInt_19:
       clr.l     D0
logicalNumericInt_20:
       move.l    D2,A0
       move.l    D0,(A0)
; break;
       bra.s     logicalNumericInt_2
logicalNumericInt_8:
; case 0xF7:
; *rVal = (*rVal != *hVal);
       move.l    D2,A0
       move.l    D3,A1
       move.l    (A0),D0
       cmp.l     (A1),D0
       beq.s     logicalNumericInt_21
       moveq     #1,D0
       bra.s     logicalNumericInt_22
logicalNumericInt_21:
       clr.l     D0
logicalNumericInt_22:
       move.l    D2,A0
       move.l    D0,(A0)
; break;
logicalNumericInt_2:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; void logicalString(unsigned char o, char *r, char *h)
; {
       xdef      _logicalString
_logicalString:
       link      A6,#-4
       movem.l   D2/D3,-(A7)
; int t, ex;
; int *rVal = r;
       move.l    12(A6),D3
; ex = ustrcmp(r,h);
       move.l    16(A6),-(A7)
       move.l    12(A6),-(A7)
       jsr       _ustrcmp
       addq.w    #8,A7
       move.l    D0,D2
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
; switch(o) {
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #245,D0
       beq       logicalString_6
       bhi.s     logicalString_9
       cmp.l     #61,D0
       beq.s     logicalString_3
       bhi.s     logicalString_10
       cmp.l     #60,D0
       beq       logicalString_5
       bra       logicalString_2
logicalString_10:
       cmp.l     #62,D0
       beq.s     logicalString_4
       bra       logicalString_2
logicalString_9:
       cmp.l     #247,D0
       beq       logicalString_8
       bhi       logicalString_2
       cmp.l     #246,D0
       beq       logicalString_7
       bra       logicalString_2
logicalString_3:
; case '=':
; *rVal = (ex == 0);
       tst.l     D2
       bne.s     logicalString_11
       moveq     #1,D0
       bra.s     logicalString_12
logicalString_11:
       clr.l     D0
logicalString_12:
       move.l    D3,A0
       move.l    D0,(A0)
; break;
       bra       logicalString_2
logicalString_4:
; case '>':
; *rVal = (ex > 0);
       cmp.l     #0,D2
       ble.s     logicalString_13
       moveq     #1,D0
       bra.s     logicalString_14
logicalString_13:
       clr.l     D0
logicalString_14:
       move.l    D3,A0
       move.l    D0,(A0)
; break;
       bra       logicalString_2
logicalString_5:
; case '<':
; *rVal = (ex < 0);
       cmp.l     #0,D2
       bge.s     logicalString_15
       moveq     #1,D0
       bra.s     logicalString_16
logicalString_15:
       clr.l     D0
logicalString_16:
       move.l    D3,A0
       move.l    D0,(A0)
; break;
       bra       logicalString_2
logicalString_6:
; case 0xF5:
; *rVal = (ex >= 0);
       cmp.l     #0,D2
       blt.s     logicalString_17
       moveq     #1,D0
       bra.s     logicalString_18
logicalString_17:
       clr.l     D0
logicalString_18:
       move.l    D3,A0
       move.l    D0,(A0)
; break;
       bra.s     logicalString_2
logicalString_7:
; case 0xF6:
; *rVal = (ex <= 0);
       cmp.l     #0,D2
       bgt.s     logicalString_19
       moveq     #1,D0
       bra.s     logicalString_20
logicalString_19:
       clr.l     D0
logicalString_20:
       move.l    D3,A0
       move.l    D0,(A0)
; break;
       bra.s     logicalString_2
logicalString_8:
; case 0xF7:
; *rVal = (ex != 0);
       tst.l     D2
       beq.s     logicalString_21
       moveq     #1,D0
       bra.s     logicalString_22
logicalString_21:
       clr.l     D0
logicalString_22:
       move.l    D3,A0
       move.l    D0,(A0)
; break;
logicalString_2:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------------------
; // Reverse the sign.
; //--------------------------------------------------------------------------------------
; void unaryInt(char o, int *r)
; {
       xdef      _unaryInt
_unaryInt:
       link      A6,#0
; if (o=='-')
       move.b    11(A6),D0
       cmp.b     #45,D0
       bne.s     unaryInt_1
; *r = -(*r);
       move.l    12(A6),A0
       move.l    (A0),D0
       neg.l     D0
       move.l    12(A6),A0
       move.l    D0,(A0)
unaryInt_1:
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Reverse the sign.
; //--------------------------------------------------------------------------------------
; void unaryReal(char o, int *r)
; {
       xdef      _unaryReal
_unaryReal:
       link      A6,#0
; if (o=='-')
       move.b    11(A6),D0
       cmp.b     #45,D0
       bne.s     unaryReal_1
; {
; *r = fppNeg(*r);
       move.l    12(A6),A0
       move.l    (A0),-(A7)
       jsr       _fppNeg
       addq.w    #4,A7
       move.l    12(A6),A0
       move.l    D0,(A0)
unaryReal_1:
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------------------
; // Find the value of a variable.
; //--------------------------------------------------------------------------------------
; unsigned char* find_var(char *s)
; {
       xdef      _find_var
_find_var:
       link      A6,#-252
       movem.l   D2/A2/A3/A4,-(A7)
       move.l    8(A6),D2
       lea       -250(A6),A2
       lea       _strlen.L,A3
       lea       _vErroProc.L,A4
; unsigned char vTemp[250];
; *vErroProc = 0x00;
       move.l    (A4),A0
       clr.w     (A0)
; if (!isalphas(*s)){
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne.s     find_var_1
; *vErroProc = 4; // not a variable
       move.l    (A4),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       find_var_3
find_var_1:
; }
; if (strlen(s) < 3)
       move.l    D2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #3,D0
       bge       find_var_4
; {
; vTemp[0] = *s;
       move.l    D2,A0
       move.b    (A0),(A2)
; vTemp[2] = VARTYPEDEFAULT;
       move.b    #35,2(A2)
; if (strlen(s) == 2 && *(s + 1) < 0x30)
       move.l    D2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     find_var_6
       move.l    D2,A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bge.s     find_var_6
; vTemp[2] = *(s + 1);
       move.l    D2,A0
       move.b    1(A0),2(A2)
find_var_6:
; if (strlen(s) == 2 && isalphas(*(s + 1)))
       move.l    D2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     find_var_8
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq.s     find_var_8
; vTemp[1] = *(s + 1);
       move.l    D2,A0
       move.b    1(A0),1(A2)
       bra.s     find_var_9
find_var_8:
; else
; vTemp[1] = 0x00;
       clr.b     1(A2)
find_var_9:
       bra.s     find_var_5
find_var_4:
; }
; else
; {
; vTemp[0] = *s++;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A0),(A2)
; vTemp[1] = *s++;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A0),1(A2)
; vTemp[2] = *s;
       move.l    D2,A0
       move.b    (A0),2(A2)
find_var_5:
; }
; if (!findVariable(&vTemp))
       move.l    A2,-(A7)
       jsr       _findVariable
       addq.w    #4,A7
       tst.l     D0
       bne.s     find_var_10
; {
; *vErroProc = 4; // not a variable
       move.l    (A4),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra.s     find_var_3
find_var_10:
; }
; return vTemp;
       move.l    A2,D0
find_var_3:
       movem.l   (A7)+,D2/A2/A3/A4
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; void forPush(for_stack i)
; {
       xdef      _forPush
_forPush:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _ftos.L,A2
; if (*ftos>FOR_NEST)
       move.l    (A2),A0
       move.l    (A0),D0
       cmp.l     #80,D0
       ble.s     forPush_1
; {
; *vErroProc = 10;
       move.l    _vErroProc.L,A0
       move.w    #10,(A0)
; return;
       bra.s     forPush_3
forPush_1:
; }
; *(forStack + *ftos) = i;
       move.l    _forStack.L,D0
       move.l    (A2),A0
       move.l    (A0),D1
       muls      #20,D1
       add.l     D1,D0
       move.l    D0,A0
       lea       8(A6),A1
       moveq     #4,D0
       move.l    (A1)+,(A0)+
       dbra      D0,*-2
; *ftos = *ftos + 1;
       move.l    (A2),A0
       addq.l    #1,(A0)
forPush_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; for_stack forPop(void)
; {
       xdef      _forPop
_forPop:
       link      A6,#-20
       move.l    A2,-(A7)
       lea       _ftos.L,A2
; for_stack i;
; *ftos = *ftos - 1;
       move.l    (A2),A0
       subq.l    #1,(A0)
; if (*ftos<0)
       move.l    (A2),A0
       move.l    (A0),D0
       cmp.l     #0,D0
       bge.s     forPop_1
; {
; *vErroProc = 11;
       move.l    _vErroProc.L,A0
       move.w    #11,(A0)
; return(*forStack);
       move.l    _forStack.L,A0
       move.l    8(A6),A1
       moveq     #4,D0
       move.l    (A0)+,(A1)+
       dbra      D0,*-2
       move.l    8(A6),D0
       bra       forPop_3
forPop_1:
; }
; i=*(forStack + *ftos);
       lea       -20(A6),A0
       move.l    _forStack.L,D0
       move.l    (A2),A1
       move.l    (A1),D1
       muls      #20,D1
       add.l     D1,D0
       move.l    D0,A1
       moveq     #4,D0
       move.l    (A1)+,(A0)+
       dbra      D0,*-2
; return(i);
       lea       -20(A6),A0
       move.l    8(A6),A1
       moveq     #4,D0
       move.l    (A0)+,(A1)+
       dbra      D0,*-2
       move.l    8(A6),D0
forPop_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // GOSUB stack push function.
; //-----------------------------------------------------------------------------
; void gosubPush(unsigned long i)
; {
       xdef      _gosubPush
_gosubPush:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _gtos.L,A2
; if (*gtos>SUB_NEST)
       move.l    (A2),A0
       move.l    (A0),D0
       cmp.l     #190,D0
       ble.s     gosubPush_1
; {
; *vErroProc = 12;
       move.l    _vErroProc.L,A0
       move.w    #12,(A0)
; return;
       bra.s     gosubPush_3
gosubPush_1:
; }
; *(gosubStack + *gtos)=i;
       move.l    _gosubStack.L,A0
       move.l    (A2),A1
       move.l    (A1),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
; *gtos = *gtos + 1;
       move.l    (A2),A0
       addq.l    #1,(A0)
gosubPush_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // GOSUB stack pop function.
; //-----------------------------------------------------------------------------
; unsigned long gosubPop(void)
; {
       xdef      _gosubPop
_gosubPop:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _gtos.L,A2
; unsigned long i;
; *gtos = *gtos - 1;
       move.l    (A2),A0
       subq.l    #1,(A0)
; if (*gtos<0)
       move.l    (A2),A0
       move.l    (A0),D0
       cmp.l     #0,D0
       bge.s     gosubPop_1
; {
; *vErroProc = 13;
       move.l    _vErroProc.L,A0
       move.w    #13,(A0)
; return 0;
       clr.l     D0
       bra.s     gosubPop_3
gosubPop_1:
; }
; i=*(gosubStack + *gtos);
       move.l    _gosubStack.L,A0
       move.l    (A2),A1
       move.l    (A1),D0
       lsl.l     #2,D0
       move.l    0(A0,D0.L),-4(A6)
; return i;
       move.l    -4(A6),D0
gosubPop_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; //
; //-----------------------------------------------------------------------------
; unsigned int powNum(unsigned int pbase, unsigned char pexp)
; {
       xdef      _powNum
_powNum:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; unsigned int iz, vRes = pbase;
       move.l    8(A6),D3
; pexp--;
       subq.b    #1,15(A6)
; for(iz = 0; iz < pexp; iz++)
       clr.l     D2
powNum_1:
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     D0,D2
       bhs.s     powNum_3
; {
; vRes = vRes * pbase;
       move.l    D3,-(A7)
       move.l    8(A6),-(A7)
       jsr       ULMUL
       move.l    (A7),D3
       addq.w    #8,A7
       addq.l    #1,D2
       bra       powNum_1
powNum_3:
; }
; return vRes;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // FUNCOES PONTO FLUTUANTE
; //-----------------------------------------------------------------------------
; //-----------------------------------------------------------------------------
; // Convert from String to Float Single-Precision
; //-----------------------------------------------------------------------------
; unsigned long floatStringToFpp(unsigned char* pFloat)
; {
       xdef      _floatStringToFpp
_floatStringToFpp:
       link      A6,#-4
; unsigned long vFpp;
; *floatBufferStr = pFloat;
       move.l    _floatBufferStr.L,A0
       move.l    8(A6),(A0)
; STR_TO_FP();
       jsr       _STR_TO_FP
; vFpp = *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),-4(A6)
; return vFpp;
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Convert from Float Single-Precision to String
; //-----------------------------------------------------------------------------
; int fppTofloatString(unsigned long pFpp, unsigned char *buf)
; {
       xdef      _fppTofloatString
_fppTofloatString:
       link      A6,#0
; *floatBufferStr = buf;
       move.l    _floatBufferStr.L,A0
       move.l    12(A6),(A0)
; *floatNumD7 = pFpp;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FP_TO_STR();
       jsr       _FP_TO_STR
; return 0;
       clr.l     D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function to SUM D7+D6
; //-----------------------------------------------------------------------------
; unsigned long fppSum(unsigned long pFppD7, unsigned long pFppD6)
; {
       xdef      _fppSum
_fppSum:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; *floatNumD6 = pFppD6;
       move.l    _floatNumD6.L,A0
       move.l    12(A6),(A0)
; FPP_SUM();
       jsr       _FPP_SUM
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function to Subtraction D7-D6
; //-----------------------------------------------------------------------------
; unsigned long fppSub(unsigned long pFppD7, unsigned long pFppD6)
; {
       xdef      _fppSub
_fppSub:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; *floatNumD6 = pFppD6;
       move.l    _floatNumD6.L,A0
       move.l    12(A6),(A0)
; FPP_SUB();
       jsr       _FPP_SUB
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function to Mul D7*D6
; //-----------------------------------------------------------------------------
; unsigned long fppMul(unsigned long pFppD7, unsigned long pFppD6)
; {
       xdef      _fppMul
_fppMul:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; *floatNumD6 = pFppD6;
       move.l    _floatNumD6.L,A0
       move.l    12(A6),(A0)
; FPP_MUL();
       jsr       _FPP_MUL
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function to Division D7/D6
; //-----------------------------------------------------------------------------
; unsigned long fppDiv(unsigned long pFppD7, unsigned long pFppD6)
; {
       xdef      _fppDiv
_fppDiv:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; *floatNumD6 = pFppD6;
       move.l    _floatNumD6.L,A0
       move.l    12(A6),(A0)
; FPP_DIV();
       jsr       _FPP_DIV
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function to Power D7^D6
; //-----------------------------------------------------------------------------
; unsigned long fppPwr(unsigned long pFppD7, unsigned long pFppD6)
; {
       xdef      _fppPwr
_fppPwr:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; *floatNumD6 = pFppD6;
       move.l    _floatNumD6.L,A0
       move.l    12(A6),(A0)
; FPP_PWR();
       jsr       _FPP_PWR
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Convert Float to Int
; //-----------------------------------------------------------------------------
; long fppInt(unsigned long pFppD7)
; {
       xdef      _fppInt
_fppInt:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_INT();
       jsr       _FPP_INT
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Convert Int to Float
; //-----------------------------------------------------------------------------
; unsigned long fppReal(long pFppD7)
; {
       xdef      _fppReal
_fppReal:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_FPP();
       jsr       _FPP_FPP
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return SIN
; //-----------------------------------------------------------------------------
; unsigned long fppSin(long pFppD7)
; {
       xdef      _fppSin
_fppSin:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_SIN();
       jsr       _FPP_SIN
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return COS
; //-----------------------------------------------------------------------------
; unsigned long fppCos(long pFppD7)
; {
       xdef      _fppCos
_fppCos:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_COS();
       jsr       _FPP_COS
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return TAN
; //-----------------------------------------------------------------------------
; unsigned long fppTan(long pFppD7)
; {
       xdef      _fppTan
_fppTan:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_TAN();
       jsr       _FPP_TAN
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return SIN Hiperb
; //-----------------------------------------------------------------------------
; unsigned long fppSinH(long pFppD7)
; {
       xdef      _fppSinH
_fppSinH:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_SINH();
       jsr       _FPP_SINH
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return COS Hiperb
; //-----------------------------------------------------------------------------
; unsigned long fppCosH(long pFppD7)
; {
       xdef      _fppCosH
_fppCosH:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_COSH();
       jsr       _FPP_COSH
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return TAN Hiperb
; //-----------------------------------------------------------------------------
; unsigned long fppTanH(long pFppD7)
; {
       xdef      _fppTanH
_fppTanH:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_TANH();
       jsr       _FPP_TANH
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return Sqrt
; //-----------------------------------------------------------------------------
; unsigned long fppSqrt(long pFppD7)
; {
       xdef      _fppSqrt
_fppSqrt:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_SQRT();
       jsr       _FPP_SQRT
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return TAN Hiperb
; //-----------------------------------------------------------------------------
; unsigned long fppLn(long pFppD7)
; {
       xdef      _fppLn
_fppLn:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_LN();
       jsr       _FPP_LN
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return Exp
; //-----------------------------------------------------------------------------
; unsigned long fppExp(long pFppD7)
; {
       xdef      _fppExp
_fppExp:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_EXP();
       jsr       _FPP_EXP
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return ABS
; //-----------------------------------------------------------------------------
; unsigned long fppAbs(long pFppD7)
; {
       xdef      _fppAbs
_fppAbs:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_ABS();
       jsr       _FPP_ABS
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function Return Neg
; //-----------------------------------------------------------------------------
; unsigned long fppNeg(long pFppD7)
; {
       xdef      _fppNeg
_fppNeg:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; FPP_NEG();
       jsr       _FPP_NEG
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Float Function to Comp 2 float values D7-D6
; //-----------------------------------------------------------------------------
; unsigned long fppComp(unsigned long pFppD7, unsigned long pFppD6)
; {
       xdef      _fppComp
_fppComp:
       link      A6,#0
; *floatNumD7 = pFppD7;
       move.l    _floatNumD7.L,A0
       move.l    8(A6),(A0)
; *floatNumD6 = pFppD6;
       move.l    _floatNumD6.L,A0
       move.l    12(A6),(A0)
; FPP_CMP();
       jsr       _FPP_CMP
; return *floatNumD7;
       move.l    _floatNumD7.L,A0
       move.l    (A0),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // FUNCOES BASIC
; //-----------------------------------------------------------------------------
; //-----------------------------------------------------------------------------
; // Joga pra tela Texto.
; // Syntaxe:
; //      Print "<Texto>"/<value>[, "<Texto>"/<value>][; "<Texto>"/<value>]
; //-----------------------------------------------------------------------------
; int basPrint(void)
; {
       xdef      _basPrint
_basPrint:
       link      A6,#-516
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _token.L,A2
       lea       _tok.L,A3
       lea       _vErroProc.L,A4
       lea       -224(A6),A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -514(A6)
       clr.b     -513(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -244(A6)
       clr.l     -240(A6)
       clr.l     -236(A6)
       clr.l     -232(A6)
; unsigned char answer[200];
; long *lVal = answer;
       move.l    A5,-24(A6)
; int  *iVal = answer;
       move.l    A5,-20(A6)
; int len=0, spaces;
       clr.l     -16(A6)
; char last_delim, last_token_type = 0;
       clr.b     -11(A6)
; unsigned char sqtdtam[10];
; do {
basPrint_1:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basPrint_3
       clr.l     D0
       bra       basPrint_5
basPrint_3:
; if (*tok == EOL || *tok == FINISHED)
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basPrint_8
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       bne.s     basPrint_6
basPrint_8:
; break;
       bra       basPrint_2
basPrint_6:
; if (*token_type == QUOTE) { // is string
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basPrint_9
; printText(token);
       move.l    (A2),-(A7)
       jsr       _printText
       addq.w    #4,A7
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basPrint_11
       clr.l     D0
       bra       basPrint_5
basPrint_11:
       bra       basPrint_23
basPrint_9:
; }
; else if (*token!=':') { // is expression
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #58,D0
       beq       basPrint_23
; last_token_type = *token_type;
       move.l    _token_type.L,A0
       move.b    (A0),-11(A6)
; putback();
       jsr       _putback
; getExp(&answer);
       move.l    A5,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basPrint_15
       clr.l     D0
       bra       basPrint_5
basPrint_15:
; if (*value_type != '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq       basPrint_20
; {
; if (*value_type == '#')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basPrint_19
; {
; // Real
; fppTofloatString(*lVal, answer);
       move.l    A5,-(A7)
       move.l    -24(A6),A0
       move.l    (A0),-(A7)
       jsr       _fppTofloatString
       addq.w    #8,A7
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basPrint_21
       clr.l     D0
       bra       basPrint_5
basPrint_21:
       bra.s     basPrint_20
basPrint_19:
; }
; else
; {
; // Inteiro
; itoa(*iVal, answer, 10);
       pea       10
       move.l    A5,-(A7)
       move.l    -20(A6),A0
       move.l    (A0),-(A7)
       jsr       _itoa
       add.w     #12,A7
basPrint_20:
; }
; }
; printText(answer);
       move.l    A5,-(A7)
       jsr       _printText
       addq.w    #4,A7
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basPrint_23
       clr.l     D0
       bra       basPrint_5
basPrint_23:
; }
; last_delim = *token;
       move.l    (A2),A0
       move.b    (A0),D3
; if (*token==',') {
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       bne       basPrint_25
; // compute number of spaces to move to next tab
; spaces = 8 - (len % 8);
       moveq     #8,D0
       ext.w     D0
       ext.l     D0
       move.l    -16(A6),-(A7)
       pea       8
       jsr       LDIV
       move.l    4(A7),D1
       addq.w    #8,A7
       sub.l     D1,D0
       move.l    D0,D2
; while(spaces) {
basPrint_27:
       tst.l     D2
       beq.s     basPrint_29
; printChar(' ',1);
       pea       1
       pea       32
       jsr       _printChar
       addq.w    #8,A7
; spaces--;
       subq.l    #1,D2
       bra       basPrint_27
basPrint_29:
       bra       basPrint_35
basPrint_25:
; }
; }
; else if (*token==';' || *token=='+')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #59,D0
       beq.s     basPrint_32
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #43,D0
       bne.s     basPrint_30
basPrint_32:
       bra       basPrint_35
basPrint_30:
; /* do nothing */;
; else if (*token==':')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #58,D0
       bne.s     basPrint_33
; {
; *pointerRunProg = *pointerRunProg - 1;
       move.l    _pointerRunProg.L,A0
       subq.l    #1,(A0)
       bra       basPrint_35
basPrint_33:
; }
; else if (*tok!=EOL && *tok!=FINISHED && *token!=':')
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basPrint_35
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basPrint_35
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #58,D0
       beq.s     basPrint_35
; {
; *vErroProc = 14;
       move.l    (A4),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basPrint_5
basPrint_35:
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #59,D0
       beq       basPrint_1
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq       basPrint_1
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #43,D0
       beq       basPrint_1
basPrint_2:
; }
; } while (*token==';' || *token==',' || *token=='+');
; if (*tok == EOL || *tok == FINISHED || *token==':') {
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basPrint_39
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basPrint_39
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #58,D0
       bne.s     basPrint_40
basPrint_39:
; if (last_delim != ';' && last_delim!=',')
       cmp.b     #59,D3
       beq.s     basPrint_40
       cmp.b     #44,D3
       beq.s     basPrint_40
; printText("\r\n");
       pea       @basic_96.L
       jsr       _printText
       addq.w    #4,A7
basPrint_40:
; }
; return 0;
       clr.l     D0
basPrint_5:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Devolve o caracter ligado ao codigo ascii passado
; // Syntaxe:
; //      CHR$(<codigo ascii>)
; //-----------------------------------------------------------------------------
; int basChr(void)
; {
       xdef      _basChr
_basChr:
       link      A6,#-324
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       _token_type.L,A4
       lea       _token.L,A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -324(A6)
       clr.b     -323(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -54(A6)
       clr.l     -50(A6)
       clr.l     -46(A6)
       clr.l     -42(A6)
; unsigned char answer[10];
; long *lVal = answer;
       lea       -34(A6),A0
       move.l    A0,-24(A6)
; int  *iVal = answer;
       lea       -34(A6),A0
       move.l    A0,D2
; int len=0, spaces;
       clr.l     -20(A6)
; char last_delim, last_token_type = 0;
       clr.b     -11(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basChr_1
       clr.l     D0
       bra       basChr_3
basChr_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basChr_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basChr_6
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basChr_4
basChr_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basChr_3
basChr_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basChr_7
       clr.l     D0
       bra       basChr_3
basChr_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basChr_9
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basChr_3
basChr_9:
; }
; else { /* is expression */
; last_token_type = *token_type;
       move.l    (A4),A0
       move.b    (A0),-11(A6)
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -34(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basChr_11
       clr.l     D0
       bra       basChr_3
basChr_11:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basChr_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basChr_3
basChr_13:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basChr_15
; {
; *iVal = fppInt(*iVal);
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D2,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basChr_15:
; }
; // Inteiro
; if (*iVal<0 || *iVal>255)
       move.l    D2,A0
       move.l    (A0),D0
       cmp.l     #0,D0
       blt.s     basChr_19
       move.l    D2,A0
       move.l    (A0),D0
       cmp.l     #255,D0
       ble.s     basChr_17
basChr_19:
; {
; *vErroProc = 5;
       move.l    (A2),A0
       move.w    #5,(A0)
; return 0;
       clr.l     D0
       bra       basChr_3
basChr_17:
; }
; }
; last_delim = *token;
       move.l    (A5),A0
       move.b    (A0),-12(A6)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basChr_20
       clr.l     D0
       bra       basChr_3
basChr_20:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basChr_22
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra.s     basChr_3
basChr_22:
; }
; *token=(char)*iVal;
       move.l    D2,A0
       move.l    (A0),D0
       move.l    (A5),A0
       move.b    D0,(A0)
; *(token + 1)=0x00;
       move.l    (A5),A0
       clr.b     1(A0)
; *value_type='$';
       move.l    (A3),A0
       move.b    #36,(A0)
; return 0;
       clr.l     D0
basChr_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Devolve o numerico da string
; // Syntaxe:
; //      VAL(<string>)
; //-----------------------------------------------------------------------------
; int basVal(void)
; {
       xdef      _basVal
_basVal:
       link      A6,#-336
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       -44(A6),A4
       lea       _token_type.L,A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -334(A6)
       clr.b     -333(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -64(A6)
       clr.l     -60(A6)
       clr.l     -56(A6)
       clr.l     -52(A6)
; unsigned char answer[20];
; int  iVal = answer;
       move.l    A4,D2
; int vValue = 0;
       clr.l     -24(A6)
; int len=0, spaces;
       clr.l     -20(A6)
; char last_delim, last_value_type=' ', last_token_type = 0;
       moveq     #32,D3
       clr.b     -11(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basVal_1
       clr.l     D0
       bra       basVal_3
basVal_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basVal_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basVal_6
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basVal_4
basVal_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basVal_3
basVal_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basVal_7
       clr.l     D0
       bra       basVal_3
basVal_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne       basVal_9
; if (strchr(token,'.'))  // verifica se eh numero inteiro ou real
       pea       46
       move.l    (A3),-(A7)
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       beq.s     basVal_11
; {
; last_value_type='#'; // Real
       moveq     #35,D3
; iVal=floatStringToFpp(token);
       move.l    (A3),-(A7)
       jsr       _floatStringToFpp
       addq.w    #4,A7
       move.l    D0,D2
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basVal_13
       clr.l     D0
       bra       basVal_3
basVal_13:
       bra.s     basVal_12
basVal_11:
; }
; else
; {
; last_value_type='%'; // Inteiro
       moveq     #37,D3
; iVal=atoi(token);
       move.l    (A3),-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,D2
basVal_12:
       bra       basVal_20
basVal_9:
; }
; }
; else { /* is expression */
; last_token_type = *token_type;
       move.l    (A5),A0
       move.b    (A0),-11(A6)
; putback();
       jsr       _putback
; getExp(&answer);
       move.l    A4,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basVal_15
       clr.l     D0
       bra       basVal_3
basVal_15:
; if (*value_type != '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basVal_17
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basVal_3
basVal_17:
; }
; if (strchr(answer,'.'))  // verifica se eh numero inteiro ou real
       pea       46
       move.l    A4,-(A7)
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       beq.s     basVal_19
; {
; last_value_type='#'; // Real
       moveq     #35,D3
; iVal=floatStringToFpp(answer);
       move.l    A4,-(A7)
       jsr       _floatStringToFpp
       addq.w    #4,A7
       move.l    D0,D2
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basVal_21
       clr.l     D0
       bra       basVal_3
basVal_21:
       bra.s     basVal_20
basVal_19:
; }
; else
; {
; last_value_type='%'; // Inteiro
       moveq     #37,D3
; iVal=atoi(answer);
       move.l    A4,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,D2
basVal_20:
; }
; }
; last_delim = *token;
       move.l    (A3),A0
       move.b    (A0),-12(A6)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basVal_23
       clr.l     D0
       bra       basVal_3
basVal_23:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basVal_25
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basVal_3
basVal_25:
; }
; *token=((int)(iVal & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(iVal & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(iVal & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,2(A0)
; *(token + 3)=(iVal & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A3),A0
       move.b    D0,3(A0)
; *value_type = last_value_type;
       move.l    _value_type.L,A0
       move.b    D3,(A0)
; return 0;
       clr.l     D0
basVal_3:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Devolve a string do numero
; // Syntaxe:
; //      STR$(<Numero>)
; //-----------------------------------------------------------------------------
; int basStr(void)
; {
       xdef      _basStr
_basStr:
       link      A6,#-364
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token_type.L,A3
       lea       _token.L,A4
       lea       _value_type.L,A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -364(A6)
       clr.b     -363(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -94(A6)
       clr.l     -90(A6)
       clr.l     -86(A6)
       clr.l     -82(A6)
; unsigned char answer[50];
; long *lVal = answer;
       lea       -74(A6),A0
       move.l    A0,-24(A6)
; int  *iVal = answer;
       lea       -74(A6),A0
       move.l    A0,D2
; int len=0, spaces;
       clr.l     -20(A6)
; char last_delim, last_token_type = 0;
       clr.b     -11(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basStr_1
       clr.l     D0
       bra       basStr_3
basStr_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basStr_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basStr_6
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basStr_4
basStr_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basStr_3
basStr_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basStr_7
       clr.l     D0
       bra       basStr_3
basStr_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basStr_9
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basStr_3
basStr_9:
; }
; else { /* is expression */
; last_token_type = *token_type;
       move.l    (A3),A0
       move.b    (A0),-11(A6)
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -74(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basStr_11
       clr.l     D0
       bra       basStr_3
basStr_11:
; if (*value_type == '$')
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basStr_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basStr_3
basStr_13:
; }
; }
; last_delim = *token;
       move.l    (A4),A0
       move.b    (A0),-12(A6)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basStr_15
       clr.l     D0
       bra       basStr_3
basStr_15:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basStr_17
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basStr_3
basStr_17:
; }
; if (*value_type=='#')    // real
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basStr_19
; {
; fppTofloatString(*iVal,token);
       move.l    (A4),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppTofloatString
       addq.w    #8,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basStr_21
       clr.l     D0
       bra.s     basStr_3
basStr_21:
       bra.s     basStr_20
basStr_19:
; }
; else    // Inteiro
; {
; itoa(*iVal,token,10);
       pea       10
       move.l    (A4),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _itoa
       add.w     #12,A7
basStr_20:
; }
; *value_type='$';
       move.l    (A5),A0
       move.b    #36,(A0)
; return 0;
       clr.l     D0
basStr_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Devolve o tamanho da string
; // Syntaxe:
; //      LEN(<string>)
; //-----------------------------------------------------------------------------
; int basLen(void)
; {
       xdef      _basLen
_basLen:
       link      A6,#-516
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       _token_type.L,A4
       lea       _nextToken.L,A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -514(A6)
       clr.b     -513(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -244(A6)
       clr.l     -240(A6)
       clr.l     -236(A6)
       clr.l     -232(A6)
; unsigned char answer[200];
; int iVal = 0;
       clr.l     D2
; int vValue = 0;
       clr.l     -24(A6)
; int len=0, spaces;
       clr.l     -20(A6)
; char last_delim, last_token_type = 0;
       clr.b     -11(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLen_1
       clr.l     D0
       bra       basLen_3
basLen_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basLen_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basLen_6
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basLen_4
basLen_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basLen_3
basLen_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLen_7
       clr.l     D0
       bra       basLen_3
basLen_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basLen_9
; iVal=strlen(token);
       move.l    (A3),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D2
       bra       basLen_10
basLen_9:
; }
; else { /* is expression */
; last_token_type = *token_type;
       move.l    (A4),A0
       move.b    (A0),-11(A6)
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -224(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLen_11
       clr.l     D0
       bra       basLen_3
basLen_11:
; if (*value_type != '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basLen_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basLen_3
basLen_13:
; }
; iVal=strlen(answer);
       pea       -224(A6)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D2
basLen_10:
; }
; last_delim = *token;
       move.l    (A3),A0
       move.b    (A0),-12(A6)
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLen_15
       clr.l     D0
       bra       basLen_3
basLen_15:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basLen_17
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basLen_3
basLen_17:
; }
; *token=((int)(iVal & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(iVal & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(iVal & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,2(A0)
; *(token + 3)=(iVal & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A3),A0
       move.b    D0,3(A0)
; *value_type='%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basLen_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Devolve qtd memoria usuario disponivel
; // Syntaxe:
; //      FRE(0)
; //-----------------------------------------------------------------------------
; int basFre(void)
; {
       xdef      _basFre
_basFre:
       link      A6,#-404
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _printText.L,A2
       lea       _vErroProc.L,A3
       lea       -54(A6),A4
       lea       _ltoa.L,A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -402(A6)
       clr.b     -401(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -132(A6)
       clr.l     -128(A6)
       clr.l     -124(A6)
       clr.l     -120(A6)
; unsigned char answer[50];
; long *lVal = answer;
       lea       -112(A6),A0
       move.l    A0,-62(A6)
; int  *iVal = answer;
       lea       -112(A6),A0
       move.l    A0,-58(A6)
; long vTotal = 0;
       clr.l     D2
; char vbuffer [sizeof(long)*8+1];
; int len=0, spaces;
       clr.l     -20(A6)
; char last_delim;
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basFre_1
       clr.l     D0
       bra       basFre_3
basFre_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basFre_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basFre_6
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basFre_4
basFre_6:
; {
; *vErroProc = 15;
       move.l    (A3),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basFre_3
basFre_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basFre_7
       clr.l     D0
       bra       basFre_3
basFre_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basFre_9
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basFre_3
basFre_9:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -112(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basFre_11
       clr.l     D0
       bra       basFre_3
basFre_11:
; if (*iVal!=0)
       move.l    -58(A6),A0
       move.l    (A0),D0
       beq.s     basFre_13
; {
; *vErroProc = 5;
       move.l    (A3),A0
       move.w    #5,(A0)
; return 0;
       clr.l     D0
       bra       basFre_3
basFre_13:
; }
; }
; last_delim = *token;
       move.l    _token.L,A0
       move.b    (A0),-11(A6)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basFre_15
       clr.l     D0
       bra       basFre_3
basFre_15:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basFre_17
; {
; *vErroProc = 15;
       move.l    (A3),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basFre_3
basFre_17:
; }
; // Calcula Quantidade de Memoria e printa na tela
; printText("Memory Free for: \r\n\0");
       pea       @basic_140.L
       jsr       (A2)
       addq.w    #4,A7
; vTotal = (pStartArrayVar - pStartSimpVar) + (pStartStack - pStartString);
       move.l    _pStartArrayVar.L,D0
       sub.l     _pStartSimpVar.L,D0
       move.l    _pStartStack.L,D1
       sub.l     _pStartString.L,D1
       add.l     D1,D0
       move.l    D0,D2
; ltoa(vTotal, vbuffer, 10);
       pea       10
       move.l    A4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; printText("     Variables: \0");
       pea       @basic_141.L
       jsr       (A2)
       addq.w    #4,A7
; printText(vbuffer);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printText("Bytes\r\n\0");
       pea       @basic_142.L
       jsr       (A2)
       addq.w    #4,A7
; vTotal = pStartProg - pStartArrayVar;
       move.l    _pStartProg.L,D0
       sub.l     _pStartArrayVar.L,D0
       move.l    D0,D2
; ltoa(vTotal, vbuffer, 10);
       pea       10
       move.l    A4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; printText("        Arrays: \0");
       pea       @basic_143.L
       jsr       (A2)
       addq.w    #4,A7
; printText(vbuffer);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printText("Bytes\r\n\0");
       pea       @basic_142.L
       jsr       (A2)
       addq.w    #4,A7
; vTotal = pStartString - *nextAddrLine;
       move.l    _pStartString.L,D0
       move.l    _nextAddrLine.L,A0
       sub.l     (A0),D0
       move.l    D0,D2
; ltoa(vTotal, vbuffer, 10);
       pea       10
       move.l    A4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; printText("       Program: \0");
       pea       @basic_144.L
       jsr       (A2)
       addq.w    #4,A7
; printText(vbuffer);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printText("Bytes\r\n\0");
       pea       @basic_142.L
       jsr       (A2)
       addq.w    #4,A7
; return 0;
       clr.l     D0
basFre_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; int basTrig(unsigned char pFunc)
; {
       xdef      _basTrig
_basTrig:
       link      A6,#-4
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       _value_type.L,A4
       lea       _nextToken.L,A5
; unsigned long vReal = 0, vResult = 0;
       clr.l     -4(A6)
       clr.l     D2
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTrig_1
       clr.l     D0
       bra       basTrig_3
basTrig_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basTrig_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basTrig_6
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basTrig_4
basTrig_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basTrig_3
basTrig_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTrig_7
       clr.l     D0
       bra       basTrig_3
basTrig_7:
; putback();
       jsr       _putback
; getExp(&vReal); //
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basTrig_9
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basTrig_3
basTrig_9:
; }
; else if (*value_type != '#')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       beq.s     basTrig_11
; {
; *value_type='#'; // Real
       move.l    (A4),A0
       move.b    #35,(A0)
; vReal=fppReal(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D0,-4(A6)
basTrig_11:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTrig_13
       clr.l     D0
       bra       basTrig_3
basTrig_13:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basTrig_15
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basTrig_3
basTrig_15:
; }
; switch (pFunc)
       move.b    11(A6),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo       basTrig_17
       cmp.l     #6,D0
       bhs       basTrig_17
       asl.l     #1,D0
       move.w    basTrig_19(PC,D0.L),D0
       jmp       basTrig_19(PC,D0.W)
basTrig_19:
       dc.w      basTrig_20-basTrig_19
       dc.w      basTrig_21-basTrig_19
       dc.w      basTrig_22-basTrig_19
       dc.w      basTrig_23-basTrig_19
       dc.w      basTrig_24-basTrig_19
       dc.w      basTrig_25-basTrig_19
basTrig_20:
; {
; case 1: // sin
; vResult = fppSin(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppSin
       addq.w    #4,A7
       move.l    D0,D2
; break;
       bra       basTrig_18
basTrig_21:
; case 2: // cos
; vResult = fppCos(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppCos
       addq.w    #4,A7
       move.l    D0,D2
; break;
       bra       basTrig_18
basTrig_22:
; case 3: // tan
; vResult = fppTan(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppTan
       addq.w    #4,A7
       move.l    D0,D2
; break;
       bra       basTrig_18
basTrig_23:
; case 4: // log (ln)
; vResult = fppLn(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppLn
       addq.w    #4,A7
       move.l    D0,D2
; break;
       bra.s     basTrig_18
basTrig_24:
; case 5: // exp
; vResult = fppExp(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppExp
       addq.w    #4,A7
       move.l    D0,D2
; break;
       bra.s     basTrig_18
basTrig_25:
; case 6: // sqrt
; vResult = fppSqrt(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppSqrt
       addq.w    #4,A7
       move.l    D0,D2
; break;
       bra.s     basTrig_18
basTrig_17:
; default:
; *vErroProc = 14;
       move.l    (A2),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basTrig_3
basTrig_18:
; }
; *token=((int)(vResult & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(vResult & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(vResult & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,2(A0)
; *(token + 3)=(vResult & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A3),A0
       move.b    D0,3(A0)
; *value_type = '#';
       move.l    (A4),A0
       move.b    #35,(A0)
; return 0;
       clr.l     D0
basTrig_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; int basAsc(void)
; {
       xdef      _basAsc
_basAsc:
       link      A6,#-24
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       _token_type.L,A4
       lea       _nextToken.L,A5
; unsigned char answer[20];
; int  iVal = answer;
       lea       -22(A6),A0
       move.l    A0,D2
; char last_delim;
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAsc_1
       clr.l     D0
       bra       basAsc_3
basAsc_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basAsc_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basAsc_6
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basAsc_4
basAsc_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basAsc_3
basAsc_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAsc_7
       clr.l     D0
       bra       basAsc_3
basAsc_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basAsc_9
; if (strlen(token)>1)
       move.l    (A3),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #1,D0
       ble.s     basAsc_11
; {
; *vErroProc = 6;
       move.l    (A2),A0
       move.w    #6,(A0)
; return 0;
       clr.l     D0
       bra       basAsc_3
basAsc_11:
; }
; iVal = *token;
       move.l    (A3),A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    D0,D2
       bra       basAsc_10
basAsc_9:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -22(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAsc_13
       clr.l     D0
       bra       basAsc_3
basAsc_13:
; if (*value_type != '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basAsc_15
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basAsc_3
basAsc_15:
; }
; iVal = *answer;
       move.b    -22(A6),D0
       and.l     #255,D0
       move.l    D0,D2
basAsc_10:
; }
; last_delim = *token;
       move.l    (A3),A0
       move.b    (A0),-1(A6)
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAsc_17
       clr.l     D0
       bra       basAsc_3
basAsc_17:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basAsc_19
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basAsc_3
basAsc_19:
; }
; *token=((int)(iVal & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(iVal & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(iVal & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,2(A0)
; *(token + 3)=(iVal & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A3),A0
       move.b    D0,3(A0)
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basAsc_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; int basLeftRightMid(char pTipo)
; {
       xdef      _basLeftRightMid
_basLeftRightMid:
       link      A6,#-424
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       -218(A6),A3
       lea       _token.L,A4
       lea       _strlen.L,A5
       move.b    11(A6),D5
       ext.w     D5
       ext.l     D5
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     D2
       clr.l     D4
       clr.l     D6
       clr.l     D3
; unsigned char answer[200], vTemp[200];
; int vqtd = 0, vstart = 0;
       clr.l     -18(A6)
       clr.l     -14(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_1
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basLeftRightMid_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basLeftRightMid_6
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basLeftRightMid_4
basLeftRightMid_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_7
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basLeftRightMid_9
; strcpy(vTemp, token);
       move.l    (A4),-(A7)
       move.l    A3,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
       bra       basLeftRightMid_10
basLeftRightMid_9:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -418(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_11
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_11:
; if (*value_type != '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basLeftRightMid_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_13:
; }
; strcpy(vTemp, answer);
       pea       -418(A6)
       move.l    A3,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
basLeftRightMid_10:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_15
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_15:
; // Deve ser uma virgula para Receber a qtd, e se for mid = a posiao incial
; if (*token!=',')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq.s     basLeftRightMid_17
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_17:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_19
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_19:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basLeftRightMid_21
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_21:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; if (pTipo=='M')
       cmp.b     #77,D5
       bne.s     basLeftRightMid_23
; {
; getExp(&vstart);
       pea       -14(A6)
       jsr       _getExp
       addq.w    #4,A7
; vqtd=strlen(vTemp);
       move.l    A3,-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D0,-18(A6)
       bra.s     basLeftRightMid_24
basLeftRightMid_23:
; }
; else
; getExp(&vqtd);
       pea       -18(A6)
       jsr       _getExp
       addq.w    #4,A7
basLeftRightMid_24:
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_25
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_25:
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basLeftRightMid_27
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_27:
; }
; }
; if (pTipo == 'M')
       cmp.b     #77,D5
       bne       basLeftRightMid_39
; {
; // Deve ser uma virgula para Receber a qtd
; if (*token==',')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       bne       basLeftRightMid_39
; {
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_33
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_33:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basLeftRightMid_35
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_35:
; }
; else { /* is expression */
; //putback();
; getExp(&vqtd);
       pea       -18(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_37
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_37:
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basLeftRightMid_39
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_39:
; }
; }
; }
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basLeftRightMid_41
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_41:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basLeftRightMid_43
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basLeftRightMid_3
basLeftRightMid_43:
; }
; if (vqtd > strlen(vTemp))
       move.l    A3,-(A7)
       jsr       (A5)
       addq.w    #4,A7
       cmp.l     -18(A6),D0
       bge.s     basLeftRightMid_48
; {
; if (pTipo=='M')
       cmp.b     #77,D5
       bne.s     basLeftRightMid_47
; vqtd = (strlen(vTemp) - vstart) + 1;
       move.l    A3,-(A7)
       jsr       (A5)
       addq.w    #4,A7
       sub.l     -14(A6),D0
       addq.l    #1,D0
       move.l    D0,-18(A6)
       bra.s     basLeftRightMid_48
basLeftRightMid_47:
; else
; vqtd = strlen(vTemp);
       move.l    A3,-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D0,-18(A6)
basLeftRightMid_48:
; }
; if (pTipo == 'L') // Left$
       cmp.b     #76,D5
       bne.s     basLeftRightMid_49
; {
; for (ix = 0; ix < vqtd; ix++)
       clr.l     D2
basLeftRightMid_51:
       cmp.l     -18(A6),D2
       bge.s     basLeftRightMid_53
; *(token + ix) = vTemp[ix];
       move.l    (A4),A0
       move.b    0(A3,D2.L),0(A0,D2.L)
       addq.l    #1,D2
       bra       basLeftRightMid_51
basLeftRightMid_53:
; *(token + ix) = 0x00;
       move.l    (A4),A0
       clr.b     0(A0,D2.L)
       bra       basLeftRightMid_55
basLeftRightMid_49:
; }
; else if (pTipo == 'R') // Right$
       cmp.b     #82,D5
       bne       basLeftRightMid_54
; {
; iy = strlen(vTemp);
       move.l    A3,-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D0,D4
; iz = (iy - vqtd);
       move.l    D4,D0
       sub.l     -18(A6),D0
       move.l    D0,D6
; iw = 0;
       clr.l     D3
; for (ix = iz; ix < iy; ix++)
       move.l    D6,D2
basLeftRightMid_56:
       cmp.l     D4,D2
       bge.s     basLeftRightMid_58
; *(token + iw++) = vTemp[ix];
       move.l    (A4),A0
       move.l    D3,D0
       addq.l    #1,D3
       move.b    0(A3,D2.L),0(A0,D0.L)
       addq.l    #1,D2
       bra       basLeftRightMid_56
basLeftRightMid_58:
; *(token + iw)=0x00;
       move.l    (A4),A0
       clr.b     0(A0,D3.L)
       bra       basLeftRightMid_55
basLeftRightMid_54:
; }
; else  // Mid$
; {
; iy = strlen(vTemp);
       move.l    A3,-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D0,D4
; iw=0;
       clr.l     D3
; vstart--;
       subq.l    #1,-14(A6)
; for (ix = vstart; ix < iy; ix++)
       move.l    -14(A6),D2
basLeftRightMid_59:
       cmp.l     D4,D2
       bge.s     basLeftRightMid_61
; {
; if (iw <= iy && vqtd-- > 0)
       cmp.l     D4,D3
       bgt.s     basLeftRightMid_62
       move.l    -18(A6),D0
       subq.l    #1,-18(A6)
       cmp.l     #0,D0
       ble.s     basLeftRightMid_62
; *(token + iw++) = vTemp[ix];
       move.l    (A4),A0
       move.l    D3,D0
       addq.l    #1,D3
       move.b    0(A3,D2.L),0(A0,D0.L)
       bra.s     basLeftRightMid_63
basLeftRightMid_62:
; else
; break;
       bra.s     basLeftRightMid_61
basLeftRightMid_63:
       addq.l    #1,D2
       bra       basLeftRightMid_59
basLeftRightMid_61:
; }
; *(token + iw) = 0x00;
       move.l    (A4),A0
       clr.b     0(A0,D3.L)
basLeftRightMid_55:
; }
; *value_type = '$';
       move.l    _value_type.L,A0
       move.b    #36,(A0)
; return 0;
       clr.l     D0
basLeftRightMid_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //  Comandos de memoria
; //      Leitura de Memoria:   peek(<endereco>)
; //      Gravacao em endereco: poke(<endereco>,<byte>)
; //--------------------------------------------------------------------------------------
; int basPeekPoke(char pTipo)
; {
       xdef      _basPeekPoke
_basPeekPoke:
       link      A6,#-100
       movem.l   A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       _token_type.L,A4
       lea       _nextToken.L,A5
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -98(A6)
       clr.l     -94(A6)
       clr.l     -90(A6)
       clr.l     -86(A6)
; unsigned char answer[30], vTemp[30];
; unsigned char *vEnd = 0;
       clr.l     -18(A6)
; unsigned int vByte = 0;
       clr.l     -14(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPeekPoke_1
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basPeekPoke_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basPeekPoke_6
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basPeekPoke_4
basPeekPoke_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPeekPoke_7
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basPeekPoke_9
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_9:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&vEnd);
       pea       -18(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPeekPoke_11
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_11:
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basPeekPoke_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_13:
; }
; }
; // Deve ser uma virgula para Receber a qtd
; if (pTipo == 'W')
       move.b    11(A6),D0
       cmp.b     #87,D0
       bne       basPeekPoke_25
; {
; if (*token==',')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       bne       basPeekPoke_25
; {
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPeekPoke_19
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_19:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basPeekPoke_21
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_21:
; }
; else { /* is expression */
; //putback();
; getExp(&vByte);
       pea       -14(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPeekPoke_23
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_23:
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basPeekPoke_25
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_25:
; }
; }
; }
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPeekPoke_27
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_27:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basPeekPoke_29
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basPeekPoke_3
basPeekPoke_29:
; }
; if (pTipo == 'R')
       move.b    11(A6),D0
       cmp.b     #82,D0
       bne.s     basPeekPoke_31
; {
; *token = 0;
       move.l    (A3),A0
       clr.b     (A0)
; *(token + 1) = 0;
       move.l    (A3),A0
       clr.b     1(A0)
; *(token + 2) = 0;
       move.l    (A3),A0
       clr.b     2(A0)
; *(token + 3) = *vEnd;
       move.l    -18(A6),A0
       move.l    (A3),A1
       move.b    (A0),3(A1)
       bra.s     basPeekPoke_32
basPeekPoke_31:
; }
; else
; {
; *vEnd = (char)vByte;
       move.l    -14(A6),D0
       move.l    -18(A6),A0
       move.b    D0,(A0)
basPeekPoke_32:
; }
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basPeekPoke_3:
       movem.l   (A7)+,A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //  Array (min 2 dimensoes)
; //      Sintaxe:
; //              DIM (<dim 1>,<dim 2>[,<dim 3>,<dim 4>,...,<dim n>])
; //--------------------------------------------------------------------------------------
; int basDim(void)
; {
       xdef      _basDim
_basDim:
       link      A6,#-448
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _token.L,A2
       lea       _vErroProc.L,A3
       lea       _varName.L,A4
       lea       -356(A6),A5
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -446(A6)
       clr.l     -442(A6)
       clr.l     -438(A6)
       clr.l     -434(A6)
; unsigned char answer[30], vTemp[30];
; unsigned char sqtdtam[10];
; unsigned int vDim[88], ixDim = 0;
       clr.l     D2
; unsigned char varTipo;
; long vRetFV;
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basDim_1
       clr.l     D0
       bra       basDim_3
basDim_1:
; // Pega o nome da variavel
; if (!isalphas(*token)) {
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne.s     basDim_4
; *vErroProc = 4;
       move.l    (A3),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basDim_3
basDim_4:
; }
; if (strlen(token) < 3)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #3,D0
       bge       basDim_6
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    (A0),(A1)
; varTipo = VARTYPEDEFAULT;
       moveq     #35,D3
; if (strlen(token) == 2 && *(token + 1) < 0x30)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basDim_8
       move.l    (A2),A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bhs.s     basDim_8
; varTipo = *(token + 1);
       move.l    (A2),A0
       move.b    1(A0),D3
basDim_8:
; if (strlen(token) == 2 && isalphas(*(token + 1)))
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basDim_10
       move.l    (A2),A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq.s     basDim_10
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    1(A0),1(A1)
       bra.s     basDim_11
basDim_10:
; else
; *(varName + 1) = 0x00;
       move.l    (A4),A0
       clr.b     1(A0)
basDim_11:
; *(varName + 2) = varTipo;
       move.l    (A4),A0
       move.b    D3,2(A0)
       bra       basDim_7
basDim_6:
; }
; else
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    (A0),(A1)
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    1(A0),1(A1)
; *(varName + 2) = *(token + 2);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    2(A0),2(A1)
; iz = strlen(token) - 1;
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       subq.l    #1,D0
       move.l    D0,-438(A6)
; varTipo = *(varName + 2);
       move.l    (A4),A0
       move.b    2(A0),D3
basDim_7:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basDim_12
       clr.l     D0
       bra       basDim_3
basDim_12:
; // Erro, primeiro caracter depois da variavel, deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basDim_16
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basDim_16
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basDim_14
basDim_16:
; {
; *vErroProc = 15;
       move.l    (A3),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basDim_3
basDim_14:
; }
; do
; {
basDim_17:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basDim_19
       clr.l     D0
       bra       basDim_3
basDim_19:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basDim_21
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basDim_3
basDim_21:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&vDim[ixDim]);
       move.l    A5,D1
       move.l    D0,-(A7)
       move.l    D2,D0
       lsl.l     #2,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basDim_23
       clr.l     D0
       bra       basDim_3
basDim_23:
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basDim_25
; {
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basDim_3
basDim_25:
; }
; if (*value_type == '#')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basDim_27
; {
; vDim[ixDim] = fppInt(vDim[ixDim]);
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    0(A5,D1.L),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    D0,0(A5,D1.L)
; *value_type = '%';
       move.l    _value_type.L,A0
       move.b    #37,(A0)
basDim_27:
; }
; ixDim++;
       addq.l    #1,D2
; }
; if (*token == ',')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       bne.s     basDim_29
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
       bra.s     basDim_30
basDim_29:
; }
; else
; break;
       bra.s     basDim_18
basDim_30:
       bra       basDim_17
basDim_18:
; } while(1);
; // Deve ter pelo menos 1 elemento
; if (ixDim < 1)
       cmp.l     #1,D2
       bhs.s     basDim_31
; {
; *vErroProc = 21;
       move.l    (A3),A0
       move.w    #21,(A0)
; return 0;
       clr.l     D0
       bra       basDim_3
basDim_31:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basDim_33
       clr.l     D0
       bra       basDim_3
basDim_33:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basDim_35
; {
; *vErroProc = 15;
       move.l    (A3),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basDim_3
basDim_35:
; }
; // assign the value
; vRetFV = findVariable(varName);
       move.l    (A4),-(A7)
       jsr       _findVariable
       addq.w    #4,A7
       move.l    D0,-4(A6)
; // Se nao existe a variavel, cria variavel e atribui o valor
; if (!vRetFV)
       tst.l     -4(A6)
       bne.s     basDim_37
; createVariableArray(varName, varTipo, ixDim, vDim);
       move.l    A5,-(A7)
       move.l    D2,-(A7)
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       move.l    (A4),-(A7)
       jsr       _createVariableArray
       add.w     #16,A7
       bra.s     basDim_38
basDim_37:
; else
; {
; *vErroProc = 23;
       move.l    (A3),A0
       move.w    #23,(A0)
; return 0;
       clr.l     D0
       bra.s     basDim_3
basDim_38:
; }
; return 0;
       clr.l     D0
basDim_3:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; //--------------------------------------------------------------------------------------
; int basIf(void)
; {
       xdef      _basIf
_basIf:
       link      A6,#-4
       movem.l   D2/A2/A3,-(A7)
       lea       _pointerRunProg.L,A2
       lea       _vErroProc.L,A3
; unsigned int vCond = 0;
       clr.l     -4(A6)
; unsigned char *vTempPointer;
; getExp(&vCond); // get target value
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$' || *value_type == '#') {
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basIf_3
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basIf_1
basIf_3:
; *vErroProc = 16;
       move.l    (A3),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basIf_4
basIf_1:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A3),A0
       tst.w     (A0)
       beq.s     basIf_5
       clr.l     D0
       bra       basIf_4
basIf_5:
; if (*token!=0x83)
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #131,D0
       beq.s     basIf_7
; {
; *vErroProc = 8;
       move.l    (A3),A0
       move.w    #8,(A0)
; return 0;
       clr.l     D0
       bra       basIf_4
basIf_7:
; }
; if (vCond)
       tst.l     -4(A6)
       beq.s     basIf_9
; {
; // Vai pro proximo comando apos o Then e continua
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A2),A0
       addq.l    #1,(A0)
; // simula ":" para continuar a execucao
; *doisPontos = 1;
       move.l    _doisPontos.L,A0
       move.b    #1,(A0)
       bra.s     basIf_13
basIf_9:
; }
; else
; {
; // Ignora toda a linha
; vTempPointer = *pointerRunProg;
       move.l    (A2),A0
       move.l    (A0),D2
; while (*vTempPointer)
basIf_11:
       move.l    D2,A0
       tst.b     (A0)
       beq.s     basIf_13
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A2),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A2),A0
       move.l    (A0),D2
       bra       basIf_11
basIf_13:
; }
; }
; return 0;
       clr.l     D0
basIf_4:
       movem.l   (A7)+,D2/A2/A3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Atribuir valor a uma variavel - comando opcional.
; // Syntaxe:
; //            [LET] <variavel> = <string/valor>
; //--------------------------------------------------------------------------------------
; int basLet(void)
; {
       xdef      _basLet
_basLet:
       link      A6,#-220
       movem.l   D2/D3/D4/D5/A2/A3/A4/A5,-(A7)
       lea       _token.L,A2
       lea       _varName.L,A3
       lea       _vErroProc.L,A4
       lea       -214(A6),A5
; long vRetFV, iz;
; unsigned char varTipo;
; unsigned char value[200];
; unsigned long *lValue = &value;
       move.l    A5,D5
; unsigned char sqtdtam[10];
; unsigned char vArray = 0;
       clr.b     D4
; unsigned char *vTempPointer;
; /* get the variable name */
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basLet_1
       clr.l     D0
       bra       basLet_3
basLet_1:
; if (!isalphas(*token)) {
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne.s     basLet_4
; *vErroProc = 4;
       move.l    (A4),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basLet_3
basLet_4:
; }
; if (strlen(token) < 3)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #3,D0
       bge       basLet_6
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    (A0),(A1)
; varTipo = VARTYPEDEFAULT;
       moveq     #35,D2
; if (strlen(token) == 2 && *(token + 1) < 0x30)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basLet_8
       move.l    (A2),A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bhs.s     basLet_8
; varTipo = *(token + 1);
       move.l    (A2),A0
       move.b    1(A0),D2
basLet_8:
; if (strlen(token) == 2 && isalphas(*(token + 1)))
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basLet_10
       move.l    (A2),A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq.s     basLet_10
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    1(A0),1(A1)
       bra.s     basLet_11
basLet_10:
; else
; *(varName + 1) = 0x00;
       move.l    (A3),A0
       clr.b     1(A0)
basLet_11:
; *(varName + 2) = varTipo;
       move.l    (A3),A0
       move.b    D2,2(A0)
       bra       basLet_7
basLet_6:
; }
; else
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    (A0),(A1)
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    1(A0),1(A1)
; *(varName + 2) = *(token + 2);
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    2(A0),2(A1)
; iz = strlen(token) - 1;
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       subq.l    #1,D0
       move.l    D0,-218(A6)
; varTipo = *(varName + 2);
       move.l    (A3),A0
       move.b    2(A0),D2
basLet_7:
; }
; // verifica se é array (abre parenteses no inicio)
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),-4(A6)
; if (*vTempPointer == 0x28)
       move.l    -4(A6),A0
       move.b    (A0),D0
       cmp.b     #40,D0
       bne       basLet_12
; {
; vRetFV = findVariable(varName);
       move.l    (A3),-(A7)
       jsr       _findVariable
       addq.w    #4,A7
       move.l    D0,D3
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basLet_14
       clr.l     D0
       bra       basLet_3
basLet_14:
; if (!vRetFV)
       tst.l     D3
       bne.s     basLet_16
; {
; *vErroProc = 4;
       move.l    (A4),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basLet_3
basLet_16:
; }
; vArray = 1;
       moveq     #1,D4
basLet_12:
; }
; // get the equals sign
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A4),A0
       tst.w     (A0)
       beq.s     basLet_18
       clr.l     D0
       bra       basLet_3
basLet_18:
; if (*token!='=') {
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #61,D0
       beq.s     basLet_20
; *vErroProc = 3;
       move.l    (A4),A0
       move.w    #3,(A0)
; return 0;
       clr.l     D0
       bra       basLet_3
basLet_20:
; }
; /* get the value to assign to varName */
; getExp(&value);
       move.l    A5,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (varTipo == '#' && *value_type != '#')
       cmp.b     #35,D2
       bne.s     basLet_22
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       beq.s     basLet_22
; *lValue = fppReal(*lValue);
       move.l    D5,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D5,A0
       move.l    D0,(A0)
basLet_22:
; // assign the value
; if (!vArray)
       tst.b     D4
       bne       basLet_24
; {
; vRetFV = findVariable(varName);
       move.l    (A3),-(A7)
       jsr       _findVariable
       addq.w    #4,A7
       move.l    D0,D3
; // Se nao existe a variavel, cria variavel e atribui o valor
; if (!vRetFV)
       tst.l     D3
       bne.s     basLet_26
; createVariable(varName, value, varTipo);
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       move.l    A5,-(A7)
       move.l    (A3),-(A7)
       jsr       _createVariable
       add.w     #12,A7
       bra.s     basLet_27
basLet_26:
; else // se ja existe, altera
; updateVariable((vRetFV + 3), value, varTipo, 1);
       pea       1
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       move.l    A5,-(A7)
       move.l    D3,D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _updateVariable
       add.w     #16,A7
basLet_27:
       bra.s     basLet_25
basLet_24:
; }
; else
; {
; updateVariable(vRetFV, value, varTipo, 1);
       pea       1
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       move.l    A5,-(A7)
       move.l    D3,-(A7)
       jsr       _updateVariable
       add.w     #16,A7
basLet_25:
; }
; return 0;
       clr.l     D0
basLet_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Entrada pelo teclado de numeros/caracteres ateh teclar ENTER (INPUT)
; // Entrada pelo teclado de um unico caracter ou numero (GET)
; // Entrada dos dados de acordo com o tipo de variavel $(qquer), %(Nums), #(Nums & '.')
; // Syntaxe:
; //          INPUT ["texto",]<variavel> : A variavel sera criada se nao existir
; //          GET <variavel> : A variavel sera criada se nao existir
; //--------------------------------------------------------------------------------------
; int basInputGet(unsigned char pSize)
; {
       xdef      _basInputGet
_basInputGet:
       link      A6,#-504
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _token.L,A2
       lea       -218(A6),A3
       lea       _varName.L,A4
       lea       _vErroProc.L,A5
; unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
       clr.b     -504(A6)
       clr.b     -503(A6)
; char sNumLin [sizeof(short)*8+1];
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     D6
       clr.l     -234(A6)
       clr.l     -230(A6)
       clr.l     -226(A6)
; unsigned char answer[200], vtec;
; long *lVal = answer;
       move.l    A3,-18(A6)
; int  *iVal = answer;
       move.l    A3,D5
; char vTemTexto = 0;
       clr.b     D4
; int len=0, spaces;
       clr.l     -14(A6)
; char last_delim;
; unsigned char *buffptr = vbuf;
       move.l    _vbuf.L,-4(A6)
; long vRetFV;
; unsigned char varTipo;
; do {
basInputGet_1:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     basInputGet_3
       clr.l     D0
       bra       basInputGet_5
basInputGet_3:
; if (*tok == EOL || *tok == FINISHED)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basInputGet_8
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       bne.s     basInputGet_6
basInputGet_8:
; break;
       bra       basInputGet_2
basInputGet_6:
; if (*token_type == QUOTE) { /* is string */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne       basInputGet_9
; if (vTemTexto)
       tst.b     D4
       beq.s     basInputGet_11
; {
; *vErroProc = 14;
       move.l    (A5),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basInputGet_5
basInputGet_11:
; }
; printText(token);
       move.l    (A2),-(A7)
       jsr       _printText
       addq.w    #4,A7
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     basInputGet_13
       clr.l     D0
       bra       basInputGet_5
basInputGet_13:
; vTemTexto = 1;
       moveq     #1,D4
       bra       basInputGet_50
basInputGet_9:
; }
; else { /* is expression */
; // Verifica se comeca com letra, pois tem que ser uma variavel agora
; if (!isalphas(*token))
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne.s     basInputGet_15
; {
; *vErroProc = 4;
       move.l    (A5),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basInputGet_5
basInputGet_15:
; }
; if (strlen(token) < 3)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #3,D0
       bge       basInputGet_17
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    (A0),(A1)
; varTipo = VARTYPEDEFAULT;
       moveq     #35,D2
; if (strlen(token) == 2 && *(token + 1) < 0x30)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basInputGet_19
       move.l    (A2),A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bhs.s     basInputGet_19
; varTipo = *(token + 1);
       move.l    (A2),A0
       move.b    1(A0),D2
basInputGet_19:
; if (strlen(token) == 2 && isalphas(*(token + 1)))
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basInputGet_21
       move.l    (A2),A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq.s     basInputGet_21
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    1(A0),1(A1)
       bra.s     basInputGet_22
basInputGet_21:
; else
; *(varName + 1) = 0x00;
       move.l    (A4),A0
       clr.b     1(A0)
basInputGet_22:
; *(varName + 2) = varTipo;
       move.l    (A4),A0
       move.b    D2,2(A0)
       bra       basInputGet_18
basInputGet_17:
; }
; else
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    (A0),(A1)
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    1(A0),1(A1)
; *(varName + 2) = *(token + 2);
       move.l    (A2),A0
       move.l    (A4),A1
       move.b    2(A0),2(A1)
; iz = strlen(token) - 1;
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       subq.l    #1,D0
       move.l    D0,-230(A6)
; varTipo = *(varName + 2);
       move.l    (A4),A0
       move.b    2(A0),D2
basInputGet_18:
; }
; if (pSize == 1)
       move.b    11(A6),D0
       cmp.b     #1,D0
       bne       basInputGet_23
; {
; // GET
; for (ix = 0; ix < 15000; ix++)
       clr.l     D6
basInputGet_25:
       cmp.l     #15000,D6
       bge.s     basInputGet_27
; {
; vtec = *vBufReceived;
       move.l    _vBufReceived.L,A0
       move.b    (A0),D3
; if (vtec)
       tst.b     D3
       beq.s     basInputGet_28
; break;
       bra.s     basInputGet_27
basInputGet_28:
       addq.l    #1,D6
       bra       basInputGet_25
basInputGet_27:
; }
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; //                vtec = inputLine(1,'@');    // Qualquer coisa
; if (varTipo != '$' && vtec)
       cmp.b     #36,D2
       beq.s     basInputGet_32
       and.l     #255,D3
       beq.s     basInputGet_32
; {
; if (!isdigitus(vtec))
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       _isdigitus
       addq.w    #4,A7
       tst.l     D0
       bne.s     basInputGet_32
; vtec = 0;
       clr.b     D3
basInputGet_32:
; }
; answer[0] = vtec;
       move.b    D3,(A3)
; answer[1] = 0x00;
       clr.b     1(A3)
       bra       basInputGet_24
basInputGet_23:
; }
; else
; {
; // INPUT
; vtec = inputLine(255,varTipo);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       255
       jsr       _inputLine
       addq.w    #8,A7
       move.b    D0,D3
; if (*vbuf != 0x00 && (vtec == 0x0D || vtec == 0x0A))
       move.l    _vbuf.L,A0
       move.b    (A0),D0
       beq       basInputGet_34
       cmp.b     #13,D3
       beq.s     basInputGet_36
       cmp.b     #10,D3
       bne.s     basInputGet_34
basInputGet_36:
; {
; ix = 0;
       clr.l     D6
; while (*buffptr)
basInputGet_37:
       move.l    -4(A6),A0
       tst.b     (A0)
       beq.s     basInputGet_39
; {
; answer[ix++] = *buffptr++;
       move.l    -4(A6),A0
       addq.l    #1,-4(A6)
       move.l    D6,D0
       addq.l    #1,D6
       move.b    (A0),0(A3,D0.L)
; answer[ix] = 0x00;
       clr.b     0(A3,D6.L)
       bra       basInputGet_37
basInputGet_39:
       bra.s     basInputGet_35
basInputGet_34:
; }
; }
; else
; answer[0] = 0x00;
       clr.b     (A3)
basInputGet_35:
; printText("\r\n");
       pea       @basic_96.L
       jsr       _printText
       addq.w    #4,A7
basInputGet_24:
; }
; if (varTipo!='$')
       cmp.b     #36,D2
       beq       basInputGet_40
; {
; if (varTipo=='#')  // verifica se eh numero inteiro ou real
       cmp.b     #35,D2
       bne.s     basInputGet_42
; {
; iVal=floatStringToFpp(answer);
       move.l    A3,-(A7)
       jsr       _floatStringToFpp
       addq.w    #4,A7
       move.l    D0,D5
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     basInputGet_44
       clr.l     D0
       bra       basInputGet_5
basInputGet_44:
       bra.s     basInputGet_43
basInputGet_42:
; }
; else
; {
; iVal=atoi(answer);
       move.l    A3,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,D5
basInputGet_43:
; }
; answer[0]=((int)(iVal & 0xFF000000) >> 24);
       move.l    D5,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.b    D0,(A3)
; answer[1]=((int)(iVal & 0x00FF0000) >> 16);
       move.l    D5,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.b    D0,1(A3)
; answer[2]=((int)(iVal & 0x0000FF00) >> 8);
       move.l    D5,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.b    D0,2(A3)
; answer[3]=(char)(iVal & 0x000000FF);
       move.l    D5,D0
       and.l     #255,D0
       move.b    D0,3(A3)
basInputGet_40:
; }
; if (*pointerRunProg != 0x28)  // se eh array, tem parenteses
       move.l    _pointerRunProg.L,A0
       move.l    (A0),D0
       cmp.l     #40,D0
       beq       basInputGet_46
; {
; // assign the value
; vRetFV = findVariable(varName);
       move.l    (A4),-(A7)
       jsr       _findVariable
       addq.w    #4,A7
       move.l    D0,D7
; // Se nao existe variavel e inicio sentenca, cria variavel e atribui o valor
; if (!vRetFV)
       tst.l     D7
       bne.s     basInputGet_48
; createVariable(varName, answer, varTipo);
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       move.l    A3,-(A7)
       move.l    (A4),-(A7)
       jsr       _createVariable
       add.w     #12,A7
       bra.s     basInputGet_49
basInputGet_48:
; else // se ja existe, altera
; updateVariable((vRetFV + 3), answer, varTipo, 1);
       pea       1
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       move.l    A3,-(A7)
       move.l    D7,D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _updateVariable
       add.w     #16,A7
basInputGet_49:
       bra.s     basInputGet_47
basInputGet_46:
; }
; else
; {
; updateVariable(vRetFV, answer, varTipo, 1);
       pea       1
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       move.l    A3,-(A7)
       move.l    D7,-(A7)
       jsr       _updateVariable
       add.w     #16,A7
basInputGet_47:
; }
; vTemTexto=2;
       moveq     #2,D4
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A5),A0
       tst.w     (A0)
       beq.s     basInputGet_50
       clr.l     D0
       bra       basInputGet_5
basInputGet_50:
; }
; last_delim = *token;
       move.l    (A2),A0
       move.b    (A0),-5(A6)
; if (vTemTexto==1 && *token==';')
       cmp.b     #1,D4
       bne.s     basInputGet_52
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #59,D0
       bne.s     basInputGet_52
       bra       basInputGet_58
basInputGet_52:
; /* do nothing */;
; else if (vTemTexto==1 && *token!=';')
       cmp.b     #1,D4
       bne.s     basInputGet_54
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #59,D0
       beq.s     basInputGet_54
; {
; *vErroProc = 14;
       move.l    (A5),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basInputGet_5
basInputGet_54:
; }
; else if (vTemTexto!=1 && *token==';')
       cmp.b     #1,D4
       beq.s     basInputGet_56
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #59,D0
       bne.s     basInputGet_56
; {
; *vErroProc = 14;
       move.l    (A5),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basInputGet_5
basInputGet_56:
; }
; else if (*tok!=EOL && *tok!=FINISHED && *token!=':')
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basInputGet_58
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basInputGet_58
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #58,D0
       beq.s     basInputGet_58
; {
; *vErroProc = 14;
       move.l    (A5),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra.s     basInputGet_5
basInputGet_58:
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #59,D0
       beq       basInputGet_1
basInputGet_2:
; }
; } while (*token==';');
; return 0;
       clr.l     D0
basInputGet_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; char forFind(for_stack *i, unsigned char* endLastVar)
; {
       xdef      _forFind
_forFind:
       link      A6,#-12
       movem.l   D2/D3,-(A7)
; int ix;
; unsigned char sqtdtam[10];
; for_stack *j;
; j = forStack;
       move.l    _forStack.L,D3
; for(ix = 0; ix < *ftos; ix++)
       clr.l     D2
forFind_1:
       move.l    _ftos.L,A0
       cmp.l     (A0),D2
       bge       forFind_3
; {
; if (j[ix].nameVar[0] == endLastVar[1] && j[ix].nameVar[1] == endLastVar[2])
       move.l    D3,A0
       move.l    D2,D0
       muls      #20,D0
       move.l    12(A6),A1
       move.b    0(A0,D0.L),D1
       cmp.b     1(A1),D1
       bne       forFind_4
       move.l    D3,A0
       move.l    D2,D0
       muls      #20,D0
       add.l     D0,A0
       move.l    12(A6),A1
       move.b    1(A0),D0
       cmp.b     2(A1),D0
       bne.s     forFind_4
; {
; *i = j[ix];
       move.l    8(A6),A0
       move.l    D3,D0
       move.l    D2,D1
       muls      #20,D1
       add.l     D1,D0
       move.l    D0,A1
       moveq     #4,D0
       move.l    (A1)+,(A0)+
       dbra      D0,*-2
; return ix;
       move.b    D2,D0
       bra.s     forFind_6
forFind_4:
; }
; else if (!j[ix].nameVar[0])
       move.l    D3,A0
       move.l    D2,D0
       muls      #20,D0
       tst.b     0(A0,D0.L)
       bne.s     forFind_7
; return -1;
       moveq     #-1,D0
       bra.s     forFind_6
forFind_7:
       addq.l    #1,D2
       bra       forFind_1
forFind_3:
; }
; return -1;
       moveq     #-1,D0
forFind_6:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Inicio do laco de repeticao
; // Syntaxe:
; //          FOR <variavel> = <inicio> TO <final> [STEP <passo>] : A variavel sera criada se nao existir
; //--------------------------------------------------------------------------------------
; int basFor(void)
; {
       xdef      _basFor
_basFor:
       link      A6,#-48
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -46(A6),A2
       lea       _pointerRunProg.L,A3
       lea       _logicalNumericFloatLong.L,A4
       lea       _fppReal.L,A5
; for_stack i, *j;
; int value=0;
       clr.l     -26(A6)
; long *endVarCont;
; long iStep = 1;
       move.l    #1,-22(A6)
; long iTarget = 0;
       clr.l     -18(A6)
; unsigned char* endLastVar;
; unsigned char sqtdtam[10];
; char vRetVar = -1;
       moveq     #-1,D6
; unsigned char *vTempPointer;
; char vResLog1 = 0, vResLog2 = 0;
       clr.b     -3(A6)
       clr.b     -2(A6)
; char vResLog3 = 0, vResLog4 = 0;
       clr.b     -1(A6)
       moveq     #0,D7
; basLet();
       jsr       _basLet
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basFor_1
       clr.l     D0
       bra       basFor_3
basFor_1:
; endLastVar = *atuVarAddr - 3;
       move.l    _atuVarAddr.L,A0
       move.l    (A0),D0
       subq.l    #3,D0
       move.l    D0,D5
; endVarCont = *atuVarAddr + 1;
       move.l    _atuVarAddr.L,A0
       move.l    (A0),D0
       addq.l    #1,D0
       move.l    D0,D3
; vRetVar = forFind(&i, endLastVar);
       move.l    D5,-(A7)
       move.l    A2,-(A7)
       jsr       _forFind
       addq.w    #8,A7
       move.b    D0,D6
; if (vRetVar < 0)
       cmp.b     #0,D6
       bge.s     basFor_4
; {
; i.nameVar[0]=endLastVar[1];
       move.l    D5,A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    1(A0),(A1)
; i.nameVar[1]=endLastVar[2];
       move.l    D5,A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    2(A0),1(A1)
; i.nameVar[2]=endLastVar[0];
       move.l    D5,A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    (A0),2(A1)
basFor_4:
; }
; if (i.nameVar[2] == '#')
       move.l    A2,D0
       move.l    D0,A0
       move.b    2(A0),D0
       cmp.b     #35,D0
       bne.s     basFor_6
; i.step = fppReal(iStep);
       move.l    -22(A6),-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    A2,D1
       move.l    D1,A0
       move.l    D0,12(A0)
       bra.s     basFor_7
basFor_6:
; else
; i.step = iStep;
       move.l    A2,D0
       move.l    D0,A0
       move.l    -22(A6),12(A0)
basFor_7:
; i.endVar = endVarCont;
       move.l    A2,D0
       move.l    D0,A0
       move.l    D3,4(A0)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basFor_8
       clr.l     D0
       bra       basFor_3
basFor_8:
; if (*tok!=0x86) /* read and discard the TO */
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #134,D0
       beq.s     basFor_10
; {
; *vErroProc = 9;
       move.l    _vErroProc.L,A0
       move.w    #9,(A0)
; return 0;
       clr.l     D0
       bra       basFor_3
basFor_10:
; }
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; getExp(&iTarget); /* get target value */
       pea       -18(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (i.nameVar[2] == '#' && *value_type == '%')
       move.l    A2,D0
       move.l    D0,A0
       move.b    2(A0),D0
       cmp.b     #35,D0
       bne.s     basFor_12
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #37,D0
       bne.s     basFor_12
; i.target = fppReal(iTarget);
       move.l    -18(A6),-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    A2,D1
       move.l    D1,A0
       move.l    D0,8(A0)
       bra.s     basFor_13
basFor_12:
; else
; i.target = iTarget;
       move.l    A2,D0
       move.l    D0,A0
       move.l    -18(A6),8(A0)
basFor_13:
; if (*tok==0x88) /* read STEP */
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #136,D0
       bne       basFor_17
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; getExp(&iStep); /* get target value */
       pea       -22(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (i.nameVar[2] == '#' && *value_type == '%')
       move.l    A2,D0
       move.l    D0,A0
       move.b    2(A0),D0
       cmp.b     #35,D0
       bne.s     basFor_16
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #37,D0
       bne.s     basFor_16
; i.step = fppReal(iStep);
       move.l    -22(A6),-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    A2,D1
       move.l    D1,A0
       move.l    D0,12(A0)
       bra.s     basFor_17
basFor_16:
; else
; i.step = iStep;
       move.l    A2,D0
       move.l    D0,A0
       move.l    -22(A6),12(A0)
basFor_17:
; }
; endVarCont=i.endVar;
       move.l    A2,D0
       move.l    D0,A0
       move.l    4(A0),D3
; // if loop can execute at least once, push info on stack     //    if ((i.step > 0 && *endVarCont <= i.target) || (i.step < 0 && *endVarCont >= i.target))
; if (i.nameVar[2] == '#')
       move.l    A2,D0
       move.l    D0,A0
       move.b    2(A0),D0
       cmp.b     #35,D0
       bne       basFor_18
; {
; vResLog1 = logicalNumericFloatLong(0xF6 /* <= */, *endVarCont, i.target);
       move.l    A2,D1
       move.l    D1,A0
       move.l    8(A0),-(A7)
       move.l    D3,A0
       move.l    (A0),-(A7)
       pea       246
       jsr       (A4)
       add.w     #12,A7
       move.b    D0,-3(A6)
; vResLog2 = logicalNumericFloatLong(0xF5 /* >= */, *endVarCont, i.target);
       move.l    A2,D1
       move.l    D1,A0
       move.l    8(A0),-(A7)
       move.l    D3,A0
       move.l    (A0),-(A7)
       pea       245
       jsr       (A4)
       add.w     #12,A7
       move.b    D0,-2(A6)
; vResLog3 = logicalNumericFloatLong('>', i.step, 0);
       clr.l     -(A7)
       move.l    A2,D1
       move.l    D1,A0
       move.l    12(A0),-(A7)
       pea       62
       jsr       (A4)
       add.w     #12,A7
       move.b    D0,-1(A6)
; vResLog4 = logicalNumericFloatLong('<', i.step, 0);
       clr.l     -(A7)
       move.l    A2,D1
       move.l    D1,A0
       move.l    12(A0),-(A7)
       pea       60
       jsr       (A4)
       add.w     #12,A7
       move.b    D0,D7
       bra       basFor_19
basFor_18:
; }
; else
; {
; vResLog1 = (*endVarCont <= i.target);
       move.l    D3,A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    (A0),D0
       cmp.l     8(A1),D0
       bgt.s     basFor_20
       moveq     #1,D0
       bra.s     basFor_21
basFor_20:
       clr.l     D0
basFor_21:
       move.b    D0,-3(A6)
; vResLog2 = (*endVarCont >= i.target);
       move.l    D3,A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    (A0),D0
       cmp.l     8(A1),D0
       blt.s     basFor_22
       moveq     #1,D0
       bra.s     basFor_23
basFor_22:
       clr.l     D0
basFor_23:
       move.b    D0,-2(A6)
; vResLog3 = (i.step > 0);
       move.l    A2,D0
       move.l    D0,A0
       move.l    12(A0),D0
       cmp.l     #0,D0
       ble.s     basFor_24
       moveq     #1,D0
       bra.s     basFor_25
basFor_24:
       clr.l     D0
basFor_25:
       move.b    D0,-1(A6)
; vResLog4 = (i.step < 0);
       move.l    A2,D0
       move.l    D0,A0
       move.l    12(A0),D0
       cmp.l     #0,D0
       bge.s     basFor_26
       moveq     #1,D0
       bra.s     basFor_27
basFor_26:
       clr.l     D0
basFor_27:
       move.b    D0,D7
basFor_19:
; }
; if (vResLog3 && vResLog1 || (vResLog4 && vResLog2))
       tst.b     -1(A6)
       beq.s     basFor_31
       tst.b     -3(A6)
       bne.s     basFor_30
basFor_31:
       tst.b     D7
       beq       basFor_28
       tst.b     -2(A6)
       beq       basFor_28
basFor_30:
; {
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
; if (*vTempPointer==0x3A) // ":"
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #58,D0
       bne.s     basFor_32
; {
; i.progPosPointerRet = *pointerRunProg;
       move.l    (A3),A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    (A0),16(A1)
       bra.s     basFor_33
basFor_32:
; }
; else
; i.progPosPointerRet = *nextAddr;
       move.l    _nextAddr.L,A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    (A0),16(A1)
basFor_33:
; if (vRetVar < 0)
       cmp.b     #0,D6
       bge.s     basFor_34
; forPush(i);
       move.l    A2,D1
       move.l    D1,A0
       add.w     #20,A0
       moveq     #4,D1
       move.l    -(A0),-(A7)
       dbra      D1,*-2
       jsr       _forPush
       add.w     #20,A7
       bra       basFor_35
basFor_34:
; else
; {
; j = (forStack + vRetVar);
       move.l    _forStack.L,D0
       ext.w     D6
       ext.l     D6
       move.l    D6,D1
       muls      #20,D1
       ext.w     D1
       ext.l     D1
       add.l     D1,D0
       move.l    D0,D4
; j->target = i.target;
       move.l    A2,D0
       move.l    D0,A0
       move.l    D4,A1
       move.l    8(A0),8(A1)
; j->step = i.step;
       move.l    A2,D0
       move.l    D0,A0
       move.l    D4,A1
       move.l    12(A0),12(A1)
; j->endVar = i.endVar;
       move.l    A2,D0
       move.l    D0,A0
       move.l    D4,A1
       move.l    4(A0),4(A1)
; j->progPosPointerRet = i.progPosPointerRet;
       move.l    A2,D0
       move.l    D0,A0
       move.l    D4,A1
       move.l    16(A0),16(A1)
basFor_35:
       bra       basFor_38
basFor_28:
; }
; }
; else  /* otherwise, skip loop code alltogether */
; {
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
; while(*vTempPointer != 0x87) // Search NEXT
basFor_36:
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #135,D0
       beq       basFor_38
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
; // Verifica se chegou no next
; if (*vTempPointer == 0x87)
       move.l    D2,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #135,D0
       bne       basFor_45
; {
; // Verifica se tem letra, se nao tiver, usa ele
; if (*(vTempPointer + 1)!=0x00)
       move.l    D2,A0
       move.b    1(A0),D0
       beq       basFor_45
; {
; // verifica se é a mesma variavel que ele tem
; if (*(vTempPointer + 1) != i.nameVar[0])
       move.l    D2,A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    1(A0),D0
       cmp.b     (A1),D0
       beq.s     basFor_43
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
       bra       basFor_45
basFor_43:
; }
; else
; {
; if (*(vTempPointer + 2) != i.nameVar[1] && *(vTempPointer + 2) != i.nameVar[2])
       move.l    D2,A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    2(A0),D0
       cmp.b     1(A1),D0
       beq.s     basFor_45
       move.l    D2,A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    2(A0),D0
       cmp.b     2(A1),D0
       beq.s     basFor_45
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A3),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A3),A0
       move.l    (A0),D2
basFor_45:
       bra       basFor_36
basFor_38:
; }
; }
; }
; }
; }
; }
; return 0;
       clr.l     D0
basFor_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Final/Incremento do Laco de repeticao, voltando para o commando/linha após o FOR
; // Syntaxe:
; //          NEXT [<variavel>]
; //--------------------------------------------------------------------------------------
; int basNext(void)
; {
       xdef      _basNext
_basNext:
       link      A6,#-40
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -28(A6),A2
       lea       -8(A6),A3
       lea       _token.L,A4
       lea       _logicalNumericFloatLong.L,A5
; unsigned char sqtdtam[10];
; for_stack i;
; int *endVarCont;
; unsigned char answer[3];
; char vRetVar = -1;
       moveq     #-1,D7
; unsigned char *vTempPointer;
; char vResLog1 = 0, vResLog2 = 0;
       clr.b     D6
       clr.b     D5
; char vResLog3 = 0, vResLog4 = 0;
       clr.b     D4
       clr.b     D3
; /*writeLongSerial("Aqui 777.666.0-[");
; itoa(*pointerRunProg,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]-[");
; itoa(*pointerRunProg,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]\r\n");*/
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),-4(A6)
; if (isalphas(*vTempPointer))
       move.l    -4(A6),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq       basNext_1
; {
; // procura pela variavel no forStack
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basNext_3
       clr.l     D0
       bra       basNext_5
basNext_3:
; if (*token_type != VARIABLE)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     basNext_6
; {
; *vErroProc = 4;
       move.l    _vErroProc.L,A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basNext_5
basNext_6:
; }
; answer[1] = *token;
       move.l    (A4),A0
       move.b    (A0),1(A3)
; if (strlen(token) == 1)
       move.l    (A4),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #1,D0
       bne.s     basNext_8
; {
; answer[0] = 0x00;
       clr.b     (A3)
; answer[2] = 0x00;
       clr.b     2(A3)
       bra       basNext_11
basNext_8:
; }
; else if (strlen(token) == 2)
       move.l    (A4),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basNext_10
; {
; if (*(token + 1) < 0x30)
       move.l    (A4),A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bhs.s     basNext_12
; {
; answer[0] = *(token + 1);
       move.l    (A4),A0
       move.b    1(A0),(A3)
; answer[2] = 0x00;
       clr.b     2(A3)
       bra.s     basNext_13
basNext_12:
; }
; else
; {
; answer[0] = 0x00;
       clr.b     (A3)
; answer[2] = *(token + 1);
       move.l    (A4),A0
       move.b    1(A0),2(A3)
basNext_13:
       bra.s     basNext_11
basNext_10:
; }
; }
; else
; {
; answer[0] = *(token + 2);
       move.l    (A4),A0
       move.b    2(A0),(A3)
; answer[2] = *(token + 1);
       move.l    (A4),A0
       move.b    1(A0),2(A3)
basNext_11:
; }
; vRetVar = forFind(&i,answer);
       move.l    A3,-(A7)
       move.l    A2,-(A7)
       jsr       _forFind
       addq.w    #8,A7
       move.b    D0,D7
; if (vRetVar < 0)
       cmp.b     #0,D7
       bge.s     basNext_14
; {
; *vErroProc = 11;
       move.l    _vErroProc.L,A0
       move.w    #11,(A0)
; return 0;
       clr.l     D0
       bra       basNext_5
basNext_14:
       bra.s     basNext_2
basNext_1:
; }
; }
; else // faz o pop da pilha
; i = forPop(); // read the loop info
       move.l    A2,A0
       move.l    A0,-(A7)
       jsr       _forPop
       move.l    (A7)+,A0
       move.l    D0,A1
       moveq     #4,D0
       move.l    (A1)+,(A0)+
       dbra      D0,*-2
basNext_2:
; endVarCont = i.endVar;
       move.l    A2,D0
       move.l    D0,A0
       move.l    4(A0),D2
; if (i.nameVar[2] == '#')
       move.l    A2,D0
       move.l    D0,A0
       move.b    2(A0),D0
       cmp.b     #35,D0
       bne.s     basNext_16
; {
; *endVarCont = fppSum(*endVarCont,i.step); // inc/dec, using step, control variable
       move.l    A2,D1
       move.l    D1,A0
       move.l    12(A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppSum
       addq.w    #8,A7
       move.l    D2,A0
       move.l    D0,(A0)
       bra.s     basNext_17
basNext_16:
; }
; else
; *endVarCont = *endVarCont + i.step; // inc/dec, using step, control variable
       move.l    D2,A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    12(A1),D0
       add.l     D0,(A0)
basNext_17:
; if (i.nameVar[2] == '#')
       move.l    A2,D0
       move.l    D0,A0
       move.b    2(A0),D0
       cmp.b     #35,D0
       bne       basNext_18
; {
; vResLog1 = logicalNumericFloatLong('>', *endVarCont, i.target);
       move.l    A2,D1
       move.l    D1,A0
       move.l    8(A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       pea       62
       jsr       (A5)
       add.w     #12,A7
       move.b    D0,D6
; vResLog2 = logicalNumericFloatLong('<', *endVarCont, i.target);
       move.l    A2,D1
       move.l    D1,A0
       move.l    8(A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       pea       60
       jsr       (A5)
       add.w     #12,A7
       move.b    D0,D5
; vResLog3 = logicalNumericFloatLong('>', i.step, 0);
       clr.l     -(A7)
       move.l    A2,D1
       move.l    D1,A0
       move.l    12(A0),-(A7)
       pea       62
       jsr       (A5)
       add.w     #12,A7
       move.b    D0,D4
; vResLog4 = logicalNumericFloatLong('<', i.step, 0);
       clr.l     -(A7)
       move.l    A2,D1
       move.l    D1,A0
       move.l    12(A0),-(A7)
       pea       60
       jsr       (A5)
       add.w     #12,A7
       move.b    D0,D3
       bra       basNext_19
basNext_18:
; }
; else
; {
; vResLog1 = (*endVarCont > i.target);
       move.l    D2,A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    (A0),D0
       cmp.l     8(A1),D0
       ble.s     basNext_20
       moveq     #1,D0
       bra.s     basNext_21
basNext_20:
       clr.l     D0
basNext_21:
       move.b    D0,D6
; vResLog2 = (*endVarCont < i.target);
       move.l    D2,A0
       move.l    A2,D0
       move.l    D0,A1
       move.l    (A0),D0
       cmp.l     8(A1),D0
       bge.s     basNext_22
       moveq     #1,D0
       bra.s     basNext_23
basNext_22:
       clr.l     D0
basNext_23:
       move.b    D0,D5
; vResLog3 = (i.step > 0);
       move.l    A2,D0
       move.l    D0,A0
       move.l    12(A0),D0
       cmp.l     #0,D0
       ble.s     basNext_24
       moveq     #1,D0
       bra.s     basNext_25
basNext_24:
       clr.l     D0
basNext_25:
       move.b    D0,D4
; vResLog4 = (i.step < 0);
       move.l    A2,D0
       move.l    D0,A0
       move.l    12(A0),D0
       cmp.l     #0,D0
       bge.s     basNext_26
       moveq     #1,D0
       bra.s     basNext_27
basNext_26:
       clr.l     D0
basNext_27:
       move.b    D0,D3
basNext_19:
; }
; // compara se ja chegou no final  //     if ((i.step > 0 && *endVarCont>i.target) || (i.step < 0 && *endVarCont<i.target))
; if ((vResLog3 && vResLog1) || (vResLog4 && vResLog2))
       tst.b     D4
       beq.s     basNext_31
       tst.b     D6
       bne.s     basNext_30
basNext_31:
       tst.b     D3
       beq.s     basNext_28
       tst.b     D5
       beq.s     basNext_28
basNext_30:
; return 0 ;  // all done
       clr.l     D0
       bra.s     basNext_5
basNext_28:
; *changedPointer = i.progPosPointerRet;  // loop
       move.l    A2,D0
       move.l    D0,A0
       move.l    _changedPointer.L,A1
       move.l    16(A0),(A1)
; if (vRetVar < 0)
       cmp.b     #0,D7
       bge.s     basNext_32
; forPush(i);  // otherwise, restore the info
       move.l    A2,D1
       move.l    D1,A0
       add.w     #20,A0
       moveq     #4,D1
       move.l    -(A0),-(A7)
       dbra      D1,*-2
       jsr       _forPush
       add.w     #20,A7
basNext_32:
; return 0;
       clr.l     D0
basNext_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Salta para uma linha se erro
; // Syntaxe:
; //          ON <VAR> GOSUB <num.linha 1>,<num.linha 2>,...,,<num.linha n>
; //          ON <VAR> GOTO <num.linha 1>,<num.linha 2>,...,<num.linha n>
; //--------------------------------------------------------------------------------------
; int basOnVar(void)
; {
       xdef      _basOnVar
_basOnVar:
       link      A6,#-12
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       _nextToken.L,A4
       lea       _pointerRunProg.L,A5
; unsigned char* vNextAddrGoto;
; unsigned int vNumLin = 0;
       clr.l     -12(A6)
; unsigned char *vTempPointer;
; unsigned int vSalto;
; unsigned int iSalto = 0;
       clr.l     -4(A6)
; unsigned int ix;
; vTempPointer = *pointerRunProg;
       move.l    (A5),A0
       move.l    (A0),D3
; if (isalphas(*vTempPointer))
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq       basOnVar_1
; {
; // procura pela variavel no forStack
; nextToken();
       jsr       (A4)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basOnVar_3
       clr.l     D0
       bra       basOnVar_5
basOnVar_3:
; if (*token_type != VARIABLE)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     basOnVar_6
; {
; *vErroProc = 4;
       move.l    (A2),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_6:
; }
; putback();
       jsr       _putback
; getExp(&iSalto);
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basOnVar_8
       clr.l     D0
       bra       basOnVar_5
basOnVar_8:
; if (*value_type != '%')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #37,D0
       beq.s     basOnVar_10
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_10:
; }
; if (iSalto == 0 || iSalto > 255)
       move.l    -4(A6),D0
       beq.s     basOnVar_14
       move.l    -4(A6),D0
       cmp.l     #255,D0
       bls.s     basOnVar_12
basOnVar_14:
; {
; *vErroProc = 5;
       move.l    (A2),A0
       move.w    #5,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_12:
       bra.s     basOnVar_2
basOnVar_1:
; }
; }
; else
; {
; *vErroProc = 4;
       move.l    (A2),A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_2:
; }
; vTempPointer = *pointerRunProg;
       move.l    (A5),A0
       move.l    (A0),D3
; // Se nao for goto ou gosub, erro
; if (*vTempPointer != 0x89 && *vTempPointer != 0x8A)
       move.l    D3,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #137,D0
       beq.s     basOnVar_15
       move.l    D3,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #138,D0
       beq.s     basOnVar_15
; {
; *vErroProc = 14;
       move.l    (A2),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_15:
; }
; vSalto = *vTempPointer;
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    D0,-8(A6)
; ix = 0;
       clr.l     D4
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A5),A0
       addq.l    #1,(A0)
; while (1)
basOnVar_17:
; {
; getExp(&vNumLin); // get target value
       pea       -12(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$' || *value_type == '#') {
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basOnVar_22
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basOnVar_20
basOnVar_22:
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_20:
; }
; ix++;
       addq.l    #1,D4
; if (ix == iSalto)
       cmp.l     -4(A6),D4
       bne.s     basOnVar_23
; break;
       bra       basOnVar_19
basOnVar_23:
; nextToken();
       jsr       (A4)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basOnVar_25
       clr.l     D0
       bra       basOnVar_5
basOnVar_25:
; // Deve ser uma virgula
; if (*token!=',')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq.s     basOnVar_27
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_27:
; }
; nextToken();
       jsr       (A4)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basOnVar_29
       clr.l     D0
       bra       basOnVar_5
basOnVar_29:
; putback();
       jsr       _putback
       bra       basOnVar_17
basOnVar_19:
; }
; if (ix == 0 || ix > iSalto)
       tst.l     D4
       beq.s     basOnVar_33
       cmp.l     -4(A6),D4
       bls.s     basOnVar_31
basOnVar_33:
; {
; *vErroProc = 14;
       move.l    (A2),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_31:
; }
; vNextAddrGoto = findNumberLine(vNumLin, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    -12(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D2
; if (vSalto == 0x89)
       move.l    -8(A6),D0
       cmp.l     #137,D0
       bne       basOnVar_34
; {
; // GOTO
; if (vNextAddrGoto > 0)
       cmp.l     #0,D2
       bls       basOnVar_36
; {
; if ((unsigned int)(((unsigned int)*(vNextAddrGoto + 3) << 8) | *(vNextAddrGoto + 4)) == vNumLin)
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       cmp.l     -12(A6),D0
       bne.s     basOnVar_38
; {
; *changedPointer = vNextAddrGoto;
       move.l    _changedPointer.L,A0
       move.l    D2,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_38:
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_36:
; }
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
       bra       basOnVar_5
basOnVar_34:
; }
; }
; else
; {
; // GOSUB
; if (vNextAddrGoto > 0)
       cmp.l     #0,D2
       bls       basOnVar_40
; {
; if ((unsigned int)(((unsigned int)*(vNextAddrGoto + 3) << 8) | *(vNextAddrGoto + 4)) == vNumLin)
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       cmp.l     -12(A6),D0
       bne.s     basOnVar_42
; {
; gosubPush(*nextAddr);
       move.l    _nextAddr.L,A0
       move.l    (A0),-(A7)
       jsr       _gosubPush
       addq.w    #4,A7
; *changedPointer = vNextAddrGoto;
       move.l    _changedPointer.L,A0
       move.l    D2,(A0)
; return 0;
       clr.l     D0
       bra.s     basOnVar_5
basOnVar_42:
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
       bra.s     basOnVar_5
basOnVar_40:
; }
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
basOnVar_5:
       movem.l   (A7)+,D2/D3/D4/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; return 0;
; }
; //--------------------------------------------------------------------------------------
; // Salta para uma linha se erro
; // Syntaxe:
; //          ONERR GOTO <num.linha>
; //--------------------------------------------------------------------------------------
; int basOnErr(void)
; {
       xdef      _basOnErr
_basOnErr:
       link      A6,#-20
       movem.l   D2/A2,-(A7)
       lea       _vErroProc.L,A2
; unsigned char* vNextAddrGoto;
; unsigned int vNumLin = 0;
       clr.l     -18(A6)
; unsigned char sqtdtam[10];
; unsigned char *vTempPointer;
; vTempPointer = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),-4(A6)
; // Se nao for goto, erro
; if (*vTempPointer != 0x89)
       move.l    -4(A6),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #137,D0
       beq.s     basOnErr_1
; {
; *vErroProc = 14;
       move.l    (A2),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basOnErr_3
basOnErr_1:
; }
; // soma mais um pra ir pro numero da linha
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
; getExp(&vNumLin); // get target value
       pea       -18(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$' || *value_type == '#') {
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basOnErr_6
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basOnErr_4
basOnErr_6:
; *vErroProc = 17;
       move.l    (A2),A0
       move.w    #17,(A0)
; return 0;
       clr.l     D0
       bra       basOnErr_3
basOnErr_4:
; }
; vNextAddrGoto = findNumberLine(vNumLin, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    -18(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D2
; if (vNextAddrGoto > 0)
       cmp.l     #0,D2
       bls       basOnErr_7
; {
; if ((unsigned int)(((unsigned int)*(vNextAddrGoto + 3) << 8) | *(vNextAddrGoto + 4)) == vNumLin)
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       cmp.l     -18(A6),D0
       bne.s     basOnErr_9
; {
; *onErrGoto = vNextAddrGoto;
       move.l    _onErrGoto.L,A0
       move.l    D2,(A0)
; return 0;
       clr.l     D0
       bra.s     basOnErr_3
basOnErr_9:
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
       bra.s     basOnErr_3
basOnErr_7:
; }
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
basOnErr_3:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; return 0;
; }
; //--------------------------------------------------------------------------------------
; // Salta para uma linha, sem retorno
; // Syntaxe:
; //          GOTO <num.linha>
; //--------------------------------------------------------------------------------------
; int basGoto(void)
; {
       xdef      _basGoto
_basGoto:
       link      A6,#-16
       movem.l   D2/A2,-(A7)
       lea       _vErroProc.L,A2
; unsigned char* vNextAddrGoto;
; unsigned int vNumLin = 0;
       clr.l     -14(A6)
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basGoto_1
       clr.l     D0
       bra       basGoto_3
basGoto_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basGoto_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       bne.s     basGoto_4
basGoto_6:
; {
; *vErroProc = 14;
       move.l    (A2),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basGoto_3
basGoto_4:
; }
; putback();
       jsr       _putback
; getExp(&vNumLin); // get target value
       pea       -14(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$' || *value_type == '#') {
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basGoto_9
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basGoto_7
basGoto_9:
; *vErroProc = 17;
       move.l    (A2),A0
       move.w    #17,(A0)
; return 0;
       clr.l     D0
       bra       basGoto_3
basGoto_7:
; }
; vNextAddrGoto = findNumberLine(vNumLin, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    -14(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D2
; if (vNextAddrGoto > 0)
       cmp.l     #0,D2
       bls       basGoto_10
; {
; if ((unsigned int)(((unsigned int)*(vNextAddrGoto + 3) << 8) | *(vNextAddrGoto + 4)) == vNumLin)
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       cmp.l     -14(A6),D0
       bne.s     basGoto_12
; {
; *changedPointer = vNextAddrGoto;
       move.l    _changedPointer.L,A0
       move.l    D2,(A0)
; return 0;
       clr.l     D0
       bra.s     basGoto_3
basGoto_12:
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
       bra.s     basGoto_3
basGoto_10:
; }
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
basGoto_3:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; return 0;
; }
; //--------------------------------------------------------------------------------------
; // Salta para uma linha e guarda a posicao atual para voltar
; // Syntaxe:
; //          GOSUB <num.linha>
; //--------------------------------------------------------------------------------------
; int basGosub(void)
; {
       xdef      _basGosub
_basGosub:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _vErroProc.L,A2
; unsigned char* vNextAddrGoto;
; unsigned int vNumLin = 0;
       clr.l     -4(A6)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basGosub_1
       clr.l     D0
       bra       basGosub_3
basGosub_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basGosub_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       bne.s     basGosub_4
basGosub_6:
; {
; *vErroProc = 14;
       move.l    (A2),A0
       move.w    #14,(A0)
; return 0;
       clr.l     D0
       bra       basGosub_3
basGosub_4:
; }
; putback();
       jsr       _putback
; getExp(&vNumLin); // get target valuedel 20
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$' || *value_type == '#') {
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basGosub_9
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basGosub_7
basGosub_9:
; *vErroProc = 17;
       move.l    (A2),A0
       move.w    #17,(A0)
; return 0;
       clr.l     D0
       bra       basGosub_3
basGosub_7:
; }
; vNextAddrGoto = findNumberLine(vNumLin, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    -4(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _findNumberLine
       add.w     #12,A7
       move.l    D0,D2
; if (vNextAddrGoto > 0)
       cmp.l     #0,D2
       bls       basGosub_10
; {
; if ((unsigned int)(((unsigned int)*(vNextAddrGoto + 3) << 8) | *(vNextAddrGoto + 4)) == vNumLin)
       move.l    D2,A0
       move.b    3(A0),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D2,A0
       move.b    4(A0),D1
       and.l     #255,D1
       or.l      D1,D0
       cmp.l     -4(A6),D0
       bne.s     basGosub_12
; {
; gosubPush(*nextAddr);
       move.l    _nextAddr.L,A0
       move.l    (A0),-(A7)
       jsr       _gosubPush
       addq.w    #4,A7
; *changedPointer = vNextAddrGoto;
       move.l    _changedPointer.L,A0
       move.l    D2,(A0)
; return 0;
       clr.l     D0
       bra.s     basGosub_3
basGosub_12:
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
       bra.s     basGosub_3
basGosub_10:
; }
; }
; else
; {
; *vErroProc = 7;
       move.l    (A2),A0
       move.w    #7,(A0)
; return 0;
       clr.l     D0
basGosub_3:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; return 0;
; }
; //--------------------------------------------------------------------------------------
; // Retorna de um Gosub
; // Syntaxe:
; //          RETURN
; //--------------------------------------------------------------------------------------
; int basReturn(void)
; {
       xdef      _basReturn
_basReturn:
       link      A6,#-4
; unsigned long i;
; i = gosubPop();
       jsr       _gosubPop
       move.l    D0,-4(A6)
; *changedPointer = i;
       move.l    _changedPointer.L,A0
       move.l    -4(A6),(A0)
; return 0;
       clr.l     D0
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Retorna um numero real como inteiro
; // Syntaxe:
; //          INT(<number real>)
; //--------------------------------------------------------------------------------------
; int basInt(void)
; {
       xdef      _basInt
_basInt:
       link      A6,#-4
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       _value_type.L,A4
       lea       _nextToken.L,A5
; int vReal = 0, vResult = 0;
       clr.l     -4(A6)
       clr.l     D2
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basInt_1
       clr.l     D0
       bra       basInt_3
basInt_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basInt_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basInt_6
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basInt_4
basInt_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basInt_3
basInt_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basInt_7
       clr.l     D0
       bra       basInt_3
basInt_7:
; putback();
       jsr       _putback
; getExp(&vReal); //
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basInt_9
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basInt_3
basInt_9:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basInt_11
       clr.l     D0
       bra       basInt_3
basInt_11:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basInt_13
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basInt_3
basInt_13:
; }
; if (*value_type == '#')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basInt_15
; vResult = fppInt(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D0,D2
       bra.s     basInt_16
basInt_15:
; else
; vResult = vReal;
       move.l    -4(A6),D2
basInt_16:
; *value_type='%';
       move.l    (A4),A0
       move.b    #37,(A0)
; *token=((int)(vResult & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(vResult & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(vResult & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,2(A0)
; *(token + 3)=(vResult & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A3),A0
       move.b    D0,3(A0)
; return 0;
       clr.l     D0
basInt_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Retorna um numero absoluto como inteiro
; // Syntaxe:
; //          ABS(<number real>)
; //--------------------------------------------------------------------------------------
; int basAbs(void)
; {
       xdef      _basAbs
_basAbs:
       link      A6,#-4
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _token.L,A3
       lea       _value_type.L,A4
       lea       _nextToken.L,A5
; int vReal = 0, vResult = 0;
       clr.l     -4(A6)
       clr.l     D2
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAbs_1
       clr.l     D0
       bra       basAbs_3
basAbs_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basAbs_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basAbs_6
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basAbs_4
basAbs_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basAbs_3
basAbs_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAbs_7
       clr.l     D0
       bra       basAbs_3
basAbs_7:
; putback();
       jsr       _putback
; getExp(&vReal); //
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basAbs_9
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basAbs_3
basAbs_9:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basAbs_11
       clr.l     D0
       bra       basAbs_3
basAbs_11:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basAbs_13
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basAbs_3
basAbs_13:
; }
; if (*value_type == '#')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basAbs_15
; vResult = fppAbs(vReal);
       move.l    -4(A6),-(A7)
       jsr       _fppAbs
       addq.w    #4,A7
       move.l    D0,D2
       bra.s     basAbs_17
basAbs_15:
; else
; {
; vResult = vReal;
       move.l    -4(A6),D2
; if (vResult < 1)
       cmp.l     #1,D2
       bge.s     basAbs_17
; vResult = vResult * (-1);
       move.l    D2,-(A7)
       pea       -1
       jsr       LMUL
       move.l    (A7),D2
       addq.w    #8,A7
basAbs_17:
; }
; *value_type='%';
       move.l    (A4),A0
       move.b    #37,(A0)
; *token=((int)(vResult & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(vResult & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(vResult & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A3),A0
       move.b    D0,2(A0)
; *(token + 3)=(vResult & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A3),A0
       move.b    D0,3(A0)
; return 0;
       clr.l     D0
basAbs_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Retorna um numero randomicamente
; // Syntaxe:
; //          RND(<number>)
; //--------------------------------------------------------------------------------------
; int basRnd(void)
; {
       xdef      _basRnd
_basRnd:
       link      A6,#-48
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       -20(A6),A3
       lea       _token.L,A4
       lea       _randSeed.L,A5
; unsigned long vRand;
; int vReal = 0, vResult = 0;
       clr.l     -48(A6)
       clr.l     -44(A6)
; unsigned char vTRand[20];
; unsigned char vSRand[20];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basRnd_1
       clr.l     D0
       bra       basRnd_3
basRnd_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basRnd_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basRnd_6
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basRnd_4
basRnd_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basRnd_3
basRnd_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basRnd_7
       clr.l     D0
       bra       basRnd_3
basRnd_7:
; putback();
       jsr       _putback
; getExp(&vReal); //
       pea       -48(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basRnd_9
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basRnd_3
basRnd_9:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basRnd_11
       clr.l     D0
       bra       basRnd_3
basRnd_11:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type != CLOSEPARENT)
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basRnd_13
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basRnd_3
basRnd_13:
; }
; if (vReal == 0)
       move.l    -48(A6),D0
       bne.s     basRnd_15
; {
; vRand = *randSeed;
       move.l    (A5),A0
       move.l    (A0),D2
       bra       basRnd_20
basRnd_15:
; }
; else if (vReal >= -1 && vReal < 0)
       move.l    -48(A6),D0
       cmp.l     #-1,D0
       blt       basRnd_17
       move.l    -48(A6),D0
       cmp.l     #0,D0
       bge       basRnd_17
; {
; vRand = *(vmfp + Reg_TADR);
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.l     #255,D0
       move.l    D0,D2
; vRand = (vRand << 3);
       lsl.l     #3,D2
; vRand += 0x466;
       add.l     #1126,D2
; vRand -= ((*(vmfp + Reg_TADR)) * 3);
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.w     #255,D0
       mulu.w    #3,D0
       and.l     #65535,D0
       sub.l     D0,D2
; *randSeed = vRand;
       move.l    (A5),A0
       move.l    D2,(A0)
       bra       basRnd_20
basRnd_17:
; }
; else if (vReal > 0 && vReal <= 1)
       move.l    -48(A6),D0
       cmp.l     #0,D0
       ble       basRnd_19
       move.l    -48(A6),D0
       cmp.l     #1,D0
       bgt.s     basRnd_19
; {
; vRand = *randSeed;
       move.l    (A5),A0
       move.l    (A0),D2
; vRand = (vRand << 3);
       lsl.l     #3,D2
; vRand += 0x466;
       add.l     #1126,D2
; vRand -= ((*(vmfp + Reg_TADR)) * 3);
       move.l    _vmfp.L,A0
       move.w    _Reg_TADR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.w     #255,D0
       mulu.w    #3,D0
       and.l     #65535,D0
       sub.l     D0,D2
; *randSeed = vRand;
       move.l    (A5),A0
       move.l    D2,(A0)
       bra.s     basRnd_20
basRnd_19:
; }
; else
; {
; *vErroProc = 5;
       move.l    (A2),A0
       move.w    #5,(A0)
; return 0;
       clr.l     D0
       bra       basRnd_3
basRnd_20:
; }
; itoa(vRand, vTRand, 10);
       pea       10
       pea       -40(A6)
       move.l    D2,-(A7)
       jsr       _itoa
       add.w     #12,A7
; vSRand[0] = '0';
       move.b    #48,(A3)
; vSRand[1] = '.';
       move.b    #46,1(A3)
; vSRand[2] = 0x00;
       clr.b     2(A3)
; strcat(vSRand, vTRand);
       pea       -40(A6)
       move.l    A3,-(A7)
       jsr       _strcat
       addq.w    #8,A7
; vRand = floatStringToFpp(vSRand);
       move.l    A3,-(A7)
       jsr       _floatStringToFpp
       addq.w    #4,A7
       move.l    D0,D2
; *value_type='#';
       move.l    _value_type.L,A0
       move.b    #35,(A0)
; *token=((int)(vRand & 0xFF000000) >> 24);
       move.l    D2,D0
       and.l     #-16777216,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A4),A0
       move.b    D0,(A0)
; *(token + 1)=((int)(vRand & 0x00FF0000) >> 16);
       move.l    D2,D0
       and.l     #16711680,D0
       asr.l     #8,D0
       asr.l     #8,D0
       move.l    (A4),A0
       move.b    D0,1(A0)
; *(token + 2)=((int)(vRand & 0x0000FF00) >> 8);
       move.l    D2,D0
       and.l     #65280,D0
       asr.l     #8,D0
       move.l    (A4),A0
       move.b    D0,2(A0)
; *(token + 3)=(vRand & 0x000000FF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A4),A0
       move.b    D0,3(A0)
; return 0;
       clr.l     D0
basRnd_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Seta posicao vertical (linha em texto e y em grafico)
; // Syntaxe:
; //          VTAB <numero>
; //--------------------------------------------------------------------------------------
; int basVtab(void)
; {
       xdef      _basVtab
_basVtab:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _value_type.L,A2
; unsigned int vRow = 0;
       clr.l     -4(A6)
; getExp(&vRow);
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$') {
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basVtab_1
; *vErroProc = 16;
       move.l    _vErroProc.L,A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basVtab_3
basVtab_1:
; }
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basVtab_4
; {
; vRow = fppInt(vRow);
       move.l    -4(A6),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D0,-4(A6)
; *value_type = '%';
       move.l    (A2),A0
       move.b    #37,(A0)
basVtab_4:
; }
; vdp_set_cursor(*videoCursorPosColX, vRow);
       move.l    -4(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    _videoCursorPosColX.L,A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
; return 0;
       clr.l     D0
basVtab_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Seta posicao horizontal (coluna em texto e x em grafico)
; // Syntaxe:
; //          HTAB <numero>
; //--------------------------------------------------------------------------------------
; int basHtab(void)
; {
       xdef      _basHtab
_basHtab:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _value_type.L,A2
; unsigned int vColumn = 0;
       clr.l     -4(A6)
; getExp(&vColumn);
       pea       -4(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*value_type == '$') {
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basHtab_1
; *vErroProc = 16;
       move.l    _vErroProc.L,A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHtab_3
basHtab_1:
; }
; if (*value_type == '#')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basHtab_4
; {
; vColumn = fppInt(vColumn);
       move.l    -4(A6),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D0,-4(A6)
; *value_type = '%';
       move.l    (A2),A0
       move.b    #37,(A0)
basHtab_4:
; }
; vdp_set_cursor(vColumn, *videoCursorPosRowY);
       move.l    _videoCursorPosRowY.L,A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    -4(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
; return 0;
       clr.l     D0
basHtab_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Finaliza o programa sem erro
; // Syntaxe:
; //          END
; //--------------------------------------------------------------------------------------
; int basEnd(void)
; {
       xdef      _basEnd
_basEnd:
; *nextAddr = 0;
       move.l    _nextAddr.L,A0
       clr.l     (A0)
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // Finaliza o programa com erro
; // Syntaxe:
; //          STOP
; //--------------------------------------------------------------------------------------
; int basStop(void)
; {
       xdef      _basStop
_basStop:
; *vErroProc = 1;
       move.l    _vErroProc.L,A0
       move.w    #1,(A0)
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // Retorna 'n' Espaços
; // Syntaxe:
; //          SPC <numero>
; //--------------------------------------------------------------------------------------
; int basSpc(void)
; {
       xdef      _basSpc
_basSpc:
       link      A6,#-48
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       _token_type.L,A4
       lea       _nextToken.L,A5
; unsigned int vSpc = 0;
       clr.l     D4
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     D2
       clr.l     -48(A6)
       clr.l     -44(A6)
       clr.l     -40(A6)
; unsigned char answer[20];
; int  *iVal = answer;
       lea       -32(A6),A0
       move.l    A0,D3
; unsigned char vTab, vColumn;
; unsigned char sqtdtam[10];
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basSpc_1
       clr.l     D0
       bra       basSpc_3
basSpc_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basSpc_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basSpc_6
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basSpc_4
basSpc_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basSpc_3
basSpc_4:
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basSpc_7
       clr.l     D0
       bra       basSpc_3
basSpc_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basSpc_9
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basSpc_3
basSpc_9:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -32(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basSpc_11
       clr.l     D0
       bra       basSpc_3
basSpc_11:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basSpc_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basSpc_3
basSpc_13:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basSpc_15
; {
; *iVal = fppInt(*iVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basSpc_15:
; }
; }
; nextToken();
       jsr       (A5)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basSpc_17
       clr.l     D0
       bra       basSpc_3
basSpc_17:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basSpc_19
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra.s     basSpc_3
basSpc_19:
; }
; vSpc=(char)*iVal;
       move.l    D3,A0
       move.l    (A0),D4
; for (ix = 0; ix < vSpc; ix++)
       clr.l     D2
basSpc_21:
       cmp.l     D4,D2
       bhs.s     basSpc_23
; *(token + ix) = ' ';
       move.l    _token.L,A0
       move.b    #32,0(A0,D2.L)
       addq.l    #1,D2
       bra       basSpc_21
basSpc_23:
; *(token + ix) = 0;
       move.l    _token.L,A0
       clr.b     0(A0,D2.L)
; *value_type = '$';
       move.l    (A3),A0
       move.b    #36,(A0)
; return 0;
       clr.l     D0
basSpc_3:
       movem.l   (A7)+,D2/D3/D4/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Advance 'n' columns
; // Syntaxe:
; //          TAB <numero>
; //--------------------------------------------------------------------------------------
; int basTab(void)
; {
       xdef      _basTab
_basTab:
       link      A6,#-52
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       _videoCursorPosRowY.L,A4
       lea       _token_type.L,A5
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -50(A6)
       clr.l     -46(A6)
       clr.l     -42(A6)
       clr.l     -38(A6)
; unsigned char answer[20];
; int  *iVal = answer;
       lea       -30(A6),A0
       move.l    A0,D3
; unsigned char vTab, vColumn;
; unsigned char sqtdtam[10];
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTab_1
       clr.l     D0
       bra       basTab_3
basTab_1:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basTab_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basTab_6
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basTab_4
basTab_6:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basTab_3
basTab_4:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTab_7
       clr.l     D0
       bra       basTab_3
basTab_7:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basTab_9
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basTab_3
basTab_9:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -30(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTab_11
       clr.l     D0
       bra       basTab_3
basTab_11:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basTab_13
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basTab_3
basTab_13:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basTab_15
; {
; *iVal = fppInt(*iVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basTab_15:
; }
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basTab_17
       clr.l     D0
       bra       basTab_3
basTab_17:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basTab_19
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basTab_3
basTab_19:
; }
; vTab=(char)*iVal;
       move.l    D3,A0
       move.l    (A0),D0
       move.b    D0,D4
; vColumn = *videoCursorPosColX;
       move.l    _videoCursorPosColX.L,A0
       move.w    (A0),D0
       move.b    D0,D2
; if (vTab>vColumn)
       cmp.b     D2,D4
       bls       basTab_21
; {
; vColumn = vColumn + vTab;
       add.b     D4,D2
; while (vColumn>*vdpMaxCols)
basTab_23:
       move.l    _vdpMaxCols.L,A0
       cmp.b     (A0),D2
       bls.s     basTab_25
; {
; vColumn = vColumn - *vdpMaxCols;
       move.l    _vdpMaxCols.L,A0
       move.b    (A0),D0
       sub.b     D0,D2
; if (*videoCursorPosRowY < *vdpMaxRows)
       move.l    (A4),A0
       move.l    _vdpMaxRows.L,A1
       move.b    (A1),D0
       and.w     #255,D0
       cmp.w     (A0),D0
       bls.s     basTab_26
; *videoCursorPosRowY += 1;
       move.l    (A4),A0
       addq.w    #1,(A0)
basTab_26:
       bra       basTab_23
basTab_25:
; }
; vdp_set_cursor(vColumn, *videoCursorPosRowY);
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
basTab_21:
; }
; *token = ' ';
       move.l    _token.L,A0
       move.b    #32,(A0)
; *value_type='$';
       move.l    (A3),A0
       move.b    #36,(A0)
; return 0;
       clr.l     D0
basTab_3:
       movem.l   (A7)+,D2/D3/D4/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Text Screen Mode (40 cols x 24 rows)
; // Syntaxe:
; //          TEXT
; //--------------------------------------------------------------------------------------
; int basText(void)
; {
       xdef      _basText
_basText:
; *fgcolor = VDP_WHITE;
       move.l    _fgcolor.L,A0
       move.b    #15,(A0)
; *bgcolor = VDP_BLACK;
       move.l    _bgcolor.L,A0
       move.b    #1,(A0)
; vdp_init(VDP_MODE_TEXT, (*fgcolor<<4) | (*bgcolor & 0x0f), 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       lsl.b     #4,D1
       move.l    _bgcolor.L,A0
       move.l    D0,-(A7)
       move.b    (A0),D0
       and.b     #15,D0
       or.b      D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       3
       jsr       _vdp_init
       add.w     #16,A7
; clearScr();
       jsr       _clearScr
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // Low Resolution Screen Mode (64x48)
; // Syntaxe:
; //          GR
; //--------------------------------------------------------------------------------------
; int basGr(void)
; {
       xdef      _basGr
_basGr:
; vdp_init(VDP_MODE_MULTICOLOR, 0, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       pea       2
       jsr       _vdp_init
       add.w     #16,A7
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // High Resolution Screen Mode (256x192)
; // Syntaxe:
; //          HGR
; //--------------------------------------------------------------------------------------
; int basHgr(void)
; {
       xdef      _basHgr
_basHgr:
; vdp_init(VDP_MODE_G2, 0x0, 1, 0);
       clr.l     -(A7)
       pea       1
       clr.l     -(A7)
       pea       1
       jsr       _vdp_init
       add.w     #16,A7
; vdp_set_bdcolor(VDP_BLACK);
       pea       1
       jsr       _vdp_set_bdcolor
       addq.w    #4,A7
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // Inverte as Cores de tela (COR FRENTE <> COR NORMAL)
; // Syntaxe:
; //          INVERSE
; //
; //    **********************************************************************************
; //    ** SOMENTE PARA COMPATIBILIDADE, NO TMS91xx E TMS99xx NAO FUNCIONA COR POR CHAR **
; //    **********************************************************************************
; //--------------------------------------------------------------------------------------
; int basInverse(void)
; {
       xdef      _basInverse
_basInverse:
; /*    unsigned char vTempCor;
; *fgcolorAnt = *fgcolor;
; *bgcolorAnt = *bgcolor;
; vTempCor = *fgcolor;
; *fgcolor = *bgcolor;
; *bgcolor = vTempCor;
; vdp_textcolor(*fgcolor,*bgcolor);*/
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // Volta as cores de tela as cores iniciais
; // Syntaxe:
; //          NORMAL
; //
; //    **********************************************************************************
; //    ** SOMENTE PARA COMPATIBILIDADE, NO TMS91xx E TMS99xx NAO FUNCIONA COR POR CHAR **
; //    **********************************************************************************
; //--------------------------------------------------------------------------------------
; int basNormal(void)
; {
       xdef      _basNormal
_basNormal:
; /*    *fgcolor = *fgcolorAnt;
; *bgcolor = *bgcolorAnt;
; vdp_textcolor(*fgcolor,*bgcolor);*/
; return 0;
       clr.l     D0
       rts
; }
; //--------------------------------------------------------------------------------------
; // Muda a cor do plot em baixa/alta resolucao (GR or HGR from basHcolor)
; // Syntaxe:
; //          COLOR=<color>
; //--------------------------------------------------------------------------------------
; int basColor(void)
; {
       xdef      _basColor
_basColor:
       link      A6,#-52
       movem.l   D2/D3/A2/A3/A4,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       _pointerRunProg.L,A4
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -52(A6)
       clr.l     -48(A6)
       clr.l     -44(A6)
       clr.l     -40(A6)
; unsigned char answer[20];
; int  *iVal = answer;
       lea       -32(A6),A0
       move.l    A0,D2
; unsigned char vTab, vColumn;
; unsigned char sqtdtam[10];
; unsigned char *vTempPointer;
; if (*vdp_mode != VDP_MODE_MULTICOLOR && *vdp_mode != VDP_MODE_G2)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     basColor_1
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     basColor_1
; {
; *vErroProc = 24;
       move.l    (A2),A0
       move.w    #24,(A0)
; return 0;
       clr.l     D0
       bra       basColor_3
basColor_1:
; }
; vTempPointer = *pointerRunProg;
       move.l    (A4),A0
       move.l    (A0),D3
; if (*vTempPointer != '=')
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #61,D0
       beq.s     basColor_4
; {
; *vErroProc = 3;
       move.l    (A2),A0
       move.w    #3,(A0)
; return 0;
       clr.l     D0
       bra       basColor_3
basColor_4:
; }
; *pointerRunProg = *pointerRunProg + 1;
       move.l    (A4),A0
       addq.l    #1,(A0)
; vTempPointer = *pointerRunProg;
       move.l    (A4),A0
       move.l    (A0),D3
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basColor_6
       clr.l     D0
       bra       basColor_3
basColor_6:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basColor_8
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basColor_3
basColor_8:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -32(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basColor_10
       clr.l     D0
       bra       basColor_3
basColor_10:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basColor_12
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basColor_3
basColor_12:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basColor_14
; {
; *iVal = fppInt(*iVal);
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D2,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basColor_14:
; }
; }
; *fgcolor=(char)*iVal;
       move.l    D2,A0
       move.l    (A0),D0
       move.l    _fgcolor.L,A0
       move.b    D0,(A0)
; *value_type='%';
       move.l    (A3),A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basColor_3:
       movem.l   (A7)+,D2/D3/A2/A3/A4
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Coloca um dot ou preenche uma area com a color previamente definida
; // Syntaxe:
; //          PLOT <x entre 0 e 63>, <y entre 0 e 47>
; //--------------------------------------------------------------------------------------
; int basPlot(void)
; {
       xdef      _basPlot
_basPlot:
       link      A6,#-52
       movem.l   D2/A2/A3/A4,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       -32(A6),A4
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -52(A6)
       clr.l     -48(A6)
       clr.l     -44(A6)
       clr.l     -40(A6)
; unsigned char answer[20];
; int  *iVal = answer;
       move.l    A4,D2
; unsigned char vx, vy;
; unsigned char sqtdtam[10];
; if (*vdp_mode != VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     basPlot_1
; {
; *vErroProc = 24;
       move.l    (A2),A0
       move.w    #24,(A0)
; return 0;
       clr.l     D0
       bra       basPlot_3
basPlot_1:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPlot_4
       clr.l     D0
       bra       basPlot_3
basPlot_4:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basPlot_6
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPlot_3
basPlot_6:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       move.l    A4,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPlot_8
       clr.l     D0
       bra       basPlot_3
basPlot_8:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basPlot_10
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPlot_3
basPlot_10:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basPlot_12
; {
; *iVal = fppInt(*iVal);
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D2,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basPlot_12:
; }
; }
; vx=(char)*iVal;
       move.l    D2,A0
       move.l    (A0),D0
       move.b    D0,-12(A6)
; if (*token != ',')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq.s     basPlot_14
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basPlot_3
basPlot_14:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPlot_16
       clr.l     D0
       bra       basPlot_3
basPlot_16:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basPlot_18
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPlot_3
basPlot_18:
; }
; else { /* is expression */
; //putback();
; getExp(&answer);
       move.l    A4,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basPlot_20
       clr.l     D0
       bra       basPlot_3
basPlot_20:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basPlot_22
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basPlot_3
basPlot_22:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basPlot_24
; {
; *iVal = fppInt(*iVal);
       move.l    D2,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D2,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basPlot_24:
; }
; }
; vy=(char)*iVal;
       move.l    D2,A0
       move.l    (A0),D0
       move.b    D0,-11(A6)
; vdp_plot_color(vx, vy, *fgcolor);
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -12(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_plot_color
       add.w     #12,A7
; *value_type='%';
       move.l    (A3),A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basPlot_3:
       movem.l   (A7)+,D2/A2/A3/A4
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Desenha uma linha horizontal de x1, y1 até x2, y1
; // Syntaxe:
; //          HLIN <x1>, <x2> at <y1>
; //               x1 e x2 : de 0 a 63
; //                    y1 : de 0 a 47
; //
; // Desenha uma linha vertical de x1, y1 até x1, y2
; // Syntaxe:
; //          VLIN <y1>, <y2> at <x1>
; //                    x1 : de 0 a 63
; //               y1 e y2 : de 0 a 47
; //--------------------------------------------------------------------------------------
; int basHVlin(unsigned char vTipo)   // 1 - HLIN, 2 - VLIN
; {
       xdef      _basHVlin
_basHVlin:
       link      A6,#-48
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
       lea       -30(A6),A4
       lea       _fppInt.L,A5
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     D2
       clr.l     -46(A6)
       clr.l     -42(A6)
       clr.l     -38(A6)
; unsigned char answer[20];
; int  *iVal = answer;
       move.l    A4,D3
; unsigned char vx1, vx2, vy;
; unsigned char sqtdtam[10];
; if (*vdp_mode != VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     basHVlin_1
; {
; *vErroProc = 24;
       move.l    (A2),A0
       move.w    #24,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_1:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHVlin_4
       clr.l     D0
       bra       basHVlin_3
basHVlin_4:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basHVlin_6
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_6:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       move.l    A4,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHVlin_8
       clr.l     D0
       bra       basHVlin_3
basHVlin_8:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basHVlin_10
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_10:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basHVlin_12
; {
; *iVal = fppInt(*iVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basHVlin_12:
; }
; }
; vx1=(char)*iVal;
       move.l    D3,A0
       move.l    (A0),D0
       move.b    D0,D5
; if (*token != ',')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq.s     basHVlin_14
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_14:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHVlin_16
       clr.l     D0
       bra       basHVlin_3
basHVlin_16:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basHVlin_18
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_18:
; }
; else { /* is expression */
; //putback();
; getExp(&answer);
       move.l    A4,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHVlin_20
       clr.l     D0
       bra       basHVlin_3
basHVlin_20:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basHVlin_22
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_22:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basHVlin_24
; {
; *iVal = fppInt(*iVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basHVlin_24:
; }
; }
; vx2=(char)*iVal;
       move.l    D3,A0
       move.l    (A0),D0
       move.b    D0,D4
; if (*token != 0xBA) // AT Token
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #186,D0
       beq.s     basHVlin_26
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_26:
; }
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHVlin_28
       clr.l     D0
       bra       basHVlin_3
basHVlin_28:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basHVlin_30
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_30:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       move.l    A4,-(A7)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHVlin_32
       clr.l     D0
       bra       basHVlin_3
basHVlin_32:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basHVlin_34
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHVlin_3
basHVlin_34:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basHVlin_36
; {
; *iVal = fppInt(*iVal);
       move.l    D3,A0
       move.l    (A0),-(A7)
       jsr       (A5)
       addq.w    #4,A7
       move.l    D3,A0
       move.l    D0,(A0)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basHVlin_36:
; }
; }
; vy=(char)*iVal;
       move.l    D3,A0
       move.l    (A0),D0
       move.b    D0,D6
; if (vx2 < vx1)
       cmp.b     D5,D4
       bhs.s     basHVlin_38
; {
; ix = vx1;
       and.l     #255,D5
       move.l    D5,D2
; vx1 = vx2;
       move.b    D4,D5
; vx2 = ix;
       move.b    D2,D4
basHVlin_38:
; }
; if (vTipo == 1)   // HLIN
       move.b    11(A6),D0
       cmp.b     #1,D0
       bne       basHVlin_40
; {
; for(ix = vx1; ix <= vx2; ix++)
       and.l     #255,D5
       move.l    D5,D2
basHVlin_42:
       and.l     #255,D4
       cmp.l     D4,D2
       bhi.s     basHVlin_44
; vdp_plot_color(ix, vy, *fgcolor);
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _vdp_plot_color
       add.w     #12,A7
       addq.l    #1,D2
       bra       basHVlin_42
basHVlin_44:
       bra       basHVlin_47
basHVlin_40:
; }
; else   // VLIN
; {
; for(ix = vx1; ix <= vx2; ix++)
       and.l     #255,D5
       move.l    D5,D2
basHVlin_45:
       and.l     #255,D4
       cmp.l     D4,D2
       bhi.s     basHVlin_47
; vdp_plot_color(vy, ix, *fgcolor);
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       jsr       _vdp_plot_color
       add.w     #12,A7
       addq.l    #1,D2
       bra       basHVlin_45
basHVlin_47:
; }
; *value_type='%';
       move.l    (A3),A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basHVlin_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; // Syntaxe:
; //
; //--------------------------------------------------------------------------------------
; int basScrn(void)
; {
       xdef      _basScrn
_basScrn:
       link      A6,#-56
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _nextToken.L,A3
       lea       _token_type.L,A4
       lea       _value_type.L,A5
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       clr.l     -56(A6)
       clr.l     -52(A6)
       clr.l     -48(A6)
       clr.l     -44(A6)
; unsigned char answer[20];
; int *iVal = answer;
       lea       -36(A6),A0
       move.l    A0,D2
; int *tval = token;
       move.l    _token.L,-16(A6)
; unsigned char vx, vy;
; unsigned char sqtdtam[10];
; if (*vdp_mode != VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     basScrn_1
; {
; *vErroProc = 24;
       move.l    (A2),A0
       move.w    #24,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_1:
; }
; nextToken();
       jsr       (A3)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_4
       clr.l     D0
       bra       basScrn_3
basScrn_4:
; // Erro, primeiro caracter deve ser abre parenteses
; if (*tok == EOL || *tok == FINISHED || *token_type != OPENPARENT)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basScrn_8
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basScrn_8
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #8,D0
       beq.s     basScrn_6
basScrn_8:
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_6:
; }
; nextToken();
       jsr       (A3)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_9
       clr.l     D0
       bra       basScrn_3
basScrn_9:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basScrn_11
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_11:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -36(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_13
       clr.l     D0
       bra       basScrn_3
basScrn_13:
; if (*value_type != '%')
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #37,D0
       beq.s     basScrn_15
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_15:
; }
; }
; vx=(char)*iVal;
       move.l    D2,A0
       move.l    (A0),D0
       move.b    D0,-12(A6)
; nextToken();
       jsr       (A3)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_17
       clr.l     D0
       bra       basScrn_3
basScrn_17:
; if (*token!=',')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq.s     basScrn_19
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_19:
; }
; nextToken();
       jsr       (A3)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_21
       clr.l     D0
       bra       basScrn_3
basScrn_21:
; if (*token_type == QUOTE) { /* is string, error */
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basScrn_23
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_23:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -36(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_25
       clr.l     D0
       bra       basScrn_3
basScrn_25:
; if (*value_type != '%')
       move.l    (A5),A0
       move.b    (A0),D0
       cmp.b     #37,D0
       beq.s     basScrn_27
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basScrn_3
basScrn_27:
; }
; }
; vy=(char)*iVal;
       move.l    D2,A0
       move.l    (A0),D0
       move.b    D0,-11(A6)
; nextToken();
       jsr       (A3)
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basScrn_29
       clr.l     D0
       bra       basScrn_3
basScrn_29:
; // Ultimo caracter deve ser fecha parenteses
; if (*token_type!=CLOSEPARENT)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #9,D0
       beq.s     basScrn_31
; {
; *vErroProc = 15;
       move.l    (A2),A0
       move.w    #15,(A0)
; return 0;
       clr.l     D0
       bra.s     basScrn_3
basScrn_31:
; }
; // Ler Aqui.. a cor e devolver em *tval
; *tval = vdp_read_color_pixel(vx,vy);
       move.b    -11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -12(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_read_color_pixel
       addq.w    #8,A7
       and.l     #255,D0
       move.l    -16(A6),A0
       move.l    D0,(A0)
; *value_type='%';
       move.l    (A5),A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basScrn_3:
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; // Syntaxe:
; //
; //--------------------------------------------------------------------------------------
; int basHcolor(void)
; {
       xdef      _basHcolor
_basHcolor:
; if (*vdp_mode != VDP_MODE_G2)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     basHcolor_1
; {
; *vErroProc = 24;
       move.l    _vErroProc.L,A0
       move.w    #24,(A0)
; return 0;
       clr.l     D0
       bra.s     basHcolor_3
basHcolor_1:
; }
; basColor();
       jsr       _basColor
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basHcolor_4
       clr.l     D0
       bra.s     basHcolor_3
basHcolor_4:
; return 0;
       clr.l     D0
basHcolor_3:
       rts
; }
; //--------------------------------------------------------------------------------------
; //
; // Syntaxe:
; //
; //--------------------------------------------------------------------------------------
; int basHplot(void)
; {
       xdef      _basHplot
_basHplot:
       link      A6,#-88
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vErroProc.L,A2
       lea       _value_type.L,A3
; int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
       move.w    #0,A5
       clr.l     -88(A6)
       clr.l     -84(A6)
       clr.l     -80(A6)
; unsigned char answer[20];
; int  *iVal = answer;
       lea       -72(A6),A0
       move.l    A0,A4
; int rivx, rivy;
; unsigned long riy, rlvx, rlvy, vDiag;
; unsigned char vx, vy, vtemp;
; unsigned char sqtdtam[10];
; unsigned char vOper = 0;
       moveq     #0,D7
; int x,y,addx,addy,dx,dy;
; long P;
; if (*vdp_mode != VDP_MODE_G2)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     basHplot_1
; {
; *vErroProc = 24;
       move.l    (A2),A0
       move.w    #24,(A0)
; return 0;
       clr.l     D0
       bra       basHplot_3
basHplot_1:
; }
; do
; {
basHplot_4:
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHplot_6
       clr.l     D0
       bra       basHplot_3
basHplot_6:
; if (*token != 0x86)
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #134,D0
       beq       basHplot_8
; {
; if (*token_type == QUOTE) { // is string, error
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basHplot_10
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHplot_3
basHplot_10:
; }
; else { // is expression
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -72(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHplot_12
       clr.l     D0
       bra       basHplot_3
basHplot_12:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basHplot_14
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHplot_3
basHplot_14:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basHplot_16
; {
; *iVal = fppInt(*iVal);
       move.l    (A4),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D0,(A4)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basHplot_16:
; }
; }
; vx = (unsigned char)*iVal;
       move.l    (A4),D0
       move.b    D0,D6
; if (*token != ',')
       move.l    _token.L,A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq.s     basHplot_18
; {
; *vErroProc = 18;
       move.l    (A2),A0
       move.w    #18,(A0)
; return 0;
       clr.l     D0
       bra       basHplot_3
basHplot_18:
; }
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHplot_20
       clr.l     D0
       bra       basHplot_3
basHplot_20:
; if (*token_type == QUOTE) { // is string, error
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basHplot_22
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHplot_3
basHplot_22:
; }
; else { // is expression
; //putback();
; getExp(&answer);
       pea       -72(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    (A2),A0
       tst.w     (A0)
       beq.s     basHplot_24
       clr.l     D0
       bra       basHplot_3
basHplot_24:
; if (*value_type == '$')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #36,D0
       bne.s     basHplot_26
; {
; *vErroProc = 16;
       move.l    (A2),A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basHplot_3
basHplot_26:
; }
; if (*value_type == '#')
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #35,D0
       bne.s     basHplot_28
; {
; *iVal = fppInt(*iVal);
       move.l    (A4),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D0,(A4)
; *value_type = '%';
       move.l    (A3),A0
       move.b    #37,(A0)
basHplot_28:
; }
; }
; vy = (unsigned char)*iVal;
       move.l    (A4),D0
       move.b    D0,D5
; if (!vOper)
       tst.b     D7
       bne.s     basHplot_30
; vOper = 1;
       moveq     #1,D7
basHplot_30:
       bra       basHplot_9
basHplot_8:
; }
; else
; {
; // *pointerRunProg = *pointerRunProg + 1;
; }
basHplot_9:
; if (*tok == EOL || *tok == FINISHED || *token == 0x86)    // Fim de linha, programa ou token
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basHplot_34
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       beq.s     basHplot_34
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #134,D0
       bne       basHplot_65
basHplot_34:
; {
; if (!vOper)
       tst.b     D7
       bne.s     basHplot_35
; {
; vOper = 2;
       moveq     #2,D7
       bra       basHplot_41
basHplot_35:
; }
; else if (vOper == 1)
       cmp.b     #1,D7
       bne       basHplot_37
; {
; *lastHgrX = vx;
       move.l    _lastHgrX.L,A0
       move.b    D6,(A0)
; *lastHgrY = vy;
       move.l    _lastHgrY.L,A0
       move.b    D5,(A0)
; if (*token != 0x86)
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #134,D0
       beq.s     basHplot_39
; vdp_plot_hires(vx, vy, *fgcolor, *bgcolor);
       move.l    _bgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       jsr       _vdp_plot_hires
       add.w     #16,A7
basHplot_39:
       bra       basHplot_41
basHplot_37:
; }
; else if (vOper == 2)
       cmp.b     #2,D7
       bne       basHplot_41
; {
; if (vx == *lastHgrX && vy == *lastHgrY)
       move.l    _lastHgrX.L,A0
       cmp.b     (A0),D6
       bne       basHplot_43
       move.l    _lastHgrY.L,A0
       cmp.b     (A0),D5
       bne.s     basHplot_43
; vdp_plot_hires(vx, vy, *fgcolor, *bgcolor);
       move.l    _bgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       jsr       _vdp_plot_hires
       add.w     #16,A7
       bra       basHplot_62
basHplot_43:
; else
; {
; dx = (vx - *lastHgrX);
       and.l     #255,D6
       move.l    D6,D0
       move.l    _lastHgrX.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       sub.l     D1,D0
       move.l    D0,D4
; dy = (vy - *lastHgrY);
       and.l     #255,D5
       move.l    D5,D0
       move.l    _lastHgrY.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       sub.l     D1,D0
       move.l    D0,D3
; if (dx < 0)
       cmp.l     #0,D4
       bge.s     basHplot_45
; dx = dx * (-1);
       move.l    D4,-(A7)
       pea       -1
       jsr       LMUL
       move.l    (A7),D4
       addq.w    #8,A7
basHplot_45:
; if (dy < 0)
       cmp.l     #0,D3
       bge.s     basHplot_47
; dy = dy * (-1);
       move.l    D3,-(A7)
       pea       -1
       jsr       LMUL
       move.l    (A7),D3
       addq.w    #8,A7
basHplot_47:
; x = *lastHgrX;
       move.l    _lastHgrX.L,A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    D0,-16(A6)
; y = *lastHgrY;
       move.l    _lastHgrY.L,A0
       move.b    (A0),D0
       and.l     #255,D0
       move.l    D0,-12(A6)
; if(*lastHgrX > vx)
       move.l    _lastHgrX.L,A0
       cmp.b     (A0),D6
       bhs.s     basHplot_49
; addx = -1;
       move.l    #-1,-8(A6)
       bra.s     basHplot_50
basHplot_49:
; else
; addx = 1;
       move.l    #1,-8(A6)
basHplot_50:
; if(*lastHgrY > vy)
       move.l    _lastHgrY.L,A0
       cmp.b     (A0),D5
       bhs.s     basHplot_51
; addy = -1;
       move.l    #-1,-4(A6)
       bra.s     basHplot_52
basHplot_51:
; else
; addy = 1;
       move.l    #1,-4(A6)
basHplot_52:
; if(dx >= dy)
       cmp.l     D3,D4
       blt       basHplot_53
; {
; P = (2 * dy) - dx;
       move.l    D3,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       sub.l     D4,D0
       move.l    D0,D2
; for(ix = 1; ix <= (dx + 1); ix++)
       move.w    #1,A5
basHplot_55:
       move.l    D4,D0
       addq.l    #1,D0
       move.l    A5,D1
       cmp.l     D0,D1
       bgt       basHplot_57
; {
; vdp_plot_hires(x, y, *fgcolor, 0);
       clr.l     -(A7)
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    -12(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    -16(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_plot_hires
       add.w     #16,A7
; if (P < 0)
       cmp.l     #0,D2
       bge.s     basHplot_58
; {
; P = P + (2 * dy);
       move.l    D3,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     D0,D2
; x = (x + addx);
       move.l    -8(A6),D0
       add.l     D0,-16(A6)
       bra       basHplot_59
basHplot_58:
; }
; else
; {
; P = P + (2 * dy) - (2 * dx);
       move.l    D2,D0
       move.l    D3,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.l    D4,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       sub.l     D1,D0
       move.l    D0,D2
; x = x + addx;
       move.l    -8(A6),D0
       add.l     D0,-16(A6)
; y = y + addy;
       move.l    -4(A6),D0
       add.l     D0,-12(A6)
basHplot_59:
       addq.w    #1,A5
       bra       basHplot_55
basHplot_57:
       bra       basHplot_62
basHplot_53:
; }
; }
; }
; else
; {
; P = (2 * dx) - dy;
       move.l    D4,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       sub.l     D3,D0
       move.l    D0,D2
; for(ix = 1; ix <= (dy +1); ix++)
       move.w    #1,A5
basHplot_60:
       move.l    D3,D0
       addq.l    #1,D0
       move.l    A5,D1
       cmp.l     D0,D1
       bgt       basHplot_62
; {
; vdp_plot_hires(x, y, *fgcolor, 0);
       clr.l     -(A7)
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    -12(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    -16(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_plot_hires
       add.w     #16,A7
; if (P < 0)
       cmp.l     #0,D2
       bge.s     basHplot_63
; {
; P = P + (2 * dx);
       move.l    D4,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     D0,D2
; y = y + addy;
       move.l    -4(A6),D0
       add.l     D0,-12(A6)
       bra       basHplot_64
basHplot_63:
; }
; else
; {
; P = P + (2 * dx) - (2 * dy);
       move.l    D2,D0
       move.l    D4,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.l    D3,-(A7)
       pea       2
       jsr       LMUL
       move.l    (A7),D1
       addq.w    #8,A7
       sub.l     D1,D0
       move.l    D0,D2
; x = x + addx;
       move.l    -8(A6),D0
       add.l     D0,-16(A6)
; y = y + addy;
       move.l    -4(A6),D0
       add.l     D0,-12(A6)
basHplot_64:
       addq.w    #1,A5
       bra       basHplot_60
basHplot_62:
; }
; }
; }
; }
; *lastHgrX = vx;
       move.l    _lastHgrX.L,A0
       move.b    D6,(A0)
; *lastHgrY = vy;
       move.l    _lastHgrY.L,A0
       move.b    D5,(A0)
basHplot_41:
; }
; if (*token == 0x86)
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #134,D0
       bne.s     basHplot_65
; {
; *pointerRunProg = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       addq.l    #1,(A0)
basHplot_65:
; }
; }
; vOper = 2;
       moveq     #2,D7
       move.l    _token.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #134,D0
       beq       basHplot_4
; } while (*token == 0x86); // TO Token
; *value_type='%';
       move.l    (A3),A0
       move.b    #37,(A0)
; return 0;
       clr.l     D0
basHplot_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Ler dados no comando DATA
; // Syntaxe:
; //          READ <variavel>
; //--------------------------------------------------------------------------------------
; int basRead(void)
; {
       xdef      _basRead
_basRead:
       link      A6,#-124
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4/A5,-(A7)
       lea       _token.L,A2
       lea       _vDataLineAtu.L,A3
       lea       _vDataPointer.L,A4
       lea       _varName.L,A5
; int ix = 0, iy = 0, iz = 0;
       clr.l     -122(A6)
       clr.l     -118(A6)
       clr.l     -114(A6)
; unsigned char answer[100];
; int  *iVal = answer;
       lea       -110(A6),A0
       move.l    A0,D5
; unsigned char varTipo;
; unsigned char sqtdtam[10];
; unsigned long vTemp;
; unsigned char *vTempLine;
; long vRetFV;
; // Pega a variavel
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basRead_1
       clr.l     D0
       bra       basRead_3
basRead_1:
; if (*tok == EOL || *tok == FINISHED)
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #226,D0
       beq.s     basRead_6
       move.l    _tok.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #224,D0
       bne.s     basRead_4
basRead_6:
; {
; *vErroProc = 4;
       move.l    _vErroProc.L,A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basRead_3
basRead_4:
; }
; if (*token_type == QUOTE) { /* is string */
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basRead_7
; *vErroProc = 4;
       move.l    _vErroProc.L,A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basRead_3
basRead_7:
; }
; else { /* is expression */
; // Verifica se comeca com letra, pois tem que ser uma variavel
; if (!isalphas(*token))
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       bne.s     basRead_9
; {
; *vErroProc = 4;
       move.l    _vErroProc.L,A0
       move.w    #4,(A0)
; return 0;
       clr.l     D0
       bra       basRead_3
basRead_9:
; }
; if (strlen(token) < 3)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #3,D0
       bge       basRead_11
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A5),A1
       move.b    (A0),(A1)
; varTipo = VARTYPEDEFAULT;
       moveq     #35,D3
; if (strlen(token) == 2 && *(token + 1) < 0x30)
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basRead_13
       move.l    (A2),A0
       move.b    1(A0),D0
       cmp.b     #48,D0
       bhs.s     basRead_13
; varTipo = *(token + 1);
       move.l    (A2),A0
       move.b    1(A0),D3
basRead_13:
; if (strlen(token) == 2 && isalphas(*(token + 1)))
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #2,D0
       bne.s     basRead_15
       move.l    (A2),A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _isalphas
       addq.w    #4,A7
       tst.l     D0
       beq.s     basRead_15
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A5),A1
       move.b    1(A0),1(A1)
       bra.s     basRead_16
basRead_15:
; else
; *(varName + 1) = 0x00;
       move.l    (A5),A0
       clr.b     1(A0)
basRead_16:
; *(varName + 2) = varTipo;
       move.l    (A5),A0
       move.b    D3,2(A0)
       bra       basRead_12
basRead_11:
; }
; else
; {
; *varName = *token;
       move.l    (A2),A0
       move.l    (A5),A1
       move.b    (A0),(A1)
; *(varName + 1) = *(token + 1);
       move.l    (A2),A0
       move.l    (A5),A1
       move.b    1(A0),1(A1)
; *(varName + 2) = *(token + 2);
       move.l    (A2),A0
       move.l    (A5),A1
       move.b    2(A0),2(A1)
; iz = strlen(token) - 1;
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       subq.l    #1,D0
       move.l    D0,-114(A6)
; varTipo = *(varName + 2);
       move.l    (A5),A0
       move.b    2(A0),D3
basRead_12:
; }
; }
; // Procurar Data
; if (*vDataPointer == 0)
       move.l    (A4),A0
       move.l    (A0),D0
       bne       basRead_20
; {
; // Primeira Leitura, procura primeira ocorrencia
; *vDataLineAtu = *addrFirstLineNumber;
       move.l    _addrFirstLineNumber.L,A0
       move.l    (A3),A1
       move.l    (A0),(A1)
; do
; {
basRead_19:
; *vDataPointer = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A4),A1
       move.l    (A0),(A1)
; vTempLine = *vDataPointer;
       move.l    (A4),A0
       move.l    (A0),D2
; if (*(vTempLine + 5) == 0x98)    // Token do comando DATA é o primeiro comando da linha
       move.l    D2,A0
       move.b    5(A0),D0
       and.w     #255,D0
       cmp.w     #152,D0
       bne.s     basRead_21
; {
; *vDataPointer = (*vDataLineAtu + 6);
       move.l    (A3),A0
       move.l    (A0),D0
       addq.l    #6,D0
       move.l    (A4),A0
       move.l    D0,(A0)
; *vDataFirst = *vDataLineAtu;
       move.l    (A3),A0
       move.l    _vDataFirst.L,A1
       move.l    (A0),(A1)
; break;
       bra       basRead_20
basRead_21:
; }
; vTempLine = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A0),D2
; vTemp  = ((*vTempLine & 0xFF) << 16);
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       and.l     #255,D0
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,D4
; vTemp |= ((*(vTempLine + 1) & 0xFF) << 8);
       move.l    D2,A0
       move.b    1(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       asl.l     #8,D0
       or.l      D0,D4
; vTemp |= (*(vTempLine + 2) & 0xFF);
       move.l    D2,A0
       move.b    2(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       or.l      D0,D4
; *vDataLineAtu = vTemp;
       move.l    (A3),A0
       move.l    D4,(A0)
; vTempLine = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A0),D2
       move.l    D2,A0
       tst.b     (A0)
       bne       basRead_19
basRead_20:
; } while (*vTempLine);
; }
; if (*vDataPointer == 0xFFFFFFFF)
       move.l    (A4),A0
       move.l    (A0),D0
       cmp.l     #-1,D0
       bne.s     basRead_23
; {
; *vErroProc = 26;
       move.l    _vErroProc.L,A0
       move.w    #26,(A0)
; return 0;
       clr.l     D0
       bra       basRead_3
basRead_23:
; }
; *vDataBkpPointerProg = *pointerRunProg;
       move.l    _pointerRunProg.L,A0
       move.l    _vDataBkpPointerProg.L,A1
       move.l    (A0),(A1)
; *pointerRunProg = *vDataPointer;
       move.l    (A4),A0
       move.l    _pointerRunProg.L,A1
       move.l    (A0),(A1)
; nextToken();
       jsr       _nextToken
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basRead_25
       clr.l     D0
       bra       basRead_3
basRead_25:
; if (*token_type == QUOTE) {
       move.l    _token_type.L,A0
       move.b    (A0),D0
       cmp.b     #6,D0
       bne.s     basRead_27
; strcpy(answer,token);
       move.l    (A2),-(A7)
       pea       -110(A6)
       jsr       _strcpy
       addq.w    #8,A7
; *value_type = '$';
       move.l    _value_type.L,A0
       move.b    #36,(A0)
       bra.s     basRead_29
basRead_27:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; getExp(&answer);
       pea       -110(A6)
       jsr       _getExp
       addq.w    #4,A7
; if (*vErroProc) return 0;
       move.l    _vErroProc.L,A0
       tst.w     (A0)
       beq.s     basRead_29
       clr.l     D0
       bra       basRead_3
basRead_29:
; }
; // Pega ponteiro atual (proximo numero/char)
; *vDataPointer = *pointerRunProg + 1;
       move.l    _pointerRunProg.L,A0
       move.l    (A0),D0
       addq.l    #1,D0
       move.l    (A4),A0
       move.l    D0,(A0)
; // Devolve ponteiro anterior
; *pointerRunProg = *vDataBkpPointerProg;
       move.l    _vDataBkpPointerProg.L,A0
       move.l    _pointerRunProg.L,A1
       move.l    (A0),(A1)
; // Se nao foi virgula, é final de linha, procura proximo comando data
; if (*token != ',')
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #44,D0
       beq       basRead_34
; {
; do
; {
basRead_33:
; vTempLine = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A0),D2
; vTemp  = ((*(vTempLine) & 0xFF) << 16);
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       and.l     #255,D0
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,D4
; vTemp |= ((*(vTempLine + 1) & 0xFF) << 8);
       move.l    D2,A0
       move.b    1(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       asl.l     #8,D0
       or.l      D0,D4
; vTemp |= (*(vTempLine + 2) & 0xFF);
       move.l    D2,A0
       move.b    2(A0),D0
       and.l     #255,D0
       and.l     #255,D0
       or.l      D0,D4
; *vDataLineAtu = vTemp;
       move.l    (A3),A0
       move.l    D4,(A0)
; vTempLine = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A0),D2
; if (!*vDataLineAtu)
       move.l    (A3),A0
       tst.l     (A0)
       bne.s     basRead_35
; {
; *vDataPointer = 0xFFFFFFFF;
       move.l    (A4),A0
       move.l    #-1,(A0)
; break;
       bra       basRead_34
basRead_35:
; }
; *vDataPointer = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A4),A1
       move.l    (A0),(A1)
; vTempLine = *vDataPointer;
       move.l    (A4),A0
       move.l    (A0),D2
; if (*(vTempLine + 5) == 0x98)    // Token do comando DATA é o primeiro comando da linha
       move.l    D2,A0
       move.b    5(A0),D0
       and.w     #255,D0
       cmp.w     #152,D0
       bne.s     basRead_37
; {
; *vDataPointer = (*vDataLineAtu + 6);
       move.l    (A3),A0
       move.l    (A0),D0
       addq.l    #6,D0
       move.l    (A4),A0
       move.l    D0,(A0)
; break;
       bra.s     basRead_34
basRead_37:
; }
; vTempLine = *vDataLineAtu;
       move.l    (A3),A0
       move.l    (A0),D2
       move.l    D2,A0
       tst.b     (A0)
       bne       basRead_33
basRead_34:
; } while (*vTempLine);
; }
; if (varTipo != *value_type)
       move.l    _value_type.L,A0
       cmp.b     (A0),D3
       beq       basRead_39
; {
; if (*value_type == '$' || varTipo == '$')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #36,D0
       beq.s     basRead_43
       cmp.b     #36,D3
       bne.s     basRead_41
basRead_43:
; {
; *vErroProc = 16;
       move.l    _vErroProc.L,A0
       move.w    #16,(A0)
; return 0;
       clr.l     D0
       bra       basRead_3
basRead_41:
; }
; if (*value_type == '%')
       move.l    _value_type.L,A0
       move.b    (A0),D0
       cmp.b     #37,D0
       bne.s     basRead_44
; *iVal = fppReal(*iVal);
       move.l    D5,A0
       move.l    (A0),-(A7)
       jsr       _fppReal
       addq.w    #4,A7
       move.l    D5,A0
       move.l    D0,(A0)
       bra.s     basRead_45
basRead_44:
; else
; *iVal = fppInt(*iVal);
       move.l    D5,A0
       move.l    (A0),-(A7)
       jsr       _fppInt
       addq.w    #4,A7
       move.l    D5,A0
       move.l    D0,(A0)
basRead_45:
; *value_type = varTipo;
       move.l    _value_type.L,A0
       move.b    D3,(A0)
basRead_39:
; }
; // assign the value
; vRetFV = findVariable(varName);
       move.l    (A5),-(A7)
       jsr       _findVariable
       addq.w    #4,A7
       move.l    D0,D6
; // Se nao existe variavel e inicio sentenca, cria variavel e atribui o valor
; if (!vRetFV)
       tst.l     D6
       bne.s     basRead_46
; createVariable(varName, answer, varTipo);
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       pea       -110(A6)
       move.l    (A5),-(A7)
       jsr       _createVariable
       add.w     #12,A7
       bra.s     basRead_47
basRead_46:
; else // se ja existe, altera
; updateVariable((vRetFV + 3), answer, varTipo, 1);
       pea       1
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       pea       -110(A6)
       move.l    D6,D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _updateVariable
       add.w     #16,A7
basRead_47:
; return 0;
       clr.l     D0
basRead_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //--------------------------------------------------------------------------------------
; // Volta ponteiro do READ para o primeiro item dos comandos DATA
; // Syntaxe:
; //          RESTORE
; //--------------------------------------------------------------------------------------
; int basRestore(void)
; {
       xdef      _basRestore
_basRestore:
; *vDataLineAtu = *vDataFirst;
       move.l    _vDataFirst.L,A0
       move.l    _vDataLineAtu.L,A1
       move.l    (A0),(A1)
; *vDataPointer = (*vDataLineAtu + 6);
       move.l    _vDataLineAtu.L,A0
       move.l    (A0),D0
       addq.l    #6,D0
       move.l    _vDataPointer.L,A0
       move.l    D0,(A0)
; return 0;
       clr.l     D0
       rts
; }
; #endif
       section   const
@basic_1:
       dc.b      63,114,101,115,101,114,118,101,100,32,48,0
@basic_2:
       dc.b      63,83,116,111,112,112,101,100,0
@basic_3:
       dc.b      63,78,111,32,101,120,112,114,101,115,115,105
       dc.b      111,110,32,112,114,101,115,101,110,116,0
@basic_4:
       dc.b      63,69,113,117,97,108,115,32,115,105,103,110
       dc.b      32,101,120,112,101,99,116,101,100,0
@basic_5:
       dc.b      63,78,111,116,32,97,32,118,97,114,105,97,98
       dc.b      108,101,0
@basic_6:
       dc.b      63,79,117,116,32,111,102,32,114,97,110,103,101
       dc.b      0
@basic_7:
       dc.b      63,73,108,108,101,103,97,108,32,113,117,97,110
       dc.b      116,105,116,121,0
@basic_8:
       dc.b      63,76,105,110,101,32,110,111,116,32,102,111
       dc.b      117,110,100,0
@basic_9:
       dc.b      63,84,72,69,78,32,101,120,112,101,99,116,101
       dc.b      100,0
@basic_10:
       dc.b      63,84,79,32,101,120,112,101,99,116,101,100,0
@basic_11:
       dc.b      63,84,111,111,32,109,97,110,121,32,110,101,115
       dc.b      116,101,100,32,70,79,82,32,108,111,111,112,115
       dc.b      0
@basic_12:
       dc.b      63,78,69,88,84,32,119,105,116,104,111,117,116
       dc.b      32,70,79,82,0
@basic_13:
       dc.b      63,84,111,111,32,109,97,110,121,32,110,101,115
       dc.b      116,101,100,32,71,79,83,85,66,115,0
@basic_14:
       dc.b      63,82,69,84,85,82,78,32,119,105,116,104,111
       dc.b      117,116,32,71,79,83,85,66,0
@basic_15:
       dc.b      63,83,121,110,116,97,120,32,101,114,114,111
       dc.b      114,0
@basic_16:
       dc.b      63,85,110,98,97,108,97,110,99,101,100,32,112
       dc.b      97,114,101,110,116,104,101,115,101,115,0
@basic_17:
       dc.b      63,73,110,99,111,109,112,97,116,105,98,108,101
       dc.b      32,116,121,112,101,115,0
@basic_18:
       dc.b      63,76,105,110,101,32,110,117,109,98,101,114
       dc.b      32,101,120,112,101,99,116,101,100,0
@basic_19:
       dc.b      63,67,111,109,109,97,32,69,115,112,101,99,116
       dc.b      101,100,0
@basic_20:
       dc.b      63,84,105,109,101,111,117,116,0
@basic_21:
       dc.b      63,76,111,97,100,32,119,105,116,104,32,69,114
       dc.b      114,111,114,115,0
@basic_22:
       dc.b      63,83,105,122,101,32,101,114,114,111,114,0
@basic_23:
       dc.b      63,79,117,116,32,111,102,32,109,101,109,111
       dc.b      114,121,0
@basic_24:
       dc.b      63,86,97,114,105,97,98,108,101,32,110,97,109
       dc.b      101,32,97,108,114,101,97,100,121,32,101,120
       dc.b      105,115,116,0
@basic_25:
       dc.b      63,87,114,111,110,103,32,109,111,100,101,32
       dc.b      114,101,115,111,108,117,116,105,111,110,0
@basic_26:
       dc.b      63,73,108,108,101,103,97,108,32,112,111,115
       dc.b      105,116,105,111,110,0
@basic_27:
       dc.b      63,79,117,116,32,111,102,32,100,97,116,97,0
@basic_28:
       dc.b      76,69,84,0
@basic_29:
       dc.b      80,82,73,78,84,0
@basic_30:
       dc.b      73,70,0
@basic_31:
       dc.b      84,72,69,78,0
@basic_32:
       dc.b      70,79,82,0
@basic_33:
       dc.b      84,79,0
@basic_34:
       dc.b      78,69,88,84,0
@basic_35:
       dc.b      83,84,69,80,0
@basic_36:
       dc.b      71,79,84,79,0
@basic_37:
       dc.b      71,79,83,85,66,0
@basic_38:
       dc.b      82,69,84,85,82,78,0
@basic_39:
       dc.b      82,69,77,0
@basic_40:
       dc.b      73,78,86,69,82,83,69,0
@basic_41:
       dc.b      78,79,82,77,65,76,0
@basic_42:
       dc.b      68,73,77,0
@basic_43:
       dc.b      79,78,0
@basic_44:
       dc.b      73,78,80,85,84,0
@basic_45:
       dc.b      71,69,84,0
@basic_46:
       dc.b      86,84,65,66,0
@basic_47:
       dc.b      72,84,65,66,0
@basic_48:
       dc.b      72,79,77,69,0
@basic_49:
       dc.b      67,76,69,65,82,0
@basic_50:
       dc.b      68,65,84,65,0
@basic_51:
       dc.b      82,69,65,68,0
@basic_52:
       dc.b      82,69,83,84,79,82,69,0
@basic_53:
       dc.b      69,78,68,0
@basic_54:
       dc.b      83,84,79,80,0
@basic_55:
       dc.b      84,69,88,84,0
@basic_56:
       dc.b      71,82,0
@basic_57:
       dc.b      72,71,82,0
@basic_58:
       dc.b      67,79,76,79,82,0
@basic_59:
       dc.b      80,76,79,84,0
@basic_60:
       dc.b      72,76,73,78,0
@basic_61:
       dc.b      86,76,73,78,0
@basic_62:
       dc.b      72,67,79,76,79,82,0
@basic_63:
       dc.b      72,80,76,79,84,0
@basic_64:
       dc.b      65,84,0
@basic_65:
       dc.b      79,78,69,82,82,0
@basic_66:
       dc.b      65,83,67,0
@basic_67:
       dc.b      80,69,69,75,0
@basic_68:
       dc.b      80,79,75,69,0
@basic_69:
       dc.b      82,78,68,0
@basic_70:
       dc.b      76,69,78,0
@basic_71:
       dc.b      86,65,76,0
@basic_72:
       dc.b      83,84,82,36,0
@basic_73:
       dc.b      83,67,82,78,0
@basic_74:
       dc.b      67,72,82,36,0
@basic_75:
       dc.b      70,82,69,0
@basic_76:
       dc.b      83,81,82,84,0
@basic_77:
       dc.b      83,73,78,0
@basic_78:
       dc.b      67,79,83,0
@basic_79:
       dc.b      84,65,78,0
@basic_80:
       dc.b      76,79,71,0
@basic_81:
       dc.b      69,88,80,0
@basic_82:
       dc.b      83,80,67,0
@basic_83:
       dc.b      84,65,66,0
@basic_84:
       dc.b      77,73,68,36,0
@basic_85:
       dc.b      82,73,71,72,84,36,0
@basic_86:
       dc.b      76,69,70,84,36,0
@basic_87:
       dc.b      73,78,84,0
@basic_88:
       dc.b      65,66,83,0
@basic_89:
       dc.b      65,78,68,0
@basic_90:
       dc.b      79,82,0
@basic_91:
       dc.b      62,61,0
@basic_92:
       dc.b      60,61,0
@basic_93:
       dc.b      60,62,0
@basic_94:
       dc.b      78,79,84,0
@basic_95:
       dc.b      77,77,83,74,45,66,65,83,73,67,32,118,49,46,48
       dc.b      101,0
@basic_96:
       dc.b      13,10,0
@basic_97:
       dc.b      85,116,105,108,105,116,121,32,40,99,41,32,50
       dc.b      48,50,50,45,50,48,50,52,13,10,0
@basic_98:
       dc.b      79,75,13,10,0
@basic_99:
       dc.b      13,10,79,75,0
@basic_100:
       dc.b      78,69,87,0
@basic_101:
       dc.b      69,68,73,84,0
@basic_102:
       dc.b      76,73,83,84,0
@basic_103:
       dc.b      76,73,83,84,80,0
@basic_104:
       dc.b      82,85,78,0
@basic_105:
       dc.b      68,69,76,0
@basic_106:
       dc.b      88,76,79,65,68,0
@basic_107:
       dc.b      84,73,77,69,82,0
@basic_108:
       dc.b      84,105,109,101,114,58,32,0
@basic_109:
       dc.b      109,115,13,10,0
@basic_110:
       dc.b      84,82,65,67,69,0
@basic_111:
       dc.b      78,79,84,82,65,67,69,0
@basic_112:
       dc.b      81,85,73,84,0
@basic_113:
       dc.b      32,0
@basic_114:
       dc.b      32,59,44,43,45,60,62,40,41,47,42,94,61,58,0
@basic_115:
       dc.b      76,105,110,101,32,110,117,109,98,101,114,32
       dc.b      97,108,114,101,97,100,121,32,101,120,105,115
       dc.b      116,115,13,10,0
@basic_116:
       dc.b      78,111,110,45,101,120,105,115,116,101,110,116
       dc.b      32,108,105,110,101,32,110,117,109,98,101,114
       dc.b      13,10,0
@basic_117:
       dc.b      112,114,101,115,115,32,97,110,121,32,107,101
       dc.b      121,32,116,111,32,99,111,110,116,105,110,117
       dc.b      101,0
@basic_118:
       dc.b      64,0
@basic_119:
       dc.b      83,121,110,116,97,120,32,69,114,114,111,114
       dc.b      32,33,0
@basic_120:
       dc.b      13,10,65,98,111,114,116,101,100,32,33,33,33
       dc.b      13,10,0
@basic_121:
       dc.b      13,10,83,116,111,112,112,101,100,32,97,116,32
       dc.b      0
@basic_122:
       dc.b      13,10,69,120,101,99,117,116,105,110,103,32,97
       dc.b      116,32,0
@basic_123:
       dc.b      32,97,116,32,0
@basic_124:
       dc.b      32,33,13,10,0
@basic_125:
       dc.b      43,45,42,94,47,61,59,58,44,62,60,0
@basic_126:
       dc.b      58,0
@basic_127:
       dc.b      76,111,97,100,105,110,103,32,66,97,115,105,99
       dc.b      32,80,114,111,103,114,97,109,46,46,46,13,10
       dc.b      0
@basic_128:
       dc.b      56,56,48,48,48,48,0
@basic_129:
       dc.b      68,111,110,101,46,13,10,0
@basic_130:
       dc.b      80,114,111,99,101,115,115,105,110,103,46,46
       dc.b      46,13,10,0
@basic_131:
       dc.b      65,113,117,105,32,52,52,52,46,54,54,54,46,48
       dc.b      45,91,0
@basic_132:
       dc.b      93,13,10,0
@basic_133:
       dc.b      65,113,117,105,32,52,52,52,46,54,54,54,46,49
       dc.b      45,91,0
@basic_134:
       dc.b      93,45,91,0
@basic_135:
       dc.b      65,113,117,105,32,52,52,52,46,54,54,54,46,50
       dc.b      45,91,0
@basic_136:
       dc.b      65,113,117,105,32,52,52,52,46,54,54,54,46,51
       dc.b      45,91,0
@basic_137:
       dc.b      65,113,117,105,32,52,52,52,46,54,54,54,46,52
       dc.b      45,91,0
@basic_138:
       dc.b      65,113,117,105,32,51,51,51,46,54,54,54,46,48
       dc.b      45,91,0
@basic_139:
       dc.b      65,113,117,105,32,51,51,51,46,54,54,54,46,49
       dc.b      45,91,0
@basic_140:
       dc.b      77,101,109,111,114,121,32,70,114,101,101,32
       dc.b      102,111,114,58,32,13,10,0
@basic_141:
       dc.b      32,32,32,32,32,86,97,114,105,97,98,108,101,115
       dc.b      58,32,0
@basic_142:
       dc.b      66,121,116,101,115,13,10,0
@basic_143:
       dc.b      32,32,32,32,32,32,32,32,65,114,114,97,121,115
       dc.b      58,32,0
@basic_144:
       dc.b      32,32,32,32,32,32,32,80,114,111,103,114,97,109
       dc.b      58,32,0
       xdef      _keywords_count
_keywords_count:
       dc.l      67
@basic_keywords:
       dc.l      @basic_28,128,@basic_29,129,@basic_30,130
       dc.l      @basic_31,131,@basic_32,133,@basic_33,134
       dc.l      @basic_34,135,@basic_35,136,@basic_36,137
       dc.l      @basic_37,138,@basic_38,139,@basic_39,140
       dc.l      @basic_40,141,@basic_41,142,@basic_42,143
       dc.l      @basic_43,145,@basic_44,146,@basic_45,147
       dc.l      @basic_46,148,@basic_47,149,@basic_48,150
       dc.l      @basic_49,151,@basic_50,152,@basic_51,153
       dc.l      @basic_52,154,@basic_53,158,@basic_54,159
       dc.l      @basic_55,176,@basic_56,177,@basic_57,178
       dc.l      @basic_58,179,@basic_59,180,@basic_60,181
       dc.l      @basic_61,182,@basic_62,184,@basic_63,185
       dc.l      @basic_64,186,@basic_65,187,@basic_66,196
       dc.l      @basic_67,205,@basic_68,206,@basic_69,209
       dc.l      @basic_70,219,@basic_71,220,@basic_72,221
       dc.l      @basic_73,224,@basic_74,225,@basic_75,226
       dc.l      @basic_76,227,@basic_77,228,@basic_78,229
       dc.l      @basic_79,230,@basic_80,231,@basic_81,232
       dc.l      @basic_82,233,@basic_83,234,@basic_84,235
       dc.l      @basic_85,236,@basic_86,237,@basic_87,238
       dc.l      @basic_88,239,@basic_89,243,@basic_90,244
       dc.l      @basic_91,245,@basic_92,246,@basic_93,247
       dc.l      @basic_94,248
       xdef      _operandsWithTokens
_operandsWithTokens:
       dc.b      43,45,42,47,94,62,61,60,0
       section   data
       xdef      _vmfp
_vmfp:
       dc.l      4194336
       xdef      _vvdgd
_vvdgd:
       dc.l      4194369
       xdef      _vvdgc
_vvdgc:
       dc.l      4194371
       xdef      _vdest
_vdest:
       dc.l      0
       xdef      _fgcolor
_fgcolor:
       dc.l      6356992
       xdef      _bgcolor
_bgcolor:
       dc.l      6363136
       xdef      _videoBufferQtdY
_videoBufferQtdY:
       dc.l      6363138
       xdef      _color_table_size
_color_table_size:
       dc.l      6363140
       xdef      _color_table
_color_table:
       dc.l      6363142
       xdef      _sprite_attribute_table
_sprite_attribute_table:
       dc.l      6363150
       xdef      _videoFontes
_videoFontes:
       dc.l      6363158
       xdef      _videoCursorPosCol
_videoCursorPosCol:
       dc.l      6363166
       xdef      _videoCursorPosRow
_videoCursorPosRow:
       dc.l      6363168
       xdef      _videoCursorPosColX
_videoCursorPosColX:
       dc.l      6363170
       xdef      _videoCursorPosRowY
_videoCursorPosRowY:
       dc.l      6363172
       xdef      _videoCursorBlink
_videoCursorBlink:
       dc.l      6363174
       xdef      _videoCursorShow
_videoCursorShow:
       dc.l      6363176
       xdef      _name_table
_name_table:
       dc.l      6363178
       xdef      _vdp_mode
_vdp_mode:
       dc.l      6363186
       xdef      _videoScroll
_videoScroll:
       dc.l      6363188
       xdef      _videoScrollDir
_videoScrollDir:
       dc.l      6363190
       xdef      _pattern_table
_pattern_table:
       dc.l      6363192
       xdef      _sprite_size_sel
_sprite_size_sel:
       dc.l      6363200
       xdef      _vdpMaxCols
_vdpMaxCols:
       dc.l      6363202
       xdef      _sprite_pattern_table
_sprite_pattern_table:
       dc.l      6363204
       xdef      _vdpMaxRows
_vdpMaxRows:
       dc.l      6363206
       xdef      _fgcolorAnt
_fgcolorAnt:
       dc.l      6363208
       xdef      _bgcolorAnt
_bgcolorAnt:
       dc.l      6363210
       xdef      _kbdKeyPntr
_kbdKeyPntr:
       dc.l      6331163
       xdef      _kbdKeyBuffer
_kbdKeyBuffer:
       dc.l      6331164
       xdef      _kbdvprim
_kbdvprim:
       dc.l      6331196
       xdef      _kbdvmove
_kbdvmove:
       dc.l      6331198
       xdef      _kbdvshift
_kbdvshift:
       dc.l      6331200
       xdef      _kbdvctrl
_kbdvctrl:
       dc.l      6331202
       xdef      _kbdvalt
_kbdvalt:
       dc.l      6331204
       xdef      _kbdvcaps
_kbdvcaps:
       dc.l      6331206
       xdef      _kbdvnum
_kbdvnum:
       dc.l      6331208
       xdef      _kbdvscr
_kbdvscr:
       dc.l      6331210
       xdef      _kbdvreleased
_kbdvreleased:
       dc.l      6331212
       xdef      _kbdve0
_kbdve0:
       dc.l      6331214
       xdef      _kbdScanCodeBuf
_kbdScanCodeBuf:
       dc.l      6331216
       xdef      _kbdScanCodeCount
_kbdScanCodeCount:
       dc.l      6331234
       xdef      _kbdClockCount
_kbdClockCount:
       dc.l      6331236
       xdef      _scanCode
_scanCode:
       dc.l      6331238
       xdef      _vxmaxold
_vxmaxold:
       dc.l      6331240
       xdef      _vymaxold
_vymaxold:
       dc.l      6331242
       xdef      _voverx
_voverx:
       dc.l      6331244
       xdef      _vovery
_vovery:
       dc.l      6331246
       xdef      _vparamstr
_vparamstr:
       dc.l      6331248
       xdef      _vparam
_vparam:
       dc.l      6331504
       xdef      _vbbutton
_vbbutton:
       dc.l      6331562
       xdef      _vkeyopen
_vkeyopen:
       dc.l      6331564
       xdef      _vbytetec
_vbytetec:
       dc.l      6331566
       xdef      _pposx
_pposx:
       dc.l      6331568
       xdef      _pposy
_pposy:
       dc.l      6331570
       xdef      _vbuttonwiny
_vbuttonwiny:
       dc.l      6331574
       xdef      _vbuttonwin
_vbuttonwin:
       dc.l      6331576
       xdef      _vpostx
_vpostx:
       dc.l      6331584
       xdef      _vposty
_vposty:
       dc.l      6331586
       xdef      _next_pos
_next_pos:
       dc.l      6331598
       xdef      _viconef
_viconef:
       dc.l      6332408
       xdef      _vcorf
_vcorf:
       dc.l      6344700
       xdef      _vcorb
_vcorb:
       dc.l      6344702
       xdef      _vcol
_vcol:
       dc.l      6344704
       xdef      _vlin
_vlin:
       dc.l      6344706
       xdef      _voutput
_voutput:
       dc.l      6344708
       xdef      _vxmax
_vxmax:
       dc.l      6344742
       xdef      _vymax
_vymax:
       dc.l      6344744
       xdef      _xpos
_xpos:
       dc.l      6344746
       xdef      _ypos
_ypos:
       dc.l      6344748
       xdef      _vinip
_vinip:
       dc.l      6344896
       xdef      _vbufk
_vbufk:
       dc.l      6344898
       xdef      _vbufkptr
_vbufkptr:
       dc.l      6344898
       xdef      _vbufkmove
_vbufkmove:
       dc.l      6344898
       xdef      _vbufkatu
_vbufkatu:
       dc.l      6344898
       xdef      _vbufkbios
_vbufkbios:
       dc.l      6344930
       xdef      _inten
_inten:
       dc.l      6344944
       xdef      _vxgmax
_vxgmax:
       dc.l      6344946
       xdef      _vygmax
_vygmax:
       dc.l      6344950
       xdef      _vmtaskatu
_vmtaskatu:
       dc.l      6348708
       xdef      _vmtask
_vmtask:
       dc.l      6348708
       xdef      _vmtaskup
_vmtaskup:
       dc.l      6348708
       xdef      _intpos
_intpos:
       dc.l      6348792
       xdef      _vtotmem
_vtotmem:
       dc.l      6348796
       xdef      _v10ms
_v10ms:
       dc.l      6348798
       xdef      _vPS2
_vPS2:
       dc.l      6348800
       xdef      _vBufXmitEmpty
_vBufXmitEmpty:
       dc.l      6348802
       xdef      _vBufReceived
_vBufReceived:
       dc.l      6348804
       xdef      _vbuf
_vbuf:
       dc.l      6348806
       xdef      _errorBufferAddrBus
_errorBufferAddrBus:
       dc.l      6349320
       xdef      _traceData
_traceData:
       dc.l      6349450
       xdef      _tracePointer
_tracePointer:
       dc.l      6350476
       xdef      _traceA7
_traceA7:
       dc.l      6350482
       xdef      _regA7
_regA7:
       dc.l      6350486
       xdef      _startBasic
_startBasic:
       dc.l      6350490
       xdef      _ascii
_ascii:
       dc.b      97,98,99,100,101,102,103,104,105,106,107,108
       dc.b      109,110,111,112,113,114,115,116,117,118,119
       dc.b      120,121,122,48,49,50,51,52,53,54,55,56,57,59
       dc.b      61,46,44,47,39,91,93,96,45,32,0
       xdef      _ascii2
_ascii2:
       dc.b      65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
       dc.b      80,81,82,83,84,85,86,87,88,89,90,41,33,64,35
       dc.b      36,37,94,38,42,40,58,43,62,60,63,32,123,125
       dc.b      126,95,32,0
       xdef      _ascii3
_ascii3:
       dc.b      65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
       dc.b      80,81,82,83,84,85,86,87,88,89,90,48,49,50,51
       dc.b      52,53,54,55,56,57,59,61,46,44,47,39,91,93,96
       dc.b      45,32,0
       xdef      _ascii4
_ascii4:
       dc.b      97,98,99,100,101,102,103,104,105,106,107,108
       dc.b      109,110,111,112,113,114,115,116,117,118,119
       dc.b      120,121,122,41,33,64,35,36,37,94,38,42,40,58
       dc.b      43,62,60,63,32,123,125,126,95,32,0
       xdef      _keyCode
_keyCode:
       dc.b      28,50,33,35,36,43,52,51,67,59,66,75,58,49,68
       dc.b      77,21,45,27,44,60,42,29,34,53,26,69,22,30,38
       dc.b      37,46,54,61,62,70,76,85,73,65,74,82,84,91,14
       dc.b      78,41,0
       xdef      _Reg_UCR
_Reg_UCR:
       dc.w      5121
       xdef      _Reg_UDR
_Reg_UDR:
       dc.w      5889
       xdef      _Reg_RSR
_Reg_RSR:
       dc.w      5377
       xdef      _Reg_TSR
_Reg_TSR:
       dc.w      5633
       xdef      _Reg_VR
_Reg_VR:
       dc.w      2817
       xdef      _Reg_IERA
_Reg_IERA:
       dc.w      769
       xdef      _Reg_IERB
_Reg_IERB:
       dc.w      1025
       xdef      _Reg_IPRA
_Reg_IPRA:
       dc.w      1281
       xdef      _Reg_IPRB
_Reg_IPRB:
       dc.w      1537
       xdef      _Reg_IMRA
_Reg_IMRA:
       dc.w      2305
       xdef      _Reg_IMRB
_Reg_IMRB:
       dc.w      2561
       xdef      _Reg_ISRA
_Reg_ISRA:
       dc.w      1793
       xdef      _Reg_ISRB
_Reg_ISRB:
       dc.w      2049
       xdef      _Reg_TADR
_Reg_TADR:
       dc.w      3841
       xdef      _Reg_TBDR
_Reg_TBDR:
       dc.w      4097
       xdef      _Reg_TCDR
_Reg_TCDR:
       dc.w      4353
       xdef      _Reg_TDDR
_Reg_TDDR:
       dc.w      4609
       xdef      _Reg_TACR
_Reg_TACR:
       dc.w      3073
       xdef      _Reg_TBCR
_Reg_TBCR:
       dc.w      3329
       xdef      _Reg_TCDCR
_Reg_TCDCR:
       dc.w      3585
       xdef      _Reg_GPDR
_Reg_GPDR:
       dc.w      1
       xdef      _Reg_AER
_Reg_AER:
       dc.w      257
       xdef      _Reg_DDR
_Reg_DDR:
       dc.w      513
       xdef      _pStartSimpVar
_pStartSimpVar:
       dc.l      8388608
       xdef      _pStartArrayVar
_pStartArrayVar:
       dc.l      8400896
       xdef      _pStartString
_pStartString:
       dc.l      8433664
       xdef      _pStartProg
_pStartProg:
       dc.l      8519680
       xdef      _pStartXBasLoad
_pStartXBasLoad:
       dc.l      8912896
       xdef      _pStartStack
_pStartStack:
       dc.l      9428992
       xdef      _pProcess
_pProcess:
       dc.l      9437182
       xdef      _pTypeLine
_pTypeLine:
       dc.l      9437180
       xdef      _nextAddrLine
_nextAddrLine:
       dc.l      9437176
       xdef      _firstLineNumber
_firstLineNumber:
       dc.l      9437174
       xdef      _addrFirstLineNumber
_addrFirstLineNumber:
       dc.l      9437170
       xdef      _addrLastLineNumber
_addrLastLineNumber:
       dc.l      9437166
       xdef      _nextAddr
_nextAddr:
       dc.l      9437162
       xdef      _nextAddrSimpVar
_nextAddrSimpVar:
       dc.l      9437158
       xdef      _nextAddrArrayVar
_nextAddrArrayVar:
       dc.l      9437154
       xdef      _nextAddrString
_nextAddrString:
       dc.l      9437150
       xdef      _comandLineTokenized
_comandLineTokenized:
       dc.l      9436895
       xdef      _vParenteses
_vParenteses:
       dc.l      9436893
       xdef      _vInicioSentenca
_vInicioSentenca:
       dc.l      9436891
       xdef      _vMaisTokens
_vMaisTokens:
       dc.l      9436889
       xdef      _vTemIf
_vTemIf:
       dc.l      9436887
       xdef      _doisPontos
_doisPontos:
       dc.l      9436883
       xdef      _vTemAndOr
_vTemAndOr:
       dc.l      9436881
       xdef      _vTemThen
_vTemThen:
       dc.l      9436879
       xdef      _vTemElse
_vTemElse:
       dc.l      9436877
       xdef      _vTemIfAndOr
_vTemIfAndOr:
       dc.l      9436874
       xdef      _vErroProc
_vErroProc:
       dc.l      9436870
       xdef      _ftos
_ftos:
       dc.l      9436866
       xdef      _gtos
_gtos:
       dc.l      9436862
       xdef      _forStack
_forStack:
       dc.l      9434814
       xdef      _atuVarAddr
_atuVarAddr:
       dc.l      9434800
       xdef      _changedPointer
_changedPointer:
       dc.l      9434792
       xdef      _floatBufferStr
_floatBufferStr:
       dc.l      9432998
       xdef      _floatNumD7
_floatNumD7:
       dc.l      9432734
       xdef      _floatNumD6
_floatNumD6:
       dc.l      9432726
       xdef      _floatNumA0
_floatNumA0:
       dc.l      9432718
       xdef      _randSeed
_randSeed:
       dc.l      9432710
       xdef      _lastHgrX
_lastHgrX:
       dc.l      9432708
       xdef      _lastHgrY
_lastHgrY:
       dc.l      9432706
       xdef      _vDataBkpPointerProg
_vDataBkpPointerProg:
       dc.l      9432688
       xdef      _token
_token:
       dc.l      9432430
       xdef      _varName
_varName:
       dc.l      9432174
       xdef      _traceOn
_traceOn:
       dc.l      9432166
       xdef      _gosubStack
_gosubStack:
       dc.l      9431398
       xdef      _vDataFirst
_vDataFirst:
       dc.l      9431394
       xdef      _vDataLineAtu
_vDataLineAtu:
       dc.l      9431390
       xdef      _vDataPointer
_vDataPointer:
       dc.l      9432666
       xdef      _pointerRunProg
_pointerRunProg:
       dc.l      9432662
       xdef      _tok
_tok:
       dc.l      9432660
       xdef      _token_type
_token_type:
       dc.l      9432658
       xdef      _value_type
_value_type:
       dc.l      9432656
       xdef      _onErrGoto
_onErrGoto:
       dc.l      9432650
@basic_listError:
       dc.l      @basic_1,@basic_2,@basic_3,@basic_4,@basic_5
       dc.l      @basic_6,@basic_7,@basic_8,@basic_9,@basic_10
       dc.l      @basic_11,@basic_12,@basic_13,@basic_14,@basic_15
       dc.l      @basic_16,@basic_17,@basic_18,@basic_19,@basic_20
       dc.l      @basic_21,@basic_22,@basic_23,@basic_24,@basic_25
       dc.l      @basic_26,@basic_27
       xref      _inputLine
       xref      _strcpy
       xref      _itoa
       xref      _ltoa
       xref      LDIV
       xref      LMUL
       xref      _FPP_SUM
       xref      _atoi
       xref      _FPP_SUB
       xref      _strlen
       xref      _vdp_set_bdcolor
       xref      _FPP_EXP
       xref      _vdp_read_color_pixel
       xref      ULMUL
       xref      _FPP_INT
       xref      _vdp_plot_color
       xref      _clearScr
       xref      _vdp_set_cursor
       xref      _vdp_init
       xref      _FPP_LN
       xref      _FPP_DIV
       xref      _FPP_NEG
       xref      _STR_TO_FP
       xref      _FPP_FPP
       xref      _FPP_SQRT
       xref      _FPP_COSH
       xref      _FPP_PWR
       xref      _FP_TO_STR
       xref      _strcat
       xref      _FPP_TAN
       xref      _FPP_ABS
       xref      _FPP_SINH
       xref      _FPP_MUL
       xref      _writeLongSerial
       xref      _toupper
       xref      _strchr
       xref      _printText
       xref      _readChar
       xref      _loadSerialToMem
       xref      _FPP_COS
       xref      _vdp_plot_hires
       xref      _strcmp
       xref      _FPP_SIN
       xref      _FPP_TANH
       xref      _FPP_CMP
       xref      _strncmp
       xref      _printChar
