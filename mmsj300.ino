/*
  Created by Fabrizio Di Vittorio (fdivitto2013@gmail.com) - <http://www.fabgl.com>
  Copyright (c) 2019-2022 Fabrizio Di Vittorio.
  All rights reserved.


* Please contact fdivitto2013@gmail.com if you need a commercial license.


* This library and related software is available under GPL v3.

  FabGL is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  FabGL is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with FabGL.  If not, see <http://www.gnu.org/licenses/>.
 */


#include "fabgl.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "mmsj300.h"


fabgl::VGA16Controller DisplayController;
fabgl::Terminal        Terminal;


void setup()
{
  //Serial.begin(115200); delay(500); Serial.write("\n\n\n"); // DEBUG ONLY

  pinMode(pinD0, INPUT);
  pinMode(pinD1, INPUT);
  pinMode(pinD2, INPUT);
  pinMode(pinD3, INPUT);
  pinMode(pinD4, INPUT);
  pinMode(pinD5, INPUT);
  pinMode(pinD6, INPUT);
  pinMode(pinD7, INPUT);
  pinMode(pinCS_VDG,INPUT);
  pinMode(pinRW,INPUT);
  pinMode(pinDTACKVDG,OUTPUT);

  digitalWrite(pinDTACKVDG,HIGH);

  DisplayController.begin();
  DisplayController.setResolution(VGA_640x480_60Hz);

  Terminal.begin(&DisplayController);
  //Terminal.setLogStream(Serial);  // DEBUG ONLY

  Terminal.write("\e[40;92m"); // background: black, foreground: green
  Terminal.write("\e[2J");     // clear screen
  Terminal.write("\e[1;1H");   // move cursor to 1,1
  Terminal.write("VDG-300 v0.01\r\n");
  Terminal.write("VGA Controller by Fabrizio Di Vittorio 2019-2022 - www.fabgl.com\r\n");
  Terminal.write("ESP32 module\r\n");
  Terminal.write("www.utilityinf.com.br\r\n");
  Terminal.write("\r\n");
}


void sPrintf(const char * format, ...)
{
  va_list ap;
  va_start(ap, format);
  int size = vsnprintf(nullptr, 0, format, ap) + 1;
  if (size > 0) {
    va_end(ap);
    va_start(ap, format);
    char buf[size + 1];
    vsnprintf(buf, size, format, ap);
    for (int i = 0; i < size; ++i) {
      Terminal.write(buf[i]);
    }
  }
  va_end(ap);
}

//-------------------------------------------------------------------
void PSPComm(void) {
  unsigned char ix, vtimeout;
  char cTemp[32];

  if (!digitalRead(pinCS_VDG) && preadycs == 0x0F) 
  {
    preadycs = 0x00;

    if (!digitalRead(pinRW) && !preadyrd) 
    {
      pbyte[pbytecountw]  = ((digitalRead(pinD7) << 7) & 0x80);
      pbyte[pbytecountw] |= ((digitalRead(pinD6) << 6) & 0x40);
      pbyte[pbytecountw] |= ((digitalRead(pinD5) << 5) & 0x20);
      pbyte[pbytecountw] |= ((digitalRead(pinD4) << 4) & 0x10);
      pbyte[pbytecountw] |= ((digitalRead(pinD3) << 3) & 0x08);
      pbyte[pbytecountw] |= ((digitalRead(pinD2) << 2) & 0x04);
      pbyte[pbytecountw] |= ((digitalRead(pinD1) << 1) & 0x02);
      pbyte[pbytecountw] |= (digitalRead(pinD0) & 0x01);
      pbyte[pbytecountw + 1] = 0x00;
      
      Terminal.write("\e[10;1H");   
      sPrintf("Qtd.Recebida: %d", pbyte[0]);
      Terminal.write("\e[11;1H");   
      sPrintf("Qtd.Processada: %d", pbytecountw);
      Terminal.write("\e[12;1H");   
      sPrintf("DTACK_VDG:  LOW");

      digitalWrite(pinDTACKVDG, LOW);  

      while (!digitalRead(pinCS_VDG));
      
      digitalWrite(pinDTACKVDG, HIGH);  

      Terminal.write("\e[12;1H");   
      sPrintf("DTACK_VDG: HIGH");

      if (pbyte[0] != 0x00 && pbytecountw == pbyte[0])
        preadywr = 0x01;

      if (pbyte[0] != 0x00)
        pbytecountw++;
    }
    else if (digitalRead(pinRW) && preadyrd) 
    {
      // All Outputs
      pinMode(pinD0, OUTPUT);
      pinMode(pinD1, OUTPUT);
      pinMode(pinD2, OUTPUT);
      pinMode(pinD3, OUTPUT);
      pinMode(pinD4, OUTPUT);
      pinMode(pinD5, OUTPUT);
      pinMode(pinD6, OUTPUT);
      pinMode(pinD7, OUTPUT);

      digitalWrite(pinD0, pbyte[pbytecountr] & B00000001);
      digitalWrite(pinD1, pbyte[pbytecountr] & (B00000010 >> 1));
      digitalWrite(pinD2, pbyte[pbytecountr] & (B00000100 >> 2));
      digitalWrite(pinD3, pbyte[pbytecountr] & (B00001000 >> 3));
      digitalWrite(pinD4, pbyte[pbytecountr] & (B00010000 >> 4));
      digitalWrite(pinD5, pbyte[pbytecountr] & (B00100000 >> 5));
      digitalWrite(pinD6, pbyte[pbytecountr] & (B01000000 >> 6));
      digitalWrite(pinD7, pbyte[pbytecountr++] & (B10000000 >> 7));

      digitalWrite(pinDTACKVDG, LOW);  

      while (!digitalRead(pinCS_VDG));
      
      // All Inputs
      pinMode(pinD0, INPUT);
      pinMode(pinD1, INPUT);
      pinMode(pinD2, INPUT);
      pinMode(pinD3, INPUT);
      pinMode(pinD4, INPUT);
      pinMode(pinD5, INPUT);
      pinMode(pinD6, INPUT);
      pinMode(pinD7, INPUT);

      digitalWrite(pinDTACKVDG, HIGH);  
    }
  }   

  preadycs++;
  if (preadycs > 0x0F)
    preadycs = 0x00;
}

//-------------------------------------------------------------------
void interfacRead(unsigned char vqtd) {
  pbytecountr = 0;
  preadyrd = 0x01;
  preadycs = 0;

  while (pbytecountr < vqtd)
    PSPComm();

  preadyrd = 0x00;
}

//--------------------------------------------------------------------------
unsigned int convertColor(unsigned int pcolor, unsigned int ptipo) {
  unsigned retcolor = 0;

  switch(pcolor)
  {
    case 0:     // black
      retcolor = 30 + (10 * ptipo);
      break;
    case 65535: // white
      retcolor = 37 + (10 * ptipo);
      break;
  }

  return retcolor;
}

//--------------------------------------------------------------------------
void processVdg()
{
  unsigned int ixx, iyy, ix, iz, iy, iw, qtdbytes;
  unsigned int vxxnew, vyynew;
  unsigned char spritenum;
  
  pbytecountw = 0x00;
  pbytecountr = 0x00;       
  preadywr = 0x00;
  preadyrd = 0x00;
  pbyte[0] = 0x00;
  indProc = 1;
    
  do {
    PSPComm();
  } while (pbyte[0] != 0 && !preadywr);

  if (preadywr) 
  {
    pbytecountw = 0x00;
    pbytecountr = 0x00;       
    preadywr = 0x00;
    
    pconv1 = pbyte[2];
    pconv2 = pbyte[3];
    vxx = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
    
    pconv1 = pbyte[4];
    pconv2 = pbyte[5];
    vyy = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF); 
    
    pconv1 = pbyte[6];
    pconv2 = pbyte[7];
    vxxf = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
    
    pconv1 = pbyte[8];
    pconv2 = pbyte[9];
    vyyf = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
    
    dfont = pbyte[6];
    
    pconv1 = pbyte[7];
    pconv2 = pbyte[8];
    fcor = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
    
    pconv1 = pbyte[9];
    pconv2 = pbyte[10];
    bcor = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
    
    pconv1 = pbyte[10];
    pconv2 = pbyte[11];
    fcorgraf = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
  
    switch (pbyte[1]) 
    {
      case 0xC0:    // Show bitmap
        ix = 6;
        while (pbyte[ix] != 0) 
        {
          cchar = pbyte[ix];
          pbyte[ix - 6] = cchar;
          ix++;
        }
        pbyte[ix - 6] = '\0';
//        TFT_BmpDraw((char*)pbyte,vxx,vyy);
        break;
      case 0xC1:    // Load Lib Icons
        ix = 2;
        while (pbyte[ix] != 0) 
        {
          cchar = pbyte[ix];
          pbyte[ix - 2] = cchar;
          ix++;
        }
        pbyte[ix - 2] = '\0';
//        TFT_LoadIconLib((char*)pbyte);
        break;
      case 0xD0: // Clear Screen
        pconv1 = pbyte[2];
        pconv2 = pbyte[3];
        fcorgraf = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);

        Terminal.write("\e[40;92m"); // background: black, foreground: green
        Terminal.write("\e[2J");     // clear screen
        Terminal.write("\e[1;1H");   // move cursor to 1,1

        break;
      case 0xD1: // Write String
        if (dfont > 7)
            dfont = 1;

        if (indTypeScreen == 1)
        {
          if (vxx != 0)
            vxx = (vxx / 8) + 1;
          if (vyy != 0)
            vyy = (vyy / 10) + 1;
        }

        ix = 11;
        while (pbyte[ix] != 0) 
        {
          cchar = pbyte[ix];
          pbyte[ix - 11] = cchar;
          ix++;
        }
        pbyte[ix - 11] = '\0';

        fcor = convertColor(fcor, 0);
        bcor = convertColor(bcor, 1);

        Terminal.write(("\e[" + String(bcor) + ";" + String(fcor) + "m").c_str()); // background: defined, foreground: defined
        Terminal.write(("\e[" + String(vyy) + ";" + String(vxx) + "H").c_str());   // move cursor to x, y
        Terminal.write((char*)pbyte); 

        //sPrintf("%s",pbyte);

        vxcur = vxx + dFontW;
        vycur = vyy;
        break;
      case 0xD2: // Write Char
        if (dfont > 7)
            dfont = 1;
        if (indTypeScreen == 1)
        {
          if (vxx != 0)
            vxx = (vxx / 8) + 1;
          if (vyy != 0)
            vyy = (vyy / 10) + 1;
        }

        fcor = convertColor(fcor, 0);
        bcor = convertColor(bcor, 1);
        
        if (pbyte[11] == 0x08) 
        {
          Terminal.write(("\e[" + String(bcor) +";" + String(fcor) + "m").c_str()); // background: black, foreground: green
          Terminal.write(("\e[" + String(vyy) + ";" + String(vxx) + "H").c_str());   // move cursor
          Terminal.write(" ");
//          sPrintf(" ");
 
          vxcur = vxx;
          vycur = vyy;
        }      
        else 
        {
          Terminal.write(("\e[" + String(bcor) +";" + String(fcor) + "m").c_str()); // background: black, foreground: green
          Terminal.write(("\e[" + String(vyy) + ";" + String(vxx) + "H").c_str());   // move cursor
          Terminal.write(pbyte[11]);
//          sPrintf("%c",pbyte[11]);

          vxcur = vxx;
          vycur = vyy;
          vycur += 8;
        }    
        break;
      case 0xD3: //Draw a Box
//        tft.fillRect(vxx,vyy,vxxf,vyyf,fcorgraf);
        break;
      case 0xD4: //Draw a Line
//        tft.drawLine(vxx,vyy,vxxf,vyyf,fcorgraf);
        break;
      case 0xD5: // Draw a Rectangle
//        tft.drawRect(vxx,vyy,vxxf,vyyf,fcorgraf);
        break;
      case 0xD6: // Draw a Circle
//        tft.drawCircle(vxx,vyy,pbyte[6],fcor);
        if (pbyte[7])
//          tft.fillCircle(vxx,vyy,pbyte[6],bcor);
        break;
      case 0xD7: // Set a point in LCD 
//        tft.drawPixel(vxx,vyy,fcor);
        break;
      case 0xD8: // 0 - Hidden Cursor, 1 - Show Cursor
        vcur = pbyte[2];
        fcorcur = fcor;
        bcorcur = bcor;

        if (vcur)
          Terminal.enableCursor(true);
        else
          Terminal.enableCursor(false);

//        if (vcur == 2 && (vxcur != 0 || vycur != 0)) 
//            TFT_Char(vxcur,vycur,' ',fcorcur,bcorcur,1);
        break;                     
      case 0xD9: // Vertical Scroll
        pconv1 = pbyte[3];
        pconv2 = pbyte[4];
        bcor = ((pconv1 << 8) & 0xFF00) | (pconv2 & 0x00FF);
        
//        TFT_Scroll(16 /*pbyte[2]*/, 1);
        
        interfacRead(1);
        break;
      case 0xDA: // Seta tipo de interface (caracter ou grafico)
        indTypeScreen = pbyte[2];
        break;
      case 0xDE:
        qtdbytes = pbyte[2] * pbyte[3];
        iw = ((qtdbytes) * 2 / 1152);
        spritenum = pbyte[4] * iw;

        for (iy = 0; iy < iw; iy++)
        {
            ixx = 0;
            do {
                pbytecountw = 0;
                preadywr = 0;
                do {
                    PSPComm();
                } while (pbyte[0] != 0 && !preadywr);

//                iz = pbyte[2];
                iz = ixx * 128;
                for(ix = 3; ix <= 130; ix++) 
                    pvideobyte[iz++] = pbyte[ix];

                qtdbytes -= 64;
                ixx++;
            } while (qtdbytes > 0 && ixx < 9);

            #ifdef __USE__ICON_32KB__SRAM__
//              SpiRam2.write_stream((int)(spritenum * 1152), pvideobyte, 1152);
            #else
//              SpiRam2.write_stream(ENDERICONSTART + (int)(spritenum * 1152), pvideobyte, 1152);
            #endif

            spritenum += 1;
        }
        break;
      case 0xDF:
        iy = (((vxxf * vyyf) * 2) / 1152);
        ixx = vxxf / 24;
        iyy = vyyf / 24;

        spritenum = pbyte[10] * iy;

        for (iw = 0; iw < iy; iw++)
        {
            #ifdef __USE__ICON_32KB__SRAM__
//              SpiRam2.read_stream((int)(spritenum * 1152), pvideobyte, 1152);
            #else
//              SpiRam2.read_stream(ENDERICONSTART + (int)(spritenum * 1152), pvideobyte, 1152);
            #endif

            iz = 0;
            for (ix = 0; ix < 1152; ix += 2)
            {
                pvideo[iz] = pvideobyte[ix] << 8;
                pvideo[iz++] |= pvideobyte[ix + 1];
            }

            // vxxf e vyyf vao funcionar como dim_x e dim_y respectivamente
            vyynew = vyy + (12 * iw);
//            TFT_Image(vxx, vyynew, 48, 12, (unsigned int*)pvideo);

            spritenum += 1;
        }
        break;
      case 0xEA:
        // vxxf e vyyf vao funcionar como width e height respectivamente
//        TFT_SaveScreen(0x0000, vxx, vyy, vxxf, vyyf);
        break;
      case 0xEB:
        // vxxf e vyyf vao funcionar como width e height respectivamente
//        TFT_RestoreScreen(0x0000, vxx, vyy, vxxf, vyyf);
        break;
      case 0xEC:
        // vxxf e vyyf vao funcionar como dim_x e dim_y respectivamente
//        TFT_InvertRect(vxx, vyy, vxxf, vyyf);
        break;
      case 0xED:
        vReceiveVDG = pbyte[2];
        break;
      case 0xEF: // Return Status Information
        pbyte[0] = B01000001;    // D7-D6 (00-ATMEGA2560, 10-18F4550, 01-ESP32, 11-none)
                                 // D1 (0-No Touch, 1-Touch)
                                 // D0 (0-LCDG, 1-VGA)
        pbyte[1] = (DisplayController.getScreenWidth() & 0xFF00) >> 8;
        pbyte[2] = (DisplayController.getScreenWidth() & 0x00FF);
        pbyte[3] = (DisplayController.getScreenHeight() & 0xFF00) >> 8;
        pbyte[4] = (DisplayController.getScreenHeight() & 0x00FF);
        pbyte[5] = dFontW;
        pbyte[6] = dFontH;

        interfacRead(7);
        break;
    }

    pbyte[0] = 0x00;
    pbyte[1] = 0x00;  
  }
}

void loop()
{ 
  /*if (firstTime)
  {
    delay(1500);

    Terminal.write("\e[40;92m"); // background: black, foreground: green
    Terminal.write("\e[2J");     // clear screen
    Terminal.write("\e[1;1H");   // move cursor to 1,1

    firstTime = 0;
  }*/

  if (!digitalRead(pinCS_VDG))
    processVdg();
}
