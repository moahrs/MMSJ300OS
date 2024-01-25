unsigned char *pStartSimpVar        = 0x00800000;    // Area Variaveis Simples
unsigned char *pStartArrayVar       = 0x00802000;   // Area Arrays
unsigned char *pStartProg           = 0x00808000;       // Area Programa
unsigned char *pStartString         = 0x008FC000;     // Area Strings
unsigned char *pStartListVarUse     = 0x008FEF00;   // Lista das 16 variaveis mais usadas
unsigned char *pStartStack          = 0x008FF000;      // Area variaveis sistema e stack pointer

//**************************************************
// ESSA VARIAVEL NAO VAI EXISTIR QUANDO FOR PRA BIOS
//************************************************** 
unsigned char *pProcess             = 0x008FFFFE;
//************************************************** 
//************************************************** 
//************************************************** 

unsigned char *pTypeLine            = 0x008FFFFC; // 0x00 = Proxima linha tem "READY" e ">". 0x01 = Proxima linha tem somente ">"
unsigned long *nextAddrLine         = 0x008FFFF8; // Endereço da proxima linha disponivel pra ser incluida do basic
unsigned short *firstLineNumber     = 0x008FFFF6; // Numero de Linha mais Baixo
unsigned long *addrFirstLineNumber  = 0x008FFFF2; // Endereço do numero de linha mais baixo
unsigned long *addrLastLineNumber   = 0x008FFFEE; // Endereço do numero de linha mais baixo
unsigned long *nextAddr             = 0x008FFFEA; // usado para controleno runProg
unsigned long *nextAddrSimpVar      = 0x008FFFE6; // Endereço da proxima linha disponivel pra definir variavel
unsigned long *nextAddrArrayVar     = 0x008FFFE2; // Endereço da proxima linha disponivel pra definir array
unsigned long *nextAddrString       = 0x008FFFDE; // Endereço da proxima linha disponivel pra incluir string
unsigned char *comandLineTokenized  = 0x008FFEDF; // Linha digitada sem numeros inicial e sem comandos basicos irá interpretada com tokens (255 Bytes)
unsigned char *vParenteses          = 0x008FFEDD; // Controle de Parenteses na linha inteira durante processamento
unsigned char *vInicioSentenca      = 0x008FFEDB; // Indica inicio de sentenca, sempre inicio analise ou depois de uma ",", ":", "THEN" ou "ELSE"
unsigned char *vMaisTokens          = 0x008FFED9; // Tem um = como atribuição mas tem mais variaveis e/ou tokens no sistema
unsigned char *vTemIf               = 0x008FFED7; // Linha começou com if, e tem que ter pelo menos then ou then e else
unsigned char *pointerRunProg       = 0x008FFED5; // Ponteiro da execução do programa ou linha digitada
unsigned char *doisPontos           = 0x008FFED3; // Se teve 2 pontos na linha e inicia novo comando como se fosse linha nova
unsigned char *vTemAndOr            = 0x008FFED1; // Foi lido uma vez um AND ou um OR, e deve finalizar a condicao anterior, na proxima deve executar ele.
unsigned char *vTemThen             = 0x008FFECF; // Foi lido then
unsigned char *vTemElse             = 0x008FFECD; // Foi lido else
unsigned char *vTemIfAndOr          = 0x008FFECA; // Foi lido uma vez um AND ou um OR com IF, e deve finalizar a condicao anterior, na proxima deve executar ele.

struct keyword_token 
{
  char *keyword;
  int token;
};

const keywords_count = 46;
const keywordsUnique_count = 8;

typedef struct
{
  unsigned char tString[250];
  short tInt;
  long tLong;
  unsigned char tType;  // 0 - String, 1 - Int, 2 - Long
} typeInf;

typedef struct
{
  unsigned short tNumLine;  // 2
  unsigned long tAddr;      // 8
  unsigned long tStep;      // 8
  unsigned long tFinal;     // 8
  unsigned char tVar[2];    // 2 = total 20
} ctrlFor;

static const struct keyword_token keywords[] = 
{
  {"LET", 		0x80},   // ok ok
  {"PRINT", 	0x81},   // ok ok
  {"IF", 		  0x82},   // -- ok
  {"THEN", 		0x83},   // -- ok
  {"ELSE", 		0x84},   // -- ok
  {"FOR", 		0x85},   // -- 
  {"TO", 		  0x86},   // -- 
  {"NEXT", 		0x87},   // -- 
  {"STEP", 		0x88},   // -- 
  {"GOTO" , 	0x89},
  {"GOSUB", 	0x8A},
  {"RETURN", 	0x8B},
  {"REM", 		0x8C},
  {"PEEK", 		0x8D},
  {"POKE", 		0x8E},
  {"READ", 		0x8F},
  {"RND", 		0x91},
  {"INPUT", 	0x92},   // -- 
  {"GET",     0x93},   // -- 
  {"VTAB",    0x94},
  {"HTAB",    0x95},
  {"HOME", 		0x96},   // -- ok
  {"CLEAR", 	0x97},   // -- --
  {"DATA", 		0x98},
  {"DIM", 		0x99},
  {"CALL",    0x9A},
  {"LEN", 		0x9B},   // ok ok
  {"VAL", 		0x9C},   // ok ok
  {"STR$", 		0x9D},   // ok ok
  {"END", 		0x9E},
  {"STOP", 		0x9F},
  {"NOT",     0xA0},
  {"CHR$",    0xA1},   // ok ok
  {"FRE",     0xA2},   // ok ok
  {"SQRT",    0xA3},   // ok ok
  {"SIN",     0xA4},   // ok ok
  {"COS",     0xA5},   // ok ok
  {"TAN",     0xA6},   // ok ok
  {"LOG",     0xA7},   
  {"EXP",     0xA8},   
  {"RESERVED",0xA9},   
  {"AND",     0xF3},   // ok ok
  {"OR",      0xF4},   // ok ok
  {">=",      0xF5},   // ok ok
  {"<=",      0xF6},   // ok ok
  {"<>",      0xF7}    // ok ok
};

const char operandsWithTokens[] = "+-*/^>=<";

static const struct keyword_token keywordsUnique[] = 
{
  {"+",       0xFF},  // ok ok
  {"-",       0xFE},  // ok ok
  {"*",       0xFD},  // ok ok
  {"/",       0xFC},  // ok ok
  {"^",       0xFB},  // ok ok
  {">",       0xFA},  // ok ok
  {"=",       0xF9},  // ok ok
  {"<",       0xF8}   // ok ok
};

void processLine(void);
void tokenizeLine(unsigned char *pTokenized);
void saveLine(unsigned char *pNumber, unsigned char *pLinha);
void runProg(unsigned char *pNumber);
int executeToken(unsigned char pToken, typeInf *pRetInf);
void listProg(unsigned char *pArg);
void delLine(unsigned char *pArg);
int findToken(unsigned char pToken);
unsigned long findNumberLine(unsigned short pNumber, unsigned char pTipoRet, unsigned char pTipoFind);
void showErrorMessage(char pError, unsigned int pNumLine);
char createVariable(unsigned char* pVariable, unsigned char* pValor, char pType);
char updateVariable(unsigned long* pVariable, unsigned char* pValor, char pType, char pOper);
void managerList(unsigned char* pVariable, unsigned long pEnder);
long findVariable(unsigned char* pVariable);
int endSentence(unsigned char pToken);
int analiseVariable(typeInf *pRetInf);
int nextToken(typeInf *pRetInf);

// -------------------------------------------------------------------------------
// Funcoes Basic
// -------------------------------------------------------------------------------
char basLet(typeInf *pRetInf);
char basPrint(typeInf *pRetInf);
char basChr(typeInf *pRetInf);
char basFre(typeInf *pRetInf);
char basSum(typeInf *pRetInf);
char basSub(typeInf *pRetInf);
char basMul(typeInf *pRetInf);
char basDiv(typeInf *pRetInf);
char basPow(typeInf *pRetInf);
long basSqrt(typeInf *pRetInf);
long basSin(typeInf *pRetInf);
long basCos(typeInf *pRetInf);
long basTan(typeInf *pRetInf);
char basVal(typeInf *pRetInf);
char basLen(typeInf *pRetInf);
char basStr(typeInf *pRetInf);
char basAnd(typeInf *pRetInf);
char basOr(typeInf *pRetInf);
char basEqual(typeInf *pRetInf);
char basCompare(typeInf *pRetInf, unsigned char pToken);
char basIf(typeInf *pRetInf);
char basLet(typeInf *pRetInf);
char basInputGet(typeInf *pRetInf, unsigned char pSize);
char basFor(typeInf *pRetInf);
char basNext(typeInf *pRetInf);

// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
// Funcoes Aritimeticas que Suportam Inteiros e Ponto Flutuante (Numeros Reais)
// -------------------------------------------------------------------------------
/*unsigned int powNum(unsigned int pbase, unsigned char pexp);
unsigned int floatStringToFpp(unsigned char* pFloat);
unsigned char* fppTofloatString(unsigned long pFpp);
unsigned long fppAdd(unsigned long a, unsigned long b);
long fppSub(unsigned int a, unsigned int b);
unsigned long fppMul(unsigned long a, unsigned long b);
long fppDiv(unsigned int a, unsigned int b);
long fppSqrt(unsigned int a, unsigned int b);
long fppSin(unsigned int a, unsigned int b);
long fppCos(unsigned int a, unsigned int b);
long fppTan(unsigned int a, unsigned int b);
unsigned long shift32RightJamming(int a, int count);*/




static const long fix16_overflow = 0x80000000;
static const long fix16_maximum = 0x7FFFFFFF;
static const long fix16_minimum = 0x80000000;
static const long fix16_one = 0x00000010;
static const unsigned int scales[8] = {
    /* 5 decimals is enough for full fix16_t precision */
    1, 10, 100, 1000, 10000, 100000, 100000, 100000
};

static const fix16_t FOUR_DIV_PI  = 0x145F3;            /*!< Fix16 value of 4/PI */
static const fix16_t _FOUR_DIV_PI2 = 0xFFFF9840;        /*!< Fix16 value of -4/PI² */
static const fix16_t X4_CORRECTION_COMPONENT = 0x399A;  /*!< Fix16 value of 0.225 */
static const fix16_t PI_DIV_4 = 0x0000C90F;             /*!< Fix16 value of PI/4 */
static const fix16_t THREE_PI_DIV_4 = 0x00025B2F;       /*!< Fix16 value of 3PI/4 */

static const fix16_t fix16_pi  = 205887;     /*!< fix16_t value of pi */
static const fix16_t fix16_e   = 178145;     /*!< fix16_t value of e */

static long _fix16_sin_cache_index[4096]  = { 0 };
static long _fix16_sin_cache_value[4096]  = { 0 };
static long _fix16_atan_cache_index[2][4096] = { { 0 }, { 0 } };
static long _fix16_atan_cache_value[4096] = { 0 };

static const char CHAR_BIT = 8;

long fix16_add(long a, long b);
long fix16_sub(long a, long b);
long fix16_mul(long inArg0, long inArg1);
unsigned short clz(unsigned int x);
long fix16_div(long a, long b);
char *itoa_loop(char *buf, unsigned int scale, unsigned int value, char skip);
void fix16_to_str(long value, char *buf, int decimals);
long fix16_from_str(char *buf);
int fix16_to_int(long a);
long fix16_sdiv(long inArg0, long inArg1);
long fix16_sqrt(long inValue);
long fix16_sin_parabola(long inAngle);
long fix16_sin(long inAngle);
long fix16_cos(long inAngle);
long fix16_tan(long inAngle);
/* desabilitados por hora, problema com erro de non-scalar array index
long fix16_asin(long x);
long fix16_acos(long x);
long fix16_atan2(long inY , long inX);
long fix16_atan(long x);*/
// -------------------------------------------------------------------------------
