#define MC68000 1

#define BUF_SIZE 160
#define MEM_SIZE 0x10000

char fStop=0;

#define VAR_SIZE 6
								 // 2 char + long
#define INT_FLAG 1
#define STR_FLAG 2

char DirectBuf[BUF_SIZE];
char *TextP;
unsigned char *PrgBase = 0x00820000;
unsigned char *MemTop = 0x00830000;
unsigned long *VarBase = 0x00830002;
unsigned long *VarEnd = 0x0083000A;
unsigned long *StrBase = 0x00830012;

#define VERSIONE 0x101

char DirectMode=1;
char fError=0;
int Linea;

char ExecLine(void);
char ExecStmt(unsigned char);
char *CercaLine(int, char);
long EvalExpr(char, char *);
long GetValue(char);
char DoCheck(char);
char *CercaFine(char);
void SkipSpaces(void);
char CheckMemory(int);
char *AllocaString(int);
int Tokenize(void);
int GetLine(void);
int StoreLine(int t);
int DoError(char n);
long myAtoi(void);
int myXtoi(void) ;
int RelinkBasic(void);
int myStrnicmp(const char* s1, const char* s2, int n);
void cursOn(void);
void cursOff(void);
void myMemMove(void *dest, void *src, int n);
int outp(unsigned long pPerif, unsigned int pData);
unsigned long inp (unsigned long pPerif);

char *KeyWords[]={
  "SYSTEM","NEW","LIST","RUN","END","STOP","PRINT","REM","FOR","TO","STEP","NEXT","GOTO",
  "GOSUB","RETURN","IF","THEN","ELSE","ON","CALL","POKE","OUTP","INPUT","GET",
  "CLS","BEEP","SAVE","LOAD",0
  };

char *Funct[]={
  "AND","OR","NOT","SGN","ABS","INT","SQR","SIN","COS","TAN","LOG","EXP","FRE","RND","PEEK",
  "INP","LEN","STR$","VAL","CHR$","ASC","MID$","INSTR","TAB",
  "DIN",0
  };

char *Errore[]={
  "Syntax error",
  "Invalid value",
  "Undefined row",
  "Type mismatch",
  "RETURN without GOSUB",
  "NEXT without FOR",
  "Memory end",
  "String too long",
  "",
  "",
  "",
  "",
  "",
  "",
  "",
  "",
  "Stopped"
  };
  
char BitTable[8]={ 0x80,0x40,0x20,0x10,8,4,2,1 };

#ifndef MC68000
void (_interrupt _far *OldCtrl_C)();
void _interrupt _far Ctrl_C();
#endif

