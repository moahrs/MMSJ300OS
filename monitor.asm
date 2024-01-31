; D:\PROJETOS\MMSJ300\MONITOR.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J.Fondse
; /********************************************************************************
; *    Programa    : monitor.c
; *    Objetivo    : BIOS do modulo MMSJ300 - Versao vintage compatible
; *    Criado em   : 17/09/2022
; *    Programador : Moacir Jr.
; *--------------------------------------------------------------------------------
; * Data        Versao  Responsavel  Motivo
; * 17/09/2022  0.1     Moacir Jr.   Criacao Versao Beta
; *                                  512KB EEPROM + 256KB RAM BUFFER + 8MB RAM USU
; * 12/11/2023  0.2     Moacir Jr.   Adaptacao do MC68901 p/ serial e interrupcoes
; * 01/06/2023  0.3     Moacir Jr.   Adaptacao do teclado PS/2 via arduino nano
; *                                  Simulando um FPGA de epoca
; * 22/06/2023  0.4     Moacir Jr.   Adaptacao do TMS9118 VDP
; * 23/06/2023  0.4a    Moacir Jr.   Adaptacao lib arduino tms9918 pro mmsj300
; * 15/07/2023  0.4b    Moacir Jr.   Colocar tela vermelha de erros
; * 15/07/2023  0.4c    Moacir Jr.   Colocar rotina de trace
; * 18/07/2023  0.4d    Moacir Jr.   Verificar e Ajustar Problema no G2 do VDP
; * 19/07/2023  1.0     Moacir Jr.   Versao para publicacao
; * 20/07/2023  1.0a    Moacir Jr.   Ajuste de bugs
; * 21/07/2023  1.1     Moacir Jr.   Adaptar Basic ao monitor
; * 25/07/2023  1.1a    Moacir Jr.   Ajustes no inputLine, aceitar tipo '@'
; * 20/01/2024  1.1b    Moacir Jr.   Iniciar direto no basic... Ai com QUIT, volta pro monitor
; *--------------------------------------------------------------------------------
; *
; * Mapa de Memoria
; * ---------------
; *
; *     SLOT 0                          SLOT 1
; * +-------------+ 000000h
; * |   EEPROM    |
; * |   512KB     |
; * |   (BIOS)    | 07FFFFh
; * +-------------+ 080000h
; * |    LIVRE    | 1FFFFFh
; * +-------------+ 200000h
; * |             |
; * |  EXPANSAO   |
; * |             | 3FFFFFh
; * +-------------+ 400000h
; * |             |
; * | PERIFERICOS |
; * |             | 5FFFFFh
; * +-------------+ 600000h
; * |  RAM 256KB  |
; * |  BUFFER E   |
; * |  SISTEMA    | 63FFFFh
; * +-------------+ 640000h
; * |    LIVRE    | 7FFFFFh
; * +-------------+ 800000h
; * |             |
; * |   ATUAL     |
; * |    RAM      |
; * |  USUARIO    |
; * |    1MB      | 8FFFFFh
; * +-------------+ 900000h
; * |             |
; * |             |
; * |    RAM      |
; * |  USUARIO    |
; * |    7MB      |
; * |             |
; * |             |
; * |             |
; * |             |
; * |             |
; * |             |
; * |             |
; * |             |
; * +-------------+ FFFFFFh
; *--------------------------------------------------------------------------------
; *
; * Enderecos de Perifericos
; *
; * 00400020h a 0040003F - MFP MC68901p
; *                        - SERIAL 9600, 8, 1, n
; *                        - TECLADO (PC-AT - PS/2) via Arduino Nano
; *                        - Controle de Interrupcoes e PS/2
; * 00400040h a 00400043 - VIDEO TMS9118 (16KB VRAM):
; *             00400041 - Data Mode
; *             00400043 - Register / Adress Mode
; ********************************************************************************/
; //#define __FS12__ 1
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "mmsj300api.h"
; #include "monitor.h"
; #ifdef __FS12__
; #include "monitorf.h"
; #endif
; #define versionBios "1.1b"
; //-----------------------------------------------------------------------------
; // Principal
; //-----------------------------------------------------------------------------
; void main(void)
; {
       section   code
       xdef      _main
_main:
       link      A6,#-16
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vmfp.L,A2
       lea       _printText.L,A3
       lea       _vbuf.L,A4
       lea       -12(A6),A5
; unsigned short *xaddr = (unsigned short *) 0x00600000;
       move.l    #6291456,D2
; unsigned short vbytepic = 0, xdado;
       clr.w     -14(A6)
; unsigned int ix = 0, xcounter = 0;
       clr.l     D3
       clr.l     D4
; unsigned char sqtdtam[10], vRetInput;
; unsigned char vRamSyst1st = 1, vRamUser1st = 1;
       move.b    #1,-2(A6)
       move.b    #1,-1(A6)
; int vRetProcCmd;
; // Inicia com Basic
; *startBasic = 1;
       move.l    _startBasic.L,A0
       move.w    #1,(A0)
; // Tempo para Inicializar a Memoria DRAM (se tiver), Perifericos e etc...
; for(ix = 0; ix <= 12000; ix++);
       clr.l     D3
main_1:
       cmp.l     #12000,D3
       bhi.s     main_3
       addq.l    #1,D3
       bra       main_1
main_3:
; //---------------------------------------------
; // Enviar setup para o MFP 68901
; //---------------------------------------------
; *vBufXmitEmpty = 1;
       move.l    _vBufXmitEmpty.L,A0
       move.b    #1,(A0)
; // Setup Timers
; *(vmfp + Reg_TCDR)  = 0x02;
       move.l    (A2),A0
       move.w    _Reg_TCDR.L,D0
       and.l     #65535,D0
       move.b    #2,0(A0,D0.L)
; *(vmfp + Reg_TDDR)  = 0x02;
       move.l    (A2),A0
       move.w    _Reg_TDDR.L,D0
       and.l     #65535,D0
       move.b    #2,0(A0,D0.L)
; *(vmfp + Reg_TCDCR) = 0x11;
       move.l    (A2),A0
       move.w    _Reg_TCDCR.L,D0
       and.l     #65535,D0
       move.b    #17,0(A0,D0.L)
; // Setup Interruptions
; *(vmfp + Reg_VR)    = 0xA8; // vector = 0xA msb = 0x1010 and lsb = 0x1000 software end session interrupt
       move.l    (A2),A0
       move.w    _Reg_VR.L,D0
       and.l     #65535,D0
       move.b    #168,0(A0,D0.L)
; *(vmfp + Reg_IERA)  = 0x00; // disable all at start
       move.l    (A2),A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_IERB)  = 0x00; // disable all at start
       move.l    (A2),A0
       move.w    _Reg_IERB.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_IMRA)  = 0x00; // disable all at start
       move.l    (A2),A0
       move.w    _Reg_IMRA.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_IMRB)  = 0x00; // disable all at start
       move.l    (A2),A0
       move.w    _Reg_IMRB.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_ISRA)  = 0x00; // disable all at start
       move.l    (A2),A0
       move.w    _Reg_ISRA.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_ISRB)  = 0x00; // disable all at start
       move.l    (A2),A0
       move.w    _Reg_ISRB.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; // Setup Serial = 9600, 8, 1, n
; *(vmfp + Reg_UCR)   = 0x88;
       move.l    (A2),A0
       move.w    _Reg_UCR.L,D0
       and.l     #65535,D0
       move.b    #136,0(A0,D0.L)
; *(vmfp + Reg_RSR)   = 0x01;
       move.l    (A2),A0
       move.w    _Reg_RSR.L,D0
       and.l     #65535,D0
       move.b    #1,0(A0,D0.L)
; *(vmfp + Reg_TSR)   = 0x21;
       move.l    (A2),A0
       move.w    _Reg_TSR.L,D0
       and.l     #65535,D0
       move.b    #33,0(A0,D0.L)
; // Setup GPIO
; *(vmfp + Reg_DDR)   = 0x10; // I4 as Output, I7 - I5 e I3 - I0 as Input
       move.l    (A2),A0
       move.w    _Reg_DDR.L,D0
       and.l     #65535,D0
       move.b    #16,0(A0,D0.L)
; *(vmfp + Reg_AER)   = 0x00; // All Interrupts transction 1 to 0
       move.l    (A2),A0
       move.w    _Reg_AER.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; // Setup Interruptions
; *(vmfp + Reg_IERA)  = 0x00; // 0xCE; // serial interrupt (buffer full and empty) i7 = Fs vdp6847, I6 = Clock KeyBoard (clk pin OR DTRDY pin)
       move.l    (A2),A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_IERB)  = 0x00;
       move.l    (A2),A0
       move.w    _Reg_IERB.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_IMRA)  = 0x00; // 0xCE; // serial interrupt (buffer full and empty) i7 = Fs vdp6847, I6 = Clock KeyBoard (clk pin OR DTRDY pin)
       move.l    (A2),A0
       move.w    _Reg_IMRA.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; *(vmfp + Reg_IMRB)  = 0x00;
       move.l    (A2),A0
       move.w    _Reg_IMRB.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; //---------------------------------------------
; #ifdef __KEYPS2_EXT__
; *(vmfp + Reg_GPDR) |= 0x10;  // Seta CS = 1 (I4) do controlador
       move.l    (A2),A0
       move.w    _Reg_GPDR.L,D0
       and.l     #65535,D0
       or.b      #16,0(A0,D0.L)
; #endif
; //---------------------------------------------
; // Enviar setup para o VDP TMS9118
; //---------------------------------------------
; // Definindo variaveis de video
; *videoCursorPosColX = 0;
       move.l    _videoCursorPosColX.L,A0
       clr.w     (A0)
; *videoCursorPosRowY = 0;
       move.l    _videoCursorPosRowY.L,A0
       clr.w     (A0)
; *videoScroll = 1;       // Ativo
       move.l    _videoScroll.L,A0
       move.b    #1,(A0)
; *videoScrollDir = 1;    // Pra Cima
       move.l    _videoScrollDir.L,A0
       move.b    #1,(A0)
; *videoCursorBlink = 1;
       move.l    _videoCursorBlink.L,A0
       move.b    #1,(A0)
; *videoCursorShow = 0;
       move.l    _videoCursorShow.L,A0
       clr.b     (A0)
; *vdpMaxCols = 39;
       move.l    _vdpMaxCols.L,A0
       move.b    #39,(A0)
; *vdpMaxRows = 23;
       move.l    _vdpMaxRows.L,A0
       move.b    #23,(A0)
; vdp_init_textmode(VDP_WHITE, VDP_BLACK);
       pea       1
       pea       15
       jsr       _vdp_init_textmode
       addq.w    #8,A7
; //---------------------------------------------
; // Zera Tudo (se tiver o que zerar), sem verificar, antes de testar
; xaddr = 0x00600000;
       move.l    #6291456,D2
; while (xaddr <= 0x00FFFFFE)
main_4:
       cmp.l     #16777214,D2
       bhi.s     main_6
; {
; *xaddr = 0x0000;
       move.l    D2,A0
       clr.w     (A0)
; xaddr += 32768;
       add.l     #65536,D2
       bra       main_4
main_6:
; }
; // Testando memoria RAM de 64 em 64K Word pra saber quando tem
; xaddr = 0x00600000;
       move.l    #6291456,D2
; xcounter = 0;
       clr.l     D4
; while (xaddr <= 0x00FFFFFE) {
main_7:
       cmp.l     #16777214,D2
       bhi       main_9
; // Se ja passou por esse endereco, cai fora - (caso de usar memoria de sistema como principal)
; xdado = *xaddr;
       move.l    D2,A0
       move.w    (A0),D5
; if (xaddr < 0x00800000 && xdado == 0x5A4C && !vRamSyst1st)
       cmp.l     #8388608,D2
       bhs.s     main_10
       cmp.w     #23116,D5
       bne.s     main_10
       tst.b     -2(A6)
       bne.s     main_12
       moveq     #1,D0
       bra.s     main_13
main_12:
       clr.l     D0
main_13:
       and.l     #255,D0
       beq.s     main_10
; {
; xaddr = 0x00800000;
       move.l    #8388608,D2
; continue;
       bra       main_8
main_10:
; }
; else
; {
; if (xaddr >= 0x00800000 && xdado == 0x5A4C && !vRamUser1st)
       cmp.l     #8388608,D2
       blo.s     main_14
       cmp.w     #23116,D5
       bne.s     main_14
       tst.b     -1(A6)
       bne.s     main_16
       moveq     #1,D0
       bra.s     main_17
main_16:
       clr.l     D0
main_17:
       and.l     #255,D0
       beq.s     main_14
; break;
       bra       main_9
main_14:
; }
; // Testa Gravacao de 0000h
; *xaddr = 0x0000;
       move.l    D2,A0
       clr.w     (A0)
; for(ix = 0; ix <= 100; ix++);
       clr.l     D3
main_18:
       cmp.l     #100,D3
       bhi.s     main_20
       addq.l    #1,D3
       bra       main_18
main_20:
; xdado = *xaddr;
       move.l    D2,A0
       move.w    (A0),D5
; if (xdado != 0x0000)
       tst.w     D5
       beq.s     main_21
; {
; if (xaddr < 0x00800000)
       cmp.l     #8388608,D2
       bhs.s     main_23
; {
; xaddr = 0x00800000;
       move.l    #8388608,D2
; continue;
       bra       main_8
main_23:
; }
; break;
       bra       main_9
main_21:
; }
; // Testa Gravacao de FFFFh
; *xaddr = 0xFFFF;
       move.l    D2,A0
       move.w    #65535,(A0)
; for(ix = 0; ix <= 100; ix++);
       clr.l     D3
main_25:
       cmp.l     #100,D3
       bhi.s     main_27
       addq.l    #1,D3
       bra       main_25
main_27:
; xdado = *xaddr;
       move.l    D2,A0
       move.w    (A0),D5
; if (xdado != 0xFFFF)
       cmp.w     #65535,D5
       beq.s     main_28
; {
; if (xaddr < 0x00800000)
       cmp.l     #8388608,D2
       bhs.s     main_30
; {
; xaddr = 0x00800000;
       move.l    #8388608,D2
; continue;
       bra.s     main_8
main_30:
; }
; break;
       bra.s     main_9
main_28:
; }
; // Se tudo ok, deixa gravado 0x5A4C para nao ler novamente - (caso de usar memoria de sistema como principal)
; *xaddr = 0x5A4C;
       move.l    D2,A0
       move.w    #23116,(A0)
; if (xaddr < 0x00800000)
       cmp.l     #8388608,D2
       bhs.s     main_32
; vRamSyst1st = 0;
       clr.b     -2(A6)
       bra.s     main_33
main_32:
; else
; vRamUser1st = 0;
       clr.b     -1(A6)
main_33:
; xcounter += 64; // dobrar a soma para aparecer em bytes e nao em words
       add.l     #64,D4
; // Limite maximo de contagem, 8MB
; if (xcounter >= 8448)
       cmp.l     #8448,D4
       blo.s     main_34
; break;
       bra.s     main_9
main_34:
; xaddr += 32768;
       add.l     #65536,D2
main_8:
       bra       main_7
main_9:
; }
; *vtotmem = xcounter;
       move.l    _vtotmem.L,A0
       move.w    D4,(A0)
; *(vmfp + Reg_GPDR) = 0x00;
       move.l    (A2),A0
       move.w    _Reg_GPDR.L,D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; clearScr();
       jsr       _clearScr
; printText("MMSJ-300 BIOS v"versionBios);
       pea       @monitor_1.L
       jsr       (A3)
       addq.w    #4,A7
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
; #ifdef __FS12__
; fsInit();
; #endif
; printText("Utility (c) 2014-2024\r\n\0");
       pea       @monitor_3.L
       jsr       (A3)
       addq.w    #4,A7
; itoa(xcounter, sqtdtam, 10);
       pea       10
       move.l    A5,-(A7)
       move.l    D4,-(A7)
       jsr       _itoa
       add.w     #12,A7
; printText(sqtdtam);
       move.l    A5,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; printText("K Bytes Found. ");
       pea       @monitor_4.L
       jsr       (A3)
       addq.w    #4,A7
; xcounter = xcounter - 256;
       sub.l     #256,D4
; itoa(xcounter, sqtdtam, 10);
       pea       10
       move.l    A5,-(A7)
       move.l    D4,-(A7)
       jsr       _itoa
       add.w     #12,A7
; printText(sqtdtam);
       move.l    A5,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; printText("K Bytes Free.\r\n\0");
       pea       @monitor_5.L
       jsr       (A3)
       addq.w    #4,A7
; if (!*startBasic)
       move.l    _startBasic.L,A0
       tst.w     (A0)
       bne.s     main_36
; {
; printText("OK\r\n\0");
       pea       @monitor_6.L
       jsr       (A3)
       addq.w    #4,A7
; printText(">");
       pea       @monitor_7.L
       jsr       (A3)
       addq.w    #4,A7
main_36:
; }
; showCursor();
       jsr       _showCursor
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; *vbuf = '\0';
       move.l    (A4),A0
       clr.b     (A0)
; #if defined(__KEYPS2__) || defined(__KEYPS2_EXT__)
; *kbdvprim = 1;
       move.l    _kbdvprim.L,A0
       move.b    #1,(A0)
; *kbdvshift = 0;
       move.l    _kbdvshift.L,A0
       clr.b     (A0)
; *kbdvctrl = 0;
       move.l    _kbdvctrl.L,A0
       clr.b     (A0)
; *kbdvalt = 0;
       move.l    _kbdvalt.L,A0
       clr.b     (A0)
; *kbdvcaps = 0;
       move.l    _kbdvcaps.L,A0
       clr.b     (A0)
; *kbdvnum = 0;
       move.l    _kbdvnum.L,A0
       clr.b     (A0)
; *kbdvscr = 0;
       move.l    _kbdvscr.L,A0
       clr.b     (A0)
; *kbdvreleased = 0x00;
       move.l    _kbdvreleased.L,A0
       clr.b     (A0)
; *kbdve0 = 0;
       move.l    _kbdve0.L,A0
       clr.b     (A0)
; *kbdClockCount = 0;
       move.l    _kbdClockCount.L,A0
       clr.b     (A0)
; *kbdScanCodeCount = 0;
       move.l    _kbdScanCodeCount.L,A0
       clr.b     (A0)
; *kbdKeyBuffer = 0x00;
       move.l    _kbdKeyBuffer.L,A0
       clr.b     (A0)
; *scanCode = 0;
       move.l    _scanCode.L,A0
       clr.w     (A0)
; *kbdKeyPntr = 0;
       move.l    _kbdKeyPntr.L,A0
       clr.b     (A0)
; // Ativando Interrupcao de Kbd PS/2
; *(vmfp + Reg_IERA) |= 0x40; // GPI6 will be PS2 interrupt (clk pin OR DTRDY pin)
       move.l    (A2),A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       or.b      #64,0(A0,D0.L)
; *(vmfp + Reg_IMRA) |= 0x40; // GPI6 will be PS2 interrupt (clk pin OR DTRDY pin)
       move.l    (A2),A0
       move.w    _Reg_IMRA.L,D0
       and.l     #65535,D0
       or.b      #64,0(A0,D0.L)
; #endif
; while (1)
main_38:
; {
; if (*startBasic)
       move.l    _startBasic.L,A0
       tst.w     (A0)
       beq.s     main_41
; {
; runBas();
       jsr       _runBas
; *startBasic = 0;
       move.l    _startBasic.L,A0
       clr.w     (A0)
; *vbuf = 0x00;
       move.l    (A4),A0
       clr.b     (A0)
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
; printChar('>', 1);
       pea       1
       pea       62
       jsr       _printChar
       addq.w    #8,A7
main_41:
; }
; vRetInput = inputLine(128,'$');
       pea       36
       pea       128
       jsr       _inputLine
       addq.w    #8,A7
       move.b    D0,D6
; if (*vbuf != 0x00 && (vRetInput == 0x0D || vRetInput == 0x0A))
       move.l    (A4),A0
       move.b    (A0),D0
       beq       main_43
       cmp.b     #13,D6
       beq.s     main_45
       cmp.b     #10,D6
       bne       main_43
main_45:
; {
; vRetProcCmd = 1;
       moveq     #1,D7
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
; vRetProcCmd = processCmd();
       jsr       _processCmd
       move.l    D0,D7
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; *vbuf = '\0';
       move.l    (A4),A0
       clr.b     (A0)
; if (vRetProcCmd)
       tst.l     D7
       beq.s     main_46
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
main_46:
; printChar('>', 1);
       pea       1
       pea       62
       jsr       _printChar
       addq.w    #8,A7
       bra.s     main_48
main_43:
; }
; else if (vRetInput != 0x1B)
       cmp.b     #27,D6
       beq.s     main_48
; {
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
; printChar('>', 1);
       pea       1
       pea       62
       jsr       _printChar
       addq.w    #8,A7
main_48:
       bra       main_38
; }
; }
; }
; //-----------------------------------------------------------------------------
; // pQtdInput - Quantidade a ser digitada, min 1 max 255
; // pTipo - Tipo de entrada:
; //                  input : $ - String, % - Inteiro (sem ponto), # - Real (com ponto), @ - Sem Cursor e Qualquer Coisa e sem enter
; //                   edit : S - String, I - Inteiro (sem ponto), R - Real (com ponto)
; //-----------------------------------------------------------------------------
; unsigned char inputLine(unsigned int pQtdInput, unsigned char pTipo)
; {
       xdef      _inputLine
_inputLine:
       link      A6,#-24
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vbuf.L,A2
       move.b    15(A6),D3
       and.l     #255,D3
       lea       _videoCursorPosColX.L,A3
       lea       _printChar.L,A4
       lea       _videoCursorPosRowY.L,A5
; unsigned char *vbufptr = vbuf;
       move.l    (A2),D6
; unsigned char vtec, vtecant;
; int vRetProcCmd, iw, ix;
; int countCursor = 0;
       clr.l     -16(A6)
; char pEdit = 0, pIns = 0, vbuftemp, vbuftemp2;
       clr.b     -12(A6)
       clr.b     -11(A6)
; int iPos, iz;
; unsigned short vantX, vantY;
; if (pQtdInput == 0)
       move.l    8(A6),D0
       bne.s     inputLine_1
; pQtdInput = 512;
       move.l    #512,8(A6)
inputLine_1:
; vtecant = 0x00;
       clr.b     -21(A6)
; vbufptr = vbuf;
       move.l    (A2),D6
; // Se for Linha editavel apresenta a linha na tela
; if (pTipo == 'S' || pTipo == 'I' || pTipo == 'R')
       cmp.b     #83,D3
       beq.s     inputLine_5
       cmp.b     #73,D3
       beq.s     inputLine_5
       cmp.b     #82,D3
       bne       inputLine_3
inputLine_5:
; {
; // Apresenta a linha na tela, e posiciona o cursor na tela na primeira posicao valida
; iw = strlen(vbuf) / 40;
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,-(A7)
       pea       40
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D7
; printText(vbuf);
       move.l    (A2),-(A7)
       jsr       _printText
       addq.w    #4,A7
; *videoCursorPosRowY -= iw;
       move.l    (A5),A0
       sub.w     D7,(A0)
; *videoCursorPosColX = 0;
       move.l    (A3),A0
       clr.w     (A0)
; pEdit = 1;
       move.b    #1,-12(A6)
; iPos = 0;
       clr.l     D4
; pIns = 0xFF;
       move.b    #255,-11(A6)
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_3:
; }
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_6
; showCursor();
       jsr       _showCursor
inputLine_6:
; while (1)
inputLine_8:
; {
; // Piscar Cursor
; if (*videoCursorBlink && pTipo != '@')
       move.l    _videoCursorBlink.L,A0
       move.b    (A0),D0
       and.l     #255,D0
       beq       inputLine_11
       cmp.b     #64,D3
       beq       inputLine_11
; {
; switch (countCursor)
       move.l    -16(A6),D0
       cmp.l     #12000,D0
       beq.s     inputLine_16
       bgt       inputLine_14
       cmp.l     #6000,D0
       beq.s     inputLine_15
       bra.s     inputLine_14
inputLine_15:
; {
; case 6000:
; hideCursor();
       jsr       _hideCursor
; if (pEdit)
       tst.b     -12(A6)
       beq.s     inputLine_17
; printChar(vbuf[iPos],0);
       clr.l     -(A7)
       move.l    (A2),A0
       move.b    0(A0,D4.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
inputLine_17:
; break;
       bra.s     inputLine_14
inputLine_16:
; case 12000:
; showCursor();
       jsr       _showCursor
; countCursor = 0;
       clr.l     -16(A6)
; break;
inputLine_14:
; }
; countCursor++;
       addq.l    #1,-16(A6)
inputLine_11:
; }
; // Inicia leitura
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; readChar();
       jsr       _readChar
; vtec = *vBufReceived;
       move.l    _vBufReceived.L,A0
       move.b    (A0),D2
; if (pTipo == '@')
       cmp.b     #64,D3
       bne.s     inputLine_19
; return vtec;
       move.b    D2,D0
       bra       inputLine_21
inputLine_19:
; // Se nao for string ($ e S) ou Tudo (@), só aceita numeros
; if (pTipo != '$' && pTipo != 'S' && pTipo != '@' && vtec != '.' && vtec > 0x1F && (vtec < 0x30 || vtec > 0x39))
       cmp.b     #36,D3
       beq.s     inputLine_22
       cmp.b     #83,D3
       beq.s     inputLine_22
       cmp.b     #64,D3
       beq.s     inputLine_22
       cmp.b     #46,D2
       beq.s     inputLine_22
       cmp.b     #31,D2
       bls.s     inputLine_22
       cmp.b     #48,D2
       blo.s     inputLine_24
       cmp.b     #57,D2
       bls.s     inputLine_22
inputLine_24:
; vtec = 0;
       clr.b     D2
inputLine_22:
; // So aceita ponto de for numero real (# ou R) ou string ($ ou S) ou tudo (@)
; if (vtec == '.' && pTipo != '#' && pTipo != '$' &&  pTipo != 'R' && pTipo != 'S' && pTipo != '@')
       cmp.b     #46,D2
       bne.s     inputLine_25
       cmp.b     #35,D3
       beq.s     inputLine_25
       cmp.b     #36,D3
       beq.s     inputLine_25
       cmp.b     #82,D3
       beq.s     inputLine_25
       cmp.b     #83,D3
       beq.s     inputLine_25
       cmp.b     #64,D3
       beq.s     inputLine_25
; vtec = 0;
       clr.b     D2
inputLine_25:
; if (vtec)
       tst.b     D2
       beq       inputLine_27
; {
; // Prevenir sujeira no buffer ou repeticao
; if (vtec == vtecant)
       cmp.b     -21(A6),D2
       bne.s     inputLine_31
; {
; if (countCursor % 300 != 0)
       move.l    -16(A6),-(A7)
       pea       300
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     inputLine_31
; continue;
       bra       inputLine_28
inputLine_31:
; }
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_35
; {
; hideCursor();
       jsr       _hideCursor
; if (pEdit)
       tst.b     -12(A6)
       beq.s     inputLine_35
; printChar(vbuf[iPos],0);
       clr.l     -(A7)
       move.l    (A2),A0
       move.b    0(A0,D4.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
inputLine_35:
; }
; vtecant = vtec;
       move.b    D2,-21(A6)
; if (vtec >= 0x20 && vtec != 0x7F)   // Caracter Printavel menos o DELete
       cmp.b     #32,D2
       blo       inputLine_37
       cmp.b     #127,D2
       beq       inputLine_37
; {
; if (!pEdit)
       tst.b     -12(A6)
       bne       inputLine_39
; {
; // Digitcao Normal
; if (vbufptr > vbuf + pQtdInput)
       move.l    (A2),D0
       add.l     8(A6),D0
       cmp.l     D0,D6
       bls.s     inputLine_43
; {
; *vbufptr--;
       move.l    D6,A0
       subq.l    #1,D6
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_43
; printChar(0x08, 1);
       pea       1
       pea       8
       jsr       (A4)
       addq.w    #8,A7
inputLine_43:
; }
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_45
; printChar(vtec, 1);
       pea       1
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       (A4)
       addq.w    #8,A7
inputLine_45:
; *vbufptr++ = vtec;
       move.l    D6,A0
       addq.l    #1,D6
       move.b    D2,(A0)
; *vbufptr = '\0';
       move.l    D6,A0
       clr.b     (A0)
       bra       inputLine_58
inputLine_39:
; }
; else
; {
; iw = strlen(vbuf);
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D7
; // Edicao de Linha
; if (!pIns)
       tst.b     -11(A6)
       bne       inputLine_47
; {
; // Sem insercao de caracteres
; if (iw < pQtdInput)
       cmp.l     8(A6),D7
       bhs.s     inputLine_49
; {
; if (vbuf[iPos] == 0x00)
       move.l    (A2),A0
       move.b    0(A0,D4.L),D0
       bne.s     inputLine_51
; vbuf[iPos + 1] = 0x00;
       move.l    (A2),A0
       move.l    D4,A1
       clr.b     1(A1,A0.L)
inputLine_51:
; vbuf[iPos] = vtec;
       move.l    (A2),A0
       move.b    D2,0(A0,D4.L)
; printChar(vbuf[iPos],0);
       clr.l     -(A7)
       move.l    (A2),A0
       move.b    0(A0,D4.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
inputLine_49:
       bra       inputLine_53
inputLine_47:
; }
; }
; else
; {
; // Com insercao de caracteres
; if ((iw + 1) <= pQtdInput)
       move.l    D7,D0
       addq.l    #1,D0
       cmp.l     8(A6),D0
       bhi       inputLine_53
; {
; // Copia todos os caracteres mais 1 pro final
; vbuftemp2 = vbuf[iPos];
       move.l    (A2),A0
       move.b    0(A0,D4.L),-9(A6)
; vbuftemp = vbuf[iPos + 1];
       move.l    (A2),A0
       move.l    D4,A1
       move.b    1(A1,A0.L),-10(A6)
; vantX = *videoCursorPosColX;
       move.l    (A3),A0
       move.w    (A0),-4(A6)
; vantY = *videoCursorPosRowY;
       move.l    (A5),A0
       move.w    (A0),-2(A6)
; printChar(vtec,1);
       pea       1
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; for (ix = iPos; ix <= iw ; ix++)
       move.l    D4,D5
inputLine_55:
       cmp.l     D7,D5
       bgt       inputLine_57
; {
; vbuf[ix + 1] = vbuftemp2;
       move.l    (A2),A0
       move.l    D5,A1
       move.b    -9(A6),1(A1,A0.L)
; vbuftemp2 = vbuftemp;
       move.b    -10(A6),-9(A6)
; vbuftemp = vbuf[ix + 2];
       move.l    (A2),A0
       move.l    D5,A1
       move.b    2(A1,A0.L),-10(A6)
; printChar(vbuf[ix + 1],1);
       pea       1
       move.l    (A2),A0
       move.l    D5,A1
       move.b    1(A1,A0.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
       addq.l    #1,D5
       bra       inputLine_55
inputLine_57:
; }
; vbuf[iw + 1] = 0x00;
       move.l    (A2),A0
       move.l    D7,A1
       clr.b     1(A1,A0.L)
; vbuf[iPos] = vtec;
       move.l    (A2),A0
       move.b    D2,0(A0,D4.L)
; *videoCursorPosColX = vantX;
       move.l    (A3),A0
       move.w    -4(A6),(A0)
; *videoCursorPosRowY = vantY;
       move.l    (A5),A0
       move.w    -2(A6),(A0)
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_53:
; }
; }
; if (iw <= pQtdInput)
       cmp.l     8(A6),D7
       bhi.s     inputLine_58
; {
; iPos++;
       addq.l    #1,D4
; *videoCursorPosColX = *videoCursorPosColX + 1;
       move.l    (A3),A0
       addq.w    #1,(A0)
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_58:
       bra       inputLine_105
inputLine_37:
; }
; }
; }
; /*else if (pEdit && vtec == 0x11)    // UpArrow (17)
; {
; // TBD
; }
; else if (pEdit && vtec == 0x13)    // DownArrow (19)
; {
; // TBD
; }*/
; else if (pEdit && vtec == 0x12)    // LeftArrow (18)
       move.b    -12(A6),D0
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq       inputLine_60
       cmp.b     #18,D2
       bne       inputLine_60
; {
; if (iPos > 0)
       cmp.l     #0,D4
       ble       inputLine_62
; {
; printChar(vbuf[iPos],0);
       clr.l     -(A7)
       move.l    (A2),A0
       move.b    0(A0,D4.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; iPos--;
       subq.l    #1,D4
; if (*videoCursorPosColX == 0)
       move.l    (A3),A0
       move.w    (A0),D0
       bne.s     inputLine_64
; *videoCursorPosColX = 255;
       move.l    (A3),A0
       move.w    #255,(A0)
       bra.s     inputLine_65
inputLine_64:
; else
; *videoCursorPosColX = *videoCursorPosColX - 1;
       move.l    (A3),A0
       subq.w    #1,(A0)
inputLine_65:
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_62:
       bra       inputLine_105
inputLine_60:
; }
; }
; else if (pEdit && vtec == 0x14)    // RightArrow (20)
       move.b    -12(A6),D0
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq       inputLine_66
       cmp.b     #20,D2
       bne       inputLine_66
; {
; if (iPos < strlen(vbuf))
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     D0,D4
       bge       inputLine_68
; {
; printChar(vbuf[iPos],0);
       clr.l     -(A7)
       move.l    (A2),A0
       move.b    0(A0,D4.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; iPos++;
       addq.l    #1,D4
; *videoCursorPosColX = *videoCursorPosColX + 1;
       move.l    (A3),A0
       addq.w    #1,(A0)
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_68:
       bra       inputLine_105
inputLine_66:
; }
; }
; else if (vtec == 0x15)  // Insert
       cmp.b     #21,D2
       bne.s     inputLine_70
; {
; pIns = ~pIns;
       move.b    -11(A6),D0
       not.b     D0
       move.b    D0,-11(A6)
       bra       inputLine_105
inputLine_70:
; /*writeLongSerial("Aqui 332.666.1-[");
; itoa(pIns,sqtdtam,16);
; writeLongSerial(sqtdtam);
; writeLongSerial("]\r\n");*/
; }
; else if (vtec == 0x08 && !pEdit)  // Backspace
       cmp.b     #8,D2
       bne       inputLine_72
       tst.b     -12(A6)
       bne.s     inputLine_74
       moveq     #1,D0
       bra.s     inputLine_75
inputLine_74:
       clr.l     D0
inputLine_75:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq.s     inputLine_72
; {
; // Digitcao Normal
; if (vbufptr > vbuf)
       cmp.l     (A2),D6
       bls.s     inputLine_78
; {
; *vbufptr--;
       move.l    D6,A0
       subq.l    #1,D6
; *vbufptr = 0x00;
       move.l    D6,A0
       clr.b     (A0)
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_78
; printChar(0x08, 1);
       pea       1
       pea       8
       jsr       (A4)
       addq.w    #8,A7
inputLine_78:
       bra       inputLine_105
inputLine_72:
; }
; }
; else if ((vtec == 0x08 || vtec == 0x7F) && pEdit)  // Backspace
       cmp.b     #8,D2
       beq.s     inputLine_82
       cmp.b     #127,D2
       bne       inputLine_80
inputLine_82:
       move.b    -12(A6),D0
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq       inputLine_80
; {
; iw = strlen(vbuf);
       move.l    (A2),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D7
; if ((vtec == 0x08 && iPos > 0) || vtec == 0x7F)
       cmp.b     #8,D2
       bne.s     inputLine_86
       cmp.l     #0,D4
       bgt.s     inputLine_85
inputLine_86:
       cmp.b     #127,D2
       bne       inputLine_83
inputLine_85:
; {
; if (vtec == 0x08)
       cmp.b     #8,D2
       bne       inputLine_87
; {
; iPos--;
       subq.l    #1,D4
; if (*videoCursorPosColX == 0)
       move.l    (A3),A0
       move.w    (A0),D0
       bne.s     inputLine_89
; *videoCursorPosColX = 255;
       move.l    (A3),A0
       move.w    #255,(A0)
       bra.s     inputLine_90
inputLine_89:
; else
; *videoCursorPosColX = *videoCursorPosColX - 1;
       move.l    (A3),A0
       subq.w    #1,(A0)
inputLine_90:
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_87:
; }
; vantX = *videoCursorPosColX;
       move.l    (A3),A0
       move.w    (A0),-4(A6)
; vantY = *videoCursorPosRowY;
       move.l    (A5),A0
       move.w    (A0),-2(A6)
; for (ix = iPos; ix < iw ; ix++)
       move.l    D4,D5
inputLine_91:
       cmp.l     D7,D5
       bge.s     inputLine_93
; {
; vbuf[ix] = vbuf[ix + 1];
       move.l    (A2),A0
       move.l    D5,A1
       move.l    A0,-(A7)
       move.l    (A2),A0
       move.b    1(A1,A0.L),0(A0,D5.L)
       move.l    (A7)+,A0
; printChar(vbuf[ix],1);
       pea       1
       move.l    (A2),A0
       move.b    0(A0,D5.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
       addq.l    #1,D5
       bra       inputLine_91
inputLine_93:
; }
; vbuf[ix] = 0x00;
       move.l    (A2),A0
       clr.b     0(A0,D5.L)
; *videoCursorPosColX = vantX;
       move.l    (A3),A0
       move.w    -4(A6),(A0)
; *videoCursorPosRowY = vantY;
       move.l    (A5),A0
       move.w    -2(A6),(A0)
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A5),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_set_cursor
       addq.w    #8,A7
inputLine_83:
       bra       inputLine_105
inputLine_80:
; }
; }
; else if (vtec == 0x1B)   // ESC
       cmp.b     #27,D2
       bne       inputLine_94
; {
; // Limpa a linha, esvazia o buffer e retorna tecla
; while (vbufptr > vbuf)
inputLine_96:
       cmp.l     (A2),D6
       bls       inputLine_98
; {
; *vbufptr--;
       move.l    D6,A0
       subq.l    #1,D6
; *vbufptr = 0x00;
       move.l    D6,A0
       clr.b     (A0)
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_99
; hideCursor();
       jsr       _hideCursor
inputLine_99:
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_101
; printChar(0x08, 1);
       pea       1
       pea       8
       jsr       (A4)
       addq.w    #8,A7
inputLine_101:
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_103
; showCursor();
       jsr       _showCursor
inputLine_103:
       bra       inputLine_96
inputLine_98:
; }
; hideCursor();
       jsr       _hideCursor
; return vtec;
       move.b    D2,D0
       bra.s     inputLine_21
inputLine_94:
; }
; else if (vtec == 0x0D || vtec == 0x0A ) // CR ou LF
       cmp.b     #13,D2
       beq.s     inputLine_107
       cmp.b     #10,D2
       bne.s     inputLine_105
inputLine_107:
; {
; return vtec;
       move.b    D2,D0
       bra.s     inputLine_21
inputLine_105:
; }
; if (pTipo != '@')
       cmp.b     #64,D3
       beq.s     inputLine_108
; showCursor();
       jsr       _showCursor
inputLine_108:
       bra.s     inputLine_28
inputLine_27:
; }
; else
; {
; vtecant = 0x00;
       clr.b     -21(A6)
inputLine_28:
       bra       inputLine_8
inputLine_21:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; return 0x00;
; }
; //-----------------------------------------------------------------------------
; int processCmd(void)
; {
       xdef      _processCmd
_processCmd:
       link      A6,#-156
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -154(A6),A2
       lea       _strcmp.L,A3
       lea       -122(A6),A4
       lea       -70(A6),A5
; unsigned char linhacomando[32], linhaarg[32], vloop;
; unsigned char *blin = vbuf;
       move.l    _vbuf.L,D6
; unsigned short varg = 0;
       clr.w     D4
; unsigned short ix, iy, iz, ikk, izz;
; unsigned short vbytepic = 0, vrecfim;
       clr.w     -86(A6)
; unsigned char sqtdtam[10], cuntam, vparam[32], vparam2[16], vparam3[16], vpicret, vresp;
; int vRet = 1;
       move.l    #1,-4(A6)
; // Separar linha entre comando e argumento
; linhacomando[0] = '\0';
       clr.b     (A2)
; linhaarg[0] = '\0';
       clr.b     (A4)
; ix = 0;
       clr.w     D3
; iy = 0;
       clr.w     D2
; while (*blin)
processCmd_1:
       move.l    D6,A0
       tst.b     (A0)
       beq       processCmd_3
; {
; if (!varg && *blin == 0x20)
       tst.w     D4
       bne.s     processCmd_6
       moveq     #1,D0
       bra.s     processCmd_7
processCmd_6:
       clr.l     D0
processCmd_7:
       and.l     #65535,D0
       beq.s     processCmd_4
       move.l    D6,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       bne.s     processCmd_4
; {
; varg = 0x01;
       moveq     #1,D4
; linhacomando[ix] = '\0';
       and.l     #65535,D3
       clr.b     0(A2,D3.L)
; iy = ix;
       move.w    D3,D2
; ix = 0;
       clr.w     D3
       bra       processCmd_5
processCmd_4:
; }
; else
; {
; if (!varg)
       tst.w     D4
       bne.s     processCmd_8
; linhacomando[ix] = toupper(*blin);
       move.l    D6,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       and.l     #65535,D3
       move.b    D0,0(A2,D3.L)
       bra.s     processCmd_9
processCmd_8:
; else
; linhaarg[ix] = toupper(*blin);
       move.l    D6,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       and.l     #65535,D3
       move.b    D0,0(A4,D3.L)
processCmd_9:
; ix++;
       addq.w    #1,D3
processCmd_5:
; }
; *blin++;
       move.l    D6,A0
       addq.l    #1,D6
       bra       processCmd_1
processCmd_3:
; }
; if (!varg)
       tst.w     D4
       bne.s     processCmd_10
; {
; linhacomando[ix] = '\0';
       and.l     #65535,D3
       clr.b     0(A2,D3.L)
; iy = ix;
       move.w    D3,D2
       bra       processCmd_14
processCmd_10:
; }
; else
; {
; linhaarg[ix] = '\0';
       and.l     #65535,D3
       clr.b     0(A4,D3.L)
; ikk = 0;
       clr.w     D5
; iz = 0;
       clr.w     -88(A6)
; izz = 0;
       moveq     #0,D7
; varg = 0;
       clr.w     D4
; while (ikk < ix)
processCmd_12:
       cmp.w     D3,D5
       bhs       processCmd_14
; {
; if (linhaarg[ikk] == 0x20)
       and.l     #65535,D5
       move.b    0(A4,D5.L),D0
       cmp.b     #32,D0
       bne.s     processCmd_15
; varg++;
       addq.w    #1,D4
       bra       processCmd_21
processCmd_15:
; else
; {
; if (!varg)
       tst.w     D4
       bne.s     processCmd_17
; vparam[ikk] = linhaarg[ikk];
       and.l     #65535,D5
       and.l     #65535,D5
       move.b    0(A4,D5.L),0(A5,D5.L)
       bra.s     processCmd_21
processCmd_17:
; else if (varg == 1)
       cmp.w     #1,D4
       bne.s     processCmd_19
; {
; vparam2[iz] = linhaarg[ikk];
       and.l     #65535,D5
       move.w    -88(A6),D0
       and.l     #65535,D0
       move.b    0(A4,D5.L),-38(A6,D0.L)
; iz++;
       addq.w    #1,-88(A6)
       bra.s     processCmd_21
processCmd_19:
; }
; else if (varg == 2)
       cmp.w     #2,D4
       bne.s     processCmd_21
; {
; vparam3[izz] = linhaarg[ikk];
       and.l     #65535,D5
       and.l     #65535,D7
       move.b    0(A4,D5.L),-22(A6,D7.L)
; izz++;
       addq.w    #1,D7
processCmd_21:
; }
; }
; ikk++;
       addq.w    #1,D5
       bra       processCmd_12
processCmd_14:
; }
; }
; vparam[ikk] = '\0';
       and.l     #65535,D5
       clr.b     0(A5,D5.L)
; vparam2[iz] = '\0';
       move.w    -88(A6),D0
       and.l     #65535,D0
       clr.b     -38(A6,D0.L)
; vparam3[izz] = '\0';
       and.l     #65535,D7
       clr.b     -22(A6,D7.L)
; vpicret = 0;
       clr.b     -6(A6)
; // Processar e definir o que fazer
; if (linhacomando[0] != 0)
       move.b    (A2),D0
       beq       processCmd_45
; {
; if (!strcmp(linhacomando,"CLS") && iy == 3)
       pea       @monitor_8.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_25
       cmp.w     #3,D2
       bne.s     processCmd_25
; {
; clearScr();
       jsr       _clearScr
; vRet = 0;
       clr.l     -4(A6)
       bra       processCmd_45
processCmd_25:
; }
; else if (!strcmp(linhacomando,"CLEAR") && iy == 5)
       pea       @monitor_9.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_27
       cmp.w     #5,D2
       bne.s     processCmd_27
; {
; clearScr();
       jsr       _clearScr
; vRet = 0;
       clr.l     -4(A6)
       bra       processCmd_45
processCmd_27:
; }
; else if (!strcmp(linhacomando,"VER") && iy == 3)
       pea       @monitor_10.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_29
       cmp.w     #3,D2
       bne.s     processCmd_29
; {
; printText("MMSJ-300 BIOS v"versionBios);
       pea       @monitor_1.L
       jsr       _printText
       addq.w    #4,A7
       bra       processCmd_45
processCmd_29:
; #if defined(__FS12__)
; fsVer();
; #endif
; }
; else if (!strcmp(linhacomando,"LOAD") && iy == 4)
       pea       @monitor_11.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_31
       cmp.w     #4,D2
       bne.s     processCmd_31
; {
; printText("Wait...\r\n\0");
       pea       @monitor_12.L
       jsr       _printText
       addq.w    #4,A7
; loadSerialToMem(linhaarg, 1);
       pea       1
       move.l    A4,-(A7)
       jsr       _loadSerialToMem
       addq.w    #8,A7
       bra       processCmd_45
processCmd_31:
; }
; else if (!strcmp(linhacomando,"RUN") && iy == 3)
       pea       @monitor_13.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_33
       cmp.w     #3,D2
       bne.s     processCmd_33
; {
; runMem(linhaarg);
       move.l    A4,-(A7)
       jsr       _runMem
       addq.w    #4,A7
       bra       processCmd_45
processCmd_33:
; }
; else if (!strcmp(linhacomando,"BASIC") && iy == 5)
       pea       @monitor_14.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_35
       cmp.w     #5,D2
       bne.s     processCmd_35
; {
; runBasic(linhaarg);
       move.l    A4,-(A7)
       jsr       _runBasic
       addq.w    #4,A7
       bra       processCmd_45
processCmd_35:
; }
; else if (!strcmp(linhacomando,"MODE") && iy == 4)
       pea       @monitor_15.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_37
       cmp.w     #4,D2
       bne.s     processCmd_37
; {
; modeVideo(vparam);
       move.l    A5,-(A7)
       jsr       _modeVideo
       addq.w    #4,A7
       bra       processCmd_45
processCmd_37:
; }
; else if (!strcmp(linhacomando,"POKE") && iy == 4)
       pea       @monitor_16.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_39
       cmp.w     #4,D2
       bne.s     processCmd_39
; {
; pokeMem(vparam, vparam2);
       pea       -38(A6)
       move.l    A5,-(A7)
       jsr       _pokeMem
       addq.w    #8,A7
       bra       processCmd_45
processCmd_39:
; }
; else if (!strcmp(linhacomando,"DUMP") && iy == 4)
       pea       @monitor_17.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_41
       cmp.w     #4,D2
       bne.s     processCmd_41
; {
; dumpMem(vparam, vparam2, vparam3);
       pea       -22(A6)
       pea       -38(A6)
       move.l    A5,-(A7)
       jsr       _dumpMem
       add.w     #12,A7
       bra       processCmd_45
processCmd_41:
; }
; else if (!strcmp(linhacomando,"DUMPS") && iy == 5)
       pea       @monitor_18.L
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #8,A7
       tst.l     D0
       bne.s     processCmd_43
       cmp.w     #5,D2
       bne.s     processCmd_43
; {
; dumpMem2(vparam, vparam2);
       pea       -38(A6)
       move.l    A5,-(A7)
       jsr       _dumpMem2
       addq.w    #8,A7
       bra.s     processCmd_45
processCmd_43:
; }
; else
; {
; vresp = 0;
       clr.b     -5(A6)
; #if defined(__FS12__)
; fsOsCommand(linhacomando, ix, iy, linhaarg, vparam, vparam2, vparam3, &vresp);
; #endif
; if (!vresp)
       tst.b     -5(A6)
       bne.s     processCmd_45
; printText("Unknown Command !!!\r\n\0");
       pea       @monitor_19.L
       jsr       _printText
       addq.w    #4,A7
processCmd_45:
; }
; }
; return vRet;
       move.l    -4(A6),D0
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void clearScr(void)
; {
       xdef      _clearScr
_clearScr:
       move.l    D2,-(A7)
; unsigned int i;
; // Ler Linha
; setWriteAddress(*name_table);
       move.l    _name_table.L,A0
       move.l    (A0),-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 960; i++)
       clr.l     D2
clearScr_1:
       cmp.l     #960,D2
       bhs.s     clearScr_3
; *vvdgd = 0x00;
       move.l    _vvdgd.L,A0
       clr.b     (A0)
       addq.l    #1,D2
       bra       clearScr_1
clearScr_3:
; *videoCursorPosColX = 0;
       move.l    _videoCursorPosColX.L,A0
       clr.w     (A0)
; *videoCursorPosRowY = 0;
       move.l    _videoCursorPosRowY.L,A0
       clr.w     (A0)
       move.l    (A7)+,D2
       rts
; #ifdef __MON_SERIAL_VDG__
; writeLongSerial("\r\n\r\n\0");
; writeLongSerial("\033[2J");   // Clear Screeen
; writeLongSerial("\033[H");    // Cursor to Upper left corner
; #endif
; }
; //-----------------------------------------------------------------------------
; void printChar(unsigned char pchr, unsigned char pmove)
; {
       xdef      _printChar
_printChar:
       link      A6,#0
       movem.l   A2/A3/A4/A5,-(A7)
       lea       _videoCursorPosRowY.L,A2
       lea       _videoCursorPosColX.L,A3
       lea       _vdp_write.L,A4
       lea       _vdp_set_cursor.L,A5
; switch (pchr)
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #13,D0
       beq       printChar_4
       bhi.s     printChar_8
       cmp.l     #10,D0
       beq.s     printChar_3
       bhi       printChar_1
       cmp.l     #8,D0
       beq       printChar_5
       bra       printChar_1
printChar_8:
       cmp.l     #255,D0
       beq       printChar_6
       bra       printChar_1
printChar_3:
; {
; case 0x0A:  // LF
; *videoCursorPosRowY = *videoCursorPosRowY + 1;
       move.l    (A2),A0
       addq.w    #1,(A0)
; if (*videoCursorPosRowY == 24)
       move.l    (A2),A0
       move.w    (A0),D0
       cmp.w     #24,D0
       bne.s     printChar_9
; {
; *videoCursorPosRowY = 23;
       move.l    (A2),A0
       move.w    #23,(A0)
; geraScroll();
       jsr       _geraScroll
printChar_9:
; }
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; break;
       bra       printChar_17
printChar_4:
; case 0x0D:  // CR
; *videoCursorPosColX = 0;
       move.l    (A3),A0
       clr.w     (A0)
; vdp_set_cursor(0, *videoCursorPosRowY);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       jsr       (A5)
       addq.w    #8,A7
; break;
       bra       printChar_17
printChar_5:
; case 0x08:  // BackSpace
; if (*videoCursorPosColX > 0)
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #0,D0
       bls.s     printChar_11
; {
; *videoCursorPosColX = *videoCursorPosColX - 1;
       move.l    (A3),A0
       subq.w    #1,(A0)
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A5)
       addq.w    #8,A7
printChar_11:
; }
; break;
       bra       printChar_17
printChar_6:
; case 0xFF:  // Cursor
; if (*videoCursorShow)
       move.l    _videoCursorShow.L,A0
       tst.b     (A0)
       beq.s     printChar_13
; vdp_write(0xFE);
       pea       254
       jsr       (A4)
       addq.w    #4,A7
       bra.s     printChar_14
printChar_13:
; else
; vdp_write(0x20);
       pea       32
       jsr       (A4)
       addq.w    #4,A7
printChar_14:
; break;
       bra       printChar_17
printChar_1:
; default:
; vdp_write(pchr);
       move.b    11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #4,A7
; vdp_colorize(*fgcolor, *bgcolor);
       move.l    _bgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_colorize
       addq.w    #8,A7
; if (pmove)
       tst.b     15(A6)
       beq.s     printChar_17
; {
; vdp_set_cursor_pos(VDP_CSR_RIGHT);
       pea       3
       jsr       _vdp_set_cursor_pos
       addq.w    #4,A7
; if (*vdp_mode == VDP_MODE_TEXT && *videoCursorPosRowY == 24)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne.s     printChar_17
       move.l    (A2),A0
       move.w    (A0),D0
       cmp.w     #24,D0
       bne.s     printChar_17
; {
; *videoCursorPosRowY = 23;
       move.l    (A2),A0
       move.w    #23,(A0)
; geraScroll();
       jsr       _geraScroll
printChar_17:
       movem.l   (A7)+,A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; }
; #ifdef __MON_SERIAL_VDG__
; writeSerial(pchr);
; #endif
; }
; //-----------------------------------------------------------------------------
; void printText(unsigned char *msg)
; {
       xdef      _printText
_printText:
       link      A6,#0
; while (*msg)
printText_1:
       move.l    8(A6),A0
       tst.b     (A0)
       beq.s     printText_3
; {
; printChar(*msg++, 1);
       pea       1
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _printChar
       addq.w    #8,A7
       bra       printText_1
printText_3:
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void readChar(void)
; {
       xdef      _readChar
_readChar:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _kbdKeyBuffer.L,A2
; #if defined(__KEYPS2__) || defined(__KEYPS2_EXT__)
; unsigned char ix = 0, vmove;
       clr.b     D2
; if (*kbdKeyPntr > 0)
       move.l    _kbdKeyPntr.L,A0
       move.b    (A0),D0
       cmp.b     #0,D0
       bls       readChar_1
; {
; // Desabilita KBD and VDP Interruption
; *(vmfp + Reg_IERA) &= 0x3E;
       move.l    _vmfp.L,A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       and.b     #62,0(A0,D0.L)
; // Pega proxima tecla disponivel
; *vBufReceived = *kbdKeyBuffer;
       move.l    (A2),A0
       move.l    _vBufReceived.L,A1
       move.b    (A0),(A1)
; // Move pilha pra proxima tecla pra primeira a ser lida
; ix = 0;
       clr.b     D2
; while (ix <= 15) {
readChar_3:
       cmp.b     #15,D2
       bhi.s     readChar_5
; vmove = *(kbdKeyBuffer + ix + 1);
       move.l    (A2),A0
       and.l     #255,D2
       add.l     D2,A0
       move.b    1(A0),-1(A6)
; *(kbdKeyBuffer + ix) = vmove;
       move.l    (A2),A0
       and.l     #255,D2
       move.b    -1(A6),0(A0,D2.L)
; ix++;
       addq.b    #1,D2
       bra       readChar_3
readChar_5:
; }
; // Diminui contador do buffer
; *kbdKeyPntr = *kbdKeyPntr - 1;
       move.l    _kbdKeyPntr.L,A0
       subq.b    #1,(A0)
; // Habilita KBD and VDP Interruption
; *(vmfp + Reg_IERA) |= 0xC0;
       move.l    _vmfp.L,A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       or.b      #192,0(A0,D0.L)
readChar_1:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; #endif
; #ifdef __MON_SERIAL_KBD__
; if ((*(vmfp + Reg_RSR) & 0x80))  // Se buffer de recepcao cheio
; {
; *vBufReceived = *(vmfp + Reg_UDR);
; }
; #endif
; #ifdef __KEYKBD__
; // TBD
; #endif
; }
; //-----------------------------------------------------------------------------
; // VDP Functions
; //-----------------------------------------------------------------------------
; void setRegister(unsigned char registerIndex, unsigned char value)
; {
       xdef      _setRegister
_setRegister:
       link      A6,#0
; *vvdgc = value;
       move.l    _vvdgc.L,A0
       move.b    15(A6),(A0)
; *vvdgc = (0x80 | registerIndex);
       move.w    #128,D0
       move.b    11(A6),D1
       and.w     #255,D1
       or.w      D1,D0
       move.l    _vvdgc.L,A0
       move.b    D0,(A0)
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; unsigned char read_status_reg(void)
; {
       xdef      _read_status_reg
_read_status_reg:
       link      A6,#-4
; unsigned char memByte;
; memByte = *vvdgc;
       move.l    _vvdgc.L,A0
       move.b    (A0),-1(A6)
; return memByte;
       move.b    -1(A6),D0
       unlk      A6
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
; int vdp_init(unsigned char mode, unsigned char color, unsigned char big_sprites, unsigned char magnify)
; {
       xdef      _vdp_init
_vdp_init:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4/A5,-(A7)
       lea       _setRegister.L,A2
       lea       _name_table.L,A3
       lea       _pattern_table.L,A4
       lea       _vvdgd.L,A5
       move.b    19(A6),D5
       and.l     #255,D5
       move.b    23(A6),D6
       and.w     #255,D6
; unsigned int i, j;
; unsigned char *tempFontes = videoFontes;
       move.l    _videoFontes.L,D3
; *vdp_mode = mode;
       move.l    _vdp_mode.L,A0
       move.b    11(A6),(A0)
; *sprite_size_sel = big_sprites;
       move.l    _sprite_size_sel.L,A0
       move.b    D5,(A0)
; // Clear Ram
; setWriteAddress(0x0);
       clr.l     -(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 0x3FFF; i++)
       clr.l     D2
vdp_init_1:
       cmp.l     #16383,D2
       bhs.s     vdp_init_3
; *vvdgd = 0;
       move.l    (A5),A0
       clr.b     (A0)
       addq.l    #1,D2
       bra       vdp_init_1
vdp_init_3:
; switch (mode)
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       vdp_init_4
       asl.l     #1,D0
       move.w    vdp_init_6(PC,D0.L),D0
       jmp       vdp_init_6(PC,D0.W)
vdp_init_6:
       dc.w      vdp_init_7-vdp_init_6
       dc.w      vdp_init_8-vdp_init_6
       dc.w      vdp_init_9-vdp_init_6
       dc.w      vdp_init_10-vdp_init_6
vdp_init_7:
; {
; case VDP_MODE_G1:
; setRegister(0, 0x00);
       clr.l     -(A7)
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #8,A7
; setRegister(1, 0xC0 | (big_sprites << 1) | magnify); // Ram size 16k, activate video output
       move.w    #192,D1
       move.l    D0,-(A7)
       move.b    D5,D0
       lsl.b     #1,D0
       and.w     #255,D0
       or.w      D0,D1
       move.l    (A7)+,D0
       and.w     #255,D6
       or.w      D6,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       1
       jsr       (A2)
       addq.w    #8,A7
; setRegister(2, 0x05); // Name table at 0x1400
       pea       5
       pea       2
       jsr       (A2)
       addq.w    #8,A7
; setRegister(3, 0x80); // Color, start at 0x2000
       pea       128
       pea       3
       jsr       (A2)
       addq.w    #8,A7
; setRegister(4, 0x01); // Pattern generator start at 0x800
       pea       1
       pea       4
       jsr       (A2)
       addq.w    #8,A7
; setRegister(5, 0x20); // Sprite attriutes start at 0x1000
       pea       32
       pea       5
       jsr       (A2)
       addq.w    #8,A7
; setRegister(6, 0x00); // Sprite pattern table at 0x000
       clr.l     -(A7)
       pea       6
       jsr       (A2)
       addq.w    #8,A7
; *sprite_pattern_table = 0;
       move.l    _sprite_pattern_table.L,A0
       clr.b     (A0)
; *pattern_table = 0x800;
       move.l    (A4),A0
       move.l    #2048,(A0)
; *sprite_attribute_table = 0x1000;
       move.l    _sprite_attribute_table.L,A0
       move.l    #4096,(A0)
; *name_table = 0x1400;
       move.l    (A3),A0
       move.l    #5120,(A0)
; *color_table = 0x2000;
       move.l    _color_table.L,A0
       move.l    #8192,(A0)
; *color_table_size = 32;
       move.l    _color_table_size.L,A0
       move.b    #32,(A0)
; // Initialize pattern table with ASCII patterns
; setWriteAddress(*pattern_table + 0x100);
       move.l    (A4),A0
       move.l    (A0),D1
       add.l     #256,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 1784; i++)  // era 768
       clr.l     D2
vdp_init_12:
       cmp.l     #1784,D2
       bhs.s     vdp_init_14
; {
; tempFontes = *videoFontes + i;
       move.l    _videoFontes.L,A0
       move.l    (A0),D0
       add.l     D2,D0
       move.l    D0,D3
; *vvdgd = *tempFontes;
       move.l    D3,A0
       move.l    (A5),A1
       move.b    (A0),(A1)
       addq.l    #1,D2
       bra       vdp_init_12
vdp_init_14:
; }
; break;
       bra       vdp_init_5
vdp_init_8:
; case VDP_MODE_G2:
; setRegister(0, 0x02);
       pea       2
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #8,A7
; setRegister(1, 0xC0 | (big_sprites << 1) | magnify); // Ram size 16k, Disable Int, 16x16 Sprites, mag off, activate video output
       move.w    #192,D1
       move.l    D0,-(A7)
       move.b    D5,D0
       lsl.b     #1,D0
       and.w     #255,D0
       or.w      D0,D1
       move.l    (A7)+,D0
       and.w     #255,D6
       or.w      D6,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       1
       jsr       (A2)
       addq.w    #8,A7
; setRegister(2, 0x0E); // Name table at 0x3800
       pea       14
       pea       2
       jsr       (A2)
       addq.w    #8,A7
; setRegister(3, 0xFF); // Color, start at 0x2000             // segundo manual, deve ser 7F para 0x0000 ou FF para 0x2000
       pea       255
       pea       3
       jsr       (A2)
       addq.w    #8,A7
; setRegister(4, 0x03); // Pattern generator start at 0x000   // segundo manual, deve ser 03 para 0x0000 ou 07 para 0x2000
       pea       3
       pea       4
       jsr       (A2)
       addq.w    #8,A7
; setRegister(5, 0x76); // Sprite attriutes start at 0x3800
       pea       118
       pea       5
       jsr       (A2)
       addq.w    #8,A7
; setRegister(6, 0x03); // Sprite pattern table at 0x1800
       pea       3
       pea       6
       jsr       (A2)
       addq.w    #8,A7
; *pattern_table = 0x00;
       move.l    (A4),A0
       clr.l     (A0)
; *sprite_pattern_table = 0x1800;
       move.l    _sprite_pattern_table.L,A0
       clr.b     (A0)
; *color_table = 0x2000;
       move.l    _color_table.L,A0
       move.l    #8192,(A0)
; *name_table = 0x3800;
       move.l    (A3),A0
       move.l    #14336,(A0)
; *sprite_attribute_table = 0x3B00;
       move.l    _sprite_attribute_table.L,A0
       move.l    #15104,(A0)
; *color_table_size = 0x1800;
       move.l    _color_table_size.L,A0
       clr.b     (A0)
; *vdpMaxCols = 255;
       move.l    _vdpMaxCols.L,A0
       move.b    #255,(A0)
; *vdpMaxRows = 191;
       move.l    _vdpMaxRows.L,A0
       move.b    #191,(A0)
; setWriteAddress(*name_table);
       move.l    (A3),A0
       move.l    (A0),-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 768; i++)  // era 768
       clr.l     D2
vdp_init_15:
       cmp.l     #768,D2
       bhs.s     vdp_init_17
; *vvdgd = (unsigned char)(i & 0xFF);
       move.l    D2,D0
       and.l     #255,D0
       move.l    (A5),A0
       move.b    D0,(A0)
       addq.l    #1,D2
       bra       vdp_init_15
vdp_init_17:
; break;
       bra       vdp_init_5
vdp_init_9:
; case VDP_MODE_MULTICOLOR:
; setRegister(0, 0x00);
       clr.l     -(A7)
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #8,A7
; setRegister(1, 0xC8 | (big_sprites << 1) | magnify); // Ram size 16k, Multicolor
       move.w    #200,D1
       move.l    D0,-(A7)
       move.b    D5,D0
       lsl.b     #1,D0
       and.w     #255,D0
       or.w      D0,D1
       move.l    (A7)+,D0
       and.w     #255,D6
       or.w      D6,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       1
       jsr       (A2)
       addq.w    #8,A7
; setRegister(2, 0x05); // Name table at 0x1400
       pea       5
       pea       2
       jsr       (A2)
       addq.w    #8,A7
; // setRegister(3, 0xFF); // Color table not available
; setRegister(4, 0x01); // Pattern table start at 0x800
       pea       1
       pea       4
       jsr       (A2)
       addq.w    #8,A7
; setRegister(5, 0x76); // Sprite Attribute table at 0x1000
       pea       118
       pea       5
       jsr       (A2)
       addq.w    #8,A7
; setRegister(6, 0x03); // Sprites Pattern Table at 0x0
       pea       3
       pea       6
       jsr       (A2)
       addq.w    #8,A7
; *pattern_table = 0x800;
       move.l    (A4),A0
       move.l    #2048,(A0)
; *name_table = 0x1400;
       move.l    (A3),A0
       move.l    #5120,(A0)
; *vdpMaxCols = 63;
       move.l    _vdpMaxCols.L,A0
       move.b    #63,(A0)
; *vdpMaxRows = 47;
       move.l    _vdpMaxRows.L,A0
       move.b    #47,(A0)
; setWriteAddress(*name_table); // Init name table
       move.l    (A3),A0
       move.l    (A0),-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (j = 0; j < 24; j++)
       clr.l     D4
vdp_init_18:
       cmp.l     #24,D4
       bhs       vdp_init_20
; for (i = 0; i < 32; i++)
       clr.l     D2
vdp_init_21:
       cmp.l     #32,D2
       bhs       vdp_init_23
; *vvdgd = (i + 32 * (j / 4));
       move.l    D2,D0
       move.l    D4,-(A7)
       pea       4
       jsr       ULDIV
       move.l    (A7),D1
       addq.w    #8,A7
       move.l    D1,-(A7)
       pea       32
       jsr       ULMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.l    (A5),A0
       move.b    D0,(A0)
       addq.l    #1,D2
       bra       vdp_init_21
vdp_init_23:
       addq.l    #1,D4
       bra       vdp_init_18
vdp_init_20:
; break;
       bra       vdp_init_5
vdp_init_10:
; case VDP_MODE_TEXT:
; setRegister(0, 0x00);
       clr.l     -(A7)
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #8,A7
; setRegister(1, 0xD2); // Ram size 16k, Disable Int
       pea       210
       pea       1
       jsr       (A2)
       addq.w    #8,A7
; setRegister(2, 0x02); // Name table at 0x800
       pea       2
       pea       2
       jsr       (A2)
       addq.w    #8,A7
; setRegister(4, 0x00); // Pattern table start at 0x0
       clr.l     -(A7)
       pea       4
       jsr       (A2)
       addq.w    #8,A7
; *pattern_table = 0x00;
       move.l    (A4),A0
       clr.l     (A0)
; *name_table = 0x800;
       move.l    (A3),A0
       move.l    #2048,(A0)
; *vdpMaxCols = 39;
       move.l    _vdpMaxCols.L,A0
       move.b    #39,(A0)
; *vdpMaxRows = 23;
       move.l    _vdpMaxRows.L,A0
       move.b    #23,(A0)
; setWriteAddress(*pattern_table + 0x100);
       move.l    (A4),A0
       move.l    (A0),D1
       add.l     #256,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 1784; i++)  // era 768
       clr.l     D2
vdp_init_24:
       cmp.l     #1784,D2
       bhs.s     vdp_init_26
; {
; tempFontes = *videoFontes + i;
       move.l    _videoFontes.L,A0
       move.l    (A0),D0
       add.l     D2,D0
       move.l    D0,D3
; *vvdgd = *tempFontes;
       move.l    D3,A0
       move.l    (A5),A1
       move.b    (A0),(A1)
       addq.l    #1,D2
       bra       vdp_init_24
vdp_init_26:
; }
; vdp_textcolor(VDP_WHITE, VDP_BLACK);
       pea       1
       pea       15
       jsr       _vdp_textcolor
       addq.w    #8,A7
; break;
       bra.s     vdp_init_5
vdp_init_4:
; default:
; return VDP_ERROR; // Unsupported mode
       moveq     #1,D0
       bra.s     vdp_init_27
vdp_init_5:
; }
; setRegister(7, color);
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       7
       jsr       (A2)
       addq.w    #8,A7
; return VDP_OK;
       clr.l     D0
vdp_init_27:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_colorize(unsigned char fg, unsigned char bg)
; {
       xdef      _vdp_colorize
_vdp_colorize:
       link      A6,#-8
       move.l    D2,-(A7)
; unsigned int name_offset = *videoCursorPosRowY * (*vdpMaxCols + 1) + *videoCursorPosColX; // Position in name table
       move.l    _videoCursorPosRowY.L,A0
       move.w    (A0),D0
       move.l    _vdpMaxCols.L,A0
       move.b    (A0),D1
       addq.b    #1,D1
       and.w     #255,D1
       mulu.w    D1,D0
       and.l     #65535,D0
       move.l    _videoCursorPosColX.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,-8(A6)
; unsigned int color_offset = name_offset << 3;                      // Offset of pattern in pattern table
       move.l    -8(A6),D0
       lsl.l     #3,D0
       move.l    D0,-4(A6)
; unsigned int i;
; if (*vdp_mode != VDP_MODE_G2)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     vdp_colorize_1
; return;
       bra       vdp_colorize_6
vdp_colorize_1:
; setWriteAddress(*color_table + color_offset);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     -4(A6),D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 8; i++)
       clr.l     D2
vdp_colorize_4:
       cmp.l     #8,D2
       bhs.s     vdp_colorize_6
; *vvdgd = ((fg << 4) + bg);
       move.b    11(A6),D0
       lsl.b     #4,D0
       add.b     15(A6),D0
       move.l    _vvdgd.L,A0
       move.b    D0,(A0)
       addq.l    #1,D2
       bra       vdp_colorize_4
vdp_colorize_6:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_plot_hires(unsigned char x, unsigned char y, unsigned char color1, unsigned char color2 = 0)
; {
       xdef      _vdp_plot_hires
_vdp_plot_hires:
       link      A6,#-24
       movem.l   D2/D3/D4/D5/A2/A3/A4/A5,-(A7)
       lea       _vvdgd.L,A2
       lea       _setReadAddress.L,A3
       lea       _color_table.L,A4
       lea       _pattern_table.L,A5
       move.b    11(A6),D5
       and.l     #255,D5
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
       move.l    D0,-22(A6)
; posY = (int)(256 * (y / 8));
       move.b    15(A6),D0
       and.l     #65535,D0
       divu.w    #8,D0
       and.w     #255,D0
       lsl.w     #8,D0
       ext.l     D0
       move.l    D0,-18(A6)
; modY = (int)(y % 8);
       move.b    15(A6),D0
       and.l     #65535,D0
       divu.w    #8,D0
       swap      D0
       and.l     #255,D0
       move.l    D0,-14(A6)
; offset = posX + modY + posY;
       move.l    -22(A6),D0
       add.l     -14(A6),D0
       add.l     -18(A6),D0
       move.l    D0,D2
; setReadAddress(*pattern_table + offset);
       move.l    (A5),A0
       move.l    (A0),D1
       add.l     D2,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; setReadAddress(*pattern_table + offset);
       move.l    (A5),A0
       move.l    (A0),D1
       add.l     D2,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; pixel = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),D4
; setReadAddress(*color_table + offset);
       move.l    (A4),A0
       move.l    (A0),D1
       add.l     D2,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; setReadAddress(*color_table + offset);
       move.l    (A4),A0
       move.l    (A0),D1
       add.l     D2,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; color = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),D3
; if(color1 != 0x00)
       move.b    19(A6),D0
       beq.s     vdp_plot_hires_1
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
       move.b    D3,D0
       and.b     #15,D0
       move.b    19(A6),D1
       lsl.b     #4,D1
       or.b      D1,D0
       move.b    D0,D3
       bra       vdp_plot_hires_2
vdp_plot_hires_1:
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
       move.b    D3,D0
       and.w     #255,D0
       and.w     #240,D0
       move.b    23(A6),D1
       and.b     #15,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,D3
vdp_plot_hires_2:
; }
; setWriteAddress(*pattern_table + offset);
       move.l    (A5),A0
       move.l    (A0),D1
       add.l     D2,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (pixel);
       move.l    (A2),A0
       move.b    D4,(A0)
; setWriteAddress(*color_table + offset);
       move.l    (A4),A0
       move.l    (A0),D1
       add.l     D2,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (color);
       move.l    (A2),A0
       move.b    D3,(A0)
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4/A5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_plot_color(unsigned char x, unsigned char y, unsigned char color)
; {
       xdef      _vdp_plot_color
_vdp_plot_color:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4,-(A7)
       lea       _vvdgd.L,A2
       move.b    19(A6),D3
       and.l     #255,D3
       move.b    15(A6),D5
       and.l     #255,D5
       move.b    11(A6),D6
       and.l     #255,D6
       lea       _setWriteAddress.L,A3
; unsigned int addr = *pattern_table + 8 * (x / 2) + y % 8 + 256 * (y / 8);
       move.l    _pattern_table.L,A0
       move.l    (A0),D0
       move.b    D6,D1
       and.l     #65535,D1
       divu.w    #2,D1
       and.w     #255,D1
       mulu.w    #8,D1
       and.l     #255,D1
       add.l     D1,D0
       move.b    D5,D1
       and.l     #65535,D1
       divu.w    #8,D1
       swap      D1
       and.l     #255,D1
       add.l     D1,D0
       move.b    D5,D1
       and.l     #65535,D1
       divu.w    #8,D1
       and.w     #255,D1
       lsl.w     #8,D1
       ext.l     D1
       add.l     D1,D0
       move.l    D0,A4
; unsigned char dot = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),D7
; unsigned int offset = 8 * (x / 2) + y % 8 + 256 * (y / 8);
       move.b    D6,D0
       and.l     #65535,D0
       divu.w    #2,D0
       and.w     #255,D0
       mulu.w    #8,D0
       and.l     #65535,D0
       move.b    D5,D1
       and.l     #65535,D1
       divu.w    #8,D1
       swap      D1
       and.l     #255,D1
       add.l     D1,D0
       move.b    D5,D1
       and.l     #65535,D1
       divu.w    #8,D1
       and.l     #255,D1
       lsl.l     #8,D1
       add.l     D1,D0
       move.l    D0,D4
; unsigned char color_ = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),D2
; if (*vdp_mode == VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       bne       vdp_plot_color_1
; {
; setReadAddress(addr);
       move.l    A4,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; setWriteAddress(addr);
       move.l    A4,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; if (x & 1) // Odd columns
       move.b    D6,D0
       and.b     #1,D0
       beq.s     vdp_plot_color_3
; *vvdgd = ((dot & 0xF0) + (color & 0x0f));
       move.b    D7,D0
       and.w     #255,D0
       and.w     #240,D0
       move.b    D3,D1
       and.b     #15,D1
       and.w     #255,D1
       add.w     D1,D0
       move.l    (A2),A0
       move.b    D0,(A0)
       bra.s     vdp_plot_color_4
vdp_plot_color_3:
; else
; *vvdgd = ((dot & 0x0F) + (color << 4));
       move.b    D7,D0
       and.b     #15,D0
       move.b    D3,D1
       lsl.b     #4,D1
       add.b     D1,D0
       move.l    (A2),A0
       move.b    D0,(A0)
vdp_plot_color_4:
       bra       vdp_plot_color_5
vdp_plot_color_1:
; }
; else if (*vdp_mode == VDP_MODE_G2)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       bne       vdp_plot_color_5
; {
; // Draw bitmap
; setReadAddress(*color_table + offset);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     D4,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; if((x & 1) == 0) //Even
       move.b    D6,D0
       and.b     #1,D0
       bne.s     vdp_plot_color_7
; {
; color_ &= 0x0F;
       and.b     #15,D2
; color_ |= (color << 4);
       move.b    D3,D0
       lsl.b     #4,D0
       or.b      D0,D2
       bra.s     vdp_plot_color_8
vdp_plot_color_7:
; }
; else
; {
; color_ &= 0xF0;
       and.b     #240,D2
; color_ |= color & 0x0F;
       move.b    D3,D0
       and.b     #15,D0
       or.b      D0,D2
vdp_plot_color_8:
; }
; setWriteAddress(*pattern_table + offset);
       move.l    _pattern_table.L,A0
       move.l    (A0),D1
       add.l     D4,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; *vvdgd = (0xF0);
       move.l    (A2),A0
       move.b    #240,(A0)
; setWriteAddress(*color_table + offset);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     D4,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; *vvdgd = (color_);
       move.l    (A2),A0
       move.b    D2,(A0)
vdp_plot_color_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4
       unlk      A6
       rts
; // Colorize
; }
; }
; //-----------------------------------------------------------------------------
; void vdp_set_sprite_pattern(unsigned char number, const unsigned char *sprite)
; {
       xdef      _vdp_set_sprite_pattern
_vdp_set_sprite_pattern:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char i;
; if(*sprite_size_sel)
       move.l    _sprite_size_sel.L,A0
       tst.b     (A0)
       beq       vdp_set_sprite_pattern_1
; {
; setWriteAddress(*sprite_pattern_table + (32 * number));
       move.l    _sprite_pattern_table.L,A0
       move.b    (A0),D1
       move.l    D0,-(A7)
       move.b    11(A6),D0
       and.w     #255,D0
       mulu.w    #32,D0
       add.b     D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i<32; i++)
       clr.b     D2
vdp_set_sprite_pattern_3:
       cmp.b     #32,D2
       bhs.s     vdp_set_sprite_pattern_5
; {
; *vvdgd = (sprite[i]);
       move.l    12(A6),A0
       and.l     #255,D2
       move.l    _vvdgd.L,A1
       move.b    0(A0,D2.L),(A1)
       addq.b    #1,D2
       bra       vdp_set_sprite_pattern_3
vdp_set_sprite_pattern_5:
       bra       vdp_set_sprite_pattern_8
vdp_set_sprite_pattern_1:
; }
; }
; else
; {
; setWriteAddress(*sprite_pattern_table + (8 * number));
       move.l    _sprite_pattern_table.L,A0
       move.b    (A0),D1
       move.l    D0,-(A7)
       move.b    11(A6),D0
       and.w     #255,D0
       mulu.w    #8,D0
       add.b     D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i<8; i++)
       clr.b     D2
vdp_set_sprite_pattern_6:
       cmp.b     #8,D2
       bhs.s     vdp_set_sprite_pattern_8
; {
; *vvdgd = (sprite[i]);
       move.l    12(A6),A0
       and.l     #255,D2
       move.l    _vvdgd.L,A1
       move.b    0(A0,D2.L),(A1)
       addq.b    #1,D2
       bra       vdp_set_sprite_pattern_6
vdp_set_sprite_pattern_8:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; //-----------------------------------------------------------------------------
; void vdp_sprite_color(unsigned int addr, unsigned char color)
; {
       xdef      _vdp_sprite_color
_vdp_sprite_color:
       link      A6,#-4
; unsigned char ecclr;
; setReadAddress(addr + 3);
       move.l    8(A6),D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; ecclr = *vvdgd & 0x80 | (color & 0x0F);
       move.l    _vvdgd.L,A0
       move.b    (A0),D0
       and.w     #255,D0
       and.w     #128,D0
       move.b    15(A6),D1
       and.b     #15,D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,-1(A6)
; setWriteAddress(addr + 3);
       move.l    8(A6),D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (ecclr);
       move.l    _vvdgd.L,A0
       move.b    -1(A6),(A0)
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; Sprite_attributes vdp_sprite_get_attributes(unsigned int addr)
; {
       xdef      _vdp_sprite_get_attributes
_vdp_sprite_get_attributes:
       link      A6,#-4
       movem.l   A2/A3,-(A7)
       lea       -4(A6),A2
       lea       _vvdgd.L,A3
; Sprite_attributes attrs;
; setReadAddress(addr);
       move.l    12(A6),-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; attrs.y = *vvdgd;
       move.l    (A3),A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    (A0),1(A1)
; attrs.x = *vvdgd;
       move.l    (A3),A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    (A0),(A1)
; attrs.name_ptr = *vvdgd;
       move.l    (A3),A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    (A0),2(A1)
; attrs.ecclr = *vvdgd;
       move.l    (A3),A0
       move.l    A2,D0
       move.l    D0,A1
       move.b    (A0),3(A1)
; return attrs;
       move.l    A2,A0
       move.l    8(A6),A1
       move.l    (A0)+,(A1)+
       move.l    8(A6),D0
       movem.l   (A7)+,A2/A3
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; Sprite_attributes vdp_sprite_get_position(unsigned int addr)
; {
       xdef      _vdp_sprite_get_position
_vdp_sprite_get_position:
       link      A6,#-8
       movem.l   D2/A2/A3,-(A7)
       lea       _vvdgd.L,A2
       lea       -4(A6),A3
; unsigned char x;
; unsigned char eccr;
; unsigned char vdumbread;
; Sprite_attributes attrs;
; setReadAddress(addr);
       move.l    12(A6),-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; attrs.y = *vvdgd;
       move.l    (A2),A0
       move.l    A3,D0
       move.l    D0,A1
       move.b    (A0),1(A1)
; x = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),D2
; vdumbread = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),-5(A6)
; eccr = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),-6(A6)
; attrs.x = eccr & 0x80 ? x : x+32;
       move.b    -6(A6),D0
       and.w     #255,D0
       and.w     #128,D0
       beq.s     vdp_sprite_get_position_1
       move.b    D2,D0
       bra.s     vdp_sprite_get_position_2
vdp_sprite_get_position_1:
       move.b    D2,D0
       add.b     #32,D0
vdp_sprite_get_position_2:
       move.l    A3,D1
       move.l    D1,A0
       move.b    D0,(A0)
; return attrs;
       move.l    A3,A0
       move.l    8(A6),A1
       move.l    (A0)+,(A1)+
       move.l    8(A6),D0
       movem.l   (A7)+,D2/A2/A3
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; unsigned int vdp_sprite_init(unsigned char name, unsigned char priority, unsigned char color = 0)
; {
       xdef      _vdp_sprite_init
_vdp_sprite_init:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _vvdgd.L,A2
; unsigned int addr = *sprite_attribute_table + 4*priority;
       move.l    _sprite_attribute_table.L,A0
       move.l    (A0),D0
       move.b    15(A6),D1
       and.w     #255,D1
       mulu.w    #4,D1
       and.l     #255,D1
       add.l     D1,D0
       move.l    D0,D2
; setWriteAddress(addr);
       move.l    D2,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (0);
       move.l    (A2),A0
       clr.b     (A0)
; *vvdgd = (0);
       move.l    (A2),A0
       clr.b     (A0)
; if(*sprite_size_sel)
       move.l    _sprite_size_sel.L,A0
       tst.b     (A0)
       beq.s     vdp_sprite_init_1
; *vvdgd = (4*name);
       move.b    11(A6),D0
       and.w     #255,D0
       mulu.w    #4,D0
       move.l    (A2),A0
       move.b    D0,(A0)
       bra.s     vdp_sprite_init_2
vdp_sprite_init_1:
; else
; *vvdgd = (4*name);
       move.b    11(A6),D0
       and.w     #255,D0
       mulu.w    #4,D0
       move.l    (A2),A0
       move.b    D0,(A0)
vdp_sprite_init_2:
; *vvdgd = (0x80 | (color & 0xF));
       move.w    #128,D0
       move.b    19(A6),D1
       and.b     #15,D1
       and.w     #255,D1
       or.w      D1,D0
       move.l    (A2),A0
       move.b    D0,(A0)
; return addr;
       move.l    D2,D0
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; unsigned char vdp_sprite_set_position(unsigned int addr, unsigned int x, unsigned char y)
; {
       xdef      _vdp_sprite_set_position
_vdp_sprite_set_position:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/A2,-(A7)
       lea       _vvdgd.L,A2
       move.l    8(A6),D2
       move.l    12(A6),D5
; unsigned char ec, xpos;
; unsigned char color;
; if (x < 144)
       cmp.l     #144,D5
       bhs.s     vdp_sprite_set_position_1
; {
; ec = 1;
       moveq     #1,D4
; xpos = x;
       move.b    D5,D3
       bra.s     vdp_sprite_set_position_2
vdp_sprite_set_position_1:
; }
; else
; {
; ec = 0;
       clr.b     D4
; xpos = x-32;
       move.l    D5,D0
       sub.l     #32,D0
       move.b    D0,D3
vdp_sprite_set_position_2:
; }
; setReadAddress(addr + 3);
       move.l    D2,D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; color = *vvdgd & 0x0f;
       move.l    (A2),A0
       move.b    (A0),D0
       and.b     #15,D0
       move.b    D0,-1(A6)
; setWriteAddress(addr);
       move.l    D2,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (y);
       move.l    (A2),A0
       move.b    19(A6),(A0)
; *vvdgd = (xpos);
       move.l    (A2),A0
       move.b    D3,(A0)
; setWriteAddress(addr + 3);
       move.l    D2,D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = ((ec << 7) | color);
       move.b    D4,D0
       lsl.b     #7,D0
       or.b      -1(A6),D0
       move.l    (A2),A0
       move.b    D0,(A0)
; return read_status_reg();
       jsr       _read_status_reg
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_set_bdcolor(unsigned char color)
; {
       xdef      _vdp_set_bdcolor
_vdp_set_bdcolor:
       link      A6,#0
; setRegister(7, color);
       move.b    11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       7
       jsr       _setRegister
       addq.w    #8,A7
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_set_pattern_color(unsigned int index, unsigned char fg, unsigned char bg)
; {
       xdef      _vdp_set_pattern_color
_vdp_set_pattern_color:
       link      A6,#0
; if (*vdp_mode == VDP_MODE_G1)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       bne.s     vdp_set_pattern_color_1
; {
; index &= 31;
       and.l     #31,8(A6)
vdp_set_pattern_color_1:
; }
; setWriteAddress(*color_table + index);
       move.l    _color_table.L,A0
       move.l    (A0),D1
       add.l     8(A6),D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = ((fg << 4) + bg);
       move.b    15(A6),D0
       lsl.b     #4,D0
       add.b     19(A6),D0
       move.l    _vvdgd.L,A0
       move.b    D0,(A0)
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_set_cursor(unsigned char pcol, unsigned char prow)
; {
       xdef      _vdp_set_cursor
_vdp_set_cursor:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       move.b    15(A6),D2
       and.l     #255,D2
       move.b    11(A6),D3
       and.l     #255,D3
       lea       _vdpMaxRows.L,A2
; if (pcol == 255) //<0
       and.w     #255,D3
       cmp.w     #255,D3
       bne.s     vdp_set_cursor_1
; {
; pcol = *vdpMaxCols;
       move.l    _vdpMaxCols.L,A0
       move.b    (A0),D3
; prow--;
       subq.b    #1,D2
       bra.s     vdp_set_cursor_3
vdp_set_cursor_1:
; }
; else if (pcol > *vdpMaxCols)
       move.l    _vdpMaxCols.L,A0
       cmp.b     (A0),D3
       bls.s     vdp_set_cursor_3
; {
; pcol = 0;
       clr.b     D3
; prow++;
       addq.b    #1,D2
vdp_set_cursor_3:
; }
; if (prow == 255)
       and.w     #255,D2
       cmp.w     #255,D2
       bne.s     vdp_set_cursor_5
; {
; prow = *vdpMaxRows;
       move.l    (A2),A0
       move.b    (A0),D2
       bra.s     vdp_set_cursor_7
vdp_set_cursor_5:
; }
; else if (prow > *vdpMaxRows)
       move.l    (A2),A0
       cmp.b     (A0),D2
       bls.s     vdp_set_cursor_7
; {
; prow = *vdpMaxRows; //0;
       move.l    (A2),A0
       move.b    (A0),D2
; geraScroll();
       jsr       _geraScroll
vdp_set_cursor_7:
; }
; *videoCursorPosColX = pcol;
       and.w     #255,D3
       move.l    _videoCursorPosColX.L,A0
       move.w    D3,(A0)
; *videoCursorPosRowY = prow;
       and.w     #255,D2
       move.l    _videoCursorPosRowY.L,A0
       move.w    D2,(A0)
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void vdp_set_cursor_pos(unsigned char direction)
; {
       xdef      _vdp_set_cursor_pos
_vdp_set_cursor_pos:
       link      A6,#0
       movem.l   D2/A2/A3/A4,-(A7)
       lea       _videoCursorPosColX.L,A2
       lea       _videoCursorPosRowY.L,A3
       lea       _vdp_set_cursor.L,A4
; unsigned char pMoveId = 1;
       moveq     #1,D2
; if (*vdp_mode == VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       bne.s     vdp_set_cursor_pos_1
; pMoveId = 8;
       moveq     #8,D2
vdp_set_cursor_pos_1:
; switch (direction)
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       vdp_set_cursor_pos_4
       asl.l     #1,D0
       move.w    vdp_set_cursor_pos_5(PC,D0.L),D0
       jmp       vdp_set_cursor_pos_5(PC,D0.W)
vdp_set_cursor_pos_5:
       dc.w      vdp_set_cursor_pos_6-vdp_set_cursor_pos_5
       dc.w      vdp_set_cursor_pos_7-vdp_set_cursor_pos_5
       dc.w      vdp_set_cursor_pos_8-vdp_set_cursor_pos_5
       dc.w      vdp_set_cursor_pos_9-vdp_set_cursor_pos_5
vdp_set_cursor_pos_6:
; {
; case VDP_CSR_UP:
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY - pMoveId);
       move.l    (A3),A0
       move.w    (A0),D1
       and.w     #255,D2
       sub.w     D2,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; break;
       bra       vdp_set_cursor_pos_4
vdp_set_cursor_pos_7:
; case VDP_CSR_DOWN:
; vdp_set_cursor(*videoCursorPosColX, *videoCursorPosRowY + pMoveId);
       move.l    (A3),A0
       move.w    (A0),D1
       and.w     #255,D2
       add.w     D2,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; break;
       bra       vdp_set_cursor_pos_4
vdp_set_cursor_pos_8:
; case VDP_CSR_LEFT:
; vdp_set_cursor(*videoCursorPosColX - pMoveId, *videoCursorPosRowY);
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.w    (A0),D1
       and.w     #255,D2
       sub.w     D2,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; break;
       bra.s     vdp_set_cursor_pos_4
vdp_set_cursor_pos_9:
; case VDP_CSR_RIGHT:
; vdp_set_cursor(*videoCursorPosColX + pMoveId, *videoCursorPosRowY);
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.w    (A0),D1
       and.w     #255,D2
       add.w     D2,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #8,A7
; break;
vdp_set_cursor_pos_4:
       movem.l   (A7)+,D2/A2/A3/A4
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void vdp_write(unsigned char chr)
; {
       xdef      _vdp_write
_vdp_write:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _videoCursorPosColX.L,A2
       lea       _videoCursorPosRowY.L,A3
       move.b    11(A6),D7
       and.l     #255,D7
       lea       _videoFontes.L,A4
; unsigned int name_offset = *videoCursorPosRowY * (*vdpMaxCols + 1) + *videoCursorPosColX; // Position in name table
       move.l    (A3),A0
       move.w    (A0),D0
       move.l    _vdpMaxCols.L,A0
       move.b    (A0),D1
       addq.b    #1,D1
       and.w     #255,D1
       mulu.w    D1,D0
       and.l     #65535,D0
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,A5
; unsigned int pattern_offset = name_offset << 3;                    // Offset of pattern in pattern table
       move.l    A5,D0
       lsl.l     #3,D0
       move.l    D0,-8(A6)
; char i, ix;
; unsigned short vAntX, vAntY;
; unsigned char *tempFontes = videoFontes;
       move.l    (A4),D5
; unsigned long vEndFont, vEndPart;
; if (*vdp_mode == VDP_MODE_G2)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       bne       vdp_write_1
; {
; setWriteAddress(*pattern_table + pattern_offset);
       move.l    _pattern_table.L,A0
       move.l    (A0),D1
       add.l     -8(A6),D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; for (i = 0; i < 8; i++)
       clr.b     D2
vdp_write_3:
       cmp.b     #8,D2
       bge       vdp_write_5
; {
; vEndFont = *videoFontes;
       move.l    (A4),A0
       move.l    (A0),D4
; vEndPart = chr - 32;
       and.l     #255,D7
       move.l    D7,D0
       sub.l     #32,D0
       move.l    D0,D3
; vEndPart = vEndPart << 3;
       lsl.l     #3,D3
; vEndFont += vEndPart + i;
       move.l    D3,D0
       ext.w     D2
       ext.l     D2
       add.l     D2,D0
       add.l     D0,D4
; tempFontes = vEndFont;
       move.l    D4,D5
; *vvdgd = *tempFontes;
       move.l    D5,A0
       move.l    _vvdgd.L,A1
       move.b    (A0),(A1)
       addq.b    #1,D2
       bra       vdp_write_3
vdp_write_5:
       bra       vdp_write_7
vdp_write_1:
; }
; }
; else if (*vdp_mode == VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       bne       vdp_write_6
; {
; vAntY = *videoCursorPosRowY;
       move.l    (A3),A0
       move.w    (A0),-2(A6)
; for (i = 0; i < 8; i++)
       clr.b     D2
vdp_write_8:
       cmp.b     #8,D2
       bge       vdp_write_10
; {
; vEndFont = *videoFontes;
       move.l    (A4),A0
       move.l    (A0),D4
; vEndPart = chr - 32;
       and.l     #255,D7
       move.l    D7,D0
       sub.l     #32,D0
       move.l    D0,D3
; vEndPart = vEndPart << 3;
       lsl.l     #3,D3
; vEndFont += vEndPart + i;
       move.l    D3,D0
       ext.w     D2
       ext.l     D2
       add.l     D2,D0
       add.l     D0,D4
; tempFontes = vEndFont;
       move.l    D4,D5
; vAntX = *videoCursorPosColX;
       move.l    (A2),A0
       move.w    (A0),-4(A6)
; for (ix = 7; ix >=0; ix--)
       moveq     #7,D6
vdp_write_11:
       cmp.b     #0,D6
       blt       vdp_write_13
; {
; vdp_plot_color(*videoCursorPosColX, *videoCursorPosRowY, ((*tempFontes >> ix) & 0x01) ? *fgcolor : *bgcolor);
       move.l    D5,A0
       move.b    (A0),D1
       lsr.b     D6,D1
       and.b     #1,D1
       beq.s     vdp_write_14
       move.l    _fgcolor.L,A0
       move.b    (A0),D1
       bra.s     vdp_write_15
vdp_write_14:
       move.l    _bgcolor.L,A0
       move.b    (A0),D1
vdp_write_15:
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _vdp_plot_color
       add.w     #12,A7
; *videoCursorPosColX = *videoCursorPosColX + 1;
       move.l    (A2),A0
       addq.w    #1,(A0)
       subq.b    #1,D6
       bra       vdp_write_11
vdp_write_13:
; }
; *videoCursorPosColX = vAntX;
       move.l    (A2),A0
       move.w    -4(A6),(A0)
; *videoCursorPosRowY = *videoCursorPosRowY + 1;
       move.l    (A3),A0
       addq.w    #1,(A0)
       addq.b    #1,D2
       bra       vdp_write_8
vdp_write_10:
; }
; *videoCursorPosRowY = vAntY;
       move.l    (A3),A0
       move.w    -2(A6),(A0)
       bra.s     vdp_write_7
vdp_write_6:
; }
; else // G1 and text mode
; {
; setWriteAddress(*name_table + name_offset);
       move.l    _name_table.L,A0
       move.l    (A0),D1
       add.l     A5,D1
       move.l    D1,-(A7)
       jsr       _setWriteAddress
       addq.w    #4,A7
; *vvdgd = (chr);
       move.l    _vvdgd.L,A0
       move.b    D7,(A0)
vdp_write_7:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void vdp_textcolor(unsigned char fg, unsigned char bg)
; {
       xdef      _vdp_textcolor
_vdp_textcolor:
       link      A6,#0
; *fgcolor = fg;
       move.l    _fgcolor.L,A0
       move.b    11(A6),(A0)
; *bgcolor = bg;
       move.l    _bgcolor.L,A0
       move.b    15(A6),(A0)
; if (*vdp_mode == VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne.s     vdp_textcolor_1
; setRegister(7, (fg << 4) + bg);
       move.b    11(A6),D1
       lsl.b     #4,D1
       add.b     15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       7
       jsr       _setRegister
       addq.w    #8,A7
vdp_textcolor_1:
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; int vdp_init_textmode(unsigned char fg, unsigned char bg)
; {
       xdef      _vdp_init_textmode
_vdp_init_textmode:
       link      A6,#-4
; unsigned int vret;
; *fgcolor = fg;
       move.l    _fgcolor.L,A0
       move.b    11(A6),(A0)
; *bgcolor = bg;
       move.l    _bgcolor.L,A0
       move.b    15(A6),(A0)
; vret = vdp_init(VDP_MODE_TEXT, (*fgcolor<<4) | (*bgcolor & 0x0f), 0, 0);
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
       move.l    D0,-4(A6)
; return vret;
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; int vdp_init_g1(unsigned char fg, unsigned char bg)
; {
       xdef      _vdp_init_g1
_vdp_init_g1:
       link      A6,#-4
; unsigned int vret;
; *fgcolor = fg;
       move.l    _fgcolor.L,A0
       move.b    11(A6),(A0)
; *bgcolor = bg;
       move.l    _bgcolor.L,A0
       move.b    15(A6),(A0)
; vret = vdp_init(VDP_MODE_G1, (*fgcolor<<4) | (*bgcolor & 0x0f), 0, 0);
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
       clr.l     -(A7)
       jsr       _vdp_init
       add.w     #16,A7
       move.l    D0,-4(A6)
; return vret;
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; int vdp_init_g2(unsigned char big_sprites, unsigned char scale_sprites) // 1, false
; {
       xdef      _vdp_init_g2
_vdp_init_g2:
       link      A6,#-4
; unsigned int vret;
; vret = vdp_init(VDP_MODE_G2, 0x0, big_sprites, scale_sprites);
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       pea       1
       jsr       _vdp_init
       add.w     #16,A7
       move.l    D0,-4(A6)
; return vret;
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; int vdp_init_multicolor(void)
; {
       xdef      _vdp_init_multicolor
_vdp_init_multicolor:
       link      A6,#-4
; unsigned int vret;
; vret = vdp_init(VDP_MODE_MULTICOLOR, 0, 0, 0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       pea       2
       jsr       _vdp_init
       add.w     #16,A7
       move.l    D0,-4(A6)
; return vret;
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; char vdp_read_color_pixel(unsigned char x, unsigned char y)
; {
       xdef      _vdp_read_color_pixel
_vdp_read_color_pixel:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; char vRetColor = -1;
       moveq     #-1,D3
; unsigned int addr = 0;
       clr.l     D2
; if (*vdp_mode == VDP_MODE_MULTICOLOR)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       bne       vdp_read_color_pixel_4
; {
; addr = *pattern_table + 8 * (x / 2) + y % 8 + 256 * (y / 8);
       move.l    _pattern_table.L,A0
       move.l    (A0),D0
       move.b    11(A6),D1
       and.l     #65535,D1
       divu.w    #2,D1
       and.w     #255,D1
       mulu.w    #8,D1
       and.l     #255,D1
       add.l     D1,D0
       move.b    15(A6),D1
       and.l     #65535,D1
       divu.w    #8,D1
       swap      D1
       and.l     #255,D1
       add.l     D1,D0
       move.b    15(A6),D1
       and.l     #65535,D1
       divu.w    #8,D1
       and.w     #255,D1
       lsl.w     #8,D1
       ext.l     D1
       add.l     D1,D0
       move.l    D0,D2
; setReadAddress(addr);
       move.l    D2,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; setReadAddress(addr);
       move.l    D2,-(A7)
       jsr       _setReadAddress
       addq.w    #4,A7
; if (x & 1) // Odd columns
       move.b    11(A6),D0
       and.b     #1,D0
       beq.s     vdp_read_color_pixel_3
; vRetColor = (*vvdgd & 0x0f);
       move.l    _vvdgd.L,A0
       move.b    (A0),D0
       and.b     #15,D0
       move.b    D0,D3
       bra.s     vdp_read_color_pixel_4
vdp_read_color_pixel_3:
; else
; vRetColor = (*vvdgd >> 4);        
       move.l    _vvdgd.L,A0
       move.b    (A0),D0
       lsr.b     #4,D0
       move.b    D0,D3
vdp_read_color_pixel_4:
; }
; return vRetColor;
       move.b    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void geraScroll(void)
; {
       xdef      _geraScroll
_geraScroll:
       link      A6,#-44
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       _vvdgd.L,A2
       lea       _name_table.L,A3
       lea       _setWriteAddress.L,A4
       lea       _vdpMaxCols.L,A5
; unsigned int name_offset = 0; // Position in name table
       clr.l     D3
; unsigned int i, j;
; unsigned char chr[40];
; unsigned char vdumbread;
; if (*vdp_mode == VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne       geraScroll_14
; {
; for (i = 1; i < 24; i++)
       moveq     #1,D4
geraScroll_3:
       cmp.l     #24,D4
       bhs       geraScroll_5
; {
; // Ler Linha
; name_offset = (i * (*vdpMaxCols + 1)); // Position in name table
       move.l    (A5),A0
       move.b    (A0),D0
       addq.b    #1,D0
       and.l     #255,D0
       move.l    D4,-(A7)
       move.l    D0,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D3
; setWriteAddress((*name_table + name_offset));
       move.l    (A3),A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #4,A7
; vdumbread = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),-1(A6)
; for (j = 0; j < 40; j++)
       clr.l     D2
geraScroll_6:
       cmp.l     #40,D2
       bhs.s     geraScroll_8
; {
; chr[j] = *vvdgd;
       move.l    (A2),A0
       move.b    (A0),-42(A6,D2.L)
       addq.l    #1,D2
       bra       geraScroll_6
geraScroll_8:
; }
; // Escrever na linha anterior
; name_offset = ((i - 1) * (*vdpMaxCols + 1)); // Position in name table
       move.l    D4,D0
       subq.l    #1,D0
       move.l    (A5),A0
       move.b    (A0),D1
       addq.b    #1,D1
       and.l     #255,D1
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D3
; setWriteAddress((*name_table + name_offset));
       move.l    (A3),A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #4,A7
; for (j = 0; j < 40; j++)
       clr.l     D2
geraScroll_9:
       cmp.l     #40,D2
       bhs.s     geraScroll_11
; {
; *vvdgd = chr[j];
       move.l    (A2),A0
       move.b    -42(A6,D2.L),(A0)
       addq.l    #1,D2
       bra       geraScroll_9
geraScroll_11:
       addq.l    #1,D4
       bra       geraScroll_3
geraScroll_5:
; }
; }
; // Apaga Ultima Linha
; name_offset = (23 * (*vdpMaxCols + 1)); // Position in name table
       move.l    (A5),A0
       move.b    (A0),D0
       addq.b    #1,D0
       and.w     #255,D0
       mulu.w    #23,D0
       and.l     #65535,D0
       move.l    D0,D3
; setWriteAddress((*name_table + name_offset));
       move.l    (A3),A0
       move.l    (A0),D1
       add.l     D3,D1
       move.l    D1,-(A7)
       jsr       (A4)
       addq.w    #4,A7
; for (j = 0; j < 40; j++)
       clr.l     D2
geraScroll_12:
       cmp.l     #40,D2
       bhs.s     geraScroll_14
; {
; *vvdgd = 0x00;
       move.l    (A2),A0
       clr.b     (A0)
       addq.l    #1,D2
       bra       geraScroll_12
geraScroll_14:
       movem.l   (A7)+,D2/D3/D4/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; }
; //-----------------------------------------------------------------------------
; void hideCursor(void)
; {
       xdef      _hideCursor
_hideCursor:
; if (!*videoCursorShow)  // Cursor já esta escondido, nao faz nada
       move.l    _videoCursorShow.L,A0
       tst.b     (A0)
       bne.s     hideCursor_1
; return;
       bra.s     hideCursor_3
hideCursor_1:
; *videoCursorShow = 0;
       move.l    _videoCursorShow.L,A0
       clr.b     (A0)
; printChar(0xFF, 1);
       pea       1
       pea       255
       jsr       _printChar
       addq.w    #8,A7
hideCursor_3:
       rts
; }
; //-----------------------------------------------------------------------------
; void showCursor(void)
; {
       xdef      _showCursor
_showCursor:
; if (*videoCursorShow)   // Cursor já esta aparecendo, nao faz nada
       move.l    _videoCursorShow.L,A0
       tst.b     (A0)
       beq.s     showCursor_1
; return;
       bra.s     showCursor_3
showCursor_1:
; *videoCursorShow = 1;
       move.l    _videoCursorShow.L,A0
       move.b    #1,(A0)
; printChar(0xFF, 1);
       pea       1
       pea       255
       jsr       _printChar
       addq.w    #8,A7
showCursor_3:
       rts
; }
; //-----------------------------------------------------------------------------
; void modeVideo(unsigned char *pMode)
; {
       xdef      _modeVideo
_modeVideo:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _printText.L,A2
; unsigned long vMode = 0;
       clr.l     D2
; if (pMode[0] != 0x00)
       move.l    8(A6),A0
       move.b    (A0),D0
       beq       modeVideo_1
; {
; vMode = atol(pMode);
       move.l    8(A6),-(A7)
       jsr       _atol
       addq.w    #4,A7
       move.l    D0,D2
; if (vMode <= 3)
       cmp.l     #3,D2
       bhi       modeVideo_3
; {
; switch(vMode)
       move.l    D2,D0
       cmp.l     #4,D0
       bhs       modeVideo_6
       asl.l     #1,D0
       move.w    modeVideo_7(PC,D0.L),D0
       jmp       modeVideo_7(PC,D0.W)
modeVideo_7:
       dc.w      modeVideo_8-modeVideo_7
       dc.w      modeVideo_9-modeVideo_7
       dc.w      modeVideo_10-modeVideo_7
       dc.w      modeVideo_11-modeVideo_7
modeVideo_8:
; {
; case 0:
; vdp_init_textmode(VDP_WHITE, VDP_BLACK);
       pea       1
       pea       15
       jsr       _vdp_init_textmode
       addq.w    #8,A7
; break;
       bra.s     modeVideo_6
modeVideo_9:
; case 1:
; vdp_init_g1(VDP_WHITE, VDP_BLACK);
       pea       1
       pea       15
       jsr       _vdp_init_g1
       addq.w    #8,A7
; break;
       bra.s     modeVideo_6
modeVideo_10:
; case 2:
; vdp_init_g2(1, 0);
       clr.l     -(A7)
       pea       1
       jsr       _vdp_init_g2
       addq.w    #8,A7
; break;
       bra.s     modeVideo_6
modeVideo_11:
; case 3:
; vdp_init_multicolor();
       jsr       _vdp_init_multicolor
; break;
modeVideo_6:
; }
; clearScr();
       jsr       _clearScr
       bra.s     modeVideo_4
modeVideo_3:
; }
; else
; vMode = 0xFF;
       move.l    #255,D2
modeVideo_4:
       bra.s     modeVideo_2
modeVideo_1:
; }
; else
; vMode = 0xFF;
       move.l    #255,D2
modeVideo_2:
; if (vMode == 0xFF && *vdp_mode == VDP_MODE_TEXT)
       cmp.l     #255,D2
       bne       modeVideo_12
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne.s     modeVideo_12
; {
; printText("usage: mode [code]\r\n\0");
       pea       @monitor_20.L
       jsr       (A2)
       addq.w    #4,A7
; printText("   code: 0 = Text Mode 40x24\r\n\0");
       pea       @monitor_21.L
       jsr       (A2)
       addq.w    #4,A7
; printText("         1 = Graphic Text Mode 32x24\r\n\0");
       pea       @monitor_22.L
       jsr       (A2)
       addq.w    #4,A7
; printText("         2 = Graphic 256x192\r\n\0");
       pea       @monitor_23.L
       jsr       (A2)
       addq.w    #4,A7
; printText("         3 = Graphic 64x48\r\n\0");
       pea       @monitor_24.L
       jsr       (A2)
       addq.w    #4,A7
modeVideo_12:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void asctohex(unsigned char a, unsigned char *s)
; {
       xdef      _asctohex
_asctohex:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    12(A6),D3
; unsigned char c;
; c = (a >> 4) & 0x0f;
       move.b    11(A6),D0
       lsr.b     #4,D0
       and.b     #15,D0
       move.b    D0,D2
; if (c <= 9) c+= '0'; else c += 'a' - 10;
       cmp.b     #9,D2
       bhi.s     asctohex_1
       add.b     #48,D2
       bra.s     asctohex_2
asctohex_1:
       add.b     #87,D2
asctohex_2:
; *s++ = c;
       move.l    D3,A0
       addq.l    #1,D3
       move.b    D2,(A0)
; c = a & 0x0f;
       move.b    11(A6),D0
       and.b     #15,D0
       move.b    D0,D2
; if (c <= 9) c+= '0'; else c += 'a' - 10;
       cmp.b     #9,D2
       bhi.s     asctohex_3
       add.b     #48,D2
       bra.s     asctohex_4
asctohex_3:
       add.b     #87,D2
asctohex_4:
; *s++ = c;
       move.l    D3,A0
       addq.l    #1,D3
       move.b    D2,(A0)
; *s = 0;
       move.l    D3,A0
       clr.b     (A0)
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; int hex2int(char ch)
; {
       xdef      _hex2int
_hex2int:
       link      A6,#0
       move.l    D2,-(A7)
       move.b    11(A6),D2
       ext.w     D2
       ext.l     D2
; if (ch >= '0' && ch <= '9')
       cmp.b     #48,D2
       blt.s     hex2int_1
       cmp.b     #57,D2
       bgt.s     hex2int_1
; return ch - '0';
       ext.w     D2
       ext.l     D2
       move.l    D2,D0
       sub.l     #48,D0
       bra       hex2int_3
hex2int_1:
; if (ch >= 'A' && ch <= 'F')
       cmp.b     #65,D2
       blt.s     hex2int_4
       cmp.b     #70,D2
       bgt.s     hex2int_4
; return ch - 'A' + 10;
       moveq     #-55,D0
       ext.w     D2
       ext.l     D2
       add.l     D2,D0
       bra.s     hex2int_3
hex2int_4:
; if (ch >= 'a' && ch <= 'f')
       cmp.b     #97,D2
       blt.s     hex2int_6
       cmp.b     #102,D2
       bgt.s     hex2int_6
; return ch - 'a' + 10;
       moveq     #-87,D0
       ext.w     D2
       ext.l     D2
       add.l     D2,D0
       bra.s     hex2int_3
hex2int_6:
; return -1;
       moveq     #-1,D0
hex2int_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; unsigned long pow(int val, int pot)
; {
       xdef      _pow
_pow:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D2
       move.l    12(A6),D4
; int ix;
; int base = val;
       move.l    D2,D5
; if (val != 0)
       tst.l     D2
       beq       pow_9
; {
; if (pot == 0)
       tst.l     D4
       bne.s     pow_3
; val = 1;
       moveq     #1,D2
       bra       pow_9
pow_3:
; else if (pot == 1)
       cmp.l     #1,D4
       bne.s     pow_5
; val = base;
       move.l    D5,D2
       bra.s     pow_9
pow_5:
; else
; {
; for (ix = 0; ix <= pot; ix++)
       clr.l     D3
pow_7:
       cmp.l     D4,D3
       bgt.s     pow_9
; {
; if (ix >= 2)
       cmp.l     #2,D3
       blt.s     pow_10
; val *= base;
       move.l    D2,-(A7)
       move.l    D5,-(A7)
       jsr       LMUL
       move.l    (A7),D2
       addq.w    #8,A7
pow_10:
       addq.l    #1,D3
       bra       pow_7
pow_9:
; }
; }
; }
; return val;
       move.l    D2,D0
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; unsigned long hexToLong(char *pHex)
; {
       xdef      _hexToLong
_hexToLong:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
; int ix;
; unsigned char ilen = strlen(pHex) - 1;
       move.l    8(A6),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       subq.l    #1,D0
       move.b    D0,D4
; unsigned long pVal = 0;
       clr.l     D3
; for (ix = ilen; ix >= 0; ix--)
       and.l     #255,D4
       move.l    D4,D2
hexToLong_1:
       cmp.l     #0,D2
       blt       hexToLong_3
; {
; pVal += hex2int(pHex[ilen - ix]) * pow(16, ix);
       move.l    8(A6),A0
       move.b    D4,D1
       and.l     #255,D1
       sub.l     D2,D1
       move.b    0(A0,D1.L),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _hex2int
       addq.w    #4,A7
       move.l    D0,-(A7)
       move.l    D2,-(A7)
       pea       16
       jsr       _pow
       addq.w    #8,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     D0,D3
       subq.l    #1,D2
       bra       hexToLong_1
hexToLong_3:
; }
; return pVal;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void pokeMem(unsigned char *pEnder, unsigned char *pByte)
; {
       xdef      _pokeMem
_pokeMem:
       link      A6,#-8
       move.l    D2,-(A7)
; unsigned char *vEnder = hexToLong(pEnder);
       move.l    8(A6),-(A7)
       jsr       _hexToLong
       addq.w    #4,A7
       move.l    D0,-8(A6)
; unsigned long tByte = hexToLong(pByte);
       move.l    12(A6),-(A7)
       jsr       _hexToLong
       addq.w    #4,A7
       move.l    D0,-4(A6)
; unsigned char vByte = 0;
       clr.b     D2
; if (pEnder[0] != 0x00 && pByte[0] != 0x00)
       move.l    8(A6),A0
       move.b    (A0),D0
       beq.s     pokeMem_1
       move.l    12(A6),A0
       move.b    (A0),D0
       beq.s     pokeMem_1
; {
; vByte = (unsigned char)tByte;
       move.l    -4(A6),D0
       move.b    D0,D2
; *vEnder = vByte;
       move.l    -8(A6),A0
       move.b    D2,(A0)
       bra.s     pokeMem_3
pokeMem_1:
; }
; else
; {
; if (*vdp_mode == VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne.s     pokeMem_3
; printText("usage: poke <ender> <byte>\r\n\0");
       pea       @monitor_25.L
       jsr       _printText
       addq.w    #4,A7
pokeMem_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // dump <ender> [qtd (default 64)] [cols (default 8 (42cols) or 4 (32cols))]
; //-----------------------------------------------------------------------------
; void dumpMem (unsigned char *pEnder, unsigned char *pqtd, unsigned char *pCols)
; {
       xdef      _dumpMem
_dumpMem:
       link      A6,#-72
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _printText.L,A2
       lea       -60(A6),A3
       lea       -10(A6),A4
       lea       -44(A6),A5
; unsigned char ptype = 0x00;
       clr.b     -71(A6)
; unsigned char *pender = hexToLong(pEnder);
       move.l    8(A6),-(A7)
       jsr       _hexToLong
       addq.w    #4,A7
       move.l    D0,-70(A6)
; unsigned long vqtd = 64, ix;
       moveq     #64,D7
; unsigned long vcols = 8;
       moveq     #8,D4
; int iy;
; unsigned char shex[4], vchr[2];
; unsigned char pbytes[16];
; char vbuffer [sizeof(long)*8+1];
; char buffer[10];
; int i=0;
       clr.l     D3
; int j=0;
       clr.l     D5
; if (pEnder[0] == 0)
       move.l    8(A6),A0
       move.b    (A0),D0
       bne.s     dumpMem_1
; {
; if (*vdp_mode == VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne.s     dumpMem_3
; {
; printText("usage: dump <ender> [qtd] [cols]\r\n\0");
       pea       @monitor_26.L
       jsr       (A2)
       addq.w    #4,A7
; printText("    qtd: default 64\r\n\0");
       pea       @monitor_27.L
       jsr       (A2)
       addq.w    #4,A7
; printText("   cols: default 8\r\n\0");
       pea       @monitor_28.L
       jsr       (A2)
       addq.w    #4,A7
dumpMem_3:
; }
; return;
       bra       dumpMem_14
dumpMem_1:
; }
; if (*vdpMaxCols == 32)
       move.l    _vdpMaxCols.L,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       bne.s     dumpMem_6
; vcols = 4;
       moveq     #4,D4
dumpMem_6:
; if (pqtd[0] != 0x00)
       move.l    12(A6),A0
       move.b    (A0),D0
       beq.s     dumpMem_8
; vqtd = atol(pqtd);
       move.l    12(A6),-(A7)
       jsr       _atol
       addq.w    #4,A7
       move.l    D0,D7
dumpMem_8:
; if (pCols[0] != 0x00)
       move.l    16(A6),A0
       move.b    (A0),D0
       beq.s     dumpMem_10
; vcols = atol(pCols);
       move.l    16(A6),-(A7)
       jsr       _atol
       addq.w    #4,A7
       move.l    D0,D4
dumpMem_10:
; for (ix = 0; ix < vqtd; ix += vcols)
       clr.l     D6
dumpMem_12:
       cmp.l     D7,D6
       bhs       dumpMem_14
; {
; ltoa (pender,vbuffer,16);
       pea       16
       move.l    A5,-(A7)
       move.l    -70(A6),-(A7)
       jsr       _ltoa
       add.w     #12,A7
; for (i=0; i<(6-strlen(vbuffer));i++) {
       clr.l     D3
dumpMem_15:
       moveq     #6,D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       move.l    A5,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       sub.l     D1,D0
       cmp.l     D0,D3
       bge.s     dumpMem_17
; buffer[i]='0';
       move.b    #48,0(A4,D3.L)
       addq.l    #1,D3
       bra       dumpMem_15
dumpMem_17:
; }
; for(j=0;j<strlen(vbuffer);j++){
       clr.l     D5
dumpMem_18:
       move.l    A5,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     D0,D5
       bge.s     dumpMem_20
; buffer[i] = vbuffer[j];
       move.b    0(A5,D5.L),0(A4,D3.L)
; i++;
       addq.l    #1,D3
; buffer[i] = 0x00;
       clr.b     0(A4,D3.L)
       addq.l    #1,D5
       bra       dumpMem_18
dumpMem_20:
; }
; printText(buffer);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printChar(':', 1);
       pea       1
       pea       58
       jsr       _printChar
       addq.w    #8,A7
; for (iy = 0; iy < vcols; iy++)
       clr.l     D2
dumpMem_21:
       cmp.l     D4,D2
       bhs.s     dumpMem_23
; pbytes[iy] = *pender++;
       move.l    -70(A6),A0
       addq.l    #1,-70(A6)
       move.b    (A0),0(A3,D2.L)
       addq.l    #1,D2
       bra       dumpMem_21
dumpMem_23:
; for (iy = 0; iy < vcols; iy++)
       clr.l     D2
dumpMem_24:
       cmp.l     D4,D2
       bhs       dumpMem_26
; {
; asctohex(pbytes[iy], shex);
       pea       -66(A6)
       move.b    0(A3,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _asctohex
       addq.w    #8,A7
; printText(shex);
       pea       -66(A6)
       jsr       (A2)
       addq.w    #4,A7
; if ((vcols - iy) >= 2)
       move.l    D4,D0
       sub.l     D2,D0
       cmp.l     #2,D0
       blo.s     dumpMem_27
; printChar(' ', 1);
       pea       1
       pea       32
       jsr       _printChar
       addq.w    #8,A7
dumpMem_27:
       addq.l    #1,D2
       bra       dumpMem_24
dumpMem_26:
; }
; printText("|\0");
       pea       @monitor_29.L
       jsr       (A2)
       addq.w    #4,A7
; for (iy = 0; iy < vcols; iy++)
       clr.l     D2
dumpMem_29:
       cmp.l     D4,D2
       bhs.s     dumpMem_31
; {
; if (pbytes[iy] >= 0x20)
       move.b    0(A3,D2.L),D0
       cmp.b     #32,D0
       blo.s     dumpMem_32
; {
; vchr[0] = pbytes[iy];
       move.b    0(A3,D2.L),-62+0(A6)
; vchr[1] = 0x00;
       clr.b     -62+1(A6)
; printText(vchr);
       pea       -62(A6)
       jsr       (A2)
       addq.w    #4,A7
       bra.s     dumpMem_33
dumpMem_32:
; }
; else
; printChar('.', 1);
       pea       1
       pea       46
       jsr       _printChar
       addq.w    #8,A7
dumpMem_33:
       addq.l    #1,D2
       bra       dumpMem_29
dumpMem_31:
; }
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
       add.l     D4,D6
       bra       dumpMem_12
dumpMem_14:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // dumps <ender> [qtd (default 256)]
; // Joga direto pra serial
; //-----------------------------------------------------------------------------
; void dumpMem2 (unsigned char *pEnder, unsigned char *pqtd)
; {
       xdef      _dumpMem2
_dumpMem2:
       link      A6,#-68
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _writeLongSerial.L,A2
       lea       -60(A6),A3
       lea       -10(A6),A4
       lea       -44(A6),A5
; unsigned char ptype = 0x00;
       clr.b     -65(A6)
; unsigned char *pender = hexToLong(pEnder);;
       move.l    8(A6),-(A7)
       jsr       _hexToLong
       addq.w    #4,A7
       move.l    D0,D5
; unsigned long vqtd = 256, ix;
       move.l    #256,D7
; int iy;
; unsigned char shex[4];
; unsigned char pbytes[16];
; char vbuffer [sizeof(long)*8+1];
; char buffer[10];
; int i=0;
       clr.l     D3
; int j=0;
       clr.l     D4
; if (pEnder[0] == 0)
       move.l    8(A6),A0
       move.b    (A0),D0
       bne.s     dumpMem2_1
; {
; if (*vdp_mode == VDP_MODE_TEXT)
       move.l    _vdp_mode.L,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       bne.s     dumpMem2_3
; writeLongSerial("usage: dump <ender initial> [qtd (default 256)]\r\n\0");
       pea       @monitor_30.L
       jsr       (A2)
       addq.w    #4,A7
dumpMem2_3:
; return;
       bra       dumpMem2_10
dumpMem2_1:
; }
; if (pqtd[0] != 0x00)
       move.l    12(A6),A0
       move.b    (A0),D0
       beq.s     dumpMem2_6
; vqtd = atol(pqtd);
       move.l    12(A6),-(A7)
       jsr       _atol
       addq.w    #4,A7
       move.l    D0,D7
dumpMem2_6:
; for (ix = 0; ix < vqtd; ix += 16)
       clr.l     D6
dumpMem2_8:
       cmp.l     D7,D6
       bhs       dumpMem2_10
; {
; ltoa (pender,vbuffer,16);
       pea       16
       move.l    A5,-(A7)
       move.l    D5,-(A7)
       jsr       _ltoa
       add.w     #12,A7
; for (i=0; i<(6-strlen(vbuffer));i++) {
       clr.l     D3
dumpMem2_11:
       moveq     #6,D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       move.l    A5,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       sub.l     D1,D0
       cmp.l     D0,D3
       bge.s     dumpMem2_13
; buffer[i]='0';
       move.b    #48,0(A4,D3.L)
       addq.l    #1,D3
       bra       dumpMem2_11
dumpMem2_13:
; }
; for(j=0;j<strlen(vbuffer);j++){
       clr.l     D4
dumpMem2_14:
       move.l    A5,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     D0,D4
       bge.s     dumpMem2_16
; buffer[i] = vbuffer[j];
       move.b    0(A5,D4.L),0(A4,D3.L)
; i++;
       addq.l    #1,D3
; buffer[i] = 0x00;
       clr.b     0(A4,D3.L)
       addq.l    #1,D4
       bra       dumpMem2_14
dumpMem2_16:
; }
; writeLongSerial(buffer);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; writeLongSerial("h : ");
       pea       @monitor_31.L
       jsr       (A2)
       addq.w    #4,A7
; for (iy = 0; iy < 16; iy++)
       clr.l     D2
dumpMem2_17:
       cmp.l     #16,D2
       bge.s     dumpMem2_19
; {
; pbytes[iy] = *pender;
       move.l    D5,A0
       move.b    (A0),0(A3,D2.L)
; pender = pender + vdpAddCol;
       add.l     #256,D5
       addq.l    #1,D2
       bra       dumpMem2_17
dumpMem2_19:
; }
; for (iy = 0; iy < 16; iy++)
       clr.l     D2
dumpMem2_20:
       cmp.l     #16,D2
       bge.s     dumpMem2_22
; {
; asctohex(pbytes[iy], shex);
       pea       -64(A6)
       move.b    0(A3,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _asctohex
       addq.w    #8,A7
; writeLongSerial(shex);
       pea       -64(A6)
       jsr       (A2)
       addq.w    #4,A7
; writeSerial(' ');
       pea       32
       jsr       _writeSerial
       addq.w    #4,A7
       addq.l    #1,D2
       bra       dumpMem2_20
dumpMem2_22:
; }
; writeLongSerial(" | \0");
       pea       @monitor_32.L
       jsr       (A2)
       addq.w    #4,A7
; for (iy = 0; iy < 16; iy++)
       clr.l     D2
dumpMem2_23:
       cmp.l     #16,D2
       bge.s     dumpMem2_25
; {
; if (pbytes[iy] >= 0x20)
       move.b    0(A3,D2.L),D0
       cmp.b     #32,D0
       blo.s     dumpMem2_26
; writeSerial(pbytes[iy]);
       move.b    0(A3,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _writeSerial
       addq.w    #4,A7
       bra.s     dumpMem2_27
dumpMem2_26:
; else
; writeSerial('.');
       pea       46
       jsr       _writeSerial
       addq.w    #4,A7
dumpMem2_27:
       addq.l    #1,D2
       bra       dumpMem2_23
dumpMem2_25:
; }
; writeLongSerial("\r\n\0");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
       add.l     #16,D6
       bra       dumpMem2_8
dumpMem2_10:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void writeSerial(unsigned char pchr)
; {
       xdef      _writeSerial
_writeSerial:
       link      A6,#0
; while(!(*(vmfp + Reg_TSR) & 0x80));  // Aguarda buffer de transmissao estar vazio
writeSerial_1:
       move.l    _vmfp.L,A0
       move.w    _Reg_TSR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.w     #255,D0
       and.w     #128,D0
       bne.s     writeSerial_3
       bra       writeSerial_1
writeSerial_3:
; *(vmfp + Reg_UDR) = pchr;
       move.l    _vmfp.L,A0
       move.w    _Reg_UDR.L,D0
       and.l     #65535,D0
       move.b    11(A6),0(A0,D0.L)
; *vBufXmitEmpty = 0;     // Indica que o buffer de transmissao esta cheio
       move.l    _vBufXmitEmpty.L,A0
       clr.b     (A0)
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void writeLongSerial(unsigned char *msg)
; {
       xdef      _writeLongSerial
_writeLongSerial:
       link      A6,#0
; while (*msg)
writeLongSerial_1:
       move.l    8(A6),A0
       tst.b     (A0)
       beq.s     writeLongSerial_3
; {
; writeSerial(*msg++);
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _writeSerial
       addq.w    #4,A7
       bra       writeLongSerial_1
writeLongSerial_3:
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; // load <ender initial to save>
; //-----------------------------------------------------------------------------
; //         Uses XMODEM Protocol
; //-----------------------------------------------------------------------------
; // ptipo : 1 = mostra mensagens 0 = nao mostra e apenas retorna os erros ou 0x00 carregado com sucesso
; //-----------------------------------------------------------------------------
; unsigned char loadSerialToMem(unsigned char *pEnder, unsigned char ptipo)
; {
       xdef      _loadSerialToMem
_loadSerialToMem:
       link      A6,#-44
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _vmfp.L,A2
       lea       _printText.L,A3
       lea       _Reg_GPDR.L,A4
       move.b    15(A6),D5
       and.l     #255,D5
       lea       _vdp_write.L,A5
; unsigned long vTamanho;
; unsigned char vHeader[3];
; unsigned int vchecksum = 0;
       clr.l     -36(A6)
; unsigned char inputBuffer, verro = 0;
       clr.b     -31(A6)
; unsigned char *vEndSave = hexToLong(pEnder);
       move.l    8(A6),-(A7)
       jsr       _hexToLong
       addq.w    #4,A7
       move.l    D0,D6
; unsigned char *vEndOld  = hexToLong(pEnder);
       move.l    8(A6),-(A7)
       jsr       _hexToLong
       addq.w    #4,A7
       move.l    D0,-30(A6)
; unsigned long vTimeout = 0, vchecksumcalc = 0;
       clr.l     D4
       clr.l     -26(A6)
; unsigned char sqtdtam[20];
; unsigned char vinicio = 0x00;
       clr.b     D2
; unsigned char vStart = 0x00;
       clr.b     -2(A6)
; unsigned char vBlockOld = 0x00;
       clr.b     -1(A6)
; unsigned int vAnim = 1000;
       move.l    #1000,D7
; if (pEnder[0] == 0)
       move.l    8(A6),A0
       move.b    (A0),D0
       bne       loadSerialToMem_1
; {
; if (ptipo)
       tst.b     D5
       beq.s     loadSerialToMem_3
; {
; printText("Invalid Argument: \0");
       pea       @monitor_33.L
       jsr       (A3)
       addq.w    #4,A7
; printText(pEnder);
       move.l    8(A6),-(A7)
       jsr       (A3)
       addq.w    #4,A7
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
; printText("usage: load <ender>\r\n\0");
       pea       @monitor_34.L
       jsr       (A3)
       addq.w    #4,A7
; printText("    <ender> : ender to save >= 00800000h\r\n\0");
       pea       @monitor_35.L
       jsr       (A3)
       addq.w    #4,A7
loadSerialToMem_3:
; }
; return 0xFF;
       move.b    #255,D0
       bra       loadSerialToMem_5
loadSerialToMem_1:
; }
; if (ptipo)
       tst.b     D5
       beq.s     loadSerialToMem_6
; printText("Receiving... \0");
       pea       @monitor_36.L
       jsr       (A3)
       addq.w    #4,A7
loadSerialToMem_6:
; // Desabilita KBD and VDP Interruption
; *(vmfp + Reg_IERA) &= 0x3E;
       move.l    (A2),A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       and.b     #62,0(A0,D0.L)
; while(1)
loadSerialToMem_8:
; {
; inputBuffer = 0;
       clr.b     D3
; vTimeout = 0;
       clr.l     D4
; if (ptipo)
       tst.b     D5
       beq       loadSerialToMem_11
; {
; switch (vAnim)
       cmp.l     #2400,D7
       beq       loadSerialToMem_17
       bhi.s     loadSerialToMem_19
       cmp.l     #1600,D7
       beq.s     loadSerialToMem_16
       bhi       loadSerialToMem_14
       cmp.l     #800,D7
       beq.s     loadSerialToMem_15
       bra       loadSerialToMem_14
loadSerialToMem_19:
       cmp.l     #3200,D7
       beq.s     loadSerialToMem_18
       bra       loadSerialToMem_14
loadSerialToMem_15:
; {
; case 800:
; vdp_write(0x2F);    // Show "/"
       pea       47
       jsr       (A5)
       addq.w    #4,A7
; break;
       bra.s     loadSerialToMem_14
loadSerialToMem_16:
; case 1600:
; vdp_write(0x2D);    // Show "-"
       pea       45
       jsr       (A5)
       addq.w    #4,A7
; break;
       bra.s     loadSerialToMem_14
loadSerialToMem_17:
; case 2400:
; vdp_write(0x5C);    // Show "\"
       pea       92
       jsr       (A5)
       addq.w    #4,A7
; break;
       bra.s     loadSerialToMem_14
loadSerialToMem_18:
; case 3200:
; vdp_write(0x7C);    // Show "|"
       pea       124
       jsr       (A5)
       addq.w    #4,A7
; vAnim = 0;
       moveq     #0,D7
; break;
loadSerialToMem_14:
; }
; vAnim++;
       addq.l    #1,D7
loadSerialToMem_11:
; }
; while(!(*(vmfp + Reg_RSR) & 0x80))
loadSerialToMem_20:
       move.l    (A2),A0
       move.w    _Reg_RSR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.w     #255,D0
       and.w     #128,D0
       bne       loadSerialToMem_22
; {
; if(vinicio == 0x00 && vStart == 0x00)
       tst.b     D2
       bne       loadSerialToMem_26
       move.b    -2(A6),D0
       bne       loadSerialToMem_26
; {
; if ((vTimeout % 100000) == 0) // +/- 10s
       move.l    D4,-(A7)
       pea       100000
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     loadSerialToMem_25
; {
; *(vmfp + Reg_GPDR) = 0x01;
       move.l    (A2),A0
       move.w    (A4),D0
       and.l     #65535,D0
       move.b    #1,0(A0,D0.L)
; writeSerial(0x15);    // Send NACK to start
       pea       21
       jsr       _writeSerial
       addq.w    #4,A7
       bra.s     loadSerialToMem_26
loadSerialToMem_25:
; }
; else
; {
; *(vmfp + Reg_GPDR) = 0x01;
       move.l    (A2),A0
       move.w    (A4),D0
       and.l     #65535,D0
       move.b    #1,0(A0,D0.L)
loadSerialToMem_26:
; }
; }
; vTimeout++;
       addq.l    #1,D4
; if (vTimeout > 3000000) // +/- 5 min
       cmp.l     #3000000,D4
       bls.s     loadSerialToMem_27
; break;
       bra.s     loadSerialToMem_22
loadSerialToMem_27:
       bra       loadSerialToMem_20
loadSerialToMem_22:
; };
; if (vTimeout > 3000000)
       cmp.l     #3000000,D4
       bls.s     loadSerialToMem_29
; break;
       bra       loadSerialToMem_10
loadSerialToMem_29:
; inputBuffer = *(vmfp + Reg_UDR);
       move.l    (A2),A0
       move.w    _Reg_UDR.L,D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D3
; if (vinicio == 0 && inputBuffer == 0x04)    // Primeiro byte eh EOT
       tst.b     D2
       bne.s     loadSerialToMem_31
       cmp.b     #4,D3
       bne.s     loadSerialToMem_31
; {
; writeSerial(0x06);    // Send ACK
       pea       6
       jsr       _writeSerial
       addq.w    #4,A7
; break;
       bra       loadSerialToMem_10
loadSerialToMem_31:
; }
; else if (vinicio < 3)
       cmp.b     #3,D2
       bhs       loadSerialToMem_33
; {
; *(vmfp + Reg_GPDR) = 0x04;
       move.l    (A2),A0
       move.w    (A4),D0
       and.l     #65535,D0
       move.b    #4,0(A0,D0.L)
; vHeader[vinicio] = inputBuffer;
       and.l     #255,D2
       move.b    D3,-40(A6,D2.L)
; if (vinicio == 1)
       cmp.b     #1,D2
       bne.s     loadSerialToMem_38
; {
; if (vBlockOld == inputBuffer)
       cmp.b     -1(A6),D3
       bne.s     loadSerialToMem_37
; vEndSave = vEndOld;
       move.l    -30(A6),D6
       bra.s     loadSerialToMem_38
loadSerialToMem_37:
; else
; {
; vEndOld = vEndSave;
       move.l    D6,-30(A6)
; vBlockOld = inputBuffer;
       move.b    D3,-1(A6)
loadSerialToMem_38:
; }
; }
; vinicio++;
       addq.b    #1,D2
; vchecksumcalc = 0;
       clr.l     -26(A6)
; verro = 0;
       clr.b     -31(A6)
; vStart = 0x01;
       move.b    #1,-2(A6)
       bra       loadSerialToMem_40
loadSerialToMem_33:
; }
; else if (vinicio == 131)
       and.w     #255,D2
       cmp.w     #131,D2
       bne       loadSerialToMem_39
; {
; *(vmfp + Reg_GPDR) = 0x05;
       move.l    (A2),A0
       move.w    (A4),D0
       and.l     #65535,D0
       move.b    #5,0(A0,D0.L)
; vinicio = 0;
       clr.b     D2
; vchecksum = inputBuffer;
       and.l     #255,D3
       move.l    D3,-36(A6)
; if ((vchecksumcalc % 256) != vchecksum)
       move.l    -26(A6),-(A7)
       pea       256
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       cmp.l     -36(A6),D0
       beq.s     loadSerialToMem_41
; {
; *(vmfp + Reg_GPDR) = 0x00;
       move.l    (A2),A0
       move.w    (A4),D0
       and.l     #65535,D0
       clr.b     0(A0,D0.L)
; verro = 1;
       move.b    #1,-31(A6)
; vEndSave = vEndOld;
       move.l    -30(A6),D6
; writeSerial(0x15);    // Send NACK
       pea       21
       jsr       _writeSerial
       addq.w    #4,A7
       bra.s     loadSerialToMem_42
loadSerialToMem_41:
; }
; else
; {
; *(vmfp + Reg_GPDR) = 0x01;
       move.l    (A2),A0
       move.w    (A4),D0
       and.l     #65535,D0
       move.b    #1,0(A0,D0.L)
; writeSerial(0x06);    // Send ACK
       pea       6
       jsr       _writeSerial
       addq.w    #4,A7
loadSerialToMem_42:
       bra.s     loadSerialToMem_40
loadSerialToMem_39:
; }
; }
; else
; {
; *vEndSave++ = inputBuffer;
       move.l    D6,A0
       addq.l    #1,D6
       move.b    D3,(A0)
; vchecksumcalc += inputBuffer;
       and.l     #255,D3
       add.l     D3,-26(A6)
; vinicio++;
       addq.b    #1,D2
loadSerialToMem_40:
       bra       loadSerialToMem_8
loadSerialToMem_10:
; }
; }
; vdp_write(' ');
       pea       32
       jsr       (A5)
       addq.w    #4,A7
; printText("\r\n\0");
       pea       @monitor_2.L
       jsr       (A3)
       addq.w    #4,A7
; // Habilita KBD and VDP Interruption
; *(vmfp + Reg_IERA) |= 0xC0;
       move.l    (A2),A0
       move.w    _Reg_IERA.L,D0
       and.l     #65535,D0
       or.b      #192,0(A0,D0.L)
; if (vTimeout > 3000000)
       cmp.l     #3000000,D4
       bls.s     loadSerialToMem_43
; {
; if (ptipo)
       tst.b     D5
       beq.s     loadSerialToMem_45
; printText("Timeout. Process Aborted.\r\n\0");
       pea       @monitor_37.L
       jsr       (A3)
       addq.w    #4,A7
loadSerialToMem_45:
; return 0xFE;
       move.b    #254,D0
       bra.s     loadSerialToMem_5
loadSerialToMem_43:
; }
; else
; {
; if (!verro)
       tst.b     -31(A6)
       bne.s     loadSerialToMem_47
; {
; if (ptipo)
       tst.b     D5
       beq.s     loadSerialToMem_49
; printText("File loaded in to memory successfuly.\r\n\0");
       pea       @monitor_38.L
       jsr       (A3)
       addq.w    #4,A7
loadSerialToMem_49:
; return 0x00;
       clr.b     D0
       bra.s     loadSerialToMem_5
loadSerialToMem_47:
; }
; else
; {
; if (ptipo)
       tst.b     D5
       beq.s     loadSerialToMem_51
; printText("File loaded in to memory with checksum errors.\r\n\0");
       pea       @monitor_39.L
       jsr       (A3)
       addq.w    #4,A7
loadSerialToMem_51:
; return 0xFD;
       move.b    #253,D0
loadSerialToMem_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; return 0xF0;
; }
; //-----------------------------------------------------------------------------
; void runMem(unsigned long pEnder)
; {
       xdef      _runMem
_runMem:
       link      A6,#0
; runCmd();
       jsr       _runCmd
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void runBasic(unsigned long pEnder)
; {
       xdef      _runBasic
_runBasic:
       link      A6,#0
; runBas();
       jsr       _runBas
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; // Delay Function
; //-----------------------------------------------------------------------------
; void delayms(int pTimeMS)
; {
       xdef      _delayms
_delayms:
       link      A6,#-4
       move.l    D2,-(A7)
; unsigned int ix;
; unsigned int iTempo = (100 * pTimeMS);
       move.l    8(A6),-(A7)
       pea       100
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-4(A6)
; for(ix = 0; ix <= iTempo; ix++);    // +/- 1ms * pTimeMs parada
       clr.l     D2
delayms_1:
       cmp.l     -4(A6),D2
       bhi.s     delayms_3
       addq.l    #1,D2
       bra       delayms_1
delayms_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //-----------------------------------------------------------------------------
; void delayus(int pTimeUS)
; {
       xdef      _delayus
_delayus:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned int ix;
; for(ix = 0; ix <= pTimeUS; ix++);    // +/- 1us * pTimeMs parada
       clr.l     D2
delayus_1:
       cmp.l     8(A6),D2
       bhi.s     delayus_3
       addq.l    #1,D2
       bra       delayus_1
delayus_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #ifdef __KEYPS2__
; //-----------------------------------------------------------------------------
; // KBD PS2 Functions
; //-----------------------------------------------------------------------------
; void processCode(void)
; {
; unsigned char decoded;
; if (*kbdScanCodeBuf == 0xAA && *kbdvprim)
; {
; sendByte(0xFE);
; *kbdvprim = 0;
; }
; if ((*kbdScanCodeBuf | 0x10) == 0xF0)
; {
; // release code!
; *kbdvreleased = 0x01;
; *kbdScanCodeCount = 0;
; }
; else if ((*kbdScanCodeBuf | 0x10) == 0xE0)
; {
; // apenas prepara para o proximo codigo
; *kbdve0 = 0x01;
; *kbdScanCodeCount = 0;
; }
; else if ((*kbdScanCodeBuf | 0x10) == 0xE1)
; {
; // apenas prepara para o proximo codigo
; delayms(100);
; *kbdScanCodeCount=0;
; }
; else
; {
; // normal character received
; if (!*kbdvcaps && !*kbdvshift)
; decoded = convertCode(*kbdScanCodeBuf,keyCode,ascii);
; else if (!*kbdvcaps && *kbdvshift)
; decoded = convertCode(*kbdScanCodeBuf,keyCode,ascii2);
; else if (*kbdvcaps && !*kbdvshift)
; decoded = convertCode(*kbdScanCodeBuf,keyCode,ascii3);
; else if (*kbdvcaps && *kbdvshift)
; decoded = convertCode(*kbdScanCodeBuf,keyCode,ascii4);
; if (decoded != '\0')
; {
; // allowed key code character received
; if (!*kbdvreleased)
; {
; if (*kbdKeyPntr > kbdKeyBuffMax)
; {
; // buffer full
; }
; else
; {
; *(kbdKeyBuffer + *kbdKeyPntr) = decoded;
; *kbdKeyPntr = *kbdKeyPntr + 1;
; *(kbdKeyBuffer + *kbdKeyPntr) = '\0';
; }
; }
; }
; else
; {
; // other character received
; switch (*kbdScanCodeBuf)
; {
; case 0x12:  // Shift
; case 0x59:
; *kbdvshift = ~*kbdvreleased & 0x01;
; break;
; case 0x14:  // Ctrl
; *kbdvctrl = ~*kbdvreleased & 0x01;
; break;
; case 0x11:  // Alt
; *kbdvalt = ~*kbdvreleased & 0x01;
; break;
; case 0x58:  // Caps Lock
; if (!*kbdvreleased)
; {
; *kbdvcaps = ~*kbdvcaps & 0x01;
; sendByte(0xED);
; sendByte((0x00 | (*kbdvcaps << 2) | (*kbdvnum << 1) | (*kbdvscr)));
; }
; break;
; case 0x77:  // Num Lock
; if (!*kbdvreleased)
; {
; *kbdvnum = ~*kbdvnum & 0x01;
; sendByte(0xED);
; sendByte((0x00 | (*kbdvcaps << 2) | (*kbdvnum << 1) | (*kbdvscr)));
; }
; break;
; case 0x7E:  // Scroll Lock
; if (!*kbdvreleased)
; {
; *kbdvscr = ~*kbdvscr & 0x01;
; sendByte(0xED);
; sendByte((0x00 | (*kbdvcaps << 2) | (*kbdvnum << 1) | (*kbdvscr)));
; }
; break;
; case 0x66:  // backspace
; if (!*kbdvreleased)
; {
; *(kbdKeyBuffer + *kbdKeyPntr) = 0x08;
; *kbdKeyPntr = *kbdKeyPntr + 1;
; *(kbdKeyBuffer + *kbdKeyPntr) = '\0';
; }
; break;
; case 0x5A:  // enter
; if (!*kbdvreleased)
; {
; *(kbdKeyBuffer + *kbdKeyPntr) = 0x0D;
; *kbdKeyPntr = *kbdKeyPntr + 1;
; *(kbdKeyBuffer + *kbdKeyPntr) = '\0';
; }
; break;
; case 0x76:  // ESCAPE
; if (!*kbdvreleased)
; {
; *(kbdKeyBuffer + *kbdKeyPntr) = 0x1B;
; *kbdKeyPntr = *kbdKeyPntr + 1;
; *(kbdKeyBuffer + *kbdKeyPntr) = '\0';
; }
; break;
; case 0x0D:  // TAB
; if (!*kbdvreleased)
; {
; *(kbdKeyBuffer + *kbdKeyPntr) = 0x09;
; *kbdKeyPntr = *kbdKeyPntr + 1;
; *(kbdKeyBuffer + *kbdKeyPntr) = '\0';
; }
; break;
; } // end switch
; } // end if (decoded>0x00)
; *kbdvreleased = 0x00;
; delayms(20);
; *kbdScanCodeCount = 0;
; }
; }
; //-----------------------------------------------------------------------------
; unsigned char convertCode(unsigned char codeToFind, unsigned char *source, unsigned char *destination)
; {
; while(*source != codeToFind && *source++ > 0x00)
; destination++;
; return *destination;
; }
; //-----------------------------------------------------------------------------
; void sendByte(unsigned char b)
; {
; /*unsigned char a=0;
; unsigned char p = 1;
; unsigned char t = 0;
; // Desabilita KBD and VDP Interruption
; *(vmfp + Reg_IERA) &= 0x3E;
; *(vmfp + Reg_GPDR) &= 0xBF; // Zera Clock (I6)
; *(vmfp + Reg_DDR)  |= 0x40; // I6 as Output
; delayus(125);
; *(vmfp + Reg_GPDR) &= 0xFE; // Zera Data (I0)
; *(vmfp + Reg_DDR)  |= 0x01; // I0 as Output
; delayus(125);
; *(vmfp + Reg_DDR)  &= 0xBF; // I6 as Input
; for(a = 0; a < 8; a++) {
; t = (b >> a) & 0x01;
; while ((*(vmfp + Reg_GPDR) & 0x40) == 0x40); //wait clock for 0
; *(vmfp + Reg_GPDR) |= t;
; if (t) p++;
; while ((*(vmfp + Reg_GPDR) & 0x40) == 0x00); //wait clock for 1
; }
; while((*(vmfp + Reg_GPDR) & 0x40) == 0x40); //wait clock for 0
; *(vmfp + Reg_GPDR) |= p & 0x01;
; while((*(vmfp + Reg_GPDR) & 0x40) == 0x00); //wait clock for 1
; *(vmfp + Reg_DDR)  &= 0xFE; // I0 as Input
; while((*(vmfp + Reg_GPDR) & 0x01) == 0x01); //wait data for 0
; while((*(vmfp + Reg_GPDR) & 0x40) == 0x40); //wait clock for 0
; // Habilita KBD and VDP Interruption
; *(vmfp + Reg_IERA) |= 0xC0;*/
; }
; #endif
; //-----------------------------------------------------------------------------
; void basicFuncBios(void)
; {
       xdef      _basicFuncBios
_basicFuncBios:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcSpuriousInt(void)
; {
       xdef      _funcSpuriousInt
_funcSpuriousInt:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntPIC(void)
; {
       xdef      _funcIntPIC
_funcIntPIC:
       rts
; // Chamada de dados do PIC para o processador
; }
; //-----------------------------------------------------------------------------
; void funcIntUsbSerial(void)
; {
       xdef      _funcIntUsbSerial
_funcIntUsbSerial:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntVideo(void)
; {
       xdef      _funcIntVideo
_funcIntVideo:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMouse(void)
; {
       xdef      _funcIntMouse
_funcIntMouse:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntKeyboard(void)
; {
       xdef      _funcIntKeyboard
_funcIntKeyboard:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMultiTask(void)
; {
       xdef      _funcIntMultiTask
_funcIntMultiTask:
       rts
; // Nao usara por enquanto, porque sera controlado pelo SO
; // E serah feito em ASM por causa das trocas de SP (A7)
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi0(void)
; {
       xdef      _funcIntMfpGpi0
_funcIntMfpGpi0:
; // TBD
; *(vmfp + Reg_ISRB) &= 0xFE;  // Reseta flag de interrupcao GPI0 no MFP
       move.l    _vmfp.L,A0
       move.w    _Reg_ISRB.L,D0
       and.l     #65535,D0
       and.b     #254,0(A0,D0.L)
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi1(void)
; {
       xdef      _funcIntMfpGpi1
_funcIntMfpGpi1:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi2(void)
; {
       xdef      _funcIntMfpGpi2
_funcIntMfpGpi2:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi3(void)
; {
       xdef      _funcIntMfpGpi3
_funcIntMfpGpi3:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpTmrD(void)
; {
       xdef      _funcIntMfpTmrD
_funcIntMfpTmrD:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpTmrC(void)
; {
       xdef      _funcIntMfpTmrC
_funcIntMfpTmrC:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi4(void)
; {
       xdef      _funcIntMfpGpi4
_funcIntMfpGpi4:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi5(void)
; {
       xdef      _funcIntMfpGpi5
_funcIntMfpGpi5:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpTmrB(void)
; {
       xdef      _funcIntMfpTmrB
_funcIntMfpTmrB:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpXmitErr(void)
; {
       xdef      _funcIntMfpXmitErr
_funcIntMfpXmitErr:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpXmitBufEmpty(void)
; {
       xdef      _funcIntMfpXmitBufEmpty
_funcIntMfpXmitBufEmpty:
; *vBufXmitEmpty = 1; // Buffer Transmissao Vazio
       move.l    _vBufXmitEmpty.L,A0
       move.b    #1,(A0)
; *(vmfp + Reg_GPDR) = 0x05;
       move.l    _vmfp.L,A0
       move.w    _Reg_GPDR.L,D0
       and.l     #65535,D0
       move.b    #5,0(A0,D0.L)
; *(vmfp + Reg_ISRA) &= 0xFB; // Reseta flag de interrupcao no MFP
       move.l    _vmfp.L,A0
       move.w    _Reg_ISRA.L,D0
       and.l     #65535,D0
       and.b     #251,0(A0,D0.L)
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpRecErr(void)
; {
       xdef      _funcIntMfpRecErr
_funcIntMfpRecErr:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpRecBufFull(void)
; {
       xdef      _funcIntMfpRecBufFull
_funcIntMfpRecBufFull:
; *vBufReceived = *(vmfp + Reg_UDR);   // Carrega byte do buffer do MFP
       move.l    _vmfp.L,A0
       move.w    _Reg_UDR.L,D0
       and.l     #65535,D0
       move.l    _vBufReceived.L,A1
       move.b    0(A0,D0.L),(A1)
; *(vmfp + Reg_ISRA) &= 0xEF;  // Reseta flag de interrupcao no MFP
       move.l    _vmfp.L,A0
       move.w    _Reg_ISRA.L,D0
       and.l     #65535,D0
       and.b     #239,0(A0,D0.L)
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpTmrA(void)
; {
       xdef      _funcIntMfpTmrA
_funcIntMfpTmrA:
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi6(void)
; {
       xdef      _funcIntMfpGpi6
_funcIntMfpGpi6:
       movem.l   D2/A2/A3/A4,-(A7)
       lea       _vmfp.L,A2
       lea       _Reg_GPDR.L,A3
       lea       _kbdKeyPntr.L,A4
; #ifdef __KEYPS2_EXT__
; unsigned char decoded = 0xFF;
       move.b    #255,D2
; // Pega dados do controlador via protocolo
; while (decoded != 0)
funcIntMfpGpi6_1:
       tst.b     D2
       beq       funcIntMfpGpi6_3
; {
; *(vmfp + Reg_GPDR) &= 0xEF;  // Seta CS (I4) = 0 do controlador e/ou indicando que ja leu MSB
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       and.b     #239,0(A0,D0.L)
; while (*(vmfp + Reg_GPDR) & 0x20); // Aguarda Controlador liberar LSB para leitura
funcIntMfpGpi6_4:
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.b     #32,D0
       beq.s     funcIntMfpGpi6_6
       bra       funcIntMfpGpi6_4
funcIntMfpGpi6_6:
; decoded = *(vmfp + Reg_GPDR) & 0x0F;
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.b     #15,D0
       move.b    D0,D2
; *(vmfp + Reg_GPDR) |= 0x10;  // Seta CS (I4) = 1 do controlador indicando que ja leu LSB
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       or.b      #16,0(A0,D0.L)
; while (!(*(vmfp + Reg_GPDR) & 0x20)); // Aguarda Controlador liberar MSB para leitura
funcIntMfpGpi6_7:
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.b     #32,D0
       bne.s     funcIntMfpGpi6_9
       bra       funcIntMfpGpi6_7
funcIntMfpGpi6_9:
; decoded |= ((*(vmfp + Reg_GPDR) & 0x0F) << 4);
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       move.b    0(A0,D0.L),D0
       and.b     #15,D0
       lsl.b     #4,D0
       or.b      D0,D2
; if (decoded != 0x00)
       tst.b     D2
       beq       funcIntMfpGpi6_10
; {
; // Coloca tecla digitada no buffer
; *(kbdKeyBuffer + *kbdKeyPntr) = decoded;
       move.l    _kbdKeyBuffer.L,A0
       move.l    (A4),A1
       move.b    (A1),D0
       and.l     #255,D0
       move.b    D2,0(A0,D0.L)
; if (*kbdKeyPntr < kbdKeyBuffMax)
       move.l    (A4),A0
       move.b    (A0),D0
       cmp.b     #15,D0
       bhs.s     funcIntMfpGpi6_12
; *kbdKeyPntr = *kbdKeyPntr + 1;
       move.l    (A4),A0
       addq.b    #1,(A0)
funcIntMfpGpi6_12:
; *(kbdKeyBuffer + *kbdKeyPntr) = '\0';
       move.l    _kbdKeyBuffer.L,A0
       move.l    (A4),A1
       move.b    (A1),D0
       and.l     #255,D0
       clr.b     0(A0,D0.L)
funcIntMfpGpi6_10:
; }
; *(vmfp + Reg_GPDR) &= 0xEF;  // Seta CS (I4) = 0 do controlador e/ou indicando que ja leu MSB
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       and.b     #239,0(A0,D0.L)
       bra       funcIntMfpGpi6_1
funcIntMfpGpi6_3:
; }
; *(vmfp + Reg_GPDR) |= 0x10;  // Seta CS = 1 (I4) do controlador
       move.l    (A2),A0
       move.w    (A3),D0
       and.l     #65535,D0
       or.b      #16,0(A0,D0.L)
; #endif
; #ifdef __KEYPS2__
; if (*kbdClockCount < 10)
; {
; // No 11 bits received yet: add to the scancode [start][d0...d7][parity][stop]
; *scanCode = (*scanCode >> 1);
; *scanCode = *scanCode | (unsigned short)((unsigned short)(*(vmfp + Reg_GPDR) & 0x01) * 0x400);
; *kbdClockCount = *kbdClockCount + 1;
; }
; else if (*kbdClockCount == 10)
; {
; // 11 bits received: process the code
; *(kbdScanCodeBuf + *kbdScanCodeCount) = (unsigned char)((*scanCode >> 2) & 0xFF);
; if (*kbdScanCodeCount < kbdMaxCharBuff)
; *kbdScanCodeCount = *kbdScanCodeCount + 1;
; *scanCode = 0;
; *kbdClockCount = 0;
; // Convert scancode
; processCode();
; }
; #endif
; *(vmfp + Reg_ISRA) &= 0xBF;  // Reseta flag de interrupcao no MFP
       move.l    (A2),A0
       move.w    _Reg_ISRA.L,D0
       and.l     #65535,D0
       and.b     #191,0(A0,D0.L)
       movem.l   (A7)+,D2/A2/A3/A4
       rts
; }
; //-----------------------------------------------------------------------------
; void funcIntMfpGpi7(void)
; {
       xdef      _funcIntMfpGpi7
_funcIntMfpGpi7:
; *(vmfp + Reg_ISRA) &= 0x7F;  // Reseta flag de interrupcao no MFP
       move.l    _vmfp.L,A0
       move.w    _Reg_ISRA.L,D0
       and.l     #65535,D0
       and.b     #127,0(A0,D0.L)
       rts
; }
; //-----------------------------------------------------------------------------
; void funcZeroesLeft(unsigned char* buffer, unsigned char vTam)
; {
       xdef      _funcZeroesLeft
_funcZeroesLeft:
       link      A6,#-20
       movem.l   D2/D3/D4/D5/A2/A3,-(A7)
       lea       -20(A6),A2
       move.l    8(A6),D4
       lea       _strlen.L,A3
       move.b    15(A6),D5
       and.l     #255,D5
; unsigned char vbuffer[20], i, j;
; if (vTam < strlen(vbuffer))
       and.l     #255,D5
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     D0,D5
       bhs.s     funcZeroesLeft_1
; vTam = strlen(vbuffer);
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.b    D0,D5
funcZeroesLeft_1:
; strcpy(vbuffer,buffer);
       move.l    D4,-(A7)
       move.l    A2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; for (i=0; i<(vTam-strlen(vbuffer));i++) {
       clr.b     D2
funcZeroesLeft_3:
       and.l     #255,D2
       move.b    D5,D0
       and.l     #255,D0
       move.l    D0,-(A7)
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       sub.l     D1,D0
       cmp.l     D0,D2
       bhs.s     funcZeroesLeft_5
; buffer[i]='0';
       move.l    D4,A0
       and.l     #255,D2
       move.b    #48,0(A0,D2.L)
       addq.b    #1,D2
       bra       funcZeroesLeft_3
funcZeroesLeft_5:
; }
; for(j=0;j<strlen(vbuffer);j++){
       clr.b     D3
funcZeroesLeft_6:
       and.l     #255,D3
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       cmp.l     D0,D3
       bhs.s     funcZeroesLeft_8
; buffer[i] = vbuffer[j];
       and.l     #255,D3
       move.l    D4,A0
       and.l     #255,D2
       move.b    0(A2,D3.L),0(A0,D2.L)
; i++;
       addq.b    #1,D2
; buffer[i] = 0x00;
       move.l    D4,A0
       and.l     #255,D2
       clr.b     0(A0,D2.L)
       addq.b    #1,D3
       bra       funcZeroesLeft_6
funcZeroesLeft_8:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3
       unlk      A6
       rts
; }
; }
; //-----------------------------------------------------------------------------
; void funcErrorBusAddr(void)
; {
       xdef      _funcErrorBusAddr
_funcErrorBusAddr:
       link      A6,#-20
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       _printText.L,A2
       lea       _printChar.L,A3
       lea       -20(A6),A4
       lea       _funcZeroesLeft.L,A5
; unsigned int ix = 0, iz;
       clr.l     D2
; unsigned char sqtdtam[20];
; unsigned short vOP = 0;
       clr.w     D4
; *videoCursorPosColX = 0;
       move.l    _videoCursorPosColX.L,A0
       clr.w     (A0)
; *videoCursorPosRowY = 0;
       move.l    _videoCursorPosRowY.L,A0
       clr.w     (A0)
; *videoScroll = 1;       // Ativo
       move.l    _videoScroll.L,A0
       move.b    #1,(A0)
; *videoScrollDir = 1;    // Pra Cima
       move.l    _videoScrollDir.L,A0
       move.b    #1,(A0)
; *videoCursorBlink = 1;
       move.l    _videoCursorBlink.L,A0
       move.b    #1,(A0)
; *videoCursorShow = 0;
       move.l    _videoCursorShow.L,A0
       clr.b     (A0)
; *vdpMaxCols = 39;
       move.l    _vdpMaxCols.L,A0
       move.b    #39,(A0)
; *vdpMaxRows = 23;
       move.l    _vdpMaxRows.L,A0
       move.b    #23,(A0)
; vdp_init_textmode(VDP_WHITE, VDP_DARK_RED);
       pea       6
       pea       15
       jsr       _vdp_init_textmode
       addq.w    #8,A7
; clearScr();
       jsr       _clearScr
; printChar(218,1);
       pea       1
       pea       218
       jsr       (A3)
       addq.w    #8,A7
; for (ix = 0; ix < 36; ix++)
       clr.l     D2
funcErrorBusAddr_1:
       cmp.l     #36,D2
       bhs.s     funcErrorBusAddr_3
; printChar(196,1);
       pea       1
       pea       196
       jsr       (A3)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       funcErrorBusAddr_1
funcErrorBusAddr_3:
; printChar(191,1);
       pea       1
       pea       191
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("          EXCEPTION OCCURRED        ");
       pea       @monitor_41.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(195,1);
       pea       1
       pea       195
       jsr       (A3)
       addq.w    #8,A7
; for (ix = 0; ix < 36; ix++)
       clr.l     D2
funcErrorBusAddr_4:
       cmp.l     #36,D2
       bhs.s     funcErrorBusAddr_6
; printChar(196,1);
       pea       1
       pea       196
       jsr       (A3)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       funcErrorBusAddr_4
funcErrorBusAddr_6:
; printChar(180,1);
       pea       1
       pea       180
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; vOP = *errorBufferAddrBus;
       move.l    _errorBufferAddrBus.L,A0
       move.w    (A0),D4
; switch (vOP)
       and.l     #65535,D4
       move.l    D4,D0
       cmp.l     #6,D0
       bhs       funcErrorBusAddr_7
       asl.l     #1,D0
       move.w    funcErrorBusAddr_9(PC,D0.L),D0
       jmp       funcErrorBusAddr_9(PC,D0.W)
funcErrorBusAddr_9:
       dc.w      funcErrorBusAddr_10-funcErrorBusAddr_9
       dc.w      funcErrorBusAddr_11-funcErrorBusAddr_9
       dc.w      funcErrorBusAddr_12-funcErrorBusAddr_9
       dc.w      funcErrorBusAddr_13-funcErrorBusAddr_9
       dc.w      funcErrorBusAddr_14-funcErrorBusAddr_9
       dc.w      funcErrorBusAddr_15-funcErrorBusAddr_9
funcErrorBusAddr_10:
; {
; case 0x0000:
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("      BUS ERROR / ADDRESS ERROR     ");
       pea       @monitor_42.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       funcErrorBusAddr_8
funcErrorBusAddr_11:
; case 0x0001:
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("         ILLEGAL INSTRUCTION        ");
       pea       @monitor_43.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       funcErrorBusAddr_8
funcErrorBusAddr_12:
; case 0x0002:
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("             ZERO DIVIDE            ");
       pea       @monitor_44.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       funcErrorBusAddr_8
funcErrorBusAddr_13:
; case 0x0003:
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("           CHK INSTRUCTION          ");
       pea       @monitor_45.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       funcErrorBusAddr_8
funcErrorBusAddr_14:
; case 0x0004:
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("                TRAPV               ");
       pea       @monitor_46.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       funcErrorBusAddr_8
funcErrorBusAddr_15:
; case 0x0005:
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("         PRIVILEGE VIOLATION        ");
       pea       @monitor_47.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       funcErrorBusAddr_8
funcErrorBusAddr_7:
; default:
; itoa(errorBufferAddrBus,sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 8);
       pea       8
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printText(" : ");
       pea       @monitor_48.L
       jsr       (A2)
       addq.w    #4,A7
; itoa(vOP,sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; break;
funcErrorBusAddr_8:
; }
; printChar(195,1);
       pea       1
       pea       195
       jsr       (A3)
       addq.w    #8,A7
; for (ix = 0; ix < 36; ix++)
       clr.l     D2
funcErrorBusAddr_17:
       cmp.l     #36,D2
       bhs.s     funcErrorBusAddr_19
; printChar(196,1);
       pea       1
       pea       196
       jsr       (A3)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       funcErrorBusAddr_17
funcErrorBusAddr_19:
; printChar(180,1);
       pea       1
       pea       180
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; // Mostra Registradores: 2 words by register
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" D0       D1       D2       D3      ");
       pea       @monitor_49.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printChar(' ',1);
       pea       1
       pea       32
       jsr       (A3)
       addq.w    #8,A7
; for (iz = 0; iz < 4; iz++)  // Mostra d0-d3
       clr.l     D3
funcErrorBusAddr_20:
       cmp.l     #4,D3
       bhs       funcErrorBusAddr_22
; {
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; if (iz < 3)
       cmp.l     #3,D3
       bhs.s     funcErrorBusAddr_23
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
funcErrorBusAddr_23:
       addq.l    #1,D3
       bra       funcErrorBusAddr_20
funcErrorBusAddr_22:
; }
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" D4       D5       D6       D7      ");
       pea       @monitor_51.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printChar(' ',1);
       pea       1
       pea       32
       jsr       (A3)
       addq.w    #8,A7
; for (iz = 0; iz < 4; iz++)  // Mostra d4-d7
       clr.l     D3
funcErrorBusAddr_25:
       cmp.l     #4,D3
       bhs       funcErrorBusAddr_27
; {
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; if (iz < 3)
       cmp.l     #3,D3
       bhs.s     funcErrorBusAddr_28
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
funcErrorBusAddr_28:
       addq.l    #1,D3
       bra       funcErrorBusAddr_25
funcErrorBusAddr_27:
; }
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" A0       A1       A2       A3      ");
       pea       @monitor_52.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printChar(' ',1);
       pea       1
       pea       32
       jsr       (A3)
       addq.w    #8,A7
; for (iz = 0; iz < 4; iz++)  // Mostra d0-d3
       clr.l     D3
funcErrorBusAddr_30:
       cmp.l     #4,D3
       bhs       funcErrorBusAddr_32
; {
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; if (iz < 3)
       cmp.l     #3,D3
       bhs.s     funcErrorBusAddr_33
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
funcErrorBusAddr_33:
       addq.l    #1,D3
       bra       funcErrorBusAddr_30
funcErrorBusAddr_32:
; }
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" A4       A5       A6               ");
       pea       @monitor_53.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printChar(' ',1);
       pea       1
       pea       32
       jsr       (A3)
       addq.w    #8,A7
; for (iz = 0; iz < 3; iz++)  // Mostra d4-d7
       clr.l     D3
funcErrorBusAddr_35:
       cmp.l     #3,D3
       bhs       funcErrorBusAddr_37
; {
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
       addq.l    #1,D3
       bra       funcErrorBusAddr_35
funcErrorBusAddr_37:
; }
; printText("        ");
       pea       @monitor_54.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("                                    ");
       pea       @monitor_55.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" SR   PC       OffSet Special_Word  ");
       pea       @monitor_56.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printChar(' ',1);
       pea       1
       pea       32
       jsr       (A3)
       addq.w    #8,A7
; // Mostra SR: 1 word
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
; // Mostra PC to Return: 2 words
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
; // Mostra Vector offset: 1 word
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText("   ");
       pea       @monitor_57.L
       jsr       (A2)
       addq.w    #4,A7
; // Mostra Special Status Word: 1 word
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText("          ");
       pea       @monitor_58.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("                                    ");
       pea       @monitor_55.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" FaultAddr OutB InB  Instr.InB      ");
       pea       @monitor_59.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printChar(' ',1);
       pea       1
       pea       32
       jsr       (A3)
       addq.w    #8,A7
; // Mostra Fault Address: 2 words
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText("  ");
       pea       @monitor_60.L
       jsr       (A2)
       addq.w    #4,A7
; // unused: 1 word
; ix++;
       addq.l    #1,D2
; // Mostra output buffer: 1 word
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
; // unused: 1 word
; ix++;
       addq.l    #1,D2
; // Mostra input buffer: 1 word
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText(" ");
       pea       @monitor_50.L
       jsr       (A2)
       addq.w    #4,A7
; // unused: 1 word
; ix++;
       addq.l    #1,D2
; // Mostra instruction input buffer: 1 word
; itoa(*(errorBufferAddrBus + ix),sqtdtam,16);
       pea       16
       move.l    A4,-(A7)
       move.l    _errorBufferAddrBus.L,A0
       move.l    D2,D1
       lsl.l     #1,D1
       move.w    0(A0,D1.L),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _itoa
       add.w     #12,A7
; funcZeroesLeft(&sqtdtam, 4);
       pea       4
       move.l    A4,-(A7)
       jsr       (A5)
       addq.w    #8,A7
; printText(sqtdtam);
       move.l    A4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; ix++;
       addq.l    #1,D2
; printText("           ");
       pea       @monitor_61.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("\r\n");
       pea       @monitor_2.L
       jsr       (A2)
       addq.w    #4,A7
; // Halt
; printChar(195,1);
       pea       1
       pea       195
       jsr       (A3)
       addq.w    #8,A7
; for (ix = 0; ix < 36; ix++)
       clr.l     D2
funcErrorBusAddr_38:
       cmp.l     #36,D2
       bhs.s     funcErrorBusAddr_40
; printChar(196,1);
       pea       1
       pea       196
       jsr       (A3)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       funcErrorBusAddr_38
funcErrorBusAddr_40:
; printChar(180,1);
       pea       1
       pea       180
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText("            SYSTEM HALTED           ");
       pea       @monitor_62.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(179,1);
       pea       1
       pea       179
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; printChar(192,1);
       pea       1
       pea       192
       jsr       (A3)
       addq.w    #8,A7
; for (ix = 0; ix < 36; ix++)
       clr.l     D2
funcErrorBusAddr_41:
       cmp.l     #36,D2
       bhs.s     funcErrorBusAddr_43
; printChar(196,1);
       pea       1
       pea       196
       jsr       (A3)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       funcErrorBusAddr_41
funcErrorBusAddr_43:
; printChar(217,1);
       pea       1
       pea       217
       jsr       (A3)
       addq.w    #8,A7
; printText(" \r\n");
       pea       @monitor_40.L
       jsr       (A2)
       addq.w    #4,A7
; for(;;);
funcErrorBusAddr_44:
       bra       funcErrorBusAddr_44
; }
       section   const
@monitor_1:
       dc.b      77,77,83,74,45,51,48,48,32,66,73,79,83,32,118
       dc.b      49,46,49,98,0
@monitor_2:
       dc.b      13,10,0
@monitor_3:
       dc.b      85,116,105,108,105,116,121,32,40,99,41,32,50
       dc.b      48,49,52,45,50,48,50,52,13,10,0
@monitor_4:
       dc.b      75,32,66,121,116,101,115,32,70,111,117,110,100
       dc.b      46,32,0
@monitor_5:
       dc.b      75,32,66,121,116,101,115,32,70,114,101,101,46
       dc.b      13,10,0
@monitor_6:
       dc.b      79,75,13,10,0
@monitor_7:
       dc.b      62,0
@monitor_8:
       dc.b      67,76,83,0
@monitor_9:
       dc.b      67,76,69,65,82,0
@monitor_10:
       dc.b      86,69,82,0
@monitor_11:
       dc.b      76,79,65,68,0
@monitor_12:
       dc.b      87,97,105,116,46,46,46,13,10,0
@monitor_13:
       dc.b      82,85,78,0
@monitor_14:
       dc.b      66,65,83,73,67,0
@monitor_15:
       dc.b      77,79,68,69,0
@monitor_16:
       dc.b      80,79,75,69,0
@monitor_17:
       dc.b      68,85,77,80,0
@monitor_18:
       dc.b      68,85,77,80,83,0
@monitor_19:
       dc.b      85,110,107,110,111,119,110,32,67,111,109,109
       dc.b      97,110,100,32,33,33,33,13,10,0
@monitor_20:
       dc.b      117,115,97,103,101,58,32,109,111,100,101,32
       dc.b      91,99,111,100,101,93,13,10,0
@monitor_21:
       dc.b      32,32,32,99,111,100,101,58,32,48,32,61,32,84
       dc.b      101,120,116,32,77,111,100,101,32,52,48,120,50
       dc.b      52,13,10,0
@monitor_22:
       dc.b      32,32,32,32,32,32,32,32,32,49,32,61,32,71,114
       dc.b      97,112,104,105,99,32,84,101,120,116,32,77,111
       dc.b      100,101,32,51,50,120,50,52,13,10,0
@monitor_23:
       dc.b      32,32,32,32,32,32,32,32,32,50,32,61,32,71,114
       dc.b      97,112,104,105,99,32,50,53,54,120,49,57,50,13
       dc.b      10,0
@monitor_24:
       dc.b      32,32,32,32,32,32,32,32,32,51,32,61,32,71,114
       dc.b      97,112,104,105,99,32,54,52,120,52,56,13,10,0
@monitor_25:
       dc.b      117,115,97,103,101,58,32,112,111,107,101,32
       dc.b      60,101,110,100,101,114,62,32,60,98,121,116,101
       dc.b      62,13,10,0
@monitor_26:
       dc.b      117,115,97,103,101,58,32,100,117,109,112,32
       dc.b      60,101,110,100,101,114,62,32,91,113,116,100
       dc.b      93,32,91,99,111,108,115,93,13,10,0
@monitor_27:
       dc.b      32,32,32,32,113,116,100,58,32,100,101,102,97
       dc.b      117,108,116,32,54,52,13,10,0
@monitor_28:
       dc.b      32,32,32,99,111,108,115,58,32,100,101,102,97
       dc.b      117,108,116,32,56,13,10,0
@monitor_29:
       dc.b      124,0
@monitor_30:
       dc.b      117,115,97,103,101,58,32,100,117,109,112,32
       dc.b      60,101,110,100,101,114,32,105,110,105,116,105
       dc.b      97,108,62,32,91,113,116,100,32,40,100,101,102
       dc.b      97,117,108,116,32,50,53,54,41,93,13,10,0
@monitor_31:
       dc.b      104,32,58,32,0
@monitor_32:
       dc.b      32,124,32,0
@monitor_33:
       dc.b      73,110,118,97,108,105,100,32,65,114,103,117
       dc.b      109,101,110,116,58,32,0
@monitor_34:
       dc.b      117,115,97,103,101,58,32,108,111,97,100,32,60
       dc.b      101,110,100,101,114,62,13,10,0
@monitor_35:
       dc.b      32,32,32,32,60,101,110,100,101,114,62,32,58
       dc.b      32,101,110,100,101,114,32,116,111,32,115,97
       dc.b      118,101,32,62,61,32,48,48,56,48,48,48,48,48
       dc.b      104,13,10,0
@monitor_36:
       dc.b      82,101,99,101,105,118,105,110,103,46,46,46,32
       dc.b      0
@monitor_37:
       dc.b      84,105,109,101,111,117,116,46,32,80,114,111
       dc.b      99,101,115,115,32,65,98,111,114,116,101,100
       dc.b      46,13,10,0
@monitor_38:
       dc.b      70,105,108,101,32,108,111,97,100,101,100,32
       dc.b      105,110,32,116,111,32,109,101,109,111,114,121
       dc.b      32,115,117,99,99,101,115,115,102,117,108,121
       dc.b      46,13,10,0
@monitor_39:
       dc.b      70,105,108,101,32,108,111,97,100,101,100,32
       dc.b      105,110,32,116,111,32,109,101,109,111,114,121
       dc.b      32,119,105,116,104,32,99,104,101,99,107,115
       dc.b      117,109,32,101,114,114,111,114,115,46,13,10
       dc.b      0
@monitor_40:
       dc.b      32,13,10,0
@monitor_41:
       dc.b      32,32,32,32,32,32,32,32,32,32,69,88,67,69,80
       dc.b      84,73,79,78,32,79,67,67,85,82,82,69,68,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_42:
       dc.b      32,32,32,32,32,32,66,85,83,32,69,82,82,79,82
       dc.b      32,47,32,65,68,68,82,69,83,83,32,69,82,82,79
       dc.b      82,32,32,32,32,32,0
@monitor_43:
       dc.b      32,32,32,32,32,32,32,32,32,73,76,76,69,71,65
       dc.b      76,32,73,78,83,84,82,85,67,84,73,79,78,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_44:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,32,90,69
       dc.b      82,79,32,68,73,86,73,68,69,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_45:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,67,72,75,32
       dc.b      73,78,83,84,82,85,67,84,73,79,78,32,32,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_46:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
       dc.b      32,84,82,65,80,86,32,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_47:
       dc.b      32,32,32,32,32,32,32,32,32,80,82,73,86,73,76
       dc.b      69,71,69,32,86,73,79,76,65,84,73,79,78,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_48:
       dc.b      32,58,32,0
@monitor_49:
       dc.b      32,68,48,32,32,32,32,32,32,32,68,49,32,32,32
       dc.b      32,32,32,32,68,50,32,32,32,32,32,32,32,68,51
       dc.b      32,32,32,32,32,32,0
@monitor_50:
       dc.b      32,0
@monitor_51:
       dc.b      32,68,52,32,32,32,32,32,32,32,68,53,32,32,32
       dc.b      32,32,32,32,68,54,32,32,32,32,32,32,32,68,55
       dc.b      32,32,32,32,32,32,0
@monitor_52:
       dc.b      32,65,48,32,32,32,32,32,32,32,65,49,32,32,32
       dc.b      32,32,32,32,65,50,32,32,32,32,32,32,32,65,51
       dc.b      32,32,32,32,32,32,0
@monitor_53:
       dc.b      32,65,52,32,32,32,32,32,32,32,65,53,32,32,32
       dc.b      32,32,32,32,65,54,32,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_54:
       dc.b      32,32,32,32,32,32,32,32,0
@monitor_55:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,0
@monitor_56:
       dc.b      32,83,82,32,32,32,80,67,32,32,32,32,32,32,32
       dc.b      79,102,102,83,101,116,32,83,112,101,99,105,97
       dc.b      108,95,87,111,114,100,32,32,0
@monitor_57:
       dc.b      32,32,32,0
@monitor_58:
       dc.b      32,32,32,32,32,32,32,32,32,32,0
@monitor_59:
       dc.b      32,70,97,117,108,116,65,100,100,114,32,79,117
       dc.b      116,66,32,73,110,66,32,32,73,110,115,116,114
       dc.b      46,73,110,66,32,32,32,32,32,32,0
@monitor_60:
       dc.b      32,32,0
@monitor_61:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,0
@monitor_62:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,83,89,83
       dc.b      84,69,77,32,72,65,76,84,69,68,32,32,32,32,32
       dc.b      32,32,32,32,32,32,0
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
       xref      _strcpy
       xref      _itoa
       xref      _ltoa
       xref      LDIV
       xref      LMUL
       xref      _atol
       xref      _strlen
       xref      ULMUL
       xref      _runCmd
       xref      _toupper
       xref      _strcmp
       xref      ULDIV
       xref      _runBas
