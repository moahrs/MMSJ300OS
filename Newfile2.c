//-----------------------------------------------------------------------------
void clearScr(WORD pcolor) {
    *vpicg = 2;
    *vpicg = 0xD0;
    *vpicg = pcolor;

    locateScr(0,0);
}

//-----------------------------------------------------------------------------
void printStrScr(BYTE *msgs, WORD pcolor, WORD pbcolor) {
    BYTE ix = 10;
    BYTE *ss = msgs;

    while (*ss != 0x00) {
      if (*ss >= 0x20)
          ix++;

      *ss++;
    }

    #ifdef _USE_VIDEO_
        if (ix > 10) {
            // Manda Sequencia e Controle
            *vpicg = ix;
            *vpicg = 0xD1;
            *vpicg = (*vcol * 8) >> 8;
            *vpicg = *vcol * 8;
            *vpicg = (*vlin * 10) >> 8;
            *vpicg = *vlin * 10;
            *vpicg = 8;
            *vpicg = pcolor >> 8;
            *vpicg = pcolor;
            *vpicg = pbcolor >> 8;
            *vpicg = pbcolor;
        }
    #endif

    while (*msgs != 0x00) {
        if (*msgs >= 0x20) {
            *vpicg = *msgs;
            *vcol = *vcol + 1;
        }
        else {
            if (*msgs == 0x0A) {
                *vlin = *vlin + 1;
                *vcol = 0;
            }

            locateScr(*vcol, *vlin);
        }

        *msgs++;
    }
}

//-----------------------------------------------------------------------------
void printByteScr(BYTE pbyte, WORD pcolor, WORD pbcolor) {
    *vpicg = 0x0B;
    *vpicg = 0xD2;
    *vpicg = (*vcol * 8) >> 8;
    *vpicg = *vcol * 8;
    *vpicg = (*vlin * 10) >> 8;
    *vpicg = *vlin * 10;
    *vpicg = 8;
    *vpicg = pcolor >> 8;
    *vpicg = pcolor;
    *vpicg = pbcolor >> 8;
    *vpicg = pbcolor;
    *vpicg = pbyte;

    *vcol = *vcol + 1;

    locateScr(*vcol, *vlin);
}

//-----------------------------------------------------------------------------
void locateScr(BYTE pcol, BYTE plin) {
    WORD vend, ix, iy;
    WORD vlcdf[16];

    if (pcol > *vxmax) {
        pcol = 0;
        plin++;
    }

    if (plin > *vymax) {
        *vpicg = 2;
        *vpicg = 0xD9;
        *vpicg = 10;
        pcol = 0;
        plin = *vymax;

    }

    *vcol = pcol;
    *vlin = plin;
}

//-----------------------------------------------------------------------------
void carregaFile(unsigned long* xaddress)
{
  unsigned short cc, dd;
  unsigned short vrecfim, vbytepic, vbyteprog[128];
  unsigned int vbytegrava = 0;
  unsigned short xdado = 0, xcounter = 0;
  unsigned short vcrc, vcrcpic, vloop;

  vrecfim = 1;
  *verro = 0;

  while (vrecfim) {
    vloop = 1;
    while (vloop) {
        // Processa Retorno do PIC
      	recPic();

        if (vbytepic == picCommData) {
            // Carrega Dados Recebidos
            vcrc = 0;
    		for (cc = 0; cc <= 127 ; cc++)
      		{
          		recPic(); // Ler dados do PIC
      			vbyteprog[cc] = vbytepic;
      			vcrc += vbytepic;
      		}

            // Recebe 2 Bytes CRC
      		recPic();
      		vcrcpic = vbytepic;
      		recPic();
      		vcrcpic |= ((vbytepic << 8) & 0xFF00);

            if (vcrc == vcrcpic) {
                sendPic(0x01);
                sendPic(0xC5);
                vloop = 0;
            }
            else {
                sendPic(0x01);
                sendPic(0xFF);
            }
        }
        else if (vbytepic == picCommStop) {
            // Finaliza Comunicação Serial
            vloop = 0;
      		vrecfim = 0;
        }
        else {
            vloop = 0;
            vrecfim = 0;
            *verro = 1;
        }
    }

    if (vrecfim) {
        for (dd = 00; dd <= 127; dd += 2){
        	vbytegrava = vbyteprog[dd] << 8;
        	vbytegrava = vbytegrava | (vbyteprog[dd + 1] & 0x00FF);

            // Grava Dados na Posição Especificada
            *xaddress = vbytegrava;
            xaddress += 1;
        }
    }
  }
}
