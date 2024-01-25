; C:\PROJETOS\MMSJ300\PROGS\FTPSTARTMAIN.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /********************************************************************************
; *    Programa    : ftpstart.c
; *    Objetivo    : Reinicializa o FTP server, caso ele caia
; *    Criado em   : 12/04/2014
; *    Programador : Moacir Jr.
; *--------------------------------------------------------------------------------
; * Data        Versão  Responsavel  Motivo
; * 12/04/2014  0.1     Moacir Jr.   Criação Versão Beta
; *--------------------------------------------------------------------------------*/
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "mmsj300api.h"
; #include "mmsj_os.h"
; #define _USE_VIDEO_
; //-----------------------------------------------------------------------------
; // Principal
; //-----------------------------------------------------------------------------
; void main(void)
; {
       section   code
       xdef      _main
_main:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _printStrScr.L,A2
; unsigned long* vend;
; // confiuracoes iniciais
; *voutput = 0x01; // Indica Padrão Inicial Video LCDG / VGA
       move.l    _voutput.L,A0
       move.w    #1,(A0)
; *vxmax = xlen_lcdg_lan - 1;
       move.l    _vxmax.L,A0
       move.w    #39,(A0)
; *vymax = ylen_lcdg_lan - 1;
       move.l    _vymax.L,A0
       move.w    #23,(A0)
; // mostra msgs na tela
; printStrScr("FTP Server restarter v0.1\n\n\0", White, Black);
       clr.l     -(A7)
       pea       65535
       pea       @ftpsta~1_1.L
       jsr       (A2)
       add.w     #12,A7
; printStrScr("Restarting FTP Server. Please wait...\n\0", White, Black);
       clr.l     -(A7)
       pea       65535
       pea       @ftpsta~1_2.L
       jsr       (A2)
       add.w     #12,A7
; sendPic(0x01);
       move.l    _vpicd.L,A0
       move.w    #1,(A0)
; sendPic(0xD6);  // command to reinicialize the FTP Server
       move.l    _vpicd.L,A0
       move.w    #214,(A0)
; printStrScr("FTP Server restarted successfully...\n\0", White, Black);
       clr.l     -(A7)
       pea       65535
       pea       @ftpsta~1_3.L
       jsr       (A2)
       add.w     #12,A7
       move.l    (A7)+,A2
       unlk      A6
       rts
; //-----------------------------------------------------------------------------//-----------------------------------------------------------------------------
; void clearScr(WORD pcolor) {
       xdef      _clearScr
_clearScr:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _vpicg.L,A2
; *vpicg = 2;
       move.l    (A2),A0
       move.w    #2,(A0)
; *vpicg = 0xD0;
       move.l    (A2),A0
       move.w    #208,(A0)
; *vpicg = pcolor;
       move.l    (A2),A0
       move.w    10(A6),(A0)
; locateScr(0, 0, REPOS_CURSOR);
       pea       1
       clr.l     -(A7)
       clr.l     -(A7)
       jsr       _locateScr
       add.w     #12,A7
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void printPromptScr(WORD plinadd) {
       xdef      _printPromptScr
_printPromptScr:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _printStrScr.L,A2
; if (plinadd)
       tst.w     10(A6)
       beq.s     printPromptScr_1
; *vlin = *vlin + 1;
       move.l    _vlin.L,A0
       addq.w    #1,(A0)
printPromptScr_1:
; locateScr(0,*vlin, NOREPOS_CURSOR);
       clr.l     -(A7)
       move.l    _vlin.L,A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       jsr       _locateScr
       add.w     #12,A7
; printStrScr("#\0", White, Black);
       clr.l     -(A7)
       pea       65535
       pea       @ftpsta~1_4.L
       jsr       (A2)
       add.w     #12,A7
; printStrScr(vdiratu, White, Black);
       clr.l     -(A7)
       pea       65535
       move.l    _vdiratu.L,-(A7)
       jsr       (A2)
       add.w     #12,A7
; printStrScr(">\0", White, Black);
       clr.l     -(A7)
       pea       65535
       pea       @ftpsta~1_5.L
       jsr       (A2)
       add.w     #12,A7
; *vinip = *vcol;
       move.l    _vcol.L,A0
       move.w    (A0),D0
       move.l    _vinip.L,A0
       move.b    D0,(A0)
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void printStrScr(BYTE *msgs, WORD pcolor, WORD pbcolor) {
       xdef      _printStrScr
_printStrScr:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4,-(A7)
       lea       _vpicg.L,A2
       lea       _vcol.L,A3
       move.l    8(A6),D4
       lea       _vlin.L,A4
; BYTE ix = 10, iy, ichange = 0;
       moveq     #10,D3
       clr.b     D2
; BYTE *ss = msgs;
       move.l    D4,D5
; while (*ss) {
printStrScr_1:
       move.l    D5,A0
       tst.b     (A0)
       beq       printStrScr_3
; if (*ss >= 0x20)
       move.l    D5,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       blo.s     printStrScr_4
; ix++;
       addq.b    #1,D3
       bra.s     printStrScr_5
printStrScr_4:
; else
; ichange = 1;
       moveq     #1,D2
printStrScr_5:
; if ((*vcol + (ix - 10)) > *vxmax)
       move.l    (A3),A0
       move.w    (A0),D0
       move.b    D3,D1
       sub.b     #10,D1
       and.w     #255,D1
       add.w     D1,D0
       move.l    _vxmax.L,A0
       cmp.w     (A0),D0
       bls.s     printStrScr_6
; ichange = 2;
       moveq     #2,D2
printStrScr_6:
; *ss++;
       move.l    D5,A0
       addq.l    #1,D5
; if (!*ss && !ichange)
       move.l    D5,A0
       tst.b     (A0)
       bne.s     printStrScr_8
       tst.b     D2
       bne.s     printStrScr_8
; ichange = 3;
       moveq     #3,D2
printStrScr_8:
; if (ichange) {
       tst.b     D2
       beq       printStrScr_10
; // Manda Sequencia de Controle
; if (ix > 10) {
       cmp.b     #10,D3
       bls       printStrScr_12
; *vpicg = ix;
       and.w     #255,D3
       move.l    (A2),A0
       move.w    D3,(A0)
; *vpicg = 0xD1;
       move.l    (A2),A0
       move.w    #209,(A0)
; *vpicg = (*vcol * 8) >> 8;
       move.l    (A3),A0
       move.w    (A0),D0
       mulu.w    #8,D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = *vcol * 8;
       move.l    (A3),A0
       move.w    (A0),D0
       mulu.w    #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = (*vlin * 10) >> 8;
       move.l    (A4),A0
       move.w    (A0),D0
       mulu.w    #10,D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = *vlin * 10;
       move.l    (A4),A0
       move.w    (A0),D0
       mulu.w    #10,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = 8;
       move.l    (A2),A0
       move.w    #8,(A0)
; *vpicg = pcolor >> 8;
       move.w    14(A6),D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = pcolor;
       move.l    (A2),A0
       move.w    14(A6),(A0)
; *vpicg = pbcolor >> 8;
       move.w    18(A6),D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = pbcolor;
       move.l    (A2),A0
       move.w    18(A6),(A0)
printStrScr_12:
; }
; if (ichange == 1)
       cmp.b     #1,D2
       bne.s     printStrScr_14
; ix++;
       addq.b    #1,D3
printStrScr_14:
; iy = 11;
       moveq     #11,D6
; while (*msgs && iy <= ix) {
printStrScr_16:
       move.l    D4,A0
       move.b    (A0),D0
       and.l     #255,D0
       beq       printStrScr_18
       cmp.b     D3,D6
       bhi       printStrScr_18
; if (*msgs >= 0x20) {
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       blo.s     printStrScr_19
; *vpicg = *msgs;
       move.l    D4,A0
       move.b    (A0),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vcol = *vcol + 1;
       move.l    (A3),A0
       addq.w    #1,(A0)
       bra       printStrScr_20
printStrScr_19:
; }
; else {
; if (*msgs == 0x0D) {
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #13,D0
       bne.s     printStrScr_21
; *vcol = 0;
       move.l    (A3),A0
       clr.w     (A0)
       bra.s     printStrScr_23
printStrScr_21:
; }
; else if (*msgs == 0x0A) {
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #10,D0
       bne.s     printStrScr_23
; *vcol = 0;  // So para teste, despois tiro e coloco '\r' junto com '\n'
       move.l    (A3),A0
       clr.w     (A0)
; *vlin = *vlin + 1;
       move.l    (A4),A0
       addq.w    #1,(A0)
printStrScr_23:
; }
; locateScr(*vcol, *vlin, NOREPOS_CURSOR);
       clr.l     -(A7)
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _locateScr
       add.w     #12,A7
printStrScr_20:
; }
; *msgs++;
       move.l    D4,A0
       addq.l    #1,D4
; iy++;
       addq.b    #1,D6
       bra       printStrScr_16
printStrScr_18:
; }
; if (ichange == 2) {
       cmp.b     #2,D2
       bne.s     printStrScr_25
; *vcol = 0;
       move.l    (A3),A0
       clr.w     (A0)
; *vlin = *vlin + 1;
       move.l    (A4),A0
       addq.w    #1,(A0)
; locateScr(*vcol, *vlin, NOREPOS_CURSOR);
       clr.l     -(A7)
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _locateScr
       add.w     #12,A7
printStrScr_25:
; }
; ichange = 0;
       clr.b     D2
; ix = 10;
       moveq     #10,D3
printStrScr_10:
       bra       printStrScr_1
printStrScr_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4
       unlk      A6
       rts
; }
; }
; }
; //-----------------------------------------------------------------------------
; void printByteScr(BYTE pbyte, WORD pcolor, WORD pbcolor) {
       xdef      _printByteScr
_printByteScr:
       link      A6,#0
       movem.l   A2/A3/A4,-(A7)
       lea       _vpicg.L,A2
       lea       _vcol.L,A3
       lea       _vlin.L,A4
; *vpicg = 0x0B;
       move.l    (A2),A0
       move.w    #11,(A0)
; *vpicg = 0xD2;
       move.l    (A2),A0
       move.w    #210,(A0)
; *vpicg = (*vcol * 8) >> 8;
       move.l    (A3),A0
       move.w    (A0),D0
       mulu.w    #8,D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = *vcol * 8;
       move.l    (A3),A0
       move.w    (A0),D0
       mulu.w    #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = (*vlin * 10) >> 8;
       move.l    (A4),A0
       move.w    (A0),D0
       mulu.w    #10,D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = *vlin * 10;
       move.l    (A4),A0
       move.w    (A0),D0
       mulu.w    #10,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = 8;
       move.l    (A2),A0
       move.w    #8,(A0)
; *vpicg = pcolor >> 8;
       move.w    14(A6),D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = pcolor;
       move.l    (A2),A0
       move.w    14(A6),(A0)
; *vpicg = pbcolor >> 8;
       move.w    18(A6),D0
       lsr.w     #8,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vpicg = pbcolor;
       move.l    (A2),A0
       move.w    18(A6),(A0)
; *vpicg = pbyte;
       move.b    11(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.w    D0,(A0)
; *vcol = *vcol + 1;
       move.l    (A3),A0
       addq.w    #1,(A0)
; locateScr(*vcol, *vlin, REPOS_CURSOR_ON_CHANGE);
       pea       2
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _locateScr
       add.w     #12,A7
       movem.l   (A7)+,A2/A3/A4
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void locateScr(BYTE pcol, BYTE plin, BYTE pcur) {
       xdef      _locateScr
_locateScr:
       link      A6,#-40
       movem.l   D2/D3/D4/A2,-(A7)
       move.b    15(A6),D2
       and.l     #255,D2
       move.b    11(A6),D3
       and.l     #255,D3
       lea       _vpicg.L,A2
; WORD vend, ix, iy, ichange = 0;
       clr.w     D4
; WORD vlcdf[16];
; if (pcol > *vxmax) {
       and.w     #255,D3
       move.l    _vxmax.L,A0
       cmp.w     (A0),D3
       bls.s     locateScr_1
; pcol = 0;
       clr.b     D3
; plin++;
       addq.b    #1,D2
; ichange = 1;
       moveq     #1,D4
locateScr_1:
; }
; if (plin > *vymax) {
       and.w     #255,D2
       move.l    _vymax.L,A0
       cmp.w     (A0),D2
       bls.s     locateScr_3
; *vpicg = 2;
       move.l    (A2),A0
       move.w    #2,(A0)
; *vpicg = 0xD9;
       move.l    (A2),A0
       move.w    #217,(A0)
; *vpicg = 10;
       move.l    (A2),A0
       move.w    #10,(A0)
; pcol = 0;
       clr.b     D3
; plin = *vymax;
       move.l    _vymax.L,A0
       move.w    (A0),D0
       move.b    D0,D2
; ichange = 1;
       moveq     #1,D4
locateScr_3:
; }
; *vcol = pcol;
       and.w     #255,D3
       move.l    _vcol.L,A0
       move.w    D3,(A0)
; *vlin = plin;
       and.w     #255,D2
       move.l    _vlin.L,A0
       move.w    D2,(A0)
; if (pcur == 1 || (pcur == 2 && ichange)) {
       move.b    19(A6),D0
       cmp.b     #1,D0
       beq.s     locateScr_7
       move.b    19(A6),D0
       cmp.b     #2,D0
       bne.s     locateScr_5
       and.l     #65535,D4
       beq.s     locateScr_5
locateScr_7:
; printByteScr(0x08, White, Black);
       clr.l     -(A7)
       pea       65535
       pea       8
       jsr       _printByteScr
       add.w     #12,A7
; *vcol = *vcol - 1;
       move.l    _vcol.L,A0
       subq.w    #1,(A0)
locateScr_5:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void loadFile(unsigned short* xaddress)
; {
       xdef      _loadFile
_loadFile:
       link      A6,#-260
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vpicd.L,A2
       lea       -260(A6),A4
; unsigned short cc, dd;
; unsigned short vrecfim, vbytepic, vbyteprog[128];
; unsigned int vbytegrava = 0;
       moveq     #0,D7
; unsigned short xdado = 0, xcounter = 0;
       clr.w     -4(A6)
       clr.w     -2(A6)
; unsigned short vcrc, vcrcpic, vloop;
; vrecfim = 1;
       moveq     #1,D5
; *verro = 0;
       move.l    _verro.L,A0
       clr.w     (A0)
; while (vrecfim) {
loadFile_1:
       tst.w     D5
       beq       loadFile_3
; vloop = 1;
       moveq     #1,D4
; while (vloop) {
loadFile_4:
       tst.w     D4
       beq       loadFile_6
; // Processa Retorno do PIC
; recPic();
       move.l    (A2),A0
       move.w    (A0),D0
       and.w     #255,D0
       move.w    D0,D2
; if (vbytepic == picCommData) {
       cmp.w     #48,D2
       bne       loadFile_9
; // Carrega Dados Recebidos
; vcrc = 0;
       move.w    #0,A5
; for (cc = 0; cc <= 127 ; cc++)
       clr.w     D6
loadFile_11:
       cmp.w     #127,D6
       bhi.s     loadFile_13
; {
; recPic(); // Ler dados do PIC
       move.l    (A2),A0
       move.w    (A0),D0
       and.w     #255,D0
       move.w    D0,D2
; vbyteprog[cc] = vbytepic;
       and.l     #65535,D6
       move.l    D6,D0
       lsl.l     #1,D0
       move.w    D2,0(A4,D0.L)
; vcrc += vbytepic;
       add.w     D2,A5
       addq.w    #1,D6
       bra       loadFile_11
loadFile_13:
; }
; // Recebe 2 Bytes CRC
; recPic();
       move.l    (A2),A0
       move.w    (A0),D0
       and.w     #255,D0
       move.w    D0,D2
; vcrcpic = vbytepic;
       move.w    D2,A3
; recPic();
       move.l    (A2),A0
       move.w    (A0),D0
       and.w     #255,D0
       move.w    D0,D2
; vcrcpic |= ((vbytepic << 8) & 0xFF00);
       move.w    D2,D0
       lsl.w     #8,D0
       and.w     #65280,D0
       move.l    A3,D1
       or.w      D0,D1
       move.w    D1,A3
; if (vcrc == vcrcpic) {
       move.w    A5,D0
       cmp.w     A3,D0
       bne.s     loadFile_20
; sendPic(0x01);
       move.l    (A2),A0
       move.w    #1,(A0)
; sendPic(0xC5);
       move.l    (A2),A0
       move.w    #197,(A0)
; vloop = 0;
       clr.w     D4
       bra.s     loadFile_21
loadFile_20:
; }
; else {
; sendPic(0x01);
       move.l    (A2),A0
       move.w    #1,(A0)
; sendPic(0xFF);
       move.l    (A2),A0
       move.w    #255,(A0)
loadFile_21:
       bra.s     loadFile_31
loadFile_9:
; }
; }
; else if (vbytepic == picCommStop) {
       cmp.w     #64,D2
       bne.s     loadFile_30
; // Finaliza Comunicação Serial
; vloop = 0;
       clr.w     D4
; vrecfim = 0;
       clr.w     D5
       bra.s     loadFile_31
loadFile_30:
; }
; else {
; vloop = 0;
       clr.w     D4
; vrecfim = 0;
       clr.w     D5
; *verro = 1;
       move.l    _verro.L,A0
       move.w    #1,(A0)
loadFile_31:
       bra       loadFile_4
loadFile_6:
; }
; }
; if (vrecfim) {
       tst.w     D5
       beq       loadFile_36
; for (dd = 00; dd <= 127; dd += 2){
       clr.w     D3
loadFile_34:
       cmp.w     #127,D3
       bhi       loadFile_36
; vbytegrava = vbyteprog[dd] << 8;
       and.l     #65535,D3
       move.l    D3,D0
       lsl.l     #1,D0
       move.w    0(A4,D0.L),D0
       and.l     #65535,D0
       lsl.l     #8,D0
       move.l    D0,D7
; vbytegrava = vbytegrava | (vbyteprog[dd + 1] & 0x00FF);
       and.l     #65535,D3
       move.l    D3,D0
       addq.l    #1,D0
       lsl.l     #1,D0
       move.w    0(A4,D0.L),D0
       and.w     #255,D0
       and.l     #65535,D0
       or.l      D0,D7
; // Grava Dados na Posição Especificada
; *xaddress = vbytegrava;
       move.l    8(A6),A0
       move.w    D7,(A0)
; xaddress += 1;
       addq.l    #2,8(A6)
       addq.w    #2,D3
       bra       loadFile_34
loadFile_36:
       bra       loadFile_1
loadFile_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; #include "ftpstart.c"
; #include "mmsj300api.c"
       section   const
@ftpsta~1_1:
       dc.b      70,84,80,32,83,101,114,118,101,114,32,114,101
       dc.b      115,116,97,114,116,101,114,32,118,48,46,49,10
       dc.b      10,0
@ftpsta~1_2:
       dc.b      82,101,115,116,97,114,116,105,110,103,32,70
       dc.b      84,80,32,83,101,114,118,101,114,46,32,80,108
       dc.b      101,97,115,101,32,119,97,105,116,46,46,46,10
       dc.b      0
@ftpsta~1_3:
       dc.b      70,84,80,32,83,101,114,118,101,114,32,114,101
       dc.b      115,116,97,114,116,101,100,32,115,117,99,99
       dc.b      101,115,115,102,117,108,108,121,46,46,46,10
       dc.b      0
@ftpsta~1_4:
       dc.b      35,0
@ftpsta~1_5:
       dc.b      62,0
       section   data
       xdef      _vlcds
_vlcds:
       dc.l      4194304
       xdef      _vlcdd
_vlcdd:
       dc.l      4194306
       xdef      _vpicd
_vpicd:
       dc.l      4194336
       xdef      _vpicg
_vpicg:
       dc.l      4194368
       xdef      _vcol
_vcol:
       dc.l      16764928
       xdef      _vlin
_vlin:
       dc.l      16764930
       xdef      _voutput
_voutput:
       dc.l      16764932
       xdef      _vbuf
_vbuf:
       dc.l      16764934
       xdef      _vxmax
_vxmax:
       dc.l      16764966
       xdef      _vymax
_vymax:
       dc.l      16764968
       xdef      _xpos
_xpos:
       dc.l      16764970
       xdef      _ypos
_ypos:
       dc.l      16764972
       xdef      _verro
_verro:
       dc.l      16764974
       xdef      _vdiratu
_vdiratu:
       dc.l      16764976
       xdef      _vdiratup
_vdiratup:
       dc.l      16764976
       xdef      _vinip
_vinip:
       dc.l      16765120
       xdef      _vbufk
_vbufk:
       dc.l      16765122
       xdef      _vbufkptr
_vbufkptr:
       dc.l      16765122
       xdef      _vbufkmove
_vbufkmove:
       dc.l      16765122
       xdef      _vbufkatu
_vbufkatu:
       dc.l      16765122
       xdef      _vbufkbios
_vbufkbios:
       dc.l      16765154
       xdef      _inten
_inten:
       dc.l      16765168
       xdef      _vmtaskatu
_vmtaskatu:
       dc.l      16768932
       xdef      _vmtask
_vmtask:
       dc.l      16768932
       xdef      _vmtaskup
_vmtaskup:
       dc.l      16768932
       xdef      _intpos
_intpos:
       dc.l      16769016
       xdef      _vtotmem
_vtotmem:
       dc.l      16769020
       xdef      _v10ms
_v10ms:
       dc.l      16769022
