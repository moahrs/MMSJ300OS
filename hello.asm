; D:\PROJETOS\MMSJ300\PROGS\HELLO.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*------------------------------------------------------------------------------
; * MMSJ_OS.H - Arquivo de Header do Sistema Operacional
; * Author: Moacir Silveira Junior (moacir.silveira@gmail.com)
; * Date: 04/07/2013
; *------------------------------------------------------------------------------*/
; #define FAT32       3
; #define TRUE        1
; #define FALSE       0
; #if !defined(NULL)
; #define NULL        '\0'
; #endif
; #define MEDIA_SECTOR_SIZE   512
; WORD *vcorwb      = 0x0081FFFC;
; WORD *vcorwf      = 0x0081FFFE;
; BYTE *vFinalOS    = 0x00820000; // Atualizar sempre que a compilacao passar desse valor
; #define MEM_POS_MGICFG 16    // 1024 Bytes
; // mgi_flags = 16 Bytes de flags/config do MGI
; // icon_pos  = 32 Bytes pos icones
; // icon_ico  = 320 Bytes (10 por icone (32 icones)) para o nome do arquivo do icone
; // icon_prg  = 320 Bytes (10 por icone (32 icones)) para o nome do programa do icone
; #define MEM_POS_ICONES 1040  // 24 x 24 = 576 Words/Icone = 1152 Bytes/Icone
; const BYTE strValidChars[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^&'@{}[],$=!-#()%.+~_";
; const BYTE vmesc[12][3] = {{'J','a','n'},{'F','e','b'},{'M','a','r'},
; {'A','p','r'},{'M','a','y'},{'J','u','n'},
; {'J','u','l'},{'A','u','g'},{'S','e','p'},
; {'O','c','t'},{'N','o','v'},{'D','e','c'}};
; // Demarca o Final do OS, constantes desse tipo nesse compilador vao pro final do codigo.
; // Sempre verificar se esta no final mesmo
; #define ATTR_READ_ONLY      0x01
; #define ATTR_HIDDEN         0x02
; #define ATTR_SYSTEM         0x04
; #define ATTR_VOLUME         0x08
; #define ATTR_LONG_NAME      0x0f
; #define ATTR_DIRECTORY      0x10
; #define ATTR_ARCHIVE        0x20
; #define ATTR_MASK           0x3f
; #define CLUSTER_EMPTY               0x0000
; #define LAST_CLUSTER_FAT32      0x0FFFFFFF
; #define END_CLUSTER_FAT32       0x0FFFFFF7
; #define CLUSTER_FAIL_FAT32      0x0FFFFFFF
; #define NUMBER_OF_BYTES_IN_DIR_ENTRY    32
; #define DIR_DEL             0xE5
; #define DIR_EMPTY           0
; #define DIR_NAMESIZE        8
; #define DIR_EXTENSION       3
; #define DIR_NAMECOMP        (DIR_NAMESIZE+DIR_EXTENSION)
; #define EOF             ((int)-1)
; #define OPER_READ      0x01
; #define OPER_WRITE     0x02
; #define OPER_READWRITE 0x03
; #define CONV_DATA    0x01
; #define CONV_HORA    0x02
; #define INFO_SIZE    0x01
; #define INFO_CREATE  0x02
; #define INFO_UPDATE  0x03
; #define INFO_LAST    0x04
; // Tipos para Cricao/Procura de Arquivos
; #define TYPE_DIRECTORY   0x01
; #define TYPE_FILE 		 0x02
; #define TYPE_EMPTY_ENTRY 0x03
; #define TYPE_CREATE_FILE 0x04
; #define TYPE_CREATE_DIR  0x05
; #define TYPE_DEL_FILE    0x06
; #define TYPE_DEL_DIR     0x07
; #define TYPE_FIRST_ENTRY 0x08
; #define TYPE_NEXT_ENTRY  0x09
; #define TYPE_ALL         0xFF
; // Tipos para Procura de Clusters
; #define FREE_FREE 0x01
; #define FREE_USE  0x02
; #define NEXT_FREE 0x03
; #define NEXT_FULL 0x04
; #define NEXT_FIND 0x05
; //--- LCD Functions
; #define clearLcd() do { \
; *vlcds = 0x01; \
; while ((*vlcds & 0x80) == lcdBusy); \
; *vcol = 0; \
; *vlin = 0; \
; } \
; while (0)
; #define writeCmdLcd(vbyte) do { \
; *vlcds = vbyte; \
; while ((*vlcds & 0x80) == lcdBusy); \
; } \
; while (0)
; #define writeDataLcd(vbyte) do { \
; WORD ix; \
; *vlcdd = vbyte; \
; for(ix = 0; ix <= 30; ix++); \
; } \
; while (0)
; //--- Communications Functions
; void writestringPic(BYTE *msg);
; #define sendPic(vbyte) do { \
; *vpicd = vbyte; \
; } \
; while (0)
; #define recPic() do { \
; vbytepic = *vpicd & 0x00FF; \
; } \
; while (0)
; #define sendVdg(vbyte) do { \
; *vpicg = vbyte; \
; } \
; while (0)
; #define recVdg() do { \
; vbytepic = *vpicg & 0x00FF; \
; } \
; while (0)
; //--- Video VGA Functions
; #define ativaCursor() do { \
; *vpicg = 0x02; \
; *vpicg = 0xD8; \
; *vpicg = 1; \
; } \
; while (0)
; /*
; #define ativaCursor(vativa) do { \
; *vpicg = 0x0A; \
; *vpicg = 0xD8; \
; *vpicg = vativa; \
; *vpicg = 0; \
; *vpicg = 0; \
; *vpicg = 0; \
; *vpicg = 0; \
; *vpicg = *vcorf >> 8; \
; *vpicg = *vcorf; \
; *vpicg = *vcorb >> 8; \
; *vpicg = *vcorb; \
; } \
; while (0)
; */
; //--- KeyBoard Functions
; #define readKey() do { \
; sendPic(0x01); \
; sendPic(picReadKbd); \
; recPic(); \
; } \
; while (0)
; #define getKey() do { \
; if (*inten) { \
; vbytepic = 0x00; \
; if (*vbufkbios > vbufk) { \
; if (*vbufkbios > (vbufk + 31)) { \
; *vbufkbios = vbufk + 31; \
; } \
; vbufkatu = vbufk; \
; vbytepic = *vbufkatu; \
; vbufkptr = vbufk; \
; vbufkatu = *vbufkbios; \
; while (vbufkptr < vbufkatu) { \
; vbufkmove = vbufkptr; \
; vbufkptr++; \
; *vbufkmove = *vbufkptr; \
; } \
; *vbufkmove = 0x00; \
; vbufkptr = *vbufkbios; \
; vbufkptr--; \
; if (vbufkptr < (vbufk)) { \
; vbufkptr = vbufk; \
; } \
; *vbufkbios = vbufkptr; \
; } \
; if (*vbufkbios < vbufk) { \
; vbufkptr = vbufk; \
; *vbufkptr = 0x00; \
; *vbufkbios = vbufkptr; \
; } \
; } \
; else { \
; sendPic(0x01); \
; sendPic(picReadKbd); \
; recPic(); \
; } \
; } \
; while (0)
; //--- OS Functions
; void processCmd(void);
; void clearScr(WORD pcolor);
; void writes(BYTE *msgs, WORD pcolor, WORD pbcolor);
; void writec(BYTE pbyte, WORD pcolor, WORD pbcolor, BYTE ptipo);
; void putPrompt(WORD plinadd);
; void locate(BYTE pcol, BYTE plin, BYTE pcur);
; DWORD loadFile(BYTE *parquivo, unsigned short* xaddress);
; void runCmd(void);
; BYTE loadCFG(BYTE ptipo);
; void catFile(BYTE *parquivo);
; void funcKey(BYTE vambiente, BYTE vshow, BYTE venter, BYTE vtipo, WORD x, WORD y);
; // Funcoes Interface Grafica
; void locatexy(WORD pposx, WORD ppoxy);
; void writesxy(WORD x, WORD y, BYTE sizef, BYTE *msgs, WORD pcolor, WORD pbcolor);
; void writecxy(BYTE sizef, BYTE pbyte, WORD pcolor, WORD pbcolor);
; void SetDot(WORD x, WORD y, WORD color);
; void FillRect(WORD xi, WORD yi, WORD pwidth, WORD pheight, WORD pcor);
; void DrawLine(WORD x1, WORD y1, WORD x2, WORD y2, WORD color);
; void DrawRect(WORD x, WORD y, WORD pwidth, WORD pheight, WORD color);
; void DrawRoundRect(void);
; void DrawCircle(WORD xi, WORD yi, BYTE pang, BYTE pfil, WORD pcor);
; void PutImage(unsigned char* vimage, WORD x, WORD y, WORD pwidth, WORD pheight);
; void startMGI(void);
; void redrawMain(void);
; void desenhaMenu(void);
; void desenhaIconesUsuario(void);
; void MostraIcone(WORD vvx, WORD vvy, BYTE vicone);
; BYTE editortela(void);
; BYTE new_menu(void);
; void new_icon(void);
; void del_icon(void);
; void mgi_setup(void);
; void executeCmd(void);
; void verifyMGI(void);
; void InvertRect(WORD x, WORD y, WORD pwidth, WORD pheight);
; void SelRect(WORD x, WORD y, WORD pwidth, WORD pheight);
; BYTE message(char* bstr, BYTE bbutton, WORD btime);
; void showWindow(void);
; void drawButtons(WORD xib, WORD yib);
; BYTE waitButton(void);
; void fillin(unsigned char* vvar, WORD x, WORD y, WORD pwidth, BYTE vtipo);
; void radioset(unsigned char* vopt, unsigned char *vvar, WORD x, WORD y, BYTE vtipo);
; void togglebox(unsigned char* bstr, unsigned char *vvar, WORD x, WORD y, BYTE vtipo);
; void combobox(unsigned char* vopt, unsigned char *vvar,BYTE x, BYTE y, BYTE vtipo);
; void editor(unsigned char* vtexto, unsigned char *vvar,BYTE x, BYTE y, BYTE vtipo);
; void VerifyTouchLcd(BYTE vtipo);
; #define DrawVertLine(x1, y1, length, color) FillRect(x1, y1, 0, length, color)
; #define DrawHoriLine(x1, y1, length, color) FillRect(x1, y1, length, 0, color)
; #define BTNONE      0x00
; #define BTOK        0x01
; #define BTCANCEL    0x02
; #define BTYES       0x04
; #define BTNO        0x08
; #define BTHELP      0x10
; #define BTSTART     0x20
; #define BTCLOSE     0x40
; #define WINVERT     0x01
; #define WINHORI     0x00
; #define WINOPER     0x01
; #define WINDISP     0x00
; #define WHAITTOUCH   0X01
; #define NOWHAITTOUCH 0x00
; #define ICONSPERLINE   8  // Quantidade de Icones por linha
; #define SPACEICONS     4  // Quantidade de Espaços entre os Icones Horizontal
; #define COLINIICONS   40  // Linha Inicial dos Icones
; #define LINHAMENU      36
; #define COLMENU       48
; #define LINMENU       4
; #define ICON_HOME  50
; #define ICON_RUN  51
; #define ICON_NEW  52
; #define ICON_DEL  53
; #define ICON_MMSJDOS  54
; #define ICON_SETUP  55
; #define ICON_EXIT  56
; #define ICON_HOURGLASS  57
; //--- FAT32 Functions
; BYTE fsFormat (long int serialNumber, char * volumeID);
; void fsSetClusterDir (DWORD vclusdiratu);
; DWORD fsGetClusterDir (void);
; BYTE fsSectorWrite(DWORD vsector, BYTE* vbuffer, BYTE vtipo);
; BYTE fsSectorRead(DWORD vsector, BYTE* vbuffer);
; // Funcoes de Manipulacao de Arquivos
; BYTE fsCreateFile(char * vfilename);
; BYTE fsOpenFile(char * vfilename);
; BYTE fsCloseFile(char * vfilename, BYTE vupdated);
; DWORD fsInfoFile(char * vfilename, BYTE vtype);
; BYTE fsRWFile(DWORD vclusterini, DWORD voffset, BYTE *buffer, BYTE vtype);
; BYTE fsReadFile(char * vfilename, DWORD voffset, BYTE *buffer, BYTE vsizebuffer);
; BYTE fsWriteFile(char * vfilename, DWORD voffset, BYTE *buffer, BYTE vsizebuffer);
; BYTE fsDelFile(char * vfilename);
; BYTE fsRenameFile(char * vfilename, char * vnewname);
; // Funcoes de Manipulacao de Diretorios
; BYTE fsMakeDir(char * vdirname);
; BYTE fsChangeDir(char * vdirname);
; BYTE fsRemoveDir(char * vdirname);
; BYTE fsPwdDir(BYTE *vdirpath);
; // Funcoes de Apoio
; DWORD fsFindInDir(char * vname, BYTE vtype);
; BYTE fsUpdateDir(void);
; DWORD fsFindNextCluster(DWORD vclusteratual, BYTE vtype);
; DWORD fsFindClusterFree(BYTE vtype);
; //-----------------------------------------------------------------------------
; BYTE * _strcat (BYTE * dst, BYTE * cp, BYTE * src) {
       section   code
       xdef      __strcat
__strcat:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; while( *cp )
_strcat_1:
       move.l    12(A6),A0
       tst.b     (A0)
       beq.s     _strcat_3
; *dst++ = *cp++;     /* copy to dst and find end of dst */
       move.l    12(A6),A0
       addq.l    #1,12(A6)
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
       bra       _strcat_1
_strcat_3:
; while( *src )
_strcat_4:
       move.l    16(A6),A0
       tst.b     (A0)
       beq.s     _strcat_6
; *dst++ = *src++;       /* Copy src to end of dst */
       move.l    16(A6),A0
       addq.l    #1,16(A6)
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
       bra       _strcat_4
_strcat_6:
; *dst++ = 0x00;
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
; return( dst );                  /* return dst */
       move.l    D2,D0
       move.l    (A7)+,D2
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
; WORD datetimetodir(BYTE hr_day, BYTE min_month, BYTE sec_year, BYTE vtype)
; {
       xdef      _datetimetodir
_datetimetodir:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; WORD vconv = 0, vtemp;
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
; vconv  = (WORD)(vtemp & 0x7F) << 9;
       move.w    D3,D0
       and.w     #127,D0
       lsl.w     #8,D0
       lsl.w     #1,D0
       move.w    D0,D2
; vconv |= (WORD)(min_month & 0x0F) << 5;
       move.b    15(A6),D0
       and.b     #15,D0
       and.w     #255,D0
       lsl.w     #5,D0
       or.w      D0,D2
; vconv |= (WORD)(hr_day & 0x1F);
       move.b    11(A6),D0
       and.b     #31,D0
       and.w     #255,D0
       or.w      D0,D2
       bra       datetimetodir_2
datetimetodir_1:
; }
; else {
; vconv  = (WORD)(hr_day & 0x1F) << 11;
       move.b    11(A6),D0
       and.b     #31,D0
       and.w     #255,D0
       lsl.w     #8,D0
       lsl.w     #3,D0
       move.w    D0,D2
; vconv |= (WORD)(min_month & 0x3F) << 5;
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
; vconv |= (WORD)(vtemp & 0x1F);
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
; /********************************************************************************
; *    Programa    : hello.c
; *    Objetivo    : Hello para testes
; *    Criado em   : 13/10/2014
; *    Programador : Moacir Jr.
; *--------------------------------------------------------------------------------
; * Data        Versão  Responsavel  Motivo
; * 13/10/2014  0.1     Moacir Jr.   Criação Versão Beta
; *--------------------------------------------------------------------------------*/
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "mmsj300api.h"
; #include "mmsj_os.h"
; //-----------------------------------------------------------------------------
; // Principal
; //-----------------------------------------------------------------------------
; void main(void)
; {
       xdef      _main
_main:
; // mostra msgs na tela
; writes("Helooooooooo...\n\0", *vcorf, *vcorb);
       move.l    _vcorb.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    _vcorf.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @hello_1.L
       jsr       _writes
       add.w     #12,A7
       rts
; }
       section   const
@hello_1:
       dc.b      72,101,108,111,111,111,111,111,111,111,111,111
       dc.b      46,46,46,10,0
       xdef      _strValidChars
_strValidChars:
       dc.b      48,49,50,51,52,53,54,55,56,57,65,66,67,68,69
       dc.b      70,71,72,73,74,75,76,77,78,79,80,81,82,83,84
       dc.b      85,86,87,88,89,90,94,38,39,64,123,125,91,93
       dc.b      44,36,61,33,45,35,40,41,37,46,43,126,95,0
       section   data
       xdef      _vlcds
_vlcds:
       dc.l      4194304
       xdef      _vlcdd
_vlcdd:
       dc.l      4194306
       xdef      _vpicd
_vpicd:
       dc.l      4194336
       xdef      _vpicg
_vpicg:
       dc.l      4194368
       xdef      _vxmaxold
_vxmaxold:
       dc.l      16751464
       xdef      _vymaxold
_vymaxold:
       dc.l      16751466
       xdef      _voverx
_voverx:
       dc.l      16751468
       xdef      _vovery
_vovery:
       dc.l      16751470
       xdef      _vparamstr
_vparamstr:
       dc.l      16751472
       xdef      _vparam
_vparam:
       dc.l      16751728
       xdef      _vbbutton
_vbbutton:
       dc.l      16751786
       xdef      _vkeyopen
_vkeyopen:
       dc.l      16751788
       xdef      _vbytetec
_vbytetec:
       dc.l      16751790
       xdef      _pposx
_pposx:
       dc.l      16751792
       xdef      _pposy
_pposy:
       dc.l      16751794
       xdef      _vbuttonwiny
_vbuttonwiny:
       dc.l      16751798
       xdef      _vbuttonwin
_vbuttonwin:
       dc.l      16751800
       xdef      _vpostx
_vpostx:
       dc.l      16751808
       xdef      _vposty
_vposty:
       dc.l      16751810
       xdef      _next_pos
_next_pos:
       dc.l      16751822
       xdef      _vdir
_vdir:
       dc.l      16751824
       xdef      _vdisk
_vdisk:
       dc.l      16751872
       xdef      _vclusterdir
_vclusterdir:
       dc.l      16752096
       xdef      _vclusteros
_vclusteros:
       dc.l      16752104
       xdef      _gDataBuffer
_gDataBuffer:
       dc.l      16752112
       xdef      _mcfgfile
_mcfgfile:
       dc.l      16752632
       xdef      _viconef
_viconef:
       dc.l      16752632
       xdef      _vcorf
_vcorf:
       dc.l      16764924
       xdef      _vcorb
_vcorb:
       dc.l      16764926
       xdef      _vcol
_vcol:
       dc.l      16764928
       xdef      _vlin
_vlin:
       dc.l      16764930
       xdef      _voutput
_voutput:
       dc.l      16764932
       xdef      _vbuf
_vbuf:
       dc.l      16764934
       xdef      _vxmax
_vxmax:
       dc.l      16764966
       xdef      _vymax
_vymax:
       dc.l      16764968
       xdef      _xpos
_xpos:
       dc.l      16764970
       xdef      _ypos
_ypos:
       dc.l      16764972
       xdef      _verro
_verro:
       dc.l      16764974
       xdef      _vdiratu
_vdiratu:
       dc.l      16764976
       xdef      _vdiratup
_vdiratup:
       dc.l      16764976
       xdef      _vinip
_vinip:
       dc.l      16765120
       xdef      _vbufk
_vbufk:
       dc.l      16765122
       xdef      _vbufkptr
_vbufkptr:
       dc.l      16765122
       xdef      _vbufkmove
_vbufkmove:
       dc.l      16765122
       xdef      _vbufkatu
_vbufkatu:
       dc.l      16765122
       xdef      _vbufkbios
_vbufkbios:
       dc.l      16765154
       xdef      _inten
_inten:
       dc.l      16765168
       xdef      _vxgmax
_vxgmax:
       dc.l      16765170
       xdef      _vygmax
_vygmax:
       dc.l      16765174
       xdef      _vmtaskatu
_vmtaskatu:
       dc.l      16768932
       xdef      _vmtask
_vmtask:
       dc.l      16768932
       xdef      _vmtaskup
_vmtaskup:
       dc.l      16768932
       xdef      _intpos
_intpos:
       dc.l      16769016
       xdef      _vtotmem
_vtotmem:
       dc.l      16769020
       xdef      _v10ms
_v10ms:
       dc.l      16769022
       xdef      _vcorwb
_vcorwb:
       dc.l      8519676
       xdef      _vcorwf
_vcorwf:
       dc.l      8519678
       xdef      _vFinalOS
_vFinalOS:
       dc.l      8519680
       xdef      _vmesc
_vmesc:
       dc.b      74,97,110,70,101,98,77,97,114,65,112,114,77
       dc.b      97,121,74,117,110,74,117,108,65,117,103,83,101
       dc.b      112,79,99,116,78,111,118,68,101,99
       xref      ULMUL
       xref      _writes
