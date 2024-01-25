unsigned char *pProcess             = 0x008FFFFE;

static unsigned char *listError[]= {
    /* 00 */ "reserved",
    /* 01 */ "Syntax Error"
};

// -------------------------------------------------------------------------------
// Funcoes Graficas
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
unsigned long fppComp(unsigned long pFppD7, unsigned long pFppD6);
long fppInt(unsigned long pFppD7);
unsigned long fppReal(long pFppD7);
unsigned long fppSin(long pFppD7);
unsigned long fppCos(long pFppD7);
unsigned long fppTan(long pFppD7);
unsigned long fppSinH(long pFppD7);
unsigned long fppCosH(long pFppD7);
unsigned long fppTanH(long pFppD7);
unsigned long fppSqrt(long pFppD7);
unsigned long fppLn(long pFppD7);
unsigned long fppExp(long pFppD7);
unsigned long fppAbs(long pFppD7);
unsigned long fppNeg(long pFppD7);
unsigned long gerRand(void);

void FP_TO_STR(void);
void STR_TO_FP(void);
void FPP_SUM(void);
void FPP_SUB(void);
void FPP_MUL(void);
void FPP_DIV(void);
void FPP_PWR(void);
void FPP_CMP(void);
void FPP_INT(void);
void FPP_FPP(void);
void FPP_SIN(void);
void FPP_COS(void);
void FPP_TAN(void);
void FPP_SINH(void);
void FPP_COSH(void);
void FPP_TANH(void);
void FPP_SQRT(void);
void FPP_LN(void);
void FPP_EXP(void);
void FPP_CMP(void);
void FPP_ABS(void);
void FPP_NEG(void);

void TRACE_ON(void);
void TRACE_OFF(void);
