/********************************************************************************
*    Programa    : mgui.c
*    Objetivo    : MMSJ300 Graphical User Interface
*    Criado em   : 25/07/2023
*    Programador : Moacir Jr.
*--------------------------------------------------------------------------------
* Data        Versao  Responsavel  Motivo
* 25/07/2023  0.1     Moacir Jr.   Criacao Versao Beta
*--------------------------------------------------------------------------------
*
*--------------------------------------------------------------------------------
* To do
*
*--------------------------------------------------------------------------------
*
*********************************************************************************/
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "../mmsj300api.h"
#include "../monitor.h"
#include "mgui.h"

#define versionMgui "0.1"

//-----------------------------------------------------------------------------
// Principal
//-----------------------------------------------------------------------------
void main(void)
{
}

//-----------------------------------------------------------------------------
// Graphic Interface Functions
//-----------------------------------------------------------------------------
void writesxy(unsigned short x, unsigned short y, unsigned char sizef, unsigned char *msgs, unsigned short pcolor, unsigned short pbcolor) {
    unsigned char ix = 10, *ss = msgs;

    while (*ss) {
      if (*ss >= 0x20)
          ix++;
      *ss++;
    }

    // Manda Sequencia de Controle
    if (ix > 10) {
        *vpicg = ix;
        *vpicg = 0xD1;
        *vpicg = x >> 8;
        *vpicg = x;
        *vpicg = y >> 8;
        *vpicg = y;
        *vpicg = sizef;
        *vpicg = pcolor >> 8;
        *vpicg = pcolor;
        *vpicg = pbcolor >> 8;
        *vpicg = pbcolor;

        while (*msgs) {
            if (*msgs >= 0x20 && *msgs < 0x7F)
                *vpicg = *msgs;
            *msgs++;
        }
    }
}

//-----------------------------------------------------------------------------
void writecxy(unsigned char sizef, unsigned char pbyte, unsigned short pcolor, unsigned short pbcolor) {
    *vpicg = 0x0B;
    *vpicg = 0xD2;
    *vpicg = *pposx >> 8;
    *vpicg = *pposx;
    *vpicg = *pposy >> 8;
    *vpicg = *pposy;
    *vpicg = sizef;
    *vpicg = pcolor >> 8;
    *vpicg = pcolor;
    *vpicg = pbcolor >> 8;
    *vpicg = pbcolor;
    *vpicg = pbyte;

    *pposx = *pposx + sizef;

    if ((*pposx + sizef) > *vxgmax)
        *pposx = *pposx - sizef;
}

//-----------------------------------------------------------------------------
void locatexy(unsigned short xx, unsigned short yy) {
    *pposx = xx;
    *pposy = yy;
}

//-----------------------------------------------------------------------------
void SaveScreen(unsigned short xi, unsigned short yi, unsigned short pwidth, unsigned short pheight) {
    *vpicg = 9;
    *vpicg = 0xEA;
    *vpicg = xi >> 8;
    *vpicg = xi;
    *vpicg = yi >> 8;
    *vpicg = yi;
    *vpicg = pwidth >> 8;
    *vpicg = pwidth;
    *vpicg = pheight >> 8;
    *vpicg = pheight;
}

//-----------------------------------------------------------------------------
void RestoreScreen(unsigned short xi, unsigned short yi, unsigned short pwidth, unsigned short pheight) {
    *vpicg = 9;
    *vpicg = 0xEB;
    *vpicg = xi >> 8;
    *vpicg = xi;
    *vpicg = yi >> 8;
    *vpicg = yi;
    *vpicg = pwidth >> 8;
    *vpicg = pwidth;
    *vpicg = pheight >> 8;
    *vpicg = pheight;
}

//-----------------------------------------------------------------------------
void SetDot(unsigned short x, unsigned short y, unsigned short color) {
    *vpicg = 9;
    *vpicg = 0xD7;
    *vpicg = x >> 8;
    *vpicg = x;
    *vpicg = y >> 8;
    *vpicg = y;
    *vpicg = pzero;
    *vpicg = color >> 8;
    *vpicg = color;
}

//-----------------------------------------------------------------------------
void FillRect(unsigned short xi, unsigned short yi, unsigned short pwidth, unsigned short pheight, unsigned short pcor) {
    unsigned short xf, yf;

    xf = (xi + pwidth);
    yf = (yi + pheight);
    *vpicg = 11;
    *vpicg = 0xD3;
    *vpicg = xi >> 8;
    *vpicg = xi;
    *vpicg = yi >> 8;
    *vpicg = yi;
    *vpicg = pwidth >> 8;
    *vpicg = pwidth;
    *vpicg = pheight >> 8;
    *vpicg = pheight;
    *vpicg = pcor >> 8;
    *vpicg = pcor;
}

//-----------------------------------------------------------------------------
void DrawLine(unsigned short x1, unsigned short y1, unsigned short x2, unsigned short y2, unsigned short color) {
    *vpicg = 11;
    *vpicg = 0xD4;
    *vpicg = x1 >> 8;
    *vpicg = x1;
    *vpicg = y1 >> 8;
    *vpicg = y1;
    *vpicg = x2 >> 8;
    *vpicg = x2;
    *vpicg = y2 >> 8;
    *vpicg = y2;
    *vpicg = color >> 8;
    *vpicg = color;
}

//-----------------------------------------------------------------------------
void DrawRect(unsigned short xi, unsigned short yi, unsigned short pwidth, unsigned short pheight, unsigned short color) {
    unsigned short xf, yf;

    xf = (xi + pwidth);
    yf = (yi + pheight);

    *vpicg = 11;
    *vpicg = 0xD5;
    *vpicg = xi >> 8;
    *vpicg = xi;
    *vpicg = yi >> 8;
    *vpicg = yi;
    *vpicg = pwidth >> 8;
    *vpicg = pwidth;
    *vpicg = pheight >> 8;
    *vpicg = pheight;
    *vpicg = color >> 8;
    *vpicg = color;
}

//-----------------------------------------------------------------------------
void DrawRoundRect(void) {
    unsigned short xi, yi, pwidth, pheight, color;
	unsigned char radius;
	unsigned short tSwitch, x1 = 0, y1, xt, yt, wt;

    xi = vparam[0];
    yi = vparam[1];
    pwidth = vparam[2];
    pheight = vparam[3];
    radius = vparam[4];
    color = vparam[5];

    y1 = radius;

	tSwitch = 3 - 2 * radius;

	while (x1 <= y1) {
	    xt = xi + radius - x1;
	    yt = yi + radius - y1;
	    SetDot(xt, yt, color);

	    xt = xi + radius - y1;
	    yt = yi + radius - x1;
	    SetDot(xt, yt, color);

        xt = xi + pwidth-radius + x1;
	    yt = yi + radius - y1;
	    SetDot(xt, yt, color);

        xt = xi + pwidth-radius + y1;
	    yt = yi + radius - x1;
	    SetDot(xt, yt, color);

        xt = xi + pwidth-radius + x1;
        yt = yi + pheight-radius + y1;
	    SetDot(xt, yt, color);

        xt = xi + pwidth-radius + y1;
        yt = yi + pheight-radius + x1;
	    SetDot(xt, yt, color);

	    xt = xi + radius - x1;
        yt = yi + pheight-radius + y1;
	    SetDot(xt, yt, color);

	    xt = xi + radius - y1;
        yt = yi + pheight-radius + x1;
	    SetDot(xt, yt, color);

	    if (tSwitch < 0) {
	    	tSwitch += (4 * x1 + 6);
	    } else {
	    	tSwitch += (4 * (x1 - y1) + 10);
	    	y1--;
	    }
	    x1++;
	}

    xt = xi + radius;
    yt = yi + pheight;
    wt = pwidth - (2 * radius);
	DrawHoriLine(xt, yi, wt, color);		// top
	DrawHoriLine(xt, yt, wt, color);	// bottom

    xt = xi + pwidth;
    yt = yi + radius;
    wt = pheight - (2 * radius);
	DrawVertLine(xi, yt, wt, color);		// left
	DrawVertLine(xt, yt, wt, color);	// right
}

//-----------------------------------------------------------------------------
void DrawCircle(unsigned short xi, unsigned short yi, unsigned char pang, unsigned char pfil, unsigned short pcor) 
{
    *vpicg = 10;
    *vpicg = 0xD6;
    *vpicg = xi >> 8;
    *vpicg = xi;
    *vpicg = yi >> 8;
    *vpicg = yi;
    *vpicg = pang;
    *vpicg = pfil;
    *vpicg = pzero;
    *vpicg = pcor >> 8;
    *vpicg = pcor;
}

//-----------------------------------------------------------------------------
void InvertRect(unsigned short x, unsigned short y, unsigned short pwidth, unsigned short pheight) {
    *vpicg = 9;
    *vpicg = 0xEC;
    *vpicg = x >> 8;
    *vpicg = x;
    *vpicg = y >> 8;
    *vpicg = y;
    *vpicg = pheight >> 8;
    *vpicg = pheight;
    *vpicg = pwidth >> 8;
    *vpicg = pwidth;
}

//-----------------------------------------------------------------------------
void SelRect(unsigned short x, unsigned short y, unsigned short pwidth, unsigned short pheight) 
{
    DrawRect((x - 1), (y - 1), (pwidth + 2), (pheight + 2), Red);
}

//-----------------------------------------------------------------------------
void PutImage(unsigned char* cimage, unsigned short x, unsigned short y) 
{
    unsigned char *ss = cimage;
    unsigned char ix = 0;

    while (*ss)
    {
        if (*ss >= 0x20 && *ss < 0x7F) 
            ix++;        
        *ss++;
    }

    ix += 5;
    *vpicg = ix;
    *vpicg = 0xC0;
    *vpicg = x >> 8;
    *vpicg = x & 0x00FF;
    *vpicg = y >> 8;
    *vpicg = y & 0x00FF;

    while (*cimage) 
    {
        if (*cimage >= 0x20 && *cimage < 0x7F) 
            *vpicg = *cimage;
        *cimage++;
    }
}

//-----------------------------------------------------------------------------
void LoadIconLib(unsigned char* cfile) 
{
    unsigned char *ss = cfile;
    unsigned char ix = 0;

    while (*ss)
    {
        if (*ss >= 0x20 && *ss < 0x7F) 
            ix++;        
        *ss++;
    }

    ix += 1;
    *vpicg = ix;
    *vpicg = 0xC1;

    while (*cfile) 
    {
        if (*cfile >= 0x20 && *cfile < 0x7F) 
            *vpicg = *cfile;
        *cfile++;
    }
}

//-----------------------------------------------------------------------------
void PutIcone(unsigned int* vimage, unsigned short x, unsigned short y, unsigned char numSprite) 
{
    // Verificando se essa função ainda tem um uso
}

//-----------------------------------------------------------------------------
void startMGI(void) {
    unsigned char vnomefile[12];
    unsigned char lc, ll, *ptr_ico, *ptr_prg, *ptr_pos;
    unsigned char* vFinalOSPos;
    int percent;
    unsigned char sqtdtam[10];

    desativaCursor();

    ptr_pos = vFinalOS + (MEM_POS_MGICFG + 16);
    ptr_ico = ptr_pos + 32;
    ptr_prg = ptr_ico + 320;

    for (lc = 0; lc <= 31; lc++) {
        *ptr_pos++ = 0x00;
        for (ll = 0; ll <= 9; ll++) {
            *ptr_ico++ = 0x00;
            *ptr_prg++ = 0x00;
        }
    }

    *vkeyopen = 0;
    *voutput = 2;

    *vpicg = 2;
    *vpicg = 0xDA;
    *vpicg = *voutput;

    *vcorwf = White;
    *vcorwb = Blue;

    vparamstr[0] = '\0';
    vparam[0] = 70;
    vparam[1] = 40;
    vparam[2] = 320;
    vparam[3] = 240;
    vparam[4] = BTNONE;
    
    showWindow();

    writesxy(190,75,2,"MGI",*vcorwf,*vcorwb);
    writesxy(124,95,1,"Graphical Interface",*vcorwf,*vcorwb);
    writesxy(144,270,1,"Please Wait...",*vcorwf,*vcorwb);

    writesxy(136,155,1,"Loading Config",*vcorwf,*vcorwb);
    vFinalOSPos = vFinalOS + MEM_POS_MGICFG;
    _strcat(vnomefile,"MMSJMGI",".CFG");
    loadFile(vnomefile, (unsigned long*)vFinalOSPos);

    FillRect(136,135,200,30,*vcorwb);
    writesxy(136,155,1,"Loading Icons.",*vcorwf,*vcorwb);

    redrawMain();

    while(editortela());

    *voutput = 1;
    *vcol = 0;
    *vlin = 0;
    *voverx = 0;
    *vovery = 0;
    *vxmaxold = 0;
    *vymaxold = 0;

    *vpicg = 2;
    *vpicg = 0xDA;
    *vpicg = *voutput;

    clearScr();

    ativaCursor();
}

//-----------------------------------------------------------------------------
void redrawMain(void) {
    clearScr(Blue);

    // Define que só será enviado dados de video. Para todas as outras funções até concluir
    *vpicg = 0x02;
    *vpicg = 0xED;
    *vpicg = 0x01;

    // Desenhar Barra Menu Principal / Status
    desenhaMenu();

    PutImage("utility.bmp",72,100);

    // Desenhar Icones da tela (lendo do disco)
//    desenhaIconesUsuario();

    // Volta ao normal do controlador
    *vpicg = 0x02;
    *vpicg = 0xED;
    *vpicg = pzero;
}

//-----------------------------------------------------------------------------
void desenhaMenu(void) {
    unsigned char lc;
    unsigned int vx, vy;

    vx = COLMENU;
    vy = LINMENU;

    for (lc = 0; lc <= 6; lc++) 
    {
        MostraIcone(vx, vy, lc);
        vx += 60;
    }

    FillRect(0, (*vygmax - 35), *vxgmax, 35, l_gray);
}

//-----------------------------------------------------------------------------
void desenhaIconesUsuario(void) {
  unsigned short vx, vy;
  unsigned char lc, lcok, *ptr_ico, *ptr_prg, *ptr_pos;

  // COLOCAR ICONSPERLINE = 10
  // COLOCAR SPACEICONS = 8

  *next_pos = 0;

  ptr_pos = vFinalOS + (MEM_POS_MGICFG + 16);
  ptr_ico = ptr_pos + 32;
  ptr_prg = ptr_ico + 320;

  for(lc = 0; lc <= (ICONSPERLINE * 4 - 1); lc++) {
    ptr_pos = ptr_pos + lc;
    ptr_ico = ptr_ico + (lc * 10);
    ptr_prg = ptr_prg + (lc * 10);

    if (*ptr_prg != 0 && *ptr_ico != 0) {
      if (*ptr_pos <= (ICONSPERLINE - 1)) {
        vx = COLINIICONS + (24 + SPACEICONS) * *ptr_pos;
        vy = 40;
      }
      else if (*ptr_pos <= (ICONSPERLINE * 2 - 1)) {
        vx = COLINIICONS + (24 + SPACEICONS) * (*ptr_pos - ICONSPERLINE);
        vy = 72;
      }
      else if (*ptr_pos <= (ICONSPERLINE * 3 - 1)) {
        vx = COLINIICONS + (24 + SPACEICONS) * (*ptr_pos - ICONSPERLINE);
        vy = 104;
      }
      else {
        vx = COLINIICONS + (24 + SPACEICONS) * (*ptr_pos - ICONSPERLINE * 2);
        vy = 136;
      }

      lcok = lc + 20;

      SendIcone(lcok);
      MostraIcone(vx, vy, lcok);

      *next_pos = *next_pos + 1;
    }
  }
}

//-----------------------------------------------------------------------------
void SendIcone_24x24(unsigned char vicone)
{
    unsigned char vnomefile[12];
    unsigned char *ptr_prg;
    unsigned long *ptr_viconef;
    unsigned short ix, iy, iz, pw, ph;
    unsigned char* pimage;
    unsigned char ic;

    ptr_prg = vFinalOS + (MEM_POS_MGICFG + 16) + 32 + 320;

    // Procura Icone no Disco se Nao for Padrao
    if (vicone >= 20) 
    {
        vicone -= 20;
        ptr_prg = ptr_prg + (vicone * 10);
        _strcat(vnomefile,*ptr_prg,".ICO");
        loadFile(vnomefile, (unsigned long*)0x00FF9FF8);   // 12K espaco pra carregar arquivo. Colocar logica pra pegar tamanho e alocar espaco
        vicone += 20;
        if (*verro)
            vicone = 9;
        else
            ptr_viconef = viconef;
    }

    if (vicone < 20) 
        ptr_viconef = vFinalOS + (MEM_POS_ICONES + (1152 * vicone));

    ic = 0;
    iz = 0;
    pw = 24;      
    ph = 24;
    pimage = ptr_viconef;

    // Acumula dados, enviando em 9 vezes de 64 x 16 bits
    *vpicg = 0x04;
    *vpicg = 0xDE;
    *vpicg = pw;
    *vpicg = ph;
    *vpicg = vicone;

    *vpicg = 130;
    *vpicg = 0xDE;
    *vpicg = ic;

    for (ix = 0; ix < 576; ix++) 
    {
        *vpicg = *pimage++ & 0x00FF;
        *vpicg = *pimage++ & 0x00FF;
        iz++;

        if (iz == 64 && ic < 8) 
        {
            ic++;

            *vpicg = 130;
            *vpicg = 0xDE;
            *vpicg = ic;

            iz = 0;
        }
    }
}

//-----------------------------------------------------------------------------
void SendIcone(unsigned char vicone)
{
    unsigned char vnomefile[12];
    unsigned char *ptr_prg;
    unsigned long *ptr_viconef;
    unsigned short ix, iy, iz, pw, ph;
    unsigned char* pimage;
    unsigned char ic;

    ptr_prg = vFinalOS + (MEM_POS_MGICFG + 16) + 32 + 320;

    // Procura Icone no Disco se Nao for Padrao
    if (vicone >= 20) 
    {
        vicone -= 20;
        ptr_prg = ptr_prg + (vicone * 10);
        _strcat(vnomefile,*ptr_prg,".ICO");
        loadFile(vnomefile, (unsigned long*)0x00FF9FF8);   // 12K espaco pra carregar arquivo. Colocar logica pra pegar tamanho e alocar espaco
        vicone += 20;
        if (*verro)
            vicone = 9;
        else
            ptr_viconef = viconef;
    }

    if (vicone < 20) 
        ptr_viconef = vFinalOS + (MEM_POS_ICONES + (4608 * vicone));

    ic = 0;
    iz = 0;
    pw = 48;      
    ph = 48;
    pimage = ptr_viconef;

    // Acumula dados, enviando em 36 vezes de 64 x 16 bits
    *vpicg = 0x04;
    *vpicg = 0xDE;
    *vpicg = pw;
    *vpicg = ph;
    *vpicg = vicone;

    *vpicg = 130;
    *vpicg = 0xDE;
    *vpicg = ic;

    for (ix = 0; ix < 2304; ix++) 
    {
        *vpicg = *pimage++ & 0x00FF;
        *vpicg = *pimage++ & 0x00FF;
        iz++;

        if (iz == 64 && ic < 35) 
        {
            ic++;

            *vpicg = 130;
            *vpicg = 0xDE;
            *vpicg = ic;

            iz = 0;
        }
    }
}

//-----------------------------------------------------------------------------
void MostraIcone(unsigned short vvx, unsigned short vvy, unsigned char vicone) 
{
    unsigned short pw = 48, ph = 48;

    // Mostra a Imagem
    *vpicg = 10;
    *vpicg = 0xDF;
    *vpicg = vvx >> 8;
    *vpicg = vvx;
    *vpicg = vvy >> 8;
    *vpicg = vvy;
    *vpicg = pw >> 8;
    *vpicg = pw;
    *vpicg = ph >> 8;
    *vpicg = ph;
    *vpicg = vicone;
}

//--------------------------------------------------------------------------
unsigned char editortela(void) {
    unsigned char vresp = 1;
    unsigned char vx, cc, vpos, vposiconx, vposicony;
    unsigned short vbytepic;
    unsigned char *ptr_prg;

    VerifyTouchLcd(WHAITTOUCH);

    if (*vposty <= 30)
        vresp = new_menu();
    else {
        vposiconx = COLINIICONS;
        vposicony = 40;
        vpos = 0;

        if (*vposty >= 136) {
            vpos = ICONSPERLINE * 3;
            vposicony = 136;
        }
        else if (*vposty >= 30) {
            vpos = ICONSPERLINE * 2;
            vposicony = 104;
        }
        else if (*vposty >= 30) {
            vpos = ICONSPERLINE;
            vposicony = 72;
        }

        if (*vpostx >= COLINIICONS && *vpostx <= (COLINIICONS + (24 + SPACEICONS) * ICONSPERLINE) && *vposty >= 40) {
          cc = 1;
          for(vx = (COLINIICONS + (24 + SPACEICONS) * (ICONSPERLINE - 1)); vx >= (COLINIICONS + (24 + SPACEICONS)); vx -= (24 + SPACEICONS)) {
            if (*vpostx >= vx) {
              vpos += ICONSPERLINE - cc;
              vposiconx = vx;
              break;
            }

            cc++;
          }

          ptr_prg = vFinalOS + (MEM_POS_MGICFG + 16) + 32 + 320;
          ptr_prg = ptr_prg + (vpos * 10);

          if (*ptr_prg != 0) {
            InvertRect( vposiconx, vposicony, 24, 24);

            strcpy(vbuf,ptr_prg);

            MostraIcone(144, 104, ICON_HOURGLASS);  // Mostra Ampulheta

            processCmd();

            *vbuf = 0x00;

            redrawMain();
          }
        }
    }

    return vresp;
}

//-------------------------------------------------------------------------
unsigned char new_menu(void) {
    unsigned short vx, vy, lc, vposicony, mx, my, menyi[8], menyf[8];
    unsigned char vpos = 0, vresp, mpos;

    vresp = 1;

    if (*vpostx >= COLMENU && *vpostx <= (COLMENU + 24)) {
        mx = 0;
        my = LINHAMENU;
        mpos = 0;

        FillRect(mx,my,128,42,White);
        DrawRect(mx,my,128,42,Black);

        mpos += 2;
        menyi[0] = my + mpos;
        writesxy(mx + 8,my + mpos,1,"Format",Black,White);
        mpos += 12;
        menyf[0] = my + mpos;
        DrawLine(mx,my + mpos,mx+128,my + mpos,Black);

        mpos += 2;
        menyi[1] = my + mpos;
        writesxy(mx + 8,my + mpos,1,"Help",Black,White);
        mpos += 12;
        menyf[1] = my + mpos;
        mpos += 2;
        menyi[2] = my + mpos;
        writesxy(mx + 8,my + mpos,1,"About",Black,White);
        mpos += 12;
        menyf[2] = my + mpos;
        DrawLine(mx,my + mpos,mx+128,my + mpos,Black);

        VerifyTouchLcd(WHAITTOUCH);

        if ((*vposty >= my && *vposty <= my + 42) && (*vpostx >= mx && *vpostx <= mx + 128)) {
            vpos = 0;
            vposicony = 0;

            for(vy = 0; vy <= 1; vy++) {
                if (*vposty >= menyi[vy] && *vposty <= menyf[vy]) {
                    vposicony = menyi[vy];
                    break;
                }

                vpos++;
            }

            if (vposicony > 0)
                InvertRect( mx + 4, vposicony, 120, 12);

            switch (vpos) {
                case 0: // Format
/*                    strcpy(vbuf,"FORMAT\0");

                    MostraIcone(144, 104, ICON_HOURGLASS);  // Mostra Ampulheta

                    processCmd();

                    *vbuf = 0x00;*/
                    break;
                case 1: // Help
                    break;
                case 2: // About
                    message("MGUI v0.1\nGraphical User Interface\n \nwww.utilityinf.com.br\0", BTCLOSE, 0);
                    break;
            }
        }

        redrawMain();
    }
    else {
        for (lc = 1; lc <= 6; lc++) {
            mx = COLMENU + (32 * lc);
            if (*vpostx >= mx && *vpostx <= (mx + 24)) {
                InvertRect( mx, 4, 24, 24);
                InvertRect( mx, 4, 24, 24);
                break;
            }
        }

        switch (lc) {
            case 1: // RUN
                executeCmd();
                break;
            case 2: // NEW ICON
                break;
            case 3: // DEL ICON
                break;
            case 4: // MMSJDOS
                strcpy(vbuf,"MDOS\0");

                MostraIcone(144, 104, ICON_HOURGLASS);

                processCmd();

                *vbuf = 0x00;

                break;
            case 5: // SETUP
                break;
            case 6: // EXIT
                mpos = message("Deseja Sair ?\0", BTYES | BTNO, 0);
                if (mpos == BTYES)
                    vresp = 0;
                else
                    redrawMain();

                break;
        }

        if (lc < 6)
            redrawMain();
    }

    return vresp;
}

//------------------------------------------------------------------------
void VerifyMouse(unsigned char vtipo) {
}

//-------------------------------------------------------------------------
void new_icon(void) {
}

//-------------------------------------------------------------------------
void del_icon(void) {
}

//-------------------------------------------------------------------------
void mgi_setup(void) {
}

//-------------------------------------------------------------------------
void executeCmd(void) {
    unsigned char vstring[64], vwb;

    vstring[0] = '\0';

    strcpy(vparamstr,"Execute");
    vparam[0] = 10;
    vparam[1] = 40;
    vparam[2] = 280;
    vparam[3] = 50;
    vparam[4] = BTOK | BTCANCEL;
    showWindow();

    writesxy(12,55,1,"Execute:",*vcorwf,*vcorwb);
    fillin(vstring, 84, 55, 160, WINDISP);

    while (1) {
        fillin(vstring, 84, 55, 160, WINOPER);

        vwb = waitButton();

        if (vwb == BTOK || vwb == BTCANCEL)
            break;
    }

    if (vwb == BTOK) {
        strcpy(vbuf, vstring);

        MostraIcone(144, 104, ICON_HOURGLASS);  // Mostra Ampulheta

        // Chama processador de comandos
        processCmd();

        while (*vxmaxold != 0) {
            vwb = waitButton();

            if (vwb == BTCLOSE)
                break;
        }

        if (*vxmaxold != 0) {
            *vxmax = *vxmaxold;
            *vymax = *vymaxold;
            *vcol = 0;
            *vlin = 0;
            *voverx = 0;
            *vovery = 0;
            *vxmaxold = 0;
            *vymaxold = 0;
        }

        *vbuf = 0x00;  // Zera Buffer do teclado
    }
}

//-------------------------------------------------------------------------
unsigned char message(char* bstr, unsigned char bbutton, unsigned short btime)
{
	unsigned short i, ii, iii, xi, yi, xf, xm, yf, ym, pwidth, pheight, xib, yib, xic, yic;
	unsigned char qtdnl, maxlenstr;
	unsigned char qtdcstr[8], poscstr[8], cc, dd, vbty = 0;
	unsigned char *bstrptr;
	qtdnl = 1;
	maxlenstr = 0;
	qtdcstr[1] = 0;
	poscstr[1] = 0;
	i = 0;

    for (ii = 0; ii <= 7; ii++)
        vbuttonwin[ii] = 0;

    bstrptr = bstr;
	while (*bstrptr)
	{
		qtdcstr[qtdnl]++;

		if (qtdcstr[qtdnl] > 26)
			qtdcstr[qtdnl] = 26;

		if (qtdcstr[qtdnl] > maxlenstr)
			maxlenstr = qtdcstr[qtdnl];

		if (*bstrptr == '\n')
		{
			qtdcstr[qtdnl]--;
			qtdnl++;

			if (qtdnl > 6)
				qtdnl = 6;

			qtdcstr[qtdnl] = 0;
			poscstr[qtdnl] = i + 1;
		}

        bstrptr++;
        i++;
	}

	if (maxlenstr > 26)
		maxlenstr = 26;

	if (qtdnl > 6)
		qtdnl = 6;

	pwidth = maxlenstr * 8;
	pwidth = pwidth + 2;
	xm = pwidth / 2;
	xi = 160 - xm - 1;
	xf = 160 + xm - 1;

	pheight = 10 * qtdnl;
	pheight = pheight + 20;
	ym = pheight / 2;
	yi = 120 - ym - 1;
	yf = 120 + ym - 1;

	// Desenha Linha Fora
    SaveScreen(xi+2,yi,pwidth,pheight);

    FillRect(xi,yi,pwidth,pheight,White);
    vparam[0] = xi;
    vparam[1] = yi;
    vparam[2] = pwidth;
    vparam[3] = pheight;
    vparam[4] = 2;
    vparam[5] = Black;
	DrawRoundRect();  // rounded rectangle around text area

	// Escreve Texto Dentro da Caixa de Mensagem
	for (i = 1; i <= qtdnl; i++)
	{
		xib = xi + xm;
		xib = xib - ((qtdcstr[i] * 8) / 2);
		yib = yi + 2 + (10 * (i - 1));

        locatexy(xib, yib);
        bstrptr = bstr + poscstr[i];
		for (ii = poscstr[i]; ii <= (poscstr[i] + qtdcstr[i] - 1) ; ii++)
            writecxy(1, *bstrptr++, Black, White);
	}

	// Desenha Botoes
    i = 1;
    *vbbutton = bbutton;
	while (*vbbutton)
	{
		xib = xi + 2 + (44 * (i - 1));
		yib = yf - 12;
        vbty = yib;
		i++;

        drawButtons(xib, yib);
	}

  ii = 0;

  if (!btime) {
    while (!ii) {
  	  VerifyTouchLcd(WHAITTOUCH);

      for (i = 1; i <= 7; i++) {
        if (vbuttonwin[i] != 0 && *vpostx >= vbuttonwin[i] && *vpostx <= (vbuttonwin[i] + 32) && *vposty >= vbty && *vposty <= (vbty + 10)) {
          ii = 1;

          for (iii = 1; iii <= (i - 1); iii++)
            ii *= 2;

          break;
        }
      }
    }
  }
  else {
    for (dd = 0; dd <= 10; dd++)
      for (cc = 0; cc <= btime; cc++);
  }

  RestoreScreen(xi+2,yi,pwidth,pheight);

  return ii;
}

//-------------------------------------------------------------------------
void showWindow(void)
{
	unsigned short i, ii, xib, yib, x1, y1, pwidth, pheight;
    unsigned char cc = 0, sqtdtam[10], *bstr, bbutton;

    bstr = vparamstr;
    x1 = vparam[0];
    y1 = vparam[1];
    pwidth = vparam[2];
    pheight = vparam[3];
    bbutton = vparam[4];

    // Desenha a Janela
	FillRect(x1, y1, pwidth, pheight, *vcorwb);
    DrawRect(x1, y1, pwidth, pheight, *vcorwf);

    if (*bstr) {
        DrawRect(x1, y1, pwidth, 12, *vcorwf);
        writesxy(x1 + 2, y1 + 3,1,bstr,*vcorwf,*vcorwb);
    }

    i = 1;
    for (ii = 0; ii <= 7; ii++)
        vbuttonwin[ii] = 0;

	// Desenha Botoes
    *vbbutton = bbutton;
	while (*vbbutton)
	{
		xib = x1 + 2 + (44 * (i - 1));
		yib = (y1 + pheight) - 12;
        vbuttonwiny = yib;
		i++;

        drawButtons(xib, yib);
	}
}

//-------------------------------------------------------------------------
void drawButtons(unsigned short xib, unsigned short yib) {
    // Desenha Bot?
    vparam[0] = xib;
    vparam[1] = yib;
    vparam[2] = 42;
    vparam[3] = 10;
    vparam[4] = 1;
    vparam[5] = Black;
	FillRect(xib, yib, 42, 10, White);
	DrawRoundRect();  // rounded rectangle around text area

	// Escreve Texto do Bot?
	if (*vbbutton & BTOK)
	{
		writesxy(xib + 16 - 6, yib + 2,1,"OK",Black,White);
        *vbbutton = *vbbutton & 0xFE;    // 0b11111110
        vbuttonwin[1] = xib;
	}
	else if (*vbbutton & BTSTART)
	{
		writesxy(xib + 16 - 15, yib + 2,1,"START",Black,White);
        *vbbutton = *vbbutton & 0xDF;    // 0b11011111
        vbuttonwin[6] = xib;
	}
	else if (*vbbutton & BTCLOSE)
	{
		writesxy(xib + 16 - 15, yib + 2,1,"CLOSE",Black,White);
        *vbbutton = *vbbutton & 0xBF;    // 0b10111111
        vbuttonwin[7] = xib;
	}
	else if (*vbbutton & BTCANCEL)
	{
		writesxy(xib + 16 - 12, yib + 2,1,"CANC",Black,White);
        *vbbutton = *vbbutton & 0xFD;    // 0b11111101
        vbuttonwin[2] = xib;
	}
	else if (*vbbutton & BTYES)
	{
		writesxy(xib + 16 - 9, yib + 2,1,"YES",Black,White);
        *vbbutton = *vbbutton & 0xFB;    // 0b11111011
        vbuttonwin[3] = xib;
	}
	else if (*vbbutton & BTNO)
	{
		writesxy(xib + 16 - 6, yib + 2,1,"NO",Black,White);
        *vbbutton = *vbbutton & 0xF7;    // 0b11110111
        vbuttonwin[4] = xib;
	}
	else if (*vbbutton & BTHELP)
	{
		writesxy(xib + 16 - 12, yib + 2,1,"HELP",Black,White);
        *vbbutton = *vbbutton & 0xEF;    // 0b11101111
        vbuttonwin[5] = xib;
	}
}

//-------------------------------------------------------------------------
unsigned char waitButton(void) {
  unsigned char i, ii, iii;
  ii = 0;
  VerifyTouchLcd(WHAITTOUCH);

  for (i = 1; i <= 7; i++) {
    if (vbuttonwin[i] != 0 && *vpostx >= vbuttonwin[i] && *vpostx <= (vbuttonwin[i] + 32) && *vposty >= vbuttonwiny && *vposty <= (vbuttonwiny + 10)) {
      ii = 1;

      for (iii = 1; iii <= (i - 1); iii++)
        ii *= 2;

      break;
    }
  }

  return ii;
}

//-------------------------------------------------------------------------
void fillin(unsigned char* vvar, unsigned short x, unsigned short y, unsigned short pwidth, unsigned char vtipo)
{
    unsigned short cc = 0;
    unsigned char cchar, *vvarptr, vdisp = 0;

    vvarptr = vvar;

    while (*vvarptr) {
        cc += 8;
        *vvarptr++;
    }

    if (vtipo == WINOPER) {
        if (!*vkeyopen && *vpostx >= x && *vpostx <= (x + pwidth) && *vposty >= y && *vposty <= (y + 10)) {
            *vkeyopen = 0x01;
            if (!*vPS2)
                funcKey(1,1, 0, 0,x,y+12);
        }

        if (*vbytetec == 0xFF) {
            if (*vkeyopen && (*vpostx < x || *vpostx > (x + pwidth) || *vposty < y || *vposty > (y + 10))) {
                *vkeyopen = 0x00;
                if (!*vPS2)
                    funcKey(1,2, 0, 0,x,y+12);
            }
        }
        else {
            if (*vbytetec >= 0x20 && *vbytetec < 0x7F && (x + cc + 8) < (x + pwidth)) {
                *vvarptr++ = *vbytetec;
                *vvarptr = 0x00;

                locatexy(x+cc+2,y+2);
                writecxy(1, *vbytetec, Black, White);

                vdisp = 1;
            }
            else {
                switch (*vbytetec) {
                    case 0x0D:  // Enter ou Tecla END
                        if (vkeyopen) {
                            *vkeyopen = 0x00;
                            if (!*vPS2)
                                funcKey(1,2, 0, 0,x,y+12);
                        }
                        break;
                #ifdef __USE_VGA__
                    case 0x7F:  // BackSpace VGA/PS2
                #else
                    case 0x08:  // BackSpace TFT
                #endif
                        if (*pposx > (x + 10)) {
                            *vvarptr = '\0';
                            vvarptr--;
                            if (vvarptr < vvar)
                                vvarptr = vvar;
                            *vvarptr = '\0';
                            *pposx = *pposx - 8;
                            locate(*vcol,*vlin, NOREPOS_CURSOR);
                            writecxy(1, 0x08, Black, White);
                            *pposx = *pposx - 8;
                        }
                        break;
                }
            }
        }
    }

    if (vtipo == WINDISP || vdisp) {
        if (!vdisp) {
            DrawRect(x,y,pwidth,10,Black);
            FillRect(x+1,y+1,pwidth-2,8,White);
        }

        vvarptr = vvar;
        locatexy(x+2,y+2);
        while (*vvarptr) {
            cchar = *vvarptr++;
            cc++;

            writecxy(1, cchar, Black, White);

            if (*pposx >= x + pwidth)
                break;
        }
    }
}

//-------------------------------------------------------------------------
void radioset(unsigned char* vopt, unsigned char *vvar, unsigned short x, unsigned short y, unsigned char vtipo) {
  unsigned char cc, xc;
  unsigned char cchar, vdisp = 0;

  xc = 0;
  cc = 0;
  cchar = ' ';

  while(vtipo == WINOPER && cchar != '\0') {
    cchar = vopt[cc];
    if (cchar == ',') {
      if (cchar == ',' && cc != 0)
        xc++;

      if (*vpostx >= x && *vpostx <= x + 8 && *vposty >= (y + (xc * 10)) && *vposty <= ((y + (xc * 10)) + 8)) {
        vvar[0] = xc;
        vdisp = 1;
      }
    }

    cc++;
  }

  xc = 0;
  cc = 0;

  while(vtipo == WINDISP || vdisp) {
    cchar = vopt[cc];

    if (cchar == ',') {
      if (cchar == ',' && cc != 0)
        xc++;

      FillRect(x, y + (xc * 10), 8, 8, White);
      DrawCircle(x + 4, y + (xc * 10) + 2, 4, 0, Black);

      if (vvar[0] == xc)
        DrawCircle(x + 4, y + (xc * 10) + 2, 3, 1, Black);
      else
        DrawCircle(x + 4, y + (xc * 10) + 2, 3, 0, Black);

      locatexy(x + 10, y + (xc * 10));
    }

    if (cchar != ',' && cchar != '\0')
      writecxy(1, cchar, Black, White);

    if (cchar == '\0')
      break;

    cc++;
  }
}

//-------------------------------------------------------------------------
void togglebox(unsigned char* bstr, unsigned char *vvar, unsigned short x, unsigned short y, unsigned char vtipo) {
  unsigned char cc = 0;
  unsigned char cchar, vdisp = 0;

  if (vtipo == WINOPER && *vpostx >= x && *vpostx <= x + 4 && *vposty >= y && *vposty <= y + 4) {
    if (vvar[0])
      vvar[0] = 0;
    else
      vvar[0] = 1;

    vdisp = 1;
  }

  if (vtipo == WINDISP || vdisp) {
    FillRect(x, y + 2, 4, 4, White);
    DrawRect(x, y + 2, 4, 4, Black);

    if (vvar[0]) {
      DrawLine(x, y + 2, x + 4, y + 6, Black);
      DrawLine(x, y + 6, x + 4, y + 2, Black);
    }

    if (vtipo == WINDISP) {
      x += 6;
      locatexy(x,y);
      while (bstr[cc] != 0) {
        cchar = bstr[cc];
        cc++;

        writecxy(1, cchar, Black, White);
        x += 6;
      }
    }
  }
}


//-------------------------------------------------------------------------
void combobox(unsigned char* vopt, unsigned char *vvar,unsigned char x, unsigned char y, unsigned char vtipo) {
}

//-------------------------------------------------------------------------
void editor(unsigned char* vtexto, unsigned char *vvar,unsigned char x, unsigned char y, unsigned char vtipo) {
}