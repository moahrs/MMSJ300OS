; D:\PROJETOS\MMSJ300\PROGS_MONITOR\TESTEHGR.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J.Fondse
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "../mmsj300api.h"
; #include "../monitor.h"
; #include "testehgr.h"
; //-----------------------------------------------------------------------------
; // Principal
; //-----------------------------------------------------------------------------
; void main(void)
; {
       section   code
       xdef      _main
_main:
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       _fgcolor.L,A2
       lea       _bgcolor.L,A3
       lea       _writeLongSerial.L,A4
       lea       _uvdp_plot_hires.L,A5
; unsigned char vx, vy;
; unsigned char vtec;
; // Timer para o Random
; *(vmfp + Reg_TADR) = 0xF5;  // 245
       move.l    _vmfp.L,A0
       move.l    _Reg_TADR.L,D0
       move.b    #245,0(A0,D0.L)
; *(vmfp + Reg_TACR) = 0x02;  // prescaler de 10. total 2,4576Mhz/10*245 = 1003KHz
       move.l    _vmfp.L,A0
       move.l    _Reg_TACR.L,D0
       move.b    #2,0(A0,D0.L)
; clearScr();
       jsr       _clearScr
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
; writeLongSerial("***************[Ponto]******************\r\n");
       pea       @testehgr_1.L
       jsr       (A4)
       addq.w    #4,A7
; uvdp_plot_hires(40, 40, *fgcolor, *bgcolor);
       move.l    (A3),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       40
       pea       40
       jsr       (A5)
       add.w     #16,A7
; writeLongSerial("**********[Linha Horizontal]************\r\n");
       pea       @testehgr_2.L
       jsr       (A4)
       addq.w    #4,A7
; for (vx = 50; vx < 120; vx++)
       moveq     #50,D3
main_1:
       cmp.b     #120,D3
       bhs.s     main_3
; uvdp_plot_hires(vx, 50, *fgcolor, *bgcolor);
       move.l    (A3),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       50
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #16,A7
       addq.b    #1,D3
       bra       main_1
main_3:
; writeLongSerial("**********[Linha Vertical 1]************\r\n");
       pea       @testehgr_3.L
       jsr       (A4)
       addq.w    #4,A7
; for (vy = 50; vy < 120; vy++)
       moveq     #50,D2
main_4:
       cmp.b     #120,D2
       bhs.s     main_6
; uvdp_plot_hires(50, vy, *fgcolor, *bgcolor);
       move.l    (A3),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       50
       jsr       (A5)
       add.w     #16,A7
       addq.b    #1,D2
       bra       main_4
main_6:
; writeLongSerial("**********[Linha Vertical 2]************\r\n");
       pea       @testehgr_4.L
       jsr       (A4)
       addq.w    #4,A7
; for (vy = 50; vy < 120; vy++)
       moveq     #50,D2
main_7:
       cmp.b     #120,D2
       bhs.s     main_9
; uvdp_plot_hires(120, vy, *fgcolor, *bgcolor);
       move.l    (A3),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       120
       jsr       (A5)
       add.w     #16,A7
       addq.b    #1,D2
       bra       main_7
main_9:
; writeLongSerial("****************[FIM]*******************\r\n");
       pea       @testehgr_5.L
       jsr       (A4)
       addq.w    #4,A7
; vtec = 0x00;
       clr.b     D4
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; while(!vtec)
main_10:
       tst.b     D4
       bne.s     main_12
; {
; readChar();
       jsr       _readChar
; vtec = *vBufReceived;        
       move.l    _vBufReceived.L,A0
       move.b    (A0),D4
       bra       main_10
main_12:
; }
; *fgcolor = VDP_WHITE;
       move.l    (A2),A0
       move.b    #15,(A0)
; *bgcolor = VDP_BLACK;
       move.l    (A3),A0
       move.b    #1,(A0)
; vdp_init(VDP_MODE_TEXT, (*fgcolor<<4) | (*bgcolor & 0x0f), 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    (A2),A0
       move.b    (A0),D1
       lsl.b     #4,D1
       move.l    (A3),A0
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
       movem.l   (A7)+,D2/D3/D4/A2/A3/A4/A5
       rts
; }
; //-----------------------------------------------------------------------------
; void setWriteAddress(unsigned int address)
; {
       xdef      _setWriteAddress
_setWriteAddress:
       link      A6,#0
; *vvdgc = (unsigned char)(address & 0xff);
       move.l    8(A6),D0
       and.l     #255,D0
       move.l    _vvdgc.L,A0
       move.b    D0,(A0)
; *vvdgc = (unsigned char)(0x40 | (address >> 8) & 0x3f);
       moveq     #64,D0
       ext.w     D0
       ext.l     D0
       move.l    8(A6),D1
       lsr.l     #8,D1
       and.l     #63,D1
       or.l      D1,D0
       move.l    _vvdgc.L,A0
       move.b    D0,(A0)
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void setReadAddress(unsigned int address)
; {
       xdef      _setReadAddress
_setReadAddress:
       link      A6,#0
; *vvdgc = (unsigned char)(address & 0xff);
       move.l    8(A6),D0
       and.l     #255,D0
       move.l    _vvdgc.L,A0
       move.b    D0,(A0)
; *vvdgc = (unsigned char)((address >> 8) & 0x3f);
       move.l    8(A6),D0
       lsr.l     #8,D0
       and.l     #63,D0
       move.l    _vvdgc.L,A0
       move.b    D0,(A0)
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void uvdp_plot_hires(unsigned char x, unsigned char y, unsigned char color1, unsigned char color2)
; {
       xdef      _uvdp_plot_hires
_uvdp_plot_hires:
       link      A6,#-20
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _writeLongSerial.L,A2
       lea       -10(A6),A3
       lea       _itoa.L,A4
       lea       _vvdgd.L,A5
       move.b    11(A6),D5
       and.l     #255,D5
       move.b    19(A6),D6
       and.l     #255,D6
; unsigned int offset, posX, posY, modY;
; unsigned char pixel;
; unsigned char color;
; unsigned char sqtdtam[10];
; posX = (int)(8 * (x / 8));
       move.b    D5,D0
       and.l     #65535,D0
       divu.w    #8,D0
       and.w     #255,D0
       mulu.w    #8,D0
       and.l     #255,D0
       move.l    D0,-18(A6)
; posY = (int)(256 * (y / 8));
       move.b    15(A6),D0
       and.l     #65535,D0
       divu.w    #8,D0
       and.w     #255,D0
       lsl.w     #8,D0
       ext.l     D0
       move.l    D0,-14(A6)
; modY = (int)(y % 8);
       move.b    15(A6),D0
       and.l     #65535,D0
       divu.w    #8,D0
       swap      D0
       and.l     #255,D0
       move.l    D0,D7
; offset = posX + modY + posY;
       move.l    -18(A6),D0
       add.l     D7,D0
       add.l     -14(A6),D0
       move.l    D0,D3
; writeLongSerial("Aqui 777.666.0-[");
       pea       @testehgr_6.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(x,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial(",");
       pea       @testehgr_7.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(y,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[cor: ");
       pea       @testehgr_8.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(color1,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[posX: ");
       pea       @testehgr_9.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(posX,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    -18(A6),-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[modY: ");
       pea       @testehgr_10.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(modY,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    D7,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[posY: ");
       pea       @testehgr_11.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(posY,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       move.l    -14(A6),-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]-[offset: ");
       pea       @testehgr_12.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(offset,sqtdtam,16);
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
       pea       @testehgr_13.L
       jsr       (A2)
       addq.w    #4,A7
; setReadAddress(*pattern_table + offset);
       move.l    _pattern_table.L,A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; setReadAddress(*pattern_table + offset);
       move.l    _pattern_table.L,A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; pixel = *vvdgd;
       move.l    (A5),A0
       move.b    (A0),D4
; setReadAddress(*color_table + offset);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; setReadAddress(*color_table + offset);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; color = *vvdgd;
       move.l    (A5),A0
       move.b    (A0),D2
; writeLongSerial("Aqui 777.666.1-[");
       pea       @testehgr_14.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pixel,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial(",");
       pea       @testehgr_7.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(color,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @testehgr_13.L
       jsr       (A2)
       addq.w    #4,A7
; if (color1 != 0x00)
       tst.b     D6
       beq.s     uvdp_plot_hires_1
; {
; pixel |= 0x80 >> (x % 8); //Set a "1"
       move.w    #128,D0
       move.b    D5,D1
       and.l     #65535,D1
       divu.w    #8,D1
       swap      D1
       and.w     #255,D1
       asr.w     D1,D0
       or.b      D0,D4
; color = (color & 0x0F) | (color1 << 4);
       move.b    D2,D0
       and.b     #15,D0
       move.b    D6,D1
       lsl.b     #4,D1
       or.b      D1,D0
       move.b    D0,D2
       bra       uvdp_plot_hires_2
uvdp_plot_hires_1:
; }
; else
; {
; pixel &= ~(0x80 >> (x % 8)); //Set bit as "0"
       move.w    #128,D0
       move.b    D5,D1
       and.l     #65535,D1
       divu.w    #8,D1
       swap      D1
       and.w     #255,D1
       asr.w     D1,D0
       not.w     D0
       and.b     D0,D4
; color = (color & 0xF0) | (color2 & 0x0F);
       move.b    D2,D0
       and.w     #255,D0
       and.w     #240,D0
       move.b    23(A6),D1
       and.b     #15,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D2
uvdp_plot_hires_2:
; }
; writeLongSerial("Aqui 777.666.2-[");
       pea       @testehgr_15.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(pixel,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial(",");
       pea       @testehgr_7.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(color,sqtdtam,16);
       pea       16
       move.l    A3,-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       (A4)
       add.w     #12,A7
; writeLongSerial(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("]\r\n");
       pea       @testehgr_13.L
       jsr       (A2)
       addq.w    #4,A7
; setWriteAddress(*pattern_table + offset);
       move.l    _pattern_table.L,A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (pixel);
       move.l    (A5),A0
       move.b    D4,(A0)
; setWriteAddress(*color_table + offset);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (color);
       move.l    (A5),A0
       move.b    D2,(A0)
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
       section   const
@testehgr_1:
       dc.b      42,42,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      91,80,111,110,116,111,93,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,42,42,13,10,0
@testehgr_2:
       dc.b      42,42,42,42,42,42,42,42,42,42,91,76,105,110
       dc.b      104,97,32,72,111,114,105,122,111,110,116,97
       dc.b      108,93,42,42,42,42,42,42,42,42,42,42,42,42,13
       dc.b      10,0
@testehgr_3:
       dc.b      42,42,42,42,42,42,42,42,42,42,91,76,105,110
       dc.b      104,97,32,86,101,114,116,105,99,97,108,32,49
       dc.b      93,42,42,42,42,42,42,42,42,42,42,42,42,13,10
       dc.b      0
@testehgr_4:
       dc.b      42,42,42,42,42,42,42,42,42,42,91,76,105,110
       dc.b      104,97,32,86,101,114,116,105,99,97,108,32,50
       dc.b      93,42,42,42,42,42,42,42,42,42,42,42,42,13,10
       dc.b      0
@testehgr_5:
       dc.b      42,42,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,91,70,73,77,93,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,42,13,10,0
@testehgr_6:
       dc.b      65,113,117,105,32,55,55,55,46,54,54,54,46,48
       dc.b      45,91,0
@testehgr_7:
       dc.b      44,0
@testehgr_8:
       dc.b      93,45,91,99,111,114,58,32,0
@testehgr_9:
       dc.b      93,45,91,112,111,115,88,58,32,0
@testehgr_10:
       dc.b      93,45,91,109,111,100,89,58,32,0
@testehgr_11:
       dc.b      93,45,91,112,111,115,89,58,32,0
@testehgr_12:
       dc.b      93,45,91,111,102,102,115,101,116,58,32,0
@testehgr_13:
       dc.b      93,13,10,0
@testehgr_14:
       dc.b      65,113,117,105,32,55,55,55,46,54,54,54,46,49
       dc.b      45,91,0
@testehgr_15:
       dc.b      65,113,117,105,32,55,55,55,46,54,54,54,46,50
       dc.b      45,91,0
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
       xdef      _verro
_verro:
       dc.l      6344750
       xdef      _vdiratu
_vdiratu:
       dc.l      6344752
       xdef      _vdiratup
_vdiratup:
       dc.l      6344752
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
       xref      _vdp_set_bdcolor
       xref      _clearScr
       xref      _vdp_init
       xref      _writeLongSerial
       xref      _readChar
