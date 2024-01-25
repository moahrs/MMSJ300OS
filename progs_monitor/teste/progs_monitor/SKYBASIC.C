// SkyBASIC ovviamente post-dedicato a Irene B. 18/10 -> 1/12/1994

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <math.h>
#include "../mmsj300api.h"
#include "../monitor.h"
#include "skybasic.h"

void main(void) {
  char Exit=0;
  int t;
  char i,d;
  char sNumLin [sizeof(long)*8+1];

#ifndef MC68000
	OldCtrl_C=_dos_getvect(0x23);
	_dos_setvect(0x23,Ctrl_C);
#endif

  ExecStmt(0x81);           // esegue NEW

ColdStart:
	clearScr();
  printText("SkyBasic v");
  itoa((VERSIONE >> 8), sNumLin, 10);
  printText(sNumLin);
  printText(".");
  itoa((VERSIONE & 0xff), sNumLin, 10);
  printText(sNumLin);
  printText(" (C) ADPM Synthesis 1994\r\n");
  itoa((MemTop-PrgBase), sNumLin, 10);
  printText(sNumLin);
  printText(" Bytes Free");
  d=1;
WarmStart:
  do {
	  DirectMode=1;
	  fStop=0;
	  fError=0;
	  TextP=DirectBuf;
	  if(d)
		  printText("\r\nReady\r\n");
		GetLine();
		t=Tokenize();
		writeLongSerial("Aqui Return Tokenize Command...\r\n");


/*
    i=0;
	printf("Tokenize: ");
	while(TextP[i]) {
	  printf("%02x ",(unsigned int)TextP[i++]);
	  }
//	printText('\r\n', 1);
*/

		if(*TextP >= '0' && *TextP <= '9') {
		  StoreLine(t);
		  d=0;
		  }
		else {
		  i=ExecLine();
//		  printf("EXEC: %x",(unsigned int)i);
		  if(i<0) {
			  if(i==-1)
					Exit=1;
			  else
					i=-i;
			  }
		  if(i>0)
			  DoError(i);
			d=1;
		  }
		} while(!Exit);

#ifndef MC68000
	_dos_setvect(0x23,OldCtrl_C);
#endif
  }

void cursOn(void)
{

}

void cursOff(void)
{

}

int outp(unsigned long pPerif, unsigned int pData)
{
	return 0;
}

unsigned long inp (unsigned long pPerif)
{
	return 0;
}

static unsigned long int next = 1;

int rand(void) // RAND_MAX assumed to be 32767
{
    next = next * 1103515245 + 12345;
    return (unsigned int)(next/65536) % 32768;
}

void srand(unsigned int seed)
{
    next = seed;
}

char myIsxdigit(char x)
{
	switch (x)
	{
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		case 'A':
		case 'B':
		case 'C':
		case 'D':
		case 'E':
		case 'F':
			return 1;
			break;
	}

	return 0;
}

int myIsalpha(int a)
{
	if ((a >= 0x41 && a <= 0x5A) || (a >= 0x61 && a <= 0x7A))
		return 1;

	return 0;
}

int myIsprint( int ch )
{
	if (ch >= 0x20 && ch <= 0xFF)
		return 1;

	return 0;
}

int myIsalnum(int a)
{
	if ((a >= 0x41 && a <= 0x5A) || (a >= 0x61 && a <= 0x7A) || (a >= 0x30 && a <= 0x39))
		return 1;

	return 0;
}

/*
The C library function clock_t clock(void) returns the number of clock ticks elapsed since the program was launched
*/
long int clock(void)
{
	long int x = 0;

	return x;
}

int myStrnicmp(const char* s1, const char* s2, int n)
{

  if (n == 0)
    return 0;

  do {
    if (tolower((unsigned char) *s1) != tolower((unsigned char) *s2++))
      return (int)tolower((unsigned char)*s1) - (int) tolower((unsigned char) *--s2);
    if (*s1++ == 0)
      break;
  } while (--n != 0);

  return 0;
}

void scanf(const char* s2)
{

}

long myAtoi(void)
{
  long i;
  char ch;
  char m=0;

  i=0l;
  ch=*TextP;
  while(ch >='0' && ch <='9' || ch=='.') {
		if(ch=='.')
		  m=1;
		if(!m) {
//      i=i*10l;
		  i*=10l;
		  i+=(unsigned long)(ch-'0');
//      i=i+(unsigned long)(ch-'0');
		  }
		TextP++;
		ch=*TextP;
		}

  return i;
  }

int myXtoi(void)
{
  int i;
  char ch;

  i=0;
  for(;;) {
		ch=*TextP;
		if(!myIsxdigit(ch))
		  break;
		ch-='0';
		if(ch>=10) {			                  // >= è meglio di >
			if(ch>=0x30)
			  ch -= 0x20;
		  ch-=7;
		  }
		i=(i << 4)+(unsigned int)ch;
		TextP++;
		}

  return i;
}

int Tokenize() {
  /*register*/ char *p;
  char *p1,*p2;
  int i,j,t;
  char *k = 0x00;

  t=0;
  p=TextP;
  while(*p) {
//  printf("p vale %02x\r\n",*p);
	  if(*p>='0' && *p<='9') {
			p++;
			}
	  else if(*p == '"') {
			p++;
			while(*p && *p!='"') {
			  p++;
			  t++;
			  }
			}
	  else if(myIsalpha(*p)) {
//          p++;
			p1=p;
//          while(myIsalpha(*p)) {
//            p++;
//          }
			i=0;
			while(k==KeyWords[i]) {
			  j=strlen(k);
			  if(!myStrnicmp(k,p1,j)) {
//        printf("trovo %d\r\n",i);
					*p1++=i | 0x80;
//                  p=p+j;
					strcpy(p1,p+j);
					p=p1;
					break;
					}
			  i++;
				}
			if(!k) {
				p1=p;
					i=0;
					while(k==Funct[i]) {
					  j=strlen(k);
					  if(!myStrnicmp(k,p1,j)) {
							*p1++=i | 0xc0;
	//                      p=p+strlen(Funct[i]);
							strcpy(p1,p+j);
							p=p1;
							break;
							}
					  i++;
					}
				if(!k) {
				  p++;
				  }
			  }
			}
	  else if(*p=='?') {               // gestisco PRINT
			*p++=0x86;
			}
	  else if(*p==0x27) {               // gestisco REM
			*p++=0x87;
			}
	  else {
			p++;
			}
		t++;
	  }
	return t;
  }

int GetLine(void) {
  unsigned char ch;
  char i;
  /*register*/ char *p;
  char sNumLin [sizeof(long)*8+1];

  cursOn();
  p=TextP;
  *p=0;
  i=0;
  ch=0;
  do {
		ch = 0;
    *vBufReceived = 0x00;
	  while (*vBufReceived == 0x00)
		  readChar();
	  ch = *vBufReceived;

		if(ch) {
		  if(myIsprint(ch)) {
				if(i < BUF_SIZE) {
				  printChar(ch,1);
				  *p++=ch;
				  *p=0;
				  i++;
				  }
				else {
				  printChar(7,1);
				  }
				}
			else {
Get2:
				if(ch==8) {
				  if(i>0) {
					  printChar(8,1);
					  i--;
					  p--;
					  *p=0;
					  }
					else
					  printChar(7,1);
				}
			}
		}
	} while(ch != 13);
  printChar(13,1);
  printChar(10,1);
//  p--;
  *p=0;

  cursOff();

/*  i=0;
	printf("GETLINE: ");
	while(TextP[i]) {
	  printf("%02x ",TextP[i++]);
	  }
	printText('\r\n',1);
	*/

	return 0;
  }

int StoreLine(int t) {
  /*register*/ char **p;
  char *p1;
  int i;
  long n;
  char m;
  unsigned char sqtdtam[10];

  p=TextP;
  n=myAtoi();
//  printf("n vale %x; ",n);
//  t=t-(TextP-p);
//  while(*TextP >= '0' && *TextP <= '9') {
//    TextP++;
//    t--;
//    }
  m=0;
//  p=TextP;
  while(*TextP) {                   // m=0 se si vuole cancellare la riga data
		if(*TextP != ' ') {
		  m=1;
//      p=TextP;
		  break;
		  }
		TextP++;
		}
//  TextP=p;
  t=t-(TextP-p);
	writeLongSerial("Aqui 666.0 before CercaLine...\r\n");
  if(m) {
	  if(p==CercaLine(n,0)) {
			p1=p+2;
			i=4;
			while(*p1++)
			  i++;
//      printf("sostituisco %d a %x %x %x\r\n",n,p,p1,VarEnd-p1);
	writeLongSerial("Aqui 666.1 before myMemMove...\r\n");
			myMemMove(p,p1,*VarEnd-p1);
		  *VarBase = *VarBase - i;
			}
	  else {
		  if(!(p==CercaLine(n,1)))
			  p= *VarBase - 2;
			}
//    printf("\ap vale %x, t=%x, varbase %x\r\n",p,t,VarBase);
	  i=t+5;
	writeLongSerial("Aqui 666.2 before myMemMove...");
    itoa(((char *)p)+i, sqtdtam, 16);
    writeLongSerial(sqtdtam);
    writeLongSerial("...");
    itoa(p, sqtdtam, 16);
    writeLongSerial(sqtdtam);
    writeLongSerial("...");
    itoa(*VarEnd, sqtdtam, 16);
    writeLongSerial(sqtdtam);
    writeLongSerial("...");
    itoa(*VarEnd-p, sqtdtam, 16);
    writeLongSerial(sqtdtam);
    writeLongSerial("...\r\n");
	  myMemMove(((char *)p)+i,p,*VarEnd-p);
	  *VarBase = *VarBase + i;
	  p[1]=n;
	  p1=p+2;
	writeLongSerial("Aqui 666.3 before strcpy...\r\n");
	  strcpy(p1,TextP);
	  *(p1+t+1)=0;
	  *p=((char *)p)+i;
//    printf("memorizzo %d, next link %x\r\n",t,p+i);
	  }
	else {
	  if(p==CercaLine(n,0)) {
//    printf("p vale %x, varbase %x\r\n",p,VarBase);
			p1=p+2;
			i=4;
			while(*p1++)
			  i++;
//      printf("cancello %d a %x %x %x\r\n",n,p,p1,VarEnd-p1);
		  myMemMove(p,p1,*VarEnd-p1);
		  *VarBase = *VarBase - i;
//    printf("p vale %x, varbase %x\r\n",p,VarBase);
			}
	  }
	writeLongSerial("Aqui 666.4 before RelinkBasic...\r\n");
  RelinkBasic();
	writeLongSerial("Aqui 666.5 after RelinkBasic...\r\n");

  return 0;
  }

int RelinkBasic(void) {
  /*register*/ char **p,*p1;

//  printf("RELINK: ");
	writeLongSerial("Aqui 667.1 start RelinkBasic...\r\n");
  p=PrgBase;
	writeLongSerial("Aqui 667.1.0 before first while...\r\n");
  while(*p) {                    // se non è finito...
		p1=p+2;
	writeLongSerial("Aqui 667.1.1 before second while...\r\n");
		while(*p1++);
		*p=p1;
		p=p1;
	writeLongSerial("Aqui 667.1.2 before end first while...\r\n");
		}
	writeLongSerial("Aqui 667.2 after while...\r\n");
  *VarBase = p + 1;
  *VarEnd = *VarBase;
  *StrBase = MemTop;
	writeLongSerial("Aqui 667.3 exit RelinkBasic...\r\n");
//  printf("prgbase %x, varbase %x, varend %x\r\n",PrgBase,VarBase,VarEnd);
  return 0;
  }

char *HandleVar(char mode, char *flags) {               // mode = 1 SET, 0 GET
  char nome[4];
  int i;
  char ch,j;
  char *p;
  char *VarPtr;

  i=0;
  *flags=0;
  *(long *)&nome=0l;
  SkipSpaces();
  ch=*TextP;
  if(myIsalpha(ch)) {
rifo:
	  nome[i]=*TextP++ & 0xdf;
rifo2:
	  switch(*TextP) {
			case '%':
			  *flags |= INT_FLAG;
			  nome[0] |= 0x80;
			  nome[1] |= 0x80;
			  TextP++;
			  break;
			case '$':
			  *flags |= STR_FLAG;
			  nome[1] |= 0x80;
				// manca un controllo su entrambi i flags
			  TextP++;
			  break;
			case '(':
			  goto HndVar2;
			  break;
			default:
				ch=*TextP;
			  j=myIsalnum(ch);
			  if(i<1) {
					if(ch && j) {
					  i++;
					  goto rifo;
					  }
					}
			  else {
					if(ch && j) {
					  do {
							ch=*(++TextP);
							} while(ch && myIsalnum(ch));
					  goto rifo2;
					  }
					}
		  	break;
		}

	  VarPtr=0;
	  p = *VarBase;
	  while(p<*VarEnd) {
			if(*(int *)&nome==*(int *)p) {       // trovata
			  VarPtr=p+2;
			  break;
			  }
			p+=VAR_SIZE;
			}
	  if(!VarPtr) {
			p=*VarEnd;
			*p++=nome[0];
			*p++=nome[1];
			*(long *)p=0l;
			VarPtr=*VarEnd+2;
			*VarEnd=*VarEnd + VAR_SIZE;
			}
	  return VarPtr;
  }
	else {
HndVar2:
	  fError=1;
	  return 0;
  }

  return 0;
}


char ExecStmt(unsigned char n) {
  char RetVal=0;
  char *p = 0x00,*p1 = 0x00;
  char Fl = 0x00,Fl1 = 0x00;
  char ch;
  /*register*/ int i,i1;
  long l;                        // deve diventare long
  char *OldText=0,*OldVar;         // per il gosub, for
  long ToVal,StVal;              // per il for..next
  char sNumLin [sizeof(short)*8+1];

	writeLongSerial("Aqui ExecStmt Command 2...");
	itoa(n, sNumLin, 10);
  printText(sNumLin);
  printText("...\r\n");

	switch(n) {
//      case 0:
//        DirectMode=1;
//        break;
		case 0x80:
		  RetVal=-1;
			break;
		case 0x81:                 // new
			*PrgBase=0;
			*(PrgBase + 1)=0;
			*VarBase=PrgBase+2;
		case 0x83:                 // run/clr
doClr:
			*VarEnd=*VarBase;
			*StrBase=MemTop;
			if(n == 0x83) {
			  if(*PrgBase!=0 && *(PrgBase + 1)!=0) {
				  DirectMode=0;
			    TextP=PrgBase+4;
			    Linea=*(int *)(TextP-2);
			    }
			  }
			break;
		case 0x82:                      // list
			i=GetValue(0);
			if(fError) {
			  fError=0;
			  p=PrgBase;
			  i=0x7fff;
			  }
			else {
			  p=CercaLine(i,0);
			  }
		  if(p) {
			  while(p1==(*(char **)p)) {
			    i1=*((int *)(p+2));
					if(i1>i)                  // occhio a signed...
					  break;
					itoa(i1, sNumLin, 10);
				  printText(sNumLin);
				  printText(" ");
					p+=4;
					while(*p) {
						if(*p < 0) {
							if(*p < 0xc0)
							  printText(KeyWords[*p & 0x3f]);
							else
							  printText(Funct[*p & 0x3f]);
						  }
					  else
						  printChar(*p,1);
					  p++;
					  }
					p++;
	  			printChar(13,1);
				  if(fStop)
					  RetVal=17;
					printChar(10,1);
				  }
				}
			break;
		case 0x84:                // end
		  DirectMode=1;
		  TextP=*VarBase-3;
			break;
		case 0x85:                // stop
		  RetVal=17;
			break;
		case 0x86:                // print
		  ch=0;
myPrint:
	  	if(!fError) {
			  switch(*TextP) {
					case ';':
					  ch=1;
					case ' ':
					  TextP++;
					  goto myPrint;
					  break;
					case ',':
						printChar('\t',1);
					  TextP++;
					  ch=1;
					  goto myPrint;
					  break;
					case 0:
					case ':':
					  if(!ch) {                      // indica se andare a capo...
							printChar(13,1);
							printChar(10,1);
							}
					  break;
					default:
					  l=EvalExpr(15,&Fl);
					  if(fError)
						  goto myPrint;
					  if(!(Fl & STR_FLAG)) {
			  		  printChar(l<0 ? '-' : ' ',1);
						  if(Fl & INT_FLAG) {
								itoa(abs((int)l), sNumLin, 10);
							  printText(sNumLin);
							  }
						  else {
								itoa(abs(l), sNumLin, 10);
							  printText(sNumLin);
							  }
							}
					  else {
							p=(char *)l;
							ch=*(((char *)&l)+2);
							while(ch--)
							  printChar(*p++,1);
							}
					  ch=0;
					  goto myPrint;
					  break;
					}
			  }
			break;
		case 0x87:                     // REM
myRem:
		  TextP=CercaFine(0);
		  break;
		case 0x88:                     // for
			p=HandleVar(1,&Fl);
			if(!fError) {
				OldVar=p;
				if(Fl & STR_FLAG) {
				  RetVal=4;
				  goto myFor1;
				  }
				if(DoCheck('='))
				  goto myFor1;
				l=GetValue(0);
				*(long *)OldVar=l;
				if(DoCheck(0x89))
				  goto myFor1;
				ToVal=GetValue(0);
				if(fError)
				  goto myFor1;
				SkipSpaces();
				if(*TextP==0x8a) {
				  TextP++;
				  StVal=GetValue(0);
					if(fError)
					  goto myFor1;
				  }
				else
				  StVal=1;
//         printf("eccomi con var=%d, To %d, Step %d, TEXTP %x\r\n",*(int *)OldVar,(int)ToVal,(int)StVal,*TextP);
				OldText=TextP;
				for(;;) {
					ExecLine();
					SkipSpaces();
					if(*TextP && *TextP != ':') {
						p=HandleVar(0,&Fl);
						if(p != OldVar) {
						  RetVal=6;
						  goto myFor2;
						  }
					  }
					p=TextP;
//					*(long *)OldVar=*((long *)OldVar)+StVal;
					TextP=OldText;
					*(long *)OldVar+=StVal;
					if(StVal<0) {
					  if(*((long *)OldVar) < ToVal)
							break;
					  }
				  else {
				  	if(*((long *)OldVar) > ToVal)             // patch per skynet!!!!
							break;
					  }
				  }
				TextP=p;
				}
			else {
myFor1:
			  RetVal=1;
			  }
myFor2:
		  break;
		case 0x8b:
		  RetVal=-6;
		  break;
		case 0x8d:                     // gosub
		  OldText=CercaFine(1);
//        printf("fine: %x, %x\r\n",OldText,*OldText);
		  RetVal=ExecStmt(0x8c);
		  ExecLine();
		  TextP=OldText;
		  break;
		case 0x8c:                     // goto
myGoto:
		  i=(int)GetValue(0);
		  if(p==CercaLine(i,0)) {
//        printf("eseguo goto %d, p=%x\r\n",i,p);
				TextP=p+4;
				Linea=i;
				}
		  else
				RetVal=3;
		  break;
		case 0x8e:                     // return
//        if(OldText)
//          TextP=OldText;
//        else
//          RetVal=5;
				RetVal=-5;
		  break;
		case 0x8f:                     // if
		  i=(int)GetValue(0);
		  if(i) {
				DoCheck(0x90);
				}
		  else {
				goto myRem;
				}
		  break;
//		case 0x90:                     // then
//		  break;
		case 0x92:                     // on .. goto
		  i=(int)GetValue(0);
		  DoCheck(0x8c);
		  if(i<0)
				RetVal=2;
		  else {
				if(!i)
				  goto myRem;
				while(--i) {
				  GetValue(0);
				  DoCheck(',');
				  }
				goto myGoto;
				}
		  break;
		case 0x93:                     // call (sys)
		  i=(int)GetValue(0);
/*****
 * VER ISSO
 *****
#ifdef MC68000
_asm {
//  ld l,i
//  ld h,i+1
  jp (hl)
  }
#endif*/
	    break;
		case 0x94:                     // poke
		  p=(char *)GetValue(0);
		  DoCheck(',');
		  i=(int)GetValue(0);
		  *p=i;
		  break;
		case 0x95:                     // out
		  i=(int)GetValue(0);
		  DoCheck(',');
		  i1=(int)GetValue(0);
		  outp(i,i1);
		  break;
		case 0x96:                     // input
	    SkipSpaces();
		  if(*TextP==0x22) {
		    TextP++;
				while(*TextP != 0x22) {
				  printChar(*TextP++,1);
				  }
			  TextP++;
			  DoCheck(';');
				}
		  p=HandleVar(1,&Fl);
		  if(!fError) {
				printChar('?',1);
			  printChar(' ',1);
				scanf(DirectBuf);
				if(Fl & STR_FLAG) {
				  i=strlen(DirectBuf);
//            printf("la stringa è lunga %d\r\n",i);
				  p1=AllocaString(i);
				  if(p1) {
					*(char **)p=p1;
					*(((int *)p)+1)=i;
					myMemMove(p1,DirectBuf,i);
					}
			  }
			else {
			  if(Fl & INT_FLAG) {
					*(int *)p=atoi(DirectBuf);
					}
			  else
					*(long *)p=atol(DirectBuf);
			  }
			}
		  break;
		case 0x97:                     // get
		  p=HandleVar(1,&Fl);
		  if(!fError) {
				if(Fl & STR_FLAG) {
					ch = 0;
			    *vBufReceived = 0x00;
				  while (*vBufReceived == 0x00)
					  readChar();
				  ch = *vBufReceived;
					if(ch) {
						p1=AllocaString(1);
						if(p1) {
						  *(char **)p=p1;
						  *(((int *)p)+1)=1;
						  *p1=ch;
						  }
						}
				  else {
					  *(char **)p=*StrBase;
					  *(((int *)p)+1)=0;
						}
				  }
				else
				  fError=4;
				}
		  break;
		case 0x98:	// cls
      clearScr();
		  break;
		case 0x99:	// beep
	  	printChar(7,1);
		  break;
		case 0x9a:                     // save
#ifndef MC68000
		  printText("Scrittura...");
		  i=open("c:\\sky.bas",_O_CREAT | _O_TRUNC | _O_WRONLY | _O_BINARY/*,_S_IREAD | _S_IWRITE*/);
		  write(i,PrgBase,*VarBase - PrgBase);
		  close(i);
#endif
		  break;
		case 0x9b:                     // load
#ifndef MC68000
		  printText("Lettura...");
		  i=open("c:\\sky.bas",_O_RDONLY | _O_BINARY);
		  i1=read(i,PrgBase,8000);
		  close(i);
//        VarBase=PrgBase+i1;                   // cancella variabili, compreso in Relink
#else
		  *(int *)PrgBase=PrgBase+2;              // qui fa una specie di OLD...
#endif
		  RelinkBasic();
		  break;
		case ':':
		case ' ':
		  break;
		default:
			TextP--;
			p=HandleVar(1,&Fl);
			if(!fError) {
				DoCheck('=');
			  l=EvalExpr(15,&Fl1);
      writeLongSerial("Aqui 25");
			  if(fError) {
      writeLongSerial("Aqui 27");
					goto myLet2;
      writeLongSerial("Aqui 28");
					}
			  if(Fl & STR_FLAG) {
					if(!(Fl1 & STR_FLAG)) {
					  RetVal=4;
					  }
					else {
					  *(long *)p=l;
					  }
					}
			  else {
					if(Fl1 & STR_FLAG) {
					  RetVal=4;
					  }
					else {
						if(Fl & INT_FLAG) {
							*(int *)p=l;
							}
					  else {
							*(long *)p=l;
							}
					  }
				  }
				}
		  else {
myLet2:
        writeLongSerial("Aqui 30");
				RetVal=1;
				}
      writeLongSerial("Aqui 26");
		  break;
		}
  writeLongSerial("Aqui 29");
  return RetVal;
	}

char ExecLine() {
  char *p;
  char RetVal=0;
  int i;

	writeLongSerial("Aqui ExecLine Command...\r\n");

rifo:
  if(!DirectMode)
		Linea=*(int *)(TextP-2);
  while(*TextP && !RetVal) {
		writeLongSerial("Aqui ExecLine Command 1...");
		printChar(*TextP,1);
		printText("...\r\n");
	  RetVal=ExecStmt(*TextP++);
		writeLongSerial("Aqui ExecLine Command 2...\r\n");
	  if(fStop)
		  RetVal=17;
	  if(fError)
		  RetVal=fError;
	  }
	if(RetVal)
	  return RetVal;
	if(!DirectMode) {
	  TextP++;
	  if(*(int *)TextP) {
			TextP+=4;
			goto rifo;
			}
	  }
  return 0;
  }

char *CercaLine(int n, char m) {        //m =0 per ricerca esatta, 1 per = o superiore
  /*register*/ char **p,*p1 = 0x00;

  p=PrgBase;
  while(p1==*p) {
		if(p[1] == n)
		  return p;
		if(m) {
		  if(p[1] >= n)
			  return p;
		  }
		p=p1;
		}
  return 0;
  }

char *CercaFine(char m) {
  /*register*/ char *p;

  p=TextP;
  while(*p) {
		if(m && *p==':')
		  break;
		p++;
		}

  return p;
  }

//#pragma code_seg text2

char GetAritmElem(/*register*/ long *l) {
  char *p;
  char ch,Fl = 0x00;
  int i,j,i1;
  long l1;
  char RetVal;

rifo:
  ch=*TextP;
  if(ch >= '0' && ch < ('9'+1) || ch=='.') {
		*l=myAtoi();
//    while(*TextP >= '0' && *TextP<='9')
//      TextP++;
//  printf("aritm: %ld, flags %x\r\n",*l,0);
		if(*TextP=='%') {
		  TextP++;
		  return INT_FLAG;
		  }
		else
		  return 0;
		}
  else if(ch < 0) {                // prima ho i diadici...
		ch &= 0x3f;
		TextP++;
		DoCheck('(');
		switch(ch) {
		  case 2:                          // not
				l1=GetValue(0);
				*l=(!l1) ? 1 : 0;
				RetVal=INT_FLAG;
				break;
		  case 3:                          // SGN
				l1=GetValue(0);
				if(l1)
				  *l=(l1 >= 0) ? 1 : -1;
				else
				  *l=0;
				RetVal=INT_FLAG;
				break;
		  case 4:                          // ABS
				l1=GetValue(0);
				*l=abs(l1);
				RetVal=0;
				break;
		  case 5:                          // int
				l1=GetValue(0);
				*l=l1;
				RetVal=0;
				break;
/*
 * REVER ISSO... COM PONTO FLUTUANTE... 68000 NAO TEM DECIMAL
 */
/*		  case 6:                          // sqr
				l1=GetValue(0);
				*l=sqrt(l1);
				RetVal=0;
				break;
		  case 7:                          // sin
				l1=GetValue(0);
				*l=sin(l1);                    // sarà in gradi 360° su MC68000...
				RetVal=0;
				break;
		  case 8:
				l1=GetValue(0);
				*l=cos(l1);
				RetVal=0;
				break;
		  case 9:
				l1=GetValue(0);
				*l=tan(l1);
				RetVal=0;
				break;
		  case 10:
				l1=GetValue(0);
				*l=log(l1);
				RetVal=0;
				break;
		  case 11:
				l1=GetValue(0);
				*l=exp(l1);
				RetVal=0;
				break;*/
	/*
	 ******************************
	 */
		  case 12:                          // fre
	//        i=GetValue(0);
				*l=(unsigned long)(*StrBase-*VarEnd);
				RetVal=INT_FLAG;
				break;
		  case 13:                          // rnd
				i=GetValue(0);
				if(i<0) {
				  srand(i);
				  }
				*l=(unsigned long)rand();
				RetVal=0;
				break;
		  case 14:                          // peek
				i=GetValue(0);
				*l=(unsigned long)*((unsigned char *)i);
				RetVal=INT_FLAG;
				break;
		  case 15:                          // inp
				i=GetValue(0);
				if(i<0 || i>255) {
				  fError=2;
				  }
				else {
					*l=(unsigned long)inp(i);
					RetVal=INT_FLAG;
					}
				break;
		  case 16:                          // len
				l1=GetValue(1);
				*l=*(((int *)&l1)+1);
				RetVal=INT_FLAG;
				break;
		  case 17:                          // str
				break;
		  case 18:                          // val
				l1=GetValue(1);
				i=*(((int *)&l1)+1);
				p=((char *)l1)+i;               // truschino per le zero-term...
				ch=*p;
				*p=0;
				*l=atol((char *)l1);
				*p=ch;
				RetVal=0;
				break;
		  case 19:                          // chr
				i=GetValue(0);
				p=AllocaString(1);
				if(p) {
					*(char **)l=p;
					*(((int *)l)+1)=1;
					*p=i;
					RetVal=STR_FLAG;
					}
				break;
		  case 20:                          // asc
				l1=GetValue(1);
				*l=*(unsigned char *)l1;
				RetVal=INT_FLAG;
				break;
		  case 21:                          // mid
				l1=GetValue(1);
				if(!DoCheck(',')) {
				  i=GetValue(0);
				  i--;
				  j=*(((int *)&l1)+1);
				  if(i <= j) {
					  *(int *)l=(*(int *)&l1)+i;
					  SkipSpaces();
					  if(*TextP == ',') {
						TextP++;
						i1=GetValue(0);
						if(i1 <= (j-i)) {
						  *(((int *)l)+1)=i1;
						  }
						}
					  else {
							*(((int *)l)+1)=*(((int *)&l1)+1) -i;
							}
					  RetVal=STR_FLAG;
					  }
					else
					  fError=2;
				  }
				break;
		  case 24:                          // Digital In
				i=GetValue(0);
				i1=i & 7;
				i >>= 3;
				i=inp(i);
//        *l=i & BitTable[i1] ? 0 : 1;
				i1=BitTable[i1] ? 0 : 1;
				*l=(i & i1) ? 1 : 0;
				RetVal=INT_FLAG;
				break;
		  }
		DoCheck(')');
		return RetVal;
		}
  else if(myIsalpha(ch)) {
		if(toupper(ch)=='T' && toupper(*(TextP+1))=='I') {
		  TextP+=2;
		  *l=clock();
		  return 0;
		  }
		else {
			p=HandleVar(0,&Fl);
			if(!fError) {
				if(Fl & INT_FLAG) {
				  *l=(long)(*(int *)p);
				  }
				else {
				  *l=*(long *)p;
				  }
				return Fl;
				}
		  }
		}
  else {
		switch(ch) {
		  case '&':
				TextP+=2;                  // H
				*l=myXtoi();
				return INT_FLAG;
				break;
		  case 0x22:
				*(char **)l=++TextP;
				i=0;
				while(*TextP != 0x22 && *TextP) {
				  i++;
				  TextP++;
				  }
				*(((int *)l)+1)=i;
				if(*TextP)
				  TextP++;
				if(DirectMode) {
				  p=AllocaString(i);
				  if(p) {
						myMemMove(p,*(char **)l,i);
						*(char **)l=p;
						}
				  }
				return STR_FLAG;
				break;
//      case '-':
//        break;
		  case 0x5C:	// '\\'
		  case '$':
		  case '!':
		  case '#':
		  case 0x27:
				fError=1;
				break;
		  case ' ':
				TextP++;
				goto rifo;
				break;

		  }
		}
  return -1;
  }

//#pragma code_seg text

char RecursEval(char Pty, /*register*/ long *l1, char *f1) {
  long l2 = 0x00;
  char f2 = 0x00;
  unsigned char ch;
  char Go=0,InBrack=0,Times=0;
  char *p,*p1;
  int i,i1,j;

  do {
	  ch=*TextP;
//    printf("sono sul %c(%x), T %d, pty %d\r\n",ch,ch,Times,Pty);
	  switch(ch) {
			case '(':
			  TextP++;
			  InBrack++;
			  break;
			case ')':
			  if(InBrack) {
				  TextP++;
					InBrack--;
					}
			  else
					Go=1;
			  break;
			case '+':
			case '-':
//                printf("- ??unario: f %x,l %ld, pty %d, times %d\r\n",*f1,*l1,Pty,Times);
		  if(Times) {
		  if(Pty >= 5) {
				TextP++;
				  RecursEval(4,&l2,&f2);
				  if(*f1 & STR_FLAG) {
					  if(f2 & STR_FLAG) {
							i=*(((int *)l1)+1);
							i1=*(((int *)&l2)+1);
							p=AllocaString(i+i1);
							if(p) {
							  myMemMove(p,(char *)*(int *)l1,i);
							  myMemMove(p+i,(char *)*((int *)&l2),i1);
						  	*(char **)l1=p;
							  *(((int *)l1)+1)=i+i1;
						  	}
							}
					  else
						fError=4;
						}
				  else {
						if(ch=='+')
						  *l1+=l2;
						else
							*l1-=l2;
				  	}
					}
			  else
					Go=1;
				}
		  else {
		  	if(Pty >= 3) {
					TextP++;
				  RecursEval(2,l1,f1);
				  if(ch=='-')
						*l1=-*l1;
				  if(*f1 & STR_FLAG)
						fError=4;
			  	}
			 	else
					Go=1;
			  }
		  break;
		case '*':
		case '/':
		case '^':
		case '%':
		  if(Pty >= 4) {
			  TextP++;
			  RecursEval(3,&l2,&f2);
			  if((*f1 & STR_FLAG) || (f2 & STR_FLAG)) {
					fError=4;
					}
			  else {
					switch(ch) {
					  case '*':
//					  *l1 *= l2;
					  *l1 = *l1 * l2;
					  break;
					case '/':
//					  *l1 /= l2;
					  *l1 = *l1 / l2;
					  break;
					case '^':

					/******  VER COMO FAZER ESSA FUNCAO
					  l1=pow(*l1,l2);
					 **********************************/
					  break;
				  case '%':
//					  *l1 %= l2;
					  *l1 = *l1 % l2;
					  break;
					}
			  }
			}
		else
			Go=1;
		  break;
		case '<':
		case '=':
		case '>':
		  i=0;
		  if(Pty >= 6) {
			  TextP++;
			  if(*TextP == '=') {
					i=1;
					TextP++;
					}
			  else {
				  if(*TextP == '>') {
						i=-1;
						TextP++;
						}
				  }
			  RecursEval(5,&l2,&f2);
			  if(*f1 & STR_FLAG) {
				  if(f2 & STR_FLAG) {
						p=*(char **)l1;
						p1=*((char **)&l2);
						i=*(((int *)l1)+1);
						i1=*(((int *)&l2)+1);
						if(i1>i)
						  i=i1;                // prendo la +lunga
					j=strncmp(p,p1,i);
						switch(ch) {
					  case '<':
							if(!i)
								*l1=j <= 0 ? 1 : 0;
						  else {
								if(i>0)
									*l1=j < 0 ? 1 : 0;
								else
									*l1=j != 0;
								}
						  break;
					case '=':
					  *l1=j == 0;
					  break;
					case '>':
						if(i)
							*l1=j >= 0 ? 1 : 0;
					  else
							*l1=j > 0 ? 1 : 0;
					  break;
					}
				  *f1=INT_FLAG;
				}
			  else
					fError=4;
					}
			  else {
				switch(ch) {
				  case '<':
						if(!i)
							*l1=*l1 < l2;
					  else {
							if(i>0)
							  *l1=*l1 <= l2;
							else
							  *l1=*l1 != l2;
							}
					  break;
				case '=':
				  *l1=*l1 == l2;
				  break;
				case '>':
					if(i)
						*l1=*l1 >= l2;
				  else
						*l1=*l1 > l2;
				  break;
				}
			  }
			}
		else
			Go=1;
		  break;
		case 0xc0:                        // and,or
		case 0xc1:
		  if(Pty >= 7) {
		  TextP++;
			  RecursEval(6,&l2,&f2);
			  if((*f1 & STR_FLAG) || (f2 & STR_FLAG)) {
					fError=4;
					}
			  else {
					if(ch==0xc0)
					  *l1=(*(int *)l1) & ((int)l2);
					else
					  *l1=(*(int *)l1) | ((int)l2);
					*f1=INT_FLAG;
				  }
				}
			else
				Go=1;
		  break;
		case ' ':
		  TextP++;
		  Times--;
		  break;
		case 0:
		case ':':
		case ';':
		case ',':
		case 0x91:                  // then,else,goto,gosub, to,step
		case 0x90:
		case 0x8c:
		case 0x8d:
		case 0x89:
		case 0x8a:
		  Go=1;
		  break;
		default:
			*f1=GetAritmElem(l1);
		  break;
		}
	  Times++;
	  } while(!Go && !fError);

  return 0;
  }

long EvalExpr(char Pty, char *flags) {            // deve diventare long
  long l = 0;

  RecursEval(Pty,&l,flags);
  return l;
  }

long GetValue(char m) {             // m=0 number, 1 string
  char flags=-1;
  long l;

  l=EvalExpr(15,&flags);
  if(flags<0)
		fError=1;
  else {
	  if(m) {
		  if(!(flags & STR_FLAG)) {
				fError=4;
				}
		  }
		else {
		  if(flags & STR_FLAG) {
				fError=4;
				}
		  }
	  }
  return l;
  }

int DoError(char n) {

  char sNumLin [sizeof(short)*8+1];
  printChar('?',1);
#ifdef MC68000
//  beep(20);
#endif
  printText(Errore[n-1]);
  if(!DirectMode) {
	  printText(" to the line ");
		itoa(Linea, sNumLin, 10);
	  printText(sNumLin);
	  printText("\r\n");
	  }
  else {
#ifndef MC68000
	  printChar(10,1);
	  printChar(13,1);
#endif
	  }

	  return -1;
  }

void SkipSpaces() {

  while(*TextP == ' ')
		TextP++;
  }

char DoCheck(char ch) {

  SkipSpaces();
  if(ch==*TextP) {
		TextP++;
		return 0;
		}
  else {
		fError=1;
		return 1;
		}
  }

char CheckMemory(int n) {
  int i;

  i=*StrBase-*VarEnd;
  if(i<n) {
		fError=7;
		return 1;
		}
  else
		return 0;
  }

char *AllocaString(int n) {

  if(!CheckMemory(n)) {
		*StrBase = *StrBase - n;
		return *StrBase;
		}
  else
		return 0;
}

void myMemMove(void *dest, void *src, int n)
{
	int i;
	// Typecast src and dest addresses to (char *)
	unsigned char *csrc = (unsigned char *)src;
	unsigned char *cdest = (unsigned char *)dest;

	// Create a temporary array to hold data of src
	unsigned char temp[255];

	// Copy data from csrc[] to temp[]
	for (i = 0; i < n; i++)
	    temp[i] = csrc[i];

	// Copy data from temp[] to cdest[]
	for (i = 0; i < n; i++)
	    cdest[i] = temp[i];
}