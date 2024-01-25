/********************************************************************************
*    Programa    : basic.c
*    Objetivo    : MMSJ-Basic para o MMSJ300
*    Criado em   : 10/10/2022
*    Programador : Moacir Jr.
*--------------------------------------------------------------------------------
* Data        Versao  Responsavel  Motivo
* 10/10/2022  0.1     Moacir Jr.   Criacao Versao Beta
*--------------------------------------------------------------------------------
* Variables Simples: start at 00800000
*   --------------------------------------------------------
*   Type ($ = String, # = Real, % = Integer)
*   Name (2 Bytes, 1st and 2nd letters of the name)
*   --------------- --------------- ------------------------
*   Integer         Real            String
*   --------------- --------------- ------------------------
*   0x00            0x00            Length
*   Value MSB       Value MSB       Pointer to String (High)
*   Value           Value           Pointer to String
*   Value           Value           Pointer to String
*   Value LSB       Value LSB       Pointer to String (Low)
*   --------------- --------------- ------------------------
*   Total: 8 Bytes
*--------------------------------------------------------------------------------
*
*
*
*
*
*
*
*********************************************************************************/
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "../mmsj300api.h"
#include "../monitor.h"
#include "basic.h"

//#define __DEBUG__
//#define __DEBUG_2__
//#define __DEBUG_3__
//#define __DEBUG_4__
//#define __DEBUG_5__
//#define __DEBUG_6__
//#define __DEBUG_7__
//#define __DEBUG_8__
//#define __DEBUG_9__

//-----------------------------------------------------------------------------
// Principal
//-----------------------------------------------------------------------------
void main(void)
{
    unsigned char vRetInput;

    clearScr();
    printText("MMSJ-BASIC v0.3a\r\n\0");
    printText("Utility (c) 2022-2023\r\n\0");
    printText("OK\r\n\0");
    printText(">\0");

    *vBufReceived = 0x00;
    *vbuf = '\0';
    *pProcess = 0x01;
    *pTypeLine = 0x00;
    *nextAddrLine = pStartProg;
    *firstLineNumber = 0;
    *addrFirstLineNumber = 0;

    while (*pProcess)
    {
        vRetInput = inputLine(128);

        if (*vbuf != 0x00 && (vRetInput == 0x0D || vRetInput == 0x0A))
        {
            printText("\r\n\0");

            processLine();

            if (!*pTypeLine && *pProcess)
                printText("\r\nOK\0");

            *vBufReceived = 0x00;
            *vbuf = '\0';

            if (!*pTypeLine && *pProcess)
                printText("\r\n>\0");
            else if (*pTypeLine)
                printText(">\0");
        }
        else if (vRetInput != 0x1B)
        {
            printText("\r\n\0");
            printChar('>', 1);
        }
    }

    printText("\r\n*** BYE ***\r\n\0");
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
void processLine(void)
{
    unsigned char linhacomando[32], vloop, vToken;
    unsigned char *blin = vbuf;
    unsigned short varg = 0;
    unsigned short ix, iy, iz, ikk, kt;
    unsigned short vbytepic = 0, vrecfim;
    unsigned char cuntam, vLinhaArg[255], vparam2[16], vpicret;
    char vSpace = 0;
    int vReta;
    typeInf vRetInf;
    unsigned short vTam = 0;
    unsigned char *pSave = *nextAddrLine;
    unsigned long vNextAddr = 0, vAntAddr = 0;

    // Separar linha entre comando e argumento
    linhacomando[0] = '\0';
    vLinhaArg[0] = '\0';
    ix = 0;
    iy = 0;
    while (*blin)
    {
        if (!varg && *blin >= 0x20 && *blin <= 0x2F)
        {
            varg = 0x01;
            linhacomando[ix] = '\0';
            iy = ix;
            ix = 0;

            if (*blin != 0x20)
                vLinhaArg[ix++] = *blin;
            else
                vSpace = 1;
        }
        else
        {
            if (!varg)
                linhacomando[ix] = *blin;
            else
                vLinhaArg[ix] = *blin;
            ix++;
        }

        *blin++;
    }

    if (!varg)
    {
        linhacomando[ix] = '\0';
        iy = ix;
    }
    else
        vLinhaArg[ix] = '\0';

    vpicret = 0;

    // Processar e definir o que fazer
    if (linhacomando[0] != 0)
    {
        // Se for numero o inicio da linha, eh entrada de programa, senao eh comando direto
        if (linhacomando[0] >= 0x31 && linhacomando[0] <= 0x39) // 0 nao é um numero de linha valida
        {
            *pTypeLine = 0x01;

            // Entrada de programa
            tokenizeLine(vLinhaArg);
            saveLine(linhacomando, vLinhaArg);
        }
        else
        {
            *pTypeLine = 0x00;

            for (iz = 0; iz < iy; iz++)
                linhacomando[iz] = toupper(linhacomando[iz]);

            // Comando Direto
            /*if (!strcmp(linhacomando,"CLEAR") && iy == 5)
            {
                clearScr();
            }
            else*/ if (!strcmp(linhacomando,"NEW") && iy == 3)
            {
                *pStartProg = 0x00;
                *(pStartProg + 1) = 0x00;
                *(pStartProg + 2) = 0x00;

                *nextAddrLine = pStartProg;
                *firstLineNumber = 0;
                *addrFirstLineNumber = 0;
            }
            else if (!strcmp(linhacomando,"LIST") && iy == 4)
            {
                listProg(vLinhaArg);
            }
            else if (!strcmp(linhacomando,"RUN") && iy == 3)
            {
                runProg(vLinhaArg);
            }
            else if (!strcmp(linhacomando,"DEL") && iy == 3)
            {
                delLine(vLinhaArg);
            }
            /*else if (!strcmp(linhacomando,"FRE") && iy == 3)
            {
                strcpy(vRetInf.tString, vLinhaArg);
                basFre(&vRetInf);
            }*/
            //*************************************************
            // ESSE COMANDO NAO VAI EXISTIR QUANDO FOR PRA BIOS
            //*************************************************
            else if (!strcmp(linhacomando,"QUIT") && iy == 4)
            {
                *pProcess = 0x00;
            }
            //*************************************************
            //*************************************************
            //*************************************************
            else
            {
                // Tokeniza a linha toda
                strcpy(vRetInf.tString, linhacomando);

                if (vSpace)
                    strcat(vRetInf.tString, " ");

                strcat(vRetInf.tString, vLinhaArg);

                tokenizeLine(vRetInf.tString);

                strcpy(vLinhaArg, vRetInf.tString);

                // Salva a linha pra ser interpretada
                vTam = strlen(vLinhaArg);
                vNextAddr = comandLineTokenized + (vTam + 6);

                *comandLineTokenized = ((vNextAddr & 0xFF0000) >> 16);
                *(comandLineTokenized + 1) = ((vNextAddr & 0xFF00) >> 8);
                *(comandLineTokenized + 2) =  (vNextAddr & 0xFF);

                // Grava numero da linha
                *(comandLineTokenized + 3) = 0xFF;
                *(comandLineTokenized + 4) = 0xFF;

                // Grava linha tokenizada
                for(kt = 0; kt < vTam; kt++)
                    *(comandLineTokenized + (kt + 5)) = vLinhaArg[kt];

                // Grava final linha 0x00
                *(comandLineTokenized + (vTam + 5)) = 0x00;
                *(comandLineTokenized + (vTam + 6)) = 0x00;
                *(comandLineTokenized + (vTam + 7)) = 0x00;
                *(comandLineTokenized + (vTam + 8)) = 0x00;

                vAntAddr = comandLineTokenized;
                comandLineTokenized += 5;
                *nextAddrSimpVar = pStartSimpVar;
                *nextAddrArrayVar = pStartArrayVar;
                *nextAddrString = pStartString;
                *vMaisTokens = 0;
                *vParenteses = 0x00;
                *vTemIf = 0x00;
                *vTemThen = 0;
                *vTemElse = 0;
                *vTemIfAndOr = 0x00;
                pointerRunProg = comandLineTokenized;
                vRetInf.tString[0] = 0x00;
                do
                {
                    *doisPontos = 0;
                    *vInicioSentenca = 1;
                    vReta = executeToken(*pointerRunProg++, &vRetInf);
                } while (*doisPontos);
                comandLineTokenized = vAntAddr;

                if (vReta == -1)
                    printText("\r\nSyntax Error !\r\n\0");
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Transforma linha em tokens, se existirem
//-----------------------------------------------------------------------------
void tokenizeLine(unsigned char *pTokenized)
{
    unsigned char vLido[32], vLidoCaps[32], vAspas, vAchou = 0;
    unsigned char *blin = pTokenized;
    unsigned short ix, iy, kt, iz, iw;
    unsigned char vToken, vLinhaArg[255], vparam2[16], vpicret;
    char vbuffer [sizeof(long)*8+1];
    char vFirstComp = 0;

    // Separar linha entre comando e argumento
    vLinhaArg[0] = '\0';
    vLido[0]  = '\0';
    ix = 0;
    iy = 0;
    vAspas = 0;

    while (1)
    {
        vLido[ix] = '\0';

        if (*blin == 0x22)
            vAspas = !vAspas;

		if (!vAspas && !strchr(operandsWithTokens, *(blin - 1)) && strchr(operandsWithTokens, *blin) && !strchr(operandsWithTokens, *(blin + 1)))
		{
            vAchou = 0;
			for(kt = 0; kt < keywordsUnique_count; kt++)
			{
				if(keywordsUnique[kt].keyword[0] == *blin)
                {
					vToken = keywordsUnique[kt].token;

                    for(kt = 0; kt < ix; kt++)
                        vLinhaArg[iy++] = vLido[kt];

                    vLinhaArg[iy++] = vToken;

					blin++;

					if (!*blin)
						break;

					vLido[0] = '\0';
					ix = 0;

					vAchou = 1;
                }
			}

            if (vAchou)
                continue;
		}

        // Se for quebrador sequencia, verifica se é um token
        if ((!vAspas && (*blin == 0x20 /* space */ || *blin == 0x28 /* ( */ || *blin == 0x29 /* ) */ || *blin == 0x3C /* < */ || *blin == 0x3E /* > */ || *blin == 0x3D /* = */ /* vai ser <> >= <=*/)) || !*blin)
        {
            // Montar comparacoes "<>", ">=" e "<="
            if (*blin == 0x3C || *blin == 0x3E || *blin == 0x3D)
            {
                if (!vFirstComp)
                {
                    for(kt = 0; kt < ix; kt++)
                        vLinhaArg[iy++] = vLido[kt];
                    vLido[0] = 0x00;
                    ix = 0;
                    vFirstComp = 1;
                }

                vLido[ix++] = *blin;

                if (ix < 2)
                {
                    blin++;
                    continue;
                }

                vFirstComp = 0;
            }

            if (vLido[0])
            {
                vToken = 0;

                if (ix > 1)
                {
                    // Transforma em Caps pra comparar com os tokens
                    for (kt = 0; kt < ix; kt++)
                        vLidoCaps[kt] = toupper(vLido[kt]);

                    vLidoCaps[ix] = 0x00;

                    iz = strlen(vLidoCaps);
/*					if (iz == 1)
					{
						// Compara pra ver se é um token caracter unico
						for(kt = 0; kt < keywordsUnique_count; kt++)
						{
							if(keywordsUnique[kt].keyword == vLidoCaps)
                            {
								vToken = keywordsUnique[kt].token;
                                break;
                            }
						}
					}
					else
					{*/
						// Compara pra ver se é um token
						for(kt = 0; kt < keywords_count; kt++)
						{
							iw = strlen(keywords[kt].keyword);

                            if (iw == 2 && iz == iw)
                            {
                                if (vLidoCaps[0] == keywords[kt].keyword[0] && vLidoCaps[1] == keywords[kt].keyword[1])
                                {
                                    vToken = keywords[kt].token;
                                    break;
                                }
                            }
                            else
                            {
                                if(strncmp(vLidoCaps, keywords[kt].keyword, iw) == 0)
                                {
                                    vToken = keywords[kt].token;
                                    break;
                                }
                            }
						}
/*                    }*/
                }

                if (vToken)
                {
                    vLinhaArg[iy++] = vToken;

                    if (*blin == 0x28 || *blin == 0x29)
                        vLinhaArg[iy++] = *blin;
                }
                else
                {
                    for(kt = 0; kt < ix; kt++)
                        vLinhaArg[iy++] = vLido[kt];

                    if (*blin && *blin != 0x20)
                        vLinhaArg[iy++] = *blin;
                }
            }
            else
            {
                if (*blin == 0x28 || *blin == 0x29)
                    vLinhaArg[iy++] = *blin;
            }

            if (!*blin)
                break;

            vLido[0] = '\0';
            ix = 0;
        }
        else
        {
            vLido[ix++] = *blin;
        }

        blin++;
    }

    vLinhaArg[iy] = 0x00;

    for(kt = 0; kt < iy; kt++)
        pTokenized[kt] = vLinhaArg[kt];

    pTokenized[iy] = 0x00;
}

//-----------------------------------------------------------------------------
// Salva a linha no formato:
// NN NN NN LL LL xxxxxxxxxxxx 00
// onde:
//      NN NN NN         = endereço da proxima linha
//      LL LL            = Numero da linha
//      xxxxxxxxxxxxxx   = Linha Tokenizada
//      00               = Indica fim da linha
//-----------------------------------------------------------------------------
void saveLine(unsigned char *pNumber, unsigned char *pTokenized)
{
    unsigned short vTam = 0, kt;
    unsigned char *pSave = *nextAddrLine;
    unsigned long vNextAddr = 0, vAntAddr = 0, vNextAddr2 = 0;
    unsigned short vNumLin = 0;
    unsigned char *pAtu = *nextAddrLine, *pLast = *nextAddrLine;

    vNumLin = atoi(pNumber);

    if (*firstLineNumber == 0)
    {
        *firstLineNumber = vNumLin;
        *addrFirstLineNumber = pStartProg;
    }
    else
    {
        vNextAddr = findNumberLine(vNumLin, 0, 0);

        if (vNextAddr > 0)
        {
            pAtu = vNextAddr;

            if (((*(pAtu + 3) << 8) | *(pAtu + 4)) == vNumLin)
            {
                printText("Line number already exists\r\n\0");
                return;
            }

            vAntAddr = findNumberLine(vNumLin, 1, 0);
        }
    }

    vTam = strlen(pTokenized);
    if (vTam)
    {
        // Calcula nova posição da proxima linha
        if (vNextAddr == 0)
        {
            *nextAddrLine += (vTam + 6);
            vNextAddr = *nextAddrLine;

            *addrLastLineNumber = pSave;
        }
        else
        {
            if (*firstLineNumber > vNumLin)
            {
                *firstLineNumber = vNumLin;
                *addrFirstLineNumber = *nextAddrLine;
            }

            *nextAddrLine += (vTam + 6);
            vNextAddr2 = *nextAddrLine;

            if (vAntAddr != vNextAddr)
            {
                pLast = vAntAddr;
                vAntAddr = pSave;
                *pLast       = ((vAntAddr & 0xFF0000) >> 16);
                *(pLast + 1) = ((vAntAddr & 0xFF00) >> 8);
                *(pLast + 2) =  (vAntAddr & 0xFF);
            }

            pLast = *addrLastLineNumber;
            *pLast       = ((vNextAddr2 & 0xFF0000) >> 16);
            *(pLast + 1) = ((vNextAddr2 & 0xFF00) >> 8);
            *(pLast + 2) =  (vNextAddr2 & 0xFF);
        }

        pAtu = *nextAddrLine;
        *pAtu       = 0x00;
        *(pAtu + 1) = 0x00;
        *(pAtu + 2) = 0x00;
        *(pAtu + 3) = 0x00;
        *(pAtu + 4) = 0x00;

        // Grava endereço proxima linha
        *pSave++ = ((vNextAddr & 0xFF0000) >> 16);
        *pSave++ = ((vNextAddr & 0xFF00) >> 8);
        *pSave++ =  (vNextAddr & 0xFF);

        // Grava numero da linha
        *pSave++ = ((vNumLin & 0xFF00) >> 8);
        *pSave++ = (vNumLin & 0xFF);

        // Grava linha tokenizada
        for(kt = 0; kt < vTam; kt++)
            *pSave++ = *pTokenized++;

        // Grava final linha 0x00
        *pSave = 0x00;
    }
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
void showErrorMessage(char pError, unsigned int pNumLine)
{
    char sNumLin [sizeof(short)*8+1];

    itoa(pNumLine, sNumLin, 10);

    switch(pError)
    {
        case -1:
            printText("Syntax Error at \0");
            break;
        case -2:
            printText("Overflow Error at \0");
            break;
        case -3:
            printText("Zero Division Error at \0");
            break;
        case -4:
            printText("Parentheses Missing Error at \0");
            break;
        case -5:
            printText("Variable Inexistente Error at \0");
            break;
        case -6:
            printText("Incorrect Value Error at \0");
            break;
        default:
            printText("Unknow Error at \0");
            break;
    }
    printText(sNumLin);
    printText(" !\r\n\0");
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
void runProg(unsigned char *pNumber)
{
    // Default rodar desde a primeira linha
    int pIni = 0, ix;
    unsigned char *vStartList = pStartProg;
    unsigned long vNextList;
    unsigned short vNumLin;
    unsigned int vInt;
    unsigned char vString[255], vTipoRet;
    unsigned long vReal;
    typeInf vRetInf;
    int vReta;
    char sNumLin [sizeof(short)*8+1];
    char vbuffer [sizeof(long)*8+1];

    *nextAddrSimpVar = pStartSimpVar;
    *nextAddrArrayVar = pStartArrayVar;
    *nextAddrString = pStartString;

    for (ix = 0; ix < 0x2000; ix++)
        *(pStartSimpVar + ix) = 0x00;

    for (ix = 0; ix < 0x6000; ix++)
        *(pStartArrayVar + ix) = 0x00;

    for (ix = 0; ix < 0xFF; ix++)
        *(pStartListVarUse + ix) = 0x00;

    vNextList = pStartListVarUse;
    vNextList += 10;
    *(pStartListVarUse + 6) = ((vNextList & 0xFF000000) >>24);
    *(pStartListVarUse + 7) = ((vNextList & 0x00FF0000) >>16);
    *(pStartListVarUse + 8) = ((vNextList & 0x0000FF00) >>8);
    *(pStartListVarUse + 9) = (vNextList & 0x000000FF);

    if (pNumber[0] != 0x00)
    {
        // rodar desde uma linha especifica
        pIni = atoi(pNumber);
    }

    vStartList = findNumberLine(pIni, 0, 0);

    // Não achou numero de linha inicial
    if (!vStartList)
    {
        printText("Non-existent line number\r\n\0");
        return;
    }

    vNextList = vStartList;

    while (1)
    {
        // Guarda proxima posição
        vNextList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
        *nextAddr = vNextList;

        if (vNextList)
        {
            // Pega numero da linha
            vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);

            vStartList += 5;

            // Pega caracter a caracter da linha
            *vMaisTokens = 0;
            *vParenteses = 0x00;
            *vTemIf = 0x00;
            *vTemThen = 0;
            *vTemElse = 0;
            *vTemIfAndOr = 0x00;
            vRetInf.tString[0] = 0x00;
            pointerRunProg = vStartList;

            do
            {
                *doisPontos = 0;
                *vParenteses = 0x00;
                *vInicioSentenca = 1;
                vReta = executeToken(*pointerRunProg++, &vRetInf);
            } while (*doisPontos);

#ifdef __DEBUG__
ltoa(vNumLin, vbuffer, 10);
printText("-------> Aqui 000 - vNumLin=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

            if (vReta < 0)
            {
#ifdef __DEBUG__
/*ltoa(vReta, vbuffer, 16);
printText("-------> Aqui 009 - vReta=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif
                showErrorMessage(vReta, vNumLin);

                break;
            }

            vNextList = *nextAddr;
            vStartList = vNextList;
        }
        else
            break;
    }
}


//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
int executeToken(unsigned char pToken, typeInf *pRetInf)
{
    char vReta;
    char vbuffer [sizeof(long)*8+1];
//    typeInf vRetInf;


    if (*vTemThen || *vTemElse)
    {
        *doisPontos = 1;

        if (*vInicioSentenca != 2)
            *vInicioSentenca = 1;
    }

#ifdef __DEBUG_6__
ltoa(pToken, vbuffer, 16);
printText("-------> Aqui 95 - pToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

#ifdef __DEBUG__
itoa(*vInicioSentenca, vbuffer, 16);
printText("-------> Aqui 95.1 - *vInicioSentenca=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    switch (pToken)
    {
        case 0x00:  // End of Line
            vReta = 0;
            break;
        case 0x80:  // Let
            vReta = basLet(pRetInf);
            break;
        case 0x81:  // Print
            vReta = basPrint(pRetInf);
            break;
        case 0x82:  // IF
            vReta = basIf(pRetInf);
            break;
        case 0x85:  // FOR
            vReta = basFor(pRetInf);
            break;
        case 0x87:  // NEXT
            vReta = basNext(pRetInf);
            break;
        case 0x92:  // Input
            vReta = basInputGet(pRetInf, 250);
            break;
        case 0x93:  // Get
            vReta = basInputGet(pRetInf, 1);
            break;
        case 0x96:  // Home
            clearScr();
        case 0x97:  // Clear - Clear all variables
            vReta = 0;
            break;
        case 0x9B:  // Len
            vReta = basLen(pRetInf);
            break;
        case 0x9C:  // Val
            vReta = basVal(pRetInf);
            break;
        case 0x9D:  // Str$
            vReta = basStr(pRetInf);
            break;
        case 0xA1:  // Chr$
            vReta = basChr(pRetInf);
            break;
        case 0xA2:  // Fre(0)
            vReta = basFre(pRetInf);
            break;
        case 0xA3:  // Sqrt
            vReta = basSqrt(pRetInf);
            break;
        case 0xA4:  // Sin
            vReta = basSin(pRetInf);
            break;
        case 0xA5:  // Cos
            vReta = basCos(pRetInf);
            break;
        case 0xA6:  // Tan
            vReta = basTan(pRetInf);
            break;
        case 0xF3:  // AND
            vReta = basAnd(pRetInf);
            break;
        case 0xF4:  // OR
            vReta = basOr(pRetInf);
            break;
        case 0xF5:  // >=
            vReta = basCompare(pRetInf, pToken);
            break;
        case 0xF6:  // <=
            vReta = basCompare(pRetInf, pToken);
            break;
        case 0xF7:  // <>
            vReta = basCompare(pRetInf, pToken);
            break;
        case 0xF8:  // <
            vReta = basCompare(pRetInf, pToken);
            break;
        case 0xF9:  // =
            vReta = basEqual(pRetInf);
            break;
        case 0xFA:  // >
            vReta = basCompare(pRetInf, pToken);
            break;
        case 0xFB:  // ^
            vReta = basPow(pRetInf);
            break;
        case 0xFC:  // /
            vReta = basDiv(pRetInf);
            break;
        case 0xFD:  // *
            vReta = basMul(pRetInf);
            break;
        case 0xFE:  // -
            vReta = basSub(pRetInf);
            break;
        case 0xFF:  // +
            vReta = basSum(pRetInf);
            break;
        default:
            if (pToken < 0x80)
            {
                if (*vInicioSentenca)
                {
                    *pointerRunProg--;
                    vReta = basLet(pRetInf);
                }
                else
                    vReta = -1;
            }
            else
                vReta = -1;
    }

#ifdef __DEBUG_6__
ltoa(pToken, vbuffer, 16);
printText("-------> Aqui 95.2 - pToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    return vReta;
}

//-----------------------------------------------------------------------------
// Sintaxe:
//      LIST                : lista tudo
//      LIST <num>          : lista só a linha <num>
//      LIST <num>-         : lista a partir da linha <num>
//      LIST <numA>-<numB>  : lista o intervalo de <numA> até <numB>, inclusive
//-----------------------------------------------------------------------------
void listProg(unsigned char *pArg)
{
    // Default listar tudo
    unsigned short pIni = 0, pFim = 0xFFFF;
    unsigned char *vStartList = pStartProg;
    unsigned long vNextList;
    unsigned short vNumLin;
    char sNumLin [sizeof(short)*8+1];
    unsigned char vLinhaList[255], sNumPar[10], vToken;
    int ix, iy, iz;

    if (pArg[0] != 0x00 && strchr(pArg,'-') != 0x00)
    {
        ix = 0;
        iy = 0;

        // listar intervalo
        while (pArg[ix] != '-')
            sNumPar[iy++] = pArg[ix++];

        sNumPar[iy] = 0x00;

        pIni = atoi(sNumPar);

        iy = 0;
        ix++;

        while (pArg[ix])
            sNumPar[iy++] = pArg[ix++];

        sNumPar[iy] = 0x00;

        if (sNumPar[0])
            pFim = atoi(sNumPar);
        else
            pFim = 0xFFFF;
    }
    else if (pArg[0] != 0x00)
    {
        // listar 1 linha
        pIni = atoi(pArg);
        pFim = pIni;
    }

    vStartList = findNumberLine(pIni, 0, 0);

    // Não achou numero de linha inicial
    if (!vStartList)
    {
        printText("Non-existent line number\r\n\0");
        return;
    }

    vNextList = vStartList;

    while (1)
    {
        // Guarda proxima posição
        vNextList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);

        if (vNextList)
        {
            // Pega numero da linha
            vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);

            if (vNumLin > pFim)
                break;

            vStartList += 5;
            ix = 0;

            // Coloca numero da linha na listagem
            itoa(vNumLin, sNumLin, 10);
            iz = 0;

            while (sNumLin[iz])
            {
                vLinhaList[ix++] = sNumLin[iz++];
            }

            vLinhaList[ix++] = 0x20;

            // Pega caracter a caracter da linha
            while (*vStartList)
            {
                vToken = *vStartList++;

                // Verifica se é token, se for, muda pra escrito
                if (vToken >= 0x80)
                {
                    // Procura token na lista
                    iy = findToken(vToken);
                    iz = 0;

                    if (iy >= 0x80) // Tokens com um char somente
                    {
                        iy -= 0x80;

                        while (keywordsUnique[iy].keyword[iz])
                        {
                            vLinhaList[ix++] = keywordsUnique[iy].keyword[iz++];
                        }
                    }
                    else
                    {
                        while (keywords[iy].keyword[iz])
                        {
                            vLinhaList[ix++] = keywords[iy].keyword[iz++];
                        }
                    }

                    if (*vStartList != 0x28)
                        vLinhaList[ix++] = 0x20;
                }
                else
                {
                    // Apenas inclui na listagem
                    vLinhaList[ix++] = vToken;
                }
            }

            vLinhaList[ix++] = '\r';
            vLinhaList[ix++] = '\n';
            vLinhaList[ix++] = '\0';

            printText(vLinhaList);

            vStartList = vNextList;
        }
        else
            break;
    }
}

//-----------------------------------------------------------------------------
// Sintaxe:
//      DEL <num>          : apaga só a linha <num>
//      DEL <num>-         : apaga a partir da linha <num> até o fim
//      DEL <numA>-<numB>  : apaga o intervalo de <numA> até <numB>, inclusive
//-----------------------------------------------------------------------------
void delLine(unsigned char *pArg)
{
    unsigned short pIni = 0, pFim = 0xFFFF;
    unsigned char *vStartList = pStartProg;
    unsigned long vDelAddr, vAntAddr, vNewAddr;
    unsigned short vNumLin;
    char sNumLin [sizeof(short)*8+1];
    unsigned char vLinhaList[255], sNumPar[10], vToken;
    int ix, iy, iz;

    if (pArg[0] != 0x00 && strchr(pArg,'-') != 0x00)
    {
        ix = 0;
        iy = 0;

        // listar intervalo
        while (pArg[ix] != '-')
            sNumPar[iy++] = pArg[ix++];

        sNumPar[iy] = 0x00;

        pIni = atoi(sNumPar);

        iy = 0;
        ix++;

        while (pArg[ix])
            sNumPar[iy++] = pArg[ix++];

        sNumPar[iy] = 0x00;

        if (sNumPar[0])
            pFim = atoi(sNumPar);
        else
            pFim = 0xFFFF;
    }
    else if (pArg[0] != 0x00)
    {
        pIni = atoi(pArg);
        pFim = pIni;
    }
    else
    {
        printText("Syntax Error !");
        return;
    }

    vDelAddr = findNumberLine(pIni, 0, 1);

    if (!vDelAddr)
    {
        printText("Non-existent line number\r\n\0");
        return;
    }

    while (1)
    {
        vStartList = vDelAddr;

        // Guarda proxima posição
        vNewAddr = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);

        if (!vNewAddr)
            break;

        // Pega numero da linha
        vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);

        if (vNumLin > pFim)
            break;

        vAntAddr = findNumberLine(vNumLin, 1, 1);

        // Apaga a linha atual
        *vStartList       = 0x00;
        *(vStartList + 1) = 0x00;
        *(vStartList + 2) = 0x00;
        *(vStartList + 3) = 0x00;
        *(vStartList + 4) = 0x00;

        vStartList += 5;

        while (*vStartList)
            *vStartList++ = 0x00;

        vStartList = vAntAddr;
        *vStartList++ = ((vNewAddr & 0xFF0000) >> 16);
        *vStartList++ = ((vNewAddr & 0xFF00) >> 8);
        *vStartList++ =  (vNewAddr & 0xFF);

        // Se for a primeira linha, reposiciona na proxima
        if (*firstLineNumber == vNumLin)
        {
            if (vNewAddr)
            {
                vStartList = vNewAddr;

                // Pega numero da linha
                vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);

                *firstLineNumber = vNumLin;
                *addrFirstLineNumber = vNewAddr;
            }
            else
            {
                *pStartProg = 0x00;
                *(pStartProg + 1) = 0x00;
                *(pStartProg + 2) = 0x00;

                *nextAddrLine = pStartProg;
                *firstLineNumber = 0;
                *addrFirstLineNumber = 0;
            }
        }

        if (!vNewAddr)
            break;

        vDelAddr = vNewAddr;
    }
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
int findToken(unsigned char pToken)
{
    unsigned char kt;

    // Procura o Token na lista e devolve a posição
    for(kt = 0; kt < keywords_count; kt++)
    {
        if (keywords[kt].token == pToken)
            return kt;
    }

    // Procura o Token nas operações de 1 char
    for(kt = 0; kt < keywordsUnique_count; kt++)
    {
        if (keywordsUnique[kt].token == pToken)
            return (kt + 0x80);
    }

    return -1;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
unsigned long findNumberLine(unsigned short pNumber, unsigned char pTipoRet, unsigned char pTipoFind)
{
    unsigned char *vStartList = *addrFirstLineNumber;
    unsigned char *vLastList = *addrFirstLineNumber;
    unsigned short vNumber = 0;
    char vbuffer [sizeof(long)*8+1];
/*    char vbuffer2 [sizeof(short)*8+1];*/

    if (pNumber)
    {
        while(vStartList)
        {
            vNumber = ((*(vStartList + 3) << 8) | *(vStartList + 4));

#ifdef __DEBUG__
/*ltoa(vLastList, vbuffer, 16);
printText("-------> Aqui 98 - \0");
printText(vbuffer);
ltoa(vStartList, vbuffer, 16);
printText(" - \0");
printText(vbuffer);
itoa(vNumber, vbuffer2, 10);
printText(" - \0");
printText(vbuffer2);
printText(" < \0");
itoa(pNumber, vbuffer2, 10);
printText(vbuffer2);
printText("\r\n\0");*/
#endif

            if ((!pTipoFind && vNumber < pNumber) || (pTipoFind && vNumber != pNumber))
            {
                vLastList = vStartList;
                vStartList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
            }
            else
                break;
        }
    }

#ifdef __DEBUG__
/*    if (!pTipoRet)
        ltoa(vStartList, vbuffer, 16);
    else
        ltoa(vLastList, vbuffer, 16);

    printText("-------> Aqui 99 - \0");
    printText(vbuffer);
    printText("\r\n\0");*/
#endif

    if (!pTipoRet)
        return vStartList;
    else
        return vLastList;
}

//-----------------------------------------------------------------------------
// Retornos: -1 - Erro, 0 - Nao Existe, 1 - eh um valor numeral
//           [endereco > 1] - Endereco da variavel
//
//           se retorno > 1: pVariable vai conter o valor numeral (qdo 1) ou
//                           o conteudo da variavel (qdo endereco)
//-----------------------------------------------------------------------------
long findVariable(unsigned char* pVariable)
{
    unsigned char* vLista = pStartListVarUse;
    unsigned char* vTemp = pStartListVarUse;
    unsigned char* vListaAtu;
    long vEnder = 0, vVal = 0, vVal1 = 0, vVal2 = 0, vVal3 = 0, vVal4 = 0;
    int ix = 0, iy = 0, iz = 0;
    char vbuffer [sizeof(long)*8+1];

    // Verifica as validações da variavel
#ifdef __DEBUG__
printText("-------> Aqui 76 - [\0");
printText(pVariable);
printText("]\r\n\0");
#endif

/*    // Procura primeiro na lista das 16 variaveis recentemente utilizadas
    vLista  = (((unsigned long)*(pStartListVarUse + 6) << 24) & 0xFF000000);
    vLista |= (((unsigned long)*(pStartListVarUse + 7) << 16) & 0x00FF0000);
    vLista |= (((unsigned long)*(pStartListVarUse + 8) << 8) & 0x0000FF00);
    vLista |= ((unsigned long)*(pStartListVarUse + 9) & 0x000000FF);

#ifdef __DEBUG__
ltoa(vLista, vbuffer, 16);
printText("-------> Aqui 659 - vLista=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif
    while(1)
    {
        if (!*vLista)
            break;

#ifdef __DEBUG__
ltoa(vLista, vbuffer, 16);
printText("-------> Aqui 659 - vLista=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

        if (*vLista == pVariable[0] && *(vLista + 1) ==  pVariable[1])
        {
            vEnder  = (((unsigned long)*(vLista + 2) << 24) & 0xFF000000);
            vEnder |= (((unsigned long)*(vLista + 3) << 16) & 0x00FF0000);
            vEnder |= (((unsigned long)*(vLista + 4) << 8) & 0x0000FF00);
            vEnder |= ((unsigned long)*(vLista + 5) & 0x000000FF);

            return vEnder;
        }

        vListaAtu = vLista;
        vLista  = (((unsigned long)*(vListaAtu + 6) << 24) & 0xFF000000);
        vLista |= (((unsigned long)*(vListaAtu + 7) << 16) & 0x00FF0000);
        vLista |= (((unsigned long)*(vListaAtu + 8) << 8) & 0x0000FF00);
        vLista |= ((unsigned long)*(vListaAtu + 9) & 0x000000FF);
    }*/

    // Se nao achou, procura na lista geral de variaveis simples
    vLista = pStartSimpVar;
#ifdef __DEBUG__
/*printText("-------> Aqui 77\r\n\0");

ltoa(vLista, vbuffer, 16);
printText("-------> Aqui 677 - vLista=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif
    while(1)
    {
        if (*(vLista + 1) == pVariable[0] && *(vLista + 2) ==  pVariable[1])
        {
            // Pega endereço da variavel pra delvover
            vEnder = vLista;

            // Pelo tipo da variavel, ja retorna na variavel de nome o conteudo da variavel
            if (*vLista == '$')
            {
                vTemp  = (((unsigned long)*(vLista + 4) << 24) & 0xFF000000);
                vTemp |= (((unsigned long)*(vLista + 5) << 16) & 0x00FF0000);
                vTemp |= (((unsigned long)*(vLista + 6) << 8) & 0x0000FF00);
                vTemp |= ((unsigned long)*(vLista + 7) & 0x000000FF);

                iy = *(vLista + 3);
                iz = 0;
                pVariable[iz++] = 0x22;
                for (ix = 0; ix < iy; ix++)
                {
                    pVariable[iz++] = *(vTemp + ix); // Numero gerado
                    pVariable[iz] = 0x00;
                }
                pVariable[iz++] = 0x22;
                pVariable[iz++] = 0x00;
            }
            else
            {
                vVal  = (((unsigned long)*(vLista + 4) << 24) & 0xFF000000);
                vVal |= (((unsigned long)*(vLista + 5) << 16) & 0x00FF0000);
                vVal |= (((unsigned long)*(vLista + 6) << 8) & 0x0000FF00);
                vVal |= ((unsigned long)*(vLista + 7) & 0x000000FF);

#ifdef __DEBUG__
ltoa(vVal, vbuffer, 16);
printText("-------> Aqui 77 - vVal=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif
                fix16_to_str(vVal, vbuffer, 4);
                iy = strlen(vbuffer);
                for (ix = 0; ix < iy; ix++)
                {
                    pVariable[ix] = vbuffer[ix]; // Numero gerado
                    pVariable[ix + 1] = 0x00;
                }
            }

            // Se achou, coloca no topo da lista de recentemente usadas, e descarta a ultima da lista
//            managerList(pVariable, vEnder);

            #ifdef __DEBUG__
            printText("-------> Aqui 7766\r\n\0");
            #endif

            return vEnder;
        }

        vLista += 8;

        if (*vLista >= pStartArrayVar || *vLista == 0x00)
            break;
    }

#ifdef __DEBUG__
printText("-------> Aqui 7765\r\n\0");
#endif
    return 0;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
char createVariable(unsigned char* pVariable, unsigned char* pValor, char pType)
{
    char vRet = 0;
    long vTemp = 0;
    char vbuffer [sizeof(long)*8+1];
    unsigned char* vNextSimpVar;

    vTemp = *nextAddrSimpVar;
    vNextSimpVar = *nextAddrSimpVar;

#ifdef __DEBUG__
ltoa(*nextAddrSimpVar, vbuffer, 16);
printText("-------> Aqui 759 - nextAddrSimpVar=[\0");
printText(vbuffer);
printText("]\r\n\0");

printText("-------> Aqui 760 - [\0");
printText(pVariable);
printText("]=[\0");
printText(pValor);
printText("]\r\n\0");
#endif

    *vNextSimpVar++ = pType;
    *vNextSimpVar++ = pVariable[0];
    *vNextSimpVar++ = pVariable[1];

    vRet = updateVariable(vNextSimpVar, pValor, pType, 0);

#ifdef __DEBUG__
/*printText("-------> Aqui 761 - [\0");
printText(pVariable);
printText("]=[\0");
printText(pValor);
printText("]\r\n\0");*/
#endif

//    managerList(pVariable, vTemp);

    *nextAddrSimpVar += 8;

#ifdef __DEBUG__
ltoa(*nextAddrSimpVar, vbuffer, 16);
printText("-------> Aqui 762 - nextAddrSimpVar=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    return vRet;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
char updateVariable(unsigned long* pVariable, unsigned char* pValor, char pType, char pOper)
{
    long vNumVal = 0;
    int ix, iz = 0;
    char vbuffer [sizeof(long)*8+1];
    unsigned char* vNextSimpVar;
    unsigned char* vNextString;

    vNextSimpVar = pVariable;

#ifdef __DEBUG__
ltoa(vNextSimpVar, vbuffer, 16);
printText("-------> Aqui 762 - vNextSimpVar=[\0");
printText(vbuffer);
printText("]\r\n\0");

printText("-------> Aqui 765 - pValor=[\0");
printText(pValor);
printText("]\r\n\0");
#endif

    if (pType != '$')
    {
        vNumVal = fix16_from_str(pValor);
        *vNextSimpVar++ = 0x00;
    }
    else
    {
        if (pValor[0] != 0x22)
            return -6;

        iz = strlen(pValor);    // Tamanho da strings

        if (pValor[iz - 1] != 0x22)
            return -6;

#ifdef __DEBUG__
/*ltoa(*nextAddrString, vbuffer, 16);
printText("-------> Aqui 761 - *nextAddrString=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif

        // Se for o mesmo tamanho ou menor, usa a mesma posição
        if (*vNextSimpVar <= (iz - 2) && pOper)
        {
            vNextString  = (((unsigned long)*(vNextSimpVar + 4) << 24) & 0xFF000000);
            vNextString |= (((unsigned long)*(vNextSimpVar + 5) << 16) & 0x00FF0000);
            vNextString |= (((unsigned long)*(vNextSimpVar + 6) << 8) & 0x0000FF00);
            vNextString |= ((unsigned long)*(vNextSimpVar + 7) & 0x000000FF);
        }
        else
            vNextString = *nextAddrString;

#ifdef __DEBUG__
/*ltoa(vNextString, vbuffer, 16);
printText("-------> Aqui 766 - nextAddrString=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif

        vNumVal = vNextString;

        for (ix = 0; ix < iz; ix++)
        {
            if (pValor[ix] != 0x22)
                *vNextString++ = pValor[ix];
        }

        if (*vNextSimpVar > (iz - 2) || !pOper)
            *nextAddrString = vNextString;

        *vNextSimpVar++ = (iz - 2);  // tamanho sem as aspa
    }

#ifdef __DEBUG__
ltoa(vNumVal, vbuffer, 16);
printText("-------> Aqui 762 - vNumVal=[\0");
printText(vbuffer);
printText("]\r\n\0");

/*ltoa(vNextSimpVar, vbuffer, 16);
printText("-------> Aqui 762 - vNextSimpVar=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif
    *vNextSimpVar++ = ((vNumVal & 0xFF000000) >>24);
    *vNextSimpVar++ = ((vNumVal & 0x00FF0000) >>16);
    *vNextSimpVar++ = ((vNumVal & 0x0000FF00) >>8);
    *vNextSimpVar++ = (vNumVal & 0x000000FF);

#ifdef __DEBUG__
/*ltoa(vNextSimpVar, vbuffer, 16);
printText("-------> Aqui 762 - vNextSimpVar=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif
    *(vNextSimpVar + 1) = 0x00;
    *(vNextSimpVar + 2) = 0x00;
    *(vNextSimpVar + 3) = 0x00;
    *(vNextSimpVar + 4) = 0x00;

    return 0;
}

//-----------------------------------------------------------------------------
// Lista das 16 variaveis mais usadas
// Estrutura:
//     [inicio 6 Bytes zeros + <4 Bytes prim item lista> ]->[<2 Bytes nome> + <4 Bytes endereco var> + <4 Bytes prox item lista>]->...[repeat]-> [final 10 Bytes zeros]
//-----------------------------------------------------------------------------
void managerList(unsigned char* pVariable, unsigned long pEnder)
{
    unsigned char* vListaProx = pStartListVarUse;
    unsigned char* vListaAtu = pStartListVarUse;
    unsigned char* vListaAnt = pStartListVarUse;
    unsigned long vTemp = 0;
    char ix = 0;

    vListaAtu  = (((unsigned long)*(pStartListVarUse + 6) << 24) & 0xFF000000);
    vListaAtu |= (((unsigned long)*(pStartListVarUse + 7) << 16) & 0x00FF0000);
    vListaAtu |= (((unsigned long)*(pStartListVarUse + 8) << 8) & 0x0000FF00);
    vListaAtu |= ((unsigned long)*(pStartListVarUse + 9) & 0x000000FF);
    vListaProx = vListaAtu;
    vListaAnt = vListaAtu;

    if (vListaAtu == 0)
        ix = 1;

    while(1)
    {
        if (vListaAtu != 0x00)
        {
            vListaProx  = (((unsigned long)*(vListaAtu + 6) << 24) & 0xFF000000);
            vListaProx |= (((unsigned long)*(vListaAtu + 7) << 16) & 0x00FF0000);
            vListaProx |= (((unsigned long)*(vListaAtu + 8) << 8) & 0x0000FF00);
            vListaProx |= ((unsigned long)*(vListaAtu + 9) & 0x000000FF);
        }

        // Cria Lista
        if (vListaProx == 0x00)
        {
            if (ix == 0)
                vListaAtu = (pStartListVarUse + 10);
            else if (ix < 16)
                vListaAtu += 10;

            vListaProx  = (((unsigned long)*(pStartListVarUse + 6) << 24) & 0xFF000000);
            vListaProx |= (((unsigned long)*(pStartListVarUse + 7) << 16) & 0x00FF0000);
            vListaProx |= (((unsigned long)*(pStartListVarUse + 8) << 8) & 0x0000FF00);
            vListaProx |= ((unsigned long)*(pStartListVarUse + 9) & 0x000000FF);

            // Inicio lista passa a apontar pro ultimo
            vTemp = vListaAtu;
            *(pStartListVarUse + 6) = ((vTemp & 0xFF000000) >>24);
            *(pStartListVarUse + 7) = ((vTemp & 0x00FF0000) >>16);
            *(pStartListVarUse + 8) = ((vTemp & 0x0000FF00) >>8);
            *(pStartListVarUse + 9) = (vTemp & 0x000000FF);

            // Altera o ultimo item
            *vListaAtu++ = pVariable[0];
            *vListaAtu++ = pVariable[1];
            *vListaAtu++ = ((pEnder & 0xFF000000) >>24);
            *vListaAtu++ = ((pEnder & 0x00FF0000) >>16);
            *vListaAtu++ = ((pEnder & 0x0000FF00) >>8);
            *vListaAtu++ = (pEnder & 0x000000FF);

            vTemp = vListaProx;
            *vListaAtu++ = ((vTemp & 0xFF000000) >>24);   // Aponta pro primeiro item
            *vListaAtu++ = ((vTemp & 0x00FF0000) >>16);
            *vListaAtu++ = ((vTemp & 0x0000FF00) >>8);
            *vListaAtu++ = (vTemp & 0x000000FF);

            // Zera prox pos item anterior lista
            if (ix == 16)
            {
                *(vListaAnt + 6) = 0x00;
                *(vListaAnt + 7) = 0x00;
                *(vListaAnt + 8) = 0x00;
                *(vListaAnt + 9) = 0x00;
            }

            return;
        }

        vListaAnt = vListaAtu;
        vListaAtu = vListaProx;

        ix++;
    }
}

//-----------------------------------------------------------------------------
// FUNCOES PONTO FLUTUANTE
//-----------------------------------------------------------------------------
/*unsigned int powNum(unsigned int pbase, unsigned char pexp)
{
    unsigned int iz, vRes = pbase;

    for(iz = 0; iz < pexp; iz++)
    {
        vRes = vRes * pbase;
    }

    return vRes;
}

//-----------------------------------------------------------------------------
unsigned long floatStringToFpp(unsigned char* pFloat)
{
    unsigned long intPart = 0, decPart = 0;
    unsigned long vExp, vSig = 0, vMant = 0;
    unsigned long vFpp = 0, vTemp, vBase;
    unsigned int ix, iy, iz = 0;
    unsigned char lenFloat = strlen(pFloat);
    unsigned char strPart[10];

    // Verifica sinal
    if (pFloat[0] == '-')
    {
        iz = 1;
        vSig = 1;
    }

    // Pega parte inteira
    strPart[0] = 0x00;
    iy = 0;

    for (ix = iz; ix < lenFloat; ix++)
    {
        if (pFloat[ix] == '.')
        {
            iy = ix + 1;
            break;
        }

        strPart[ix] = pFloat[ix];
        strPart[ix + 1] = 0x00;
    }
    intPart = atoi(strPart);

    // Pega parte decimal
    if (iy > 0)
    {
        strPart[0] = 0x00;
        iz = 0;
        for (ix = iy; ix < lenFloat; ix++)
        {
            strPart[iz++] = pFloat[ix];
            strPart[iz] = 0x00;
        }
        decPart = atoi(strPart);
    }

    // Calcula parte decimal em binaria
    iz--;
    vBase = powNum(10,iz);
    vTemp = 0x00;
    iz = 0;

    while (decPart > 0)
    {
        decPart = decPart * 2;
        if (decPart > vBase)
        {
            decPart = decPart - vBase;
            vTemp = ((vTemp << 1) | 1);
        }
        else
            vTemp = (vTemp << 1);

        iz++;
        if (iz == 16)
            break;
    }
    vMant = vTemp;

    // Calcula Expoente e Mantissa
    if (intPart == 0)
    {
        vBase = !(powNum(2,iz) - 1);
        vTemp = vMant;        
        ix = 0;
        while(!(vTemp & vBase))
        {
            vTemp << 1;
            ix = ix + 1;
        }
        vExp = 127 - ix;
        vMant = (vMant << ix) & !vBase;
        vMant = (((intPart << iz) | vMant) << (24 - ix)) & 0x7FFFFF;
    }
    else
    {
        vTemp = intPart;
        ix = 0;
        while(vTemp)
        {
            vTemp >> 1;
            ix = ix + 1;
        }
        ix--;
        vExp = 127 + ix;
        vMant = (((intPart << iz) | vMant) << (24 - (iz + ix))) & 0x7FFFFF;
    }

    // Junta Tudo
    vFpp = (vSig << 31) | (vExp << 23) | vMant;

    return vFpp;
}

//-----------------------------------------------------------------------------
unsigned char* fppTofloatString(unsigned long pFpp)
{
    unsigned char* vRes[20], vRes2[20];
    unsigned int vExp, vMant, vSig, vBase, vBaseExp;
    unsigned int intPart = 0, decPart = 0, vTemp, ix;

    // Sinal
    vSig = (pFpp & 0xF0000000) >> 31;

    // Expoente
    vExp = (pFpp & 0x7F800000) >> 23;
    if (vExp > 127)
        vExp = vExp - 127;
    else
        vExp = 127 - vExp; 

    // Mantissa
    vTemp = (pFpp << 9);
    vMant = 0;
    ix = 1;
    while (vTemp)
    {
        if (vTemp & 0x80000000)
        {
            vMant = vMant + powNum(5, ix);
        }
        vTemp = vTemp << 1;
        vMant = vMant * 10;

        ix = ix + 1;
    }

    vBase = powNum(10,ix);
    vBaseExp = powNum(2,vExp);
    intPart = (vMant * vBaseExp) / vBase;
    decPart = ((vMant * vBaseExp) - (intPart * vBase));

    strcat(vRes,(vSig == 0 ? "" : "-"));
    itoa(intPart,vRes2,10);
    strcat(vRes,vRes2);
    strcat(vRes,".");
    itoa(decPart,vRes2,10);
    strcat(vRes,vRes2);

    return vRes;
}

unsigned long shift32RightJamming(int a, int count)
{
    if(count == 0)       
        return a;
    else if(count < 32)     
        return (a >> count) | ((a << ((-count) & 31)) != 0);
    else            
        return a != 0;
}

unsigned long fppAdd(unsigned long a, unsigned long b)
{
    unsigned long vRes = 0;
    int zExp;
    unsigned long zFrac;

    unsigned long aFrac = a & 0x007FFFFF;
    unsigned long bFrac = b & 0x007FFFFF;

    int aExp = (a >> 23) & 0xFF;
    int bExp = (b >> 23) & 0xFF;

    unsigned long aSign = a >> 31;
    unsigned long bSign = b >> 31;

    unsigned long zSign = aSign;

    int expDiff = aExp - bExp;
    aFrac <<= 6;
    bFrac <<= 6;

    // align exponents if needed
    if(expDiff > 0)
    {
        if(bExp == 0) --expDiff;
        else bFrac |= 0x20000000;

        bFrac = shift32RightJamming(bFrac, expDiff);
        zExp = aExp;
    }
    else if(expDiff < 0)
    {
        if(aExp == 0) ++expDiff;
        else aFrac |= 0x20000000;

        aFrac = shift32RightJamming(aFrac, -expDiff);
        zExp = bExp;
    }
    else if(expDiff == 0)
    {
        if(aExp == 0) return (zSign << 31) | ((aFrac + bFrac) >> 13);

        zFrac = 0x40000000 + aFrac + bFrac;
        zExp = aExp;

        return (zSign << 31) | ((zExp << 23) + (zFrac >> 7));
    }

    aFrac |= 0x20000000;
    zFrac = (aFrac + bFrac) << 1;
    --zExp;

    if((unsigned long)zFrac < 0)
    {
        zFrac = aFrac + bFrac;
        ++zExp;
    }

    // reconstruct the float; I've removed the rounding code and just truncate
    vRes = (zSign << 31) | ((zExp << 23) + (zFrac >> 7));

    return vRes;
}

long fppSub(unsigned int a, unsigned int b)
{
    long vRes = 0;

    return vRes;
}

unsigned long fppMul(unsigned long a, unsigned long b)
{
    unsigned long vRes = 0;

    // extract mantissa, exponent and sign
    unsigned long aFrac = a & 0x007FFFFF;
    unsigned long bFrac = b & 0x007FFFFF;

    unsigned long aExp = (a >> 23) & 0xFF;
    unsigned long bExp = (b >> 23) & 0xFF;

    unsigned long aSign = a >> 31;
    unsigned long bSign = b >> 31;
    unsigned long zFrac;

    unsigned long zFrac0;
    unsigned long zFrac1;

    // compute sign bit
    unsigned long zSign = aSign ^ bSign;

    // removed: handle edge conditions where the exponent is about to overflow
    // see the SoftFloat library for more information

    // compute exponent
    unsigned long zExp = aExp + bExp - 0x7F;

    // add implicit `1' bit
    aFrac = (aFrac | 0x00800000) << 7;
    bFrac = (bFrac | 0x00800000) << 8;

    zFrac = (unsigned long)aFrac * (unsigned long)bFrac;

    zFrac0 = zFrac >> 32;
    zFrac1 = zFrac & 0xFFFFFFFF;

    // check if we overflowed into more than 23-bits and handle accordingly
    zFrac0 |= (zFrac1 != 0);
    if(0 <= (unsigned long)(zFrac0 << 1))
    {
        zFrac0 <<= 1;
        zExp--;
    }

    // reconstruct the float; I've removed the rounding code and just truncate
    vRes = (zSign << 31) | ((zExp << 23) + (zFrac >> 7));

    return vRes;
}

long fppDiv(unsigned int a, unsigned int b)
{
    long vRes = 0;

    return vRes;
}

long fppSqrt(unsigned int a, unsigned int b)
{
    long vRes = 0;

    return vRes;
}

long fppSin(unsigned int a, unsigned int b)
{
    long vRes = 0;

    return vRes;
}

long fppCos(unsigned int a, unsigned int b)
{
    long vRes = 0;

    return vRes;
}

long fppTan(unsigned int a, unsigned int b)
{
    long vRes = 0;

    return vRes;
}*/

//-----------------------------------------------------------------------------
long fix16_add(long a, long b)
{
    // Use unsigned integers because overflow with signed integers is
    // an undefined operation (http://www.airs.com/blog/archives/120).
    long _a = a, _b = b;
    long sum = _a + _b;

    // Overflow can only happen if sign of a == sign of b, and then
    // it causes sign of sum != sign of a.
    if (!((_a ^ _b) & 0x80000000) && ((_a ^ sum) & 0x80000000))
        return fix16_overflow;

    return sum;
}

//-----------------------------------------------------------------------------
long fix16_sub(long a, long b)
{
    long _a = a, _b = b;
    long diff = _a - _b;

    // Overflow can only happen if sign of a != sign of b, and then
    // it causes sign of diff != sign of a.
    if (((_a ^ _b) & 0x80000000) && ((_a ^ diff) & 0x80000000))
        return fix16_overflow;

    return diff;
}

//-----------------------------------------------------------------------------
long fix16_mul(long inArg0, long inArg1)
{
    // Each argument is divided to 16-bit parts.
    //                  AB
    //          *    CD
    // -----------
    //                  BD  16 * 16 -> 32 bit products
    //               CB
    //               AD
    //              AC
    //           |----| 64 bit product
    long A = (inArg0 >> 16), C = (inArg1 >> 16);
    unsigned long B = (inArg0 & 0xFFFF), D = (inArg1 & 0xFFFF);
    long AC = A*C;
    long AD_CB = A*D + C*B;
    unsigned long BD = B*D;

    long product_hi = AC + (AD_CB >> 16);

    // Handle carry from lower 32 bits to upper part of result.
    unsigned long ad_cb_temp = AD_CB << 16;
    unsigned long product_lo = BD + ad_cb_temp;
    if (product_lo < BD)
        product_hi++;

    // The upper 17 bits should all be the same (the sign).
    if (product_hi >> 31 != product_hi >> 15)
        return fix16_overflow;

    return (product_hi << 16) | (product_lo >> 16);
}

//-----------------------------------------------------------------------------
unsigned short clz(unsigned int x)
{
    unsigned short result = 0;
    if (x == 0) return 32;
    while (!(x & 0xF0000000)) { result += 4; x <<= 4; }
    while (!(x & 0x80000000)) { result += 1; x <<= 1; }
    return result;
}

//-----------------------------------------------------------------------------
long fix16_div(long a, long b)
{
    // This uses a hardware 32/32 bit division multiple times, until we have
    // computed all the bits in (a<<17)/b. Usually this takes 1-3 iterations.
    unsigned long remainder = (a >= 0) ? a : (-a);
    unsigned long divider = (b >= 0) ? b : (-b);
    unsigned long quotient = 0;
    int bit_pos = 17;
    unsigned long shifted_div = 0;
    long shift = 0;
    unsigned long div = 0;
    long result = 0;

    if (b == 0)
        return fix16_minimum;

    // Kick-start the division a bit.
    // This improves speed in the worst-case scenarios where N and D are large
    // It gets a lower estimate for the result by N/(D >> 17 + 1).
    if (divider & 0xFFF00000)
    {
        shifted_div = ((divider >> 17) + 1);
        quotient = remainder / shifted_div;
        remainder -= ((unsigned long)quotient * divider) >> 17;
    }

    // If the divider is divisible by 2^n, take advantage of it.
    while (!(divider & 0xF) && bit_pos >= 4)
    {
        divider >>= 4;
        bit_pos -= 4;
    }

    while (remainder && bit_pos >= 0)
    {
        // Shift remainder as much as we can without overflowing
        shift = clz(remainder);
        if (shift > bit_pos) shift = bit_pos;
        remainder <<= shift;
        bit_pos -= shift;

        div = remainder / divider;
        remainder = remainder % divider;
        quotient += div << bit_pos;

        if (div & ~(0xFFFFFFFF >> bit_pos))
                return fix16_overflow;

        remainder <<= 1;
        bit_pos--;
    }

    // Quotient is always positive so rounding is easy
    quotient++;

    result = quotient >> 1;

    // Figure out the sign of the result
    if ((a ^ b) & 0x80000000)
    {
        if (result == fix16_minimum)
                return fix16_overflow;

        result = -result;
    }

    return result;
}

//-----------------------------------------------------------------------------
char *itoa_loop(char *buf, unsigned int scale, unsigned int value, char skip)
{
    while (scale)
    {
        unsigned digit = (value / scale);

        if (!skip || digit || scale == 1)
        {
            skip = 0x00;
            *buf++ = '0' + digit;
            value %= scale;
        }

        scale /= 10;
    }
    return buf;
}

//-----------------------------------------------------------------------------
void fix16_to_str(long value, char *buf, int decimals)
{
    unsigned int uvalue = (value >= 0) ? value : -value;
    unsigned int intpart = (uvalue >> 16);
    unsigned int fracpart = (uvalue & 0xFFFF);
    unsigned int scale = scales[decimals & 7];

    if (value < 0)
        *buf++ = '-';

    // Separate the integer and decimal parts of the value
    fracpart = fix16_mul(fracpart, scale);

    if (fracpart >= scale)
    {
        // Handle carry from decimal part
        intpart++;
        fracpart -= scale;
    }

    // Format integer part
    buf = itoa_loop(buf, 10000, intpart, 1);

    // Format decimal part (if any)
    if (scale != 1)
    {
        *buf++ = '.';
        buf = itoa_loop(buf, scale / 10, fracpart, 0);
    }

    *buf = '\0';
}

//-----------------------------------------------------------------------------
int fix16_to_int(long a)
{
//    #ifdef FIXMATH_NO_ROUNDING
        return (a >> 16);
/*    #else
      if (a >= 0)
        return (a + (fix16_one >> 1)) / fix16_one;
      return (a - (fix16_one >> 1)) / fix16_one;
    #endif*/
}

//-----------------------------------------------------------------------------
long fix16_from_str(const char *buf)
{
    char negative = 0;
    unsigned int intpart = 0;
    int count = 0;
    int value = 0;
    unsigned int fracpart = 0;
    unsigned int scale = 1;

    while (isspace(*buf))
        buf++;

    // Decode the sign
    negative = (*buf == '-');
    if (*buf == '+' || *buf == '-')
        buf++;

    // Decode the integer part
    while (isdigit(*buf))
    {
        intpart *= 10;
        intpart += *buf++ - '0';
        count++;
    }

    if (count == 0 || count > 5
        || intpart > 32768 || (!negative && intpart > 32767))
        return fix16_overflow;

    value = intpart << 16;

    // Decode the decimal part
    if (*buf == '.' || *buf == ',')
    {
        buf++;

        fracpart = 0;
        scale = 1;
        while (isdigit(*buf) && scale < 100000)
        {
            scale *= 10;
            fracpart *= 10;
            fracpart += *buf++ - '0';
        }

        value += fix16_div(fracpart, scale);
    }

    // Verify that there is no garbage left over
    while (*buf != '\0')
    {
        if (!isdigit(*buf) && !isspace(*buf))
            return fix16_overflow;

        buf++;
    }

    return negative ? -value : value;
}

long fix16_sdiv(long inArg0, long inArg1)
{
    long result = fix16_div(inArg0, inArg1);

    if (result == fix16_overflow)
    {
        if ((inArg0 >= 0) == (inArg1 >= 0))
            return fix16_maximum;
        else
            return fix16_minimum;
    }

    return result;
}

/* The square root algorithm is quite directly from
 * http://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_.28base_2.29
 * An important difference is that it is split to two parts
 * in order to use only 32-bit operations.
 *
 * Note that for negative numbers we return -sqrt(-inValue).
 * Not sure if someone relies on this behaviour, but not going
 * to break it for now. It doesn't slow the code much overall.
 */
long fix16_sqrt(long inValue)
{
    unsigned char  neg = (inValue < 0);
    unsigned long num = (neg ? -inValue : inValue);
    unsigned long result = 0;
    unsigned long bit;
    unsigned char  n;

    // Many numbers will be less than 15, so
    // this gives a good balance between time spent
    // in if vs. time spent in the while loop
    // when searching for the starting value.
    if (num & 0xFFF00000)
        bit = (unsigned long)1 << 30;
    else
        bit = (unsigned long)1 << 18;

    while (bit > num) bit >>= 2;

    // The main part is executed twice, in order to avoid
    // using 64 bit values in computations.
    for (n = 0; n < 2; n++)
    {
        // First we get the top 24 bits of the answer.
        while (bit)
        {
            if (num >= result + bit)
            {
                num -= result + bit;
                result = (result >> 1) + bit;
            }
            else
            {
                result = (result >> 1);
            }
            bit >>= 2;
        }

        if (n == 0)
        {
            // Then process it again to get the lowest 8 bits.
            if (num > 65535)
            {
                // The remainder 'num' is too large to be shifted left
                // by 16, so we have to add 1 to result manually and
                // adjust 'num' accordingly.
                // num = a - (result + 0.5)^2
                //   = num + result^2 - (result + 0.5)^2
                //   = num - result - 0.5
                num -= result;
                num = (num << 16) - 0x8000;
                result = (result << 16) + 0x8000;
            }
            else
            {
                num <<= 16;
                result <<= 16;
            }

            bit = 1 << 14;
        }
    }

    // Finally, if next bit would have been 1, round the result upwards.
    if (num > result)
    {
        result++;
    }

    return (neg ? -(long)result : (long)result);
}

long fix16_sin_parabola(long inAngle)
{
    long abs_inAngle, abs_retval, retval;
    long mask;

    /* Absolute function */
    mask = (inAngle >> (sizeof(long)*CHAR_BIT-1));
    abs_inAngle = (inAngle + mask) ^ mask;

    /* On 0->PI, sin looks like x² that is :
       - centered on PI/2,
       - equals 1 on PI/2,
       - equals 0 on 0 and PI
      that means :  4/PI * x  - 4/PI² * x²
      Use abs(x) to handle (-PI) -> 0 zone.
     */
    retval = fix16_mul(FOUR_DIV_PI, inAngle) + fix16_mul( fix16_mul(_FOUR_DIV_PI2, inAngle), abs_inAngle );
    /* At this point, retval equals sin(inAngle) on important points ( -PI, -PI/2, 0, PI/2, PI),
       but is not very precise between these points
     */
    /* Absolute value of retval */
    mask = (retval >> (sizeof(long)*CHAR_BIT-1));
    abs_retval = (retval + mask) ^ mask;
    /* So improve its precision by adding some x^4 component to retval */
    retval += fix16_mul(X4_CORRECTION_COMPONENT, fix16_mul(retval, abs_retval) - retval );
    return retval;
}

long fix16_sin(long inAngle)
{
    long tempAngle = inAngle % (fix16_pi << 1);
    long tempAngleSq = 0;
    long tempOut = 0;
    long tempIndex = 0;

    if(tempAngle > fix16_pi)
        tempAngle -= (fix16_pi << 1);
    else if(tempAngle < -fix16_pi)
        tempAngle += (fix16_pi << 1);

    tempIndex = ((inAngle >> 5) & 0x00000FFF);
    if(_fix16_sin_cache_index[tempIndex] == inAngle)
        return _fix16_sin_cache_value[tempIndex];

    tempAngleSq = fix16_mul(tempAngle, tempAngle);

    tempOut = tempAngle;
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut -= (tempAngle / 6);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut += (tempAngle / 120);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut -= (tempAngle / 5040);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut += (tempAngle / 362880);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut -= (tempAngle / 39916800);

    _fix16_sin_cache_index[tempIndex] = inAngle;
    _fix16_sin_cache_value[tempIndex] = tempOut;

    return tempOut;
}

long fix16_cos(long inAngle)
{
    return fix16_sin(inAngle + (fix16_pi >> 1));
}

long fix16_tan(long inAngle)
{
    return fix16_sdiv(fix16_sin(inAngle), fix16_cos(inAngle));
}

/*long fix16_asin(long x)
{
    long out;

    if((x > fix16_one)
        || (x < -fix16_one))
        return 0;

    out = (fix16_one - fix16_mul(x, x));
    out = fix16_div(x, fix16_sqrt(out));
    out = fix16_atan(out);
    return out;
}

long fix16_acos(long x)
{
    return ((fix16_pi >> 1) - fix16_asin(x));
}

long fix16_atan2(long inY , long inX)
{
    long abs_inY, mask, angle, r, r_3;
    unsigned long* hash = (inX ^ inY);

    hash ^= hash >> 20;
    hash &= 0x0FFF;
    if((_fix16_atan_cache_index[0][hash] == inX) && (_fix16_atan_cache_index[1][hash] == inY))
        return _fix16_atan_cache_value[hash];

    // Absolute inY
    mask = (inY >> (sizeof(long)*CHAR_BIT-1));
    abs_inY = (inY + mask) ^ mask;

    if (inX >= 0)
    {
        r = fix16_div( (inX - abs_inY), (inX + abs_inY));
        r_3 = fix16_mul(fix16_mul(r, r),r);
        angle = fix16_mul(0x00003240 , r_3) - fix16_mul(0x0000FB50,r) + PI_DIV_4;
    } else {
        r = fix16_div( (inX + abs_inY), (abs_inY - inX));
        r_3 = fix16_mul(fix16_mul(r, r),r);
        angle = fix16_mul(0x00003240 , r_3)
            - fix16_mul(0x0000FB50,r)
            + THREE_PI_DIV_4;
    }
    if (inY < 0)
    {
        angle = -angle;
    }

    _fix16_atan_cache_index[0][hash] = inX;
    _fix16_atan_cache_index[1][hash] = inY;
    _fix16_atan_cache_value[hash] = angle;

    return angle;
}

long fix16_atan(long x)
{
    return fix16_atan2(x, fix16_one);
}*/

//-----------------------------------------------------------------------------
// FUNCOES BASIC
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Joga pra tela Texto.
// Syntaxe:
//      Print "<Texto>"/<value>[, "<Texto>"/<value>]
//-----------------------------------------------------------------------------
char basPrint(typeInf *pRetInf)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    int vReta;

#ifdef __DEBUG_4__
printText("-------> Aqui 4665\r\n\0");
#endif
    pRetInf->tString[0] = 0x00;
    vTemp[0] = 0x00;

    // Pega a parte depois do comando
    do
    {
        vToken = nextToken(&vTemp);

#ifdef __DEBUG_4__
itoa(vToken, sNumLin, 16);
printText("[\0");
printText(sNumLin);
printText("],\0");

printText("-------> Aqui 46.35 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
        if (vToken < 0)
            return -1;

        if (vToken > 0)
        {
#ifdef __DEBUG_4__
printText("-------> Aqui 4635 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
            ix = strlen(vTemp);

            if (vToken == 0x22)
                vAspas = !vAspas;

            // Se for ',' ou ';' e nao estiver dentro de aspas, inicia novo print
            if ((vToken == ',' || vToken == ';') && !vAspas)
            {
                // Se for ',' adiciona 9 espacos
                if (vToken == ',')
                {
                    for (iw = 0; iw < 9; iw++)
                    {
                        vTemp[ix++] = ' ';
                        vTemp[ix] = 0x00;
                    }
                }
                else // Se for ';' adiciona 1 espaco
                {
                    vTemp[ix++] = ' ';
                    vTemp[ix] = 0x00;
                }

                iz = strlen(vTemp);
                for (iw = 0; iw < iz; iw++)
                {
                    pRetInf->tString[iy++] = vTemp[iw];
                    pRetInf->tString[iy] = 0x00;
                }

                vTemp[0] = 0x00;
                ix = 0;
            }
            else if (vToken < 0x80)
            {
                vTemp[ix++] = (unsigned char)vToken;
                vTemp[ix] = 0x00;

                // analisa pra ver se é variavel, e se existe
                if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
                {
                    vReta = analiseVariable(&vTemp);
                    if (vReta < 0)
                        return vReta;
                }

                if (vToken == 0x29)
                {
                    if (*vParenteses)
                    {
                        *vParenteses = *vParenteses - 1;
                        break;
                    }
                    else
                        return -1;
                }
            }
#ifdef __DEBUG__
printText("-------> Aqui 4635.1 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
        }
    } while (vToken);

/*    if (vAspas)
        return -1;*/

#ifdef __DEBUG_4__
printText("-------> Aqui 4665 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
    iz = strlen(vTemp);
    for (iw = 0; iw < iz; iw++)
    {
        pRetInf->tString[iy++] = vTemp[iw];
        pRetInf->tString[iy] = 0x00;
    }

    ix = 0;

#ifdef __DEBUG__
printText("-------> Aqui 4665 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif
    // erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vAspas = 0;

    do
    {
        // Analisa linha pra escrever
        if (pRetInf->tString[ix] == 0x00)
            break;

#ifdef __DEBUG__
itoa(pRetInf->tString[ix], sNumLin, 16);
printText("[\0");
printText(sNumLin);
printText("],\0");
#endif
        // Nao imprime as aspas
        if (pRetInf->tString[ix] != 0x22)
        {
            if ((pRetInf->tString[ix] != 0x28 && pRetInf->tString[ix] != 0x29) || ((pRetInf->tString[ix] == 0x28 || pRetInf->tString[ix] == 0x29) && vAspas))
                printChar(pRetInf->tString[ix], 1);
        }
        else
            vAspas = !vAspas;

        ix++;
    } while (1);

    printText("\r\n\0");

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basChr(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz, vNum = 0, vToken = 0, vReta;
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                {
                    return -1;
                }
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    ix = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = atoi(vAscii);

            if (vNum == 0 || vNum > 255)
                return -1;

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iy = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iy = 1;
    }

    pRetInf->tString[0 + iy] = 0x22; // "
    pRetInf->tString[1 + iy] = vNum; // Numero gerado
    pRetInf->tString[2 + iy] = 0x22; // "
    pRetInf->tString[3 + iy] = 0x00; // \0

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basVal(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    // Erro, segundo caracter deve ser aspas
    if (vTemp[1] != 0x22)
        return -3;

    iy = strlen(vTemp) - 2;

    // Erro, penultimo caracter deve ser aspas
    if (vTemp[iy] != 0x22)
        return -3;

    ix = 0;
    iy = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28 || vTemp[ix] == 0x22)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = fix16_from_str(vAscii);

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    fix16_to_str(vNum, vbuffer, 4);
    iy = strlen(vbuffer);
    iz = iw;
    pRetInf->tString[iz] = 0x00; // \0
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[iz++] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[iz] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basStr(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    char vbuffer [sizeof(long)*8+1];
    int ix = 0, iy = 0, iz, vNum = 0, vToken = 0, vReta;
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                {
                    return -1;
                }
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    ix = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = fix16_from_str(vAscii);

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iy = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iy = 1;
    }

    fix16_to_str(vNum, vbuffer, 4);
    iy = strlen(vbuffer);
    iz = 0;
    pRetInf->tString[iz++] = 0x22; // "
    pRetInf->tString[iz] = 0x00; // \0
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[iz++] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[iz] = 0x00;
    }
    pRetInf->tString[iz++] = 0x22; // "
    pRetInf->tString[iz] = 0x00; // \0

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o tamanho da string
// Syntaxe:
//      LEN(<string>)
//-----------------------------------------------------------------------------
char basLen(typeInf *pRetInf)
{
    unsigned char vAscii[250];
    unsigned char vTemp[250];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    // Erro, segundo caracter deve ser aspas
    if (vTemp[1] != 0x22)
        return -3;

    iy = strlen(vTemp) - 2;

    // Erro, penultimo caracter deve ser aspas
    if (vTemp[iy] != 0x22)
        return -3;

    ix = 0;
    iy = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28 || vTemp[ix] == 0x22)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = strlen(vAscii);

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    ltoa(vNum, vbuffer, 10);
    iy = strlen(vbuffer);
    iz = 0;
    pRetInf->tString[iz] = 0x00; // \0
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[iz++] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[iz] = 0x00;
    }


    return 0;
}

//-----------------------------------------------------------------------------
// Devolve qtd memoria usuario disponivel
// Syntaxe:
//      FRE(0)
//-----------------------------------------------------------------------------
char basFre(typeInf *pRetInf)
{
    int vZero = 0;
    unsigned long vTotal;
    unsigned char vAscii[250];
    unsigned char vTemp[250];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    if (vTemp[1] == 0x30)
        vZero = 1;

    // Erro, ultimo caracter deve ser fecha parenteses
    if (vTemp[2] == 0x00)
        return -1;

    if (vTemp[2] == 0x29 & !vZero)
        return -1;

    // Achou o parenteses final
    if (vTemp[2] == 0x29 & vZero)
    {
        // Calcula Quantidade de Memoria e printa na tela
        printText("Memory Free for: \r\n\0");
        vTotal = (pStartArrayVar - pStartSimpVar) + (pStartStack - pStartString);
        ltoa(vTotal, vbuffer, 10);
        printText("     Variables: \0");
        printText(vbuffer);
        printText("Bytes\r\n\0");

        vTotal = pStartProg - pStartArrayVar;
        ltoa(vTotal, vbuffer, 10);
        printText("        Arrays: \0");
        printText(vbuffer);
        printText("Bytes\r\n\0");

        vTotal = pStartString - *nextAddrLine;
        ltoa(vTotal, vbuffer, 10);
        printText("       Program: \0");
        printText(vbuffer);
        printText("Bytes\r\n\0");
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Soma 2 numeros ou strings passados
// Syntaxe:
//      <previous token or variable> [=] <number or string> + <number or string>
//-----------------------------------------------------------------------------
char basSum(typeInf *pRetInf)
{
    unsigned char sStr1[150], sStr2[150];
    int ix = 0, iy = 0, iz, iw = 0, vToken, vReta;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];
    char vAspas = 0, parte = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    // Pega parte antes do "+"
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            sStr1[iw++] = pRetInf->tString[ix];
    }

    sStr1[iw] = 0x00;
    sStr2[0] = 0x00;

    // Pega a parte depois do "+"
    ix = 0;
    do
    {
        vToken = nextToken(&sStr2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(sStr2);
                sStr2[ix] = (unsigned char)vToken;
                sStr2[ix + 1] = 0x00;

                // analisa pra ver se é variavel, e se existe
                if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
                {
                    vReta = analiseVariable(&sStr2);
                    if (vReta < 0)
                        return vReta;
                }
            }
        }
    } while (vToken);

#ifdef __DEBUG_2__
printText("-------> Aqui 3625 - sStr1=[\0");
printText(sStr1);
printText("]\r\n\0");

printText("-------> Aqui 3625.1 - sStr2=[\0");
printText(sStr2);
printText("]\r\n\0");
#endif
    if (strchr(sStr1, 0x22))
        vAspas = 1;

    if (!vAspas)
    {
        vRes = fix16_add(fix16_from_str(sStr1), fix16_from_str(sStr2));
    }
    else
    {
        iw = strlen(sStr1);

        if (!strchr(sStr1, 0x22))
            return -1;

        if (!strchr(sStr2, 0x22))
            return -1;

        if (iw < 250)
        {
            iy = iw + strlen(sStr2);

            if (iy < 250)
                strcat(sStr1, sStr2);
            else
            {
                iy = strlen(sStr2);
                for (iz = 0; iz < iy; iz++)
                {
                    strcat(sStr1, sStr2[iz]);
                    iw++;
                    if (iw > 249)
                        break;
                }
            }
        }
    }

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    if (!vAspas)
    {
        fix16_to_str(vRes, vbuffer, 4);
        iy = strlen(vbuffer);
        for (ix = 0; ix < iy; ix++)
        {
            pRetInf->tString[ix + iw] = vbuffer[ix]; // Numero gerado
            pRetInf->tString[ix + iw + 1] = 0x00;
        }
    }
    else
    {
        pRetInf->tString[0] = 0x22;

        iy = strlen(sStr1);
        ix = iw;
        for (iz = 0; iz < iy; iz++)
        {
            if (sStr1[iz] != 0x22)
            {
                pRetInf->tString[ix++] = sStr1[iz];
                pRetInf->tString[ix] = 0x00;
            }
        }

        pRetInf->tString[ix++] = 0x22;
        pRetInf->tString[ix] = 0x00;
    }

    if (vTemParen)
    {
        pRetInf->tString[ix++] = 0x29;
        pRetInf->tString[ix] = 0x00;
    }

#ifdef __DEBUG_2__
printText("-------> Aqui 126 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif

    return 0;
}

//-----------------------------------------------------------------------------
// Subtrai 2 numeros passados
// Syntaxe:
//      <previous token or variable> [=] <number> - <number>
//-----------------------------------------------------------------------------
char basSub(typeInf *pRetInf)
{
    unsigned char sStr1[150], sStr2[150];
    int ix = 0, iy = 0, iz, iw = 0, vToken, vReta;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];
    char vAspas = 0, parte = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    // Pega parte antes do "+"
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            sStr1[iw++] = pRetInf->tString[ix];
    }

    sStr1[iw] = 0x00;
    sStr2[0] = 0x00;

    // Pega a parte depois do "+"
    ix = 0;
    do
    {
        vToken = nextToken(&sStr2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(sStr2);
                sStr2[ix] = (unsigned char)vToken;
                sStr2[ix + 1] = 0x00;

                // analisa pra ver se é variavel, e se existe
                if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
                {
                    vReta = analiseVariable(&sStr2);
                    if (vReta < 0)
                        return vReta;
                }
            }
        }
    } while (vToken);

#ifdef __DEBUG_2__
printText("-------> Aqui 3625 - sStr1=[\0");
printText(sStr1);
printText("]\r\n\0");

printText("-------> Aqui 3625.1 - sStr2=[\0");
printText(sStr2);
printText("]\r\n\0");
#endif

    vRes = fix16_sub(fix16_from_str(sStr1), fix16_from_str(sStr2));

    fix16_to_str(vRes, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;

}

//-----------------------------------------------------------------------------
// Potencia de A elevado a B
// Syntaxe:
//      <previous token or variable> [=] <number> ^ <number>
//-----------------------------------------------------------------------------
char basPow(typeInf *pRetInf)
{
    unsigned char vNum1[10], vNum2[10];
    long vRes = 0, vR1, vR2;
    unsigned char sStr1[150], sStr2[150];
    int ix = 0, iy = 0, iz, iw = 0, vToken, vReta;
    char vbuffer [sizeof(long)*8+1];
    char vAspas = 0, parte = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    // Pega parte antes do "+"
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            sStr1[iw++] = pRetInf->tString[ix];
    }

    sStr1[iw] = 0x00;
    sStr2[0] = 0x00;

    // Pega a parte depois do "+"
    ix = 0;
    do
    {
        vToken = nextToken(&sStr2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(sStr2);
                sStr2[ix] = (unsigned char)vToken;
                sStr2[ix + 1] = 0x00;

                // analisa pra ver se é variavel, e se existe
                if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
                {
                    vReta = analiseVariable(&sStr2);
                    if (vReta < 0)
                        return vReta;
                }
            }
        }
    } while (vToken);

    vR1 = fix16_from_str(vNum1);
    vRes = vR1;
    vR2 = fix16_from_str(vNum2);
    vR2 = fix16_to_int(vR2);
    vR2--;

    for(iz = 0; iz < vR2; iz++)
    {
        vRes = fix16_mul(vRes, vR1);

        if (vRes == fix16_overflow)
            return -2;
    }

    fix16_to_str(vRes, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Multiplica 2 numeros passados
// Syntaxe:
//      <previous token or variable> [=] <number> * <number>
//-----------------------------------------------------------------------------
char basMul(typeInf *pRetInf)
{
    unsigned char sStr1[150], sStr2[150];
    int ix = 0, iy = 0, iz, iw = 0, vToken, vReta;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];
    char vAspas = 0, parte = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    // Pega parte antes do "+"
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            sStr1[iw++] = pRetInf->tString[ix];
    }

    sStr1[iw] = 0x00;
    sStr2[0] = 0x00;

    // Pega a parte depois do "+"
    ix = 0;
    do
    {
        vToken = nextToken(&sStr2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(sStr2);
                sStr2[ix] = (unsigned char)vToken;
                sStr2[ix + 1] = 0x00;

                // analisa pra ver se é variavel, e se existe
                if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
                {
                    vReta = analiseVariable(&sStr2);
                    if (vReta < 0)
                        return vReta;
                }
            }
        }
    } while (vToken);

#ifdef __DEBUG_2__
printText("-------> Aqui 3625 - sStr1=[\0");
printText(sStr1);
printText("]\r\n\0");

printText("-------> Aqui 3625.1 - sStr2=[\0");
printText(sStr2);
printText("]\r\n\0");
#endif

    vRes = fix16_mul(fix16_from_str(sStr1), fix16_from_str(sStr2));

    if (vRes == fix16_overflow)
        return -2;

    fix16_to_str(vRes, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Divide 2 numeros passados
// Syntaxe:
//      <previous token or variable> [=] <number> / <number>
//-----------------------------------------------------------------------------
char basDiv(typeInf *pRetInf)
{
    unsigned char sStr1[150], sStr2[150];
    int ix = 0, iy = 0, iz, iw = 0, vToken, vReta;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];
    char vAspas = 0, parte = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    // Pega parte antes do "+"
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            sStr1[iw++] = pRetInf->tString[ix];
    }

    sStr1[iw] = 0x00;
    sStr2[0] = 0x00;

    // Pega a parte depois do "+"
    ix = 0;
    do
    {
        vToken = nextToken(&sStr2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(sStr2);
                sStr2[ix] = (unsigned char)vToken;
                sStr2[ix + 1] = 0x00;

                // analisa pra ver se é variavel, e se existe
                if (!*vInicioSentenca && (vToken == '$' || vToken == '%' || vToken == '#'))
                {
                    vReta = analiseVariable(&sStr2);
                    if (vReta < 0)
                        return vReta;
                }
            }
        }
    } while (vToken);

#ifdef __DEBUG_2__
printText("-------> Aqui 3625 - sStr1=[\0");
printText(sStr1);
printText("]\r\n\0");

printText("-------> Aqui 3625.1 - sStr2=[\0");
printText(sStr2);
printText("]\r\n\0");
#endif

    vRes = fix16_div(fix16_from_str(sStr1), fix16_from_str(sStr2));

    if (vRes == fix16_overflow)
        return -2;

    fix16_to_str(vRes, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Raiz Quadrada Numero
// Syntaxe:
//      SQRT(<Number>)
//-----------------------------------------------------------------------------
long basSqrt(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca)
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    ix = 0;
    iy = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = fix16_sqrt(fix16_from_str(vAscii));

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    if (vNum == fix16_overflow)
        return -2;

    fix16_to_str(vNum, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Seno Numero
// Syntaxe:
//      SQRT(<Number>)
//-----------------------------------------------------------------------------
long basSin(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca)
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    ix = 0;
    iy = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = fix16_sin(fix16_from_str(vAscii));

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    if (vNum == fix16_overflow)
        return -2;

    fix16_to_str(vNum, vbuffer, 4);

    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Coseno Numero
// Syntaxe:
//      COS(<Number>)
//-----------------------------------------------------------------------------
long basCos(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca)
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    ix = 0;
    iy = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = fix16_cos(fix16_from_str(vAscii));

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    if (vNum == fix16_overflow)
        return -2;

    fix16_to_str(vNum, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Tangente Angulo
// Syntaxe:
//      TAN(<Number>)
//-----------------------------------------------------------------------------
long basTan(typeInf *pRetInf)
{
    unsigned char vAscii[50], vTemp[50];
    int ix = 0, iy = 0, iz, iw, vToken = 0, vReta;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];
    char vTemParen = 0;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vTemp[0] = 0x00;
    vAscii[0] = 0x00;

    ix = 0;
    do
    {
        vToken = nextToken(&vTemp);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix] = (unsigned char)vToken;
            vTemp[ix + 1] = 0x00;

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca)
            {
                vReta = analiseVariable(&vTemp);
                if (vReta < 0)
                    return vReta;
            }

            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
        }
    } while (vToken);

    // Erro, nao veio nada
    if (vTemp[0] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (vTemp[0] != 0x28)
        return -1;

    ix = 0;
    iy = 0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (vTemp[ix] == 0x00)
            return -1;

        // Abertura de parenteses, nao usa
        if (vTemp[ix] == 0x28)
        {
            ix++;
            continue;
        }

        // Achou o parenteses final
        if (vTemp[ix] == 0x29)
        {
            vNum = fix16_tan(fix16_from_str(vAscii));

            break;
        }

        vAscii[iy++] = vTemp[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    iw = 0;
    if (vTemParen)
    {
        pRetInf->tString[0] = 0x28; // (
        iw = 1;
    }

    if (vNum == fix16_overflow)
        return -2;

    fix16_to_str(vNum, vbuffer, 4);
    iy = strlen(vbuffer);
    for (ix = 0; ix < iy; ix++)
    {
        pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
        pRetInf->tString[ix + 1] = 0x00;
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Igualar para atribuir or comparar
// Syntaxe:
//      Atribuir: <variable> = <variable or value>
//                      OR
//      Comparacao: <variable or value> = <variable or value>
//
//      Retorno: n - Comparacao Errada, y - Comparacao OK, 2 - Variavel nova, -1 - Erro
//--------------------------------------------------------------------------------------
char basEqual(typeInf *pRetInf)
{
    unsigned char vNum1[128], vNum2[128], vNomVar[2], vTypeVar;
    int ix = 0, iy = 0, iw, iz, vToken, vReta;
    char vRes = '\0';
    char vbuffer [sizeof(long)*8+1];
    char vRetFV = 0;
    long vResNum1 = 0, vResNum2 = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    // Pega parte antes do "="
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            vNum1[iw++] = pRetInf->tString[ix];
    }

    vNum1[iw] = 0x00;

#ifdef __DEBUG_6__
printText("-------> Aqui 39.21 - vNum1=[\0");
printText(vNum1);
printText("]\r\n\0");
#endif

    // Pega a parte depois do "="
    ix = 0;
    do
    {
        vToken = nextToken(&vNum2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(vNum2);
                vNum2[ix++] = (unsigned char)vToken;
                vNum2[ix] = 0x00;
            }

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca)
            {
                vReta = analiseVariable(&vNum2);
                if (vReta < 0)
                    return vReta;
            }
        }
    } while (vToken);

    // Analisa e ve o que fazer;
    vNomVar[0] = vNum1[0]; vNomVar[1] = vNum1[1];
    iz = strlen(vNum1) - 1;
    vTypeVar = vNum1[iz];

#ifdef __DEBUG_6__
printText("-------> Aqui 39.33 - vNum1=[\0");
printText(vNum1);
printText("]\r\n\0");

printText("-------> Aqui 39.34 - vNum2=[\0");
printText(vNum2);
printText("]\r\n\0");
#endif

#ifdef __DEBUG_6__
itoa(*vInicioSentenca, vbuffer, 16);
printText("-------> Aqui 39.35 - *vInicioSentenca=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    // se criação, primeira letra tem que ser uma letra e a segunda tem que existir
    if (*vInicioSentenca)
    {
        if (vNum1[0] < 0x41 || vNum1[1] < 0x30)
            return -1;
    }

    // Se for uma variavel, procura, se nao, retorna 1 indicando que é outra coisa, um numero
    if (vNum1[0] >= 0x41)
        vRetFV = findVariable(vNum1);
    else
        vRetFV = 1;

    if (vRetFV < 0)
        return vRetFV;

    // Se nao existe variavel e nao inicio sentenca, erro
    if (!vRetFV && !*vInicioSentenca)
    {
        return -5;
    }

    iz = strlen(pRetInf->tString) - 1;
    // Se nao existe variavel e inicio sentenca, cria variavel e atribui o valor
    if (!vRetFV && *vInicioSentenca)
    {
        createVariable(vNum1, vNum2, pRetInf->tString[iz]);
    }

    // Se existe variavel e inicio sentenca, altera variavel atribuindo o valor
    if (vRetFV && *vInicioSentenca)
    {
        updateVariable(vNum1, vNum2, pRetInf->tString[iz], 1);
    }

#ifdef __DEBUG_6__
printText("-------> Aqui 39.23 - vNum1=[\0");
printText(vNum1);
printText("]\r\n\0");

printText("-------> Aqui 39.24 - vNum2=[\0");
printText(vNum2);
printText("]\r\n\0");
#endif

    // Se existe variavel e nao eh inicio sentenca, compara valores
    if (vRetFV && !*vInicioSentenca)
    {
        if (vNum1[0] == 0x22 && vNum2[0] != 0x22)
            return -1;

        if (vNum1[0] != 0x22 && vNum2[0] == 0x22)
            return -1;

        // Verifica se é valor, se for, converte pra valor em c
        if (vNum1[0] != 0x22 && vNum2[0] != 0x22)
        {
            vResNum1 = fix16_from_str(vNum1);
            vResNum2 = fix16_from_str(vNum2);

            if (vResNum1 == vResNum2)
                vRes = '1';
            else
                vRes = '0';
        }
        else
        {
            // Se for string, compara
            iz = strlen(vNum1);
            if (strncmp(vNum1, vNum2, iz) == 0)
                vRes = '1';
            else
                vRes = '0';
        }
    }

    pRetInf->tString[0] = vRes;
    pRetInf->tString[1] = 0x00;

    return 0;
}

//--------------------------------------------------------------------------------------
// Comparar:
//       > : um Valor maior q a outra
//       < : um Valor menor q a outra
//       >= : um Valor maior ou igual q a outra
//       <= : um Valor menor ou igual q a outra
//       <> : um Valor diferente q a outra
// Syntaxe:
//      Comparacao: <variable or value> > <variable or value>
//      Comparacao: <variable or value> < <variable or value>
//      Comparacao: <variable or value> >= <variable or value>
//      Comparacao: <variable or value> <= <variable or value>
//      Comparacao: <variable or value> <> <variable or value>
//
//      Retorno: n - Comparacao Errada, y - Comparacao OK
//--------------------------------------------------------------------------------------
char basCompare(typeInf *pRetInf, unsigned char pToken)
{
    unsigned char vNum1[128], vNum2[128], vNomVar[2], vTypeVar;
    int ix = 0, iy = 0, iw, iz, vToken, vReta;
    char vRes = '\0';
    char vbuffer [sizeof(long)*8+1];
    char vRetFV = 0;
    long vResNum1 = 0, vResNum2 = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    // Pega parte antes do "="
    iz = strlen(pRetInf->tString);
    iw = 0;
    for (ix = 0; ix < iz; ix++)
    {
        if (pRetInf->tString[ix] != 0x28)
            vNum1[iw++] = pRetInf->tString[ix];
    }

    vNum1[iw] = 0x00;

    // Pega a parte depois do "="
    ix = 0;
    do
    {
        vToken = nextToken(&vNum2);

        if (vToken < 0)
            return -1;

        if (vToken > 0)
        {
            if (vToken == 0x29)
            {
                if (*vParenteses)
                {
                    *vParenteses = *vParenteses - 1;
                    break;
                }
                else
                    return -1;
            }
            else
            {
                ix = strlen(vNum2);
                vNum2[ix++] = (unsigned char)vToken;
                vNum2[ix] = 0x00;
            }

            // analisa pra ver se é variavel, e se existe
            if (!*vInicioSentenca)
            {
                vReta = analiseVariable(&vNum2);
                if (vReta < 0)
                    return vReta;
            }
        }
    } while (vToken);

    // Analisa e ve o que fazer;
    vNomVar[0] = vNum1[0]; vNomVar[1] = vNum1[1];
    iz = strlen(vNum1) - 1;
    vTypeVar = vNum1[iz];

    // se criação, primeira letra tem que ser uma letra e a segunda tem que existir
    if (*vInicioSentenca)
    {
        if (vNum1[0] < 0x41 || vNum1[1] < 0x30)
            return -1;
    }

    // Se for uma variavel, procura, se nao, retorna 1 indicando que é outra coisa, um numero
    if (vNum1[0] >= 0x41)
        vRetFV = findVariable(vNum1);
    else
        vRetFV = 1;

    if (vRetFV < 0)
        return vRetFV;

    // Se nao existe variavel e nao inicio sentenca, erro
    if (!vRetFV && !*vInicioSentenca)
    {
        return -5;
    }

    // Se existe variavel e nao eh inicio sentenca, compara valores
    if (vRetFV && !*vInicioSentenca)
    {
        if (vNum1[0] == 0x22 && vNum2[0] != 0x22)
            return -1;

        if (vNum1[0] != 0x22 && vNum2[0] == 0x22)
            return -1;

        // Verifica se é valor, se for, converte pra valor em c
        if (vNum1[0] != 0x22 && vNum2[0] != 0x22)
        {
            vResNum1 = fix16_from_str(vNum1);
            vResNum2 = fix16_from_str(vNum2);

            vRes = '0';

            switch (pToken)
            {
                case 0xF5:
                    if (vResNum1 >= vResNum2)
                        vRes = '1';
                    break;
                case 0xF6:
                    if (vResNum1 <= vResNum2)
                        vRes = '1';
                    break;
                case 0xF7:
                    if (vResNum1 != vResNum2)
                        vRes = '1';
                    break;
                case 0xF8:
                    if (vResNum1 < vResNum2)
                        vRes = '1';
                    break;
                case 0xFA:
                    if (vResNum1 > vResNum2)
                        vRes = '1';
                    break;
            }
        }
        else
        {
            // Se for string, compara
            iz = strlen(vNum1);

            vRes = '0';

            switch (pToken)
            {
                case 0xF5:
                    if (strncmp(vNum1, vNum2, iz) >= 0)
                        vRes = '1';
                    break;
                case 0xF6:
                    if (strncmp(vNum1, vNum2, iz) <= 0)
                        vRes = '1';
                    break;
                case 0xF7:
                    if (strncmp(vNum1, vNum2, iz) != 0)
                        vRes = '1';
                    break;
                case 0xF8:
                    if (strncmp(vNum1, vNum2, iz) < 0)
                        vRes = '1';
                    break;
                case 0xFA:
                    if (strncmp(vNum1, vNum2, iz) > 0)
                        vRes = '1';
                    break;
            }
        }
    }

    pRetInf->tString[0] = vRes;
    pRetInf->tString[1] = 0x00;

    return 0;
}

//--------------------------------------------------------------------------------------
// Comparar 2 condiçoes com com o logico "E"
// Syntaxe:
//            <condicao> AND <condicao>
//
//      Retorno: n - Sem sucesso, y - Sucesso
//--------------------------------------------------------------------------------------
char basAnd(typeInf *pRetInf)
{
    unsigned char vNum1[10], vNum2[10];
    int ix = 0, iy = 0, iz, vParte = 0, vToken;
    char vRes = '\0';
    char vRetFV = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    // Pega parte antes do "="
    iz = strlen(pRetInf->tString);
    for (ix = 0; ix < iz; ix++)
        vNum1[ix] = pRetInf->tString[ix];

    vNum1[iz] = 0x00;

    // Pega a parte depois do "="
    ix = 0;
    do
    {
        vToken = nextToken(&vNum2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vNum2);
            vNum2[ix] = (unsigned char)vToken;
            vNum2[ix + 1] = 0x00;
        }
    } while (vToken);


#ifdef __DEBUG_6__
printText("-------> Aqui 36.23 - vNum1=[\0");
printText(vNum1);
printText("]\r\n\0");

printText("-------> Aqui 36.24 - vNum2=[\0");
printText(vNum2);
printText("]\r\n\0");
#endif

    vRes = '0';

    if (vNum1[0] == '1' && vNum2[0] == '1')
        vRes = '1';

    ix = 0;
    if (vTemParen)
        pRetInf->tString[ix++] = 0x28; // (

    pRetInf->tString[ix++] = vRes;
    pRetInf->tString[ix++] = 0x00;

    return 0;
}

//--------------------------------------------------------------------------------------
// Comparar 2 condiçoes com com o logico "OU"
// Syntaxe:
//            <condicao> OR <condicao>
//
//      Retorno: n - Sem sucesso, y - Sucesso
//--------------------------------------------------------------------------------------
char basOr(typeInf *pRetInf)
{
    unsigned char vNum1[10], vNum2[10];
    int ix = 0, iy = 0, iz, vParte = 0, vToken;
    char vRes = '\0';
    char vRetFV = 0;
    char vTemParen = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    if (pRetInf->tString[0] == '(')
        vTemParen = 1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    // Pega parte antes do "="
    iz = strlen(pRetInf->tString);
    for (ix = 0; ix < iz; ix++)
        vNum1[ix] = pRetInf->tString[ix];

    vNum1[iz] = 0x00;

    // Pega a parte depois do "="
    ix = 0;
    do
    {
        vToken = nextToken(&vNum2);

        if (vToken < 0)
            return -1;

        if (vToken > 0 && vToken < 0x80)
        {
            ix = strlen(vNum2);
            vNum2[ix] = (unsigned char)vToken;
            vNum2[ix + 1] = 0x00;
        }
    } while (vToken);

#ifdef __DEBUG_6__
printText("-------> Aqui 36.23 - vNum1=[\0");
printText(vNum1);
printText("]\r\n\0");

printText("-------> Aqui 36.24 - vNum2=[\0");
printText(vNum2);
printText("]\r\n\0");
#endif

    vRes = '0';

    if (vNum1[0] == '1' || vNum2[0] == '1')
        vRes = '1';


    ix = 0;
    if (vTemParen)
        pRetInf->tString[ix++] = 0x28; // (

    pRetInf->tString[0] = vRes;
    pRetInf->tString[1] = 0x00;

    return 0;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
char basIf(typeInf *pRetInf)
{
    unsigned char vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    int vReta;
    char uSouThen = 0;

    pRetInf->tString[0] = 0x00;
    vTemp[0] = 0x00;

    *vTemIf = 1;

    // Pega a parte depois do comando
    do
    {
        vToken = nextToken(&vTemp);

#ifdef __DEBUG_8__
itoa(vToken, sNumLin, 16);
printText("-------> Aqui 32.23 - vToken=[\0");
printText(sNumLin);
printText("]\r\n\0");

itoa(uSouThen, sNumLin, 16);
printText("-------> Aqui 32.25 - uSouThen=[\0");
printText(sNumLin);
printText("]\r\n\0");
#endif

        if (vToken < 0)
            return -1;
#ifdef __DEBUG_8__
printText("-------> Aqui 32.26 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
        if (vToken < 0x80)
        {
            ix = strlen(vTemp);
            vTemp[ix++] = (unsigned char)vToken;
            vTemp[ix] = 0x00;
        }
#ifdef __DEBUG_8__
printText("-------> Aqui 32.27 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
        // Se for then, analisa resultado final
        if (*vTemThen && !*vTemElse)
        {
#ifdef __DEBUG_8__
printText("-------> Aqui 32.57 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
            // se o retorno das condicoes for 1 procura pelo "then" continuando com o processo, senao procura pelo "else"
            if (vTemp[0] == '1')
            {
                uSouThen = 1;
            }
            else
            {
#ifdef __DEBUG_8__
printText("-------> Aqui 32.59 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
                // leva o ponteiro da leitura da linha até onde esta o "else"
                do
                {
                    vToken = *pointerRunProg++;
                    if (vToken == 0x84)
                    {
                        break;
                    }
                } while (vToken);
            }
        }
        else if (*vTemElse && uSouThen)
        {
#ifdef __DEBUG_8__
printText("-------> Aqui 32.58 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
            while (*pointerRunProg++);

            break;
        }
    } while (vToken);

    *doisPontos = 0;

    return 0;
}

//--------------------------------------------------------------------------------------
// Atribuir valor a uma variavel - comando opcional.
// Syntaxe:
//            [LET] <variavel> = <string/valor>
//--------------------------------------------------------------------------------------
char basLet(typeInf *pRetInf)
{
    int vToken = 0, vReta;
    int ix = 0;
    typeInf vRetInf;
    char vbuffer [sizeof(long)*8+1];

#ifdef __DEBUG__
printText("-------> Aqui 866.01 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif

    // So vale a atribuicao se estiver no inicio da linha (ou depois de um ":")
    if (!*vInicioSentenca)
        return -1;
    else
        *vInicioSentenca = 2;

#ifdef __DEBUG__
itoa(*pointerRunProg, vbuffer, 16);
printText("-------> Aqui 866.22 - *pointerRunProg=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    do
    {
        // Ler proximo caracter/token da linha
        vToken = nextToken(&vRetInf);

#ifdef __DEBUG__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 394.15 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

        if (vToken < 0)
            return -1;

        if (vToken >= 0x80 && *doisPontos)
            ix = 0;

        // Indica Retorno de algum tipo de valor na variavel vRetInf
        if (vToken < 0x80)
        {
            // Primeiro caracter da variavel deve ser obrigatoriamente uma letra
            if (ix == 0 && vToken < 0x41)
                return -1;

            // Armazena tokens recebidos
            vRetInf.tString[ix++] = (unsigned char)vToken;
            vRetInf.tString[ix] = 0x00;

#ifdef __DEBUG__
printText("-------> Aqui 866.11 - vRetInf.tString=[");
printText(vRetInf.tString);
printText("]\r\n\0");
#endif
        }

    } while (vToken);

    return 0;
}

//--------------------------------------------------------------------------------------
// Entrada pelo teclado de numeros/caracteres ateh teclar ENTER (INPUT)
// Entrada pelo teclado de um unico caracter ou numero (GET)
// Syntaxe:
//          INPUT ["texto";]<variavel> : A variavel sera criada se nao existir
//          GET <variavel> : A variavel sera criada se nao existir
//--------------------------------------------------------------------------------------
char basInputGet(typeInf *pRetInf, unsigned char pSize)
{
    int vToken = 0, vReta;
    int ix = 0, iz = 0;
    typeInf vRetInf;
    char vbuffer [sizeof(long)*8+1];
    int vRetFV;
    unsigned char *buffptr = vbuf;
    unsigned char vNum1[128], vNum2[128], vtec;

#ifdef __DEBUG__
printText("-------> Aqui 866.01 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif

    do
    {
        // Ler proximo caracter/token da linha
        vToken = nextToken(&vRetInf);

#ifdef __DEBUG__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 394.15 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

        if (vToken < 0)
            return -1;

        if (vToken >= 0x80 && *doisPontos)
            ix = 0;

        // Indica Retorno de algum tipo de valor na variavel vRetInf
        if (vToken < 0x80)
        {
            // Primeiro caracter da variavel deve ser obrigatoriamente uma letra
            if (ix == 0 && vToken < 0x41)
                return -1;

            // Armazena tokens recebidos
            vRetInf.tString[ix++] = (unsigned char)vToken;
            vRetInf.tString[ix] = 0x00;

#ifdef __DEBUG__
printText("-------> Aqui 866.11 - vRetInf.tString=[");
printText(vRetInf.tString);
printText("]\r\n\0");
#endif
        }

    } while (vToken);

    if (pSize == 1)
    {
        // GET
        vtec = 0;
        while (!vtec)
        {
            readChar();

            vtec = *vBufReceived;
        }

        vNum2[0] = vtec;
        vNum2[1] = 0x00;

        strcpy(vNum1, vRetInf.tString);
    }
    else
    {
        // INPUT
        vtec = inputLine(255);

        if (*vbuf != 0x00 && (vtec == 0x0D || vtec == 0x0A))
        {
            printText("\r\n\0");
            
            ix = 0;

            while (*buffptr)
            {
                vNum2[ix++] = *buffptr++;
                vNum2[ix] = 0x00;
            }
        }
        else
            vNum2[0] = 0x00;

        strcpy(vNum1, vRetInf.tString);
    }

    iz = strlen(vNum1) - 1;

    // Se for uma variavel, procura, se nao, retorna 1 indicando que é outra coisa, um numero
    if (vNum1[0] >= 0x41)
        vRetFV = findVariable(vNum1);
    else
        vRetFV = 1;

    if (vRetFV < 0)
        return vRetFV;

    // Se nao existe variavel, cria variavel e atribui o valor
    if (!vRetFV)
    {
        createVariable(vNum1, vNum2, pRetInf->tString[iz]);
    }
    else
    {
        // Se existe variavel, altera variavel atribuindo o valor
        updateVariable(vNum1, vNum2, pRetInf->tString[iz], 1);
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Inicio do laço de repeticao
// Syntaxe:
//          FOR <variavel> = <inicio> TO <final> [STEP <passo>] : A variavel sera criada se nao existir
//--------------------------------------------------------------------------------------
char basFor(typeInf *pRetInf)
{

    return 0;
}

//--------------------------------------------------------------------------------------
// Final/Incremento do Laço de repeticao, voltando para o commando/linha após o FOR
// Syntaxe:
//          NEXT [<variavel>]
//--------------------------------------------------------------------------------------
char basNext(typeInf *pRetInf)
{

    return 0;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int nextToken(typeInf *pRetInf)
{
    unsigned char vToken;
    int vReta = 0;
#ifdef __DEBUG_8__
    char vbuffer [sizeof(long)*8+1];
#endif

    // Se nao foi comando de atribuir variavel, coloca como nao é mais inicio sentenca
    if (*vInicioSentenca == 1)
        *vInicioSentenca = 0;

    // analisa pra ver se é variavel, e se existe
    // *********************************************************
    // *** RETIRADO POIS ESTAVA DANDO ERRO DE TRAVADA OU RESET
    // *** QUANDO A VARIAVEL FICAVA DEPOIS DO TOKEN TIPO +*/- .
    // *** FOI COLOCADO DENTRO DAS FUNCOES, DEPOIS DE CHAMAR O
    // *** NEXTTOKEN - ERRO PROVAVELMENTE GERADO DO COMPILADOR
    // *********************************************************
/*    if (!*vInicioSentenca)
    {
        vReta = analiseVariable(pRetInf);
        if (vReta < 0)
            return vReta;
    }*/
    // *********************************************************
    // *********************************************************
    // *********************************************************
    // *********************************************************

    // Pega proximo caracter
    vToken = *pointerRunProg++;

    // Se for 0, retorna 0 mas volta 1 pra ser pego depois
    if (!vToken)
    {
        *pointerRunProg--;
        return 0;
    }

    // Se for AND ou OR, volta 1 pra completar a condição anterior e ja enviar pro proximo AND ou OR
    if (!*vTemAndOr && (vToken == 0xF3 || vToken == 0xF4))
    {
        *pointerRunProg--;
        *vTemAndOr = 0x01;
        *vTemIfAndOr = 0x01;
        return 0;
    }
    else
        *vTemAndOr = 0x00;

    // Se for Then ou Else e tem And ou OR, volta 1 pra completar a condição anterior e ja enviar pro proximo AND ou OR
    if (!*vTemThen && !*vTemElse && *vTemIfAndOr && (vToken == 0x83 || vToken == 0x84))
    {
        *pointerRunProg--;
        *vTemIfAndOr = 0;
        return 0;
    }

    if (vToken == 0x28)
        *vParenteses = *vParenteses + 1;

#ifdef __DEBUG_8__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 394.12 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    // Verifica se chegou no ":", para iniciar nova linha
    vReta = endSentence(vToken);
    if (vReta)
        vToken = 0x00;

#ifdef __DEBUG_8__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 394.34 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    // Se for um token, chama a funcao correspondente passando o que ja tem na variavel
    if (vToken >= 0x80 && vToken != 0x83 && vToken != 0x84) // Nao chama se for Then ou Else
    {
        vReta = executeToken(vToken, pRetInf);

#ifdef __DEBUG_8__
itoa(vReta, vbuffer, 10);
printText("-------> Aqui 394.13 - vReta=[\0");
printText(vbuffer);
printText("]\r\n\0");

printText("-------> Aqui 394.17 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif

        if (vReta < 0)
            vToken = vReta;
    }

#ifdef __DEBUG_8__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 394.16 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    return vToken;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int analiseVariable(typeInf *pRetInf)
{
    unsigned char vToken, vTemp[250];
    int iyy, iw, iz = 0;
    int vReta = 0;

    if (pRetInf->tString[0] == 0x28)
        iz = 1;

    vTemp[0] = 0x00;
    vTemp[1] = 0x00;
    vTemp[2] = 0x00;

    vToken = pRetInf->tString[2 + iz];

    if (vToken == '$' || vToken == '#' || vToken == '%')
    {
        iyy = strlen(pRetInf->tString);
        for (iw = 0; iw < iyy; iw++)
        {
            vTemp[iw] = pRetInf->tString[iw + iz];
            vTemp[iw + 1] = 0x00;
        }

#ifdef __DEBUG__
printText("-------> Aqui 3942.12 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif
        if (!findVariable(&vTemp))
            return -5;
#ifdef __DEBUG__
printText("-------> Aqui 3942.12 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");
#endif

        iyy = strlen(vTemp);
        if (iz)
            pRetInf->tString[0] = '(';

        for (iw = 0; iw < iyy; iw++)
        {
            pRetInf->tString[iw + iz] = vTemp[iw];
            pRetInf->tString[iw + iz + 1] = 0x00;
            pRetInf->tType = 0;
        }

#ifdef __DEBUG__
printText("-------> Aqui 3942.12 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif
        vReta = 1;
    }

    return vReta;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int endSentence(unsigned char pToken)
{
    int vReta = 0;

    switch (pToken)
    {
        case 0x83:  // then
        case 0x84:  // else
            if (pToken == 0x83)
                *vTemThen = 1;

            if (pToken == 0x84)
                *vTemElse = 1;

            vReta = 1;
            break;
        case ':':
            *doisPontos = 1;

            if (*vInicioSentenca != 2)
                *vInicioSentenca = 1;

            vReta = 1;
            break;
    }

    return vReta;
}