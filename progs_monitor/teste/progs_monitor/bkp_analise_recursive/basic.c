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

//-----------------------------------------------------------------------------
// Principal
//-----------------------------------------------------------------------------
void main(void)
{
    unsigned char *vbufptr = vbuf;
    unsigned char vtec, vtecant;

    clearScr();
    printText("MMSJ-BASIC v0.3\r\n\0");
    printText("(c) 2022 Utility Inf. Ltda\r\n\0");
    printText("READY\r\n\0");
    printText(">\0");

    *vBufReceived = 0x00;
    *vbuf = '\0';
    vtecant = 0x00;
    *pProcess = 0x01;
    *pTypeLine = 0x00;
    *nextAddrLine = pStartProg;
    *firstLineNumber = 0;
    *addrFirstLineNumber = 0;

    while (*pProcess)
    {
        *vBufReceived = 0x00;

        readChar();

        vtec = *vBufReceived;

        if (vtec)
        {
            // Prevenir sujeira no buffer ou repetição
            if (vtec == vtecant)
                continue;

            vtecant = vtec;

            if (vtec >= 0x20)
            {
                // Limite 32 bytes na linha digitada
                if (vbufptr > vbuf + 511)
                {
                    *vbufptr--;
                    printChar('\b');
                }

                printChar(vtec);

                *vbufptr++ = vtec;
                *vbufptr = '\0';
            }
            else if (vtec == '\b')
            {
                if (vbufptr > vbuf)
                {
                    *vbufptr--;
                    printChar('\b');
                    printChar(' ');
                    printChar('\b');
                }
            }
            else if (vtec == '\r' || vtec == '\n' )
            {
                *pTypeLine = 0x00;

                if (*vbuf != 0x00)
                {
                    printText("\r\n\0");

                    processLine();

                    if (!*pTypeLine && *pProcess)
                        printText("\r\nREADY\0");

                    *vBufReceived = 0x00;
                    *vbuf = '\0';
                    vbufptr = vbuf;
                }

                if (!*pTypeLine && *pProcess)
                    printText("\r\n>\0");
                else if (*pTypeLine)
                    printText(">\0");
            }
        }
        else
        {
            vtecant = 0x00;
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
    char vReta, vSpace = 0;
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
                *vInicioSentenca = 1;
                *vMaisTokens = 0;
                *vParenteses = 0x00;
                *vTemIf = 0x00;
                vReta = analiseLine(&comandLineTokenized, 0, &vRetInf);
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
    unsigned short ix, iy, kt, iz;
    unsigned char vToken, vLinhaArg[255], vparam2[16], vpicret;

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

		if (!vAspas && strchr(operandsWithTokens, *blin))
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
        if ((!vAspas && (*blin == 0x20 /* space */ || *blin == 0x28 /* ( */ || *blin == 0x29 /* ) */ )) || !*blin)
        {
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
					if (iz == 1)
					{
						// Compara pra ver se é um token caracter unico
						for(kt = 0; kt < keywordsUnique_count; kt++)
						{
							if(keywordsUnique[kt].keyword == vLidoCaps)
								vToken = keywordsUnique[kt].token;
						}
					}
					else
					{
						// Compara pra ver se é um token
						for(kt = 0; kt < keywords_count; kt++)
						{
							iz = strlen(keywords[kt].keyword);
							if(strncmp(vLidoCaps, keywords[kt].keyword, iz) == 0)
								vToken = keywords[kt].token;
						}
                    }
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

                    if (*blin)
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
    char vReta;
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
            *vInicioSentenca = 1;
            *vMaisTokens = 0;
            *vParenteses = 0x00;
            *vTemIf = 0x00;
            vRetInf.tString[0] = 0x00;

            vReta = analiseLine(&vStartList, 0, &vRetInf);

            if (vReta < 0)
            {
#ifdef __DEBUG__
/*ltoa(vReta, vbuffer, 16);
printText("-------> Aqui 000 - vReta=[\0");
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
char executeToken(unsigned char **pStartList, unsigned char pToken, typeInf *pRetInf)
{
    char vReta;
    char vbuffer [sizeof(long)*8+1];
//    typeInf vRetInf;

    if (pToken < 0xF0 && *vInicioSentenca == 1)
        *vInicioSentenca = 0;
    else if (pToken == 0xF9 && *vInicioSentenca == 1)   // se for = ja na primeira sentença
        *vInicioSentenca = 2;

    if (pToken != 0xF9)
        *vMaisTokens = 1;

#ifdef __DEBUG__
ltoa(pToken, vbuffer, 16);
printText("-------> Aqui 95 - pToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(*vInicioSentenca, vbuffer, 16);
printText("-------> Aqui 95.1 - *vInicioSentenca=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

    vReta = analiseLine(pStartList, pToken, pRetInf);

    if (vReta >= 0)
    {
        switch (pToken)
        {
            case 0x80:  // Let
                // Nada a fazer, comando opicional
                break;
            case 0x81:  // Print
                vReta = basPrint(pRetInf);
                break;
            case 0x82:  // IF
                vReta = basIf(pRetInf);
                break;
            case 0x83:  // Then
                vReta = basThenElse(pRetInf);
                break;
            case 0x84:  // Else
                vReta = basThenElse(pRetInf);
                break;
            case 0x97:  // Clear
                clearScr();
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
                vReta = -1;
        }
    }

    return vReta;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
char analiseLine(unsigned char **pStartList, unsigned char pToken, typeInf *pRetInf)
{
    int ix, iy, iz, iw, ixx, iyy, izz, ixant = 0, iToken = 0;
    unsigned char vToken, vTipoRet;
    char vReta = 0, vAspas = 0, vTemp[255];
    char vbuffer [sizeof(long)*8+1];
    typeInf vRetInf;
	char vPrioridade = 0, vFirstArit = 0;
    char vPRetInfJustFilled = 0;
    char vParTemp = 0x00, vRespIf = 0x00;

    ix = 0;

    vRetInf.tString[0] = 0x00;
    vTemp[0] = 0x00;
    vTemp[1] = 0x00;
    vTemp[2] = 0x00;

#ifdef __DEBUG__
printText("-------> Aqui 005 - vRetInf.tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");

itoa(*vParenteses, vbuffer, 10);
printText("-------> Aqui 005.1 - *vParenteses=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

#ifdef __DEBUG__
/*ltoa(*pStartList, vbuffer, 16);
printText("-------> Aqui 95 - \0");
printText(vbuffer);
printText("\r\n\0");*/
#endif

    // Verifica se é token de Operações 1 char
    if (pToken > 0)
        iToken = findToken(pToken);

    if (pToken >= 0xF0 && iToken > -1)
    {
        if (pToken < 0xFE && pToken != 0xF9)  // Se nao é "+", "-" ou "="
            vPrioridade = 1;

        strcpy(vRetInf.tString, pRetInf->tString);
        pRetInf->tString[0] = 0x00;

#ifdef __DEBUG__
printText("-------> Aqui 006 - vRetInf.tString=[\0");
printText(vRetInf.tString);
printText("]\r\n\0");
#endif

        iy = strlen(vRetInf.tString);
        for(iw = 0; iw < iy; iw++)
        {
            if (vRetInf.tString[iw] == '(' || vRetInf.tString[iw] == ')')
                continue;

            pRetInf->tString[ix++] = vRetInf.tString[iw];
            pRetInf->tString[ix] = ',';
            pRetInf->tString[ix + 1] = 0x00;
        }

        if (iy > 0)
            ix++;
    }

    ixx = 0;

#ifdef __DEBUG__
printText("-------> Aqui 000 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif

    while (*(*pStartList))
    {
        vToken = *(*pStartList);
#ifdef __DEBUG__
/*itoa(vToken, vbuffer, 16);
printText("-------> Aqui 96.1 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif

        (*pStartList)++;

        // Verifica se deve usar o Then ou o Else
        if (vToken == 0x83 && *vTemIf)
        {
            if (pRetInf->tString[0] == "(")
                vRespIf = pRetInf->tString[1];
            else
                vRespIf = pRetInf->tString[0];

            // Se for "n" procura o else, senao, continua
            if (vRespIf == 'n')
            {
                // loop ateh achar o else
                while (vToken != 0x84 && vToken != 0x00)
                {
                    vToken = *(*pStartList);
                    (*pStartList)++;
                }
            }
            else
                *vTemIf = 0;
        }

        // Verifica se é token
        if (vToken >= 0x80)
        {
            // Se for IF, indica que tem um IF envolvido
            if (vToken == 0x82)
                *vTemIf = 1;

            // Se achou else e ja usou no then, sai fora
            if (vToken == 0x84 && !*vTemIf)
                break;

            // Procura token na lista
            iy = findToken(vToken);

            if (iy > -1)
            {
                // Executa Token
#ifdef __DEBUG__
ltoa(*pStartList, vbuffer, 16);
printText("-------> Aqui 96.22 - \0");
printText(vbuffer);
printText("\r\n\0");
#endif

#ifdef __DEBUG__
/*itoa(ix, vbuffer, 10);
printText("-------> Aqui 96.2 - ix=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif

                if (vToken == 0x83 || vToken == 0x84)
                {
                    ixx = 0;
                    vFirstArit = 0;

                    if (*vInicioSentenca != 2)
                    {
                        if (vToken == ':')
                            *vInicioSentenca = 1;
                        else 
                            *vInicioSentenca = 0;
                    }
                }

                if (!vFirstArit && vToken >= 0xF0)
                {
                    vFirstArit = 1;
                    ixant = ix;
                }

#ifdef __DEBUG__
printText("-------> Aqui 900 - vRetInf.tString=[");
printText(vRetInf.tString);
printText("]\r\n\0");

itoa(*vParenteses, vbuffer, 10);
printText("-------> Aqui 96.7 - *vParenteses=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif
                vTemp[0] = 0x00;
                vTemp[1] = 0x00;
                vTemp[2] = 0x00;

                if (vToken < 0xF0 && pToken < 0xF0)
                    strcpy(vTemp, vRetInf.tString);

                vReta = executeToken(pStartList, vToken, &vRetInf);

                if (pToken == 0xF9 && *vInicioSentenca == 2)
                    *vMaisTokens = 0;

#ifdef __DEBUG__
printText("-------> Aqui 96.72 - vRetInf.tString=[");
printText(vRetInf.tString);
printText("]\r\n\0");

itoa(vToken, vbuffer, 16);
printText("-------> Aqui 96.8 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(pToken, vbuffer, 16);
printText("-------> Aqui 96.9 - pToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif
    
                if ((vToken < 0xF0 && pToken < 0xF0) || (vParTemp != 0 && *vParenteses && pToken < 0xF0))
                {
                    iyy = strlen(vRetInf.tString);
                    iz = strlen(vTemp);
                    if (vParTemp != 0)
                    {
                        vTemp[iz++] = '(';
                        vTemp[iz] = 0x00;
                    }
                    for (iw = 0; iw < iyy; iw++)
                    {
                        vTemp[iz++] = vRetInf.tString[iw];
                        vTemp[iz] = 0x00;
                    }

                    strcpy(vRetInf.tString, vTemp);
                }

                ixx = strlen(vRetInf.tString);

#ifdef __DEBUG__
printText("-------> Aqui 901 - vRetInf.tString=[");
printText(vRetInf.tString);
printText("]\r\n\0");

/*ltoa(*pStartList, vbuffer, 16);
printText("-------> Aqui 97 - \0");
printText(vbuffer);
printText("\r\n\0");*/
#endif

                if (vReta < 0)
                    break;

#ifdef __DEBUG__
itoa(pToken, vbuffer, 16);
printText("-------> Aqui 94 - pToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(vToken, vbuffer, 16);
printText("-------> Aqui 95 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

/*itoa(ix, vbuffer, 16);
printText("-------> Aqui 92 - ix=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(ixant, vbuffer, 16);
printText("-------> Aqui 93 - ixant=[\0");
printText(vbuffer);
printText("]\r\n\0");*/

/*itoa(ix, vbuffer, 10);
printText("-------> Aqui 43.2 - ix=[\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif

/*                if (vFirstArit && vToken >= 0xF0)
                {
                    printText("-------> Aqui 43.21\r\n\0");
                    ix = ixant;
                }

                iz = strlen(vRetInf.tString);
                for (iw = 0; iw < iz; iw++)
                {
                    pRetInf->tString[ix++] = vRetInf.tString[iw];
                    pRetInf->tString[ix] = 0x00;
                    pRetInf->tType = 0;
                }

                vPRetInfJustFilled = 1;*/

#ifdef __DEBUG__
/*itoa(vToken, vbuffer, 16);
printText("-------> Aqui 43.3 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(ix, vbuffer, 10);
printText("-------> Aqui 43.4 - ix=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(ixant, vbuffer, 10);
printText("-------> Aqui 43.5 - ixant=[\0");
printText(vbuffer);
printText("]\r\n\0");

printText("-------> Aqui 43.6 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");

printText("-------> Aqui 43.7 - vRetInf.tString=[\0");
printText(vRetInf.tString);
printText("]\r\n\0");*/
#endif

//                vRetInf.tString[0] = 0x00;

#ifdef __DEBUG__
/*printText("-------> Aqui 91 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");*/
#endif

                //ixx = 0;
            }
        }
        else if (vToken > 0)
        {
            if (vToken == 0x28)
            {
                *vParenteses = *vParenteses + 1;
                vParTemp = '(';
            }

#ifdef __DEBUG__
itoa(pToken, vbuffer, 16);
printText("-------> Aqui 94 - pToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(vToken, vbuffer, 16);
printText("-------> Aqui 95 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(*vParenteses, vbuffer, 10);
printText("-------> Aqui 96.71 - *vParenteses=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

            if (!*vParenteses && vToken == 0x29)
                return -4;
            else if (*vParenteses && vToken == 0x29)
            {
                *vParenteses = *vParenteses - 1; // Testar -------> Aqui e se nao der certo, Tirar

                if (pToken < 0xF0)
                {
                    vRetInf.tString[ixx++] = vToken;
                    vRetInf.tString[ixx] = 0x00;
                }
                else
                {
                    *vParenteses = *vParenteses + 1; // Testar -------> Aqui e se nao der certo, Tirar
                    (*pStartList)--;
                }

#ifdef __DEBUG__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 44.81 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(*(*pStartList), vbuffer, 16);
printText("-------> Aqui 44.82 - *(*pStartList)=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

                if (*(*pStartList) < 0x80 && *(*pStartList) != ';' && *(*pStartList) != ':')
                    break;
            }


#ifdef __DEBUG__
printText("-------> Aqui 91.1 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif

            if (vToken == 0x22)
                vAspas = !vAspas;

            if (vToken != 0x20 || (vToken == 0x20 && vAspas))
            {
#ifdef __DEBUG__
itoa(*vInicioSentenca, vbuffer, 16);
printText("-------> Aqui 43 - vInicioSentenca=[\0");
printText(vbuffer);
itoa(vToken, vbuffer, 16);
printText("] vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif
                if (vToken == ';' || vToken == ':')
                {
                    ixx = 0;
                    vFirstArit = 0;

                    if (*vInicioSentenca != 2)
                    {
                        if (vToken == ':')
                            *vInicioSentenca = 1;
                        else 
                            *vInicioSentenca = 0;
                    }

                    if (pToken >= 0xF0)
                        break;

                    iyy = strlen(vRetInf.tString);
                    for (iw = 0; iw < iyy; iw++)
                    {
                        pRetInf->tString[ix++] = vRetInf.tString[iw];
                        pRetInf->tString[ix] = 0x00;
                        pRetInf->tType = 0;
                    }

                    pRetInf->tString[ix++] = vToken;
                    pRetInf->tString[ix] = 0x00;
                    pRetInf->tType = 0;

//                    vPRetInfJustFilled = 1;
                }
                else if ((vToken == '$' || vToken == '#' || vToken == '%') && (!*vInicioSentenca || (*vInicioSentenca == 2 && *vMaisTokens)))
                {
                    iyy = strlen(vRetInf.tString);
                    izz = 0;
                    for (iw = 0; iw < iyy; iw++)
                    {
                        if (vRetInf.tString[iw] != '(')
                        {
                            vTemp[izz++] = vRetInf.tString[iw];
                            vTemp[izz] = 0x00;
                        }
                    }

                    vTemp[iyy] = vToken;
                    vTemp[iyy + 1] = 0x00;

#ifdef __DEBUG__
/*printText("-------> Aqui 44 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");*/
                    #endif
                    iw = strlen(vTemp);
                    if (ixx < iw)
                        iw--;

                    if (!findVariable(&vTemp))
                        return -5;
#ifdef __DEBUG__
/*printText("-------> Aqui 44.5 - vTemp=[\0");
printText(vTemp);
printText("]\r\n\0");*/
#endif

                    ixx -= iw;

#ifdef __DEBUG__
itoa(ixx, vbuffer, 10);
printText("-------> Aqui 44.51 - ixx=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

                    iyy = strlen(vTemp);
                    for (iw = 0; iw < iyy; iw++)
                    {
                        vRetInf.tString[ixx++] = vTemp[iw];
                        vRetInf.tString[ixx] = 0x00;
                        vRetInf.tType = 0;
                    }

                    vTemp[0] = 0x00;
                    vTemp[1] = 0x00;
                    vTemp[2] = 0x00;

#ifdef __DEBUG__
printText("-------> Aqui 44.7 - vRetInf.tString=[\0");
printText(vRetInf.tString);
printText("]\r\n\0");
#endif
                }
                else
                {
                    if (vToken != 0x29)
                    {
                        vRetInf.tString[ixx++] = vToken;
                        vRetInf.tString[ixx] = 0x00;
                    }
                }
            }

#ifdef __DEBUG__
itoa(vToken, vbuffer, 16);
printText("-------> Aqui 44.91 - vToken=[\0");
printText(vbuffer);
printText("]\r\n\0");

itoa(*(*pStartList), vbuffer, 16);
printText("-------> Aqui 44.92 - *(*pStartList)=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

            if (*vTemIf && *(*pStartList) == 0x83)  // Se eh linha com IF e tem Token do THEN, ou Then e Else
                break;

            if (*vParenteses && vToken == 0x29 && *(*pStartList) != ';' && *(*pStartList) != ':')
                break;

            if (vToken != 0x29 && (*(*pStartList) == 0xF3 || *(*pStartList) == 0xF4))   // AND ou OR
                break;
        }
    }


#ifdef __DEBUG__
/*printText("-------> Aqui 44.8 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");

printText("-------> Aqui 44.9 - vRetInf.tString=[\0");
printText(vRetInf.tString);
printText("]\r\n\0");*/
#endif

    if (vRetInf.tString[0] != 0x00 && !vPRetInfJustFilled)
    {
        if (vFirstArit && vToken >= 0xF0)
        {
            ix = ixant;
        }

        iyy = strlen(vRetInf.tString);
        for (iw = 0; iw < iyy; iw++)
        {
            pRetInf->tString[ix++] = vRetInf.tString[iw];
            pRetInf->tString[ix] = 0x00;
            pRetInf->tType = 0;
        }
    }

#ifdef __DEBUG__
printText("-------> Aqui 44.10 - pRetInf->tString=[\0");
printText(pRetInf->tString);
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
    unsigned char vAspas = 0, vVirgula = 0;
//    char sNumLin [sizeof(short)*8+1];
    int ix = 0;

    if (pRetInf->tString[ix] == 0x00)
        return -1;

    do
    {
        if (pRetInf->tString[ix] == 0x00)
            break;

/*itoa(pRetInf->tString[ix], sNumLin, 16);
printText("[\0");
printText(sNumLin);
printText("],\0");*/
        // Ativa modo aspas
        if (pRetInf->tString[ix] == 0x22)
        {
            vAspas = !vAspas;
            ix++;
            continue;
        }

        // Ignora ponto e Virgula se nao for dentro de aspas, apenas continua analisando o que tiver depois
        if (pRetInf->tString[ix] == ';' && !vAspas)
        {
            ix++;
            continue;
        }

        // Ignora espaço se nao for dentro de Aspas
        if (pRetInf->tString[ix] == 0x20 && !vAspas)
        {
            ix++;
            continue;
        }

        printChar(pRetInf->tString[ix]);
        ix++;
    } while (1);

    printText("\r\n\0");

/*    if (vAspas)
        return -1;*/

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basChr(typeInf *pRetInf)
{
    unsigned char vAscii[10];
    int ix = 0, iy = 0, iz, vNum = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    vAscii[0] = 0x00;
    ix++;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNum = atoi(vAscii);

            if (vNum == 0 || vNum > 255)
                return -1;

            break;
        }

        vAscii[iy++] = pRetInf->tString[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    pRetInf->tString[0] = 0x22; // "
    pRetInf->tString[1] = vNum; // Numero gerado
    pRetInf->tString[2] = 0x22; // "
    pRetInf->tString[3] = 0x00; // \0

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basVal(typeInf *pRetInf)
{
    unsigned char vAscii[250];
    int ix = 0, iy = 0, iz = 0;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];

#ifdef __DEBUG__
printText("-------> Aqui 716 - [\0");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif
    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    // Erro, segundo caracter deve ser aspas
    if (pRetInf->tString[ix + 1] != 0x22)
        return -3;

    iy = strlen(pRetInf->tString) - 2;

    // Erro, penultimo caracter deve ser aspas
    if (pRetInf->tString[iy] != 0x22)
        return -3;

    vAscii[0] = 0x00;
    ix++;
    iy=0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNum = fix16_from_str(vAscii);

            break;
        }

        if (pRetInf->tString[ix] != 0x22)
        {
            vAscii[iy++] = pRetInf->tString[ix++];
            vAscii[iy] = 0x00;
        }
        else
            ix++;
    } while (1);

    fix16_to_str(vNum, vbuffer, 4);
#ifdef __DEBUG__
/*printText("-------> Aqui 726 - [\0");
printText(vbuffer);
printText("]\r\n\0");*/
#endif
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
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basStr(typeInf *pRetInf)
{
    unsigned char vAscii[250];
    int ix = 0, iy = 0, iz = 0;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    // Erro, segundo caracter nao deve ser aspas
    if (pRetInf->tString[ix + 1] == 0x22)
        return -3;

    iy = strlen(pRetInf->tString);

    vAscii[0] = 0x00;
    ix++;
    iy=0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNum = fix16_from_str(vAscii);

            break;
        }

        vAscii[iy++] = pRetInf->tString[ix++];
        vAscii[iy] = 0x00;
    } while (1);

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
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
char basLen(typeInf *pRetInf)
{
    unsigned char vAscii[250];
    int ix = 0, iy = 0, iz = 0;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];

#ifdef __DEBUG__
/*printText("-------> Aqui 625 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");*/
#endif
    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    // Erro, segundo caracter deve ser aspas
    if (pRetInf->tString[ix + 1] != 0x22)
        return -6;

    iy = strlen(pRetInf->tString) - 2;

    // Erro, penultimo caracter deve ser aspas
    if (pRetInf->tString[iy] != 0x22)
        return -6;

    vAscii[0] = 0x00;
    ix++;
    iy=0;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {

            vNum = strlen(vAscii);

            break;
        }

        if (pRetInf->tString[ix] != 0x22)
        {
//            printChar(pRetInf->tString[ix]);

            vAscii[iy++] = pRetInf->tString[ix++];
            vAscii[iy] = 0x00;
        }
        else
            ix++;
    } while (1);

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
    int ix = 0, iy = 0, iz, vZero = 0;
    unsigned long vTotal;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        if (pRetInf->tString[ix] == 0x30)
            vZero = 1;

        if (pRetInf->tString[ix] == 0x29 & !vZero)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29 & vZero)
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

            break;
        }

        ix++;
    } while (1);

    return 0;
}

//-----------------------------------------------------------------------------
// Soma 2 numeros ou strings passados
// Syntaxe:
//      <previous token or variable> [=] <number or string> + <number or string>
//-----------------------------------------------------------------------------
char basSum(typeInf *pRetInf)
{
    unsigned char vNum1[10], vNum2[10], sStr1[250], sStr2[250];
    int ix = 0, iy = 0, iz, iw = 0;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];
    char vAspas = 0, parte = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

#ifdef __DEBUG__
/*printText("-------> Aqui 123 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");*/
#endif
    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    if (strchr(pRetInf->tString, 0x22))
        vAspas = 1;

    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            if (!vAspas)
                parte = 1;

            iy = 0;
            ix++;
            parte=1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            if (!vAspas)
            {
#ifdef __DEBUG__
/*printText("-------> Aqui 124 - vNum1=[\0");
printText(vNum1);
printText("] - vNum2=[\0");
printText(vNum2);
printText("]\r\n\0");*/
#endif
                vRes = fix16_add(fix16_from_str(vNum1), fix16_from_str(vNum2));
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

            break;
        }

        if (!vAspas)
        {
            if (!parte)
            {
                vNum1[iy++] = pRetInf->tString[ix++];
                vNum1[iy] = 0x00;
            }
            else
            {
                vNum2[iy++] = pRetInf->tString[ix++];
                vNum2[iy] = 0x00;
            }
        }
        else
        {
            if (!parte)
            {
                sStr1[iy++] = pRetInf->tString[ix++];
                sStr1[iy] = 0x00;
            }
            else
            {
                sStr2[iy++] = pRetInf->tString[ix++];
                sStr2[iy] = 0x00;
            }
        }
    } while (1);

    if (!vAspas)
    {
        fix16_to_str(vRes, vbuffer, 4);
        iy = strlen(vbuffer);
        for (ix = 0; ix < iy; ix++)
        {
            pRetInf->tString[ix] = vbuffer[ix]; // Numero gerado
            pRetInf->tString[ix + 1] = 0x00;
        }
    }
    else
    {
        pRetInf->tString[0] = 0x22;

        iy = strlen(sStr1);
        ix = 0;
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

#ifdef __DEBUG__
/*printText("-------> Aqui 126 - pRetInf->tString=[\0");
printText(pRetInf->tString);
printText("]\r\n\0");*/
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
    unsigned char vNum1[10], vNum2[10];
    int ix = 0, iy = 0, iz, vParte = 0;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            vRes = fix16_sub(fix16_from_str(vNum1), fix16_from_str(vNum2));

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

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
    int ix = 0, iy = 0, iz, vParte = 0;
    long vRes = 0, vR1, vR2;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            vR1 = fix16_from_str(vNum1);
            vRes = vR1;
            vR2 = fix16_from_str(vNum2);
            vR2 = fix16_to_int(vR2);
            vR2--;

#ifdef __DEBUG__
itoa(vR1, vbuffer, 16);
printText("-------> Aqui 394.1 - vR1=[\0");
printText(vbuffer);
printText("]\r\n\0");
itoa(vR2, vbuffer, 16);
printText("-------> Aqui 394.2 - vR2=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

            for(iz = 0; iz < vR2; iz++)
            {
                vRes = fix16_mul(vRes, vR1);

#ifdef __DEBUG__
itoa(vRes, vbuffer, 16);
printText("-------> Aqui 394 - vRes=[\0");
printText(vbuffer);
printText("]\r\n\0");
#endif

                if (vRes == fix16_overflow)
                    return -2;
            }


            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

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
    unsigned char vNum1[10], vNum2[10];
    int ix = 0, iy = 0, iz, vParte = 0;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            vRes = fix16_mul(fix16_from_str(vNum1), fix16_from_str(vNum2));

            if (vRes == fix16_overflow)
                return -2;

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

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
    unsigned char vNum1[10], vNum2[10];
    int ix = 0, iy = 0, iz, vParte = 0;
    long vRes = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            vRes = fix16_div(fix16_from_str(vNum1), fix16_from_str(vNum2));

            if (vRes == fix16_overflow)
                return -2;

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

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
    unsigned char vAscii[10];
    int ix = 0, iy = 0, iz;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    vAscii[0] = 0x00;
    ix++;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNum = fix16_sqrt(fix16_from_str(vAscii));

            if (vNum == fix16_overflow)
                return -2;

            break;
        }

        vAscii[iy++] = pRetInf->tString[ix++];
        vAscii[iy] = 0x00;
    } while (1);

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
    unsigned char vAscii[10];
    int ix = 0, iy = 0, iz;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];

#ifdef __DEBUG__
printText("-------> Aqui 666 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif    
    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    vAscii[0] = 0x00;
    ix++;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNum = fix16_sin(fix16_from_str(vAscii));

            if (vNum == fix16_overflow)
                return -2;

            break;
        }

        vAscii[iy++] = pRetInf->tString[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    fix16_to_str(vNum, vbuffer, 4);
#ifdef __DEBUG__
printText("-------> Aqui 667 - vbuffer=[");
printText(vbuffer);
printText("]\r\n\0");
#endif
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
    unsigned char vAscii[10];
    int ix = 0, iy = 0, iz;
    long vNum = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    vAscii[0] = 0x00;
    ix++;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNum = fix16_cos(fix16_from_str(vAscii));

            if (vNum == fix16_overflow)
                return -2;

            break;
        }

        vAscii[iy++] = pRetInf->tString[ix++];
        vAscii[iy] = 0x00;
    } while (1);

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
    unsigned char vAscii[10];
    int ix = 0, iy = 0, iz;
    long vNumTam = 0;
    char vbuffer [sizeof(long)*8+1];

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    // Erro, primeiro caracter deve ser abre parenteses
    if (pRetInf->tString[ix] != 0x28)
        return -1;

    vAscii[0] = 0x00;
    ix++;

    do
    {
        // Erro, ultimo caracter deve ser fecha parenteses
        if (pRetInf->tString[ix] == 0x00)
            return -1;

        // Achou o parenteses final
        if (pRetInf->tString[ix] == 0x29)
        {
            vNumTam = fix16_tan(fix16_from_str(vAscii));

            if (vNumTam == fix16_overflow)
                return -2;

            break;
        }

        vAscii[iy++] = pRetInf->tString[ix++];
        vAscii[iy] = 0x00;
    } while (1);

    fix16_to_str(vNumTam, vbuffer, 4);
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
    int ix = 0, iy = 0, iz, vParte = 0;
    char vRes = '\0';
    char vbuffer [sizeof(long)*8+1];
    char vRetFV = 0;
    long vResNum1 = 0, vResNum2 = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

#ifdef __DEBUG__
/*    printText("-------> Aqui 66 - pRetInf->tString=[");
    printText(pRetInf->tString);
    printText("]\r\n\0");*/
#endif
    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            // 
            vNomVar[0] = vNum1[0]; vNomVar[1] = vNum1[1];
            iz = strlen(vNum1) - 1;
            vTypeVar = vNum1[iz];

            // Procura variavel
#ifdef __DEBUG__
printText("-------> Aqui 65 - pRetInf->tString=[");
printText(vNum1);
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

#ifdef __DEBUG__
if (*vInicioSentenca)
    printText("-------> Aqui 654 - *vInicioSentenca=[2");
else
    printText("-------> Aqui 656 - *vInicioSentenca=[0");
printText("]\r\n\0");
#endif        

            // Se nao existe variavel e nao inicio sentenca, erro
            if (!vRetFV && !*vInicioSentenca)
            {
                return -5;
            }

            // Se nao existe variavel e inicio sentenca, cria variavel e atribui o valor
            if (!vRetFV && *vInicioSentenca)
            {
                createVariable(vNum1, vNum2, pRetInf->tString[2]);
            }

            // Se existe variavel e inicio sentenca, altera variavel atribuindo o valor
            if (vRetFV && *vInicioSentenca)
            {
                updateVariable(vNum1, vNum2, pRetInf->tString[2], 1);                
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

                    if (vResNum1 == vResNum2)
                        vRes = 'y';
                    else
                        vRes = 'n';
                }
                else
                {
                    // Se for string, compara
                    iz = strlen(vNum1);
                    if (strncmp(vNum1, vNum2, iz) == 0)
                        vRes = 'y';
                    else
                        vRes = 'n';
                }
            }

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

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
    int ix = 0, iy = 0, iz, vParte = 0;
    char vRes = '\0';
    char vbuffer [sizeof(long)*8+1];
    char vRetFV = 0;
    long vResNum1 = 0, vResNum2 = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

#ifdef __DEBUG__
/*    printText("-------> Aqui 66 - pRetInf->tString=[");
    printText(pRetInf->tString);
    printText("]\r\n\0");*/
#endif
    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
            // 
            vNomVar[0] = vNum1[0]; vNomVar[1] = vNum1[1];
            iz = strlen(vNum1) - 1;
            vTypeVar = vNum1[iz];

            // Procura variavel
#ifdef __DEBUG__
printText("-------> Aqui 65 - pRetInf->tString=[");
printText(vNum1);
printText("]\r\n\0");
#endif        
            // Se for uma variavel, procura, se nao, retorna 1 indicando que é outra coisa, um numero
            if (vNum1[0] >= 0x41)
                vRetFV = findVariable(vNum1);
            else
                vRetFV = 1;

            if (vRetFV < 0)
                return vRetFV;

#ifdef __DEBUG__
if (*vInicioSentenca)
    printText("-------> Aqui 654 - *vInicioSentenca=[2");
else
    printText("-------> Aqui 656 - *vInicioSentenca=[0");
printText("]\r\n\0");
#endif        

            // Se existe variavel e nao eh inicio sentenca, compara valores
            if (vRetFV)
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

                    vRes = 'n';

                    switch (pToken)
                    {
                        case 0xF5:
                            if (vResNum1 >= vResNum2)
                                vRes = 'y';
                            break;
                        case 0xF6:
                            if (vResNum1 <= vResNum2)
                                vRes = 'y';
                            break;
                        case 0xF7:
                            if (vResNum1 != vResNum2)
                                vRes = 'y';
                            break;
                        case 0xF8:
                            if (vResNum1 < vResNum2)
                                vRes = 'y';
                            break;
                        case 0xFA:
                            if (vResNum1 > vResNum2)
                                vRes = 'y';
                            break;
                    }
                }
                else
                {
                    // Se for string, compara
                    iz = strlen(vNum1);

                    vRes = 'n';

                    switch (pToken)
                    {
                        case 0xF5:
                            if (strncmp(vNum1, vNum2, iz) >= 0)
                                vRes = 'y';
                            break;
                        case 0xF6:
                            if (strncmp(vNum1, vNum2, iz) <= 0)
                                vRes = 'y';
                            break;
                        case 0xF7:
                            if (strncmp(vNum1, vNum2, iz) != 0)
                                vRes = 'y';
                            break;
                        case 0xF8:
                            if (strncmp(vNum1, vNum2, iz) < 0)
                                vRes = 'y';
                            break;
                        case 0xFA:
                            if (strncmp(vNum1, vNum2, iz) > 0)
                                vRes = 'y';
                            break;
                    }
                }
            }

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

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
    int ix = 0, iy = 0, iz, vParte = 0;
    char vRes = '\0';
    char vRetFV = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

#ifdef __DEBUG__
printText("-------> Aqui 566 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");
#endif
    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
#ifdef __DEBUG__
printText("-------> Aqui 265 - vNum1=[");
printText(vNum1);
printText("]\r\n\0");
printText("-------> Aqui 265 - vNum2=[");
printText(vNum2);
printText("]\r\n\0");
#endif        
            
            if (vNum1[0] == 0x28 && vNum1[2] == 0x29)
            {
                vNum1[0] = vNum1[1];
                vNum1[1] = 0x00;
            }
            else if (vNum1[1] == 0x29)
                vNum1[1] = 0x00;

            if (vNum2[0] == 0x28 && vNum2[2] == 0x29)
            {
                vNum2[0] = vNum2[1];
                vNum2[1] = 0x00;
            }
            else if (vNum2[1] == 0x29)
                vNum2[1] = 0x00;

            // Verifica se é valor, se for, converte pra valor em c
            vRes = 'n';

            if (vNum1[0] == 'y' && vNum2[0] == 'y')
                vRes = 'y';

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

    pRetInf->tString[0] = vRes;
    pRetInf->tString[1] = 0x00;

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
    int ix = 0, iy = 0, iz, vParte = 0;
    char vRes = '\0';
    char vRetFV = 0;

    // Erro, nao veio nada
    if (pRetInf->tString[ix] == 0x00)
        return -1;

    vNum1[0] = '0'; vNum1[0] = '\0';
    vNum2[0] = '0'; vNum2[1] = '\0';

//#ifdef __DEBUG__
printText("-------> Aqui 866 - pRetInf->tString=[");
printText(pRetInf->tString);
printText("]\r\n\0");
//#endif
    do
    {
        // Achou a virgula separando os 2 numeros
        if (pRetInf->tString[ix] == ',')
        {
            iy = 0;
            ix++;
            vParte = 1;
        }

        // Achou o final dos 2 numeros
        if (pRetInf->tString[ix] == 0x00)
        {
//#ifdef __DEBUG__
printText("-------> Aqui 265.1 - vNum1=[");
printText(vNum1);
printText("]\r\n\0");
printText("-------> Aqui 265.1 - vNum2=[");
printText(vNum2);
printText("]\r\n\0");
//#endif        
            
            if (vNum1[0] == 0x28 && vNum1[2] == 0x29)
            {
                vNum1[0] = vNum1[1];
                vNum1[1] = 0x00;
            }
            else if (vNum1[1] == 0x29)
                vNum1[1] = 0x00;

            if (vNum2[0] == 0x28 && vNum2[2] == 0x29)
            {
                vNum2[0] = vNum2[1];
                vNum2[1] = 0x00;
            }
            else if (vNum2[1] == 0x29)
                vNum2[1] = 0x00;

            // Verifica se é valor, se for, converte pra valor em c
            vRes = 'n';

            if (vNum1[0] == 'y' || vNum2[0] == 'y')
                vRes = 'y';

            break;
        }

        if (!vParte)
        {
            vNum1[iy++] = pRetInf->tString[ix++];
            vNum1[iy] = 0x00;
        }
        else
        {
            vNum2[iy++] = pRetInf->tString[ix++];
            vNum2[iy] = 0x00;
        }
    } while (1);

    pRetInf->tString[0] = vRes;
    pRetInf->tString[1] = 0x00;

    return 0;
}

//--------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------
char basIf(typeInf *pRetInf)
{

    return 0;
}

//--------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------
char basThenElse(typeInf *pRetInf)
{

    return 0;
}
