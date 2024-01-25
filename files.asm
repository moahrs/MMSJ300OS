; D:\PROJETOS\MMSJ300\PROGS\FILES.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
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
; void SaveScreen(WORD xi, WORD yi, WORD pwidth, WORD pheight);
; void RestoreScreen(WORD xi, WORD yi, WORD pwidth, WORD pheight);
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
; *    Programa    : files.c
; *    Objetivo    : File Explorer for MMSJ_OS
; *    Criado em   : 14/10/2014
; *    Programador : Moacir Jr.
; *--------------------------------------------------------------------------------
; * Data        Versão  Responsavel  Motivo
; * 14/10/2014  0.1     Moacir Jr.   Criação Versão Beta
; *--------------------------------------------------------------------------------*/
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include "mmsj300api.h"
; #include "mmsj_os.h"
; BYTE *cfile     = 0x0081E000;   // Lista de arquivos carregados da pasta atual. 40 em 40. Max 100.
; BYTE *clinha    = 0x0081DFE0;
; WORD *vpos      = 0x0081DFF0;
; WORD *vposold   = 0x0081DFF2;
; // DEFINE FUNÇÕES
; void linhastatus(BYTE vtipomsgs);
; void SearchFile(void);
; void carregaDir(void);
; void listaDir(void);
; //-----------------------------------------------------------------------------
; // Principal
; //-----------------------------------------------------------------------------
; void main(void)
; {
       xdef      _main
_main:
       link      A6,#-148
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -118(A6),A2
       lea       _vposty.L,A3
       lea       _vpostx.L,A4
       lea       _vparam.L,A5
; BYTE vcont, ix, iy, cc, dd, ee, cnum[20], *cfileptr, *cfilepos;
; BYTE ikk, vnomefile[32], vnomefilenew[15], avdm2, avdm, avdl, vopc, vresp;
; unsigned long vtotbytes = 0;
       clr.l     -68(A6)
; BYTE vstring[64], vwb;
; strcpy(vparamstr,"File Explorer v0.1");
       pea       @files_1.L
       move.l    _vparamstr.L,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; vparam[0] = 5;
       move.l    (A5),A0
       move.w    #5,(A0)
; vparam[1] = 5;
       move.l    (A5),A0
       move.w    #5,2(A0)
; vparam[2] = 310;
       move.l    (A5),A0
       move.w    #310,4(A0)
; vparam[3] = 230;
       move.l    (A5),A0
       move.w    #230,6(A0)
; vparam[4] = BTNONE;
       move.l    (A5),A0
       clr.w     8(A0)
; showWindow();
       jsr       _showWindow
; vcont = 1;
       move.b    #1,-148(A6)
; *vpos = 0;
       move.l    _vpos.L,A0
       clr.w     (A0)
; *vposold = 0xFF;
       move.l    _vposold.L,A0
       move.w    #255,(A0)
; vnomefile[0] = 0x00;
       clr.b     (A2)
; FillRect(6,20,309,10,*vcorwf);
       move.l    _vcorwf.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       10
       pea       309
       pea       20
       pea       6
       jsr       _FillRect
       add.w     #20,A7
; writesxy(7,20,8,"Name     Ext Modify      Size   Atrib\0", *vcorwb, *vcorwf);
       move.l    _vcorwf.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    _vcorwb.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_2.L
       pea       8
       pea       20
       pea       7
       jsr       _writesxy
       add.w     #24,A7
; DrawLine(5,31,315,31,*vcorwf);
       move.l    _vcorwf.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       31
       pea       315
       pea       31
       pea       5
       jsr       _DrawLine
       add.w     #20,A7
; carregaDir();
       jsr       _carregaDir
; while (vcont)
main_1:
       tst.b     -148(A6)
       beq       main_3
; {
; linhastatus(1);
       pea       1
       jsr       _linhastatus
       addq.w    #4,A7
; listaDir();
       jsr       _listaDir
; if (*vposold == *vpos)
       move.l    _vposold.L,A0
       move.l    _vpos.L,A1
       move.w    (A0),D0
       cmp.w     (A1),D0
       bne.s     main_4
; listaDir();
       jsr       _listaDir
main_4:
; linhastatus(0);
       clr.l     -(A7)
       jsr       _linhastatus
       addq.w    #4,A7
; *vposty = 0;
       move.l    (A3),A0
       clr.w     (A0)
; while (1) {
main_6:
; VerifyTouchLcd(WHAITTOUCH);
       pea       1
       jsr       _VerifyTouchLcd
       addq.w    #4,A7
; if (*vposty >= 34 && *vposty <= 215) {
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #34,D0
       blo       main_9
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #215,D0
       bhi       main_9
; ee = 99;
       moveq     #99,D3
; dd = 0;
       clr.b     D5
; while (ee == 99) {
main_11:
       cmp.b     #99,D3
       bne       main_13
; if (*vposty >= clinha[dd] && *vposty <= (clinha[dd] + 10) && clinha[dd] != 0)
       move.l    (A3),A0
       move.l    _clinha.L,A1
       and.l     #255,D5
       move.b    0(A1,D5.L),D0
       and.w     #255,D0
       cmp.w     (A0),D0
       bhi.s     main_14
       move.l    (A3),A0
       move.l    _clinha.L,A1
       and.l     #255,D5
       move.b    0(A1,D5.L),D0
       add.b     #10,D0
       and.w     #255,D0
       cmp.w     (A0),D0
       blo.s     main_14
       move.l    _clinha.L,A0
       and.l     #255,D5
       move.b    0(A0,D5.L),D0
       beq.s     main_14
; ee = dd;
       move.b    D5,D3
main_14:
; dd++;
       addq.b    #1,D5
       bra       main_11
main_13:
; }
; if (ee != 99 ){
       cmp.b     #99,D3
       beq       main_53
; InvertRect(7,((ee + 1) * 10),303,10);
       pea       10
       pea       303
       move.b    D3,D1
       addq.b    #1,D1
       and.w     #255,D1
       mulu.w    #10,D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       7
       jsr       _InvertRect
       add.w     #16,A7
; // Abre menu : Delete, Rename, Close
; FillRect(30,10,45,30,White);
       pea       65535
       pea       30
       pea       45
       pea       10
       pea       30
       jsr       _FillRect
       add.w     #20,A7
; DrawRect(30,10,45,30,Black);
       clr.l     -(A7)
       pea       30
       pea       45
       pea       10
       pea       30
       jsr       _DrawRect
       add.w     #20,A7
; writesxy(33,12,8,"Delete",Black,White);
       pea       65535
       clr.l     -(A7)
       pea       @files_3.L
       pea       8
       pea       12
       pea       33
       jsr       _writesxy
       add.w     #24,A7
; writesxy(33,20,8,"Rename",Black,White);
       pea       65535
       clr.l     -(A7)
       pea       @files_4.L
       pea       8
       pea       20
       pea       33
       jsr       _writesxy
       add.w     #24,A7
; DrawLine(30,28,75,28,Black);
       clr.l     -(A7)
       pea       28
       pea       75
       pea       28
       pea       30
       jsr       _DrawLine
       add.w     #20,A7
; writesxy(33,30,8,"Close",Black,White);
       pea       65535
       clr.l     -(A7)
       pea       @files_5.L
       pea       8
       pea       30
       pea       33
       jsr       _writesxy
       add.w     #24,A7
; while (1) {
main_18:
; VerifyTouchLcd(WHAITTOUCH);
       pea       1
       jsr       _VerifyTouchLcd
       addq.w    #4,A7
; if (*vpostx >= 36 && *vpostx <= 70) {
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #36,D0
       blo       main_27
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #70,D0
       bhi       main_27
; if (*vposty >= 12 && *vposty <= 19 ) {
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #12,D0
       blo.s     main_23
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #19,D0
       bhi.s     main_23
; vopc = 0;
       clr.b     D4
; InvertRect(31,12,43,8);
       pea       8
       pea       43
       pea       12
       pea       31
       jsr       _InvertRect
       add.w     #16,A7
; break;
       bra       main_20
main_23:
; }
; else if (*vposty >= 20 && *vposty <= 27) {
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #20,D0
       blo.s     main_25
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #27,D0
       bhi.s     main_25
; vopc = 1;
       moveq     #1,D4
; InvertRect(31,20,43,8);
       pea       8
       pea       43
       pea       20
       pea       31
       jsr       _InvertRect
       add.w     #16,A7
; break;
       bra       main_20
main_25:
; }
; else if (*vposty >= 30 && *vposty <= 37) {
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #30,D0
       blo.s     main_27
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #37,D0
       bhi.s     main_27
; vopc = 2;
       moveq     #2,D4
; InvertRect(31,30,43,8);
       pea       8
       pea       43
       pea       30
       pea       31
       jsr       _InvertRect
       add.w     #16,A7
; break;
       bra.s     main_20
main_27:
       bra       main_18
main_20:
; }
; }
; }
; // Executa opção selecionada
; if (vopc == 0) {
       tst.b     D4
       bne       main_29
; // Deleta Arquivo
; vresp = message("Confirm\nDelete File ?\0",(BTYES | BTNO), 0);
       clr.l     -(A7)
       pea       12
       pea       @files_6.L
       jsr       _message
       add.w     #12,A7
       move.b    D0,D7
; if (vresp == 3) {
       cmp.b     #3,D7
       bne       main_36
; linhastatus(4);
       pea       4
       jsr       _linhastatus
       addq.w    #4,A7
; cfileptr = cfile + (40 * ee);
       move.l    _cfile.L,D0
       move.b    D3,D1
       and.w     #255,D1
       mulu.w    #40,D1
       and.l     #255,D1
       add.l     D1,D0
       move.l    D0,D2
; strcpy(vnomefile,cfileptr);
       move.l    D2,-(A7)
       move.l    A2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; cfileptr += 9;
       add.l     #9,D2
; if (*cfileptr != 0x00) {
       move.l    D2,A0
       move.b    (A0),D0
       beq.s     main_33
; _strcat(vnomefile,vnomefile,".");
       pea       @files_7.L
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       jsr       __strcat
       add.w     #12,A7
; _strcat(vnomefile,vnomefile,cfileptr);
       move.l    D2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       jsr       __strcat
       add.w     #12,A7
main_33:
; }
; if (fsDelFile(vnomefile) >= ERRO_D_START)
       move.l    A2,-(A7)
       jsr       _fsDelFile
       addq.w    #4,A7
       and.l     #255,D0
       cmp.l     #-16,D0
       blo.s     main_35
; message("Delete File Error.\0",(BTCLOSE), 0);
       clr.l     -(A7)
       pea       64
       pea       @files_8.L
       jsr       _message
       add.w     #12,A7
       bra.s     main_36
main_35:
; else
; carregaDir();
       jsr       _carregaDir
main_36:
; }
; break;
       bra       main_8
main_29:
; }
; else if (vopc == 1) {
       cmp.b     #1,D4
       bne       main_37
; // Renomeia Arquivo
; linhastatus(1);
       pea       1
       jsr       _linhastatus
       addq.w    #4,A7
; // Abre janela para pedir novo nome
; vstring[0] = '\0';
       clr.b     -64+0(A6)
; SaveScreen(10,40,280,50);
       pea       50
       pea       280
       pea       40
       pea       10
       jsr       _SaveScreen
       add.w     #16,A7
; strcpy(vparamstr,"Rename");
       pea       @files_4.L
       move.l    _vparamstr.L,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; vparam[0] = 10;
       move.l    (A5),A0
       move.w    #10,(A0)
; vparam[1] = 40;
       move.l    (A5),A0
       move.w    #40,2(A0)
; vparam[2] = 280;
       move.l    (A5),A0
       move.w    #280,4(A0)
; vparam[3] = 50;
       move.l    (A5),A0
       move.w    #50,6(A0)
; vparam[4] = BTOK | BTCANCEL;
       move.l    (A5),A0
       move.w    #3,8(A0)
; showWindow();
       jsr       _showWindow
; writesxy(12,55,8,"New Name:",*vcorwf,*vcorwb);
       move.l    _vcorwb.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    _vcorwf.L,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_9.L
       pea       8
       pea       55
       pea       12
       jsr       _writesxy
       add.w     #24,A7
; fillin(vstring, 120, 55, 130, WINDISP);
       clr.l     -(A7)
       pea       130
       pea       55
       pea       120
       pea       -64(A6)
       jsr       _fillin
       add.w     #20,A7
; while (1) {
main_39:
; fillin(vstring, 120, 55, 130, WINOPER);
       pea       1
       pea       130
       pea       55
       pea       120
       pea       -64(A6)
       jsr       _fillin
       add.w     #20,A7
; vwb = waitButton();
       jsr       _waitButton
       move.b    D0,D6
; if (vwb == BTOK || vwb == BTCANCEL)
       cmp.b     #1,D6
       beq.s     main_44
       cmp.b     #2,D6
       bne.s     main_42
main_44:
; break;
       bra.s     main_41
main_42:
       bra       main_39
main_41:
; }
; RestoreScreen(10,40,280,50);
       pea       50
       pea       280
       pea       40
       pea       10
       jsr       _RestoreScreen
       add.w     #16,A7
; if (vwb == BTOK) {
       cmp.b     #1,D6
       bne       main_52
; strcpy(vnomefilenew, vstring);
       pea       -64(A6)
       pea       -86(A6)
       jsr       _strcpy
       addq.w    #8,A7
; vresp = message("Confirm\nRename File ?\0",(BTYES | BTNO), 0);
       clr.l     -(A7)
       pea       12
       pea       @files_10.L
       jsr       _message
       add.w     #12,A7
       move.b    D0,D7
; if (vresp == 3) {
       cmp.b     #3,D7
       bne       main_52
; linhastatus(5);
       pea       5
       jsr       _linhastatus
       addq.w    #4,A7
; cfileptr = cfile + (40 * ee);
       move.l    _cfile.L,D0
       move.b    D3,D1
       and.w     #255,D1
       mulu.w    #40,D1
       and.l     #255,D1
       add.l     D1,D0
       move.l    D0,D2
; strcpy(vnomefile,cfileptr);
       move.l    D2,-(A7)
       move.l    A2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; cfileptr += 9;
       add.l     #9,D2
; if (*cfileptr != 0x00) {
       move.l    D2,A0
       move.b    (A0),D0
       beq.s     main_49
; _strcat(vnomefile,vnomefile,".");
       pea       @files_7.L
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       jsr       __strcat
       add.w     #12,A7
; _strcat(vnomefile,vnomefile,cfileptr);
       move.l    D2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       jsr       __strcat
       add.w     #12,A7
main_49:
; }
; if (fsRenameFile(vnomefile,vnomefilenew) >= ERRO_D_START)
       pea       -86(A6)
       move.l    A2,-(A7)
       jsr       _fsRenameFile
       addq.w    #8,A7
       and.l     #255,D0
       cmp.l     #-16,D0
       blo.s     main_51
; message("Rename File Error.\0",(BTCLOSE), 0);
       clr.l     -(A7)
       pea       64
       pea       @files_11.L
       jsr       _message
       add.w     #12,A7
       bra.s     main_52
main_51:
; else
; carregaDir();
       jsr       _carregaDir
main_52:
; }
; }
; break;
       bra       main_8
main_37:
; }
; else if (vopc == 2) {
       cmp.b     #2,D4
       bne.s     main_53
; break;
       bra       main_8
main_53:
       bra       main_65
main_9:
; }
; }
; }
; else if (*vposty > 225) {
       move.l    (A3),A0
       move.w    (A0),D0
       cmp.w     #225,D0
       bls       main_65
; // Ultima Linha
; if (*vpostx > 10 && *vpostx <= 25) {               // Flecha Esquerda
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #10,D0
       bls       main_57
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #25,D0
       bhi.s     main_57
; *vposold = *vpos;
       move.l    _vpos.L,A0
       move.l    _vposold.L,A1
       move.w    (A0),(A1)
; if (*vpos < 16)
       move.l    _vpos.L,A0
       move.w    (A0),D0
       cmp.w     #16,D0
       bhs.s     main_59
; *vpos = 0;
       move.l    _vpos.L,A0
       clr.w     (A0)
       bra.s     main_60
main_59:
; else
; *vpos -= 16;
       move.l    _vpos.L,A0
       sub.w     #16,(A0)
main_60:
; break;
       bra       main_8
main_57:
; }
; else if (*vpostx >= 30 && *vpostx <= 45) {         // Flecha Direita
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #30,D0
       blo.s     main_61
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #45,D0
       bhi.s     main_61
; *vposold = *vpos;
       move.l    _vpos.L,A0
       move.l    _vposold.L,A1
       move.w    (A0),(A1)
; *vpos += 16;
       move.l    _vpos.L,A0
       add.w     #16,(A0)
; break;
       bra       main_8
main_61:
; }
; else if (*vpostx >= 107 && *vpostx <= 187) {       // Search
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #107,D0
       blo.s     main_63
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #187,D0
       bhi.s     main_63
; break;
       bra.s     main_8
main_63:
; }
; else if (*vpostx >= 207 && *vpostx <= 287) {       // Sair
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #207,D0
       blo.s     main_65
       move.l    (A4),A0
       move.w    (A0),D0
       cmp.w     #287,D0
       bhi.s     main_65
; linhastatus(7);
       pea       7
       jsr       _linhastatus
       addq.w    #4,A7
; vcont = 0;
       clr.b     -148(A6)
; break;
       bra.s     main_8
main_65:
       bra       main_6
main_8:
       bra       main_1
main_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; }
; }
; }
; //--------------------------------------------------------------------------
; void linhastatus(BYTE vtipomsgs)
; {
       xdef      _linhastatus
_linhastatus:
       link      A6,#0
       movem.l   A2/A3/A4,-(A7)
       lea       _vcorwf.L,A2
       lea       _vcorwb.L,A3
       lea       _writesxy.L,A4
; FillRect(5,225,310,10,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       10
       pea       310
       pea       225
       pea       5
       jsr       _FillRect
       add.w     #20,A7
; switch (vtipomsgs) {
       move.b    11(A6),D0
       and.l     #255,D0
       cmp.l     #8,D0
       bhs       linhastatus_2
       asl.l     #1,D0
       move.w    linhastatus_3(PC,D0.L),D0
       jmp       linhastatus_3(PC,D0.W)
linhastatus_3:
       dc.w      linhastatus_4-linhastatus_3
       dc.w      linhastatus_5-linhastatus_3
       dc.w      linhastatus_6-linhastatus_3
       dc.w      linhastatus_7-linhastatus_3
       dc.w      linhastatus_8-linhastatus_3
       dc.w      linhastatus_9-linhastatus_3
       dc.w      linhastatus_10-linhastatus_3
       dc.w      linhastatus_11-linhastatus_3
linhastatus_4:
; case 0:
; locatexy(10,225);
       pea       225
       pea       10
       jsr       _locatexy
       addq.w    #8,A7
; writecxy(8,'<',*vcorwb,*vcorwf);     // flecha esq
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       60
       pea       8
       jsr       _writecxy
       add.w     #16,A7
; locatexy(30,225);
       pea       225
       pea       30
       jsr       _locatexy
       addq.w    #8,A7
; writecxy(8,'>',*vcorwb,*vcorwf);     // flecha dir
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       62
       pea       8
       jsr       _writecxy
       add.w     #16,A7
; writesxy(107,225,8,"search\0",*vcorwb,*vcorwf);     // Search
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_12.L
       pea       8
       pea       225
       pea       107
       jsr       (A4)
       add.w     #24,A7
; writesxy(207,225,8,"exit\0",*vcorwb,*vcorwf);     // Sair
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_13.L
       pea       8
       pea       225
       pea       207
       jsr       (A4)
       add.w     #24,A7
; break;
       bra       linhastatus_2
linhastatus_5:
; case 1:
; writesxy(7,225,8,"wait...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_14.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
       bra       linhastatus_2
linhastatus_6:
; case 2:
; writesxy(7,225,8,"processing...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_15.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
       bra       linhastatus_2
linhastatus_7:
; case 3:
; writesxy(7,225,8,"file not found...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_16.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
       bra       linhastatus_2
linhastatus_8:
; case 4:
; writesxy(7,225,8,"Deleting file...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_17.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
       bra       linhastatus_2
linhastatus_9:
; case 5:
; writesxy(7,225,8,"Renaming file...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_18.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
       bra       linhastatus_2
linhastatus_10:
; case 6:
; writesxy(7,225,8,"New file name exist...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_19.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
       bra.s     linhastatus_2
linhastatus_11:
; case 7:
; writesxy(7,225,8,"Exiting...\0",*vcorwb,*vcorwf);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @files_20.L
       pea       8
       pea       225
       pea       7
       jsr       (A4)
       add.w     #24,A7
; break;
linhastatus_2:
       movem.l   (A7)+,A2/A3/A4
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------
; void carregaDir(void)
; {
       xdef      _carregaDir
_carregaDir:
       link      A6,#-72
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -14(A6),A2
       lea       _vdir.L,A3
       lea       -46(A6),A4
       lea       _itoa.L,A5
; BYTE vcont, ikk, ix, iy, cc, dd, ee, cnum[20], *cfileptr;
; BYTE vnomefile[32];
; BYTE sqtdtam[10], cuntam;
; unsigned long vtotbytes = 0, vqtdtam;
       clr.l     -4(A6)
; // Leitura dos Arquivos
; cfileptr = cfile;
       move.l    _cfile.L,D2
; *cfileptr = 0x00;
       move.l    D2,A0
       clr.b     (A0)
; // Logica de leitura Diretorio FAT32
; if (fsFindInDir(NULL, TYPE_FIRST_ENTRY) < ERRO_D_START) {
       pea       8
       clr.l     -(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #-16,D0
       bhs       carregaDir_5
; while (1) {
carregaDir_3:
; if (vdir->Attr != ATTR_VOLUME) {
       move.l    (A3),A0
       move.b    14(A0),D0
       cmp.b     #8,D0
       beq       carregaDir_6
; // Nome
; for (cc = 0; cc <= 7; cc++) {
       clr.b     D5
carregaDir_8:
       cmp.b     #7,D5
       bhi       carregaDir_10
; if (vdir->Name[cc] >= 32) {
       move.l    (A3),A0
       and.l     #255,D5
       move.b    0(A0,D5.L),D0
       cmp.b     #32,D0
       blo.s     carregaDir_11
; *cfileptr++ = vdir->Name[cc];
       move.l    (A3),A0
       and.l     #255,D5
       move.l    D2,A1
       addq.l    #1,D2
       move.b    0(A0,D5.L),(A1)
       bra.s     carregaDir_12
carregaDir_11:
; }
; else
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
carregaDir_12:
       addq.b    #1,D5
       bra       carregaDir_8
carregaDir_10:
; }
; *cfileptr++ = '\0';
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
; // Extensão
; for (cc = 8; cc <= 10; cc++) {
       moveq     #8,D5
carregaDir_13:
       cmp.b     #10,D5
       bhi       carregaDir_15
; ikk = cc - 8;
       move.b    D5,D0
       subq.b    #8,D0
       move.b    D0,-69(A6)
; if (vdir->Ext[ikk] >= 32) {
       move.l    (A3),A0
       move.b    -69(A6),D0
       and.l     #255,D0
       add.l     D0,A0
       move.b    10(A0),D0
       cmp.b     #32,D0
       blo.s     carregaDir_16
; *cfileptr++ = vdir->Ext[ikk];
       move.l    (A3),A0
       move.b    -69(A6),D0
       and.l     #255,D0
       add.l     D0,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    10(A0),(A1)
       bra.s     carregaDir_17
carregaDir_16:
; }
; else
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
carregaDir_17:
       addq.b    #1,D5
       bra       carregaDir_13
carregaDir_15:
; }
; *cfileptr++ = '\0';
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
; // Data Ultima Modificacao
; // Mes
; vqtdtam = (vdir->UpdateDate & 0x01E0) >> 5;
       move.l    (A3),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       and.l     #480,D0
       lsr.l     #5,D0
       move.l    D0,D4
; if (vqtdtam < 1 || vqtdtam > 12)
       cmp.l     #1,D4
       blo.s     carregaDir_20
       cmp.l     #12,D4
       bls.s     carregaDir_18
carregaDir_20:
; vqtdtam = 1;
       moveq     #1,D4
carregaDir_18:
; vqtdtam--;
       subq.l    #1,D4
; *cfileptr++ = vmesc[vqtdtam][0];
       move.l    D4,D0
       muls      #3,D0
       lea       _vmesc.L,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    0(A0,D0.L),(A1)
; *cfileptr++ = vmesc[vqtdtam][1];
       move.l    D4,D0
       muls      #3,D0
       lea       _vmesc.L,A0
       add.l     D0,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    1(A0),(A1)
; *cfileptr++ = vmesc[vqtdtam][2];
       move.l    D4,D0
       muls      #3,D0
       lea       _vmesc.L,A0
       add.l     D0,A0
       move.l    D2,A1
       addq.l    #1,D2
       move.b    2(A0),(A1)
; *cfileptr++ = '/';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #47,(A0)
; // Dia
; vqtdtam = vdir->UpdateDate & 0x001F;
       move.l    (A3),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       and.l     #31,D0
       move.l    D0,D4
; memset(sqtdtam, 0x0, 10);
       pea       10
       clr.l     -(A7)
       move.l    A2,-(A7)
       jsr       _memset
       add.w     #12,A7
; itoa(vqtdtam, sqtdtam, 10);
       pea       10
       move.l    A2,-(A7)
       move.l    D4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if (vqtdtam < 10) {
       cmp.l     #10,D4
       bhs.s     carregaDir_21
; *cfileptr++ = '0';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #48,(A0)
; *cfileptr++ = sqtdtam[0];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A2),(A0)
       bra.s     carregaDir_22
carregaDir_21:
; }
; else {
; *cfileptr++ = sqtdtam[0];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A2),(A0)
; *cfileptr++ = sqtdtam[1];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    1(A2),(A0)
carregaDir_22:
; }
; *cfileptr++ = '/';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #47,(A0)
; // Ano
; vqtdtam = ((vdir->UpdateDate & 0xFE00) >> 9) + 1980;
       move.l    (A3),A0
       move.w    22(A0),D0
       and.l     #65535,D0
       and.l     #65024,D0
       lsr.l     #8,D0
       lsr.l     #1,D0
       add.l     #1980,D0
       move.l    D0,D4
; memset(sqtdtam, 0x0, 10);
       pea       10
       clr.l     -(A7)
       move.l    A2,-(A7)
       jsr       _memset
       add.w     #12,A7
; itoa(vqtdtam, sqtdtam, 10);
       pea       10
       move.l    A2,-(A7)
       move.l    D4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; *cfileptr++ = sqtdtam[0];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A2),(A0)
; *cfileptr++ = sqtdtam[1];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    1(A2),(A0)
; *cfileptr++ = sqtdtam[2];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    2(A2),(A0)
; *cfileptr++ = sqtdtam[3];
       move.l    D2,A0
       addq.l    #1,D2
       move.b    3(A2),(A0)
; *cfileptr++ = '\0';
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
; // Tamanho
; if (vdir->Attr != ATTR_DIRECTORY) {
       move.l    (A3),A0
       move.b    14(A0),D0
       cmp.b     #16,D0
       beq       carregaDir_23
; // Reduz o tamanho a unidade (GB, MB ou KB)
; vqtdtam = vdir->Size;
       move.l    (A3),A0
       move.l    30(A0),D4
; if ((vqtdtam & 0xC0000000) != 0) {
       move.l    D4,D0
       and.l     #-1073741824,D0
       beq.s     carregaDir_25
; cuntam = 'G';
       moveq     #71,D7
; vqtdtam = ((vqtdtam & 0xC0000000) >> 30) + 1;
       move.l    D4,D0
       and.l     #-1073741824,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       lsr.l     #6,D0
       addq.l    #1,D0
       move.l    D0,D4
       bra       carregaDir_30
carregaDir_25:
; }
; else if ((vqtdtam & 0x3FF00000) != 0) {
       move.l    D4,D0
       and.l     #1072693248,D0
       beq.s     carregaDir_27
; cuntam = 'M';
       moveq     #77,D7
; vqtdtam = ((vqtdtam & 0x3FF00000) >> 20) + 1;
       move.l    D4,D0
       and.l     #1072693248,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       lsr.l     #4,D0
       addq.l    #1,D0
       move.l    D0,D4
       bra.s     carregaDir_30
carregaDir_27:
; }
; else if ((vqtdtam & 0x000FFC00) != 0) {
       move.l    D4,D0
       and.l     #1047552,D0
       beq.s     carregaDir_29
; cuntam = 'K';
       moveq     #75,D7
; vqtdtam = ((vqtdtam & 0x000FFC00) >> 10) + 1;
       move.l    D4,D0
       and.l     #1047552,D0
       lsr.l     #8,D0
       lsr.l     #2,D0
       addq.l    #1,D0
       move.l    D0,D4
       bra.s     carregaDir_30
carregaDir_29:
; }
; else
; cuntam = ' ';
       moveq     #32,D7
carregaDir_30:
; // Transforma para decimal
; memset(sqtdtam, 0x0, 10);
       pea       10
       clr.l     -(A7)
       move.l    A2,-(A7)
       jsr       _memset
       add.w     #12,A7
; itoa(vqtdtam, sqtdtam, 10);
       pea       10
       move.l    A2,-(A7)
       move.l    D4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; // Primeira Parte da Linha do dir, tamanho
; for(ix = 0; ix <= 3; ix++) {
       clr.b     D3
carregaDir_31:
       cmp.b     #3,D3
       bhi.s     carregaDir_33
; if (sqtdtam[ix] == 0)
       and.l     #255,D3
       move.b    0(A2,D3.L),D0
       bne.s     carregaDir_34
; break;
       bra.s     carregaDir_33
carregaDir_34:
       addq.b    #1,D3
       bra       carregaDir_31
carregaDir_33:
; }
; iy = (4 - ix);
       moveq     #4,D0
       sub.b     D3,D0
       move.b    D0,D6
; for(ix = 0; ix <= 3; ix++) {
       clr.b     D3
carregaDir_36:
       cmp.b     #3,D3
       bhi       carregaDir_38
; if (iy <= ix) {
       cmp.b     D3,D6
       bhi.s     carregaDir_39
; ikk = ix - iy;
       move.b    D3,D0
       sub.b     D6,D0
       move.b    D0,-69(A6)
; *cfileptr++ = sqtdtam[ikk];
       move.b    -69(A6),D0
       and.l     #255,D0
       move.l    D2,A0
       addq.l    #1,D2
       move.b    0(A2,D0.L),(A0)
       bra.s     carregaDir_40
carregaDir_39:
; }
; else
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
carregaDir_40:
       addq.b    #1,D3
       bra       carregaDir_36
carregaDir_38:
; }
; *cfileptr++ = cuntam;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D7,(A0)
       bra.s     carregaDir_24
carregaDir_23:
; }
; else {
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = '0';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #48,(A0)
carregaDir_24:
; }
; *cfileptr++ = '\0';
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
; // Atributos
; if (vdir->Attr == ATTR_DIRECTORY) {
       move.l    (A3),A0
       move.b    14(A0),D0
       cmp.b     #16,D0
       bne       carregaDir_41
; *cfileptr++ = '<';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #60,(A0)
; *cfileptr++ = 'D';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #68,(A0)
; *cfileptr++ = 'I';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #73,(A0)
; *cfileptr++ = 'R';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #82,(A0)
; *cfileptr++ = '>';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #62,(A0)
       bra.s     carregaDir_42
carregaDir_41:
; }
; else {
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
; *cfileptr++ = ' ';
       move.l    D2,A0
       addq.l    #1,D2
       move.b    #32,(A0)
carregaDir_42:
; }
; *cfileptr++ = '\0';
       move.l    D2,A0
       addq.l    #1,D2
       clr.b     (A0)
; cfileptr += 3;    // para fechar 40 pos
       addq.l    #3,D2
; *cfileptr = 0x00;
       move.l    D2,A0
       clr.b     (A0)
carregaDir_6:
; }
; // Verifica se tem mais Arquivos
; for (ix = 0; ix <= 7; ix++) {
       clr.b     D3
carregaDir_43:
       cmp.b     #7,D3
       bhi.s     carregaDir_45
; vnomefile[ix] = vdir->Name[ix];
       move.l    (A3),A0
       and.l     #255,D3
       and.l     #255,D3
       move.b    0(A0,D3.L),0(A4,D3.L)
; if (vnomefile[ix] == 0x20) {
       and.l     #255,D3
       move.b    0(A4,D3.L),D0
       cmp.b     #32,D0
       bne.s     carregaDir_46
; vnomefile[ix] = '\0';
       and.l     #255,D3
       clr.b     0(A4,D3.L)
; break;
       bra.s     carregaDir_45
carregaDir_46:
       addq.b    #1,D3
       bra       carregaDir_43
carregaDir_45:
; }
; }
; vnomefile[ix] = '\0';
       and.l     #255,D3
       clr.b     0(A4,D3.L)
; if (vdir->Name[0] != '.') {
       move.l    (A3),A0
       move.b    (A0),D0
       cmp.b     #46,D0
       beq       carregaDir_48
; vnomefile[ix] = '.';
       and.l     #255,D3
       move.b    #46,0(A4,D3.L)
; ix++;
       addq.b    #1,D3
; for (iy = 0; iy <= 2; iy++) {
       clr.b     D6
carregaDir_50:
       cmp.b     #2,D6
       bhi.s     carregaDir_52
; vnomefile[ix] = vdir->Ext[iy];
       move.l    (A3),A0
       and.l     #255,D6
       add.l     D6,A0
       and.l     #255,D3
       move.b    10(A0),0(A4,D3.L)
; if (vnomefile[ix] == 0x20) {
       and.l     #255,D3
       move.b    0(A4,D3.L),D0
       cmp.b     #32,D0
       bne.s     carregaDir_53
; vnomefile[ix] = '\0';
       and.l     #255,D3
       clr.b     0(A4,D3.L)
; break;
       bra.s     carregaDir_52
carregaDir_53:
; }
; ix++;
       addq.b    #1,D3
       addq.b    #1,D6
       bra       carregaDir_50
carregaDir_52:
; }
; vnomefile[ix] = '\0';
       and.l     #255,D3
       clr.b     0(A4,D3.L)
carregaDir_48:
; }
; if (fsFindInDir(vnomefile, TYPE_NEXT_ENTRY) >= ERRO_D_START)
       pea       9
       move.l    A4,-(A7)
       jsr       _fsFindInDir
       addq.w    #8,A7
       cmp.l     #-16,D0
       blo.s     carregaDir_55
; break;
       bra.s     carregaDir_5
carregaDir_55:
       bra       carregaDir_3
carregaDir_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; }
; //--------------------------------------------------------------------------
; void listaDir(void)
; {
       xdef      _listaDir
_listaDir:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/A2/A3/A4/A5,-(A7)
       lea       _vcorwb.L,A2
       lea       _vcorwf.L,A3
       lea       _writesxy.L,A4
       lea       _vpos.L,A5
; WORD pposx, pposy, vretfs, dd, ww;
; BYTE *cfilepos, ee;
; for (dd = 0; dd <= 15; dd++)
       clr.w     D2
listaDir_1:
       cmp.w     #15,D2
       bhi.s     listaDir_3
; clinha[dd] = 0x00;
       move.l    _clinha.L,A0
       and.l     #65535,D2
       clr.b     0(A0,D2.L)
       addq.w    #1,D2
       bra       listaDir_1
listaDir_3:
; pposy = 34;
       moveq     #34,D5
; dd = *vpos;
       move.l    (A5),A0
       move.w    (A0),D2
; ee = 16;
       moveq     #16,D6
; cfilepos = cfile + (40 * dd);
       move.l    _cfile.L,D0
       move.w    D2,D1
       mulu.w    #40,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,D3
; while(*cfilepos) {
listaDir_4:
       move.l    D3,A0
       tst.b     (A0)
       beq       listaDir_6
; // Nome
; pposx = 7;
       moveq     #7,D4
; writesxy(pposx,pposy,8,cfilepos,*vcorwf,*vcorwb);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       8
       and.l     #65535,D5
       move.l    D5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #24,A7
; // Ext
; pposx = 80;
       moveq     #80,D4
; cfilepos += 9;
       add.l     #9,D3
; writesxy(pposx,pposy,8,cfilepos,*vcorwf,*vcorwb);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       8
       and.l     #65535,D5
       move.l    D5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #24,A7
; // Modif
; pposx = 112;
       moveq     #112,D4
; cfilepos += 4;
       addq.l    #4,D3
; writesxy(pposx,pposy,8,cfilepos,*vcorwf,*vcorwb);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       8
       and.l     #65535,D5
       move.l    D5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #24,A7
; // Tamanho
; pposx = 200;
       move.w    #200,D4
; cfilepos += 12;
       add.l     #12,D3
; writesxy(pposx,pposy,8,cfilepos,*vcorwf,*vcorwb);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       8
       and.l     #65535,D5
       move.l    D5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #24,A7
; // Atrib
; pposx = 264;
       move.w    #264,D4
; cfilepos += 6;
       addq.l    #6,D3
; writesxy(pposx,pposy,8,cfilepos,*vcorwf,*vcorwb);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    (A3),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       8
       and.l     #65535,D5
       move.l    D5,-(A7)
       and.l     #65535,D4
       move.l    D4,-(A7)
       jsr       (A4)
       add.w     #24,A7
; clinha[dd] = pposy;
       move.l    _clinha.L,A0
       and.l     #65535,D2
       move.b    D5,0(A0,D2.L)
; pposy += 10;
       add.w     #10,D5
; dd++;
       addq.w    #1,D2
; ee--;
       subq.b    #1,D6
; if (ee == 0)
       tst.b     D6
       bne.s     listaDir_7
; break;
       bra.s     listaDir_6
listaDir_7:
; cfilepos = cfile + (40 * dd);
       move.l    _cfile.L,D0
       move.w    D2,D1
       mulu.w    #40,D1
       and.l     #65535,D1
       add.l     D1,D0
       move.l    D0,D3
       bra       listaDir_4
listaDir_6:
; }
; if (dd == *vpos)
       move.l    (A5),A0
       cmp.w     (A0),D2
       bne.s     listaDir_9
; *vpos = *vposold;
       move.l    _vposold.L,A0
       move.l    (A5),A1
       move.w    (A0),(A1)
listaDir_9:
; if (ee > 0) {
       cmp.b     #0,D6
       bls       listaDir_11
; dd = 16 - ee;
       moveq     #16,D0
       ext.w     D0
       and.w     #255,D6
       sub.w     D6,D0
       move.w    D0,D2
; dd = dd * 10;
       move.w    D2,D0
       mulu.w    #10,D0
       move.w    D0,D2
; dd = dd + 34;
       add.w     #34,D2
; ww = ee * 10;
       move.b    D6,D0
       and.w     #255,D0
       mulu.w    #10,D0
       move.w    D0,-2(A6)
; FillRect(6,dd,309,ww,*vcorwb);
       move.l    (A2),A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -2(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       309
       and.l     #65535,D2
       move.l    D2,-(A7)
       pea       6
       jsr       _FillRect
       add.w     #20,A7
listaDir_11:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //--------------------------------------------------------------------------
; void SearchFile(void)
; {
       xdef      _SearchFile
_SearchFile:
       rts
; }
       section   const
@files_1:
       dc.b      70,105,108,101,32,69,120,112,108,111,114,101
       dc.b      114,32,118,48,46,49,0
@files_2:
       dc.b      78,97,109,101,32,32,32,32,32,69,120,116,32,77
       dc.b      111,100,105,102,121,32,32,32,32,32,32,83,105
       dc.b      122,101,32,32,32,65,116,114,105,98,0
@files_3:
       dc.b      68,101,108,101,116,101,0
@files_4:
       dc.b      82,101,110,97,109,101,0
@files_5:
       dc.b      67,108,111,115,101,0
@files_6:
       dc.b      67,111,110,102,105,114,109,10,68,101,108,101
       dc.b      116,101,32,70,105,108,101,32,63,0
@files_7:
       dc.b      46,0
@files_8:
       dc.b      68,101,108,101,116,101,32,70,105,108,101,32
       dc.b      69,114,114,111,114,46,0
@files_9:
       dc.b      78,101,119,32,78,97,109,101,58,0
@files_10:
       dc.b      67,111,110,102,105,114,109,10,82,101,110,97
       dc.b      109,101,32,70,105,108,101,32,63,0
@files_11:
       dc.b      82,101,110,97,109,101,32,70,105,108,101,32,69
       dc.b      114,114,111,114,46,0
@files_12:
       dc.b      115,101,97,114,99,104,0
@files_13:
       dc.b      101,120,105,116,0
@files_14:
       dc.b      119,97,105,116,46,46,46,0
@files_15:
       dc.b      112,114,111,99,101,115,115,105,110,103,46,46
       dc.b      46,0
@files_16:
       dc.b      102,105,108,101,32,110,111,116,32,102,111,117
       dc.b      110,100,46,46,46,0
@files_17:
       dc.b      68,101,108,101,116,105,110,103,32,102,105,108
       dc.b      101,46,46,46,0
@files_18:
       dc.b      82,101,110,97,109,105,110,103,32,102,105,108
       dc.b      101,46,46,46,0
@files_19:
       dc.b      78,101,119,32,102,105,108,101,32,110,97,109
       dc.b      101,32,101,120,105,115,116,46,46,46,0
@files_20:
       dc.b      69,120,105,116,105,110,103,46,46,46,0
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
       xdef      _cfile
_cfile:
       dc.l      8511488
       xdef      _clinha
_clinha:
       dc.l      8511456
       xdef      _vpos
_vpos:
       dc.l      8511472
       xdef      _vposold
_vposold:
       dc.l      8511474
       xref      _writecxy
       xref      _writesxy
       xref      _fsFindInDir
       xref      _strcpy
       xref      _itoa
       xref      _fillin
       xref      _DrawRect
       xref      _FillRect
       xref      _fsRenameFile
       xref      ULMUL
       xref      _DrawLine
       xref      _RestoreScreen
       xref      _SaveScreen
       xref      _waitButton
       xref      _InvertRect
       xref      _memset
       xref      _showWindow
       xref      _VerifyTouchLcd
       xref      _message
       xref      _fsDelFile
       xref      _locatexy
