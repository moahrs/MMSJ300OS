; C:\IDE68K\EXAMPLES\TIMER.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J.Fondse
; // TIMER.C - a program to count seconds since start of 68000 program
; // This program can be compiled by loading timer.prj in the "Project|Open
; // project" menu.
; // Be sure to select option "generate assembly listing" , otherwise it
; // cannot be run on the 68000 Visual Simulator.
; // To run this program in the 68000 Visual Simulator, you must enable the
; // 7-SEGMENT DISPLAY window from the Peripherals menu.
; // The display indicates the time in seconds since the Visual Simulator has
; // started. Its main purpose is to show how 68000 I/O devices can be
; // programmed from a C-program (using pointers to the device).
; // Although this program can be run in Single-step and Auto-step mode,
; // Run mode is preferred.
; // Author: Peter J. Fondse (pfondse@hetnet.nl)
; // Pointers to I/O devices
; unsigned short *display = (unsigned short *) 0xE010; // display[0] is leftmost digit etc.
; unsigned long *timer = (unsigned long *) 0xE040;     // timer
; // bit pattern for 7 segment display 0 - 9
; unsigned short bitpat[] = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F };
; // clear 7 segment display
; void clear7seg(void)
; {
       section   code
       xdef      _clear7seg
_clear7seg:
       move.l    D2,-(A7)
; int i;
; for (i = 0; i < 3; i++) display[i] = 0;      // clear first 3 digits
       clr.l     D2
clear7seg_1:
       cmp.l     #3,D2
       bge.s     clear7seg_3
       move.l    _display.L,A0
       move.l    D2,D0
       lsl.l     #1,D0
       clr.w     0(A0,D0.L)
       addq.l    #1,D2
       bra       clear7seg_1
clear7seg_3:
; display[3] = bitpat[0];                      // last digit is '0'
       move.l    _display.L,A0
       move.w    _bitpat.L,6(A0)
       move.l    (A7)+,D2
       rts
; }
; // write to 7 segment display (recursive)
; void write7seg(long n, int i)
; {
       xdef      _write7seg
_write7seg:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if (n > 9) write7seg(n / 10, i - 1);
       cmp.l     #9,D2
       ble.s     write7seg_1
       move.l    12(A6),D1
       subq.l    #1,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       pea       10
       jsr       LDIV
       move.l    (A7),D1
       addq.w    #8,A7
       move.l    D1,-(A7)
       jsr       _write7seg
       addq.w    #8,A7
write7seg_1:
; display[i] = bitpat[n % 10];
       move.l    D2,-(A7)
       pea       10
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       lsl.l     #1,D0
       lea       _bitpat.L,A0
       move.l    _display.L,A1
       move.l    12(A6),D1
       lsl.l     #1,D1
       move.w    0(A0,D0.L),0(A1,D1.L)
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; void main(void)
; {
       xdef      _main
_main:
       movem.l   D2/D3,-(A7)
; long counter = 0;
       clr.l     D2
; clear7seg();
       jsr       _clear7seg
; for (;;) {
main_1:
; long cntr = *timer / 10;
       move.l    _timer.L,A0
       move.l    (A0),-(A7)
       pea       10
       jsr       ULDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D3
; if (counter != cntr) {                   // timer has changed
       cmp.l     D3,D2
       beq.s     main_4
; counter = cntr;
       move.l    D3,D2
; if (counter == 10000) break;         // stop after 9999 seconds
       cmp.l     #10000,D2
       bne.s     main_6
       bra.s     main_3
main_6:
; write7seg(counter, 3);
       pea       3
       move.l    D2,-(A7)
       jsr       _write7seg
       addq.w    #8,A7
main_4:
       bra       main_1
main_3:
       movem.l   (A7)+,D2/D3
       rts
; }
; }
; }
       section   data
       xdef      _display
_display:
       dc.l      57360
       xdef      _timer
_timer:
       dc.l      57408
       xdef      _bitpat
_bitpat:
       dc.w      63,6,91,79,102,109,125,7,127,111
       xref      LDIV
       xref      ULDIV
