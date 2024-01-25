unsigned char pbytecountw;
unsigned char pbytecountr;
unsigned char preadywr;
unsigned char preadyrd;
unsigned char preadycs = 0;
unsigned char pbyte[133];
unsigned char pvideobyte[1160];
unsigned int pvideo[580];
unsigned int pconv1, pconv2;
unsigned int vxx, vyy;
unsigned int vxxf, vyyf; 
unsigned int fcor = 92, bcor = 40;
unsigned int fcorcur = 92, bcorcur = 40, fcorgraf = 40;
unsigned int vxcur, vycur;
unsigned char dfont;
unsigned char cchar;
unsigned int x_max, y_max;
unsigned char dFontW = 8, dFontH = 10;
char vReceiveVDG = 0;
char indProc;
char indTypeScreen = 1; // 1 - Character, 2 - Graphical
unsigned char vcur = 0;
unsigned char firstTime = 1;

#define pinD0 32
#define pinD1 33
#define pinD2 34
#define pinD3 35
#define pinD4 2
#define pinD5 12
#define pinD6 13
#define pinD7 14
#define pinCS_VDG 25      // GPIO25
#define pinRW 26          // GPIO26
#define pinDTACKVDG 27    // GPIO27
