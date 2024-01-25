typedef struct  {
  unsigned char nameVar[3];  // variable name
  long endVar; // address off the counter variable
  int target;  // target value
  int step; // step inc/dec
  int progPosPointerRet;
} for_stack;

struct keyword_token
{
  char *keyword;
  int token;
};

typedef struct
{
  unsigned char tString[250];
  short tInt;
  long tLong;
  unsigned char tType;  // 0 - String, 1 - Int, 2 - Long
} typeInf;

unsigned char *pStartSimpVar        = 0x00800000;   // Area Variaveis Simples
unsigned char *pStartArrayVar       = 0x00802000;   // Area Arrays
unsigned char *pStartProg           = 0x00808000;   // Area Programa
unsigned char *pStartString         = 0x008FC000;   // Area Strings
unsigned char *pStartStack          = 0x008FF000;   // Area variaveis sistema e stack pointer
unsigned char *pStartXBasLoad       = 0x00880000;   // Area onde será importado o programa em basic texto a ser tokenizado depois

//**************************************************
// ESSA VARIAVEL NAO VAI EXISTIR QUANDO FOR PRA BIOS
//**************************************************
unsigned char *pProcess             = 0x008FFFFE;
//**************************************************
//**************************************************
//**************************************************

unsigned char *pTypeLine            = 0x008FFFFC; // 0x00 = Proxima linha tem "READY" e ">". 0x01 = Proxima linha tem somente ">"
unsigned long *nextAddrLine         = 0x008FFFF8; // Endereco da proxima linha disponivel pra ser incluida do basic
unsigned short *firstLineNumber     = 0x008FFFF6; // Numero de Linha mais Baixo
unsigned long *addrFirstLineNumber  = 0x008FFFF2; // Endereco do numero de linha mais baixo
unsigned long *addrLastLineNumber   = 0x008FFFEE; // Endereco do numero de linha mais baixo
unsigned long *nextAddr             = 0x008FFFEA; // usado para controleno runProg
unsigned long *nextAddrSimpVar      = 0x008FFFE6; // Endereco da proxima linha disponivel pra definir variavel
unsigned long *nextAddrArrayVar     = 0x008FFFE2; // Endereco da proxima linha disponivel pra definir array
unsigned long *nextAddrString       = 0x008FFFDE; // Endereco da proxima linha disponivel pra incluir string
unsigned char *comandLineTokenized  = 0x008FFEDF; // Linha digitada sem numeros inicial e sem comandos basicos irá interpretada com tokens (255 Bytes)
unsigned char *vParenteses          = 0x008FFEDD; // Controle de Parenteses na linha inteira durante processamento
unsigned char *vInicioSentenca      = 0x008FFEDB; // Indica inicio de sentenca, sempre inicio analise ou depois de uma ",", ":", "THEN" ou "ELSE"
unsigned char *vMaisTokens          = 0x008FFED9; // Tem um = como atribuicao mas tem mais variaveis e/ou tokens no sistema
unsigned char *vTemIf               = 0x008FFED7; // Linha comecou com if, e tem que ter pelo menos then ou then e else
unsigned char *pointerRunProg       = 0x008FFED5; // Ponteiro da execucao do programa ou linha digitada
unsigned char *doisPontos           = 0x008FFED3; // Se teve 2 pontos na linha e inicia novo comando como se fosse linha nova
unsigned char *vTemAndOr            = 0x008FFED1; // Foi lido uma vez um AND ou um OR, e deve finalizar a condicao anterior, na proxima deve executar ele.
unsigned char *vTemThen             = 0x008FFECF; // Foi lido then
unsigned char *vTemElse             = 0x008FFECD; // Foi lido else
unsigned char *vTemIfAndOr          = 0x008FFECA; // Foi lido uma vez um AND ou um OR com IF, e deve finalizar a condicao anterior, na proxima deve executar ele.
unsigned short *vErroProc           = 0x008FFEC6; // Erro global
int *ftos                           = 0x008FFEC2; // index to top of FOR stack
int *gtos                           = 0x008FFEBE; // index to top of GOSUB stack
for_stack *forStack                 = 0x008FF6BE; // stack for FOR/NEXT loop
unsigned long *atuVarAddr           = 0x008FF6B0; // Endereco da variavel atualmente usada pelo basLet
unsigned long *changedPointer       = 0x008FF6A8; // Se ouve mudanca de endereço (goto/gosub/for-next e etc), nao usa sequencia, usa o endereço definido
unsigned long *gosubStack           = 0x008FEEA8; // stack for gosub/return
unsigned char *traceOn              = 0x008FEEA6; // Mostra numero linhas durante execucao, para debug
unsigned long *floatBufferStr       = 0x008FEFA6; // Endereco da variavel do buffer q vai receber a string vindo do floattostr
unsigned long *floatNumD7           = 0x008FEF9E; // com o valor a colocar em D7 para calculos float
unsigned long *floatNumD6           = 0x008FEF96; // com o valor a colocar em D6 para calculos float

const keywords_count = 51;
//const keywordsUnique_count = 1;
unsigned char token[250];
unsigned char token_type, tok;
unsigned char value_type;

// -------------------------------------------------------------------------------
// Mensagens de Erro
// -------------------------------------------------------------------------------
static unsigned char *listError[]= {
    /* 00 */ "reserved 0",
    /* 01 */ "reserved 1",
    /* 02 */ "No expression present",
    /* 03 */ "Equals sign expected",
    /* 04 */ "Not a variable",
    /* 05 */ "Out of range",
    /* 06 */ "Illegal quantity",
    /* 07 */ "Line not found",
    /* 08 */ "THEN expected",
    /* 09 */ "TO expected",
    /* 10 */ "Too many nested FOR loops",
    /* 11 */ "NEXT without FOR",
    /* 12 */ "Too many nested GOSUBs",
    /* 13 */ "RETURN without GOSUB",
    /* 14 */ "Syntax error",
    /* 15 */ "Unbalanced parentheses",
    /* 16 */ "Incompatible types",
    /* 17 */ "Line number expected",
    /* 18 */ "Comma Espected",
    /* 19 */ "Timeout",
    /* 20 */ "Load with Errors"
};

// -------------------------------------------------------------------------------
// Tokens
// -------------------------------------------------------------------------------
static const struct keyword_token keywords[] =
{                      // 1a 2a 3a - versoes (-- : desenv/testar, ok : funcionando, .. : nao feito)
  {"LET", 		0x80},   // ok ok ok
  {"PRINT", 	0x81},   // ok ok ok
  {"IF", 		  0x82},   // .. ok
  {"THEN", 		0x83},   // .. ok
  {"ASC", 		0x84},   // .. .. 
  {"FOR", 		0x85},   // .. .. ok
  {"TO", 		  0x86},   // .. .. ok
  {"NEXT", 		0x87},   // .. .. ok
  {"STEP", 		0x88},   // .. .. ok
  {"GOTO" , 	0x89},   // .. .. ok
  {"GOSUB", 	0x8A},
  {"RETURN", 	0x8B},
  {"REM", 		0x8C},
  {"PEEK", 		0x8D},
  {"POKE", 		0x8E},
  {"READ", 		0x8F},
  {"RND", 		0x91},   // .. ..
  {"INPUT", 	0x92},   // .. ok ok
  {"GET",     0x93},   // .. ok ok
  {"VTAB",    0x94},   // .. .. ok
  {"HTAB",    0x95},   // .. .. ok
  {"HOME", 		0x96},   // ok ok ok
  {"CLEAR", 	0x97},   // .. .. ok
  {"DATA", 		0x98},
  {"DIM", 		0x99},
  {"CALL",    0x9A},
  {"LEN", 		0x9B},   // ok ok ok
  {"VAL", 		0x9C},   // ok ok ok
  {"STR$", 		0x9D},   // ok ok ok
  {"END", 		0x9E},   // .. .. ok
  {"STOP", 		0x9F},
  {"NOT",     0xA0},
  {"CHR$",    0xA1},   // ok ok ok
  {"FRE",     0xA2},   // ok ok ok
  {"SQRT",    0xA3},   // ok ok
  {"SIN",     0xA4},   // ok ok
  {"COS",     0xA5},   // ok ok
  {"TAN",     0xA6},   // ok ok
  {"LOG",     0xA7},
  {"EXP",     0xA8},
  {"SPC",     0xA9},   // .. .. --
  {"TAB",     0xAA},   // .. .. --
  {"MID$",    0xAB},   // .. .. 
  {"RIGHT$",  0xAC},   // .. .. 
  {"LEFT$",   0xAD},   // .. .. 
  {"INT",     0xAE},   // .. .. 
  {"AND",     0xF3},   // ok ok
  {"OR",      0xF4},   // ok ok
  {">=",      0xF5},   // ok ok
  {"<=",      0xF6},   // ok ok
  {"<>",      0xF7}    // ok ok
};

const char operandsWithTokens[] = "+-*/^>=<";

/*static const struct keyword_token keywordsUnique[] =
{
  {"+",       0xFF},  // ok ok
  {"-",       0xFE},  // ok ok
  {"*",       0xFD},  // ok ok
  {"/",       0xFC},  // ok ok
  {"^",       0xFB},  // ok ok
  {">",       0xFA},  // ok ok
  {"=",       0xF9},  // ok ok
  {"<",       0xF8}   // ok ok
  {"§",       0xF8}   // ok ok - sem uso, somente ateh tirar isso
};*/

#define VARTYPEDEFAULT 0x25
#define FOR_NEST 100
#define SUB_NEST 100

#define FINISHED  0xE0
#define END       0xE1
#define EOL       0xE2

#define DELIMITER  1
#define VARIABLE  2
#define NUMBER    3
#define COMMAND   4
#define STRING    5
#define QUOTE     6
#define DOISPONTOS 7
#define OPENPARENT 8
#define CLOSEPARENT 9

// -------------------------------------------------------------------------------
// Funcoes do Interpretador
// -------------------------------------------------------------------------------
void processLine(void);
void tokenizeLine(unsigned char *pTokenized);
void saveLine(unsigned char *pNumber, unsigned char *pLinha);
void listProg(unsigned char *pArg);
void delLine(unsigned char *pArg);
void runProg(unsigned char *pNumber);
void showErrorMessage(unsigned int pError, unsigned int pNumLine);
int executeToken(unsigned char pToken);
int findToken(unsigned char pToken);
unsigned long findNumberLine(unsigned short pNumber, unsigned char pTipoRet, unsigned char pTipoFind);
char createVariable(unsigned char* pVariable, unsigned char* pValor, char pType);
char updateVariable(unsigned long* pVariable, unsigned char* pValor, char pType, char pOper);
int analiseVariable(unsigned char* vVariable);
long findVariable(unsigned char* pVariable);
unsigned char* find_var(char *s);
int nextToken(void);
int isalphas(unsigned char c);
int isdigitus(unsigned char c);
int iswhite(unsigned char c);
int isdelim(unsigned char c);
void getExp(unsigned char *result);
void level2(unsigned char *result);
void level3(unsigned char *result);
void level31(unsigned char *result);
void level32(unsigned char *result);
void level4(unsigned char *result);
void level5(unsigned char *result);
void level6(unsigned char *result);
void primitive(unsigned char *result);
void atithChar(unsigned char *r, unsigned char *h);
void arithInt(char o, char *r, char *h);
void arithReal(char o, int *r, int *h);
void logicalNumericFloat(unsigned char o, char *r, char *h);
void logicalNumericInt(unsigned char o, char *r, char *h);
void logicalString(unsigned char o, char *r, char *h);
void unaryInt(char o, int *r);
void unaryReal(char o, int *r);
char forFind(for_stack *i, unsigned char* endLastVar);
void forPush(for_stack i);
for_stack forPop(void);
void gosubPush(unsigned long i);
unsigned long gosubPop(void);

// -------------------------------------------------------------------------------
// Funcoes dos Comandos Basic
// -------------------------------------------------------------------------------
int basLet(void);
int basPrint(void);
int basChr(void);
int basFre(void);
int basSqrt(void);
int basSin(void);
int basCos(void);
int basTan(void);
int basVal(void);
int basLen(void);
int basStr(void);
int basAsc(void);
int basLeftRightMid(char pTipo);
int basIf(void);
int basLet(void);
int basInputGet(unsigned char pSize);
int basFor(void);
int basNext(void);
int basGoto(void);
int basGosub(void);
int basReturn(void);
int basRnd(void);
int basVtab(void);
int basHtab(void);
int basEnd(void);
int basSpc(void);
int basTab(void);
int basXBasLoad(void);
int basInt(void);

// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
// Funcoes Aritimeticas que Suportam Inteiros e Ponto Flutuante (Numeros Reais)
// -------------------------------------------------------------------------------
unsigned int powNum(unsigned int pbase, unsigned char pexp);
unsigned long floatStringToFpp(unsigned char* pFloat);
int fppTofloatString(unsigned long pFpp, unsigned char *buf);
unsigned long fppSum(unsigned long pFppD7, unsigned long pFppD6);
unsigned long fppSub(unsigned long pFppD7, unsigned long pFppD6);
unsigned long fppMul(unsigned long pFppD7, unsigned long pFppD6);
unsigned long fppDiv(unsigned long pFppD7, unsigned long pFppD6);
unsigned long fppPwr(unsigned long pFppD7, unsigned long pFppD6);
unsigned long fppCmp(unsigned long pFppD7, unsigned long pFppD6);
long fppInt(unsigned long pFppD7);
unsigned long fppReal(long pFppD7);
unsigned long fppSin(long pFppD7);
unsigned long fppCos(long pFppD7);
unsigned long fppTan(long pFppD7);
unsigned long fppSinH(long pFppD7);
unsigned long fppCosH(long pFppD7);
unsigned long fppTanH(long pFppD7);

void FP_TO_STR(void);
void STR_TO_FP(void);
void FP_SUM(void);
void FP_SUB(void);
void FP_MUL(void);
void FP_DIV(void);
void FP_PWR(void);
void FP_CMP(void);
void FP_INT(void);
void FP_FPP(void);
void FP_SIN(void);
void FP_COS(void);
void FP_TAN(void);
void FP_SINH(void);
void FP_COSH(void);
void FP_TANH(void);
