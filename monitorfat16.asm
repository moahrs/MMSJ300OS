; D:\PROJETOS\MMSJ300\MONITORFAT16.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J.Fondse
; /********************************************************************************
; *    Programa    : monitor.c
; *    Objetivo    : MMSJOS - Versao vintage compatible
; *    Criado em   : 11/07/2013
; *    Programador : Moacir Jr.
; *--------------------------------------------------------------------------------
; * Data        Versao  Responsavel  Motivo
; * 11/07/2013  0.1     Moacir Jr.   Criação Versão Beta
; * 12/11/2022  1.0     Moacir Jr.   Versao para publicacao com FAT32
; * 								   ( usando cartao SD ) ( NOT VINTAGE )
; * 29/07/2023  1.0a    Moacir Jr.   Adaptar de FAT32 para FAT16 e acesso pela Serial
; * 								   usando Arduino uno como controlador com
; *                                  FLOPPY DISK 3 1/2", e integracao no monitor
; ********************************************************************************/
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "mmsj300api.h"
; #include "monitorfat16.h"
; #include "monitor.h"
; #define versionMMSJOS "1.0a"
; //-----------------------------------------------------------------------------
; // FAT16 Functions
; //-----------------------------------------------------------------------------
; //-----------------------------------------------------------------------------
; void fsInit(void)
; {
       section   code
       xdef      _fsInit
_fsInit:
; fsMountDisk();
       jsr       _fsMountDisk
; *vdiratup++ = '/';
       move.l    _vdiratup.L,A0
       addq.l    #1,_vdiratup.L
       move.b    #47,(A0)
; *vdiratup = '\0';
       move.l    _vdiratup.L,A0
       clr.b     (A0)
; printText("MMSJ-OS v"versionMMSJOS);
       pea       @monitorfafsInit_1.L
       jsr       _printText
       addq.w    #4,A7
; printText("\r\n\0");
       pea       @monitorfafsInit_2.L
       jsr       _printText
       addq.w    #4,A7
       rts
; }
; //-----------------------------------------------------------------------------
; void fsVer(void)
; {
       xdef      _fsVer
_fsVer:
; printText("\r\n\0");
       pea       @monitorfafsVer_2.L
       jsr       _printText
       addq.w    #4,A7
; printText("MMSJ-OS v"versionMMSJOS);
       pea       @monitorfafsVer_1.L
       jsr       _printText
       addq.w    #4,A7
       rts
; }
; //-----------------------------------------------------------------------------
; char fsOsCommand(unsigned char *linhacomando, unsigned int iy, unsigned char *linhaarg, unsigned char *vparam, unsigned char *vparam2, unsigned char *vparam3)
; {
       xdef      _fsOsCommand
_fsOsCommand:
       link      A6,#-188
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -188(A6),A2
       lea       -60(A6),A3
       move.l    8(A6),D5
       lea       _vdir.L,A4
       move.l    12(A6),D6
       lea       -12(A6),A5
; unsigned char vbuffer[128], vlinha[40];
; unsigned char *vdirptr = (unsigned char*)&vdir;
       move.l    A4,-20(A6)
; unsigned short ix, iz, ikk, varg = 0;
       clr.w     D3
; unsigned char sqtdtam[10], cuntam;
; long vqtdtam;
; unsigned short vretfat;
; if (!strcmp(linhacomando,"LS") && iy == 2)
       pea       @monitorfafsOsCommand_3.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne       fsOsCommand_1
       cmp.l     #2,D6
       bne       fsOsCommand_1
; {
; if (fsFindInDir(NULL, TYPE_FIRST_ENTRY) >= ERRO_D_START)
       pea       8
       clr.b     D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsOsCommand_3
; {
; printText("File not found\n\0");
       pea       @monitorfafsOsCommand_4.L
       jsr       _printText
       addq.w    #4,A7
       bra       fsOsCommand_7
fsOsCommand_3:
; }
; else
; {
; while (1)
fsOsCommand_5:
; {
; if (vdir->Attr != ATTR_VOLUME)
       move.l    (A4),A0
       move.b    14(A0),D0
       cmp.b     #8,D0
       beq       fsOsCommand_8
; {
; memset(vbuffer, 0x0, 128);
       pea       128
       clr.l     -(A7)
       move.l    A2,-(A7)
       jsr       _memset
       add.w     #12,A7
; vdirptr = (unsigned char*)&vdir;
       move.l    A4,-20(A6)
; for(ix = 40; ix <= 79; ix++)
       moveq     #40,D2
fsOsCommand_10:
       cmp.w     #79,D2
       bhi.s     fsOsCommand_12
; vbuffer[ix] = *vdirptr++;
       move.l    -20(A6),A0
       addq.l    #1,-20(A6)
       and.l     #65535,D2
       move.b    (A0),0(A2,D2.L)
       addq.w    #1,D2
       bra       fsOsCommand_10
fsOsCommand_12:
; if (vdir->Attr != ATTR_DIRECTORY)
       move.l    (A4),A0
       move.b    14(A0),D0
       cmp.b     #16,D0
       beq       fsOsCommand_13
; {
; // Reduz o tamanho a unidade (GB, MB ou KB)
; vqtdtam = vdir->Size;
       move.l    (A4),A0
       move.l    28(A0),D4
; if ((vqtdtam & 0xC0000000) != 0)
       move.l    D4,D0
       and.l     #-1073741824,D0
       beq.s     fsOsCommand_15
; {
; cuntam = 'G';
       move.b    #71,-1(A6)
; vqtdtam = ((vqtdtam & 0xC0000000) >> 30) + 1;
       move.l    D4,D0
       and.l     #-1073741824,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       lsr.l     #6,D0
       addq.l    #1,D0
       move.l    D0,D4
       bra       fsOsCommand_20
fsOsCommand_15:
; }
; else if ((vqtdtam & 0x3FF00000) != 0)
       move.l    D4,D0
       and.l     #1072693248,D0
       beq.s     fsOsCommand_17
; {
; cuntam = 'M';
       move.b    #77,-1(A6)
; vqtdtam = ((vqtdtam & 0x3FF00000) >> 20) + 1;
       move.l    D4,D0
       and.l     #1072693248,D0
       asr.l     #8,D0
       asr.l     #8,D0
       asr.l     #4,D0
       addq.l    #1,D0
       move.l    D0,D4
       bra.s     fsOsCommand_20
fsOsCommand_17:
; }
; else if ((vqtdtam & 0x000FFC00) != 0)
       move.l    D4,D0
       and.l     #1047552,D0
       beq.s     fsOsCommand_19
; {
; cuntam = 'K';
       move.b    #75,-1(A6)
; vqtdtam = ((vqtdtam & 0x000FFC00) >> 10) + 1;
       move.l    D4,D0
       and.l     #1047552,D0
       asr.l     #8,D0
       asr.l     #2,D0
       addq.l    #1,D0
       move.l    D0,D4
       bra.s     fsOsCommand_20
fsOsCommand_19:
; }
; else
; cuntam = ' ';
       move.b    #32,-1(A6)
fsOsCommand_20:
; // Transforma para decimal
; memset(sqtdtam, 0x0, 10);
       pea       10
       clr.l     -(A7)
       move.l    A5,-(A7)
       jsr       _memset
       add.w     #12,A7
; itoa(vqtdtam, sqtdtam, 10);
       pea       10
       move.l    A5,-(A7)
       move.l    D4,-(A7)
       jsr       _itoa
       add.w     #12,A7
; // Primeira Parte da Linha do dir, tamanho
; for(ix = 0; ix <= 3; ix++)
       clr.w     D2
fsOsCommand_21:
       cmp.w     #3,D2
       bhi.s     fsOsCommand_23
; {
; if (sqtdtam[ix] == 0)
       and.l     #65535,D2
       move.b    0(A5,D2.L),D0
       bne.s     fsOsCommand_24
; break;
       bra.s     fsOsCommand_23
fsOsCommand_24:
       addq.w    #1,D2
       bra       fsOsCommand_21
fsOsCommand_23:
; }
; iy = (4 - ix);
       moveq     #4,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D2
       sub.l     D2,D0
       move.l    D0,D6
; for(ix = 0; ix <= 3; ix++)
       clr.w     D2
fsOsCommand_26:
       cmp.w     #3,D2
       bhi       fsOsCommand_28
; {
; if (iy <= ix)
       and.l     #65535,D2
       cmp.l     D2,D6
       bhi.s     fsOsCommand_29
; {
; ikk = ix - iy;
       move.w    D2,D0
       and.l     #65535,D0
       sub.l     D6,D0
       move.w    D0,-14(A6)
; vbuffer[ix] = sqtdtam[ix - iy];
       move.w    D2,D0
       and.l     #65535,D0
       sub.l     D6,D0
       and.l     #65535,D2
       move.b    0(A5,D0.L),0(A2,D2.L)
       bra.s     fsOsCommand_30
fsOsCommand_29:
; }
; else
; vbuffer[ix] = ' ';
       and.l     #65535,D2
       move.b    #32,0(A2,D2.L)
fsOsCommand_30:
       addq.w    #1,D2
       bra       fsOsCommand_26
fsOsCommand_28:
; }
; vbuffer[4] = cuntam;
       move.b    -1(A6),4(A2)
       bra.s     fsOsCommand_14
fsOsCommand_13:
; }
; else
; {
; vbuffer[0] = ' ';
       move.b    #32,(A2)
; vbuffer[1] = ' ';
       move.b    #32,1(A2)
; vbuffer[2] = ' ';
       move.b    #32,2(A2)
; vbuffer[3] = ' ';
       move.b    #32,3(A2)
; vbuffer[4] = '0';
       move.b    #48,4(A2)
fsOsCommand_14:
; }
; vbuffer[5] = ' ';
       move.b    #32,5(A2)
; // Segunda parte da linha do dir, data ult modif
; // Mes
; vqtdtam = (vdir->UpdateDate & 0x01E0) >> 5;
       move.l    (A4),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       and.l     #480,D0
       lsr.l     #5,D0
       move.l    D0,D4
; if (vqtdtam < 1 || vqtdtam > 12)
       cmp.l     #1,D4
       blt.s     fsOsCommand_33
       cmp.l     #12,D4
       ble.s     fsOsCommand_31
fsOsCommand_33:
; vqtdtam = 1;
       moveq     #1,D4
fsOsCommand_31:
; vqtdtam--;
       subq.l    #1,D4
; vbuffer[6] = vmesc[vqtdtam][0];
       move.l    D4,D0
       muls      #3,D0
       lea       _vmesc.L,A0
       move.b    0(A0,D0.L),6(A2)
; vbuffer[7] = vmesc[vqtdtam][1];
       move.l    D4,D0
       muls      #3,D0
       lea       _vmesc.L,A0
       add.l     D0,A0
       move.b    1(A0),7(A2)
; vbuffer[8] = vmesc[vqtdtam][2];
       move.l    D4,D0
       muls      #3,D0
       lea       _vmesc.L,A0
       add.l     D0,A0
       move.b    2(A0),8(A2)
; vbuffer[9] = ' ';
       move.b    #32,9(A2)
; // Dia
; vqtdtam = vdir->UpdateDate & 0x001F;
       move.l    (A4),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       and.l     #31,D0
       move.l    D0,D4
; memset(sqtdtam, 0x0, 10);
       pea       10
       clr.l     -(A7)
       move.l    A5,-(A7)
       jsr       _memset
       add.w     #12,A7
; itoa(vqtdtam, sqtdtam, 10);
       pea       10
       move.l    A5,-(A7)
       move.l    D4,-(A7)
       jsr       _itoa
       add.w     #12,A7
; if (vqtdtam < 10)
       cmp.l     #10,D4
       bge.s     fsOsCommand_34
; {
; vbuffer[10] = '0';
       move.b    #48,10(A2)
; vbuffer[11] = sqtdtam[0];
       move.b    (A5),11(A2)
       bra.s     fsOsCommand_35
fsOsCommand_34:
; }
; else
; {
; vbuffer[10] = sqtdtam[0];
       move.b    (A5),10(A2)
; vbuffer[11] = sqtdtam[1];
       move.b    1(A5),11(A2)
fsOsCommand_35:
; }
; vbuffer[12] = ' ';
       move.b    #32,12(A2)
; // Ano
; vqtdtam = ((vdir->UpdateDate & 0xFE00) >> 9) + 1980;
       move.l    (A4),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       and.l     #65024,D0
       lsr.l     #8,D0
       lsr.l     #1,D0
       add.l     #1980,D0
       move.l    D0,D4
; memset(sqtdtam, 0x0, 10);
       pea       10
       clr.l     -(A7)
       move.l    A5,-(A7)
       jsr       _memset
       add.w     #12,A7
; itoa(vqtdtam, sqtdtam, 10);
       pea       10
       move.l    A5,-(A7)
       move.l    D4,-(A7)
       jsr       _itoa
       add.w     #12,A7
; vbuffer[13] = sqtdtam[0];
       move.b    (A5),13(A2)
; vbuffer[14] = sqtdtam[1];
       move.b    1(A5),14(A2)
; vbuffer[15] = sqtdtam[2];
       move.b    2(A5),15(A2)
; vbuffer[16] = sqtdtam[3];
       move.b    3(A5),16(A2)
; vbuffer[17] = ' ';
       move.b    #32,17(A2)
; // Terceira parte da linha do dir, nome.ext
; ix = 18;
       moveq     #18,D2
; varg = 0;
       clr.w     D3
; while (vdir->Name[varg] != 0x20 && vdir->Name[varg] != 0x00 && varg <= 7)
fsOsCommand_36:
       move.l    (A4),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       cmp.b     #32,D0
       beq.s     fsOsCommand_38
       move.l    (A4),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       beq.s     fsOsCommand_38
       cmp.w     #7,D3
       bhi.s     fsOsCommand_38
; {
; vbuffer[ix] = vdir->Name[varg];
       move.l    (A4),A0
       and.l     #65535,D3
       and.l     #65535,D2
       move.b    0(A0,D3.L),0(A2,D2.L)
; ix++;
       addq.w    #1,D2
; varg++;
       addq.w    #1,D3
       bra       fsOsCommand_36
fsOsCommand_38:
; }
; vbuffer[ix] = '.';
       and.l     #65535,D2
       move.b    #46,0(A2,D2.L)
; ix++;
       addq.w    #1,D2
; varg = 0;
       clr.w     D3
; while (vdir->Ext[varg] != 0x20 && vdir->Ext[varg] != 0x00 && varg <= 2)
fsOsCommand_39:
       move.l    (A4),A0
       and.l     #65535,D3
       add.l     D3,A0
       move.b    10(A0),D0
       cmp.b     #32,D0
       beq.s     fsOsCommand_41
       move.l    (A4),A0
       and.l     #65535,D3
       add.l     D3,A0
       move.b    10(A0),D0
       beq.s     fsOsCommand_41
       cmp.w     #2,D3
       bhi.s     fsOsCommand_41
; {
; vbuffer[ix] = vdir->Ext[varg];
       move.l    (A4),A0
       and.l     #65535,D3
       add.l     D3,A0
       and.l     #65535,D2
       move.b    10(A0),0(A2,D2.L)
; ix++;
       addq.w    #1,D2
; varg++;
       addq.w    #1,D3
       bra       fsOsCommand_39
fsOsCommand_41:
; }
; if (varg == 0)
       tst.w     D3
       bne.s     fsOsCommand_42
; {
; ix--;
       subq.w    #1,D2
; vbuffer[ix] = ' ';
       and.l     #65535,D2
       move.b    #32,0(A2,D2.L)
; ix++;
       addq.w    #1,D2
fsOsCommand_42:
; }
; // Quarta parte da linha do dir, "/" para diretorio
; if (vdir->Attr == ATTR_DIRECTORY)
       move.l    (A4),A0
       move.b    14(A0),D0
       cmp.b     #16,D0
       bne.s     fsOsCommand_44
; {
; ix--;
       subq.w    #1,D2
; vbuffer[ix] = '/';
       and.l     #65535,D2
       move.b    #47,0(A2,D2.L)
; ix++;
       addq.w    #1,D2
fsOsCommand_44:
; }
; vbuffer[ix] = '\0';
       and.l     #65535,D2
       clr.b     0(A2,D2.L)
; for(ix = 0; ix <= 39; ix++)
       clr.w     D2
fsOsCommand_46:
       cmp.w     #39,D2
       bhi.s     fsOsCommand_48
; vlinha[ix] = vbuffer[ix];
       and.l     #65535,D2
       and.l     #65535,D2
       move.b    0(A2,D2.L),0(A3,D2.L)
       addq.w    #1,D2
       bra       fsOsCommand_46
fsOsCommand_48:
       bra       fsOsCommand_9
fsOsCommand_8:
; }
; else
; {
; memset(vlinha, 0x20, 40);
       pea       40
       pea       32
       move.l    A3,-(A7)
       jsr       _memset
       add.w     #12,A7
; vlinha[5]  = 'D';
       move.b    #68,5(A3)
; vlinha[6]  = 'i';
       move.b    #105,6(A3)
; vlinha[7]  = 's';
       move.b    #115,7(A3)
; vlinha[8]  = 'k';
       move.b    #107,8(A3)
; vlinha[9]  = ' ';
       move.b    #32,9(A3)
; vlinha[10] = 'N';
       move.b    #78,10(A3)
; vlinha[11] = 'a';
       move.b    #97,11(A3)
; vlinha[12] = 'm';
       move.b    #109,12(A3)
; vlinha[13] = 'e';
       move.b    #101,13(A3)
; vlinha[14] = ' ';
       move.b    #32,14(A3)
; vlinha[15] = 'i';
       move.b    #105,15(A3)
; vlinha[16] = 's';
       move.b    #115,16(A3)
; vlinha[17] = ' ';
       move.b    #32,17(A3)
; ix = 18;
       moveq     #18,D2
; varg = 0;
       clr.w     D3
; while (vdir->Name[varg] != 0x00 && varg <= 7)
fsOsCommand_49:
       move.l    (A4),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       beq.s     fsOsCommand_51
       cmp.w     #7,D3
       bhi.s     fsOsCommand_51
; {
; vlinha[ix] = vdir->Name[varg];
       move.l    (A4),A0
       and.l     #65535,D3
       and.l     #65535,D2
       move.b    0(A0,D3.L),0(A3,D2.L)
; ix++;
       addq.w    #1,D2
; varg++;
       addq.w    #1,D3
       bra       fsOsCommand_49
fsOsCommand_51:
; }
; varg = 0;
       clr.w     D3
; while (vdir->Ext[varg] != 0x00 && varg <= 2)
fsOsCommand_52:
       move.l    (A4),A0
       and.l     #65535,D3
       add.l     D3,A0
       move.b    10(A0),D0
       beq.s     fsOsCommand_54
       cmp.w     #2,D3
       bhi.s     fsOsCommand_54
; {
; vlinha[ix] = vdir->Ext[varg];
       move.l    (A4),A0
       and.l     #65535,D3
       add.l     D3,A0
       and.l     #65535,D2
       move.b    10(A0),0(A3,D2.L)
; ix++;
       addq.w    #1,D2
; varg++;
       addq.w    #1,D3
       bra       fsOsCommand_52
fsOsCommand_54:
; }
; vlinha[ix] = '\0';
       and.l     #65535,D2
       clr.b     0(A3,D2.L)
fsOsCommand_9:
; }
; // Mostra linha
; printText("\n\0");
       pea       @monitorfafsOsCommand_5.L
       jsr       _printText
       addq.w    #4,A7
; printText(vlinha);
       move.l    A3,-(A7)
       jsr       _printText
       addq.w    #4,A7
; // Verifica se Tem mais arquivos no diretorio
; for (ix = 0; ix <= 7; ix++)
       clr.w     D2
fsOsCommand_55:
       cmp.w     #7,D2
       bhi       fsOsCommand_57
; {
; vparam[ix] = vdir->Name[ix];
       move.l    (A4),A0
       and.l     #65535,D2
       move.l    20(A6),A1
       and.l     #65535,D2
       move.b    0(A0,D2.L),0(A1,D2.L)
; if (vparam[ix] == 0x20)
       move.l    20(A6),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       cmp.b     #32,D0
       bne.s     fsOsCommand_58
; {
; vparam[ix] = '\0';
       move.l    20(A6),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; break;
       bra.s     fsOsCommand_57
fsOsCommand_58:
       addq.w    #1,D2
       bra       fsOsCommand_55
fsOsCommand_57:
; }
; }
; vparam[ix] = '\0';
       move.l    20(A6),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; if (vdir->Name[0] != '.')
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #46,D0
       beq       fsOsCommand_60
; {
; vparam[ix] = '.';
       move.l    20(A6),A0
       and.l     #65535,D2
       move.b    #46,0(A0,D2.L)
; ix++;
       addq.w    #1,D2
; for (iy = 0; iy <= 2; iy++)
       clr.l     D6
fsOsCommand_62:
       cmp.l     #2,D6
       bhi       fsOsCommand_64
; {
; vparam[ix] = vdir->Ext[iy];
       move.l    (A4),A0
       add.l     D6,A0
       move.l    20(A6),A1
       and.l     #65535,D2
       move.b    10(A0),0(A1,D2.L)
; if (vparam[ix] == 0x20)
       move.l    20(A6),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       cmp.b     #32,D0
       bne.s     fsOsCommand_65
; {
; vparam[ix] = '\0';
       move.l    20(A6),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; break;
       bra.s     fsOsCommand_64
fsOsCommand_65:
; }
; ix++;
       addq.w    #1,D2
       addq.l    #1,D6
       bra       fsOsCommand_62
fsOsCommand_64:
; }
; vparam[ix] = '\0';
       move.l    20(A6),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
fsOsCommand_60:
; }
; if (fsFindInDir(vparam, TYPE_NEXT_ENTRY) >= ERRO_D_START)
       pea       9
       move.l    20(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsOsCommand_67
; {
; printText("\n\0");
       pea       @monitorfafsOsCommand_5.L
       jsr       _printText
       addq.w    #4,A7
; break;
       bra.s     fsOsCommand_7
fsOsCommand_67:
       bra       fsOsCommand_5
fsOsCommand_7:
       bra       fsOsCommand_133
fsOsCommand_1:
; }
; }
; }
; }
; else
; {
; if (!strcmp(linhacomando,"RM") && iy == 2)
       pea       @monitorfafsOsCommand_6.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_69
       cmp.l     #2,D6
       bne.s     fsOsCommand_69
; {
; vretfat = fsDelFile(linhaarg);
       move.l    16(A6),-(A7)
       jsr       _fsDelFile
       addq.w    #4,A7
       and.w     #255,D0
       move.w    D0,D7
       bra       fsOsCommand_103
fsOsCommand_69:
; }
; else if (!strcmp(linhacomando,"REN") && iy == 3)
       pea       @monitorfafsOsCommand_7.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_71
       cmp.l     #3,D6
       bne.s     fsOsCommand_71
; {
; vretfat = fsRenameFile(vparam, vparam2);
       move.l    24(A6),-(A7)
       move.l    20(A6),-(A7)
       jsr       _fsRenameFile
       addq.w    #8,A7
       and.w     #255,D0
       move.w    D0,D7
       bra       fsOsCommand_103
fsOsCommand_71:
; }
; else if (!strcmp(linhacomando,"CP") && iy == 2)
       pea       @monitorfafsOsCommand_8.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne       fsOsCommand_73
       cmp.l     #2,D6
       bne       fsOsCommand_73
; {
; ikk = 0;
       clr.w     -14(A6)
; if (fsOpenFile(vparam) != RETURN_OK)
       move.l    20(A6),-(A7)
       jsr       _fsOpenFile
       addq.w    #4,A7
       tst.b     D0
       beq.s     fsOsCommand_75
; {
; vretfat = ERRO_B_NOT_FOUND;
       move.w    #255,D7
       bra.s     fsOsCommand_79
fsOsCommand_75:
; }
; else
; {
; if (fsOpenFile(vparam2) != RETURN_OK)
       move.l    24(A6),-(A7)
       jsr       _fsOpenFile
       addq.w    #4,A7
       tst.b     D0
       beq.s     fsOsCommand_79
; {
; if (fsCreateFile(vparam2) != RETURN_OK)
       move.l    24(A6),-(A7)
       jsr       _fsCreateFile
       addq.w    #4,A7
       tst.b     D0
       beq.s     fsOsCommand_79
; {
; vretfat = ERRO_B_CREATE_FILE;
       move.w    #230,D7
fsOsCommand_79:
; }
; }
; }
; while (vretfat == RETURN_OK)
fsOsCommand_81:
       tst.w     D7
       bne       fsOsCommand_83
; {
; if (fsReadFile(vparam, ikk, vbuffer, 128) > 0)
       pea       128
       move.l    A2,-(A7)
       move.w    -14(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    20(A6),-(A7)
       jsr       _fsReadFile
       add.w     #16,A7
       cmp.w     #0,D0
       bls.s     fsOsCommand_84
; {
; if (fsWriteFile(vparam2, ikk, vbuffer, 128) != RETURN_OK)
       pea       128
       move.l    A2,-(A7)
       move.w    -14(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    24(A6),-(A7)
       jsr       _fsWriteFile
       add.w     #16,A7
       tst.b     D0
       beq.s     fsOsCommand_86
; {
; vretfat = ERRO_B_WRITE_FILE;
       move.w    #237,D7
; break;
       bra.s     fsOsCommand_83
fsOsCommand_86:
; }
; ikk += 128;
       add.w     #128,-14(A6)
       bra.s     fsOsCommand_85
fsOsCommand_84:
; }
; else
; break;
       bra.s     fsOsCommand_83
fsOsCommand_85:
       bra       fsOsCommand_81
fsOsCommand_83:
       bra       fsOsCommand_103
fsOsCommand_73:
; }
; }
; else if (!strcmp(linhacomando,"MD") && iy == 2)
       pea       @monitorfafsOsCommand_9.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_88
       cmp.l     #2,D6
       bne.s     fsOsCommand_88
; {
; vretfat = fsMakeDir(linhaarg);
       move.l    16(A6),-(A7)
       jsr       _fsMakeDir
       addq.w    #4,A7
       and.w     #255,D0
       move.w    D0,D7
       bra       fsOsCommand_103
fsOsCommand_88:
; }
; else if (!strcmp(linhacomando,"CD") && iy == 2)
       pea       @monitorfafsOsCommand_10.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_90
       cmp.l     #2,D6
       bne.s     fsOsCommand_90
; {
; vretfat = fsChangeDir(linhaarg);
       move.l    16(A6),-(A7)
       jsr       _fsChangeDir
       addq.w    #4,A7
       and.w     #255,D0
       move.w    D0,D7
       bra       fsOsCommand_103
fsOsCommand_90:
; }
; else if (!strcmp(linhacomando,"RD") && iy == 2)
       pea       @monitorfafsOsCommand_11.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_92
       cmp.l     #2,D6
       bne.s     fsOsCommand_92
; {
; vretfat = fsRemoveDir(linhaarg);
       move.l    16(A6),-(A7)
       jsr       _fsRemoveDir
       addq.w    #4,A7
       and.w     #255,D0
       move.w    D0,D7
       bra       fsOsCommand_103
fsOsCommand_92:
; }
; else if (!strcmp(linhacomando,"DATE") && iy == 4)
       pea       @monitorfafsOsCommand_12.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_94
       cmp.l     #4,D6
       bne.s     fsOsCommand_94
; {
; /*            vpicret = 1;
; sendPic(ix + 1);
; sendPic(picDOSdate);*/
; }
       bra       fsOsCommand_103
fsOsCommand_94:
; else if (!strcmp(linhacomando,"TIME") && iy == 4)
       pea       @monitorfafsOsCommand_13.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_96
       cmp.l     #4,D6
       bne.s     fsOsCommand_96
; {
; /*            vpicret = 1;
; sendPic(ix + 1);
; sendPic(picDOStime);*/
; }
       bra       fsOsCommand_103
fsOsCommand_96:
; else if (!strcmp(linhacomando,"FORMAT") && iy == 6)
       pea       @monitorfafsOsCommand_14.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_98
       cmp.l     #6,D6
       bne.s     fsOsCommand_98
; {
; vretfat = fsFormat(0x5678, linhaarg);
       move.l    16(A6),-(A7)
       pea       22136
       jsr       _fsFormat
       addq.w    #8,A7
       and.w     #255,D0
       move.w    D0,D7
       bra       fsOsCommand_103
fsOsCommand_98:
; }
; else if (!strcmp(linhacomando,"CAT") && iy == 3)
       pea       @monitorfafsOsCommand_15.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_100
       cmp.l     #3,D6
       bne.s     fsOsCommand_100
; {
; catFile(linhaarg);
       move.l    16(A6),-(A7)
       jsr       _catFile
       addq.w    #4,A7
; ix = 255;
       move.w    #255,D2
       bra       fsOsCommand_103
fsOsCommand_100:
; }
; else
; {
; // Verifica se tem Arquivo com esse nome na pasta atual no disco
; ix = iy;
       move.w    D6,D2
; linhacomando[ix] = '.';
       move.l    D5,A0
       and.l     #65535,D2
       move.b    #46,0(A0,D2.L)
; ix++;
       addq.w    #1,D2
; linhacomando[ix] = 'B';
       move.l    D5,A0
       and.l     #65535,D2
       move.b    #66,0(A0,D2.L)
; ix++;
       addq.w    #1,D2
; linhacomando[ix] = 'I';
       move.l    D5,A0
       and.l     #65535,D2
       move.b    #73,0(A0,D2.L)
; ix++;
       addq.w    #1,D2
; linhacomando[ix] = 'N';
       move.l    D5,A0
       and.l     #65535,D2
       move.b    #78,0(A0,D2.L)
; ix++;
       addq.w    #1,D2
; linhacomando[ix] = '\0';
       move.l    D5,A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; vretfat = fsFindInDir(linhacomando, TYPE_FILE);
       pea       2
       move.l    D5,-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       move.w    D0,D7
; if (vretfat <= ERRO_D_START)
       cmp.w     #65520,D7
       bhi       fsOsCommand_102
; {
; // Se tiver, carrega em 0x00810000 e executa
; loadFile(linhacomando, (unsigned long*)0x00810000);
       pea       8454144
       move.l    D5,-(A7)
       jsr       _loadFile
       addq.w    #8,A7
; if (!*verroSo)
       move.l    _verroSo.L,A0
       tst.w     (A0)
       bne.s     fsOsCommand_104
; {
; runCmd();
       jsr       _runCmd
       bra.s     fsOsCommand_105
fsOsCommand_104:
; }
; else
; {
; printText("Loading File Error...\n\0");
       pea       @monitorfafsOsCommand_16.L
       jsr       _printText
       addq.w    #4,A7
; return 0;
       clr.b     D0
       bra       fsOsCommand_106
fsOsCommand_105:
; }
; ix = 255;
       move.w    #255,D2
       bra.s     fsOsCommand_103
fsOsCommand_102:
; }
; else
; {
; // Se nao tiver, mostra erro
; printText("Invalid Command or File Name\n\0");
       pea       @monitorfafsOsCommand_17.L
       jsr       _printText
       addq.w    #4,A7
; return 0;
       clr.b     D0
       bra       fsOsCommand_106
fsOsCommand_103:
; }
; }
; if (ix != 255)
       cmp.w     #255,D2
       beq       fsOsCommand_133
; {
; if (vretfat != RETURN_OK)
       tst.w     D7
       beq.s     fsOsCommand_109
; {
; printText("Command unsuccessfully\n\0");
       pea       @monitorfafsOsCommand_18.L
       jsr       _printText
       addq.w    #4,A7
; return 0;
       clr.b     D0
       bra       fsOsCommand_106
fsOsCommand_109:
; }
; else
; {
; if (!strcmp(linhacomando,"CD"))
       pea       @monitorfafsOsCommand_10.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne       fsOsCommand_111
; {
; if (linhaarg[0] == '.' && linhaarg[1] == '.')
       move.l    16(A6),A0
       move.b    (A0),D0
       cmp.b     #46,D0
       bne       fsOsCommand_113
       move.l    16(A6),A0
       move.b    1(A0),D0
       cmp.b     #46,D0
       bne       fsOsCommand_113
; {
; while (*vdiratup != '/')
fsOsCommand_115:
       move.l    _vdiratup.L,A0
       move.b    (A0),D0
       cmp.b     #47,D0
       beq.s     fsOsCommand_117
; {
; *vdiratup-- = '\0';
       move.l    _vdiratup.L,A0
       subq.l    #1,_vdiratup.L
       clr.b     (A0)
       bra       fsOsCommand_115
fsOsCommand_117:
; }
; if (vdiratup > vdiratu)
       move.l    _vdiratup.L,D0
       cmp.l     _vdiratu.L,D0
       bls.s     fsOsCommand_118
; *vdiratup = '\0';
       move.l    _vdiratup.L,A0
       clr.b     (A0)
       bra.s     fsOsCommand_119
fsOsCommand_118:
; else
; *vdiratup++;
       move.l    _vdiratup.L,A0
       addq.l    #1,_vdiratup.L
fsOsCommand_119:
       bra       fsOsCommand_122
fsOsCommand_113:
; }
; else if(linhaarg[0] == '/')
       move.l    16(A6),A0
       move.b    (A0),D0
       cmp.b     #47,D0
       bne.s     fsOsCommand_120
; {
; vdiratup = vdiratu;
       move.l    _vdiratu.L,_vdiratup.L
; *vdiratup++ = '/';
       move.l    _vdiratup.L,A0
       addq.l    #1,_vdiratup.L
       move.b    #47,(A0)
; *vdiratup = '\0';
       move.l    _vdiratup.L,A0
       clr.b     (A0)
       bra       fsOsCommand_122
fsOsCommand_120:
; }
; else if(linhaarg[0] != '.')
       move.l    16(A6),A0
       move.b    (A0),D0
       cmp.b     #46,D0
       beq       fsOsCommand_122
; {
; *vdiratup--;
       move.l    _vdiratup.L,A0
       subq.l    #1,_vdiratup.L
; if (*vdiratup++ != '/')
       move.l    _vdiratup.L,A0
       addq.l    #1,_vdiratup.L
       move.b    (A0),D0
       cmp.b     #47,D0
       beq.s     fsOsCommand_124
; *vdiratup++ = '/';
       move.l    _vdiratup.L,A0
       addq.l    #1,_vdiratup.L
       move.b    #47,(A0)
fsOsCommand_124:
; for (varg = 0; varg < ix; varg++)
       clr.w     D3
fsOsCommand_126:
       cmp.w     D2,D3
       bhs.s     fsOsCommand_128
; *vdiratup++ = linhaarg[varg];
       move.l    16(A6),A0
       and.l     #65535,D3
       move.l    _vdiratup.L,A1
       addq.l    #1,_vdiratup.L
       move.b    0(A0,D3.L),(A1)
       addq.w    #1,D3
       bra       fsOsCommand_126
fsOsCommand_128:
; *vdiratup = '\0';
       move.l    _vdiratup.L,A0
       clr.b     (A0)
fsOsCommand_122:
       bra       fsOsCommand_133
fsOsCommand_111:
; }
; }
; else if (!strcmp(linhacomando,"DATE"))
       pea       @monitorfafsOsCommand_12.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_129
; {
; /*                    for(ix = 0; ix <= 9; ix++)
; {
; recPic();
; vlinha[ix] = vbytepic;
; }*/
; vlinha[ix] = '\0';
       and.l     #65535,D2
       clr.b     0(A3,D2.L)
; printText("  Date is \0");
       pea       @monitorfafsOsCommand_19.L
       jsr       _printText
       addq.w    #4,A7
; printText(vlinha);
       move.l    A3,-(A7)
       jsr       _printText
       addq.w    #4,A7
; printText("\n\0");
       pea       @monitorfafsOsCommand_5.L
       jsr       _printText
       addq.w    #4,A7
       bra       fsOsCommand_133
fsOsCommand_129:
; }
; else if (!strcmp(linhacomando,"TIME"))
       pea       @monitorfafsOsCommand_13.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_131
; {
; /*                    for(ix = 0; ix <= 7; ix++)
; {
; recPic();
; vlinha[ix] = vbytepic;
; }*/
; vlinha[ix] = '\0';
       and.l     #65535,D2
       clr.b     0(A3,D2.L)
; printText("  Time is \0");
       pea       @monitorfafsOsCommand_20.L
       jsr       _printText
       addq.w    #4,A7
; printText(vlinha);
       move.l    A3,-(A7)
       jsr       _printText
       addq.w    #4,A7
; printText("\n\0");
       pea       @monitorfafsOsCommand_5.L
       jsr       _printText
       addq.w    #4,A7
       bra.s     fsOsCommand_133
fsOsCommand_131:
; }
; else if (!strcmp(linhacomando,"FORMAT"))
       pea       @monitorfafsOsCommand_14.L
       move.l    D5,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     fsOsCommand_133
; {
; printText("Format disk was successfully\n\0");
       pea       @monitorfafsOsCommand_21.L
       jsr       _printText
       addq.w    #4,A7
fsOsCommand_133:
; }
; }
; }
; }
; return 1;
       moveq     #1,D0
fsOsCommand_106:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; unsigned char fsMountDisk(void)
; {
       xdef      _fsMountDisk
_fsMountDisk:
       movem.l   A2/A3,-(A7)
       lea       _vdisk.L,A2
       lea       _gDataBuffer.L,A3
; // LER BOOT SECTOR
; if (!fsSectorRead((unsigned short)0x0000,gDataBuffer))
       move.l    (A3),-(A7)
       clr.l     -(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsMountDisk_1
; return ERRO_B_READ_DISK;
       move.b    #225,D0
       bra       fsMountDisk_3
fsMountDisk_1:
; vdisk->firsts = 0;
       move.l    (A2),A0
       clr.w     (A0)
; vdisk->reserv  = (unsigned short)gDataBuffer[15] << 8;	//ok
       move.l    (A3),A0
       move.b    15(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A2),A0
       move.w    D0,26(A0)
; vdisk->reserv |= (unsigned short)gDataBuffer[14];
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    14(A1),D0
       and.w     #255,D0
       or.w      D0,26(A0)
; vdisk->secpertrack  = (unsigned short)gDataBuffer[25] << 8;	//ok
       move.l    (A3),A0
       move.b    25(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A2),A0
       move.w    D0,20(A0)
; vdisk->secpertrack |= (unsigned short)gDataBuffer[24];
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    24(A1),D0
       and.w     #255,D0
       or.w      D0,20(A0)
; vdisk->numheads  = (unsigned short)gDataBuffer[27] << 8;	//ok
       move.l    (A3),A0
       move.b    27(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A2),A0
       move.w    D0,14(A0)
; vdisk->numheads |= (unsigned short)gDataBuffer[26];
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    26(A1),D0
       and.w     #255,D0
       or.w      D0,14(A0)
; vdisk->RootEntiesCount  = (unsigned short)gDataBuffer[18] << 8;
       move.l    (A3),A0
       move.b    18(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A2),A0
       move.w    D0,12(A0)
; vdisk->RootEntiesCount |= (unsigned short)gDataBuffer[17];
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    17(A1),D0
       and.w     #255,D0
       or.w      D0,12(A0)
; vdisk->NumberOfFATs = (unsigned char)gDataBuffer[16];
       move.l    (A3),A0
       move.l    (A2),A1
       move.b    16(A0),24(A1)
; vdisk->fat = vdisk->reserv + vdisk->firsts;	//ok
       move.l    (A2),A0
       move.w    26(A0),D0
       move.l    (A2),A0
       add.w     (A0),D0
       move.l    (A2),A0
       move.w    D0,2(A0)
; vdisk->sectorSize  = (unsigned short)gDataBuffer[12] << 8;	//ok
       move.l    (A3),A0
       move.b    12(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A2),A0
       move.w    D0,16(A0)
; vdisk->sectorSize |= (unsigned short)gDataBuffer[11];
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    11(A1),D0
       and.w     #255,D0
       or.w      D0,16(A0)
; vdisk->SecPerClus = gDataBuffer[13];	//ok
       move.l    (A3),A0
       move.l    (A2),A1
       move.b    13(A0),28(A1)
; vdisk->secperfat  = (unsigned short)gDataBuffer[11] << 8; // ok com sector per fat
       move.l    (A3),A0
       move.b    11(A0),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A2),A0
       move.w    D0,18(A0)
; vdisk->secperfat |= (unsigned short)gDataBuffer[10];
       move.l    (A2),A0
       move.l    (A3),A1
       move.b    10(A1),D0
       and.w     #255,D0
       or.w      D0,18(A0)
; vdisk->fatsize = vdisk->secperfat * vdisk->sectorSize;	// Fat Size
       move.l    (A2),A0
       move.w    18(A0),D0
       move.l    (A2),A0
       mulu.w    16(A0),D0
       move.l    (A2),A0
       move.w    D0,22(A0)
; vdisk->root  = vdisk->fat + (vdisk->NumberOfFATs * vdisk->secperfat);
       move.l    (A2),A0
       move.w    2(A0),D0
       move.l    (A2),A0
       move.b    24(A0),D1
       and.w     #255,D1
       move.l    (A2),A0
       mulu.w    18(A0),D1
       add.w     D1,D0
       move.l    (A2),A0
       move.w    D0,4(A0)
; vdisk->type = FAT16;
       move.l    (A2),A0
       move.b    #3,29(A0)
; vdisk->data = vdisk->root + ((vdisk->RootEntiesCount * 32) / vdisk->sectorSize);
       move.l    (A2),A0
       move.w    4(A0),D0
       move.l    (A2),A0
       move.w    12(A0),D1
       mulu.w    #32,D1
       move.l    (A2),A0
       and.l     #65535,D1
       divu.w    16(A0),D1
       add.w     D1,D0
       move.l    (A2),A0
       move.w    D0,6(A0)
; *vclusterdir = vdisk->root;
       move.l    (A2),A0
       move.l    _vclusterdir.L,A1
       move.w    4(A0),(A1)
; return RETURN_OK;
       clr.b     D0
fsMountDisk_3:
       movem.l   (A7)+,A2/A3
       rts
; }
; //-------------------------------------------------------------------------
; void fsSetClusterDir (unsigned short vclusdiratu) {
       xdef      _fsSetClusterDir
_fsSetClusterDir:
       link      A6,#0
; *vclusterdir = vclusdiratu;
       move.l    _vclusterdir.L,A0
       move.w    10(A6),(A0)
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned short fsGetClusterDir (void) {
       xdef      _fsGetClusterDir
_fsGetClusterDir:
; return *vclusterdir;
       move.l    _vclusterdir.L,A0
       move.w    (A0),D0
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsCreateFile(char * vfilename)
; {
       xdef      _fsCreateFile
_fsCreateFile:
       link      A6,#0
; // Verifica ja existe arquivo com esse nome
; if (fsFindInDir(vfilename, TYPE_ALL) < ERRO_D_START)
       pea       255
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       bhs.s     fsCreateFile_1
; return ERRO_B_FILE_FOUND;
       move.b    #232,D0
       bra.s     fsCreateFile_3
fsCreateFile_1:
; // Cria o arquivo com o nome especificado
; if (fsFindInDir(vfilename, TYPE_CREATE_FILE) >= ERRO_D_START)
       pea       4
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsCreateFile_4
; return ERRO_B_CREATE_FILE;
       move.b    #230,D0
       bra.s     fsCreateFile_3
fsCreateFile_4:
; return RETURN_OK;
       clr.b     D0
fsCreateFile_3:
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsOpenFile(char * vfilename)
; {
       xdef      _fsOpenFile
_fsOpenFile:
       link      A6,#-32
       move.l    A2,-(A7)
       lea       -26(A6),A2
; unsigned short vdirdate, vbytepic;
; unsigned char ds1307[7], ix, vlinha[12], vtemp[5];
; // Abre o arquivo especificado
; if (fsFindInDir(vfilename, TYPE_FILE) >= ERRO_D_START)
       pea       2
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsOpenFile_1
; return ERRO_B_FILE_NOT_FOUND;
       move.b    #224,D0
       bra       fsOpenFile_3
fsOpenFile_1:
; // Ler Data/Hora
; getDateTimeAtu(ds1307);	// 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano
       move.l    A2,-(A7)
       jsr       _getDateTimeAtu
       addq.w    #4,A7
; // Converte para a Data/Hora da FAT16
; vdirdate = datetimetodir(ds1307[3], ds1307[4], ds1307[5], CONV_DATA);
       pea       1
       move.b    5(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _datetimetodir
       add.w     #16,A7
       move.w    D0,-30(A6)
; // Grava nova data no lastaccess
; vdir->LastAccessDate  = vdirdate;
       move.l    _vdir.L,A0
       move.w    -30(A6),20(A0)
; if (fsUpdateDir() != RETURN_OK)
       jsr       _fsUpdateDir
       tst.b     D0
       beq.s     fsOpenFile_4
; return ERRO_B_UPDATE_DIR;
       move.b    #233,D0
       bra.s     fsOpenFile_3
fsOpenFile_4:
; return RETURN_OK;
       clr.b     D0
fsOpenFile_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsCloseFile(char * vfilename, unsigned char vupdated)
; {
       xdef      _fsCloseFile
_fsCloseFile:
       link      A6,#-32
       movem.l   D2/A2/A3,-(A7)
       lea       -26(A6),A2
       lea       _vdir.L,A3
; unsigned short vdirdate, vdirtime, vbytepic;
; unsigned char ds1307[7], vtemp[5], ix, vlinha[12];
; if (fsFindInDir(vfilename, TYPE_FILE) < ERRO_D_START) {
       pea       2
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       bhs       fsCloseFile_1
; if (vupdated) {
       tst.b     15(A6)
       beq       fsCloseFile_5
; // Ler Data/Hora
; getDateTimeAtu(ds1307);	// 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano
       move.l    A2,-(A7)
       jsr       _getDateTimeAtu
       addq.w    #4,A7
; // Converte para a Data/Hora da FAT16
; vdirtime = datetimetodir(ds1307[0], ds1307[1], ds1307[2], CONV_HORA);
       pea       2
       move.b    2(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    1(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    (A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _datetimetodir
       add.w     #16,A7
       move.w    D0,-30(A6)
; vdirdate = datetimetodir(ds1307[3], ds1307[4], ds1307[5], CONV_DATA);
       pea       1
       move.b    5(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _datetimetodir
       add.w     #16,A7
       move.w    D0,D2
; // Grava nova data no lastaccess e nova data/hora no update date/time
; vdir->LastAccessDate  = vdirdate;
       move.l    (A3),A0
       move.w    D2,20(A0)
; vdir->UpdateTime = vdirtime;
       move.l    (A3),A0
       move.w    -30(A6),24(A0)
; vdir->UpdateDate = vdirdate;
       move.l    (A3),A0
       move.w    D2,22(A0)
; if (fsUpdateDir() != RETURN_OK)
       jsr       _fsUpdateDir
       tst.b     D0
       beq.s     fsCloseFile_5
; return ERRO_B_UPDATE_DIR;
       move.b    #233,D0
       bra.s     fsCloseFile_7
fsCloseFile_5:
       bra.s     fsCloseFile_2
fsCloseFile_1:
; }
; }
; else
; return ERRO_B_NOT_FOUND;
       move.b    #255,D0
       bra.s     fsCloseFile_7
fsCloseFile_2:
; return RETURN_OK;
       clr.b     D0
fsCloseFile_7:
       movem.l   (A7)+,D2/A2/A3
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned long fsInfoFile(char * vfilename, unsigned char vtype)
; {
       xdef      _fsInfoFile
_fsInfoFile:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _vdir.L,A2
; unsigned long vinfo = ERRO_D_NOT_FOUND, vtemp;
       move.l    #65535,D2
; // retornar as informa?es conforme solicitado.
; if (fsFindInDir(vfilename, TYPE_FILE) < ERRO_D_START) {
       pea       2
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       bhs       fsInfoFile_1
; switch (vtype) {
       move.b    15(A6),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo       fsInfoFile_4
       cmp.l     #4,D0
       bhs       fsInfoFile_4
       asl.l     #1,D0
       move.w    fsInfoFile_5(PC,D0.L),D0
       jmp       fsInfoFile_5(PC,D0.W)
fsInfoFile_5:
       dc.w      fsInfoFile_6-fsInfoFile_5
       dc.w      fsInfoFile_7-fsInfoFile_5
       dc.w      fsInfoFile_8-fsInfoFile_5
       dc.w      fsInfoFile_9-fsInfoFile_5
fsInfoFile_6:
; case INFO_SIZE:
; vinfo = vdir->Size;
       move.l    (A2),A0
       move.l    28(A0),D2
; break;
       bra       fsInfoFile_4
fsInfoFile_7:
; case INFO_CREATE:
; vtemp = (vdir->CreateDate << 16) | vdir->CreateTime;
       move.l    (A2),A0
       move.w    16(A0),D0
       and.l     #65535,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    (A2),A0
       move.w    18(A0),D1
       and.l     #65535,D1
       or.l      D1,D0
       move.l    D0,D3
; vinfo = (vtemp);
       move.l    D3,D2
; break;
       bra       fsInfoFile_4
fsInfoFile_8:
; case INFO_UPDATE:
; vtemp = (vdir->UpdateDate << 16) | vdir->UpdateTime;
       move.l    (A2),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    (A2),A0
       move.w    24(A0),D1
       and.l     #65535,D1
       or.l      D1,D0
       move.l    D0,D3
; vinfo = (vtemp);
       move.l    D3,D2
; break;
       bra.s     fsInfoFile_4
fsInfoFile_9:
; case INFO_LAST:
; vinfo = vdir->LastAccessDate;
       move.l    (A2),A0
       move.w    20(A0),D0
       and.l     #65535,D0
       move.l    D0,D2
; break;
fsInfoFile_4:
       bra.s     fsInfoFile_2
fsInfoFile_1:
; }
; }
; else
; return ERRO_D_NOT_FOUND;
       move.l    #65535,D0
       bra.s     fsInfoFile_10
fsInfoFile_2:
; return vinfo;
       move.l    D2,D0
fsInfoFile_10:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsDelFile(char * vfilename)
; {
       xdef      _fsDelFile
_fsDelFile:
       link      A6,#0
; // Apaga o arquivo solicitado
; if (fsFindInDir(vfilename, TYPE_DEL_FILE) >= ERRO_D_START)
       pea       6
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsDelFile_1
; return ERRO_B_APAGAR_ARQUIVO;
       move.b    #231,D0
       bra.s     fsDelFile_3
fsDelFile_1:
; return RETURN_OK;
       clr.b     D0
fsDelFile_3:
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsRenameFile(char * vfilename, char * vnewname)
; {
       xdef      _fsRenameFile
_fsRenameFile:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/A2,-(A7)
       move.l    12(A6),D4
       lea       _vdir.L,A2
; unsigned long vclusterfile;
; unsigned short ikk;
; unsigned char ixx, iyy;
; // Verificar se nome j?nao existe
; vclusterfile = fsFindInDir(vnewname, TYPE_ALL);
       pea       255
       move.l    D4,-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       move.l    D0,D5
; if (vclusterfile < ERRO_D_START)
       cmp.l     #65520,D5
       bhs.s     fsRenameFile_1
; return ERRO_B_FILE_FOUND;
       move.b    #232,D0
       bra       fsRenameFile_3
fsRenameFile_1:
; // Procura arquivo a ser renomeado
; vclusterfile = fsFindInDir(vfilename, TYPE_FILE);
       pea       2
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       move.l    D0,D5
; if (vclusterfile >= ERRO_D_START)
       cmp.l     #65520,D5
       blo.s     fsRenameFile_4
; return ERRO_B_FILE_NOT_FOUND;
       move.b    #224,D0
       bra       fsRenameFile_3
fsRenameFile_4:
; // Altera nome na estrutura vdir
; memset(vdir->Name, 0x20, 8);
       pea       8
       pea       32
       move.l    (A2),-(A7)
       jsr       _memset
       add.w     #12,A7
; memset(vdir->Ext, 0x20, 3);
       pea       3
       pea       32
       moveq     #10,D1
       add.l     (A2),D1
       move.l    D1,-(A7)
       jsr       _memset
       add.w     #12,A7
; iyy = 0;
       clr.b     D3
; for (ixx = 0; ixx <= strlen(vnewname); ixx++) {
       clr.b     D2
fsRenameFile_6:
       and.l     #255,D2
       move.l    D4,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     D0,D2
       bhi       fsRenameFile_8
; if (vnewname[ixx] == '\0')
       move.l    D4,A0
       and.l     #255,D2
       move.b    0(A0,D2.L),D0
       bne.s     fsRenameFile_9
; break;
       bra       fsRenameFile_8
fsRenameFile_9:
; else if (vnewname[ixx] == '.')
       move.l    D4,A0
       and.l     #255,D2
       move.b    0(A0,D2.L),D0
       cmp.b     #46,D0
       bne.s     fsRenameFile_11
; iyy = 8;
       moveq     #8,D3
       bra       fsRenameFile_12
fsRenameFile_11:
; else {
; if (iyy <= 7)
       cmp.b     #7,D3
       bhi.s     fsRenameFile_13
; vdir->Name[iyy] = vnewname[ixx];
       move.l    D4,A0
       and.l     #255,D2
       move.l    (A2),A1
       and.l     #255,D3
       move.b    0(A0,D2.L),0(A1,D3.L)
       bra.s     fsRenameFile_14
fsRenameFile_13:
; else {
; ikk = iyy - 8;
       and.w     #255,D3
       move.w    D3,D0
       subq.w    #8,D0
       move.w    D0,-2(A6)
; vdir->Ext[ikk] = vnewname[ixx];
       move.l    D4,A0
       and.l     #255,D2
       move.l    (A2),A1
       move.w    -2(A6),D0
       and.l     #65535,D0
       add.l     D0,A1
       move.b    0(A0,D2.L),10(A1)
fsRenameFile_14:
; }
; iyy++;
       addq.b    #1,D3
fsRenameFile_12:
       addq.b    #1,D2
       bra       fsRenameFile_6
fsRenameFile_8:
; }
; }
; // Altera o nome, as demais informacoes nao alteram
; if (fsUpdateDir() != RETURN_OK)
       jsr       _fsUpdateDir
       tst.b     D0
       beq.s     fsRenameFile_15
; return ERRO_B_UPDATE_DIR;
       move.b    #233,D0
       bra.s     fsRenameFile_3
fsRenameFile_15:
; return RETURN_OK;
       clr.b     D0
fsRenameFile_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; // Rotina para escrever/ler no disco
; //-------------------------------------------------------------------------
; unsigned char fsRWFile(unsigned short vclusterini, unsigned long voffset, unsigned char *buffer, unsigned char vtype)
; {
       xdef      _fsRWFile
_fsRWFile:
       link      A6,#-12
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vdisk.L,A2
       move.b    23(A6),D3
       and.l     #255,D3
       move.w    10(A6),D6
       and.l     #65535,D6
       lea       _gDataBuffer.L,A4
       move.l    16(A6),A5
; unsigned short vdata, vclusternew, vfat;
; unsigned short vpos, vsecfat, voffsec, voffclus, vtemp1, vtemp2, ikk, ikj;
; // Calcula offset de setor e cluster
; voffsec = voffset / vdisk->sectorSize;
       move.l    (A2),A0
       move.w    16(A0),D0
       and.l     #65535,D0
       move.l    12(A6),-(A7)
       move.l    D0,-(A7)
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    D0,-8(A6)
; voffclus = voffsec / vdisk->SecPerClus;
       move.w    -8(A6),D0
       move.l    (A2),A0
       move.b    28(A0),D1
       and.w     #255,D1
       and.l     #65535,D0
       divu.w    D1,D0
       move.w    D0,-6(A6)
; vclusternew = vclusterini;
       move.w    D6,D2
; // Procura o cluster onde esta o setor a ser lido
; for (vpos = 0; vpos < voffclus; vpos++) {
       clr.w     D5
fsRWFile_1:
       cmp.w     -6(A6),D5
       bhs       fsRWFile_3
; // Em operacao de escrita, como vai mexer com disco, salva buffer no setor de swap
; if (vtype == OPER_WRITE) {
       cmp.b     #2,D3
       bne.s     fsRWFile_6
; ikk = vdisk->fat - 1;
       move.l    (A2),A0
       move.w    2(A0),D0
       subq.w    #1,D0
       move.w    D0,D4
; if (!fsSectorWrite(ikk, buffer, FALSE))
       clr.l     -(A7)
       move.l    A5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsRWFile_6
; return ERRO_B_READ_DISK;
       move.b    #225,D0
       bra       fsRWFile_8
fsRWFile_6:
; }
; vclusternew = fsFindNextCluster(vclusterini, NEXT_FIND);
       pea       5
       and.l     #65535,D6
       move.l    D6,-(A7)
       jsr       _fsFindNextCluster
       addq.w    #8,A7
       move.w    D0,D2
; // Se for leitura e o offset der dentro do ultimo cluster, sai
; if (vtype == OPER_READ && vclusternew == LAST_CLUSTER_FAT16)
       cmp.b     #1,D3
       bne.s     fsRWFile_9
       cmp.w     #65535,D2
       bne.s     fsRWFile_9
; return RETURN_OK;
       clr.b     D0
       bra       fsRWFile_8
fsRWFile_9:
; // Se for gravacao e o offset der dentro do ultimo cluster, cria novo cluster
; if ((vtype == OPER_WRITE || vtype == OPER_READWRITE) && vclusternew == LAST_CLUSTER_FAT16) {
       cmp.b     #2,D3
       beq.s     fsRWFile_13
       cmp.b     #3,D3
       bne       fsRWFile_18
fsRWFile_13:
       cmp.w     #65535,D2
       bne       fsRWFile_18
; // Calcula novo cluster livre
; vclusternew = fsFindClusterFree(FREE_USE);
       pea       2
       jsr       _fsFindClusterFree
       addq.w    #4,A7
       move.w    D0,D2
; if (vclusternew == ERRO_D_DISK_FULL)
       cmp.w     #65524,D2
       bne.s     fsRWFile_14
; return ERRO_B_DISK_FULL;
       move.b    #235,D0
       bra       fsRWFile_8
fsRWFile_14:
; // Procura Cluster atual para altera?o
; vsecfat = vclusterini / 64;
       move.w    D6,D0
       and.l     #65535,D0
       divu.w    #64,D0
       move.w    D0,-10(A6)
; vfat = vdisk->fat + vsecfat;
       move.l    (A2),A0
       move.w    2(A0),D0
       add.w     -10(A6),D0
       move.w    D0,-12(A6)
; if (!fsSectorRead(vfat, gDataBuffer))
       move.l    (A4),-(A7)
       move.w    -12(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsRWFile_16
; return ERRO_B_READ_DISK;
       move.b    #225,D0
       bra       fsRWFile_8
fsRWFile_16:
; // Grava novo cluster no cluster atual
; vpos = (vclusterini - (64 * vsecfat)) * 2;
       move.w    D6,D0
       move.w    -10(A6),D1
       mulu.w    #64,D1
       sub.w     D1,D0
       mulu.w    #2,D0
       move.w    D0,D5
; gDataBuffer[vpos] = (unsigned char)(vclusternew & 0xFF);
       move.w    D2,D0
       and.w     #255,D0
       move.l    (A4),A0
       and.l     #65535,D5
       move.b    D0,0(A0,D5.L)
; ikk = vpos + 1;
       move.w    D5,D0
       addq.w    #1,D0
       move.w    D0,D4
; gDataBuffer[ikk] = (unsigned char)((vclusternew / 0x100) & 0xFF);
       move.w    D2,D0
       and.l     #65535,D0
       divu.w    #256,D0
       and.w     #255,D0
       move.l    (A4),A0
       and.l     #65535,D4
       move.b    D0,0(A0,D4.L)
; if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A4),-(A7)
       move.w    -12(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsRWFile_18
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra       fsRWFile_8
fsRWFile_18:
; }
; vclusterini = vclusternew;
       move.w    D2,D6
; // Em operacao de escrita, como mexeu com disco, le o buffer salvo no setor swap
; if (vtype == OPER_WRITE) {
       cmp.b     #2,D3
       bne.s     fsRWFile_22
; ikk = vdisk->fat - 1;
       move.l    (A2),A0
       move.w    2(A0),D0
       subq.w    #1,D0
       move.w    D0,D4
; if (!fsSectorRead(ikk, buffer))
       move.l    A5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsRWFile_22
; return ERRO_B_READ_DISK;
       move.b    #225,D0
       bra       fsRWFile_8
fsRWFile_22:
       addq.w    #1,D5
       bra       fsRWFile_1
fsRWFile_3:
; }
; }
; // Posiciona no setor dentro do cluster para ler/gravar
; vtemp1 = ((vclusternew - 2) * vdisk->SecPerClus);
       move.w    D2,D0
       subq.w    #2,D0
       move.l    (A2),A0
       move.b    28(A0),D1
       and.w     #255,D1
       mulu.w    D1,D0
       move.w    D0,A3
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A2),A0
       move.w    26(A0),D0
       move.l    (A2),A0
       add.w     (A0),D0
       move.l    (A2),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       add.w     D1,D0
       move.w    D0,-4(A6)
; vdata = vtemp1 + vtemp2;
       move.w    A3,D0
       add.w     -4(A6),D0
       move.w    D0,D7
; vtemp1 = (voffclus * vdisk->SecPerClus);
       move.w    -6(A6),D0
       move.l    (A2),A0
       move.b    28(A0),D1
       and.w     #255,D1
       mulu.w    D1,D0
       move.w    D0,A3
; vdata += voffsec - vtemp1;
       move.w    -8(A6),D0
       sub.w     A3,D0
       add.w     D0,D7
; if (vtype == OPER_READ || vtype == OPER_READWRITE) {
       cmp.b     #1,D3
       beq.s     fsRWFile_26
       cmp.b     #3,D3
       bne.s     fsRWFile_24
fsRWFile_26:
; // Le o setor e coloca no buffer
; if (!fsSectorRead(vdata, buffer))
       move.l    A5,-(A7)
       and.l     #65535,D7
       move.l    D7,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsRWFile_27
; return ERRO_B_READ_DISK;
       move.b    #225,D0
       bra.s     fsRWFile_8
fsRWFile_27:
       bra.s     fsRWFile_29
fsRWFile_24:
; }
; else {
; // Grava o buffer no setor
; if (!fsSectorWrite(vdata, buffer, FALSE))
       clr.l     -(A7)
       move.l    A5,-(A7)
       and.l     #65535,D7
       move.l    D7,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsRWFile_29
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra.s     fsRWFile_8
fsRWFile_29:
; }
; return RETURN_OK;
       clr.b     D0
fsRWFile_8:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; // Retorna um buffer de "vsize" (max 255) Bytes, a partir do "voffset".
; //-------------------------------------------------------------------------
; unsigned short fsReadFile(char * vfilename, unsigned long voffset, unsigned char *buffer, unsigned short vsizebuffer)
; {
       xdef      _fsReadFile
_fsReadFile:
       link      A6,#-20
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    12(A6),D2
       lea       _vdisk.L,A2
       move.w    22(A6),D7
       and.l     #65535,D7
; unsigned short ix, iy, vsizebf = 0;
       clr.w     D5
; unsigned short vsize, vsetor = 0, vsizeant = 0;
       move.w    #0,A5
       move.w    #0,A4
; unsigned short voffsec, vtemp, ikk, ikj;
; unsigned short vclusterini;
; unsigned char sqtdtam[10];
; vclusterini = fsFindInDir(vfilename, TYPE_FILE);
       pea       2
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       move.w    D0,-12(A6)
; if (vclusterini >= ERRO_D_START)
       move.w    -12(A6),D0
       cmp.w     #65520,D0
       blo.s     fsReadFile_1
; return 0;	// Erro na abertura/Arquivo nao existe
       clr.w     D0
       bra       fsReadFile_3
fsReadFile_1:
; // Verifica se o offset eh maior que o tamanho do arquivo
; if (voffset > vdir->Size)
       move.l    _vdir.L,A0
       cmp.l     28(A0),D2
       bls.s     fsReadFile_4
; return 0;
       clr.w     D0
       bra       fsReadFile_3
fsReadFile_4:
; // Verifica se offset vai precisar gravar mais de 1 setor (entre 2 setores)
; vtemp = voffset / vdisk->sectorSize;
       move.l    (A2),A0
       move.w    16(A0),D0
       and.l     #65535,D0
       move.l    D2,-(A7)
       move.l    D0,-(A7)
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    D0,A3
; voffsec = (voffset - (vdisk->sectorSize * (vtemp)));
       move.l    D2,D0
       move.l    (A2),A0
       move.w    16(A0),D1
       move.l    D0,-(A7)
       move.w    A3,D0
       mulu.w    D0,D1
       move.l    (A7)+,D0
       and.l     #65535,D1
       sub.l     D1,D0
       move.w    D0,D4
; if ((voffsec + vsizebuffer) > vdisk->sectorSize)
       move.w    D4,D0
       add.w     D7,D0
       move.l    (A2),A0
       cmp.w     16(A0),D0
       bls.s     fsReadFile_6
; vsetor = 1;
       move.w    #1,A5
fsReadFile_6:
; /*itoa(vsetor, sqtdtam, 10);
; printText(sqtdtam);
; printText(".\n\0");*/
; /*itoa(voffsec, sqtdtam, 10);
; printText(sqtdtam);
; printText(".\n\0");*/
; /*itoa(vdisk->sectorSize, sqtdtam, 10);
; printText(sqtdtam);
; printText(".\n\0");*/
; /*itoa(voffset, sqtdtam, 10);
; printText(sqtdtam);
; printText(".\n\0");*/
; /*itoa(vsizebuffer, sqtdtam, 10);
; printText(sqtdtam);
; printText(".\n\0");*/
; for (ix = 0; ix <= vsetor; ix++) {
       clr.w     -18(A6)
fsReadFile_8:
       move.w    A5,D0
       cmp.w     -18(A6),D0
       blo       fsReadFile_10
; vtemp = voffset / vdisk->sectorSize;
       move.l    (A2),A0
       move.w    16(A0),D0
       and.l     #65535,D0
       move.l    D2,-(A7)
       move.l    D0,-(A7)
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    D0,A3
; voffsec = (voffset - (vdisk->sectorSize * (vtemp)));
       move.l    D2,D0
       move.l    (A2),A0
       move.w    16(A0),D1
       move.l    D0,-(A7)
       move.w    A3,D0
       mulu.w    D0,D1
       move.l    (A7)+,D0
       and.l     #65535,D1
       sub.l     D1,D0
       move.w    D0,D4
; // Ler setor do offset
; if (fsRWFile(vclusterini, voffset, gDataBuffer, OPER_READ) != RETURN_OK)
       pea       1
       move.l    _gDataBuffer.L,-(A7)
       move.l    D2,-(A7)
       move.w    -12(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsRWFile
       add.w     #16,A7
       tst.b     D0
       beq.s     fsReadFile_11
; return vsizebf;
       move.w    D5,D0
       bra       fsReadFile_3
fsReadFile_11:
; // Verifica tamanho a ser gravado
; if ((voffsec + vsizebuffer) <= vdisk->sectorSize)
       move.w    D4,D0
       add.w     D7,D0
       move.l    (A2),A0
       cmp.w     16(A0),D0
       bhi.s     fsReadFile_13
; vsize = vsizebuffer - vsizeant;
       move.w    D7,D0
       sub.w     A4,D0
       move.w    D0,D3
       bra.s     fsReadFile_14
fsReadFile_13:
; else
; vsize = vdisk->sectorSize - voffsec;
       move.l    (A2),A0
       move.w    16(A0),D0
       sub.w     D4,D0
       move.w    D0,D3
fsReadFile_14:
; vsizebf += vsize;
       add.w     D3,D5
; if (vsizebf > (vdir->Size - voffset))
       and.l     #65535,D5
       move.l    _vdir.L,A0
       move.l    28(A0),D0
       sub.l     D2,D0
       cmp.l     D0,D5
       bls.s     fsReadFile_15
; vsizebf = vdir->Size - voffset;
       move.l    _vdir.L,A0
       move.l    28(A0),D0
       sub.l     D2,D0
       move.w    D0,D5
fsReadFile_15:
; /*itoa(vsize, sqtdtam, 10);
; printText(sqtdtam);
; printText(".\n\0");*/
; if (vsetor == 0)
       move.w    A5,D0
       bne.s     fsReadFile_17
; vsize = vsizebuffer;
       move.w    D7,D3
fsReadFile_17:
; // Retorna os dados no buffer
; for (iy = 0; iy < vsize; iy++) {
       clr.w     D6
fsReadFile_19:
       cmp.w     D3,D6
       bhs.s     fsReadFile_21
; ikk = vsizeant + iy;
       move.w    A4,D0
       add.w     D6,D0
       move.w    D0,-16(A6)
; ikj = voffsec + iy;
       move.w    D4,D0
       add.w     D6,D0
       move.w    D0,-14(A6)
; buffer[ikk] = gDataBuffer[ikj];
       move.l    _gDataBuffer.L,A0
       move.w    -14(A6),D0
       and.l     #65535,D0
       move.l    16(A6),A1
       move.w    -16(A6),D1
       and.l     #65535,D1
       move.b    0(A0,D0.L),0(A1,D1.L)
       addq.w    #1,D6
       bra       fsReadFile_19
fsReadFile_21:
; }
; vsizeant = vsize;
       move.w    D3,A4
; voffset += vsize;
       and.l     #65535,D3
       add.l     D3,D2
       addq.w    #1,-18(A6)
       bra       fsReadFile_8
fsReadFile_10:
; }
; return vsizebf;
       move.w    D5,D0
fsReadFile_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; // buffer a ser gravado nao pode ter mais que 128 bytes
; //-------------------------------------------------------------------------
; unsigned char fsWriteFile(char * vfilename, unsigned long voffset, unsigned char *buffer, unsigned char vsizebuffer)
; {
       xdef      _fsWriteFile
_fsWriteFile:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    12(A6),D2
       lea       _vdisk.L,A2
       move.b    23(A6),D6
       and.w     #255,D6
       lea       _gDataBuffer.L,A5
; unsigned char vsetor = 0, ix, iy;
       clr.b     -6(A6)
; unsigned short vsize, vsizeant = 0;
       move.w    #0,A4
; unsigned short voffsec, vtemp, ikk, ikj;
; unsigned short vclusterini;
; vclusterini = fsFindInDir(vfilename, TYPE_FILE);
       pea       2
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       move.w    D0,A3
; if (vclusterini >= ERRO_D_START)
       move.w    A3,D0
       cmp.w     #65520,D0
       blo.s     fsWriteFile_1
; return ERRO_B_FILE_NOT_FOUND;	// Erro na abertura/Arquivo nao existe
       move.b    #224,D0
       bra       fsWriteFile_3
fsWriteFile_1:
; // Verifica se offset vai precisar gravar mais de 1 setor (entre 2 setores)
; vtemp = voffset / vdisk->sectorSize;
       move.l    (A2),A0
       move.w    16(A0),D0
       and.l     #65535,D0
       move.l    D2,-(A7)
       move.l    D0,-(A7)
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    D0,D7
; voffsec = (voffset - (vdisk->sectorSize * (vtemp)));
       move.l    D2,D0
       move.l    (A2),A0
       move.w    16(A0),D1
       mulu.w    D7,D1
       and.l     #65535,D1
       sub.l     D1,D0
       move.w    D0,D3
; if ((voffsec + vsizebuffer) > vdisk->sectorSize)
       move.w    D3,D0
       and.w     #255,D6
       add.w     D6,D0
       move.l    (A2),A0
       cmp.w     16(A0),D0
       bls.s     fsWriteFile_4
; vsetor = 1;
       move.b    #1,-6(A6)
fsWriteFile_4:
; for (ix = 0; ix <= vsetor; ix++) {
       clr.b     -5(A6)
fsWriteFile_6:
       move.b    -5(A6),D0
       cmp.b     -6(A6),D0
       bhi       fsWriteFile_8
; vtemp = voffset / vdisk->sectorSize;
       move.l    (A2),A0
       move.w    16(A0),D0
       and.l     #65535,D0
       move.l    D2,-(A7)
       move.l    D0,-(A7)
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    D0,D7
; voffsec = (voffset - (vdisk->sectorSize * (vtemp)));
       move.l    D2,D0
       move.l    (A2),A0
       move.w    16(A0),D1
       mulu.w    D7,D1
       and.l     #65535,D1
       sub.l     D1,D0
       move.w    D0,D3
; // Ler setor do offset
; if (fsRWFile(vclusterini, voffset, gDataBuffer, OPER_READWRITE) != RETURN_OK)
       pea       3
       move.l    (A5),-(A7)
       move.l    D2,-(A7)
       move.l    A3,-(A7)
       jsr       _fsRWFile
       add.w     #16,A7
       tst.b     D0
       beq.s     fsWriteFile_9
; return ERRO_B_READ_FILE;
       move.b    #236,D0
       bra       fsWriteFile_3
fsWriteFile_9:
; // Verifica tamanho a ser gravado
; if ((voffsec + vsizebuffer) <= vdisk->sectorSize)
       move.w    D3,D0
       and.w     #255,D6
       add.w     D6,D0
       move.l    (A2),A0
       cmp.w     16(A0),D0
       bhi.s     fsWriteFile_11
; vsize = vsizebuffer - vsizeant;
       move.b    D6,D0
       and.w     #255,D0
       sub.w     A4,D0
       move.w    D0,D5
       bra.s     fsWriteFile_12
fsWriteFile_11:
; else
; vsize = vdisk->sectorSize - voffsec;
       move.l    (A2),A0
       move.w    16(A0),D0
       sub.w     D3,D0
       move.w    D0,D5
fsWriteFile_12:
; // Prepara buffer para grava?o
; for (iy = 0; iy < vsize; iy++) {
       clr.b     D4
fsWriteFile_13:
       and.w     #255,D4
       cmp.w     D5,D4
       bhs       fsWriteFile_15
; ikk = iy + voffsec;
       move.b    D4,D0
       and.w     #255,D0
       add.w     D3,D0
       move.w    D0,-4(A6)
; ikj = vsizeant + iy;
       move.w    A4,D0
       and.w     #255,D4
       add.w     D4,D0
       move.w    D0,-2(A6)
; gDataBuffer[ikk] = buffer[ikj];
       move.l    16(A6),A0
       move.w    -2(A6),D0
       and.l     #65535,D0
       move.l    (A5),A1
       move.w    -4(A6),D1
       and.l     #65535,D1
       move.b    0(A0,D0.L),0(A1,D1.L)
       addq.b    #1,D4
       bra       fsWriteFile_13
fsWriteFile_15:
; }
; // Grava setor
; if (fsRWFile(vclusterini, voffset, gDataBuffer, OPER_WRITE) != RETURN_OK)
       pea       2
       move.l    (A5),-(A7)
       move.l    D2,-(A7)
       move.l    A3,-(A7)
       jsr       _fsRWFile
       add.w     #16,A7
       tst.b     D0
       beq.s     fsWriteFile_16
; return ERRO_B_WRITE_FILE;
       move.b    #237,D0
       bra       fsWriteFile_3
fsWriteFile_16:
; vsizeant = vsize;
       move.w    D5,A4
; if (vsetor == 1)
       move.b    -6(A6),D0
       cmp.b     #1,D0
       bne.s     fsWriteFile_18
; voffset += vsize;
       and.l     #65535,D5
       add.l     D5,D2
fsWriteFile_18:
       addq.b    #1,-5(A6)
       bra       fsWriteFile_6
fsWriteFile_8:
; }
; if ((voffset + vsizebuffer) > vdir->Size) {
       move.l    D2,D0
       and.l     #255,D6
       add.l     D6,D0
       move.l    _vdir.L,A0
       cmp.l     28(A0),D0
       bls.s     fsWriteFile_22
; vdir->Size = voffset + vsizebuffer;
       move.l    D2,D0
       and.l     #255,D6
       add.l     D6,D0
       move.l    _vdir.L,A0
       move.l    D0,28(A0)
; if (fsUpdateDir() != RETURN_OK)
       jsr       _fsUpdateDir
       tst.b     D0
       beq.s     fsWriteFile_22
; return ERRO_B_UPDATE_DIR;
       move.b    #233,D0
       bra.s     fsWriteFile_3
fsWriteFile_22:
; }
; return RETURN_OK;
       clr.b     D0
fsWriteFile_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsMakeDir(char * vdirname)
; {
       xdef      _fsMakeDir
_fsMakeDir:
       link      A6,#0
; // Verifica ja existe arquivo/dir com esse nome
; if (fsFindInDir(vdirname, TYPE_ALL) < ERRO_D_START)
       pea       255
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       bhs.s     fsMakeDir_1
; return ERRO_B_DIR_FOUND;
       move.b    #238,D0
       bra.s     fsMakeDir_3
fsMakeDir_1:
; // Cria o dir solicitado
; if (fsFindInDir(vdirname, TYPE_CREATE_DIR) >= ERRO_D_START)
       pea       5
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsMakeDir_4
; return ERRO_B_CREATE_DIR;
       move.b    #239,D0
       bra.s     fsMakeDir_3
fsMakeDir_4:
; return RETURN_OK;
       clr.b     D0
fsMakeDir_3:
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsChangeDir(char * vdirname)
; {
       xdef      _fsChangeDir
_fsChangeDir:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned short vclusterdirnew;
; // Troca o diretorio conforme especificado
; if (vdirname[0] == '/')
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #47,D0
       bne.s     fsChangeDir_1
; vclusterdirnew = 0x0002;
       moveq     #2,D2
       bra.s     fsChangeDir_2
fsChangeDir_1:
; else
; vclusterdirnew	= fsFindInDir(vdirname, TYPE_DIRECTORY);
       pea       1
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       move.w    D0,D2
fsChangeDir_2:
; if (vclusterdirnew >= ERRO_D_START)
       cmp.w     #65520,D2
       blo.s     fsChangeDir_3
; return ERRO_B_DIR_NOT_FOUND;
       move.b    #229,D0
       bra.s     fsChangeDir_5
fsChangeDir_3:
; // Coloca o novo diretorio como atual
; *vclusterdir = vclusterdirnew;
       move.l    _vclusterdir.L,A0
       move.w    D2,(A0)
; return RETURN_OK;
       clr.b     D0
fsChangeDir_5:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsRemoveDir(char * vdirname)
; {
       xdef      _fsRemoveDir
_fsRemoveDir:
       link      A6,#0
; // Apaga o diretorio conforme especificado
; if (fsFindInDir(vdirname, TYPE_DEL_DIR) >= ERRO_D_START)
       pea       7
       move.l    8(A6),-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #65520,D0
       blo.s     fsRemoveDir_1
; return ERRO_B_DIR_NOT_FOUND;
       move.b    #229,D0
       bra.s     fsRemoveDir_3
fsRemoveDir_1:
; return RETURN_OK;
       clr.b     D0
fsRemoveDir_3:
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsPwdDir(unsigned char *vdirpath) {
       xdef      _fsPwdDir
_fsPwdDir:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if (*vclusterdir == vdisk->root) {
       move.l    _vclusterdir.L,A0
       move.l    _vdisk.L,A1
       move.w    (A0),D0
       cmp.w     4(A1),D0
       bne.s     fsPwdDir_1
; vdirpath[0] = '/';
       move.l    D2,A0
       move.b    #47,(A0)
; vdirpath[1] = '\0';
       move.l    D2,A0
       clr.b     1(A0)
       bra.s     fsPwdDir_2
fsPwdDir_1:
; }
; else {
; vdirpath[0] = 'o';
       move.l    D2,A0
       move.b    #111,(A0)
; vdirpath[1] = '\0';
       move.l    D2,A0
       clr.b     1(A0)
fsPwdDir_2:
; }
; return RETURN_OK;
       clr.b     D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned long fsFindInDir(char * vname, unsigned char vtype)
; {
       xdef      _fsFindInDir
_fsFindInDir:
       link      A6,#-84
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _gDataBuffer.L,A2
       lea       _vdir.L,A3
       lea       _vdisk.L,A4
; unsigned long vfat, vdata, vclusterfile, vclusterdirnew, vclusteratual, vtemp1, vtemp2;
; unsigned char fnameName[9], fnameExt[4];
; unsigned short im, ix, iy, iz, vpos, vsecfat, ventrydir, ixold;
; unsigned short vdirdate, vdirtime, ikk, ikj, vtemp, vbytepic;
; unsigned char vcomp, iw, ds1307[7], iww, vtempt[5], vlinha[5];
; unsigned char sqtdtam[10];
; memset(fnameName, 0x20, 8);
       pea       8
       pea       32
       pea       -66(A6)
       jsr       _memset
       add.w     #12,A7
; memset(fnameExt, 0x20, 3);
       pea       3
       pea       32
       pea       -56(A6)
       jsr       _memset
       add.w     #12,A7
; if (vname != NULL) {
       clr.b     D0
       and.l     #255,D0
       cmp.l     8(A6),D0
       beq       fsFindInDir_9
; if (vname[0] == '.' && vname[1] == '.') {
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #46,D0
       bne.s     fsFindInDir_3
       move.l    8(A6),A0
       move.b    1(A0),D0
       cmp.b     #46,D0
       bne.s     fsFindInDir_3
; fnameName[0] = vname[0];
       move.l    8(A6),A0
       move.b    (A0),-66+0(A6)
; fnameName[1] = vname[1];
       move.l    8(A6),A0
       move.b    1(A0),-66+1(A6)
       bra       fsFindInDir_9
fsFindInDir_3:
; }
; else if (vname[0] == '.') {
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #46,D0
       bne.s     fsFindInDir_5
; fnameName[0] = vname[0];
       move.l    8(A6),A0
       move.b    (A0),-66+0(A6)
       bra       fsFindInDir_9
fsFindInDir_5:
; }
; else {
; iy = 0;
       clr.w     -50(A6)
; for (ix = 0; ix <= strlen(vname); ix++) {
       clr.w     D3
fsFindInDir_7:
       and.l     #65535,D3
       move.l    8(A6),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     D0,D3
       bhi       fsFindInDir_9
; if (vname[ix] == '\0')
       move.l    8(A6),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       bne.s     fsFindInDir_10
; break;
       bra       fsFindInDir_9
fsFindInDir_10:
; else if (vname[ix] == '.')
       move.l    8(A6),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       cmp.b     #46,D0
       bne.s     fsFindInDir_12
; iy = 8;
       move.w    #8,-50(A6)
       bra       fsFindInDir_13
fsFindInDir_12:
; else {
; for (iww = 0; iww <= 56; iww++) {
       clr.b     -23(A6)
fsFindInDir_14:
       move.b    -23(A6),D0
       cmp.b     #56,D0
       bhi.s     fsFindInDir_16
; if (strValidChars[iww] == vname[ix])
       move.b    -23(A6),D0
       and.l     #255,D0
       lea       _strValidChars.L,A0
       move.l    8(A6),A1
       and.l     #65535,D3
       move.b    0(A0,D0.L),D1
       cmp.b     0(A1,D3.L),D1
       bne.s     fsFindInDir_17
; break;
       bra.s     fsFindInDir_16
fsFindInDir_17:
       addq.b    #1,-23(A6)
       bra       fsFindInDir_14
fsFindInDir_16:
; }
; if (iww > 56)
       move.b    -23(A6),D0
       cmp.b     #56,D0
       bls.s     fsFindInDir_19
; return ERRO_D_INVALID_NAME;
       move.l    #65525,D0
       bra       fsFindInDir_21
fsFindInDir_19:
; if (iy <= 7)
       move.w    -50(A6),D0
       cmp.w     #7,D0
       bhi.s     fsFindInDir_22
; fnameName[iy] = vname[ix];
       move.l    8(A6),A0
       and.l     #65535,D3
       move.w    -50(A6),D0
       and.l     #65535,D0
       move.b    0(A0,D3.L),-66(A6,D0.L)
       bra.s     fsFindInDir_23
fsFindInDir_22:
; else {
; ikk = iy - 8;
       move.w    -50(A6),D0
       subq.w    #8,D0
       move.w    D0,D2
; fnameExt[ikk] = vname[ix];
       move.l    8(A6),A0
       and.l     #65535,D3
       and.l     #65535,D2
       move.b    0(A0,D3.L),-56(A6,D2.L)
fsFindInDir_23:
; }
; iy++;
       addq.w    #1,-50(A6)
fsFindInDir_13:
       addq.w    #1,D3
       bra       fsFindInDir_7
fsFindInDir_9:
; }
; }
; }
; }
; vfat = vdisk->fat;
       move.l    (A4),A0
       move.w    2(A0),D0
       and.l     #65535,D0
       move.l    D0,-82(A6)
; vtemp1 = ((*vclusterdir - 2) * vdisk->SecPerClus);
       move.l    _vclusterdir.L,A0
       move.w    (A0),D0
       subq.w    #2,D0
       move.l    (A4),A0
       move.b    28(A0),D1
       and.w     #255,D1
       mulu.w    D1,D0
       and.l     #65535,D0
       move.l    D0,-74(A6)
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A4),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    (A4),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-70(A6)
; vdata = vtemp1 + vtemp2;
       move.l    -74(A6),D0
       add.l     -70(A6),D0
       move.l    D0,D4
; vclusterfile = ERRO_D_NOT_FOUND;
       move.l    #65535,A5
; vclusterdirnew = *vclusterdir;
       move.l    _vclusterdir.L,A0
       move.w    (A0),D0
       and.l     #65535,D0
       move.l    D0,D6
; ventrydir = 0;
       clr.w     -44(A6)
; while (vdata != LAST_CLUSTER_FAT16) {
fsFindInDir_24:
       cmp.l     #65535,D4
       beq       fsFindInDir_26
; for (iw = 0; iw < vdisk->SecPerClus; iw++) {
       clr.b     -31(A6)
fsFindInDir_27:
       move.l    (A4),A0
       move.b    -31(A6),D0
       cmp.b     28(A0),D0
       bhs       fsFindInDir_29
; if (!fsSectorRead(vdata, gDataBuffer))
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsFindInDir_30
; return ERRO_D_READ_DISK;
       move.l    #65521,D0
       bra       fsFindInDir_21
fsFindInDir_30:
; for (ix = 0; ix < vdisk->sectorSize; ix += 32) {
       clr.w     D3
fsFindInDir_32:
       move.l    (A4),A0
       cmp.w     16(A0),D3
       bhs       fsFindInDir_34
; for (iy = 0; iy < 8; iy++) {
       clr.w     -50(A6)
fsFindInDir_35:
       move.w    -50(A6),D0
       cmp.w     #8,D0
       bhs.s     fsFindInDir_37
; ikk = ix + iy;
       move.w    D3,D0
       add.w     -50(A6),D0
       move.w    D0,D2
; vdir->Name[iy] = gDataBuffer[ikk];
       move.l    (A2),A0
       and.l     #65535,D2
       move.l    (A3),A1
       move.w    -50(A6),D0
       and.l     #65535,D0
       move.b    0(A0,D2.L),0(A1,D0.L)
       addq.w    #1,-50(A6)
       bra       fsFindInDir_35
fsFindInDir_37:
; }
; for (iy = 0; iy < 3; iy++) {
       clr.w     -50(A6)
fsFindInDir_38:
       move.w    -50(A6),D0
       cmp.w     #3,D0
       bhs.s     fsFindInDir_40
; ikk = ix + 8 + iy;
       move.w    D3,D0
       addq.w    #8,D0
       add.w     -50(A6),D0
       move.w    D0,D2
; vdir->Ext[iy] = gDataBuffer[ikk];
       move.l    (A2),A0
       and.l     #65535,D2
       move.l    (A3),A1
       move.w    -50(A6),D0
       and.l     #65535,D0
       add.l     D0,A1
       move.b    0(A0,D2.L),10(A1)
       addq.w    #1,-50(A6)
       bra       fsFindInDir_38
fsFindInDir_40:
; }
; ikk = ix + 11;
       move.w    D3,D0
       add.w     #11,D0
       move.w    D0,D2
; vdir->Attr = gDataBuffer[ikk];
       move.l    (A2),A0
       and.l     #65535,D2
       move.l    (A3),A1
       move.b    0(A0,D2.L),14(A1)
; ikk = ix + 15;
       move.w    D3,D0
       add.w     #15,D0
       move.w    D0,D2
; vdir->CreateTime  = (unsigned short)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A3),A0
       move.w    D0,18(A0)
; ikk = ix + 14;
       move.w    D3,D0
       add.w     #14,D0
       move.w    D0,D2
; vdir->CreateTime |= (unsigned short)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.w     #255,D0
       or.w      D0,18(A0)
; ikk = ix + 17;
       move.w    D3,D0
       add.w     #17,D0
       move.w    D0,D2
; vdir->CreateDate  = (unsigned short)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A3),A0
       move.w    D0,16(A0)
; ikk = ix + 16;
       move.w    D3,D0
       add.w     #16,D0
       move.w    D0,D2
; vdir->CreateDate |= (unsigned short)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.w     #255,D0
       or.w      D0,16(A0)
; ikk = ix + 19;
       move.w    D3,D0
       add.w     #19,D0
       move.w    D0,D2
; vdir->LastAccessDate  = (unsigned short)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A3),A0
       move.w    D0,20(A0)
; ikk = ix + 18;
       move.w    D3,D0
       add.w     #18,D0
       move.w    D0,D2
; vdir->LastAccessDate |= (unsigned short)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.w     #255,D0
       or.w      D0,20(A0)
; ikk = ix + 23;
       move.w    D3,D0
       add.w     #23,D0
       move.w    D0,D2
; vdir->UpdateTime  = (unsigned short)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A3),A0
       move.w    D0,24(A0)
; ikk = ix + 22;
       move.w    D3,D0
       add.w     #22,D0
       move.w    D0,D2
; vdir->UpdateTime |= (unsigned short)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.w     #255,D0
       or.w      D0,24(A0)
; ikk = ix + 25;
       move.w    D3,D0
       add.w     #25,D0
       move.w    D0,D2
; vdir->UpdateDate  = (unsigned short)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.l    (A3),A0
       move.w    D0,22(A0)
; ikk = ix + 24;
       move.w    D3,D0
       add.w     #24,D0
       move.w    D0,D2
; vdir->UpdateDate |= (unsigned short)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.w     #255,D0
       or.w      D0,22(A0)
; ikk = ix + 21;
       move.w    D3,D0
       add.w     #21,D0
       move.w    D0,D2
; vdir->FirstCluster  = (unsigned long)gDataBuffer[ikk] << 24;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    (A3),A0
       move.w    D0,26(A0)
; ikk = ix + 20;
       move.w    D3,D0
       add.w     #20,D0
       move.w    D0,D2
; vdir->FirstCluster |= (unsigned long)gDataBuffer[ikk] << 16;
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       or.w      D0,26(A0)
; ikk = ix + 27;
       move.w    D3,D0
       add.w     #27,D0
       move.w    D0,D2
; vdir->FirstCluster |= (unsigned long)gDataBuffer[ikk] << 8;
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       or.w      D0,26(A0)
; ikk = ix + 26;
       move.w    D3,D0
       add.w     #26,D0
       move.w    D0,D2
; vdir->FirstCluster |= (unsigned long)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.l     #255,D0
       or.w      D0,26(A0)
; ikk = ix + 31;
       move.w    D3,D0
       add.w     #31,D0
       move.w    D0,D2
; vdir->Size  = (unsigned long)gDataBuffer[ikk] << 24;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       move.l    (A3),A0
       move.l    D0,28(A0)
; ikk = ix + 30;
       move.w    D3,D0
       add.w     #30,D0
       move.w    D0,D2
; vdir->Size |= (unsigned long)gDataBuffer[ikk] << 16;
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       lsl.l     #8,D0
       or.l      D0,28(A0)
; ikk = ix + 29;
       move.w    D3,D0
       add.w     #29,D0
       move.w    D0,D2
; vdir->Size |= (unsigned long)gDataBuffer[ikk] << 8;
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       or.l      D0,28(A0)
; ikk = ix + 28;
       move.w    D3,D0
       add.w     #28,D0
       move.w    D0,D2
; vdir->Size |= (unsigned long)gDataBuffer[ikk];
       move.l    (A3),A0
       move.l    (A2),A1
       and.l     #65535,D2
       move.b    0(A1,D2.L),D0
       and.l     #255,D0
       or.l      D0,28(A0)
; vdir->DirClusSec = vdata;
       move.l    (A3),A0
       move.w    D4,32(A0)
; vdir->DirEntry = ix;
       move.l    (A3),A0
       move.w    D3,34(A0)
; if (vtype == TYPE_FIRST_ENTRY && vdir->Attr != 0x0F) {
       move.b    15(A6),D0
       cmp.b     #8,D0
       bne       fsFindInDir_45
       move.l    (A3),A0
       move.b    14(A0),D0
       cmp.b     #15,D0
       beq.s     fsFindInDir_45
; if (vdir->Name[0] != DIR_DEL) {
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #229,D0
       beq.s     fsFindInDir_45
; if (vdir->Name[0] != DIR_EMPTY) {
       move.l    (A3),A0
       move.b    (A0),D0
       beq.s     fsFindInDir_45
; vclusterfile = vdir->FirstCluster;
       move.l    (A3),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    D0,A5
; vdata = LAST_CLUSTER_FAT16;
       move.l    #65535,D4
; break;
       bra       fsFindInDir_34
fsFindInDir_45:
; }
; }
; }
; if (vtype == TYPE_EMPTY_ENTRY || vtype == TYPE_CREATE_FILE || vtype == TYPE_CREATE_DIR) {
       move.b    15(A6),D0
       cmp.b     #3,D0
       beq.s     fsFindInDir_49
       move.b    15(A6),D0
       cmp.b     #4,D0
       beq.s     fsFindInDir_49
       move.b    15(A6),D0
       cmp.b     #5,D0
       bne       fsFindInDir_47
fsFindInDir_49:
; if (vdir->Name[0] == DIR_EMPTY || vdir->Name[0] == DIR_DEL) {
       move.l    (A3),A0
       move.b    (A0),D0
       beq.s     fsFindInDir_52
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #229,D0
       bne       fsFindInDir_50
fsFindInDir_52:
; vclusterfile = ventrydir;
       move.w    -44(A6),D0
       and.l     #65535,D0
       move.l    D0,A5
; if (vtype != TYPE_EMPTY_ENTRY) {
       move.b    15(A6),D0
       cmp.b     #3,D0
       beq       fsFindInDir_53
; vclusterfile = fsFindClusterFree(FREE_USE);
       pea       2
       jsr       _fsFindClusterFree
       addq.w    #4,A7
       and.l     #65535,D0
       move.l    D0,A5
; if (vclusterfile >= ERRO_D_START)
       move.l    A5,D0
       cmp.l     #65520,D0
       blo.s     fsFindInDir_55
; return ERRO_D_NOT_FOUND;
       move.l    #65535,D0
       bra       fsFindInDir_21
fsFindInDir_55:
; if (!fsSectorRead(vdata, gDataBuffer))
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsFindInDir_57
; return ERRO_D_READ_DISK;
       move.l    #65521,D0
       bra       fsFindInDir_21
fsFindInDir_57:
; for (iz = 0; iz <= 10; iz++) {
       clr.w     D5
fsFindInDir_59:
       cmp.w     #10,D5
       bhi       fsFindInDir_61
; if (iz <= 7) {
       cmp.w     #7,D5
       bhi.s     fsFindInDir_62
; ikk = ix + iz;
       move.w    D3,D0
       add.w     D5,D0
       move.w    D0,D2
; gDataBuffer[ikk] = fnameName[iz];
       and.l     #65535,D5
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    -66(A6,D5.L),0(A0,D2.L)
       bra.s     fsFindInDir_63
fsFindInDir_62:
; }
; else {
; ikk = ix + iz;
       move.w    D3,D0
       add.w     D5,D0
       move.w    D0,D2
; ikj = iz - 8;
       move.w    D5,D0
       subq.w    #8,D0
       move.w    D0,-38(A6)
; gDataBuffer[ikk] = fnameExt[ikj];
       move.w    -38(A6),D0
       and.l     #65535,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    -56(A6,D0.L),0(A0,D2.L)
fsFindInDir_63:
       addq.w    #1,D5
       bra       fsFindInDir_59
fsFindInDir_61:
; }
; }
; if (vtype == TYPE_CREATE_FILE)
       move.b    15(A6),D0
       cmp.b     #4,D0
       bne.s     fsFindInDir_64
; gDataBuffer[ix + 11] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D3
       move.l    D3,A1
       clr.b     11(A1,A0.L)
       bra.s     fsFindInDir_65
fsFindInDir_64:
; else
; gDataBuffer[ix + 11] = ATTR_DIRECTORY;
       move.l    (A2),A0
       and.l     #65535,D3
       move.l    D3,A1
       move.b    #16,11(A1,A0.L)
fsFindInDir_65:
; // Ler Data/Hora
; getDateTimeAtu(ds1307);	// 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano
       pea       -30(A6)
       jsr       _getDateTimeAtu
       addq.w    #4,A7
; // Converte para a Data/Hora da FAT16
; vdirtime = datetimetodir(ds1307[0], ds1307[1], ds1307[2], CONV_HORA);
       pea       2
       move.b    -30+2(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -30+1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -30+0(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _datetimetodir
       add.w     #16,A7
       move.w    D0,-40(A6)
; vdirdate = datetimetodir(ds1307[3], ds1307[4], ds1307[5], CONV_DATA);
       pea       1
       move.b    -30+5(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -30+4(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -30+3(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _datetimetodir
       add.w     #16,A7
       move.w    D0,D7
; // Coloca dados no buffer para gravacao
; ikk = ix + 12;
       move.w    D3,D0
       add.w     #12,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;	// case
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = ix + 13;
       move.w    D3,D0
       add.w     #13,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;	// creation time in ms
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = ix + 14;
       move.w    D3,D0
       add.w     #14,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdirtime & 0xFF);	// creation time (ds1307)
       move.w    -40(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 15;
       move.w    D3,D0
       add.w     #15,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdirtime >> 8) & 0xFF);
       move.w    -40(A6),D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 16;
       move.w    D3,D0
       add.w     #16,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdirdate & 0xFF);	// creation date (ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 17;
       move.w    D3,D0
       add.w     #17,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 18;
       move.w    D3,D0
       add.w     #18,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdirdate & 0xFF);	// last access	(ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 19;
       move.w    D3,D0
       add.w     #19,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 22;
       move.w    D3,D0
       add.w     #22,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdirtime & 0xFF);	// time update (ds1307)
       move.w    -40(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 23;
       move.w    D3,D0
       add.w     #23,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdirtime >> 8) & 0xFF);
       move.w    -40(A6),D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 24;
       move.w    D3,D0
       add.w     #24,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdirdate & 0xFF);	// date update (ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 25;
       move.w    D3,D0
       add.w     #25,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 26;
       move.w    D3,D0
       add.w     #26,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vclusterfile & 0xFF);
       move.l    A5,D0
       and.l     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 27;
       move.w    D3,D0
       add.w     #27,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vclusterfile / 0x100) & 0xFF);
       move.l    A5,-(A7)
       pea       256
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 20;
       move.w    D3,D0
       add.w     #20,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vclusterfile / 0x10000) & 0xFF);
       move.l    A5,-(A7)
       pea       65536
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 21;
       move.w    D3,D0
       add.w     #21,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vclusterfile / 0x1000000) & 0xFF);
       move.l    A5,-(A7)
       pea       16777216
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ix + 28;
       move.w    D3,D0
       add.w     #28,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = ix + 29;
       move.w    D3,D0
       add.w     #29,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = ix + 30;
       move.w    D3,D0
       add.w     #30,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = ix + 31;
       move.w    D3,D0
       add.w     #31,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindInDir_66
; return ERRO_D_WRITE_DISK;
       move.l    #65522,D0
       bra       fsFindInDir_21
fsFindInDir_66:
; if (vtype == TYPE_CREATE_DIR) {
       move.b    15(A6),D0
       cmp.b     #5,D0
       bne       fsFindInDir_75
; // Posicionar na nova posicao do diretorio
; vtemp1 = ((vclusterfile - 2) * vdisk->SecPerClus);
       move.l    A5,D0
       subq.l    #2,D0
       move.l    (A4),A0
       move.b    28(A0),D1
       and.l     #255,D1
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-74(A6)
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A4),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    (A4),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-70(A6)
; vdata = vtemp1 + vtemp2;
       move.l    -74(A6),D0
       add.l     -70(A6),D0
       move.l    D0,D4
; // Limpar novo cluster do diretorio (Zerar)
; memset(gDataBuffer, 0x00, vdisk->sectorSize);
       move.l    (A4),A0
       move.w    16(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       move.l    (A2),-(A7)
       jsr       _memset
       add.w     #12,A7
; for (iz = 0; iz < vdisk->SecPerClus; iz++) {
       clr.w     D5
fsFindInDir_70:
       move.l    (A4),A0
       move.b    28(A0),D0
       and.w     #255,D0
       cmp.w     D0,D5
       bhs.s     fsFindInDir_72
; if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindInDir_73
; return ERRO_D_WRITE_DISK;
       move.l    #65522,D0
       bra       fsFindInDir_21
fsFindInDir_73:
; vdata++;
       addq.l    #1,D4
       addq.w    #1,D5
       bra       fsFindInDir_70
fsFindInDir_72:
; }
; vtemp1 = ((vclusterfile - 2) * vdisk->SecPerClus);
       move.l    A5,D0
       subq.l    #2,D0
       move.l    (A4),A0
       move.b    28(A0),D1
       and.l     #255,D1
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-74(A6)
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A4),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    (A4),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-70(A6)
; vdata = vtemp1 + vtemp2;
       move.l    -74(A6),D0
       add.l     -70(A6),D0
       move.l    D0,D4
; // Criar diretorio . (atual)
; memset(gDataBuffer, 0x00, vdisk->sectorSize);
       move.l    (A4),A0
       move.w    16(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       move.l    (A2),-(A7)
       jsr       _memset
       add.w     #12,A7
; ix = 0;
       clr.w     D3
; gDataBuffer[0] = '.';
       move.l    (A2),A0
       move.b    #46,(A0)
; gDataBuffer[1] = 0x20;
       move.l    (A2),A0
       move.b    #32,1(A0)
; gDataBuffer[2] = 0x20;
       move.l    (A2),A0
       move.b    #32,2(A0)
; gDataBuffer[3] = 0x20;
       move.l    (A2),A0
       move.b    #32,3(A0)
; gDataBuffer[4] = 0x20;
       move.l    (A2),A0
       move.b    #32,4(A0)
; gDataBuffer[5] = 0x20;
       move.l    (A2),A0
       move.b    #32,5(A0)
; gDataBuffer[6] = 0x20;
       move.l    (A2),A0
       move.b    #32,6(A0)
; gDataBuffer[7] = 0x20;
       move.l    (A2),A0
       move.b    #32,7(A0)
; gDataBuffer[8] = 0x20;
       move.l    (A2),A0
       move.b    #32,8(A0)
; gDataBuffer[9] = 0x20;
       move.l    (A2),A0
       move.b    #32,9(A0)
; gDataBuffer[10] = 0x20;
       move.l    (A2),A0
       move.b    #32,10(A0)
; gDataBuffer[11] = 0x10;
       move.l    (A2),A0
       move.b    #16,11(A0)
; gDataBuffer[12] = 0x00;	// case
       move.l    (A2),A0
       clr.b     12(A0)
; gDataBuffer[13] = 0x00;	// creation time in ms
       move.l    (A2),A0
       clr.b     13(A0)
; gDataBuffer[14] = (unsigned char)(vdirtime & 0xFF);	// creation time (ds1307)
       move.w    -40(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,14(A0)
; gDataBuffer[15] = (unsigned char)((vdirtime >> 8) & 0xFF);
       move.w    -40(A6),D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,15(A0)
; gDataBuffer[16] = (unsigned char)(vdirdate & 0xFF);	// creation date (ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,16(A0)
; gDataBuffer[17] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,17(A0)
; gDataBuffer[18] = (unsigned char)(vdirdate & 0xFF);	// last access	(ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,18(A0)
; gDataBuffer[19] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,19(A0)
; gDataBuffer[22] = (unsigned char)(vdirtime & 0xFF);	// time update (ds1307)
       move.w    -40(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,22(A0)
; gDataBuffer[23] = (unsigned char)((vdirtime >> 8) & 0xFF);
       move.w    -40(A6),D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,23(A0)
; gDataBuffer[24] = (unsigned char)(vdirdate & 0xFF);	// date update (ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,24(A0)
; gDataBuffer[25] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,25(A0)
; gDataBuffer[26] = (unsigned char)(vclusterfile & 0xFF);
       move.l    A5,D0
       and.l     #255,D0
       move.l    (A2),A0
       move.b    D0,26(A0)
; gDataBuffer[27] = (unsigned char)((vclusterfile / 0x100) & 0xFF);
       move.l    A5,-(A7)
       pea       256
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       move.b    D0,27(A0)
; gDataBuffer[28] = 0x00;
       move.l    (A2),A0
       clr.b     28(A0)
; gDataBuffer[29] = 0x00;
       move.l    (A2),A0
       clr.b     29(A0)
; gDataBuffer[30] = 0x00;
       move.l    (A2),A0
       clr.b     30(A0)
; gDataBuffer[31] = 0x00;
       move.l    (A2),A0
       clr.b     31(A0)
; // Criar diretorio .. (anterior)
; ix = 32;
       moveq     #32,D3
; gDataBuffer[32] = '.';
       move.l    (A2),A0
       move.b    #46,32(A0)
; gDataBuffer[33] = '.';
       move.l    (A2),A0
       move.b    #46,33(A0)
; gDataBuffer[34] = 0x20;
       move.l    (A2),A0
       move.b    #32,34(A0)
; gDataBuffer[35] = 0x20;
       move.l    (A2),A0
       move.b    #32,35(A0)
; gDataBuffer[36] = 0x20;
       move.l    (A2),A0
       move.b    #32,36(A0)
; gDataBuffer[37] = 0x20;
       move.l    (A2),A0
       move.b    #32,37(A0)
; gDataBuffer[38] = 0x20;
       move.l    (A2),A0
       move.b    #32,38(A0)
; gDataBuffer[39] = 0x20;
       move.l    (A2),A0
       move.b    #32,39(A0)
; gDataBuffer[40] = 0x20;
       move.l    (A2),A0
       move.b    #32,40(A0)
; gDataBuffer[41] = 0x20;
       move.l    (A2),A0
       move.b    #32,41(A0)
; gDataBuffer[42] = 0x20;
       move.l    (A2),A0
       move.b    #32,42(A0)
; gDataBuffer[43] = 0x10;
       move.l    (A2),A0
       move.b    #16,43(A0)
; gDataBuffer[44] = 0x00;	// case
       move.l    (A2),A0
       clr.b     44(A0)
; gDataBuffer[45] = 0x00;	// creation time in ms
       move.l    (A2),A0
       clr.b     45(A0)
; gDataBuffer[46] = (unsigned char)(vdirtime & 0xFF);	// creation time (ds1307)
       move.w    -40(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,46(A0)
; gDataBuffer[47] = (unsigned char)((vdirtime >> 8) & 0xFF);
       move.w    -40(A6),D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,47(A0)
; gDataBuffer[48] = (unsigned char)(vdirdate & 0xFF);	// creation date (ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,48(A0)
; gDataBuffer[49] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,49(A0)
; gDataBuffer[50] = (unsigned char)(vdirdate & 0xFF);	// last access	(ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,50(A0)
; gDataBuffer[51] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,51(A0)
; gDataBuffer[54] = (unsigned char)(vdirtime & 0xFF);	// time update (ds1307)
       move.w    -40(A6),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,54(A0)
; gDataBuffer[55] = (unsigned char)((vdirtime >> 8) & 0xFF);
       move.w    -40(A6),D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,55(A0)
; gDataBuffer[56] = (unsigned char)(vdirdate & 0xFF);	// date update (ds1307)
       move.w    D7,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,56(A0)
; gDataBuffer[57] = (unsigned char)((vdirdate >> 8) & 0xFF);
       move.w    D7,D0
       lsr.w     #8,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,57(A0)
; gDataBuffer[58] = (unsigned char)(*vclusterdir & 0xFF);
       move.l    _vclusterdir.L,A0
       move.w    (A0),D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,58(A0)
; gDataBuffer[59] = (unsigned char)((*vclusterdir / 0x100) & 0xFF);
       move.l    _vclusterdir.L,A0
       move.w    (A0),D0
       and.l     #65535,D0
       divu.w    #256,D0
       and.w     #255,D0
       move.l    (A2),A0
       move.b    D0,59(A0)
; gDataBuffer[60] = 0x00;
       move.l    (A2),A0
       clr.b     60(A0)
; gDataBuffer[61] = 0x00;
       move.l    (A2),A0
       clr.b     61(A0)
; gDataBuffer[62] = 0x00;
       move.l    (A2),A0
       clr.b     62(A0)
; gDataBuffer[63] = 0x00;
       move.l    (A2),A0
       clr.b     63(A0)
; if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindInDir_75
; return ERRO_D_WRITE_DISK;
       move.l    #65522,D0
       bra       fsFindInDir_21
fsFindInDir_75:
; }
; vdata = LAST_CLUSTER_FAT16;
       move.l    #65535,D4
; break;
       bra       fsFindInDir_34
fsFindInDir_53:
; }
; vdata = LAST_CLUSTER_FAT16;
       move.l    #65535,D4
; break;
       bra       fsFindInDir_34
fsFindInDir_50:
       bra       fsFindInDir_105
fsFindInDir_47:
; }
; }
; else if (vtype != TYPE_FIRST_ENTRY) {
       move.b    15(A6),D0
       cmp.b     #8,D0
       beq       fsFindInDir_105
; if (vdir->Name[0] != DIR_EMPTY && vdir->Name[0] != DIR_DEL) {
       move.l    (A3),A0
       move.b    (A0),D0
       beq       fsFindInDir_105
       move.l    (A3),A0
       move.b    (A0),D0
       and.w     #255,D0
       cmp.w     #229,D0
       beq       fsFindInDir_105
; vcomp = 1;
       move.b    #1,-32(A6)
; for (iz = 0; iz <= 10; iz++) {
       clr.w     D5
fsFindInDir_81:
       cmp.w     #10,D5
       bhi       fsFindInDir_83
; if (iz <= 7) {
       cmp.w     #7,D5
       bhi.s     fsFindInDir_84
; if (fnameName[iz] != vdir->Name[iz]) {
       and.l     #65535,D5
       move.l    (A3),A0
       and.l     #65535,D5
       move.b    -66(A6,D5.L),D0
       cmp.b     0(A0,D5.L),D0
       beq.s     fsFindInDir_86
; vcomp = 0;
       clr.b     -32(A6)
; break;
       bra.s     fsFindInDir_83
fsFindInDir_86:
       bra.s     fsFindInDir_88
fsFindInDir_84:
; }
; }
; else {
; ikk = iz - 8;
       move.w    D5,D0
       subq.w    #8,D0
       move.w    D0,D2
; if (fnameExt[ikk] != vdir->Ext[ikk]) {
       and.l     #65535,D2
       move.l    (A3),A0
       and.l     #65535,D2
       add.l     D2,A0
       move.b    -56(A6,D2.L),D0
       cmp.b     10(A0),D0
       beq.s     fsFindInDir_88
; vcomp = 0;
       clr.b     -32(A6)
; break;
       bra.s     fsFindInDir_83
fsFindInDir_88:
       addq.w    #1,D5
       bra       fsFindInDir_81
fsFindInDir_83:
; }
; }
; }
; if (vcomp) {
       tst.b     -32(A6)
       beq       fsFindInDir_105
; if (vtype == TYPE_ALL || (vtype == TYPE_FILE && vdir->Attr != ATTR_DIRECTORY) || (vtype == TYPE_DIRECTORY && vdir->Attr == ATTR_DIRECTORY)) {
       move.b    15(A6),D0
       and.w     #255,D0
       cmp.w     #255,D0
       beq.s     fsFindInDir_94
       move.b    15(A6),D0
       cmp.b     #2,D0
       bne.s     fsFindInDir_95
       move.l    (A3),A0
       move.b    14(A0),D0
       cmp.b     #16,D0
       bne.s     fsFindInDir_94
fsFindInDir_95:
       move.b    15(A6),D0
       cmp.b     #1,D0
       bne.s     fsFindInDir_92
       move.l    (A3),A0
       move.b    14(A0),D0
       cmp.b     #16,D0
       bne.s     fsFindInDir_92
fsFindInDir_94:
; vclusterfile = vdir->FirstCluster;
       move.l    (A3),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    D0,A5
; break;
       bra       fsFindInDir_34
fsFindInDir_92:
; }
; else if (vtype == TYPE_NEXT_ENTRY) {
       move.b    15(A6),D0
       cmp.b     #9,D0
       bne.s     fsFindInDir_96
; vtype = TYPE_FIRST_ENTRY;
       move.b    #8,15(A6)
       bra       fsFindInDir_105
fsFindInDir_96:
; }
; else if (vtype == TYPE_DEL_FILE || vtype == TYPE_DEL_DIR) {
       move.b    15(A6),D0
       cmp.b     #6,D0
       beq.s     fsFindInDir_100
       move.b    15(A6),D0
       cmp.b     #7,D0
       bne       fsFindInDir_105
fsFindInDir_100:
; // Guardando Cluster Atual
; vclusteratual = vdir->FirstCluster;
       move.l    (A3),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    D0,-78(A6)
; // Apagando no Diretorio
; gDataBuffer[ix] = DIR_DEL;
       move.l    (A2),A0
       and.l     #65535,D3
       move.b    #229,0(A0,D3.L)
; ikk = ix + 26;
       move.w    D3,D0
       add.w     #26,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = ix + 27;
       move.w    D3,D0
       add.w     #27,D0
       move.w    D0,D2
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindInDir_101
; return ERRO_D_WRITE_DISK;
       move.l    #65522,D0
       bra       fsFindInDir_21
fsFindInDir_101:
; // Apagando vestigios na FAT
; while (1) {
fsFindInDir_103:
; // Procura Proximo Cluster e ja zera
; vclusterdirnew = fsFindNextCluster(vclusteratual, NEXT_FREE);
       pea       3
       move.l    -78(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsFindNextCluster
       addq.w    #8,A7
       and.l     #65535,D0
       move.l    D0,D6
; if (vclusterdirnew >= ERRO_D_START)
       cmp.l     #65520,D6
       blo.s     fsFindInDir_106
; return ERRO_D_NOT_FOUND;
       move.l    #65535,D0
       bra       fsFindInDir_21
fsFindInDir_106:
; if (vclusterdirnew == LAST_CLUSTER_FAT16) {
       cmp.l     #65535,D6
       bne.s     fsFindInDir_108
; vclusterfile = LAST_CLUSTER_FAT16;
       move.l    #65535,A5
; vdata = LAST_CLUSTER_FAT16;
       move.l    #65535,D4
; break;
       bra.s     fsFindInDir_105
fsFindInDir_108:
; }
; // Tornar cluster atual o proximo
; vclusteratual = vclusterdirnew;
       move.l    D6,-78(A6)
       bra       fsFindInDir_103
fsFindInDir_105:
; }
; }
; }
; }
; }
; if (vdir->Name[0] == DIR_EMPTY) {
       move.l    (A3),A0
       move.b    (A0),D0
       bne.s     fsFindInDir_110
; vdata = LAST_CLUSTER_FAT16;
       move.l    #65535,D4
; break;
       bra.s     fsFindInDir_34
fsFindInDir_110:
       add.w     #32,D3
       bra       fsFindInDir_32
fsFindInDir_34:
; }
; }
; if (vclusterfile < ERRO_D_START || vdata == LAST_CLUSTER_FAT16)
       move.l    A5,D0
       cmp.l     #65520,D0
       blo.s     fsFindInDir_114
       cmp.l     #65535,D4
       bne.s     fsFindInDir_112
fsFindInDir_114:
; break;
       bra.s     fsFindInDir_29
fsFindInDir_112:
; ventrydir++;
       addq.w    #1,-44(A6)
; vdata++;
       addq.l    #1,D4
       addq.b    #1,-31(A6)
       bra       fsFindInDir_27
fsFindInDir_29:
; }
; // Se conseguiu concluir a operacao solicitada, sai do loop
; if (vclusterfile < ERRO_D_START || vdata == LAST_CLUSTER_FAT16)
       move.l    A5,D0
       cmp.l     #65520,D0
       blo.s     fsFindInDir_117
       cmp.l     #65535,D4
       bne.s     fsFindInDir_115
fsFindInDir_117:
; break;
       bra       fsFindInDir_26
fsFindInDir_115:
; else {
; // Posiciona na FAT, o endereco da pasta atual
; vsecfat = vclusterdirnew / 128;
       move.l    D6,-(A7)
       pea       128
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    D0,-46(A6)
; vfat = vdisk->fat + vsecfat;
       move.l    (A4),A0
       move.w    2(A0),D0
       and.l     #65535,D0
       move.w    -46(A6),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-82(A6)
; if (!fsSectorRead(vfat, gDataBuffer))
       move.l    (A2),-(A7)
       move.l    -82(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsFindInDir_118
; return ERRO_D_READ_DISK;
       move.l    #65521,D0
       bra       fsFindInDir_21
fsFindInDir_118:
; vtemp = vclusterdirnew - (128 * vsecfat);
       move.l    D6,D0
       move.w    -46(A6),D1
       mulu.w    #128,D1
       and.l     #65535,D1
       sub.l     D1,D0
       move.w    D0,-36(A6)
; vpos = vtemp * 4;
       move.w    -36(A6),D0
       mulu.w    #4,D0
       move.w    D0,-48(A6)
; ikk = vpos + 1;
       move.w    -48(A6),D0
       addq.w    #1,D0
       move.w    D0,D2
; vclusterdirnew  = (unsigned long)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.l    D0,D6
; ikk = vpos;
       move.w    -48(A6),D2
; vclusterdirnew |= (unsigned long)gDataBuffer[ikk];
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.l     #255,D0
       or.l      D0,D6
; if (vclusterdirnew != LAST_CLUSTER_FAT16) {
       cmp.l     #65535,D6
       beq       fsFindInDir_120
; // Devolve a proxima posicao para procura/uso
; vtemp1 = ((vclusterdirnew - 2) * vdisk->SecPerClus);
       move.l    D6,D0
       subq.l    #2,D0
       move.l    (A4),A0
       move.b    28(A0),D1
       and.l     #255,D1
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-74(A6)
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A4),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    (A4),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-70(A6)
; vdata = vtemp1 + vtemp2;
       move.l    -74(A6),D0
       add.l     -70(A6),D0
       move.l    D0,D4
       bra       fsFindInDir_123
fsFindInDir_120:
; }
; else {
; // Se for para criar uma nova entrada no diretorio e nao tem mais espaco
; // Cria uma nova entrada na Fat
; if (vtype == TYPE_EMPTY_ENTRY || vtype == TYPE_CREATE_FILE || vtype == TYPE_CREATE_DIR) {
       move.b    15(A6),D0
       cmp.b     #3,D0
       beq.s     fsFindInDir_124
       move.b    15(A6),D0
       cmp.b     #4,D0
       beq.s     fsFindInDir_124
       move.b    15(A6),D0
       cmp.b     #5,D0
       bne       fsFindInDir_122
fsFindInDir_124:
; vclusterdirnew = fsFindClusterFree(FREE_USE);
       pea       2
       jsr       _fsFindClusterFree
       addq.w    #4,A7
       and.l     #65535,D0
       move.l    D0,D6
; if (vclusterdirnew < ERRO_D_START) {
       cmp.l     #65520,D6
       bhs       fsFindInDir_125
; if (!fsSectorRead(vfat, gDataBuffer))
       move.l    (A2),-(A7)
       move.l    -82(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsFindInDir_127
; return ERRO_D_READ_DISK;
       move.l    #65521,D0
       bra       fsFindInDir_21
fsFindInDir_127:
; gDataBuffer[vpos] = (unsigned char)(vclusterdirnew & 0xFF);
       move.l    D6,D0
       and.l     #255,D0
       move.l    (A2),A0
       move.w    -48(A6),D1
       and.l     #65535,D1
       move.b    D0,0(A0,D1.L)
; ikk = vpos + 1;
       move.w    -48(A6),D0
       addq.w    #1,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vclusterdirnew / 0x100) & 0xFF);
       move.l    D6,-(A7)
       pea       256
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = vpos + 2;
       move.w    -48(A6),D0
       addq.w    #2,D0
       move.w    D0,D2
; if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       move.l    -82(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindInDir_129
; return ERRO_D_WRITE_DISK;
       move.l    #65522,D0
       bra       fsFindInDir_21
fsFindInDir_129:
; // Posicionar na nova posicao do diretorio
; vtemp1 = ((vclusterdirnew - 2) * vdisk->SecPerClus);
       move.l    D6,D0
       subq.l    #2,D0
       move.l    (A4),A0
       move.b    28(A0),D1
       and.l     #255,D1
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-74(A6)
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A4),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    (A4),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-70(A6)
; vdata = vtemp1 + vtemp2;
       move.l    -74(A6),D0
       add.l     -70(A6),D0
       move.l    D0,D4
; // Limpar novo cluster do diretorio (Zerar)
; memset(gDataBuffer, 0x00, vdisk->sectorSize);
       move.l    (A4),A0
       move.w    16(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       move.l    (A2),-(A7)
       jsr       _memset
       add.w     #12,A7
; for (iz = 0; iz < vdisk->SecPerClus; iz++) {
       clr.w     D5
fsFindInDir_131:
       move.l    (A4),A0
       move.b    28(A0),D0
       and.w     #255,D0
       cmp.w     D0,D5
       bhs.s     fsFindInDir_133
; if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindInDir_134
; return ERRO_D_WRITE_DISK;
       move.l    #65522,D0
       bra       fsFindInDir_21
fsFindInDir_134:
; vdata++;
       addq.l    #1,D4
       addq.w    #1,D5
       bra       fsFindInDir_131
fsFindInDir_133:
; }
; vtemp1 = ((vclusterdirnew - 2) * vdisk->SecPerClus);
       move.l    D6,D0
       subq.l    #2,D0
       move.l    (A4),A0
       move.b    28(A0),D1
       and.l     #255,D1
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-74(A6)
; vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
       move.l    (A4),A0
       move.w    26(A0),D0
       and.l     #65535,D0
       move.l    (A4),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    (A4),A0
       move.w    22(A0),D1
       mulu.w    #2,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-70(A6)
; vdata = vtemp1 + vtemp2;
       move.l    -74(A6),D0
       add.l     -70(A6),D0
       move.l    D0,D4
       bra.s     fsFindInDir_126
fsFindInDir_125:
; }
; else {
; vclusterdirnew = LAST_CLUSTER_FAT16;
       move.l    #65535,D6
; vclusterfile = ERRO_D_NOT_FOUND;
       move.l    #65535,A5
; vdata = vclusterdirnew;
       move.l    D6,D4
fsFindInDir_126:
       bra.s     fsFindInDir_123
fsFindInDir_122:
; }
; }
; else {
; vdata = vclusterdirnew;
       move.l    D6,D4
fsFindInDir_123:
       bra       fsFindInDir_24
fsFindInDir_26:
; }
; }
; }
; }
; return vclusterfile;
       move.l    A5,D0
fsFindInDir_21:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsUpdateDir()
; {
       xdef      _fsUpdateDir
_fsUpdateDir:
       movem.l   D2/D3/D4/A2/A3,-(A7)
       lea       _vdir.L,A2
       lea       _gDataBuffer.L,A3
; unsigned char iy;
; unsigned short ventry, ikk;
; if (!fsSectorRead(vdir->DirClusSec, gDataBuffer))
       move.l    (A3),-(A7)
       move.l    (A2),A0
       move.w    32(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsUpdateDir_1
; return ERRO_B_READ_DISK;
       move.b    #225,D0
       bra       fsUpdateDir_3
fsUpdateDir_1:
; ventry = vdir->DirEntry;
       move.l    (A2),A0
       move.w    34(A0),D3
; for (iy = 0; iy < 8; iy++) {
       clr.b     D4
fsUpdateDir_4:
       cmp.b     #8,D4
       bhs.s     fsUpdateDir_6
; ikk = ventry + iy;
       move.w    D3,D0
       and.w     #255,D4
       add.w     D4,D0
       move.w    D0,D2
; gDataBuffer[ikk] = vdir->Name[iy];
       move.l    (A2),A0
       and.l     #255,D4
       move.l    (A3),A1
       and.l     #65535,D2
       move.b    0(A0,D4.L),0(A1,D2.L)
       addq.b    #1,D4
       bra       fsUpdateDir_4
fsUpdateDir_6:
; }
; for (iy = 0; iy < 3; iy++) {
       clr.b     D4
fsUpdateDir_7:
       cmp.b     #3,D4
       bhs.s     fsUpdateDir_9
; ikk = ventry + 8 + iy;
       move.w    D3,D0
       addq.w    #8,D0
       and.w     #255,D4
       add.w     D4,D0
       move.w    D0,D2
; gDataBuffer[ikk] = vdir->Ext[iy];
       move.l    (A2),A0
       and.l     #255,D4
       add.l     D4,A0
       move.l    (A3),A1
       and.l     #65535,D2
       move.b    10(A0),0(A1,D2.L)
       addq.b    #1,D4
       bra       fsUpdateDir_7
fsUpdateDir_9:
; }
; ikk = ventry + 18;
       move.w    D3,D0
       add.w     #18,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdir->LastAccessDate & 0xFF);	// last access	(ds1307)
       move.l    (A2),A0
       move.w    20(A0),D0
       and.w     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 19;
       move.w    D3,D0
       add.w     #19,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdir->LastAccessDate / 0x100) & 0xFF);
       move.l    (A2),A0
       move.w    20(A0),D0
       and.l     #65535,D0
       divu.w    #256,D0
       and.w     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 22;
       move.w    D3,D0
       add.w     #22,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdir->UpdateTime & 0xFF);	// time update (ds1307)
       move.l    (A2),A0
       move.w    24(A0),D0
       and.w     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 23;
       move.w    D3,D0
       add.w     #23,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdir->UpdateTime / 0x100) & 0xFF);
       move.l    (A2),A0
       move.w    24(A0),D0
       and.l     #65535,D0
       divu.w    #256,D0
       and.w     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 24;
       move.w    D3,D0
       add.w     #24,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdir->UpdateDate & 0xFF);	// date update (ds1307)
       move.l    (A2),A0
       move.w    22(A0),D0
       and.w     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 25;
       move.w    D3,D0
       add.w     #25,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdir->UpdateDate / 0x100) & 0xFF);
       move.l    (A2),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       divu.w    #256,D0
       and.w     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 28;
       move.w    D3,D0
       add.w     #28,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)(vdir->Size & 0xFF);
       move.l    (A2),A0
       move.l    28(A0),D0
       and.l     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 29;
       move.w    D3,D0
       add.w     #29,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdir->Size / 0x100) & 0xFF);
       move.l    (A2),A0
       move.l    28(A0),-(A7)
       pea       256
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 30;
       move.w    D3,D0
       add.w     #30,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdir->Size / 0x10000) & 0xFF);
       move.l    (A2),A0
       move.l    28(A0),-(A7)
       pea       65536
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; ikk = ventry + 31;
       move.w    D3,D0
       add.w     #31,D0
       move.w    D0,D2
; gDataBuffer[ikk] = (unsigned char)((vdir->Size / 0x1000000) & 0xFF);
       move.l    (A2),A0
       move.l    28(A0),-(A7)
       pea       16777216
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A3),A0
       and.l     #65535,D2
       move.b    D0,0(A0,D2.L)
; if (!fsSectorWrite(vdir->DirClusSec, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A3),-(A7)
       move.l    (A2),A0
       move.w    32(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsUpdateDir_10
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra.s     fsUpdateDir_3
fsUpdateDir_10:
; return RETURN_OK;
       clr.b     D0
fsUpdateDir_3:
       movem.l   (A7)+,D2/D3/D4/A2/A3
       rts
; }
; //-------------------------------------------------------------------------
; unsigned short fsFindNextCluster(unsigned short vclusteratual, unsigned char vtype)
; {
       xdef      _fsFindNextCluster
_fsFindNextCluster:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/D7/A2,-(A7)
       lea       _gDataBuffer.L,A2
       move.b    15(A6),D4
       and.l     #255,D4
; unsigned short vfat, vclusternew;
; unsigned short vpos, vsecfat, ikk;
; vsecfat = vclusteratual / 128;
       move.w    10(A6),D0
       and.l     #65535,D0
       divu.w    #128,D0
       move.w    D0,D7
; vfat = vdisk->fat + vsecfat;
       move.l    _vdisk.L,A0
       move.w    2(A0),D0
       add.w     D7,D0
       move.w    D0,D6
; if (!fsSectorRead(vfat, gDataBuffer))
       move.l    (A2),-(A7)
       and.l     #65535,D6
       move.l    D6,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsFindNextCluster_1
; return ERRO_D_READ_DISK;
       move.w    #65521,D0
       bra       fsFindNextCluster_3
fsFindNextCluster_1:
; vpos = (vclusteratual - (128 * vsecfat)) * 4;
       move.w    10(A6),D0
       move.w    D7,D1
       mulu.w    #128,D1
       sub.w     D1,D0
       mulu.w    #4,D0
       move.w    D0,D2
; ikk = vpos + 1;
       move.w    D2,D0
       addq.w    #1,D0
       move.w    D0,D3
; vclusternew  = (unsigned short)gDataBuffer[ikk] << 8;
       move.l    (A2),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       and.w     #255,D0
       lsl.w     #8,D0
       move.w    D0,D5
; vclusternew |= (unsigned short)gDataBuffer[vpos];
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       and.w     #255,D0
       or.w      D0,D5
; if (vtype != NEXT_FIND) {
       cmp.b     #5,D4
       beq       fsFindNextCluster_10
; if (vtype == NEXT_FREE) {
       cmp.b     #3,D4
       bne.s     fsFindNextCluster_6
; gDataBuffer[vpos] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
; ikk = vpos + 1;
       move.w    D2,D0
       addq.w    #1,D0
       move.w    D0,D3
; gDataBuffer[ikk] = 0x00;
       move.l    (A2),A0
       and.l     #65535,D3
       clr.b     0(A0,D3.L)
       bra.s     fsFindNextCluster_8
fsFindNextCluster_6:
; }
; else if (vtype == NEXT_FULL) {
       cmp.b     #4,D4
       bne.s     fsFindNextCluster_8
; gDataBuffer[vpos] = 0xFF;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    #255,0(A0,D2.L)
; ikk = vpos + 1;
       move.w    D2,D0
       addq.w    #1,D0
       move.w    D0,D3
; gDataBuffer[ikk] = 0x0FF;
       move.l    (A2),A0
       and.l     #65535,D3
       move.b    #255,0(A0,D3.L)
fsFindNextCluster_8:
; }
; if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D6
       move.l    D6,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindNextCluster_10
; return ERRO_D_WRITE_DISK;
       move.w    #65522,D0
       bra.s     fsFindNextCluster_3
fsFindNextCluster_10:
; }
; return vclusternew;
       move.w    D5,D0
fsFindNextCluster_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned short fsFindClusterFree(unsigned char vtype)
; {
       xdef      _fsFindClusterFree
_fsFindClusterFree:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/A2/A3,-(A7)
       lea       _gDataBuffer.L,A2
       lea       _vdisk.L,A3
; unsigned long vclusterfree = 0x00, cc, vfat;
       clr.l     D6
; unsigned short jj, ikk, ikk2, ikk3;
; vfat = vdisk->fat;
       move.l    (A3),A0
       move.w    2(A0),D0
       and.l     #65535,D0
       move.l    D0,D5
; for (cc = 0; cc <= vdisk->fatsize; cc++) {
       clr.l     D4
fsFindClusterFree_1:
       move.l    (A3),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       cmp.l     D0,D4
       bhi       fsFindClusterFree_3
; // LER FAT SECTOR
; if (!fsSectorRead(vfat, gDataBuffer))
       move.l    (A2),-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       jsr       _fsSectorRead
       addq.w    #8,A7
       tst.b     D0
       bne.s     fsFindClusterFree_4
; return ERRO_D_READ_DISK;
       move.w    #65521,D0
       bra       fsFindClusterFree_6
fsFindClusterFree_4:
; // Procura Cluster Livre dentro desse setor
; for (jj = 0; jj < vdisk->sectorSize; jj += 4) {
       clr.w     D2
fsFindClusterFree_7:
       move.l    (A3),A0
       cmp.w     16(A0),D2
       bhs       fsFindClusterFree_9
; ikk = jj + 1;
       move.w    D2,D0
       addq.w    #1,D0
       move.w    D0,D3
; ikk2 = jj + 2;
       move.w    D2,D0
       addq.w    #2,D0
       move.w    D0,-4(A6)
; ikk3 = jj + 3;
       move.w    D2,D0
       addq.w    #3,D0
       move.w    D0,-2(A6)
; if (gDataBuffer[jj] == 0x00 && gDataBuffer[ikk] == 0x00 && gDataBuffer[ikk2] == 0x00 && gDataBuffer[ikk3] == 0x00)
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D0
       bne.s     fsFindClusterFree_10
       move.l    (A2),A0
       and.l     #65535,D3
       move.b    0(A0,D3.L),D0
       bne.s     fsFindClusterFree_10
       move.l    (A2),A0
       move.w    -4(A6),D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       bne.s     fsFindClusterFree_10
       move.l    (A2),A0
       move.w    -2(A6),D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       bne.s     fsFindClusterFree_10
; break;
       bra.s     fsFindClusterFree_9
fsFindClusterFree_10:
; vclusterfree++;
       addq.l    #1,D6
       addq.w    #4,D2
       bra       fsFindClusterFree_7
fsFindClusterFree_9:
; }
; // Se achou algum setor livre, sai do loop
; if (jj < vdisk->sectorSize)
       move.l    (A3),A0
       cmp.w     16(A0),D2
       bhs.s     fsFindClusterFree_12
; break;
       bra.s     fsFindClusterFree_3
fsFindClusterFree_12:
; // Soma mais 1 para procurar proximo cluster
; vfat++;
       addq.l    #1,D5
       addq.l    #1,D4
       bra       fsFindClusterFree_1
fsFindClusterFree_3:
; }
; if (cc > vdisk->fatsize)
       move.l    (A3),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       cmp.l     D0,D4
       bls.s     fsFindClusterFree_14
; vclusterfree = ERRO_D_DISK_FULL;
       move.l    #65524,D6
       bra       fsFindClusterFree_18
fsFindClusterFree_14:
; else {
; if (vtype == FREE_USE) {
       move.b    11(A6),D0
       cmp.b     #2,D0
       bne       fsFindClusterFree_18
; gDataBuffer[jj] = 0xFF;
       move.l    (A2),A0
       and.l     #65535,D2
       move.b    #255,0(A0,D2.L)
; ikk = jj + 1;
       move.w    D2,D0
       addq.w    #1,D0
       move.w    D0,D3
; gDataBuffer[ikk] = 0x0F;
       move.l    (A2),A0
       and.l     #65535,D3
       move.b    #15,0(A0,D3.L)
; if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       jsr       _fsSectorWrite
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFindClusterFree_18
; return ERRO_D_WRITE_DISK;
       move.w    #65522,D0
       bra.s     fsFindClusterFree_6
fsFindClusterFree_18:
; }
; }
; return (vclusterfree);
       move.w    D6,D0
fsFindClusterFree_6:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsFormat (long int serialNumber, char * volumeID)
; {
       xdef      _fsFormat
_fsFormat:
       link      A6,#-20
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _gDataBuffer.L,A2
       lea       _fsSectorWrite.L,A3
       move.l    12(A6),D7
       lea       _memset.L,A4
; unsigned short    j;
; unsigned long   secCount, RootDirSectors;
; unsigned long   root, fat, firsts = 0, fatsize, test;
       clr.l     D4
; unsigned long   Index;
; unsigned char    SecPerClus;
; unsigned char *  dataBufferPointer = gDataBuffer;
       move.l    (A2),-4(A6)
; //-------------------
; SecPerClus = 1;
       move.b    #1,-5(A6)
; secCount = 0;
       clr.l     -18(A6)
; //-------------------
; //-------------------
; fatsize = (secCount - 0x26);
       move.l    -18(A6),D0
       sub.l     #38,D0
       move.l    D0,D6
; fatsize = (fatsize / ((256 * SecPerClus + 2) / 2));
       move.b    -5(A6),D0
       and.w     #255,D0
       lsl.w     #8,D0
       addq.w    #2,D0
       and.l     #65535,D0
       divu.w    #2,D0
       ext.l     D0
       move.l    D6,-(A7)
       move.l    D0,-(A7)
       jsr       ULDIV
       move.l    (A7),D6
       addq.w    #8,A7
; fat = 0x26 + firsts;
       moveq     #38,D0
       ext.w     D0
       ext.l     D0
       add.l     D4,D0
       move.l    D0,D5
; root = fat + (2 * fatsize);
       move.l    D5,D0
       move.l    D6,-(A7)
       pea       2
       jsr       ULMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.l    D0,A5
; //-------------------
; // Formata MicroSD
; memset (gDataBuffer, 0x00, MEDIA_SECTOR_SIZE);
       pea       512
       clr.l     -(A7)
       move.l    (A2),-(A7)
       jsr       (A4)
       add.w     #12,A7
; // Non-file system specific values
; gDataBuffer[0] = 0xEB;         //Jump instruction
       move.l    (A2),A0
       move.b    #235,(A0)
; gDataBuffer[1] = 0xFE;
       move.l    (A2),A0
       move.b    #254,1(A0)
; gDataBuffer[2] = 0x90;
       move.l    (A2),A0
       move.b    #144,2(A0)
; gDataBuffer[3] =  'M';         //OEM Name
       move.l    (A2),A0
       move.b    #77,3(A0)
; gDataBuffer[4] =  'M';
       move.l    (A2),A0
       move.b    #77,4(A0)
; gDataBuffer[5] =  'S';
       move.l    (A2),A0
       move.b    #83,5(A0)
; gDataBuffer[6] =  'J';
       move.l    (A2),A0
       move.b    #74,6(A0)
; gDataBuffer[7] =  ' ';
       move.l    (A2),A0
       move.b    #32,7(A0)
; gDataBuffer[8] =  'F';
       move.l    (A2),A0
       move.b    #70,8(A0)
; gDataBuffer[9] =  'A';
       move.l    (A2),A0
       move.b    #65,9(A0)
; gDataBuffer[10] = 'T';
       move.l    (A2),A0
       move.b    #84,10(A0)
; gDataBuffer[11] = 0x00;             //Sector size
       move.l    (A2),A0
       clr.b     11(A0)
; gDataBuffer[12] = 0x02;
       move.l    (A2),A0
       move.b    #2,12(A0)
; gDataBuffer[13] = SecPerClus;   //Sectors per cluster
       move.l    (A2),A0
       move.b    -5(A6),13(A0)
; gDataBuffer[14] = 0x01;         //Reserved sector count
       move.l    (A2),A0
       move.b    #1,14(A0)
; gDataBuffer[15] = 0x00;
       move.l    (A2),A0
       clr.b     15(A0)
; fat = 0x01 + firsts;
       moveq     #1,D0
       ext.w     D0
       ext.l     D0
       add.l     D4,D0
       move.l    D0,D5
; gDataBuffer[16] = 0x02;         //number of FATs
       move.l    (A2),A0
       move.b    #2,16(A0)
; gDataBuffer[17] = 0x00;          //Max number of root directory entries - 512 files allowed
       move.l    (A2),A0
       clr.b     17(A0)
; gDataBuffer[18] = 0x00;
       move.l    (A2),A0
       clr.b     18(A0)
; gDataBuffer[19] = 0x40;         //total sectors
       move.l    (A2),A0
       move.b    #64,19(A0)
; gDataBuffer[20] = 0x0B;
       move.l    (A2),A0
       move.b    #11,20(A0)
; gDataBuffer[21] = 0xF0;         //Media Descriptor
       move.l    (A2),A0
       move.b    #240,21(A0)
; gDataBuffer[22] = 0x09;         //Sectors per FAT
       move.l    (A2),A0
       move.b    #9,22(A0)
; gDataBuffer[23] = 0x00;
       move.l    (A2),A0
       clr.b     23(A0)
; gDataBuffer[24] = 0x12;         //Sectors per track
       move.l    (A2),A0
       move.b    #18,24(A0)
; gDataBuffer[25] = 0x00;
       move.l    (A2),A0
       clr.b     25(A0)
; gDataBuffer[26] = 0x02;         //Number of heads
       move.l    (A2),A0
       move.b    #2,26(A0)
; gDataBuffer[27] = 0x00;
       move.l    (A2),A0
       clr.b     27(A0)
; // Hidden sectors = sectors between the MBR and the boot sector
; gDataBuffer[28] = (unsigned char)(firsts & 0xFF);
       move.l    D4,D0
       and.l     #255,D0
       move.l    (A2),A0
       move.b    D0,28(A0)
; gDataBuffer[29] = (unsigned char)((firsts / 0x100) & 0xFF);
       move.l    D4,-(A7)
       pea       256
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       move.b    D0,29(A0)
; gDataBuffer[30] = (unsigned char)((firsts / 0x10000) & 0xFF);
       move.l    D4,-(A7)
       pea       65536
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       move.b    D0,30(A0)
; gDataBuffer[31] = (unsigned char)((firsts / 0x1000000) & 0xFF);
       move.l    D4,-(A7)
       pea       16777216
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       and.l     #255,D0
       move.l    (A2),A0
       move.b    D0,31(A0)
; // Total Sectors = same as sectors in the partition from MBR
; gDataBuffer[32] = 0;
       move.l    (A2),A0
       clr.b     32(A0)
; gDataBuffer[33] = 0;
       move.l    (A2),A0
       clr.b     33(A0)
; gDataBuffer[34] = 0;
       move.l    (A2),A0
       clr.b     34(A0)
; gDataBuffer[35] = 0;
       move.l    (A2),A0
       clr.b     35(A0)
; // Sectors per FAT
; gDataBuffer[36] = 0x80;			// Drive Number
       move.l    (A2),A0
       move.b    #128,36(A0)
; gDataBuffer[37] = 0x00;			// Reserved
       move.l    (A2),A0
       clr.b     37(A0)
; gDataBuffer[38] = 0x29;			// Extended Boot Signature
       move.l    (A2),A0
       move.b    #41,38(A0)
; gDataBuffer[39] = 0x40;			// Serial Number
       move.l    (A2),A0
       move.b    #64,39(A0)
; gDataBuffer[40] = 0x0B;
       move.l    (A2),A0
       move.b    #11,40(A0)
; gDataBuffer[41] = 0x21;
       move.l    (A2),A0
       move.b    #33,41(A0)
; gDataBuffer[42] = 0x50;
       move.l    (A2),A0
       move.b    #80,42(A0)
; // Volume ID
; if (volumeID != NULL)
       clr.b     D0
       and.l     #255,D0
       cmp.l     D0,D7
       beq       fsFormat_1
; {
; for (Index = 0; (*(volumeID + Index) != 0) && (Index < 11); Index++)
       clr.l     D2
fsFormat_3:
       move.l    D7,A0
       move.b    0(A0,D2.L),D0
       beq.s     fsFormat_5
       cmp.l     #11,D2
       bhs.s     fsFormat_5
; {
; gDataBuffer[Index + 43] = *(volumeID + Index);
       move.l    D7,A0
       move.l    (A2),A1
       move.l    A0,-(A7)
       move.l    D2,A0
       move.b    0(A0,D2.L),43(A0,A1.L)
       move.l    (A7)+,A0
       addq.l    #1,D2
       bra       fsFormat_3
fsFormat_5:
; }
; while (Index < 11)
fsFormat_6:
       cmp.l     #11,D2
       bhs.s     fsFormat_8
; {
; gDataBuffer[43 + Index++] = 0x20;
       move.l    (A2),A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    #32,43(A1,A0.L)
       bra       fsFormat_6
fsFormat_8:
       bra.s     fsFormat_11
fsFormat_1:
; }
; }
; else
; {
; for (Index = 0; Index < 11; Index++)
       clr.l     D2
fsFormat_9:
       cmp.l     #11,D2
       bhs.s     fsFormat_11
; {
; gDataBuffer[Index + 43] = 0;
       move.l    (A2),A0
       move.l    D2,A1
       clr.b     43(A1,A0.L)
       addq.l    #1,D2
       bra       fsFormat_9
fsFormat_11:
; }
; }
; gDataBuffer[54] = 'F';
       move.l    (A2),A0
       move.b    #70,54(A0)
; gDataBuffer[55] = 'A';
       move.l    (A2),A0
       move.b    #65,55(A0)
; gDataBuffer[56] = 'T';
       move.l    (A2),A0
       move.b    #84,56(A0)
; gDataBuffer[57] = '1';
       move.l    (A2),A0
       move.b    #49,57(A0)
; gDataBuffer[58] = '6';
       move.l    (A2),A0
       move.b    #54,58(A0)
; gDataBuffer[59] = ' ';
       move.l    (A2),A0
       move.b    #32,59(A0)
; gDataBuffer[60] = ' ';
       move.l    (A2),A0
       move.b    #32,60(A0)
; gDataBuffer[61] = ' ';
       move.l    (A2),A0
       move.b    #32,61(A0)
; gDataBuffer[510] = 0x55;
       move.l    (A2),A0
       move.b    #85,510(A0)
; gDataBuffer[511] = 0xAA;
       move.l    (A2),A0
       move.b    #170,511(A0)
; if (!fsSectorWrite(0, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       clr.l     -(A7)
       jsr       (A3)
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFormat_12
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra       fsFormat_14
fsFormat_12:
; // Erase the FAT
; memset (gDataBuffer, 0x00, MEDIA_SECTOR_SIZE);
       pea       512
       clr.l     -(A7)
       move.l    (A2),-(A7)
       jsr       (A4)
       add.w     #12,A7
; gDataBuffer[0] = 0xF8;          //BPB_Media byte value in its low 8 bits, and all other bits are set to 1
       move.l    (A2),A0
       move.b    #248,(A0)
; gDataBuffer[1] = 0xFF;
       move.l    (A2),A0
       move.b    #255,1(A0)
; gDataBuffer[2] = 0xFF;          //Disk is clean and no read/write errors were encountered
       move.l    (A2),A0
       move.b    #255,2(A0)
; gDataBuffer[3] = 0xFF;
       move.l    (A2),A0
       move.b    #255,3(A0)
; gDataBuffer[4]  = 0xFF;         //Root Directory EOF
       move.l    (A2),A0
       move.b    #255,4(A0)
; gDataBuffer[5]  = 0xFF;
       move.l    (A2),A0
       move.b    #255,5(A0)
; for (j = 1; j != 0xFFFF; j--)
       moveq     #1,D3
fsFormat_15:
       cmp.w     #65535,D3
       beq       fsFormat_17
; {
; if (!fsSectorWrite (fat + (j * fatsize), gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       move.l    D5,D1
       and.l     #65535,D3
       move.l    D3,-(A7)
       move.l    D6,-(A7)
       move.l    D0,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    (A7)+,D0
       add.l     D0,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       (A3)
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFormat_18
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra       fsFormat_14
fsFormat_18:
       subq.w    #1,D3
       bra       fsFormat_15
fsFormat_17:
; }
; memset (gDataBuffer, 0x00, 12);
       pea       12
       clr.l     -(A7)
       move.l    (A2),-(A7)
       jsr       (A4)
       add.w     #12,A7
; for (Index = fat + 1; Index < (fat + fatsize); Index++)
       move.l    D5,D0
       addq.l    #1,D0
       move.l    D0,D2
fsFormat_20:
       move.l    D5,D0
       add.l     D6,D0
       cmp.l     D0,D2
       bhs       fsFormat_22
; {
; for (j = 1; j != 0xFFFF; j--)
       moveq     #1,D3
fsFormat_23:
       cmp.w     #65535,D3
       beq       fsFormat_25
; {
; if (!fsSectorWrite (Index + (j * fatsize), gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       move.l    D2,D1
       and.l     #65535,D3
       move.l    D3,-(A7)
       move.l    D6,-(A7)
       move.l    D0,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    (A7)+,D0
       add.l     D0,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       (A3)
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFormat_26
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra       fsFormat_14
fsFormat_26:
       subq.w    #1,D3
       bra       fsFormat_23
fsFormat_25:
       addq.l    #1,D2
       bra       fsFormat_20
fsFormat_22:
; }
; }
; // Erase the root directory
; for (Index = 1; Index < SecPerClus; Index++)
       moveq     #1,D2
fsFormat_28:
       move.b    -5(A6),D0
       and.l     #255,D0
       cmp.l     D0,D2
       bhs.s     fsFormat_30
; {
; if (!fsSectorWrite (root + Index, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       move.l    A5,D1
       add.l     D2,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       (A3)
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFormat_31
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra       fsFormat_14
fsFormat_31:
       addq.l    #1,D2
       bra       fsFormat_28
fsFormat_30:
; }
; // Create a drive name entry in the root dir
; Index = 0;
       clr.l     D2
; while ((*(volumeID + Index) != 0) && (Index < 11))
fsFormat_33:
       move.l    D7,A0
       move.b    0(A0,D2.L),D0
       beq.s     fsFormat_35
       cmp.l     #11,D2
       bhs.s     fsFormat_35
; {
; gDataBuffer[Index] = *(volumeID + Index);
       move.l    D7,A0
       move.l    (A2),A1
       move.b    0(A0,D2.L),0(A1,D2.L)
; Index++;
       addq.l    #1,D2
       bra       fsFormat_33
fsFormat_35:
; }
; while (Index < 11)
fsFormat_36:
       cmp.l     #11,D2
       bhs.s     fsFormat_38
; {
; gDataBuffer[Index++] = ' ';
       move.l    (A2),A0
       move.l    D2,D0
       addq.l    #1,D2
       move.b    #32,0(A0,D0.L)
       bra       fsFormat_36
fsFormat_38:
; }
; gDataBuffer[11] = 0x08;
       move.l    (A2),A0
       move.b    #8,11(A0)
; gDataBuffer[17] = 0x11;
       move.l    (A2),A0
       move.b    #17,17(A0)
; gDataBuffer[19] = 0x11;
       move.l    (A2),A0
       move.b    #17,19(A0)
; gDataBuffer[23] = 0x11;
       move.l    (A2),A0
       move.b    #17,23(A0)
; if (!fsSectorWrite (root, gDataBuffer, FALSE))
       clr.l     -(A7)
       move.l    (A2),-(A7)
       move.l    A5,-(A7)
       jsr       (A3)
       add.w     #12,A7
       tst.b     D0
       bne.s     fsFormat_39
; return ERRO_B_WRITE_DISK;
       move.b    #226,D0
       bra.s     fsFormat_14
fsFormat_39:
; return RETURN_OK;
       clr.b     D0
fsFormat_14:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsSectorRead(unsigned short vcluster, unsigned char* vbuffer)
; {
       xdef      _fsSectorRead
_fsSectorRead:
       link      A6,#-548
       movem.l   D2/D3/D4/D5/A2/A3/A4/A5,-(A7)
       lea       -12(A6),A2
       lea       _fsSendSerial.L,A3
       lea       _fsSendLongSerial.L,A4
       lea       _itoa.L,A5
; unsigned short vrecfim, vbytepic;
; unsigned char vbyteprog[512], vbytes[4],cc, dd;
; unsigned short xdado = 0, xcounter = 0;
       clr.w     -26(A6)
       clr.w     -24(A6)
; unsigned short vcrc, vcrcpic, vloop;
; unsigned int ix;
; unsigned long vsectorok;
; unsigned char sqtdtam[11], vtrack = 0, vhead = 0, vsector = 0;
       clr.b     D5
       clr.b     D4
       clr.b     D3
; fsConvClusterToTHS(vcluster, vtrack, vhead, vsector);
       and.l     #255,D3
       move.l    D3,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       move.w    10(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsConvClusterToTHS
       add.w     #16,A7
; // Clear Buffer de Recebimento
; while (fsRecSerial(vbuffer) >=0);
fsSectorRead_1:
       move.l    12(A6),-(A7)
       jsr       _fsRecSerial
       addq.w    #4,A7
       cmp.l     #0,D0
       blt.s     fsSectorRead_3
       bra       fsSectorRead_1
fsSectorRead_3:
; // r<track>,<sector><head>   Ex.: r0,1,0
; if (fsSendSerial('r') < 0) return 0;
       pea       114
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_4
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_4:
; itoa(vtrack,sqtdtam,10);
       pea       10
       move.l    A2,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (fsSendLongSerial(sqtdtam) < 0) return 0;
       move.l    A2,-(A7)
       jsr       (A4)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_7
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_7:
; if (fsSendSerial(',') < 0) return 0;
       pea       44
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_9
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_9:
; itoa(vsector,sqtdtam,10);
       pea       10
       move.l    A2,-(A7)
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (fsSendLongSerial(sqtdtam) < 0) return 0;
       move.l    A2,-(A7)
       jsr       (A4)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_11
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_11:
; if (fsSendSerial(',') < 0) return 0;
       pea       44
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_13
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_13:
; itoa(vhead,sqtdtam,10);
       pea       10
       move.l    A2,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (fsSendLongSerial(sqtdtam) < 0) return 0;
       move.l    A2,-(A7)
       jsr       (A4)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_15
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_15:
; if (fsSendSerial('\r') < 0) return 0;
       pea       13
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_17
       clr.b     D0
       bra       fsSectorRead_6
fsSectorRead_17:
; if (fsSendSerial('\n') < 0) return 0;
       pea       10
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_19
       clr.b     D0
       bra.s     fsSectorRead_6
fsSectorRead_19:
; for(ix = 0; ix < 512; ix++)
       clr.l     D2
fsSectorRead_21:
       cmp.l     #512,D2
       bhs.s     fsSectorRead_23
; {
; if (fsRecSerial(vbuffer) < 0)
       move.l    12(A6),-(A7)
       jsr       _fsRecSerial
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorRead_24
; return 0;
       clr.b     D0
       bra.s     fsSectorRead_6
fsSectorRead_24:
       addq.l    #1,D2
       bra       fsSectorRead_21
fsSectorRead_23:
; }
; return 1;
       moveq     #1,D0
fsSectorRead_6:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned char fsSectorWrite(unsigned short vcluster, unsigned char* vbuffer, unsigned char vtipo)
; {
       xdef      _fsSectorWrite
_fsSectorWrite:
       link      A6,#-36
       movem.l   D2/D3/D4/D5/A2/A3/A4/A5,-(A7)
       lea       -12(A6),A2
       lea       _fsSendSerial.L,A3
       lea       _fsSendLongSerial.L,A4
       lea       _itoa.L,A5
; unsigned char ix, vbytes[3], idd, idd1;
; unsigned short vpos = 0, ikk, ikk1, vcrc, vbytepic, iddok;
       clr.w     D2
; unsigned long vsectorok;
; unsigned char sqtdtam[11], vtrack = 0, vhead = 0, vsector = 0;
       clr.b     D5
       clr.b     D4
       clr.b     D3
; fsConvClusterToTHS(vcluster, vtrack, vhead, vsector);
       and.l     #255,D3
       move.l    D3,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       move.w    10(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _fsConvClusterToTHS
       add.w     #16,A7
; // w<track>,<sector><head>   Ex.: w0,1,0
; if (fsSendSerial('w') < 0) return 0;
       pea       119
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_1
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_1:
; itoa(vtrack,sqtdtam,10);
       pea       10
       move.l    A2,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (fsSendLongSerial(sqtdtam) < 0) return 0;
       move.l    A2,-(A7)
       jsr       (A4)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_4
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_4:
; if (fsSendSerial(',') < 0) return 0;
       pea       44
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_6
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_6:
; itoa(vsector,sqtdtam,10);
       pea       10
       move.l    A2,-(A7)
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (fsSendLongSerial(sqtdtam) < 0) return 0;
       move.l    A2,-(A7)
       jsr       (A4)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_8
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_8:
; if (fsSendSerial(',') < 0) return 0;
       pea       44
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_10
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_10:
; itoa(vhead,sqtdtam,10);
       pea       10
       move.l    A2,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (fsSendLongSerial(sqtdtam) < 0) return 0;
       move.l    A2,-(A7)
       jsr       (A4)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_12
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_12:
; if (fsSendSerial('\r') < 0) return 0;
       pea       13
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_14
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_14:
; if (fsSendSerial('\n') < 0) return 0;
       pea       10
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_16
       clr.b     D0
       bra       fsSectorWrite_3
fsSectorWrite_16:
; while (vpos < 512)
fsSectorWrite_18:
       cmp.w     #512,D2
       bhs.s     fsSectorWrite_20
; {
; if (fsSendSerial(vbuffer[vpos]) < 0)
       move.l    12(A6),A0
       and.l     #65535,D2
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSectorWrite_21
; return 0;
       clr.b     D0
       bra.s     fsSectorWrite_3
fsSectorWrite_21:
; vpos++;
       addq.w    #1,D2
       bra       fsSectorWrite_18
fsSectorWrite_20:
; }
; return 1;
       moveq     #1,D0
fsSectorWrite_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; int fsRecSerial(unsigned char* pByte)
; {
       xdef      _fsRecSerial
_fsRecSerial:
       link      A6,#0
       move.l    D2,-(A7)
; int vTimeOut = 131072;
       move.l    #131072,D2
; while(!(*(vmfp + Reg_RSR) & 0x80))
fsRecSerial_1:
       move.l    _vmfp.L,A0
       move.l    _Reg_RSR.L,D0
       move.b    0(A0,D0.L),D0
       and.w     #255,D0
       and.w     #128,D0
       bne.s     fsRecSerial_3
; {
; if (--vTimeOut < 0)
       subq.l    #1,D2
       cmp.l     #0,D2
       bge.s     fsRecSerial_4
; break;
       bra.s     fsRecSerial_3
fsRecSerial_4:
       bra       fsRecSerial_1
fsRecSerial_3:
; }
; if (vTimeOut >= 0)
       cmp.l     #0,D2
       blt.s     fsRecSerial_6
; *pByte = *(vmfp + Reg_UDR);
       move.l    _vmfp.L,A0
       move.l    _Reg_UDR.L,D0
       move.l    8(A6),A1
       move.b    0(A0,D0.L),(A1)
fsRecSerial_6:
; return vTimeOut;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; int fsSendSerial(unsigned char pByte)
; {
       xdef      _fsSendSerial
_fsSendSerial:
       link      A6,#0
       move.l    D2,-(A7)
; int vTimeOut = 131072;
       move.l    #131072,D2
; while(!(*(vmfp + Reg_TSR) & 0x80))  // Aguarda buffer de transmissao estar vazio
fsSendSerial_1:
       move.l    _vmfp.L,A0
       move.l    _Reg_TSR.L,D0
       move.b    0(A0,D0.L),D0
       and.w     #255,D0
       and.w     #128,D0
       bne.s     fsSendSerial_3
; {
; if (--vTimeOut < 0)
       subq.l    #1,D2
       cmp.l     #0,D2
       bge.s     fsSendSerial_4
; break;
       bra.s     fsSendSerial_3
fsSendSerial_4:
       bra       fsSendSerial_1
fsSendSerial_3:
; }
; if (vTimeOut >= 0)
       cmp.l     #0,D2
       blt.s     fsSendSerial_6
; *(vmfp + Reg_UDR) = pByte;
       move.l    _vmfp.L,A0
       move.l    _Reg_UDR.L,D0
       move.b    11(A6),0(A0,D0.L)
fsSendSerial_6:
; return vTimeOut;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; int fsSendLongSerial(unsigned char *msg)
; {
       xdef      _fsSendLongSerial
_fsSendLongSerial:
       link      A6,#0
; while (*msg)
fsSendLongSerial_1:
       move.l    8(A6),A0
       tst.b     (A0)
       beq.s     fsSendLongSerial_3
; {
; if (fsSendSerial(*msg++) < 0)
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _fsSendSerial
       addq.w    #4,A7
       cmp.l     #0,D0
       bge.s     fsSendLongSerial_4
; return -1;
       moveq     #-1,D0
       bra.s     fsSendLongSerial_6
fsSendLongSerial_4:
       bra       fsSendLongSerial_1
fsSendLongSerial_3:
; }
; return 1;
       moveq     #1,D0
fsSendLongSerial_6:
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; void fsConvClusterToTHS(unsigned short cluster, unsigned char* vtrack, unsigned char* vhead, unsigned char* vsector)
; {
       xdef      _fsConvClusterToTHS
_fsConvClusterToTHS:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _vdisk.L,A2
       move.w    10(A6),D2
       and.l     #65535,D2
; *vsector = (cluster % vdisk->secpertrack) + 1;
       move.w    D2,D0
       move.l    (A2),D1
       add.l     #20,D1
       move.l    D1,A0
       and.l     #65535,D0
       divu.w    (A0),D0
       swap      D0
       addq.w    #1,D0
       move.l    20(A6),A0
       move.b    D0,(A0)
; *vhead = (cluster / vdisk->secpertrack) % vdisk->numheads;
       move.w    D2,D0
       move.l    (A2),D1
       add.l     #20,D1
       move.l    D1,A0
       and.l     #65535,D0
       divu.w    (A0),D0
       move.l    (A2),D1
       add.l     #14,D1
       move.l    D1,A0
       and.l     #65535,D0
       divu.w    (A0),D0
       swap      D0
       move.l    16(A6),A0
       move.b    D0,(A0)
; *vtrack = cluster / (vdisk->secpertrack * vdisk->numheads);
       move.w    D2,D0
       move.l    (A2),A0
       move.w    20(A0),D1
       move.l    (A2),A0
       mulu.w    14(A0),D1
       and.l     #65535,D0
       divu.w    D1,D0
       move.l    12(A6),A0
       move.b    D0,(A0)
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned int bcd2dec(unsigned int bcd)
; {
       xdef      _bcd2dec
_bcd2dec:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D2
; unsigned int dec=0;
       clr.l     D4
; unsigned int mult;
; for (mult=1; bcd; bcd=bcd>>4,mult*=10)
       moveq     #1,D3
bcd2dec_1:
       tst.l     D2
       beq.s     bcd2dec_3
; dec += (bcd & 0x0f) * mult;
       move.l    D2,D0
       and.l     #15,D0
       move.l    D0,-(A7)
       move.l    D3,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     D0,D4
       lsr.l     #4,D2
       move.l    D3,-(A7)
       pea       10
       jsr       ULMUL
       move.l    (A7),D3
       addq.w    #8,A7
       bra       bcd2dec_1
bcd2dec_3:
; return dec;
       move.l    D4,D0
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; // ds1307 array: 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano
; //-------------------------------------------------------------------------
; int getDateTimeAtu(ds1307)
; {
       xdef      _getDateTimeAtu
_getDateTimeAtu:
       link      A6,#0
; return 0;
       clr.l     D0
       unlk      A6
       rts
; }
; //-------------------------------------------------------------------------
; unsigned short datetimetodir(unsigned char hr_day, unsigned char min_month, unsigned char sec_year, unsigned char vtype)
; {
       xdef      _datetimetodir
_datetimetodir:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; unsigned short vconv = 0, vtemp;
       clr.w     D2
; if (vtype == CONV_DATA) {
       move.b    23(A6),D0
       cmp.b     #1,D0
       bne       datetimetodir_1
; vtemp = sec_year - 1980;
       move.b    19(A6),D0
       and.w     #255,D0
       sub.w     #1980,D0
       move.w    D0,D3
; vconv  = (unsigned short)(vtemp & 0x7F) << 9;
       move.w    D3,D0
       and.w     #127,D0
       lsl.w     #8,D0
       lsl.w     #1,D0
       move.w    D0,D2
; vconv |= (unsigned short)(min_month & 0x0F) << 5;
       move.b    15(A6),D0
       and.b     #15,D0
       and.w     #255,D0
       lsl.w     #5,D0
       or.w      D0,D2
; vconv |= (unsigned short)(hr_day & 0x1F);
       move.b    11(A6),D0
       and.b     #31,D0
       and.w     #255,D0
       or.w      D0,D2
       bra       datetimetodir_2
datetimetodir_1:
; }
; else {
; vconv  = (unsigned short)(hr_day & 0x1F) << 11;
       move.b    11(A6),D0
       and.b     #31,D0
       and.w     #255,D0
       lsl.w     #8,D0
       lsl.w     #3,D0
       move.w    D0,D2
; vconv |= (unsigned short)(min_month & 0x3F) << 5;
       move.b    15(A6),D0
       and.b     #63,D0
       and.w     #255,D0
       lsl.w     #5,D0
       or.w      D0,D2
; vtemp = sec_year / 2;
       move.b    19(A6),D0
       and.l     #65535,D0
       divu.w    #2,D0
       and.w     #255,D0
       move.w    D0,D3
; vconv |= (unsigned short)(vtemp & 0x1F);
       move.w    D3,D0
       and.w     #31,D0
       or.w      D0,D2
datetimetodir_2:
; }
; return vconv;
       move.w    D2,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
       section   const
@monitorfa@monitorfa@monitorfa@monitorf_1:
       dc.b      77,77,83,74,45,79,83,32,118,49,46,48,97,0
@monitorfa@monitorfa@monitorfa@monitorf_2:
       dc.b      13,10,0
@monitorfa@monitorfa@monitorfa@monitorf_3:
       dc.b      76,83,0
@monitorfa@monitorfa@monitorfa@monitorf_4:
       dc.b      70,105,108,101,32,110,111,116,32,102,111,117
       dc.b      110,100,10,0
@monitorfa@monitorfa@monitorfa@monitorf_5:
       dc.b      10,0
@monitorfa@monitorfa@monitorfa@monitorf_6:
       dc.b      82,77,0
@monitorfa@monitorfa@monitorfa@monitorf_7:
       dc.b      82,69,78,0
@monitorfa@monitorfa@monitorfa@monitorf_8:
       dc.b      67,80,0
@monitorfa@monitorfa@monitorfa@monitorf_9:
       dc.b      77,68,0
@monitorfa@monitorfa@monitorfa@monitorf_10:
       dc.b      67,68,0
@monitorfa@monitorfa@monitorfa@monitorf_11:
       dc.b      82,68,0
@monitorfa@monitorfa@monitorfa@monitorf_12:
       dc.b      68,65,84,69,0
@monitorfa@monitorfa@monitorfa@monitorf_13:
       dc.b      84,73,77,69,0
@monitorfa@monitorfa@monitorfa@monitorf_14:
       dc.b      70,79,82,77,65,84,0
@monitorfa@monitorfa@monitorfa@monitorf_15:
       dc.b      67,65,84,0
@monitorfa@monitorfa@monitorfa@monitorf_16:
       dc.b      76,111,97,100,105,110,103,32,70,105,108,101
       dc.b      32,69,114,114,111,114,46,46,46,10,0
@monitorfa@monitorfa@monitorfa@monitorf_17:
       dc.b      73,110,118,97,108,105,100,32,67,111,109,109
       dc.b      97,110,100,32,111,114,32,70,105,108,101,32,78
       dc.b      97,109,101,10,0
@monitorfa@monitorfa@monitorfa@monitorf_18:
       dc.b      67,111,109,109,97,110,100,32,117,110,115,117
       dc.b      99,99,101,115,115,102,117,108,108,121,10,0
@monitorfa@monitorfa@monitorfa@monitorf_19:
       dc.b      32,32,68,97,116,101,32,105,115,32,0
@monitorfa@monitorfa@monitorfa@monitorf_20:
       dc.b      32,32,84,105,109,101,32,105,115,32,0
@monitorfa@monitorfa@monitorfa@monitorf_21:
       dc.b      70,111,114,109,97,116,32,100,105,115,107,32
       dc.b      119,97,115,32,115,117,99,99,101,115,115,102
       dc.b      117,108,108,121,10,0
       xdef      _strValidChars
_strValidChars:
       dc.b      48,49,50,51,52,53,54,55,56,57,65,66,67,68,69
       dc.b      70,71,72,73,74,75,76,77,78,79,80,81,82,83,84
       dc.b      85,86,87,88,89,90,94,38,39,64,123,125,91,93
       dc.b      44,36,61,33,45,35,40,41,37,46,43,126,95,0
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
       xdef      _mcfgfile
_mcfgfile:
       dc.l      6332408
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
       dc.l      6350466
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
       xdef      _vmesc
_vmesc:
       dc.b      74,97,110,70,101,98,77,97,114,65,112,114,77
       dc.b      97,121,74,117,110,74,117,108,65,117,103,83,101
       dc.b      112,79,99,116,78,111,118,68,101,99
       xdef      _vdir
_vdir:
       dc.l      6331600
       xdef      _vdisk
_vdisk:
       dc.l      6331648
       xdef      _vclusterdir
_vclusterdir:
       dc.l      6331872
       xdef      _vclusteros
_vclusteros:
       dc.l      6331880
       xdef      _gDataBuffer
_gDataBuffer:
       dc.l      6331888
       xdef      _verroSo
_verroSo:
       dc.l      6344750
       xdef      _vdiratu
_vdiratu:
       dc.l      6344752
       xdef      _vdiratup
_vdiratup:
       dc.l      6344752
       xdef      _Reg_UCR
_Reg_UCR:
       dc.l      5121
       xdef      _Reg_UDR
_Reg_UDR:
       dc.l      5889
       xdef      _Reg_RSR
_Reg_RSR:
       dc.l      5377
       xdef      _Reg_TSR
_Reg_TSR:
       dc.l      5633
       xdef      _Reg_VR
_Reg_VR:
       dc.l      2817
       xdef      _Reg_IERA
_Reg_IERA:
       dc.l      769
       xdef      _Reg_IERB
_Reg_IERB:
       dc.l      1025
       xdef      _Reg_IPRA
_Reg_IPRA:
       dc.l      1281
       xdef      _Reg_IPRB
_Reg_IPRB:
       dc.l      1537
       xdef      _Reg_IMRA
_Reg_IMRA:
       dc.l      2305
       xdef      _Reg_IMRB
_Reg_IMRB:
       dc.l      2561
       xdef      _Reg_ISRA
_Reg_ISRA:
       dc.l      1793
       xdef      _Reg_ISRB
_Reg_ISRB:
       dc.l      2049
       xdef      _Reg_TADR
_Reg_TADR:
       dc.l      3841
       xdef      _Reg_TBDR
_Reg_TBDR:
       dc.l      4097
       xdef      _Reg_TCDR
_Reg_TCDR:
       dc.l      4353
       xdef      _Reg_TDDR
_Reg_TDDR:
       dc.l      4609
       xdef      _Reg_TACR
_Reg_TACR:
       dc.l      3073
       xdef      _Reg_TBCR
_Reg_TBCR:
       dc.l      3329
       xdef      _Reg_TCDCR
_Reg_TCDCR:
       dc.l      3585
       xdef      _Reg_GPDR
_Reg_GPDR:
       dc.l      1
       xdef      _Reg_AER
_Reg_AER:
       dc.l      257
       xdef      _Reg_DDR
_Reg_DDR:
       dc.l      513
       section   bss
       xdef      _WORD
_WORD:
       ds.b      4
       xref      _itoa
       xref      _strlen
       xref      _catFile
       xref      ULMUL
       xref      _memset
       xref      _runCmd
       xref      _printText
       xref      _strcmp
       xref      ULDIV
       xref      _loadFile
