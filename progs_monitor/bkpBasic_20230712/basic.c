/********************************************************************************
*    Programa    : basic.c
*    Objetivo    : MMSJ-Basic para o MMSJ300
*    Criado em   : 10/10/2022
*    Programador : Moacir Jr.
*--------------------------------------------------------------------------------
* Data        Versao  Responsavel  Motivo
* 10/10/2022  0.1     Moacir Jr.   Criacao Versao Beta
* 26/06/2023  0.4     Moacir Jr.   Simplificacoes e ajustres
* 27/06/2023  0.4a    Moacir Jr.   Adaptar processos de for-next e if-then-else
* 01/07/2023  0.4b    Moacir Jr.   Ajuste de Bugs
* 03/07/2023  0.5     Moacir Jr.   Colocar Logica Ponto Flutuante
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
*   Actual, using struct varMem
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

#define __FFP_FUNC__
#define __LOOP_FUNC__
#define __COND_FUNC__
#define __DIV_FUNC__
#define __GRAPH_FUNC__

#define versionBasic "0.5"

//-----------------------------------------------------------------------------
// Principal
//-----------------------------------------------------------------------------
void main(void)
{
    unsigned char vRetInput;

    *(vmfp + Reg_TADR) = 0xF5;  // 245
    *(vmfp + Reg_TACR) = 0x02;  // prescaler de 10. total 2,4576Mhz/10*245 = 1003KHz

    clearScr();
    printText("MMSJ-BASIC v"versionBasic);
    printText("\r\n\0");
    printText("Utility (c) 2022-2023\r\n\0");
    printText("OK\r\n\0");

    *vBufReceived = 0x00;
    *vbuf = '\0';
    *pProcess = 0x01;
    *pTypeLine = 0x00;
    *nextAddrLine = pStartProg;
    *firstLineNumber = 0;
    *addrFirstLineNumber = 0;
    *traceOn = 0;
    *lastHgrX = 0;
    *lastHgrY = 0;

    while (*pProcess)
    {
        vRetInput = inputLine(128,'$');

        if (*vbuf != 0x00 && (vRetInput == 0x0D || vRetInput == 0x0A))
        {
            printText("\r\n\0");

            processLine();

            if (!*pTypeLine && *pProcess)
                printText("\r\nOK\0");

            *vBufReceived = 0x00;
            *vbuf = '\0';

            if (!*pTypeLine && *pProcess)
                printText("\r\n\0");   // printText("\r\n>\0");
        }
        else if (vRetInput != 0x1B)
        {
            printText("\r\n\0");
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
    unsigned char vTimer;
    unsigned char vBuffer[20];

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
            if (!strcmp(linhacomando,"HOME") && iy == 4)
            {
                clearScr();
            }
            else if (!strcmp(linhacomando,"NEW") && iy == 3)
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
            else if (!strcmp(linhacomando,"XBASLOAD") && iy == 8)
            {
                basXBasLoad();
            }
            else if (!strcmp(linhacomando,"TIMER") && iy == 5)
            {
                // Ler contador A do 68901
                vTimer = *(vmfp + Reg_TADR);

                // Devolve pra tela
                itoa(vTimer,vBuffer,10);
                printText("Timer: ");
                printText(vBuffer);
                printText("ms\r\n\0");
            }
            else if (!strcmp(linhacomando,"TRACE") && iy == 5)
            {
                *traceOn = 1;
            }
            else if (!strcmp(linhacomando,"NOTRACE") && iy == 7)
            {
                *traceOn = 0;
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
                *ftos=0;
                *gtos=0;
                *vErroProc = 0;
                do
                {
                    *doisPontos = 0;
                    *vInicioSentenca = 1;
                    vReta = executeToken(*pointerRunProg++);
                } while (*doisPontos);
                comandLineTokenized = vAntAddr;

                if (*vdp_mode != VDP_MODE_TEXT)
                    basText();

                if (*vErroProc)
                {
                    showErrorMessage(*vErroProc, 0);
                }
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
    char isToken;

    // Separar linha entre comando e argumento
    vLinhaArg[0] = '\0';
    vLido[0]  = '\0';
    ix = 0;
    iy = 0;
    vAspas = 0;
//writeLongSerial("Aqui 000\r\n");

    while (1)
    {
        vLido[ix] = '\0';

        if (*blin == 0x22)
            vAspas = !vAspas;
/*writeLongSerial("Aqui 666-");
writeSerial(*blin);
writeLongSerial(".\r\n");
writeLongSerial("Aqui 666-");
writeSerial(*blin);
writeLongSerial(".\r\n");*/

/*		if (!vAspas && !strchr(operandsWithTokens, *(blin - 1)) && strchr(operandsWithTokens, *blin) && !strchr(operandsWithTokens, *(blin + 1)))
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
		}*/

        // Se for quebrador sequencia, verifica se é um token
        if ((!vAspas && strchr(" ;,+-<>()/*^=:",*blin)) || !*blin)
        {
/*writeLongSerial("Aqui 777-");
writeSerial(*blin);
writeLongSerial(".\r\n");*/
            // Montar comparacoes "<>", ">=" e "<="
            if (((*blin == 0x3C || *blin == 0x3E) && (!vFirstComp && (*(blin + 1) == 0x3E || *(blin + 1) == 0x3D))) || (vFirstComp && *blin == 0x3D) || (vFirstComp && *blin == 0x3E))
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
                        else if (iz==iw)
                        {
                            if(strncmp(vLidoCaps, keywords[kt].keyword, iw) == 0)
                            {
                                vToken = keywords[kt].token;
                                break;
                            }
                        }
					}
                }

                if (vToken)
                {
                    vLinhaArg[iy++] = vToken;

                    //if (*blin == 0x28 || *blin == 0x29)
                    //    vLinhaArg[iy++] = *blin;

                    //if (*blin == 0x3A)  // :
                    if (*blin && *blin != 0x20 && vToken < 0xF0)
                        vLinhaArg[iy++] = toupper(*blin);
                }
                else
                {
                    for(kt = 0; kt < ix; kt++)
                        vLinhaArg[iy++] = vLido[kt];

                    if (*blin && *blin != 0x20)
                        vLinhaArg[iy++] = toupper(*blin);
                }
            }
            else
            {
                if (*blin && *blin != 0x20)
//                if (*blin == 0x28 || *blin == 0x29)
                    vLinhaArg[iy++] = toupper(*blin);
            }

            if (!*blin)
                break;

            vLido[0] = '\0';
            ix = 0;
        }
        else
        {
            if (!vAspas)
                vLido[ix++] = toupper(*blin);
            else
                vLido[ix++] = *blin;
        }

        blin++;
    }

//writeLongSerial("Aqui 002\r\n");
    vLinhaArg[iy] = 0x00;
//writeLongSerial("Aqui 003\r\n");

    for(kt = 0; kt < iy; kt++)
        pTokenized[kt] = vLinhaArg[kt];
//writeLongSerial("Aqui 004\r\n");

    pTokenized[iy] = 0x00;
//writeLongSerial("Aqui 005\r\n");
}

//-----------------------------------------------------------------------------
// Salva a linha no formato:
// NN NN NN LL LL xxxxxxxxxxxx 00
// onde:
//      NN NN NN         = endereco da proxima linha
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
        // Calcula nova posicao da proxima linha
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

        // Grava endereco proxima linha
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

    // Nao achou numero de linha inicial
    if (!vStartList)
    {
        printText("Non-existent line number\r\n\0");
        return;
    }

    vNextList = vStartList;

    while (1)
    {
        // Guarda proxima posicao
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

/*                    if (iy >= 0x80) // Tokens com um char somente
                    {
                        iy -= 0x80;

                        while (keywordsUnique[iy].keyword[iz])
                        {
                            vLinhaList[ix++] = keywordsUnique[iy].keyword[iz++];
                        }
                    }
                    else
                    {*/
                        while (keywords[iy].keyword[iz])
                        {
                            vLinhaList[ix++] = keywords[iy].keyword[iz++];
                        }

                        if (*vStartList != 0x28)
                            vLinhaList[ix++] = 0x20;
                    /*}*/
                }
                else
                {
                    // Apenas inclui na listagem
                    vLinhaList[ix++] = vToken;

                    if (isdigitus(vToken) && *vStartList!=')' && *vStartList!='"' && !isdigitus(*vStartList))
                        vLinhaList[ix++] = 0x20;
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

        // Guarda proxima posicao
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
    unsigned int vReta;
    char sNumLin [sizeof(short)*8+1];
    char vbuffer [sizeof(long)*8+1];
    unsigned char *vPointerChangedPointer;
    unsigned char *pForStack = forStack;
    unsigned char sqtdtam[20];

    *nextAddrSimpVar = pStartSimpVar;
    *nextAddrArrayVar = pStartArrayVar;
    *nextAddrString = pStartString;

    for (ix = 0; ix < 0x2000; ix++)
        *(pStartSimpVar + ix) = 0x00;

    for (ix = 0; ix < 0x6000; ix++)
        *(pStartArrayVar + ix) = 0x00;

    for (ix = 0; ix < 0x800; ix++)
        *(pForStack + ix) = 0x00;

    if (pNumber[0] != 0x00)
    {
        // rodar desde uma linha especifica
        pIni = atoi(pNumber);
    }

    vStartList = findNumberLine(pIni, 0, 0);

    // Nao achou numero de linha inicial
    if (!vStartList)
    {
        printText("Non-existent line number\r\n\0");
        return;
    }

    vNextList = vStartList;

    *ftos=0;
    *gtos=0;
    *changedPointer = 0;
    vDataPointer = 0;

    while (1)
    {
        if (*changedPointer!=0)
            vStartList = *changedPointer;

        // Guarda proxima posicao
        vNextList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
        *nextAddr = vNextList;

        if (vNextList)
        {
            // Pega numero da linha
            vNumLin = (*(vStartList + 3) << 8) | *(vStartList + 4);

            vStartList += 5;

            // Pega caracter a caracter da linha
            *changedPointer = 0;
            *vMaisTokens = 0;
            *vParenteses = 0x00;
            *vTemIf = 0x00;
            *vTemThen = 0;
            *vTemElse = 0;
            *vTemIfAndOr = 0x00;
            vRetInf.tString[0] = 0x00;
            pointerRunProg = vStartList;
            *vErroProc = 0;

            do
            {
                readChar();
                if (*vBufReceived==27)
                {
                    // volta para modo texto

                    // mostra mensagem de para subita
                    printText("\r\nStopped at ");
                    itoa(vNumLin, sNumLin, 10);
                    printText(sNumLin);
                    printText("\r\n");

                    // sai do laço
                    *nextAddr = 0;
                    break;
                }

                *doisPontos = 0;
                *vParenteses = 0x00;
                *vInicioSentenca = 1;

                if (*traceOn)
                {
                    printText("\r\nExecuting at ");
                    itoa(vNumLin, sNumLin, 10);
                    printText(sNumLin);
                    printText("\r\n");
                }

                vReta = executeToken(*pointerRunProg++);
                if (*vErroProc) break;

                if (*changedPointer!=0)
                {
                    vPointerChangedPointer = *changedPointer;

                    if (*vPointerChangedPointer == 0x3A)
                    {
                        pointerRunProg = *changedPointer;
                        *changedPointer = 0;
                    }
                }

                if (*pointerRunProg != 0x00)
                {
                    if (*pointerRunProg == 0x3A)
                    {
                        *doisPontos = 1;
                        pointerRunProg++;
                    }
                    else
                    {
                        if (*doisPontos && *pointerRunProg <= 0x80)
                        {
                            /* nao faz nada */
                        }
                        else
                        {
                            nextToken();
                            if (*vErroProc) break;
                        }
                    }
                }
            } while (*doisPontos);

            if (*vErroProc)
            {
                if (*vdp_mode != VDP_MODE_TEXT)
                    basText();

                showErrorMessage(*vErroProc, vNumLin);
                break;
            }

            if (*nextAddr == 0)
                break;

            vNextList = *nextAddr;
            vStartList = vNextList;
        }
        else
            break;
    }

    if (*vdp_mode != VDP_MODE_TEXT)
        basText();
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
void showErrorMessage(unsigned int pError, unsigned int pNumLine)
{
    char sNumLin [sizeof(short)*8+1];

    printText("\r\n");
    printText(listError[pError]);

    if (pNumLine > 0)
    {
        itoa(pNumLine, sNumLin, 10);

        printText(" at ");
        printText(sNumLin);
    }

    printText(" !\r\n\0");

    *vErroProc = 0;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
int executeToken(unsigned char pToken)
{
    char vReta = 0;
    unsigned char *pForStack = forStack;
    int ix;
    unsigned char sqtdtam[20];

    switch (pToken)
    {
        case 0x00:  // End of Line
            vReta = 0;
            break;
        case 0x80:  // Let
            vReta = basLet();
            break;
        case 0x81:  // Print
            vReta = basPrint();
            break;
        case 0x82:  // IF
            vReta = basIf();
            break;
        case 0x83:  // THEN - nao faz nada
            vReta = 0;
            break;
        case 0x84:  // ASC
            vReta = basAsc();
            break;
        case 0x85:  // FOR
            vReta = basFor();
            break;
        case 0x86:  // TO - nao faz nada
            vReta = 0;
            break;
        case 0x87:  // NEXT
            vReta = basNext();
            break;
        case 0x88:  // STEP - nao faz nada
            vReta = 0;
            break;
        case 0x89:  // GOTO
            vReta = basGoto();
            break;
        case 0x8A:  // GOSUB
            vReta = basGosub();
            break;
        case 0x8B:  // RETURN
            vReta = basReturn();
            break;
        case 0x8C:  // REM - Ignora todas a linha depois dele
            vReta = 0;
            break;
        case 0x8D:  // PEEK
            vReta = basPeekPoke('R');
            break;
        case 0x8E:  // POKE
            vReta = basPeekPoke('W');
            break;
        case 0x8F:  // DIM
            vReta = basDim();
            break;
        case 0x91:  // RND
            vReta = basRnd();
            break;
        case 0x92:  // Input
            vReta = basInputGet(250);
            break;
        case 0x93:  // Get
            vReta = basInputGet(1);
            break;
        case 0x94:  // vTAB
            vReta = basVtab();
            break;
        case 0x95:  // HTAB
            vReta = basHtab();
            break;
        case 0x96:  // Home
            clearScr();
            break;
        case 0x97:  // Clear - Clear all variables
            for (ix = 0; ix < 0x2000; ix++)
                *(pStartSimpVar + ix) = 0x00;

            for (ix = 0; ix < 0x6000; ix++)
                *(pStartArrayVar + ix) = 0x00;

            for (ix = 0; ix < 0x800; ix++)
                *(pForStack + ix) = 0x00;

            vReta = 0;
            break;
        case 0x98:  // DATA - Ignora toda a linha depois dele, READ vai ler essa linha
            vReta = 0;
            break;
        case 0x99:  // Read
            vReta = basRead();
            break;
        case 0x9A:  // Restore
            vReta = basRestore();
            break;
        case 0x9B:  // Len
            vReta = basLen();
            break;
        case 0x9C:  // Val
            vReta = basVal();
            break;
        case 0x9D:  // Str$
            vReta = basStr();
            break;
        case 0x9E:  // END
            vReta = basEnd();
            break;
        case 0x9F:  // STOP
            vReta = basStop();
            break;
        case 0xA1:  // Chr$
            vReta = basChr();
            break;
        case 0xA2:  // Fre(0)
            vReta = basFre();
            break;
        case 0xA3:  // Sqrt
            vReta = basSqrt();
            break;
        case 0xA4:  // Sin
            vReta = basSin();
            break;
        case 0xA5:  // Cos
            vReta = basCos();
            break;
        case 0xA6:  // Tan
            vReta = basTan();
            break;
        case 0xA7:  // LN
            vReta = basLn();
            break;
        case 0xA8:  // Exp
            vReta = basExp();
            break;
        case 0xA9:  // SPC
            vReta = basSpc();
            break;
        case 0xAA:  // Tab
            vReta = basTab();
            break;
        case 0xAB:  // Mid$
            vReta = basLeftRightMid('M');
            break;
        case 0xAC:  // Right$
            vReta = basLeftRightMid('R');
            break;
        case 0xAD:  // Left$
            vReta = basLeftRightMid('L');
            break;
        case 0xAE:  // INT
            vReta = basInt();
            break;
        case 0xAF:  // ABS
            vReta = basAbs();
            break;
        case 0xB0:  // TEXT
            vReta = basText();
            break;
        case 0xB1:  // GR
            vReta = basGr();
            break;
        case 0xB2:  // HGR
            vReta = basHgr();
            break;
        case 0xB3:  // COLOR
            vReta = basColor();
            break;
        case 0xB4:  // PLOT
            vReta = basPlot();
            break;
        case 0xB5:  // HLIN
            vReta = basHlin();
            break;
        case 0xB6:  // VLIN
            vReta = basVlin();
            break;
        case 0xB7:  // PLOT
            vReta = basScrn();
            break;
        case 0xB8:  // HCOLOR
            vReta = basHcolor();
            break;
        case 0xB9:  // HPLOT
            vReta = basHplot();
            break;
        case 0xBA:  // AT - Nao faz nada
            vReta = 0;
            break;
        default:
            if (pToken < 0x80)  // variavel sem LET
            {
                *pointerRunProg--;
                vReta = basLet();
            }
            else // Nao forem operadores logicos
            {
                *vErroProc = 14;
                vReta = 14;
            }
    }

    return vReta;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int nextToken(void)
{
    unsigned char *temp;
    int vRet, ccc;
    unsigned char sqtdtam[20];

    token_type=0;
    tok=0;
    temp=token;

    if(*pointerRunProg>=0x80 && *pointerRunProg<0xF0)   /* is a command */
    {
        tok=*pointerRunProg;
        token_type = COMMAND;
        token[0]=*pointerRunProg;
        token[1]=0x00;

        return token_type;
    }

    if(*pointerRunProg=='\0') { /* end of file */
        *token=0;
        tok = FINISHED;
        token_type=DELIMITER;

        return token_type;
    }

    while(iswhite(*pointerRunProg)) /* skip over white space */
        ++pointerRunProg;

    if(*pointerRunProg=='\r') { /* crlf */
        ++pointerRunProg;
        ++pointerRunProg;
        tok = EOL; *token='\r';
        token[1]='\n'; token[2]=0;
        token_type = DELIMITER;

        return token_type;
    }

    if(strchr("+-*^/=;:,><", *pointerRunProg) || *pointerRunProg>=0xF0) { /* delimiter */
        *temp=*pointerRunProg;
        pointerRunProg++; /* advance to next position */
        temp++;
        *temp=0;
        token_type=DELIMITER;

        return token_type;
    }

    if (*pointerRunProg==0x28 || *pointerRunProg==0x29)
    {
        if (*pointerRunProg==0x28)
            token_type=OPENPARENT;
        else
            token_type=CLOSEPARENT;

        token[0] = *pointerRunProg++;
        token[1] = 0x00;

        return token_type;
    }

    if (*pointerRunProg==":")
    {
        *doisPontos = 1;
        token_type=DOISPONTOS;

        return token_type;
    }

    if(*pointerRunProg=='"') { /* quoted string */
        pointerRunProg++;

        while(*pointerRunProg!='"'&& *pointerRunProg!='\r')
            *temp++=*pointerRunProg++;

        if(*pointerRunProg=='\r')
        {
            *vErroProc = 15;
            return 0;
        }

        pointerRunProg++;*temp=0;
        token_type=QUOTE;

        return token_type;
    }

    if(isdigitus(*pointerRunProg)) { /* number */
        while(!isdelim(*pointerRunProg) && (*pointerRunProg<0x80 || *pointerRunProg>=0xF0))
        {
            *temp++=*pointerRunProg++;
        }
        *temp = '\0';
        token_type = NUMBER;

        return token_type;
    }

    if(isalphas(*pointerRunProg)) { /* var or command */
        while(!isdelim(*pointerRunProg) && (*pointerRunProg<0x80 || *pointerRunProg>=0xF0))
            *temp++=*pointerRunProg++;
        *temp = '\0';
        token_type=VARIABLE;

        return token_type;
    }

    *temp = '\0';

    /* see if a string is a command or a variable */
    if(token_type==STRING) {
        token_type = VARIABLE;
    }

    return token_type;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
int findToken(unsigned char pToken)
{
    unsigned char kt;

    // Procura o Token na lista e devolve a posicao
    for(kt = 0; kt < keywords_count; kt++)
    {
        if (keywords[kt].token == pToken)
            return kt;
    }

    // Procura o Token nas operacões de 1 char
    /*for(kt = 0; kt < keywordsUnique_count; kt++)
    {
        if (keywordsUnique[kt].token == pToken)
            return (kt + 0x80);
    }*/

    return 14;
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

    if (pNumber)
    {
        while(vStartList)
        {
            vNumber = ((*(vStartList + 3) << 8) | *(vStartList + 4));

            if ((!pTipoFind && vNumber < pNumber) || (pTipoFind && vNumber != pNumber))
            {
                vLastList = vStartList;
                vStartList = (*(vStartList) << 16) | (*(vStartList + 1) << 8) | *(vStartList + 2);
            }
            else
                break;
        }
    }

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
    unsigned char* vLista = pStartSimpVar;
    unsigned char* vTemp = pStartSimpVar;
    unsigned char* vListaAtu;
    long vEnder = 0, vVal = 0, vVal1 = 0, vVal2 = 0, vVal3 = 0, vVal4 = 0;
    int ix = 0, iy = 0, iz = 0;
    char vbuffer [sizeof(long)*8+1];
    unsigned char sqtdtam[10];
    unsigned int vDim[88];
    int ixDim = 0;
    unsigned char vArray = 0;
    unsigned long* vPosNextVar = 0;
    unsigned char* vPosValueVar = 0;
    unsigned char vTamValue = 4;

    // Verifica se é array (tem parenteses logo depois do nome da variavel)
    if (*pointerRunProg == 0x28)
    {
        // Define que eh array
        vArray = 1;

        // Procura as dimensoes
        nextToken();
        if (*vErroProc) return 0;

        // Erro, primeiro caracter depois da variavel, deve ser abre parenteses
        if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
        {
            *vErroProc = 15;
            return 0;
        }

        do
        {
            nextToken();
            if (*vErroProc) return 0;

            if(token_type==QUOTE) { /* is string, error */
                *vErroProc = 16;
                return 0;
            }
            else { /* is expression */
                putback();

                getExp(&vDim[ixDim]);
                if (*vErroProc) return 0;

                if (value_type == '$' || value_type == '#')
                {
                    *vErroProc = 16;
                    return 0;
                }

                ixDim++;
            }

            if (*token == ',')
                pointerRunProg = pointerRunProg + 1;
            else
                break;
        } while(1);

        // Deve ter pelo menos 1 elemento
        if (ixDim < 1)
        {
            *vErroProc = 21;
            return 0;
        }

        nextToken();
        if (*vErroProc) return 0;

        // Ultimo caracter deve ser fecha parenteses
        if (token_type!=CLOSEPARENT)
        {
            *vErroProc = 15;
            return 0;
        }
    }

    // Procura na lista geral de variaveis simples
    if (vArray)
        vLista = pStartArrayVar;
    else
        vLista = pStartSimpVar;

    while(1)
    {
        *vPosNextVar = &vLista[3];

        if (*(vLista + 1) == pVariable[0] && *(vLista + 2) ==  pVariable[1])
        {
            // Pega endereco da variavel pra delvover
            if (vArray)
            {
                if (*vLista == '$')
                    vTamValue = 5;

                // Verifica se os tamanhos da dimensao informada e da variavel sao iguais
                if (ixDim != vLista[7])
                {
                    *vErroProc = 21;
                    return 0;
                }

                // Verifica se as posicoes informadas sao iguais ou menores que as da variavel, e ja calcula a nova posicao
                for (ix = (ixDim - 1); ix >= 0; ix--)
                {
                    // Verifica tamanho posicao
                    if ((vDim[ix] + 1) > vLista[ix + 8])
                    {
                        *vErroProc = 21;
                        return 0;
                    }

                    // Calcular a possicao do conteudo da variavel
                    if (!*vPosValueVar)
                        vPosValueVar = vDim[ix] * vTamValue;
                    else
                        vPosValueVar = vPosValueVar * vDim[ix];
                }

                vPosValueVar = vLista + 8 + ixDim + vPosValueVar;
                vEnder = vPosValueVar;
            }
            else
            {
                vPosValueVar = vLista + 3;
                vEnder = vLista;
            }

            // Pelo tipo da variavel, ja retorna na variavel de nome o conteudo da variavel
            if (*vLista == '$')
            {
                vTemp  = (((unsigned long)*(vPosValueVar + 1) << 24) & 0xFF000000);
                vTemp |= (((unsigned long)*(vPosValueVar + 2) << 16) & 0x00FF0000);
                vTemp |= (((unsigned long)*(vPosValueVar + 3) << 8) & 0x0000FF00);
                vTemp |= ((unsigned long)*(vPosValueVar + 4) & 0x000000FF);

                iy = *vPosValueVar;
                iz = 0;

                for (ix = 0; ix < iy; ix++)
                {
                    pVariable[iz++] = *(vTemp + ix); // Numero gerado
                    pVariable[iz] = 0x00;
                }

                pVariable[iz++] = 0x00;
            }
            else
            {
                if (!vArray)
                    vPosValueVar++;

                pVariable[0] = *(vPosValueVar);
                pVariable[1] = *(vPosValueVar + 1);
                pVariable[2] = *(vPosValueVar + 2);
                pVariable[3] = *(vPosValueVar + 3);
                pVariable[4] = 0x00;
            }

            return vEnder;
        }

        if (vArray)
            vLista = *vPosNextVar;
        else
            vLista += 8;

        if ((!vArray && vLista >= pStartArrayVar) || (vArray && vLista >= pStartProg) || *vLista == 0x00)
            break;
    }

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
    char vLenVar = 0;

    vTemp = *nextAddrSimpVar;
    vNextSimpVar = *nextAddrSimpVar;

    vLenVar = strlen(pVariable);

    *vNextSimpVar++ = pType;
    *vNextSimpVar++ = pVariable[0];
    *vNextSimpVar++ = pVariable[1];

    vRet = updateVariable(vNextSimpVar, pValor, pType, 0);
    *nextAddrSimpVar += 8;

    return vRet;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
char updateVariable(unsigned long* pVariable, unsigned char* pValor, char pType, char pOper)
{
    int vNumVal = 0;
    int ix, iz = 0;
    char vbuffer [sizeof(long)*8+1];
    unsigned char* vNextSimpVar;
    unsigned char* vNextString;
    unsigned char* sqtdtam[20];

    vNextSimpVar = pVariable;
    *atuVarAddr = pVariable;

    if (pType == '#' || pType == '%')   // Real ou Inteiro
    {
        if (vNextSimpVar < 0x00802000)
            *vNextSimpVar++ = 0x00;

        *vNextSimpVar++ = pValor[0];
        *vNextSimpVar++ = pValor[1];
        *vNextSimpVar++ = pValor[2];
        *vNextSimpVar++ = pValor[3];
    }
    else // String
    {
        iz = strlen(pValor);    // Tamanho da strings

        // Se for o mesmo tamanho ou menor, usa a mesma posicao
        if (*vNextSimpVar <= iz && pOper)
        {
            vNextString  = (((unsigned long)*(vNextSimpVar + 1) << 24) & 0xFF000000);
            vNextString |= (((unsigned long)*(vNextSimpVar + 2) << 16) & 0x00FF0000);
            vNextString |= (((unsigned long)*(vNextSimpVar + 3) << 8) & 0x0000FF00);
            vNextString |= ((unsigned long)*(vNextSimpVar + 4) & 0x000000FF);
        }
        else
            vNextString = *nextAddrString;

        vNumVal = vNextString;

        for (ix = 0; ix < iz; ix++)
        {
            *vNextString++ = pValor[ix];
        }

        if (*vNextSimpVar > iz || !pOper)
            *nextAddrString = vNextString;

        *vNextSimpVar++ = iz;

        *vNextSimpVar++ = ((vNumVal & 0xFF000000) >>24);
        *vNextSimpVar++ = ((vNumVal & 0x00FF0000) >>16);
        *vNextSimpVar++ = ((vNumVal & 0x0000FF00) >>8);
        *vNextSimpVar++ = (vNumVal & 0x000000FF);
    }

/*    *(vNextSimpVar + 1) = 0x00;
    *(vNextSimpVar + 2) = 0x00;
    *(vNextSimpVar + 3) = 0x00;
    *(vNextSimpVar + 4) = 0x00;*/

    return 0;
}

//--------------------------------------------------------------------------------------
char createVariableArray(unsigned char* pVariable, char pType, unsigned int pNumDim, unsigned int *pDim)
{
    char vRet = 0;
    long vTemp = 0;
    unsigned char* vTempC = &vTemp;
    char vbuffer [sizeof(long)*8+1];
    unsigned char* vNextArrayVar;
    char vLenVar = 0;
    int ix, vTam, vAreaFree = (*pStartProg - *pStartArrayVar);
    unsigned char sqtdtam[20];

    vTemp = *nextAddrArrayVar;
    vNextArrayVar = *nextAddrArrayVar;

    vLenVar = strlen(pVariable);

    *vNextArrayVar++ = pType;
    *vNextArrayVar++ = pVariable[0];
    *vNextArrayVar++ = pVariable[1];
    vTam = 0;

    for (ix = 0; ix < pNumDim; ix++)
    {
        // Somando mais 1, porque 0 = 1 em quantidade e e em posicao (igual ao c)
        pDim[ix] = pDim[ix] + 1;

        // Definir o tamanho do campo de dados do array
        if (vTam == 0)
            vTam = pDim[ix];
        else
            vTam = vTam * pDim[ix];
    }

    if (pType == '$')
        vTam = vTam * 5;
    else
        vTam = vTam * 4;

    if ((vTam + 8 + pNumDim) > vAreaFree)
    {
        *vErroProc = 22;
        return 0;
    }

    // Coloca setup do array
    vTemp = vTemp + vTam + 8 + pNumDim;
    *vNextArrayVar++ = vTempC[0];
    *vNextArrayVar++ = vTempC[1];
    *vNextArrayVar++ = vTempC[2];
    *vNextArrayVar++ = vTempC[3];
    *vNextArrayVar++ = pNumDim;

    for (ix = 0; ix < pNumDim; ix++)
        *vNextArrayVar++ = pDim[ix];

    // Limpa area de dados (zera)
    for (ix = 0; ix < vTam; ix++)
        vNextArrayVar[ix] = 0x00;

    *nextAddrArrayVar = vTemp;

    return 0;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int analiseVariable(unsigned char* vVariable)
{
    unsigned char vToken;

    vToken = vVariable[2];

    if (vToken == '$' || vToken == '#' || vToken == '%')
    {
        if (!findVariable(&vVariable))
        {
            *vErroProc = 4;
            return 0;
        }
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Return a token to input stream.
//--------------------------------------------------------------------------------------
void putback(void)
{
    unsigned char *t;

    if (token_type==COMMAND)    // comando nao faz isso
        return;

    t = token;
    while (*t++)
        pointerRunProg--;
}

//--------------------------------------------------------------------------------------
// Return true if c is a alphabetical (A-Z or a-z).
//--------------------------------------------------------------------------------------
int isalphas(unsigned char c)
{
    if((c>0x40 && c<0x5B) || (c>0x60 && c<0x7B))
       return 1;

    return 0;
}

//--------------------------------------------------------------------------------------
// Return true if c is a number (0-9).
//--------------------------------------------------------------------------------------
int isdigitus(unsigned char c)
{
    if(c>0x2F && c<0x3A)
       return 1;

    return 0;
}

//--------------------------------------------------------------------------------------
// Return true if c is a delimiter.
//--------------------------------------------------------------------------------------
int isdelim(unsigned char c)
{
    if(strchr(" ;,+-<>()/*^=:", c) || c==9 || c=='\r' || c==0 || c>=0xF0)
       return 1;

    return 0;
}

//--------------------------------------------------------------------------------------
// Return 1 if c is space or tab.
//--------------------------------------------------------------------------------------
int iswhite(unsigned char c)
{
    if(c==' ' || c=='\t')
       return 1;

    return 0;
}

//--------------------------------------------------------------------------------------
// Entry point into parser.
//--------------------------------------------------------------------------------------
void getExp(unsigned char *result)
{
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return;

    if(!*token) {
        *vErroProc = 2;
        return;
    }

    level2(result);
    if (*vErroProc) return;

    putback(); /* return last token read to input stream */

    return;
}

//--------------------------------------------------------------------------------------
/*  Add or subtract two terms real/int or string. */
//--------------------------------------------------------------------------------------
void level2(unsigned char *result)
{
    char  op;
    unsigned char hold[50];
    unsigned char valueTypeAnt;
    unsigned int *lresult = result;
    unsigned int *lhold = hold;

    level3(result);
    if (*vErroProc) return;

    op = *token;

    while(op == '+' || op == '-') {
        nextToken();
        if (*vErroProc) return;

        valueTypeAnt = value_type;

        level3(&hold);
        if (*vErroProc) return;

        if (value_type != valueTypeAnt)
        {
            if (value_type == '$' || valueTypeAnt == '$')
            {
                *vErroProc = 16;
                return;
            }
        }

        if (value_type == '$' && op == '+')
            strcat(result,&hold);
        else if (value_type == '$' && op == '-')
        {
            *vErroProc = 16;
            return;
        }
        else
        {
            // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
            if (value_type != valueTypeAnt)
            {
                if (value_type == '#')
                {
                    *lresult = fppReal(*lresult);
                }
                else
                {
                    *lhold = fppReal(*lhold);
                    value_type = '#';
                }
            }
            if (value_type == '#')
                arithReal(op, result, &hold);
            else
                arithInt(op, result, &hold);
        }

        op = *token;
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Multiply or divide two factors real/int. */
//--------------------------------------------------------------------------------------
void level3(unsigned char *result)
{
    char  op;
    unsigned char hold[50];
    unsigned int *lresult = result;
    unsigned int *lhold = hold;
    char value_type_ant=0;

    do
    {
        level31(result);
        if (*vErroProc) return;
        if (*token==0xF3||*token==0xF4)
        {
            nextToken();
            if (*vErroProc) return;
        }
        else
            break;
    }
    while (1);

    op = *token;
    while(op == '*' || op == '/' || op == '%') {
        if (value_type == '$')
        {
            *vErroProc = 16;
            return;
        }

        nextToken();
        if (*vErroProc) return;

        value_type_ant = value_type;

        level4(&hold);
        if (*vErroProc) return;

        if (value_type == '$')
        {
            *vErroProc = 16;
            return;
        }

        // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
        if (value_type != value_type_ant)
        {
            if (value_type == '#')
            {
                *lresult = fppReal(*lresult);
            }
            else
            {
                *lhold = fppReal(*lhold);
                value_type = '#';
            }
        }

        if (value_type == '#')
            arithReal(op, result, &hold);
        else
            arithInt(op, result, &hold);

        op = *token;
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Process logic conditions */
//--------------------------------------------------------------------------------------
void level31(unsigned char *result)
{
    unsigned char  op;
    unsigned char hold[50];
    char value_type_ant=0;
    int *rVal = result;
    int *hVal = hold;

    level32(result);
    if (*vErroProc) return;

    op = *token;
    if(op==0xF3 /* AND */|| op==0xF4 /* OR */) {
        nextToken();
        if (*vErroProc) return;

        level32(&hold);
        if (*vErroProc) return;

        if (op==0xF3)
            *rVal = (*rVal && *hVal);
        else
            *rVal = (*rVal || *hVal);
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Process logic conditions */
//--------------------------------------------------------------------------------------
void level32(unsigned char *result)
{
    unsigned char  op;
    unsigned char hold[50];
    unsigned char value_type_ant=0;
    unsigned int *lresult = result;
    unsigned int *lhold = hold;
    unsigned char sqtdtam[20];

    level4(result);
    if (*vErroProc) return;

    op = *token;
    if(op=='=' || op=='<' || op=='>' || op==0xF5 /* >= */ || op==0xF6 /* <= */|| op==0xF7 /* <> */) {
//        if (op==0xF5 /* >= */ || op==0xF6 /* <= */|| op==0xF7)
//            pointerRunProg++;

        nextToken();
        if (*vErroProc) return;

        value_type_ant = value_type;

        level4(&hold);
        if (*vErroProc) return;

        if ((value_type_ant=='$' && value_type!='$') || (value_type_ant != '$' && value_type == '$'))
        {
            *vErroProc = 16;
            return;
        }

        // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
        if (value_type != value_type_ant)
        {
            if (value_type == '#')
            {
                *lresult = fppReal(*lresult);
            }
            else
            {
                *lhold = fppReal(*lhold);
                value_type = '#';
            }
        }

        if (value_type == '$')
            logicalString(op, result, &hold);
        else if (value_type == '#')
            logicalNumericFloat(op, result, &hold);
        else
            logicalNumericInt(op, result, &hold);
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Process integer exponent real/int. */
//--------------------------------------------------------------------------------------
void level4(unsigned char *result)
{
    unsigned char hold[50];
    unsigned int *lresult = result;
    unsigned int *lhold = hold;
    char value_type_ant=0;

    level5(result);
    if (*vErroProc) return;

    if(*token== '^') {
        if (value_type == '$')
        {
            *vErroProc = 16;
            return;
        }

        nextToken();
        if (*vErroProc) return;

        value_type_ant = value_type;

        level4(&hold);
        if (*vErroProc) return;

        if (value_type == '$')
        {
            *vErroProc = 16;
            return;
        }

        // Se forem diferentes os 2, se for um deles string, da erro, se nao, passa o inteiro para real
        if (value_type != value_type_ant)
        {
            if (value_type == '#')
            {
                *lresult = fppReal(*lresult);
            }
            else
            {
                *lhold = fppReal(*lhold);
                value_type = '#';
            }
        }

        if (value_type == '#')
            arithReal('^', result, &hold);
        else
            arithInt('^', result, &hold);
    }

    return;
}


//--------------------------------------------------------------------------------------
/* Is a unary + or -. */
//--------------------------------------------------------------------------------------
void level5(unsigned char *result)
{
    char  op;

    op = 0;
    if(token_type==DELIMITER && (*token=='+' || *token=='-')) {
        op = *token;
        nextToken();
        if (*vErroProc) return;
    }

    level6(result);
    if (*vErroProc) return;

    if(op)
    {
        if (value_type == '$')
        {
            *vErroProc = 16;
            return;
        }

        if (value_type == '#')
            unaryReal(op, result);
        else
            unaryInt(op, result);
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Process parenthesized expression real/int/string or function. */
//--------------------------------------------------------------------------------------
void level6(unsigned char *result)
{
    if((*token == '(') && (token_type == OPENPARENT)) {
        nextToken();
        if (*vErroProc) return;

        level2(result);
        if(*token != ')')
        {
            *vErroProc = 1;
            return;
        }

        nextToken();
        if (*vErroProc) return;
    }
    else
    {
        primitive(result);
        return;
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Find value of number or variable. */
//--------------------------------------------------------------------------------------
void primitive(unsigned char *result)
{
    unsigned long ix;
    unsigned char* vix = &ix;
    unsigned char* vRet;
    unsigned char sqtdtam[10];

    switch(token_type) {
        case VARIABLE:
            if (strlen(token) < 3)
            {
                value_type=VARTYPEDEFAULT;

                if (strlen(token) == 2 && *(token + 1) < 0x30)
                    value_type = *(token + 1);
            }
            else
            {
                value_type=token[2];
            }

            vRet = find_var(token);
            if (*vErroProc) return;
            if (value_type == '$')  // Tipo da variavel
                strcpy(result,vRet);
            else
            {
                for (ix=0;ix<5;ix++)
                    result[ix]=vRet[ix];
            }
            nextToken();
            if (*vErroProc) return;
            return;
        case QUOTE:
            value_type='$';
            strcpy(result,token);
            nextToken();
            if (*vErroProc) return;
            return;
        case NUMBER:
            if (strchr(token,'.'))  // verifica se eh numero inteiro ou real
            {
                value_type='#'; // Real
                ix=floatStringToFpp(token);
                if (*vErroProc) return;
            }
            else
            {
                value_type='%'; // Inteiro
                ix=atoi(token);
            }

            vix = &ix;

            result[0] = vix[0];
            result[1] = vix[1];
            result[2] = vix[2];
            result[3] = vix[3];

            nextToken();
            if (*vErroProc) return;
            return;
        case COMMAND:
            *token=*pointerRunProg;
            executeToken(*pointerRunProg++);  // Retorno do resultado da funcao deve voltar pela variavel token. value_type tera o tipo de retorno
            if (*vErroProc) return;

            if (value_type == '$')  // Tipo do retorno
                strcpy(result,token);
            else
            {
                for (ix=0;ix<4;ix++)
                {
                    result[ix]=token[ix];
                }
            }

            nextToken();
            if (*vErroProc) return;
            return;
        default:
writeLongSerial("Aqui EEE.666.0-[");
itoa(*pointerRunProg,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(*token,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(token_type,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");
            *vErroProc = 14;
            return;
    }

    return;
}

//--------------------------------------------------------------------------------------
/* Perform the specified arithmetic inteiro. */
//--------------------------------------------------------------------------------------
void arithInt(char o, char *r, char *h)
{
    int t, ex;
    int *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
    int *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
    char* vRval = rVal;

    switch(o) {
        case '-':
            *rVal = *rVal - *hVal;
            break;
        case '+':
            *rVal = *rVal + *hVal;
            break;
        case '*':
            *rVal = *rVal * *hVal;
            break;
        case '/':
            *rVal = (*rVal)/(*hVal);
            break;
        case '^':
            ex = *rVal;
            if(*hVal==0) {
                *rVal = 1;
                break;
            }
            ex = powNum(*rVal,*hVal);
            *rVal = ex;
            break;
    }

    r[0] = vRval[0];
    r[1] = vRval[1];
    r[2] = vRval[2];
    r[3] = vRval[3];
}


//--------------------------------------------------------------------------------------
/* Perform the specified arithmetic real. */
//--------------------------------------------------------------------------------------
void arithReal(char o, char *r, char *h)
{
    int t, ex;
    int *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
    int *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
    char* vRval = rVal;

    switch(o) {
        case '-':
            *rVal = fppSub(*rVal, *hVal);
            break;
        case '+':
            *rVal = fppSum(*rVal, *hVal);
            break;
        case '*':
            *rVal = fppMul(*rVal, *hVal);
            break;
        case '/':
            *rVal = fppDiv(*rVal, *hVal);
            break;
        case '^':
            *rVal = fppPwr(*rVal, *hVal);
            break;
    }
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
void logicalNumericFloat(unsigned char o, char *r, char *h)
{
    int t, ex;
    unsigned long *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
    unsigned long *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));
    unsigned long oCCR = 0;
    unsigned char sqtdtam[20];

    oCCR = fppComp(*rVal, *hVal);

    *rVal = 0;
    value_type = '%';

    switch(o) {
        case '=':
            if (oCCR & 0x04)    // Z=1
                *rVal = 1;
            break;
        case '>':
            if (!(oCCR & 0x08) && !(oCCR & 0x04))   // N=0 e Z=0
                *rVal = 1;
            break;
        case '<':
            if ((oCCR & 0x08) && !(oCCR & 0x04))   // N=1 e Z=0
                *rVal = 1;
            break;
        case 0xF5:  // >=
            if (!(oCCR & 0x08) || (oCCR & 0x04))   // N=0 ou Z=1
                *rVal = 1;
            break;
        case 0xF6:  // <=
            if ((oCCR & 0x08) || (oCCR & 0x04))   // N=1 ou Z=1
                *rVal = 1;
            break;
        case 0xF7:  // <>
            if (!(oCCR & 0x04)) // z=0
                *rVal = 1;
            break;
    }
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
void logicalNumericInt(unsigned char o, char *r, char *h)
{
    int t, ex;
    int *rVal = r; //(int)((int)(r[0] << 24) | (int)(r[1] << 16) | (int)(r[2] << 8) | (int)(r[3]));
    int *hVal = h; //(int)((int)(h[0] << 24) | (int)(h[1] << 16) | (int)(h[2] << 8) | (int)(h[3]));

    switch(o) {
        case '=':
            *rVal = (*rVal == *hVal);
            break;
        case '>':
            *rVal = (*rVal > *hVal);
            break;
        case '<':
            *rVal = (*rVal < *hVal);
            break;
        case 0xF5:
            *rVal = (*rVal >= *hVal);
            break;
        case 0xF6:
            *rVal = (*rVal <= *hVal);
            break;
        case 0xF7:
            *rVal = (*rVal != *hVal);
            break;
    }
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
void logicalString(unsigned char o, char *r, char *h)
{
    int t, ex;
    int *rVal = r;

    ex = strcmp(*r,*h);
    value_type = '%';

    switch(o) {
        case '=':
            *rVal = !ex;
            break;
        case '>':
            *rVal = (ex > 0);
            break;
        case '<':
            *rVal = (ex < 0);
            break;
        case 0xF5:
            *rVal = (ex >= 0);
            break;
        case 0xF6:
            *rVal = (ex <= 0);
            break;
        case 0xF7:
            *rVal = (ex != 0);
            break;
    }

}

//--------------------------------------------------------------------------------------
/* Reverse the sign. */
//--------------------------------------------------------------------------------------
void unaryInt(char o, int *r)
{
    if(o=='-')
        *r = -(*r);
}

//--------------------------------------------------------------------------------------
/* Reverse the sign. */
//--------------------------------------------------------------------------------------
void unaryReal(char o, int *r)
{
    if(o=='-')
    {
        *r = (*r & ((0x7FFFFFFF) | 0x80000000));
    }
}

//--------------------------------------------------------------------------------------
/* Find the value of a variable. */
//--------------------------------------------------------------------------------------
unsigned char* find_var(char *s)
{
    unsigned char vTemp[250];

    *vErroProc = 0x00;

    if(!isalphas(*s)){
        *vErroProc = 4; /* not a variable */
        return 0;
    }

    if (strlen(s) < 3)
    {
        vTemp[0] = *s;
        vTemp[2] = VARTYPEDEFAULT;

        if (strlen(s) == 2 && *(s + 1) < 0x30)
            vTemp[2] = *(s + 1);

        if (strlen(s) == 2 && isalphas(*(s + 1)))
            vTemp[1] = *(s + 1);
        else
            vTemp[1] = 0x00;
    }
    else
    {
        vTemp[0] = *s++;
        vTemp[1] = *s++;
        vTemp[2] = *s;
    }

    if (!findVariable(&vTemp))
    {
        *vErroProc = 4; /* not a variable */
        return 0;
    }

    return vTemp;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
void forPush(for_stack i)
{
    if(*ftos>FOR_NEST)
    {
        *vErroProc = 10;
        return;
    }

    forStack[*ftos]=i;
    *ftos = *ftos + 1;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
for_stack forPop(void)
{
    for_stack i;

    *ftos = *ftos - 1;

    if(*ftos<0)
    {
        *vErroProc = 11;
        return(forStack[0]);
    }

    i=forStack[*ftos];

    return(i);
}

//-----------------------------------------------------------------------------
// GOSUB stack push function.
//-----------------------------------------------------------------------------
void gosubPush(unsigned long i)
{
    if(*gtos>SUB_NEST)
    {
        *vErroProc = 12;
        return;
    }

    gosubStack[*gtos]=i;

    *gtos = *gtos + 1;
}

//-----------------------------------------------------------------------------
// GOSUB stack pop function.
//-----------------------------------------------------------------------------
unsigned long gosubPop(void)
{
    long i;

    *gtos = *gtos - 1;

    if(*gtos<0)
    {
        *vErroProc = 13;
        return 0;
    }

    i=gosubStack[*gtos];

    return i;
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
unsigned int powNum(unsigned int pbase, unsigned char pexp)
{
    unsigned int iz, vRes = pbase;
    pexp--;

    for(iz = 0; iz < pexp; iz++)
    {
        vRes = vRes * pbase;
    }

    return vRes;
}

//-----------------------------------------------------------------------------
// FUNCOES PONTO FLUTUANTE
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Convert from String to Float Single-Precision
//-----------------------------------------------------------------------------
unsigned long floatStringToFpp(unsigned char* pFloat)
{
    unsigned long vFpp;

    *floatBufferStr = pFloat;
    STR_TO_FP();
    vFpp = *floatNumD7;

    return vFpp;
}

//-----------------------------------------------------------------------------
// Convert from Float Single-Precision to String
//-----------------------------------------------------------------------------
int fppTofloatString(unsigned long pFpp, unsigned char *buf)
{
    *floatBufferStr = buf;
    *floatNumD7 = pFpp;
    FP_TO_STR();

    return 0;
}

//-----------------------------------------------------------------------------
// Float Function to SUM D7+D6
//-----------------------------------------------------------------------------
unsigned long fppSum(unsigned long pFppD7, unsigned long pFppD6)
{
    *floatNumD7 = pFppD7;
    *floatNumD6 = pFppD6;
    FPP_SUM();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function to Subtraction D7-D6
//-----------------------------------------------------------------------------
unsigned long fppSub(unsigned long pFppD7, unsigned long pFppD6)
{
    *floatNumD7 = pFppD7;
    *floatNumD6 = pFppD6;
    FPP_SUB();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function to Mul D7*D6
//-----------------------------------------------------------------------------
unsigned long fppMul(unsigned long pFppD7, unsigned long pFppD6)
{
    *floatNumD7 = pFppD7;
    *floatNumD6 = pFppD6;
    FPP_MUL();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function to Division D7/D6
//-----------------------------------------------------------------------------
unsigned long fppDiv(unsigned long pFppD7, unsigned long pFppD6)
{
    *floatNumD7 = pFppD7;
    *floatNumD6 = pFppD6;
    FPP_DIV();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function to Power D7^D6
//-----------------------------------------------------------------------------
unsigned long fppPwr(unsigned long pFppD7, unsigned long pFppD6)
{
    *floatNumD7 = pFppD7;
    *floatNumD6 = pFppD6;
    FPP_PWR();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Convert Float to Int
//-----------------------------------------------------------------------------
long fppInt(unsigned long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_INT();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Convert Int to Float
//-----------------------------------------------------------------------------
unsigned long fppReal(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_FPP();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return SIN
//-----------------------------------------------------------------------------
unsigned long fppSin(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_SIN();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return COS
//-----------------------------------------------------------------------------
unsigned long fppCos(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_COS();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return TAN
//-----------------------------------------------------------------------------
unsigned long fppTan(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_TAN();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return SIN Hiperb
//-----------------------------------------------------------------------------
unsigned long fppSinH(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_SINH();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return COS Hiperb
//-----------------------------------------------------------------------------
unsigned long fppCosH(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_COSH();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return TAN Hiperb
//-----------------------------------------------------------------------------
unsigned long fppTanH(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_TANH();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return Sqrt
//-----------------------------------------------------------------------------
unsigned long fppSqrt(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_SQRT();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return TAN Hiperb
//-----------------------------------------------------------------------------
unsigned long fppLn(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_LN();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return Exp
//-----------------------------------------------------------------------------
unsigned long fppExp(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_EXP();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return Exp
//-----------------------------------------------------------------------------
unsigned long fppAbs(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_ABS();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function Return Exp
//-----------------------------------------------------------------------------
unsigned long fppNeg(long pFppD7)
{
    *floatNumD7 = pFppD7;
    FPP_NEG();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Float Function to Comp 2 float values D7-D6
//-----------------------------------------------------------------------------
unsigned long fppComp(unsigned long pFppD7, unsigned long pFppD6)
{
    *floatNumD7 = pFppD7;
    *floatNumD6 = pFppD6;

    FPP_CMP();

    return *floatNumD7;
}

//-----------------------------------------------------------------------------
// Return Rand number
//-----------------------------------------------------------------------------
unsigned long gerRand(void)
{
    GER_RAND();

    return *randSeed;
}

//-----------------------------------------------------------------------------
// FUNCOES BASIC
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Joga pra tela Texto.
// Syntaxe:
//      Print "<Texto>"/<value>[, "<Texto>"/<value>][; "<Texto>"/<value>]
//-----------------------------------------------------------------------------
int basPrint(void)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    long *lVal = answer;
    int  *iVal = answer;
    int len=0, spaces;
    char last_delim, last_token_type = 0;
    unsigned char sqtdtam[10];

    do {
        nextToken();
        if (*vErroProc) return 0;

        if(tok==EOL || tok==FINISHED)
            break;

        if(token_type==QUOTE) { /* is string */
            printText(token);

            nextToken();
            if (*vErroProc) return 0;
        }
        else if (*token!=':') { /* is expression */
            last_token_type = token_type;

            putback();

            getExp(&answer);
            if (*vErroProc) return 0;

            if (value_type != '$')
            {
                if (value_type == '#')
                {
                    // Real
                    fppTofloatString(*lVal, answer);
                    if (*vErroProc) return 0;
                }
                else
                {
                    // Inteiro
                    itoa(*iVal, answer, 10);
                }
            }

            printText(answer);

            nextToken();
            if (*vErroProc) return 0;
        }

        last_delim = *token;

        if(*token==',') {
            /* compute number of spaces to move to next tab */
            spaces = 8 - (len % 8);
            while(spaces) {
                printChar(' ',1);
                spaces--;
            }
        }
        else if(*token==';' || *token=='+')
            /* do nothing */;
        else if(*token==':')
            pointerRunProg--;
        else if(tok!=EOL && tok!=FINISHED && *token!=':')
        {
            *vErroProc = 14;
            return 0;
        }
    } while (*token==';' || *token==',' || *token=='+');

    if(tok==EOL || tok==FINISHED || *token==':') {
        if(last_delim != ';' && last_delim!=',')
            printText("\r\n");
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
int basChr(void)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    long *lVal = answer;
    int  *iVal = answer;
    int len=0, spaces;
    char last_delim, last_token_type = 0;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        last_token_type = token_type;

        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
        else
        {
            // Inteiro
            if (*iVal<0 || *iVal>255)
            {
                *vErroProc = 5;
                return 0;
            }
        }
    }

    last_delim = *token;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    token[0]=(char)*iVal;
    token[1]=0x00;
    value_type='$';

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
int basVal(void)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  iVal = answer;
    int vValue = 0;
    int len=0, spaces;
    char last_delim, last_value_type=' ', last_token_type = 0;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        if (strchr(token,'.'))  // verifica se eh numero inteiro ou real
        {
            last_value_type='#'; // Real
            iVal=floatStringToFpp(token);
            if (*vErroProc) return 0;
        }
        else
        {
            last_value_type='%'; // Inteiro
            iVal=atoi(token);
        }
    }
    else { /* is expression */
        last_token_type = token_type;

        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type != '$')
        {
            *vErroProc = 16;
            return 0;
        }

        if (strchr(answer,'.'))  // verifica se eh numero inteiro ou real
        {
            last_value_type='#'; // Real
            iVal=floatStringToFpp(answer);
            if (*vErroProc) return 0;
        }
        else
        {
            last_value_type='%'; // Inteiro
            iVal=atoi(answer);
        }
    }

    last_delim = *token;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    token[0]=((int)(iVal & 0xFF000000) >> 24);
    token[1]=((int)(iVal & 0x00FF0000) >> 16);
    token[2]=((int)(iVal & 0x0000FF00) >> 8);
    token[3]=(iVal & 0x000000FF);

    value_type = last_value_type;

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o caracter ligado ao codigo ascii passado
// Syntaxe:
//      CHR$(<codigo ascii>)
//-----------------------------------------------------------------------------
int basStr(void)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[50];
    long *lVal = answer;
    int  *iVal = answer;
    int len=0, spaces;
    char last_delim, last_token_type = 0;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        last_token_type = token_type;

        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    last_delim = *token;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    if (value_type=='#')    // real
    {
        fppTofloatString(*iVal,token);
        if (*vErroProc) return 0;
    }
    else    // Inteiro
    {
        itoa(*iVal,token,10);
    }

    value_type='$';

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve o tamanho da string
// Syntaxe:
//      LEN(<string>)
//-----------------------------------------------------------------------------
int basLen(void)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int iVal = 0;
    int vValue = 0;
    int len=0, spaces;
    char last_delim, last_token_type = 0;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        iVal=strlen(token);
    }
    else { /* is expression */
        last_token_type = token_type;

        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type != '$')
        {
            *vErroProc = 16;
            return 0;
        }

        iVal=strlen(answer);
    }

    last_delim = *token;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    token[0]=((int)(iVal & 0xFF000000) >> 24);
    token[1]=((int)(iVal & 0x00FF0000) >> 16);
    token[2]=((int)(iVal & 0x0000FF00) >> 8);
    token[3]=(iVal & 0x000000FF);

    value_type='%';

    return 0;
}

//-----------------------------------------------------------------------------
// Devolve qtd memoria usuario disponivel
// Syntaxe:
//      FRE(0)
//-----------------------------------------------------------------------------
int basFre(void)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[50];
    long *lVal = answer;
    int  *iVal = answer;
    long vTotal = 0;
    char vbuffer [sizeof(long)*8+1];
    int len=0, spaces;
    char last_delim;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (*iVal!=0)
        {
            *vErroProc = 5;
            return 0;
        }
    }

    last_delim = *token;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

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

    return 0;
}

//-----------------------------------------------------------------------------
// Raiz Quadrada Numero
// Syntaxe:
//      SQRT(<Number>)
//-----------------------------------------------------------------------------
int basSqrt(void)
{
    unsigned long vReal = 0, vResult = 0;
    unsigned char sqtdtam[20];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }
    else if (value_type != '#')
    {
        value_type='#'; // Real
        vReal=fppReal(vReal);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vResult = fppSqrt(vReal);

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    value_type = '#';

    return 0;
}

//-----------------------------------------------------------------------------
// Seno Numero
// Syntaxe:
//      SQRT(<Number>)
//-----------------------------------------------------------------------------
int basSin(void)
{
    unsigned long vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }
    else if (value_type != '#')
    {
        value_type='#'; // Real
        vReal=fppReal(vReal);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vResult = fppSin(vReal);

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    value_type = '#';

    return 0;
}

//-----------------------------------------------------------------------------
// Coseno Numero
// Syntaxe:
//      COS(<Number>)
//-----------------------------------------------------------------------------
int basCos(void)
{
    unsigned long vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }
    else if (value_type != '#')
    {
        value_type='#'; // Real
        vReal=fppReal(vReal);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vResult = fppCos(vReal);

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    value_type = '#';

    return 0;
}

//-----------------------------------------------------------------------------
// Tangente Angulo
// Syntaxe:
//      TAN(<Number>)
//-----------------------------------------------------------------------------
int basTan(void)
{
    unsigned long vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }
    else if (value_type != '#')
    {
        value_type='#'; // Real
        vReal=fppReal(vReal);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vResult = fppTan(vReal);

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    value_type = '#';

    return 0;
}

//-----------------------------------------------------------------------------
// Logaritimico Natural de um numero
// Syntaxe:
//      LOG(<Number>)
//-----------------------------------------------------------------------------
int basLn(void)
{
    unsigned long vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }
    else if (value_type != '#')
    {
        value_type='#'; // Real
        vReal=fppReal(vReal);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vResult = fppLn(vReal);

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    value_type = '#';

    return 0;
}

//-----------------------------------------------------------------------------
// Exponencial de um Numero
// Syntaxe:
//      EXP(<Number>)
//-----------------------------------------------------------------------------
int basExp(void)
{
    unsigned long vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }
    else if (value_type != '#')
    {
        value_type='#'; // Real
        vReal=fppReal(vReal);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vResult = fppExp(vReal);

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    value_type = '#';

    return 0;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int basAsc(void)
{
    unsigned char answer[200];
    int  iVal = answer;
    char last_delim;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        if (strlen(token)>1)
        {
            *vErroProc = 6;
            return 0;
        }

        iVal = *token;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type != '$')
        {
            *vErroProc = 16;
            return 0;
        }

        iVal = *answer;
    }

    last_delim = *token;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    token[0]=((int)(iVal & 0xFF000000) >> 24);
    token[1]=((int)(iVal & 0x00FF0000) >> 16);
    token[2]=((int)(iVal & 0x0000FF00) >> 8);
    token[3]=(iVal & 0x000000FF);

    value_type = '%';

    return 0;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int basLeftRightMid(char pTipo)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200], vTemp[200];
    int vqtd = 0, vstart = 0;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        strcpy(vTemp, token);
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type != '$')
        {
            *vErroProc = 16;
            return 0;
        }

        strcpy(vTemp, answer);
    }

    nextToken();
    if (*vErroProc) return 0;

    // Deve ser uma virgula para Receber a qtd, e se for mid = a posiao incial
    if (*token!=',')
    {
        *vErroProc = 18;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        if (pTipo=='M')
        {
            getExp(&vstart);
            vqtd=strlen(vTemp);
        }
        else
            getExp(&vqtd);

        if (*vErroProc) return 0;

        if (value_type == '$')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    if (pTipo == 'M')
    {
        // Deve ser uma virgula para Receber a qtd
        if (*token==',')
        {
            nextToken();
            if (*vErroProc) return 0;

            if(token_type==QUOTE) { /* is string, error */
                *vErroProc = 16;
                return 0;
            }
            else { /* is expression */
                //putback();

                getExp(&vqtd);

                if (*vErroProc) return 0;

                if (value_type == '$')
                {
                    *vErroProc = 16;
                    return 0;
                }
            }
        }
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    if (vqtd > strlen(vTemp))
    {
        if (pTipo=='M')
            vqtd = (strlen(vTemp) - vstart) + 1;
        else
            vqtd = strlen(vTemp);
    }

    if (pTipo == 'L') // Left$
    {
        for (ix = 0; ix < vqtd; ix++)
            token[ix] = vTemp[ix];
        token[ix] = 0x00;
    }
    else if (pTipo == 'R') // Right$
    {
        iy = strlen(vTemp);
        iz = (iy - vqtd);
        iw = 0;
        for (ix = iz; ix < iy; ix++)
            token[iw++] = vTemp[ix];
        token[iw]=0x00;
    }
    else  // Mid$
    {
        iy = strlen(vTemp);
        iw=0;
        vstart--;
        for (ix = vstart; ix < iy; ix++)
        {
            if (iw <= iy && vqtd-- > 0)
                token[iw++] = vTemp[ix];
            else
                break;
        }
        token[iw] = 0x00;
    }

    value_type = '$';

    return 0;
}

//--------------------------------------------------------------------------------------
//  Comandos de memoria
//      Leitura de Memoria:   peek(<endereco>)
//      Gravacao em endereco: poke(<endereco>,<byte>)
//--------------------------------------------------------------------------------------
int basPeekPoke(char pTipo)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200], vTemp[200];
    unsigned char *vEnd = 0;
    unsigned int vByte = 0;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&vEnd);

        if (*vErroProc) return 0;

        if (value_type == '$')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    // Deve ser uma virgula para Receber a qtd
    if (pTipo == 'W')
    {
        if (*token==',')
        {
            nextToken();
            if (*vErroProc) return 0;

            if(token_type==QUOTE) { /* is string, error */
                *vErroProc = 16;
                return 0;
            }
            else { /* is expression */
                //putback();

                getExp(&vByte);

                if (*vErroProc) return 0;

                if (value_type == '$')
                {
                    *vErroProc = 16;
                    return 0;
                }
            }
        }
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    if (pTipo == 'R')
    {
        token[0] = 0;
        token[1] = 0;
        token[2] = 0;
        token[3] = *vEnd;
    }
    else
    {
        *vEnd = (char)vByte;
    }

    value_type = '%';

    return 0;
}


//--------------------------------------------------------------------------------------
//  Array (min 2 dimensoes)
//      Sintaxe:
//              DIM (<dim 1>,<dim 2>[,<dim 3>,<dim 4>,...,<dim n>])
//--------------------------------------------------------------------------------------
int basDim(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200], vTemp[200];
    unsigned char sqtdtam[10];
    unsigned int vDim[88], ixDim = 0;
    unsigned char var[3], varTipo;
    long vRetFV;

    nextToken();
    if (*vErroProc) return 0;

    // Pega o nome da variavel
    if(!isalphas(*token)) {
        *vErroProc = 4;
        return 0;
    }

    if (strlen(token) < 3)
    {
        var[0] = *token;
        varTipo = VARTYPEDEFAULT;

        if (strlen(token) == 2 && *(token + 1) < 0x30)
            varTipo = *(token + 1);

        if (strlen(token) == 2 && isalphas(*(token + 1)))
            var[1] = *(token + 1);
        else
            var[1] = 0x00;

        var[2] = varTipo;
    }
    else
    {
        var[0] = *token;
        var[1] = *(token + 1);
        var[2] = *(token + 2);
        iz = strlen(token) - 1;
        varTipo = var[2];
    }

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter depois da variavel, deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    do
    {
        nextToken();
        if (*vErroProc) return 0;

        if(token_type==QUOTE) { /* is string, error */
            *vErroProc = 16;
            return 0;
        }
        else { /* is expression */
            putback();

            getExp(&vDim[ixDim]);
            if (*vErroProc) return 0;

            if (value_type == '$' || value_type == '#')
            {
                *vErroProc = 16;
                return 0;
            }

            ixDim++;
        }

        if (*token == ',')
            pointerRunProg = pointerRunProg + 1;
        else
            break;
    } while(1);

    // Deve ter pelo menos 1 elemento
    if (ixDim < 1)
    {
        *vErroProc = 21;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    /* assign the value */
    vRetFV = findVariable(var);
    // Se nao existe a variavel, cria variavel e atribui o valor
    if (!vRetFV)
        createVariableArray(var, varTipo, ixDim, vDim);
    else
    {
        *vErroProc = 23;
        return 0;
    }

    return 0;
}

//--------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------
int basIf(void)
{
    unsigned int vCond = 0;

    getExp(&vCond); // get target value

    if(value_type=='$'||value_type=='#') {
        *vErroProc = 16;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if (*token!=0x83)
    {
        *vErroProc = 8;
        return 0;
    }

    if (vCond)
    {
        // Vai pro proximo comando apos o Then e continua
        pointerRunProg++;

        // simula ":" para continuar a execucao
        *doisPontos = 1;
    }
    else
    {
        // Ignora toda a linha
        while (*pointerRunProg++);
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Atribuir valor a uma variavel - comando opcional.
// Syntaxe:
//            [LET] <variavel> = <string/valor>
//--------------------------------------------------------------------------------------
int basLet(void)
{
    long vRetFV, iz;
    unsigned char var[3], varTipo;
    unsigned char value[200];
    unsigned long *lValue = &value;
    unsigned char sqtdtam[10];
    unsigned char vArray = 0;

    /* get the variable name */
    nextToken();
    if (*vErroProc) return 0;

    if(!isalphas(*token)) {
        *vErroProc = 4;
        return 0;
    }

    if (strlen(token) < 3)
    {
        var[0] = *token;
        varTipo = VARTYPEDEFAULT;

        if (strlen(token) == 2 && *(token + 1) < 0x30)
            varTipo = *(token + 1);

        if (strlen(token) == 2 && isalphas(*(token + 1)))
            var[1] = *(token + 1);
        else
            var[1] = 0x00;

        var[2] = varTipo;
    }
    else
    {
        var[0] = *token;
        var[1] = *(token + 1);
        var[2] = *(token + 2);
        iz = strlen(token) - 1;
        varTipo = var[2];
    }

    // verifica se é array (abre parenteses no inicio)
    if (*pointerRunProg == 0x28)
    {
        vRetFV = findVariable(var);
        if (*vErroProc) return 0;

        if (!vRetFV)
        {
            *vErroProc = 4;
            return 0;
        }

        vArray = 1;
    }

    // get the equals sign
    nextToken();
    if (*vErroProc) return 0;

    if(*token!='=') {
        *vErroProc = 3;
        return 0;
    }
    /* get the value to assign to var */
    getExp(&value);

    if (varTipo == '#' && value_type != '#')
        *lValue = fppReal(*lValue);

    /* assign the value */
    if (!vArray)
    {
        vRetFV = findVariable(var);
        // Se nao existe a variavel, cria variavel e atribui o valor
        if (!vRetFV)
            createVariable(var, value, varTipo);
        else // se ja existe, altera
            updateVariable((vRetFV + 3), value, varTipo, 1);
    }
    else
    {
        updateVariable(vRetFV, value, varTipo, 1);
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Entrada pelo teclado de numeros/caracteres ateh teclar ENTER (INPUT)
// Entrada pelo teclado de um unico caracter ou numero (GET)
// Entrada dos dados de acordo com o tipo de variavel $(qquer), %(Nums), #(Nums & '.')
// Syntaxe:
//          INPUT ["texto",]<variavel> : A variavel sera criada se nao existir
//          GET <variavel> : A variavel sera criada se nao existir
//--------------------------------------------------------------------------------------
int basInputGet(unsigned char pSize)
{
    unsigned char vAspas = 0, vVirgula = 0, vTemp[250];
    char sNumLin [sizeof(short)*8+1];
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200], vtec;
    long *lVal = answer;
    int  *iVal = answer;
    char vTemTexto = 0;
    int len=0, spaces;
    char last_delim;
    unsigned char *buffptr = vbuf;
    long vRetFV;
    unsigned char var[3], varTipo;

    do {
        nextToken();
        if (*vErroProc) return 0;

        if(tok==EOL || tok==FINISHED)
            break;

        if(token_type==QUOTE) { /* is string */
            if (vTemTexto)
            {
                *vErroProc = 14;
                return 0;
            }

            printText(token);

            nextToken();
            if (*vErroProc) return 0;

            vTemTexto = 1;
        }
        else { /* is expression */
            // Verifica se começa com letra, pois tem que ser uma variavel agora
            if(!isalphas(*token))
            {
                *vErroProc = 4;
                return 0;
            }

            if (strlen(token) < 3)
            {
                var[0] = *token;
                varTipo = VARTYPEDEFAULT;

                if (strlen(token) == 2 && *(token + 1) < 0x30)
                    varTipo = *(token + 1);

                if (strlen(token) == 2 && isalphas(*(token + 1)))
                    var[1] = *(token + 1);
                else
                    var[1] = 0x00;

                var[2] = varTipo;
            }
            else
            {
                var[0] = *token;
                var[1] = *(token + 1);
                var[2] = *(token + 2);
                iz = strlen(token) - 1;
                varTipo = var[2];
            }

            if (pSize == 1)
            {
                // GET
                vtec = 0;
                *videoCursorShow = 0;
                *videoCursorBlink = 0;
                while (!vtec)
                {
                    vtec = inputLine(255,varTipo);

                    if (varTipo!='$')
                    {
                        if (!isdigitus(vtec))
                            vtec = 0;
                    }
                }
                *videoCursorBlink = 1;

                answer[0] = vtec;
                answer[1] = 0x00;
            }
            else
            {
                // INPUT
                vtec = inputLine(255,varTipo);

                if (*vbuf != 0x00 && (vtec == 0x0D || vtec == 0x0A))
                {
                    ix = 0;

                    while (*buffptr)
                    {
                        answer[ix++] = *buffptr++;
                        answer[ix] = 0x00;
                    }
                }
                else
                    answer[0] = 0x00;

                printText("\r\n");
            }

            if (varTipo!='$')
            {
                if (varTipo=='#')  // verifica se eh numero inteiro ou real
                {
                    iVal=floatStringToFpp(answer);
                    if (*vErroProc) return 0;
                }
                else
                {
                    iVal=atoi(answer);
                }

                answer[0]=((int)(iVal & 0xFF000000) >> 24);
                answer[1]=((int)(iVal & 0x00FF0000) >> 16);
                answer[2]=((int)(iVal & 0x0000FF00) >> 8);
                answer[3]=(char)(iVal & 0x000000FF);
            }

            /* assign the value */
            vRetFV = findVariable(var);
            // Se nao existe variavel e inicio sentenca, cria variavel e atribui o valor
            if (!vRetFV)
                createVariable(var, answer, varTipo);
            else // se ja existe, altera
                updateVariable((vRetFV + 3), answer, varTipo, 1);
            vTemTexto=2;
            nextToken();
            if (*vErroProc) return 0;
        }

        last_delim = *token;

        if(vTemTexto==1 && *token==';')
            /* do nothing */;
        else if(vTemTexto==1 && *token!=';')
        {
            *vErroProc = 14;
            return 0;
        }
        else if(vTemTexto!=1 && *token==';')
        {
            *vErroProc = 14;
            return 0;
        }
        else if(tok!=EOL && tok!=FINISHED && *token!=':')
        {
            *vErroProc = 14;
            return 0;
        }
    } while (*token==';');

    return 0;
}

//--------------------------------------------------------------------------------------
char forFind(for_stack *i, unsigned char* endLastVar)
{
    int ix;
    unsigned char sqtdtam[10];

    for(ix = 0; ix < *ftos; ix++)
    {
        if (forStack[ix].nameVar[0] == endLastVar[1] && forStack[ix].nameVar[1] == endLastVar[2])
        {
            *i = forStack[ix];

            return ix;
        }
        else if (!forStack[ix].nameVar[0])
            return -1;
    }

    return -1;
}

//--------------------------------------------------------------------------------------
// Inicio do laco de repeticao
// Syntaxe:
//          FOR <variavel> = <inicio> TO <final> [STEP <passo>] : A variavel sera criada se nao existir
//--------------------------------------------------------------------------------------
int basFor(void)
{
    for_stack i;
    int value=0;
    int *endVarCont;
    unsigned char* endLastVar;
    unsigned char sqtdtam[10];
    char vRetVar = -1;

    basLet();
    if (*vErroProc) return 0;

    endLastVar = *atuVarAddr - 3;
    endVarCont = *atuVarAddr + 1;

    vRetVar = forFind(&i, endLastVar);

    if (vRetVar < 0)
    {
        i.nameVar[0]=endLastVar[1];
        i.nameVar[1]=endLastVar[2];
        i.nameVar[2]=endLastVar[0];
    }

    i.step=1;
    i.endVar=endVarCont;

    nextToken();
    if (*vErroProc) return 0;

    if(tok!=0x86) /* read and discard the TO */
    {
        *vErroProc = 9;
        return 0;
    }

    pointerRunProg++;

    getExp(&i.target); /* get target value */

    if(tok==0x88) /* read STEP */
    {
        pointerRunProg++;

        getExp(&i.step); /* get target value */
    }

    endVarCont=i.endVar;

    /* if loop can execute at least once, push info on stack */
    if((i.step > 0 && *endVarCont <= i.target) || (i.step < 0 && *endVarCont >= i.target))
    {
        if (*pointerRunProg==0x3A)  // ":"
            i.progPosPointerRet = pointerRunProg;
        else
            i.progPosPointerRet = *nextAddr;

        if (vRetVar < 0)
            forPush(i);
        else
        {
            forStack[vRetVar].target = i.target;
            forStack[vRetVar].step = i.step;
            forStack[vRetVar].endVar = i.endVar;
            forStack[vRetVar].progPosPointerRet = i.progPosPointerRet;
        }
    }
    else  /* otherwise, skip loop code alltogether */
    {
        while(*pointerRunProg != 0x87) // Search NEXT
        {
            pointerRunProg++;

            // Verifica se chegou no next
            if (*pointerRunProg == 0x87)
            {
                // Verifica se tem letra, se nao tiver, usa ele
                if (*(pointerRunProg + 1)!=0x00)
                {
                    // verifica se é a mesma variavel que ele tem
                    if (*(pointerRunProg + 1) != i.nameVar[0])
                        pointerRunProg++;
                    else
                    {
                        if (*(pointerRunProg + 2) != i.nameVar[1] && *(pointerRunProg + 2) != i.nameVar[2])
                            pointerRunProg++;
                    }
                }
            }
        }
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Final/Incremento do Laco de repeticao, voltando para o commando/linha após o FOR
// Syntaxe:
//          NEXT [<variavel>]
//--------------------------------------------------------------------------------------
int basNext(void)
{
    unsigned char sqtdtam[10];
    for_stack i;
    int *endVarCont;
    unsigned char answer[3];
    char vRetVar = -1;

/*writeLongSerial("Aqui 777.666.1-[");
itoa(*pointerRunProg,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(*pointerRunProg,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");*/
    if (isalphas(*pointerRunProg))
    {
        // procura pela variavel no forStack
        nextToken();
        if (*vErroProc) return 0;

        if (token_type != VARIABLE)
        {
            *vErroProc = 4;
            return 0;
        }

        answer[0] = token[2];
        answer[1] = token[0];
        answer[2] = token[1];

        vRetVar = forFind(&i,answer);

        if (vRetVar < 0)
        {
            *vErroProc = 11;
            return 0;
        }
    }
    else // faz o pop da pilha
        i = forPop(); // read the loop info

    endVarCont = i.endVar;
    *endVarCont = *endVarCont + i.step; // inc/dec, using step, control variable

    if((i.step > 0 && *endVarCont>i.target) || (i.step < 0 && *endVarCont<i.target))
        return 0 ;  // all done

    *changedPointer = i.progPosPointerRet;  // loop

    if (vRetVar < 0)
        forPush(i);  // otherwise, restore the info

    return 0;
}

//--------------------------------------------------------------------------------------
// Salta para uma linha, sem retorno
// Syntaxe:
//          GOTO <num.linha>
//--------------------------------------------------------------------------------------
int basGoto(void)
{
    unsigned long vNextAddrGoto = 0;
    unsigned int vNumLin = 0;
    unsigned char *pAtu = *nextAddrLine;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED)
    {
        *vErroProc = 15;
        return 0;
    }

    putback();

    getExp(&vNumLin); // get target valuedel 20

    if(value_type=='$'||value_type=='#') {
        *vErroProc = 17;
        return 0;
    }

    vNextAddrGoto = findNumberLine(vNumLin, 0, 0);

    if (vNextAddrGoto > 0)
    {
        pAtu = vNextAddrGoto;

        if (((*(pAtu + 3) << 8) | *(pAtu + 4)) == vNumLin)
        {
            *changedPointer = vNextAddrGoto;
            return 0;
        }
        else
        {
            *vErroProc = 7;
            return 0;
        }
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Salta para uma linha e guarda a posicao atual para voltar
// Syntaxe:
//          GOSUB <num.linha>
//--------------------------------------------------------------------------------------
int basGosub(void)
{
    unsigned long vNextAddrGoto = 0;
    unsigned int vNumLin = 0;
    unsigned char *pAtu = *nextAddrLine;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED)
    {
        *vErroProc = 15;
        return 0;
    }

    putback();

    getExp(&vNumLin); // get target valuedel 20

    if(value_type=='$'||value_type=='#') {
        *vErroProc = 17;
        return 0;
    }

    vNextAddrGoto = findNumberLine(vNumLin, 0, 0);

    if (vNextAddrGoto > 0)
    {
        pAtu = vNextAddrGoto;

        if (((*(pAtu + 3) << 8) | *(pAtu + 4)) == vNumLin)
        {
            gosubPush(*nextAddr);
            *changedPointer = vNextAddrGoto;
            return 0;
        }
        else
        {
            *vErroProc = 7;
            return 0;
        }
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Retorna de um Gosub
// Syntaxe:
//          RETURN
//--------------------------------------------------------------------------------------
int basReturn(void)
{
    long i;

    i = gosubPop();

    *changedPointer = i;

    return 0;
}

//--------------------------------------------------------------------------------------
// Retorna um numero real como inteiro
// Syntaxe:
//          INT(<number real>)
//--------------------------------------------------------------------------------------
int basInt(void)
{
    int vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    if (value_type == '#')
        vResult = fppInt(vReal);
    else
        vResult = vReal;

    value_type='%';

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    return 0;
}

//--------------------------------------------------------------------------------------
// Retorna um numero real como inteiro
// Syntaxe:
//          INT(<number real>)
//--------------------------------------------------------------------------------------
int basAbs(void)
{
    int vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 14;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    if (value_type == '#')
        vResult = fppAbs(vReal);
    else
    {
        vResult = vReal;

        if (vResult < 1)
            vResult = vResult * (-1);
    }

    value_type='%';

    token[0]=((int)(vResult & 0xFF000000) >> 24);
    token[1]=((int)(vResult & 0x00FF0000) >> 16);
    token[2]=((int)(vResult & 0x0000FF00) >> 8);
    token[3]=(vResult & 0x000000FF);

    return 0;
}

//--------------------------------------------------------------------------------------
// Retorna um numero randomicamente
// Syntaxe:
//          RND(<number>)
//--------------------------------------------------------------------------------------
int basRnd(void)
{
    unsigned long vRand;
    int vReal = 0, vResult = 0;

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    putback();

    getExp(&vReal); //

    if(value_type == '$')  // mudar de == '#' para != '#' quando single point estiver funcionando
    {
        *vErroProc = 16;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    if (vReal == 0)
    {
        vRand = *randSeed;
    }
    else if (vReal < 0)
    {
        vRand - 0;
    }
    else if (vReal <= 1)
    {
        vRand = *(vmfp + Reg_TADR);
        vRand = vRand * (*randSeed);
        vRand = (vRand >> 8);
        vRand -= 0x466;
        vRand += 209;
        *randSeed = vRand;
    }
    else if (vReal > 1)
    {
        *vErroProc = 5;
        return 0;
    }

    value_type='#';

    token[0]=((int)(vRand & 0xFF000000) >> 24);
    token[1]=((int)(vRand & 0x00FF0000) >> 16);
    token[2]=((int)(vRand & 0x0000FF00) >> 8);
    token[3]=(vRand & 0x000000FF);

    return 0;
}

//--------------------------------------------------------------------------------------
// Seta posicao vertical (linha em texto e y em grafico)
// Syntaxe:
//          VTAB <numero>
//--------------------------------------------------------------------------------------
int basVtab(void)
{
    unsigned int vRow = 0;

    getExp(&vRow);

    if(value_type=='$'||value_type=='#') {
        *vErroProc = 16;
        return 0;
    }

    vdp_set_cursor(*videoCursorPosColX, vRow);

    return 0;
}

//--------------------------------------------------------------------------------------
// Seta posicao horizontal (coluna em texto e x em grafico)
// Syntaxe:
//          HTAB <numero>
//--------------------------------------------------------------------------------------
int basHtab(void)
{
    unsigned int vColumn = 0;

    getExp(&vColumn);

    if(value_type=='$'||value_type=='#') {
        *vErroProc = 16;
        return 0;
    }

    vdp_set_cursor(vColumn, *videoCursorPosRowY);

    return 0;
}

//--------------------------------------------------------------------------------------
// Finaliza o programa sem erro
// Syntaxe:
//          END
//--------------------------------------------------------------------------------------
int basEnd(void)
{
    *nextAddr = 0;

    return 0;
}

//--------------------------------------------------------------------------------------
// Finaliza o programa com erro
// Syntaxe:
//          STOP
//--------------------------------------------------------------------------------------
int basStop(void)
{
    *vErroProc = 1;

    return 0;
}

//--------------------------------------------------------------------------------------
// Retorna 'n' Espaços
// Syntaxe:
//          SPC <numero>
//--------------------------------------------------------------------------------------
int basSpc(void)
{
    unsigned int vSpc = 0;
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vTab, vColumn;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vSpc=(char)*iVal;

    for (ix = 0; ix < vSpc; ix++)
        token[ix] = ' ';

    token[ix] = 0;
    value_type = '$';

    return 0;
}

//--------------------------------------------------------------------------------------
// Advance 'n' columns
// Syntaxe:
//          TAB <numero>
//--------------------------------------------------------------------------------------
int basTab(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vTab, vColumn;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    vTab=(char)*iVal;

    vColumn = *videoCursorPosColX;

    if (vTab>vColumn)
    {
        vColumn = vColumn + vTab;

        while (vColumn>*vdpMaxCols)
        {
            vColumn = vColumn - *vdpMaxCols;
            if (*videoCursorPosRowY < *vdpMaxRows)
                *videoCursorPosRowY += 1;
        }

        vdp_set_cursor(vColumn, *videoCursorPosRowY);
    }

    *token = ' ';
    value_type='$';

    return 0;
}

//--------------------------------------------------------------------------------------
// Load basic program in memory, throught xmodem protocol
// Syntaxe:
//          XBASLOAD
//--------------------------------------------------------------------------------------
int basXBasLoad(void)
{
    unsigned char vRet = 0;
    unsigned char vByte = 0;
    unsigned char *vTemp = pStartXBasLoad;
    unsigned char *vBufptr = vbuf;

    printText("Loading Basic Program...\r\n");

    // Carrega programa em outro ponto da memoria
    vRet = loadSerialToMem("880000",0);

    // Se tudo OK, tokeniza como se estivesse sendo digitado
    if (!vRet)
    {
        printText("Done.\r\n");
        printText("Processing...\r\n");

        while (1)
        {
            vByte = *vTemp++;

            if (vByte != 0x1A)
            {
                if (vByte != 0xD && vByte != 0x0A)
                    *vBufptr++ = vByte;
                else
                {
                    vTemp++;
                    *vBufptr = 0x00;
                    vBufptr = vbuf;
                    processLine();
                }
            }
            else
                break;
        }

        printText("Done.\r\n");
    }
    else
    {
        if (vRet == 0xFE)
            *vErroProc = 19;
        else
            *vErroProc = 20;
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Text Screen Mode (40 cols x 24 rows)
// Syntaxe:
//          TEXT
//--------------------------------------------------------------------------------------
int basText(void)
{
    *fgcolor = VDP_WHITE;
    *bgcolor = VDP_BLACK;
    vdp_init(VDP_MODE_TEXT, (*fgcolor<<4) | (*bgcolor & 0x0f), 0, 0);
    clearScr();
    return 0;
}

//--------------------------------------------------------------------------------------
// Low Resolution Screen Mode (64x48)
// Syntaxe:
//          TEXT
//--------------------------------------------------------------------------------------
int basGr(void)
{
    unsigned char sqtdtam[10];
    vdp_init(VDP_MODE_MULTICOLOR, 0, 0, 0);
    return 0;
}

//--------------------------------------------------------------------------------------
// High Resolution Screen Mode (256x192)
// Syntaxe:
//          TEXT
//--------------------------------------------------------------------------------------
int basHgr(void)
{
    vdp_init(VDP_MODE_G2, 0x0, 1, 0);
    return 0;
}

//--------------------------------------------------------------------------------------
// Muda a cor do plot em baixa/alta resolucao (GR or HGR from basHcolor)
// Syntaxe:
//          COLOR=<color>
//--------------------------------------------------------------------------------------
int basColor(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vTab, vColumn;
    unsigned char sqtdtam[10];

    if (*vdp_mode != VDP_MODE_MULTICOLOR && *vdp_mode != VDP_MODE_G2)
    {
        *vErroProc = 24;
        return 0;
    }

    if (*pointerRunProg != '=')
    {
        *vErroProc = 3;
        return 0;
    }

    pointerRunProg++;

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    *fgcolor=(char)*iVal;

    value_type='%';

    return 0;
}

//--------------------------------------------------------------------------------------
// Coloca um dot ou preenche uma area com a color previamente definida
// Syntaxe:
//          PLOT <x entre 0 e 63>, <y entre 0 e 47>
//--------------------------------------------------------------------------------------
int basPlot(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vx, vy;
    unsigned char sqtdtam[10];

    if (*vdp_mode != VDP_MODE_MULTICOLOR)
    {
        *vErroProc = 24;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vx=(char)*iVal;

    if (*token != ',')
    {
        *vErroProc = 18;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        //putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vy=(char)*iVal;

    vdp_plot_color(vx, vy, *fgcolor);

    value_type='%';

    return 0;
}

//--------------------------------------------------------------------------------------
// Desenha uma linha horizontal de x1, y1 até x2, y1
// Syntaxe:
//          HLIN <x1>, <x2> at <y1>
//               x1 e x2 : de 0 a 63
//                    y1 : de 0 a 47
//--------------------------------------------------------------------------------------
int basHlin(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vx1, vx2, vy;
    unsigned char sqtdtam[10];

    if (*vdp_mode != VDP_MODE_MULTICOLOR)
    {
        *vErroProc = 24;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vx1=(char)*iVal;

    if (*token != ',')
    {
        *vErroProc = 18;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        //putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vx2=(char)*iVal;

    if (*token != 0xBA) // AT Token
    {
        *vErroProc = 18;
        return 0;
    }

    pointerRunProg++;

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vy=(char)*iVal;

    if (vx2 < vx1)
    {
        ix = vx1;
        vx1 = vx2;
        vx2 = ix;
    }

    for(ix = vx1; ix <= vx2; ix++)
        vdp_plot_color(ix, vy, *fgcolor);

    value_type='%';

    return 0;
}

//--------------------------------------------------------------------------------------
// Desenha uma linha vertical de x1, y1 até x1, y2
// Syntaxe:
//          VLIN <y1>, <y2> at <x1>
//                    x1 : de 0 a 63
//               y1 e y2 : de 0 a 47
//--------------------------------------------------------------------------------------
int basVlin(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vy1, vy2, vx;
    unsigned char sqtdtam[10];

    if (*vdp_mode != VDP_MODE_MULTICOLOR)
    {
        *vErroProc = 24;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vy1=(char)*iVal;

    if (*token != ',')
    {
        *vErroProc = 18;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        //putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vy2=(char)*iVal;

    if (*token != 0xBA) // AT Token
    {
        *vErroProc = 18;
        return 0;
    }

    pointerRunProg++;

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vx=(char)*iVal;

    if (vy2 < vy1)
    {
        iy = vy1;
        vy1 = vy2;
        vy2 = iy;
    }

    for(iy = vy1; iy <= vy2; iy++)
        vdp_plot_color(vx, iy, *fgcolor);

    value_type='%';

    return 0;
}

//--------------------------------------------------------------------------------------
//
// Syntaxe:
//
//--------------------------------------------------------------------------------------
int basScrn(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int *iVal = answer;
    int *tval = token;
    unsigned char vx, vy;
    unsigned char sqtdtam[10];

    if (*vdp_mode != VDP_MODE_MULTICOLOR)
    {
        *vErroProc = 24;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    // Erro, primeiro caracter deve ser abre parenteses
    if(tok==EOL || tok==FINISHED || token_type!=OPENPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type != '%')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vx=(char)*iVal;

    nextToken();
    if (*vErroProc) return 0;

    if (*token!=',')
    {
        *vErroProc = 18;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type != '%')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vy=(char)*iVal;

    nextToken();
    if (*vErroProc) return 0;

    // Ultimo caracter deve ser fecha parenteses
    if (token_type!=CLOSEPARENT)
    {
        *vErroProc = 15;
        return 0;
    }

    // Ler Aqui.. a cor e devolver em *tval
    *tval = 0;

    value_type='%';

    return 0;
}

//--------------------------------------------------------------------------------------
//
// Syntaxe:
//
//--------------------------------------------------------------------------------------
int basHcolor(void)
{
    if (*vdp_mode != VDP_MODE_G2)
    {
        *vErroProc = 24;
        return 0;
    }

    basColor();
    if (*vErroProc) return 0;

    return 0;
}

//--------------------------------------------------------------------------------------
//
// Syntaxe:
//
//--------------------------------------------------------------------------------------
/*int basHplot(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vx, vy;
    unsigned char sqtdtam[10];
    unsigned char vOper = 0;
    int vDiag = 0;

    if (*vdp_mode != VDP_MODE_G2)
    {
        *vErroProc = 24;
        return 0;
    }

    do
    {
        nextToken();
        if (*vErroProc) return 0;

        if (*token != 0x86)
        {
            if(token_type==QUOTE) { // is string, error
                *vErroProc = 16;
                return 0;
            }
            else { // is expression
                putback();

                getExp(&answer);
                if (*vErroProc) return 0;

                if (value_type == '$' || value_type == '#')
                {
                    *vErroProc = 16;
                    return 0;
                }
            }

            vx = (char)*iVal;

            if (*token != ',')
            {
                *vErroProc = 18;
                return 0;
            }

            nextToken();
            if (*vErroProc) return 0;

            if(token_type==QUOTE) { // is string, error
                *vErroProc = 16;
                return 0;
            }
            else { // is expression
                //putback();

                getExp(&answer);
                if (*vErroProc) return 0;

                if (value_type == '$' || value_type == '#')
                {
                    *vErroProc = 16;
                    return 0;
                }
            }

            vy = (char)*iVal;

            if (!vOper)
                vOper = 1;
        }
        else
            pointerRunProg++;

        if (tok == EOL || tok == FINISHED || *token == 0x86)    // Fim de linha, programa ou token TO
        {
            if (!vOper)
            {
                vOper = 2;
            }
            else if (vOper == 1)
            {
                *lastHgrX = vx;
                *lastHgrY = vy;
writeLongSerial("Aqui 777.666.1-[");
itoa(*lastHgrX,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(*lastHgrY,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(vx,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(vy,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(*token,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");

                if (*token != 0x86)
                    vdp_plot_hires(vx, vy, *fgcolor, *bgcolor);
            }
            else if (vOper == 2)
            {
writeLongSerial("Aqui 777.666.2-[");
itoa(*lastHgrX,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(*lastHgrY,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(vx,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(vy,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]-[");
itoa(*token,sqtdtam,16);
writeLongSerial(sqtdtam);
writeLongSerial("]\r\n");
                if (vx == *lastHgrX && vy == *lastHgrY)
                    vdp_plot_hires(vx, vy, *fgcolor, *bgcolor);
                else if (vx != *lastHgrX && vy == *lastHgrY)
                {
                    if (vx < *lastHgrX)
                    {
                        ix = *lastHgrX;
                        *lastHgrX = vx;
                        vx = ix;
                    }

                    for(ix = *lastHgrX; ix <= vx; ix++)
                        vdp_plot_hires(ix, vy, *fgcolor, *bgcolor);
                }
                else if (vy != *lastHgrY && vx == *lastHgrX)
                {
                    if (vy < *lastHgrY)
                    {
                        iy = *lastHgrY;
                        *lastHgrY = vy;
                        vy = iy;
                    }

                    for(iy = *lastHgrY; iy <= vy; iy++)
                        vdp_plot_hires(vx, iy, *fgcolor, *bgcolor);
                }
                else
                {
                    vDiag = (int)((vy - *lastHgrY) / (vx - *lastHgrX));
                    iy = *lastHgrY;

                    for(ix = *lastHgrX; ix <= vx; ix++)
                    {
                        vdp_plot_hires(ix, iy, *fgcolor, *bgcolor);
                        iy = iy + vDiag;

                        if (iy < 0)
                        {
                            *vErroProc = 25;
                            return 0;
                        }
                    }
                }

                *lastHgrX = vx;
                *lastHgrY = vy;
            }

            if (*token == 0x86)
                pointerRunProg++;
        }

        vOper = 2;
   } while (*token == 0x86); // TO Token

    value_type='%';

    return 0;
}

*/
//--------------------------------------------------------------------------------------
// Coloca um dot ou preenche uma area com a color previamente definida
// Syntaxe:
//          PLOT <x entre 0 e 63>, <y entre 0 e 47>
//--------------------------------------------------------------------------------------
int basHplot(void)
{
    int ix = 0, iy = 0, iz = 0, iw = 0, vToken;
    unsigned char answer[200];
    int  *iVal = answer;
    unsigned char vx, vy;
    unsigned char sqtdtam[10];

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vx=(char)*iVal;

    if (*token != ',')
    {
        *vErroProc = 18;
        return 0;
    }

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) { /* is string, error */
        *vErroProc = 16;
        return 0;
    }
    else { /* is expression */
        //putback();

        getExp(&answer);
        if (*vErroProc) return 0;

        if (value_type == '$' || value_type == '#')
        {
            *vErroProc = 16;
            return 0;
        }
    }

    vy=(char)*iVal;

    vdp_plot_hires(vx, vy, *fgcolor, 0);

    value_type='%';

    return 0;
}

//--------------------------------------------------------------------------------------
// Ler dados no comando DATA
// Syntaxe:
//          READ <variavel>
//--------------------------------------------------------------------------------------
int basRead(void)
{
    int ix = 0, iy = 0, iz = 0;
//    unsigned char answer[100];
    unsigned char var[3], varTipo;
    unsigned char sqtdtam[10];
    unsigned long vTemp;
    long vRetFV;

    // Pega a variavel
    nextToken();
    if (*vErroProc) return 0;

    if(tok==EOL || tok==FINISHED)
    {
        *vErroProc = 4;
        return 0;
    }

    if(token_type==QUOTE) { /* is string */
        *vErroProc = 4;
        return 0;
    }
    else { /* is expression */
        // Verifica se começa com letra, pois tem que ser uma variavel
        if(!isalphas(*token))
        {
            *vErroProc = 4;
            return 0;
        }

        if (strlen(token) < 3)
        {
            var[0] = *token;
            varTipo = VARTYPEDEFAULT;

            if (strlen(token) == 2 && *(token + 1) < 0x30)
                varTipo = *(token + 1);

            if (strlen(token) == 2 && isalphas(*(token + 1)))
                var[1] = *(token + 1);
            else
                var[1] = 0x00;

            var[2] = varTipo;
        }
        else
        {
            var[0] = *token;
            var[1] = *(token + 1);
            var[2] = *(token + 2);
            iz = strlen(token) - 1;
            varTipo = var[2];
        }
    }

    // Procurar Data
    if (vDataPointer == 0)
    {
        // Primeira Leitura, procura primeira ocorrencia
        vDataLineAtu = *addrFirstLineNumber;

        do
        {
            vDataPointer = vDataLineAtu;

            if (*(vDataPointer + 5) == 0x98)    // Token do comando DATA é o primeiro comando da linha
            {
                vDataPointer = (vDataLineAtu + 6);
                vDataFirst = vDataLineAtu;
                break;
            }

            vTemp  = ((*(vDataLineAtu) & 0xFF) << 16);
            vTemp |= ((*(vDataLineAtu + 1) & 0xFF) << 8);
            vTemp |= (*(vDataLineAtu + 2) & 0xFF);

            vDataLineAtu = vTemp;

        } while (*vDataLineAtu);
    }

    if (vDataPointer == 0xFFFFFFFF)
    {
        *vErroProc = 26;
        return 0;
    }

    *vDataBkpPointerProg = pointerRunProg;

    pointerRunProg = vDataPointer;

    nextToken();
    if (*vErroProc) return 0;

    if(token_type==QUOTE) {
        strcpy(aswerPointer,token);
        value_type = '$';
    }
    else { /* is expression */
        putback();

        getExp(&aswerPointer);
        if (*vErroProc) return 0;
    }

    // Pega ponteiro atual (proximo numero/char)
    vDataPointer = pointerRunProg + 1;

    // Devolve ponteiro anterior
    pointerRunProg = *vDataBkpPointerProg;

    // Se nao foi virgula, é final de linha, procura proximo comando data
    if (*token != ',')
    {
        do
        {
            vTemp  = ((*(vDataLineAtu) & 0xFF) << 16);
            vTemp |= ((*(vDataLineAtu + 1) & 0xFF) << 8);
            vTemp |= (*(vDataLineAtu + 2) & 0xFF);

            vDataLineAtu = vTemp;
            if (!vDataLineAtu)
            {
                vDataPointer = 0xFFFFFFFF;
                break;
            }

            vDataPointer = vDataLineAtu;

            if (*(vDataPointer + 5) == 0x98)    // Token do comando DATA é o primeiro comando da linha
            {
                vDataPointer = (vDataLineAtu + 6);
                break;
            }
        } while (*vDataLineAtu);
    }

    if (varTipo != value_type)
    {
        *vErroProc = 16;
        return 0;
    }
    else
    {
        /* assign the value */
        vRetFV = findVariable(var);

        // Se nao existe variavel e inicio sentenca, cria variavel e atribui o valor
        if (!vRetFV)
            createVariable(var, aswerPointer, varTipo);
        else // se ja existe, altera
            updateVariable((vRetFV + 3), aswerPointer, varTipo, 1);
    }

    return 0;
}

//--------------------------------------------------------------------------------------
// Volta ponteiro do READ para o primeiro item dos comandos DATA
// Syntaxe:
//          RESTORE
//--------------------------------------------------------------------------------------
int basRestore(void)
{
    vDataLineAtu = vDataFirst;
    vDataPointer = (vDataLineAtu + 6);

    return 0;
}
