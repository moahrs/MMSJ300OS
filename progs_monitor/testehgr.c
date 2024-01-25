#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "../mmsj300api.h"
#include "../monitor.h"
#include "testehgr.h"

//-----------------------------------------------------------------------------
// Principal
//-----------------------------------------------------------------------------
void main(void)
{
    unsigned char vx, vy;
    unsigned char vtec;

    // Timer para o Random
    *(vmfp + Reg_TADR) = 0xF5;  // 245
    *(vmfp + Reg_TACR) = 0x02;  // prescaler de 10. total 2,4576Mhz/10*245 = 1003KHz

    clearScr();

    vdp_init(VDP_MODE_G2, 0x0, 1, 0);
    vdp_set_bdcolor(VDP_BLACK);

writeLongSerial("***************[Ponto]******************\r\n");
    uvdp_plot_hires(40, 40, *fgcolor, *bgcolor);

writeLongSerial("**********[Linha Horizontal]************\r\n");
    for (vx = 50; vx < 120; vx++)
        uvdp_plot_hires(vx, 50, *fgcolor, *bgcolor);

writeLongSerial("**********[Linha Vertical 1]************\r\n");
    for (vy = 50; vy < 120; vy++)
        uvdp_plot_hires(50, vy, *fgcolor, *bgcolor);

writeLongSerial("**********[Linha Vertical 2]************\r\n");
    for (vy = 50; vy < 120; vy++)
        uvdp_plot_hires(120, vy, *fgcolor, *bgcolor);

writeLongSerial("****************[FIM]*******************\r\n");
    vtec = 0x00;
    *vBufReceived = 0x00;

    while(!vtec)
    {
        readChar();

        vtec = *vBufReceived;        
    }

    *fgcolor = VDP_WHITE;
    *bgcolor = VDP_BLACK;
    vdp_init(VDP_MODE_TEXT, (*fgcolor<<4) | (*bgcolor & 0x0f), 0, 0);
    clearScr();
}

//-----------------------------------------------------------------------------
void setWriteAddress(unsigned int address)
{
    *vvdgc = (unsigned char)(address & 0xff);
    *vvdgc = (unsigned char)(0x40 | (address >> 8) & 0x3f);
}

//-----------------------------------------------------------------------------
void setReadAddress(unsigned int address)
{
    *vvdgc = (unsigned char)(address & 0xff);
    *vvdgc = (unsigned char)((address >> 8) & 0x3f);
}

//-----------------------------------------------------------------------------
void uvdp_plot_hires(unsigned char x, unsigned char y, unsigned char color1, unsigned char color2)
{
    unsigned int offset, posX, posY, modY;
    unsigned char pixel;
    unsigned char color;
    unsigned char sqtdtam[10];

    posX = (int)(8 * (x / 8));
    posY = (int)(256 * (y / 8));
    modY = (int)(y % 8);

    offset = posX + modY + posY;

writeLongSerial("Aqui 777.666.0-[");
itoa(x,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial(",");
itoa(y,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[cor: ");
itoa(color1,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[posX: ");
itoa(posX,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[modY: ");
itoa(modY,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[posY: ");
itoa(posY,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[offset: ");
itoa(offset,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");

    setReadAddress(*pattern_table + offset);
    setReadAddress(*pattern_table + offset);
    pixel = *vvdgd;
    setReadAddress(*color_table + offset);
    setReadAddress(*color_table + offset);
    color = *vvdgd;
writeLongSerial("Aqui 777.666.1-[");
itoa(pixel,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial(",");
itoa(color,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");
    if (color1 != 0x00)
    {
        pixel |= 0x80 >> (x % 8); //Set a "1"
        color = (color & 0x0F) | (color1 << 4);
    }
    else
    {
        pixel &= ~(0x80 >> (x % 8)); //Set bit as "0"
        color = (color & 0xF0) | (color2 & 0x0F);
    }
writeLongSerial("Aqui 777.666.2-[");
itoa(pixel,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial(",");
itoa(color,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");
    setWriteAddress(*pattern_table + offset);
    *vvdgd = (pixel);
    setWriteAddress(*color_table + offset);
    *vvdgd = (color);
}

