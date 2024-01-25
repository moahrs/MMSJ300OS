/*
*************************************************************
00400041h - ADDRESS TO WRITE/READ DATA TO VRAM
00400141h - ADDRESS TO WRITE/READ DATA TO VDP
*************************************************************
* INITIALIZE THE 9918 WITH THE FOLLOWING:
*
* REG 0 = 00 : EXT VID OFF, GRAPH 2 OFF
* REG 1 = 03 : 4116, VID ON, INT DIS, GRAPH 1, SIZE 1, MAG OFF
* REG 2 = 01 : NAME TABLE SUB BLOCK
* REG 3 = 08 : COLOR TABLE SUB BLOCK
* REG 4 = 01 : PATTERN GEN SUB BLOCK
* REG 5 = 06 : SPRITE NAME TAB SUB BLK
* REG 6 = 00 : SPRITE PATT GEN SUB BLK
* REG 7 = 07 : BACKDROP COLOR IS CYAN
**************************************************************
vdp:
First send DATA, after send Register
only read status register

vram:
send MSB A6 - A13
send LSB 0 1 A0 - A5
write data or read data
**************************************************************
*/
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "../mmsj300api.h"
#include "../monitor.h"
#include "tms9929.h"

unsigned char reverseBits(unsigned char num)
{
    unsigned char count = sizeof(num) * 8 - 1;
    unsigned char reverse_num = num;
 
    num >>= 1;
    while (num) {
        reverse_num <<= 1;
        reverse_num |= num & 1;
        num >>= 1;
        count--;
    }
    reverse_num <<= count;
    return reverse_num;
}

//-----------------------------------------------------------------------------
// Principal
//-----------------------------------------------------------------------------
void main(void)
{
    unsigned char vdpreg = 0;
    unsigned char sqtdtam[10];

    // mostra msgs na tela
    printText("Testing TMS9929anl...\n\r\0");

    printText("Setting Up...\n\r\0");
    *vvdgr = 0x00; *vvdgr = 0x80;
    *vvdgr = 0x03; *vvdgr = 0x81;
    *vvdgr = 0x01; *vvdgr = 0x82;
    *vvdgr = 0x08; *vvdgr = 0x83;
    *vvdgr = 0x01; *vvdgr = 0x84;
    *vvdgr = 0x06; *vvdgr = 0x85;
    *vvdgr = 0x00; *vvdgr = 0x86;
    *vvdgr = 0x07; *vvdgr = 0x87;

    printText("Reading Status register: \0");

    vdpreg = *vvdgr;
    itoa(vdpreg, sqtdtam, 16);

    printText(sqtdtam);

    printText("\r\nWriting at VRAM: \0");

    *vvdgr = 0x40; *vvdgr = 0x20;
    *vvdgd = 0xAA;

    *vvdgr = 0x40; *vvdgr = 0x20;
    vdpreg = *vvdgd;
    itoa(vdpreg, sqtdtam, 16);

    printText(sqtdtam);
    printText("\r\nEnd...\n\r\0");
}