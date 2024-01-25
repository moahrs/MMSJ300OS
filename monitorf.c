/********************************************************************************
*    Programa    : monitor.c
*    Objetivo    : MMSJOS - Versao vintage compatible
*    Criado em   : 11/07/2013
*    Programador : Moacir Jr.
*--------------------------------------------------------------------------------
* Data        Versao  Responsavel  Motivo
* 11/07/2013  0.1     Moacir Jr.   Criação Versão Beta
* 12/11/2022  1.0     Moacir Jr.   Versao para publicacao com FAT32
* 								   ( usando cartao SD ) ( NOT VINTAGE )
* 29/07/2023  1.0a    Moacir Jr.   Adaptar de FAT32 para FAT16 e acesso pela Serial
* 								   usando Arduino uno como controlador com
*                                  FLOPPY DISK 3 1/2", e integracao no monitor
********************************************************************************/
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "monitorf.h"

#define versionMMSJOS "1.0a"

const unsigned char strValidChars[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^&'@{}[],$=!-#()%.+~_";

const unsigned char vmesc[12][3] = {{'J','a','n'},{'F','e','b'},{'M','a','r'},
                                    {'A','p','r'},{'M','a','y'},{'J','u','n'},
                                    {'J','u','l'},{'A','u','g'},{'S','e','p'},
                                    {'O','c','t'},{'N','o','v'},{'D','e','c'}};

//-----------------------------------------------------------------------------
// FAT16 Functions
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void fsInit(void)
{
    char verr = 0;

    // Escolhe drive B
    if (fsSendSerial('s') < 0) verr = 1;

    if (!verr)
        if (fsSendSerial(0x01) < 0) verr = 1;


    // Montar o disco na variavel vdisk
    if (!verr)
        fsMountDisk();

    *vdiratuidx = 1;
    *vdiratu = '/';
    *(vdiratu + *vdiratuidx) = 0x00;

    printText("MMSJ-OS v"versionMMSJOS);
    printText("\r\n\0");
}

//-----------------------------------------------------------------------------
void fsVer(void)
{
    printText("\r\n\0");
    printText("MMSJ-OS v"versionMMSJOS);
}

//-----------------------------------------------------------------------------
char fsOsCommand(unsigned char *linhacomando, unsigned int ix, unsigned int iy, unsigned char *linhaarg, unsigned char *vparam, unsigned char *vparam2, unsigned char *vparam3, unsigned char* vresp)
{
	unsigned char vbuffer[128], vlinha[40];
    unsigned char *vdirptr = (unsigned char*)&vdir;
    unsigned short iz, izz, ikk, varg = 0;
    unsigned char sqtdtam[10], cuntam;
    unsigned char *vTempW;
    long vqtdtam;
    unsigned short vretfat;

    if (!strcmp(linhacomando,"MOUNT") && iy == 5)
    {
        if (fsMountDisk() != RETURN_OK)
            printText("Mounting disk error\r\n\0");

        *vresp = 2;
        return 1;
    }
    else if (!strcmp(linhacomando,"LS") && iy == 2)
    {
        if (fsFindInDir(NULL, TYPE_FIRST_ENTRY) >= ERRO_D_START)
            printText("File not found\r\n\0");
        else
        {
            while (1)
            {
                for (izz = 0; izz < vdisk->sectorSize; izz += 32) {
                    fsReadDir(izz, 0);

                    if (vdir->Name[0] == 0x00)
                        break;

                    if (vdir->Name[0] == 0xE5)
                        continue;

    				if (vdir->Attr != ATTR_VOLUME)
                    {
    					memset(vbuffer, 0x0, 128);
                        vdirptr = (unsigned char*)&vdir;

                        for(ix = 40; ix <= 79; ix++)
                            vbuffer[ix] = *vdirptr++;

                        if (vdir->Attr != ATTR_DIRECTORY)
                        {
                            // Reduz o tamanho a unidade (GB, MB ou KB)
                            vqtdtam = vdir->Size;

                            if ((vqtdtam & 0xC0000000) != 0)
                            {
                                cuntam = 'G';
                                vqtdtam = ((vqtdtam & 0xC0000000) >> 30) + 1;
                            }
                            else if ((vqtdtam & 0x3FF00000) != 0)
                            {
                                cuntam = 'M';
                                vqtdtam = ((vqtdtam & 0x3FF00000) >> 20) + 1;
                            }
                            else if ((vqtdtam & 0x000FFC00) != 0)
                            {
                                cuntam = 'K';
                                vqtdtam = ((vqtdtam & 0x000FFC00) >> 10) + 1;
                            }
                            else
                                cuntam = ' ';

                            // Transforma para decimal
        					memset(sqtdtam, 0x0, 10);
                            itoa(vqtdtam, sqtdtam, 10);

                            // Primeira Parte da Linha do dir, tamanho
                            for(ix = 0; ix <= 3; ix++)
                            {
                                if (sqtdtam[ix] == 0)
                                    break;
                            }

                            iy = (4 - ix);

                            for(ix = 0; ix <= 3; ix++)
                            {
                                if (iy <= ix)
                                {
                                    ikk = ix - iy;
                                    vbuffer[ix] = sqtdtam[ix - iy];
                                }
                                else
                                    vbuffer[ix] = ' ';
                            }

                            vbuffer[4] = cuntam;
                        }
                        else
                        {
                            vbuffer[0] = ' ';
                            vbuffer[1] = ' ';
                            vbuffer[2] = ' ';
                            vbuffer[3] = ' ';
                            vbuffer[4] = '0';
                        }

                        vbuffer[5] = ' ';

                        // Segunda parte da linha do dir, data ult modif
                        // Mes
                        vqtdtam = (vdir->UpdateDate & 0x01E0) >> 5;
                        if (vqtdtam < 1 || vqtdtam > 12)
                            vqtdtam = 1;

                        vqtdtam--;

                        vbuffer[6] = vmesc[vqtdtam][0];
                        vbuffer[7] = vmesc[vqtdtam][1];
                        vbuffer[8] = vmesc[vqtdtam][2];
                        vbuffer[9] = ' ';

                        // Dia
                        vqtdtam = vdir->UpdateDate & 0x001F;
      					memset(sqtdtam, 0x0, 10);
                        itoa(vqtdtam, sqtdtam, 10);

                        if (vqtdtam < 10)
                        {
                            vbuffer[10] = '0';
                            vbuffer[11] = sqtdtam[0];
                        }
                        else
                        {
                            vbuffer[10] = sqtdtam[0];
                            vbuffer[11] = sqtdtam[1];
                        }
                        vbuffer[12] = ' ';

                        // Ano
                        vqtdtam = ((vdir->UpdateDate & 0xFE00) >> 9) + 1980;
      					memset(sqtdtam, 0x0, 10);
                        itoa(vqtdtam, sqtdtam, 10);

                        vbuffer[13] = sqtdtam[0];
                        vbuffer[14] = sqtdtam[1];
                        vbuffer[15] = sqtdtam[2];
                        vbuffer[16] = sqtdtam[3];
                        vbuffer[17] = ' ';

                        // Terceira parte da linha do dir, nome.ext
                        ix = 18;
                        varg = 0;
                        while (vdir->Name[varg] != 0x20 && vdir->Name[varg] != 0x00 && varg <= 7)
                        {
                            vbuffer[ix] = vdir->Name[varg];
                            ix++;
                            varg++;
                        }

                        vbuffer[ix] = '.';
                        ix++;

                        varg = 0;
                        while (vdir->Ext[varg] != 0x20 && vdir->Ext[varg] != 0x00 && varg <= 2)
                        {
                            vbuffer[ix] = vdir->Ext[varg];
                            ix++;
                            varg++;
                        }

                        if (varg == 0)
                        {
                            ix--;
                            vbuffer[ix] = ' ';
                            ix++;
                        }

                        // Quarta parte da linha do dir, "/" para diretorio
                        if (vdir->Attr == ATTR_DIRECTORY)
                        {
                            ix--;
                            vbuffer[ix] = '/';
                            ix++;
                        }

                        vbuffer[ix] = '\0';

                        for(ix = 0; ix <= 39; ix++)
                            vlinha[ix] = vbuffer[ix];
    				}
    				else
                    {
      					memset(vlinha, 0x20, 40);
    				    vlinha[5]  = 'D';
    				    vlinha[6]  = 'i';
    				    vlinha[7]  = 's';
    				    vlinha[8]  = 'k';
    				    vlinha[9]  = ' ';
    				    vlinha[10] = 'N';
    				    vlinha[11] = 'a';
    				    vlinha[12] = 'm';
    				    vlinha[13] = 'e';
    				    vlinha[14] = ' ';
    				    vlinha[15] = 'i';
    				    vlinha[16] = 's';
    				    vlinha[17] = ' ';
    				    ix = 18;
    				    varg = 0;
                        while (vdir->Name[varg] != 0x00 && varg <= 7)
                        {
                            vlinha[ix] = vdir->Name[varg];
                            ix++;
                            varg++;
                        }

                        varg = 0;
                        while (vdir->Ext[varg] != 0x00 && varg <= 2)
                        {
                            vlinha[ix] = vdir->Ext[varg];
                            ix++;
                            varg++;
                        }

                        vlinha[ix] = '\0';
    				}

                    // Mostra linha
                    printText("\r\n\0");
                    printText(vlinha);

                    // Verifica se Tem mais arquivos no diretorio
    				for (ix = 0; ix <= 7; ix++)
                    {
    				    vparam[ix] = vdir->Name[ix];
    					if (vparam[ix] == 0x20)
                        {
    						vparam[ix] = '\0';
    						break;
    				    }
    				}

    				vparam[ix] = '\0';

    				if (vdir->Name[0] != '.')
                    {
    				    vparam[ix] = '.';
    				    ix++;
    					for (iy = 0; iy <= 2; iy++)
                        {
    					    vparam[ix] = vdir->Ext[iy];
    						if (vparam[ix] == 0x20)
                            {
    							vparam[ix] = '\0';
    							break;
    					    }
    					    ix++;
    					}
    					vparam[ix] = '\0';
    				}
                }

                if (vdir->Name[0] != 0x00)
                {
                    if (fsFindInDir(vparam, TYPE_NEXT_ENTRY) >= ERRO_D_START)
                    {
                        printText("\r\n\0");
                        break;
                    }
                }
                else
                    break;
            }

            printText("\r\n\0");
        }

        *vresp = 2;
        return 1;
    }
    else
    {
        if (!strcmp(linhacomando,"RM") && iy == 2)
        {
            vretfat = fsDelFile(linhaarg);
        }
        else if (!strcmp(linhacomando,"REN") && iy == 3)
        {
            vretfat = fsRenameFile(vparam, vparam2);
        }
        else if (!strcmp(linhacomando,"CP") && iy == 2)
        {
  			ikk = 0;

      		if (fsOpenFile(vparam) != RETURN_OK)
            {
                vretfat = ERRO_B_NOT_FOUND;
            }
            else
            {
          		if (fsOpenFile(vparam2) != RETURN_OK)
                {
        			if (fsCreateFile(vparam2) != RETURN_OK)
                    {
                          vretfat = ERRO_B_CREATE_FILE;
                    }
                }
            }

            while (vretfat == RETURN_OK)
            {
      			if (fsReadFile(vparam, ikk, vbuffer, 128) > 0)
                {
    				if (fsWriteFile(vparam2, ikk, vbuffer, 128) != RETURN_OK)
                    {
                        vretfat = ERRO_B_WRITE_FILE;
                        break;
                    }

                    ikk += 128;
                }
                else
                    break;
            }
        }
        else if (!strcmp(linhacomando,"PWD") && iy == 3)
        {
            printText(vdiratu);
            printText("\r\n\0");
            ix = 255;
        }
        else if (!strcmp(linhacomando,"MD") && iy == 2)
        {
            vretfat = fsMakeDir(linhaarg);
        }
        else if (!strcmp(linhacomando,"CD") && iy == 2)
        {
            vretfat = fsChangeDir(linhaarg);
        }
        else if (!strcmp(linhacomando,"RD") && iy == 2)
        {
            vretfat = fsRemoveDir(linhaarg);
        }
        else if (!strcmp(linhacomando,"DATE") && iy == 4)
        {
/*            vpicret = 1;
            sendPic(ix + 1);
            sendPic(picDOSdate);*/
            ix = 255;
        }
        else if (!strcmp(linhacomando,"TIME") && iy == 4)
        {
/*            vpicret = 1;
            sendPic(ix + 1);
            sendPic(picDOStime);*/
            ix = 255;
        }
        else if (!strcmp(linhacomando,"FORMAT") && iy == 6)
        {
            vretfat = fsFormat(0x5678, linhaarg);
        }
        else if (!strcmp(linhacomando,"CAT") && iy == 3)
        {
            catFile(linhaarg);
            ix = 255;
        }
        else
        {
            // Verifica se tem Arquivo com esse nome na pasta atual no disco
            ix = iy;
            linhacomando[ix] = '.';
            ix++;
            linhacomando[ix] = 'B';
            ix++;
            linhacomando[ix] = 'I';
            ix++;
            linhacomando[ix] = 'N';
            ix++;
            linhacomando[ix] = '\0';

            vretfat = fsFindInDir(linhacomando, TYPE_FILE);
            if (vretfat <= ERRO_D_START)
            {
                // Se tiver, carrega em 0x00810000 e executa
                loadFile(linhacomando, (unsigned long*)0x00810000);
                if (!*verroSo)
                {
                    runCmd();
                }
                else
                {
                    printText("Loading File Error...\r\n\0");
                    *vresp = 2;
                    return 1;
                }

                ix = 255;
            }
            else
            {
                // Se nao tiver, mostra erro
                printText("Invalid Command or File Name\r\n\0");
                *vresp = 2;
                return 1;
            }
        }

        if (ix != 255)
        {
            if (vretfat != RETURN_OK)
            {
                printText("Command unsuccessfully\r\n\0");
                *vresp = 2;
                return 1;
            }
            else
            {
                if (!strcmp(linhacomando,"CD"))
                {
                    if (linhaarg[0] == '.' && linhaarg[1] == '.')
                    {
                        vTempW = vdiratu + *vdiratuidx;
                        while (*vTempW != '/')
                        {
                            *vTempW = 0x00;
                            *vdiratuidx = *vdiratuidx - 1;
                            vTempW = vdiratu + *vdiratuidx;
                        }

                        vTempW = vdiratu + *vdiratuidx;
                        if (*vdiratuidx > 0)
                            *vTempW = 0x00;
                        else
                            *vdiratuidx = *vdiratuidx + 1;
                    }
                    else if(linhaarg[0] == '/')
                    {
                        *vdiratu = '/';
                        *vdiratuidx = 1;
                        vTempW = vdiratu + *vdiratuidx;
                        *vTempW = 0x00;
                    }
                    else if(linhaarg[0] != '.')
                    {
                        *vdiratuidx = *vdiratuidx - 1;

                        vTempW = vdiratu + *vdiratuidx;
                        if (*vTempW != '/')
                        {
                            *vdiratuidx = *vdiratuidx + 1;
                            vTempW = vdiratu + *vdiratuidx;
                            *vTempW = '/';
                            *vdiratuidx = *vdiratuidx + 1;
                        }
                        else
                            *vdiratuidx = *vdiratuidx + 1;

                        for (varg = 0; varg < ix; varg++)
                        {
                            vTempW = vdiratu + *vdiratuidx;
                            *vTempW = linhaarg[varg];
                            *vdiratuidx = *vdiratuidx + 1;
                        }

                        vTempW = vdiratu + *vdiratuidx;
                        *vTempW = 0x00;
                    }
                }
                else if (!strcmp(linhacomando,"DATE"))
                {
/*                    for(ix = 0; ix <= 9; ix++)
                    {
                        recPic();
                        vlinha[ix] = vbytepic;
                    }*/

                    vlinha[ix] = '\0';
                    printText("  Date is \0");
                    printText(vlinha);
                    printText("\r\n\0");
                }
                else if (!strcmp(linhacomando,"TIME"))
                {
/*                    for(ix = 0; ix <= 7; ix++)
                    {
                        recPic();
                        vlinha[ix] = vbytepic;
                    }*/

                    vlinha[ix] = '\0';
                    printText("  Time is \0");
                    printText(vlinha);
                    printText("\r\n\0");
                }
                else if (!strcmp(linhacomando,"FORMAT"))
                {
                    printText("Format disk was successfully\r\n\0");
                }
            }
        }
    }

    *vresp = 2;
	return 1;
}

//-----------------------------------------------------------------------------
unsigned char fsMountDisk(void)
{
    unsigned char sqtdtam[10];

	// LER BOOT SECTOR
    if (!fsSectorRead((unsigned short)0x0000,gDataBuffer))
		return ERRO_B_READ_DISK;

	vdisk->firsts = 0;

    vdisk->reserv  = (unsigned short)gDataBuffer[15] << 8;	//ok
    vdisk->reserv |= (unsigned short)gDataBuffer[14];

    vdisk->secpertrack  = (unsigned short)gDataBuffer[25] << 8;	//ok
    vdisk->secpertrack |= (unsigned short)gDataBuffer[24];

    vdisk->numheads  = (unsigned short)gDataBuffer[27] << 8;	//ok
    vdisk->numheads |= (unsigned short)gDataBuffer[26];

    vdisk->RootEntiesCount  = (unsigned short)gDataBuffer[18] << 8;
    vdisk->RootEntiesCount |= (unsigned short)gDataBuffer[17];

    vdisk->NumberOfFATs = (unsigned char)gDataBuffer[16];

	vdisk->fat = vdisk->reserv + vdisk->firsts;	//ok

    vdisk->sectorSize  = (unsigned short)gDataBuffer[12] << 8;	//ok
    vdisk->sectorSize |= (unsigned short)gDataBuffer[11];

	vdisk->SecPerClus = gDataBuffer[13];	//ok

    vdisk->secperfat  = (unsigned short)gDataBuffer[23] << 8; // ok com sector per fat
    vdisk->secperfat |= (unsigned short)gDataBuffer[22];

	vdisk->fatsize = vdisk->secperfat; // * vdisk->NumberOfFATs;	// Fat Size

    vdisk->root  = vdisk->fat + (vdisk->NumberOfFATs * vdisk->secperfat);

	vdisk->type = FAT16;

	vdisk->data = vdisk->root + ((vdisk->RootEntiesCount * 32) / vdisk->sectorSize);

	*vclusterdir = 2;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
void fsSetClusterDir (unsigned short vclusdiratu) {
    *vclusterdir = vclusdiratu;
}

//-------------------------------------------------------------------------
unsigned short fsGetClusterDir (void) {
    return *vclusterdir;
}

//-------------------------------------------------------------------------
unsigned char fsCreateFile(char * vfilename)
{
	// Verifica ja existe arquivo com esse nome
	if (fsFindInDir(vfilename, TYPE_ALL) < ERRO_D_START)
		return ERRO_B_FILE_FOUND;

	// Cria o arquivo com o nome especificado
	if (fsFindInDir(vfilename, TYPE_CREATE_FILE) >= ERRO_D_START)
		return ERRO_B_CREATE_FILE;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsOpenFile(char * vfilename)
{
	unsigned short vdirdate, vbytepic;
	unsigned char ds1307[7], ix, vlinha[12], vtemp[5];

	// Abre o arquivo especificado
	if (fsFindInDir(vfilename, TYPE_FILE) >= ERRO_D_START)
		return ERRO_B_FILE_NOT_FOUND;

	// Ler Data/Hora
	getDateTimeAtu(ds1307);	// 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano

	// Converte para a Data/Hora da FAT16
	vdirdate = datetimetodir(ds1307[3], ds1307[4], ds1307[5], CONV_DATA);

	// Grava nova data no lastaccess
	vdir->LastAccessDate  = vdirdate;

 	if (fsUpdateDir() != RETURN_OK)
		return ERRO_B_UPDATE_DIR;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsCloseFile(char * vfilename, unsigned char vupdated)
{
	unsigned short vdirdate, vdirtime, vbytepic;
	unsigned char ds1307[7], vtemp[5], ix, vlinha[12];

	if (fsFindInDir(vfilename, TYPE_FILE) < ERRO_D_START) {
		if (vupdated) {
			// Ler Data/Hora
			getDateTimeAtu(ds1307);	// 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano

			// Converte para a Data/Hora da FAT16
			vdirtime = datetimetodir(ds1307[0], ds1307[1], ds1307[2], CONV_HORA);
			vdirdate = datetimetodir(ds1307[3], ds1307[4], ds1307[5], CONV_DATA);

			// Grava nova data no lastaccess e nova data/hora no update date/time
			vdir->LastAccessDate  = vdirdate;
			vdir->UpdateTime = vdirtime;
			vdir->UpdateDate = vdirdate;

			if (fsUpdateDir() != RETURN_OK)
				return ERRO_B_UPDATE_DIR;
		}
	}
	else
		return ERRO_B_NOT_FOUND;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned long fsInfoFile(char * vfilename, unsigned char vtype)
{
	unsigned long vinfo = ERRO_D_NOT_FOUND, vtemp;

	// retornar as informa?es conforme solicitado.
	if (fsFindInDir(vfilename, TYPE_FILE) < ERRO_D_START) {
		switch (vtype) {
			case INFO_SIZE:
				vinfo = vdir->Size;
				break;
			case INFO_CREATE:
			    vtemp = (vdir->CreateDate << 16) | vdir->CreateTime;
				vinfo = (vtemp);
				break;
			case INFO_UPDATE:
			    vtemp = (vdir->UpdateDate << 16) | vdir->UpdateTime;
				vinfo = (vtemp);
				break;
			case INFO_LAST:
				vinfo = vdir->LastAccessDate;
				break;
		}
	}
	else
		return ERRO_D_NOT_FOUND;

	return vinfo;
}

//-------------------------------------------------------------------------
unsigned char fsDelFile(char * vfilename)
{
	// Apaga o arquivo solicitado
	if (fsFindInDir(vfilename, TYPE_DEL_FILE) >= ERRO_D_START)
		return ERRO_B_APAGAR_ARQUIVO;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsRenameFile(char * vfilename, char * vnewname)
{
	unsigned long vclusterfile;
	unsigned short ikk;
	unsigned char ixx, iyy;

	// Verificar se nome j?nao existe
	vclusterfile = fsFindInDir(vnewname, TYPE_ALL);

	if (vclusterfile < ERRO_D_START)
		return ERRO_B_FILE_FOUND;

	// Procura arquivo a ser renomeado
	vclusterfile = fsFindInDir(vfilename, TYPE_FILE);

	if (vclusterfile >= ERRO_D_START)
		return ERRO_B_FILE_NOT_FOUND;

	// Altera nome na estrutura vdir
	memset(vdir->Name, 0x20, 8);
	memset(vdir->Ext, 0x20, 3);

	iyy = 0;
	for (ixx = 0; ixx <= strlen(vnewname); ixx++) {
		if (vnewname[ixx] == '\0')
			break;
		else if (vnewname[ixx] == '.')
			iyy = 8;
		else {
			if (iyy <= 7)
				vdir->Name[iyy] = vnewname[ixx];
			else {
			    ikk = iyy - 8;
				vdir->Ext[ikk] = vnewname[ixx];
			}

			iyy++;
		}
	}

	// Altera o nome, as demais informacoes nao alteram
	if (fsUpdateDir() != RETURN_OK)
		return ERRO_B_UPDATE_DIR;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
// Rotina para escrever/ler no disco
//-------------------------------------------------------------------------
unsigned char fsRWFile(unsigned short vclusterini, unsigned long voffset, unsigned char *buffer, unsigned char vtype)
{
	unsigned short vdata, vclusternew, vfat;
	unsigned short vpos, vsecfat, voffsec, voffclus, vtemp1, vtemp2, ikk, ikj;

	// Calcula offset de setor e cluster
	voffsec = voffset / vdisk->sectorSize;
	voffclus = voffsec / vdisk->SecPerClus;
	vclusternew = vclusterini;

	// Procura o cluster onde esta o setor a ser lido
	for (vpos = 0; vpos < voffclus; vpos++) {
		// Em operacao de escrita, como vai mexer com disco, salva buffer no setor de swap
		if (vtype == OPER_WRITE) {
		    ikk = vdisk->fat - 1;
			if (!fsSectorWrite(ikk, buffer, FALSE))
				return ERRO_B_READ_DISK;
		}

		vclusternew = fsFindNextCluster(vclusterini, NEXT_FIND);

		// Se for leitura e o offset der dentro do ultimo cluster, sai
		if (vtype == OPER_READ && vclusternew == LAST_CLUSTER_FAT16)
			return RETURN_OK;

		// Se for gravacao e o offset der dentro do ultimo cluster, cria novo cluster
		if ((vtype == OPER_WRITE || vtype == OPER_READWRITE) && vclusternew == LAST_CLUSTER_FAT16) {
			// Calcula novo cluster livre
			vclusternew = fsFindClusterFree(FREE_USE);

			if (vclusternew == ERRO_D_DISK_FULL)
				return ERRO_B_DISK_FULL;

			// Procura Cluster atual para altera?o
			vsecfat = vclusterini / 64;
			vfat = vdisk->fat + vsecfat;

			if (!fsSectorRead(vfat, gDataBuffer))
				return ERRO_B_READ_DISK;

			// Grava novo cluster no cluster atual
			vpos = (vclusterini - (64 * vsecfat)) * 2;
			gDataBuffer[vpos] = (unsigned char)(vclusternew & 0xFF);
			ikk = vpos + 1;
			gDataBuffer[ikk] = (unsigned char)((vclusternew / 0x100) & 0xFF);

			if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
				return ERRO_B_WRITE_DISK;
		}

		vclusterini = vclusternew;

		// Em operacao de escrita, como mexeu com disco, le o buffer salvo no setor swap
		if (vtype == OPER_WRITE) {
		    ikk = vdisk->fat - 1;
			if (!fsSectorRead(ikk, buffer))
				return ERRO_B_READ_DISK;
		}
	}

	// Posiciona no setor dentro do cluster para ler/gravar
	vtemp1 = ((vclusternew - 2) * vdisk->SecPerClus);
	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
	vdata = vtemp1 + vtemp2;
	vtemp1 = (voffclus * vdisk->SecPerClus);
	vdata += voffsec - vtemp1;

	if (vtype == OPER_READ || vtype == OPER_READWRITE) {
		// Le o setor e coloca no buffer
		if (!fsSectorRead(vdata, buffer))
			return ERRO_B_READ_DISK;
	}
	else {
		// Grava o buffer no setor
		if (!fsSectorWrite(vdata, buffer, FALSE))
			return ERRO_B_WRITE_DISK;
	}

	return RETURN_OK;
}

//-------------------------------------------------------------------------
// Retorna um buffer de "vsize" (max 255) Bytes, a partir do "voffset".
//-------------------------------------------------------------------------
unsigned short fsReadFile(char * vfilename, unsigned long voffset, unsigned char *buffer, unsigned short vsizebuffer)
{
	unsigned short ix, iy, vsizebf = 0;
	unsigned short vsize, vsetor = 0, vsizeant = 0;
	unsigned short voffsec, vtemp, ikk, ikj;
	unsigned short vclusterini;
    unsigned char sqtdtam[10];

	vclusterini = fsFindInDir(vfilename, TYPE_FILE);

	if (vclusterini >= ERRO_D_START)
		return 0;	// Erro na abertura/Arquivo nao existe

	// Verifica se o offset eh maior que o tamanho do arquivo
	if (voffset > vdir->Size)
		return 0;

	// Verifica se offset vai precisar gravar mais de 1 setor (entre 2 setores)
	vtemp = voffset / vdisk->sectorSize;
	voffsec = (voffset - (vdisk->sectorSize * (vtemp)));

	if ((voffsec + vsizebuffer) > vdisk->sectorSize)
		vsetor = 1;

/*itoa(vsetor, sqtdtam, 10);
printText(sqtdtam);
printText(".\r\n\0");*/

/*itoa(voffsec, sqtdtam, 10);
printText(sqtdtam);
printText(".\r\n\0");*/

/*itoa(vdisk->sectorSize, sqtdtam, 10);
printText(sqtdtam);
printText(".\r\n\0");*/

/*itoa(voffset, sqtdtam, 10);
printText(sqtdtam);
printText(".\r\n\0");*/

/*itoa(vsizebuffer, sqtdtam, 10);
printText(sqtdtam);
printText(".\r\n\0");*/

	for (ix = 0; ix <= vsetor; ix++) {
    	vtemp = voffset / vdisk->sectorSize;
    	voffsec = (voffset - (vdisk->sectorSize * (vtemp)));

		// Ler setor do offset
		if (fsRWFile(vclusterini, voffset, gDataBuffer, OPER_READ) != RETURN_OK)
			return vsizebf;

		// Verifica tamanho a ser gravado
		if ((voffsec + vsizebuffer) <= vdisk->sectorSize)
			vsize = vsizebuffer - vsizeant;
		else
			vsize = vdisk->sectorSize - voffsec;

		vsizebf += vsize;

		if (vsizebf > (vdir->Size - voffset))
			vsizebf = vdir->Size - voffset;

/*itoa(vsize, sqtdtam, 10);
printText(sqtdtam);
printText(".\r\n\0");*/

        if (vsetor == 0)
            vsize = vsizebuffer;

		// Retorna os dados no buffer
		for (iy = 0; iy < vsize; iy++) {
		    ikk = vsizeant + iy;
		    ikj = voffsec + iy;
			buffer[ikk] = gDataBuffer[ikj];
        }

		vsizeant = vsize;
		voffset += vsize;
	}

	return vsizebf;
}

//-------------------------------------------------------------------------
// buffer a ser gravado nao pode ter mais que 128 bytes
//-------------------------------------------------------------------------
unsigned char fsWriteFile(char * vfilename, unsigned long voffset, unsigned char *buffer, unsigned char vsizebuffer)
{
	unsigned char vsetor = 0, ix, iy;
	unsigned short vsize, vsizeant = 0;
	unsigned short voffsec, vtemp, ikk, ikj;
	unsigned short vclusterini;

	vclusterini = fsFindInDir(vfilename, TYPE_FILE);

	if (vclusterini >= ERRO_D_START)
		return ERRO_B_FILE_NOT_FOUND;	// Erro na abertura/Arquivo nao existe

	// Verifica se offset vai precisar gravar mais de 1 setor (entre 2 setores)
	vtemp = voffset / vdisk->sectorSize;
	voffsec = (voffset - (vdisk->sectorSize * (vtemp)));

	if ((voffsec + vsizebuffer) > vdisk->sectorSize)
		vsetor = 1;

	for (ix = 0; ix <= vsetor; ix++) {
    	vtemp = voffset / vdisk->sectorSize;
    	voffsec = (voffset - (vdisk->sectorSize * (vtemp)));

		// Ler setor do offset
		if (fsRWFile(vclusterini, voffset, gDataBuffer, OPER_READWRITE) != RETURN_OK)
			return ERRO_B_READ_FILE;

		// Verifica tamanho a ser gravado
		if ((voffsec + vsizebuffer) <= vdisk->sectorSize)
			vsize = vsizebuffer - vsizeant;
		else
			vsize = vdisk->sectorSize - voffsec;

		// Prepara buffer para grava?o
		for (iy = 0; iy < vsize; iy++) {
		    ikk = iy + voffsec;
		    ikj = vsizeant + iy;
			gDataBuffer[ikk] = buffer[ikj];
		}

		// Grava setor
		if (fsRWFile(vclusterini, voffset, gDataBuffer, OPER_WRITE) != RETURN_OK)
			return ERRO_B_WRITE_FILE;

		vsizeant = vsize;

		if (vsetor == 1)
			voffset += vsize;
	}

	if ((voffset + vsizebuffer) > vdir->Size) {
		vdir->Size = voffset + vsizebuffer;

		if (fsUpdateDir() != RETURN_OK)
			return ERRO_B_UPDATE_DIR;
	}

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsMakeDir(char * vdirname)
{
	// Verifica ja existe arquivo/dir com esse nome
	if (fsFindInDir(vdirname, TYPE_ALL) < ERRO_D_START)
		return ERRO_B_DIR_FOUND;

	// Cria o dir solicitado
	if (fsFindInDir(vdirname, TYPE_CREATE_DIR) >= ERRO_D_START)
		return ERRO_B_CREATE_DIR;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsChangeDir(char * vdirname)
{
	unsigned short vclusterdirnew;
    unsigned char sqtdtam[11];

	// Troca o diretorio conforme especificado
	if (vdirname[0] == '/')
		vclusterdirnew = 0x0002;
	else
		vclusterdirnew	= fsFindInDir(vdirname, TYPE_DIRECTORY);

	if (vclusterdirnew >= ERRO_D_START)
		return ERRO_B_DIR_NOT_FOUND;

	// Coloca o novo diretorio como atual
	*vclusterdir = vclusterdirnew;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsRemoveDir(char * vdirname)
{
	// Apaga o diretorio conforme especificado
	if (fsFindInDir(vdirname, TYPE_DEL_DIR) >= ERRO_D_START)
		return ERRO_B_DIR_NOT_FOUND;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsPwdDir(unsigned char *vdirpath) {
    if (*vclusterdir == vdisk->root) {
        vdirpath[0] = '/';
        vdirpath[1] = '\0';
    }
    else {
        vdirpath[0] = 'o';
        vdirpath[1] = '\0';
    }

	return RETURN_OK;
}

//-------------------------------------------------------------------------
void fsReadDir(unsigned short ix, unsigned short vdata)
{
    unsigned short im, iy, iz, vpos, vsecfat, ventrydir, ixold;
    unsigned short ikk, ikj;

    for (iy = 0; iy < 8; iy++) {
        ikk = ix + iy;
        vdir->Name[iy] = gDataBuffer[ikk];
    }

    for (iy = 0; iy < 3; iy++) {
        ikk = ix + 8 + iy;
        vdir->Ext[iy] = gDataBuffer[ikk];
    }

    ikk = ix + 11;
    vdir->Attr = gDataBuffer[ikk];

    ikk = ix + 15;
    vdir->CreateTime  = (unsigned short)gDataBuffer[ikk] << 8;
    ikk = ix + 14;
    vdir->CreateTime |= (unsigned short)gDataBuffer[ikk];

    ikk = ix + 17;
    vdir->CreateDate  = (unsigned short)gDataBuffer[ikk] << 8;
    ikk = ix + 16;
    vdir->CreateDate |= (unsigned short)gDataBuffer[ikk];

    ikk = ix + 19;
    vdir->LastAccessDate  = (unsigned short)gDataBuffer[ikk] << 8;
    ikk = ix + 18;
    vdir->LastAccessDate |= (unsigned short)gDataBuffer[ikk];

    ikk = ix + 23;
    vdir->UpdateTime  = (unsigned short)gDataBuffer[ikk] << 8;
    ikk = ix + 22;
    vdir->UpdateTime |= (unsigned short)gDataBuffer[ikk];

    ikk = ix + 25;
    vdir->UpdateDate  = (unsigned short)gDataBuffer[ikk] << 8;
    ikk = ix + 24;
    vdir->UpdateDate |= (unsigned short)gDataBuffer[ikk];

    ikk = ix + 27;
    vdir->FirstCluster  = (unsigned long)gDataBuffer[ikk] << 8;
    ikk = ix + 26;
    vdir->FirstCluster |= (unsigned long)gDataBuffer[ikk];

    ikk = ix + 31;
    vdir->Size  = (unsigned long)gDataBuffer[ikk] << 24;
    ikk = ix + 30;
    vdir->Size |= (unsigned long)gDataBuffer[ikk] << 16;
    ikk = ix + 29;
    vdir->Size |= (unsigned long)gDataBuffer[ikk] << 8;
    ikk = ix + 28;
    vdir->Size |= (unsigned long)gDataBuffer[ikk];

    vdir->DirClusSec = vdata;
    vdir->DirEntry = ix;
}

//-------------------------------------------------------------------------
unsigned long fsFindInDir(char * vname, unsigned char vtype)
{
	unsigned long vfat, vdata, vclusterfile, vclusterdirnew, vclusteratual, vtemp1, vtemp2;
	unsigned char fnameName[9], fnameExt[4];
	unsigned short im, ix, iy, iz, vpos, vsecfat, ventrydir, ixold;
	unsigned short vdirdate, vdirtime, ikk, ikj, vtemp, vbytepic;
	unsigned char vcomp, iw, ds1307[7], iww, vtempt[5], vlinha[5];
    unsigned char sqtdtam[10];

	memset(fnameName, 0x20, 8);
	memset(fnameExt, 0x20, 3);

	if (vname != NULL) {
		if (vname[0] == '.' && vname[1] == '.') {
			fnameName[0] = vname[0];
			fnameName[1] = vname[1];
		}
		else if (vname[0] == '.') {
			fnameName[0] = vname[0];
		}
		else {
			iy = 0;
			for (ix = 0; ix <= strlen(vname); ix++) {
				if (vname[ix] == '\0')
					break;
				else if (vname[ix] == '.')
					iy = 8;
				else {
					for (iww = 0; iww <= 56; iww++) {
						if (strValidChars[iww] == vname[ix])
							break;
					}

					if (iww > 56)
						return ERRO_D_INVALID_NAME;

					if (iy <= 7)
						fnameName[iy] = vname[ix];
					else {
					    ikk = iy - 8;
						fnameExt[ikk] = vname[ix];
					}

					iy++;
				}
			}
		}
	}

	vfat = vdisk->fat;
	vtemp1 = ((*vclusterdir - 2) * vdisk->SecPerClus);
	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
	vdata = vtemp1 + vtemp2;

	vclusterfile = ERRO_D_NOT_FOUND;
	vclusterdirnew = *vclusterdir;
	ventrydir = 0;

	while (vdata != LAST_CLUSTER_FAT16) {
		for (iw = 0; iw < vdisk->SecPerClus; iw++) {

      		if (!fsSectorRead(vdata, gDataBuffer))
				return ERRO_D_READ_DISK;

            for (ix = 0; ix < vdisk->sectorSize; ix += 32) {
                fsReadDir(ix, vdata);

				if (vtype == TYPE_FIRST_ENTRY && vdir->Attr != 0x0F) {
					if (vdir->Name[0] != DIR_DEL) {
			 			if (vdir->Name[0] != DIR_EMPTY) {
							vclusterfile = vdata; //vdir->FirstCluster;
    						vdata = LAST_CLUSTER_FAT16;
    						break;
    					}
					}
				}

				if (vtype == TYPE_EMPTY_ENTRY || vtype == TYPE_CREATE_FILE || vtype == TYPE_CREATE_DIR) {
					if (vdir->Name[0] == DIR_EMPTY || vdir->Name[0] == DIR_DEL) {
						vclusterfile = ventrydir;

						if (vtype != TYPE_EMPTY_ENTRY) {
							vclusterfile = fsFindClusterFree(FREE_USE);

							if (vclusterfile >= ERRO_D_START)
								return ERRO_D_NOT_FOUND;

						    if (!fsSectorRead(vdata, gDataBuffer))
								return ERRO_D_READ_DISK;

							for (iz = 0; iz <= 10; iz++) {
								if (iz <= 7) {
								    ikk = ix + iz;
									gDataBuffer[ikk] = fnameName[iz];
								}
								else {
								    ikk = ix + iz;
								    ikj = iz - 8;
									gDataBuffer[ikk] = fnameExt[ikj];
								}
							}

							if (vtype == TYPE_CREATE_FILE)
								gDataBuffer[ix + 11] = 0x00;
							else
								gDataBuffer[ix + 11] = ATTR_DIRECTORY;

							// Ler Data/Hora
							getDateTimeAtu(ds1307);	// 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano

						    // Converte para a Data/Hora da FAT16
							vdirtime = datetimetodir(ds1307[0], ds1307[1], ds1307[2], CONV_HORA);
							vdirdate = datetimetodir(ds1307[3], ds1307[4], ds1307[5], CONV_DATA);

							// Coloca dados no buffer para gravacao
							ikk = ix + 12;
							gDataBuffer[ikk] = 0x00;	// case
							ikk = ix + 13;
							gDataBuffer[ikk] = 0x00;	// creation time in ms
							ikk = ix + 14;
							gDataBuffer[ikk] = (unsigned char)(vdirtime & 0xFF);	// creation time (ds1307)
							ikk = ix + 15;
							gDataBuffer[ikk] = (unsigned char)((vdirtime >> 8) & 0xFF);
							ikk = ix + 16;
							gDataBuffer[ikk] = (unsigned char)(vdirdate & 0xFF);	// creation date (ds1307)
							ikk = ix + 17;
							gDataBuffer[ikk] = (unsigned char)((vdirdate >> 8) & 0xFF);
							ikk = ix + 18;
							gDataBuffer[ikk] = (unsigned char)(vdirdate & 0xFF);	// last access	(ds1307)
							ikk = ix + 19;
							gDataBuffer[ikk] = (unsigned char)((vdirdate >> 8) & 0xFF);

							ikk = ix + 22;
							gDataBuffer[ikk] = (unsigned char)(vdirtime & 0xFF);	// time update (ds1307)
							ikk = ix + 23;
							gDataBuffer[ikk] = (unsigned char)((vdirtime >> 8) & 0xFF);
							ikk = ix + 24;
							gDataBuffer[ikk] = (unsigned char)(vdirdate & 0xFF);	// date update (ds1307)
							ikk = ix + 25;
							gDataBuffer[ikk] = (unsigned char)((vdirdate >> 8) & 0xFF);

							ikk = ix + 26;
						    gDataBuffer[ikk] = (unsigned char)(vclusterfile & 0xFF);
							ikk = ix + 27;
						    gDataBuffer[ikk] = (unsigned char)((vclusterfile / 0x100) & 0xFF);

							ikk = ix + 28;
							gDataBuffer[ikk] = 0x00;
							ikk = ix + 29;
							gDataBuffer[ikk] = 0x00;
							ikk = ix + 30;
							gDataBuffer[ikk] = 0x00;
							ikk = ix + 31;
							gDataBuffer[ikk] = 0x00;

							if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
								return ERRO_D_WRITE_DISK;

							if (vtype == TYPE_CREATE_DIR) {
	  							// Posicionar na nova posicao do diretorio
                            	vtemp1 = ((vclusterfile - 2) * vdisk->SecPerClus);
                            	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
                            	vdata = vtemp1 + vtemp2;

								// Limpar novo cluster do diretorio (Zerar)
								memset(gDataBuffer, 0x00, vdisk->sectorSize);

								for (iz = 0; iz < vdisk->SecPerClus; iz++) {
								    if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
										return ERRO_D_WRITE_DISK;
									vdata++;
								}

                            	vtemp1 = ((vclusterfile - 2) * vdisk->SecPerClus);
                            	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
                            	vdata = vtemp1 + vtemp2;

	  							// Criar diretorio . (atual)
	  							memset(gDataBuffer, 0x00, vdisk->sectorSize);

	  							ix = 0;
	  							gDataBuffer[0] = '.';
	  							gDataBuffer[1] = 0x20;
	  							gDataBuffer[2] = 0x20;
	  							gDataBuffer[3] = 0x20;
	  							gDataBuffer[4] = 0x20;
	  							gDataBuffer[5] = 0x20;
	  							gDataBuffer[6] = 0x20;
	  							gDataBuffer[7] = 0x20;
	  							gDataBuffer[8] = 0x20;
	  							gDataBuffer[9] = 0x20;
	  							gDataBuffer[10] = 0x20;

	  							gDataBuffer[11] = 0x10;

								gDataBuffer[12] = 0x00;	// case
								gDataBuffer[13] = 0x00;	// creation time in ms
								gDataBuffer[14] = (unsigned char)(vdirtime & 0xFF);	// creation time (ds1307)
								gDataBuffer[15] = (unsigned char)((vdirtime >> 8) & 0xFF);
								gDataBuffer[16] = (unsigned char)(vdirdate & 0xFF);	// creation date (ds1307)
								gDataBuffer[17] = (unsigned char)((vdirdate >> 8) & 0xFF);
								gDataBuffer[18] = (unsigned char)(vdirdate & 0xFF);	// last access	(ds1307)
								gDataBuffer[19] = (unsigned char)((vdirdate >> 8) & 0xFF);

								gDataBuffer[22] = (unsigned char)(vdirtime & 0xFF);	// time update (ds1307)
								gDataBuffer[23] = (unsigned char)((vdirtime >> 8) & 0xFF);
								gDataBuffer[24] = (unsigned char)(vdirdate & 0xFF);	// date update (ds1307)
								gDataBuffer[25] = (unsigned char)((vdirdate >> 8) & 0xFF);

	  						    gDataBuffer[26] = (unsigned char)(vclusterfile & 0xFF);
	  						    gDataBuffer[27] = (unsigned char)((vclusterfile / 0x100) & 0xFF);

	  							gDataBuffer[28] = 0x00;
	  							gDataBuffer[29] = 0x00;
	  							gDataBuffer[30] = 0x00;
	  							gDataBuffer[31] = 0x00;

	  							// Criar diretorio .. (anterior)
	  							ix = 32;
	  							gDataBuffer[32] = '.';
	  							gDataBuffer[33] = '.';
	  							gDataBuffer[34] = 0x20;
	  							gDataBuffer[35] = 0x20;
	  							gDataBuffer[36] = 0x20;
	  							gDataBuffer[37] = 0x20;
	  							gDataBuffer[38] = 0x20;
	  							gDataBuffer[39] = 0x20;
	  							gDataBuffer[40] = 0x20;
	  							gDataBuffer[41] = 0x20;
	  							gDataBuffer[42] = 0x20;

	  							gDataBuffer[43] = 0x10;

								gDataBuffer[44] = 0x00;	// case
								gDataBuffer[45] = 0x00;	// creation time in ms
								gDataBuffer[46] = (unsigned char)(vdirtime & 0xFF);	// creation time (ds1307)
								gDataBuffer[47] = (unsigned char)((vdirtime >> 8) & 0xFF);
								gDataBuffer[48] = (unsigned char)(vdirdate & 0xFF);	// creation date (ds1307)
								gDataBuffer[49] = (unsigned char)((vdirdate >> 8) & 0xFF);
								gDataBuffer[50] = (unsigned char)(vdirdate & 0xFF);	// last access	(ds1307)
								gDataBuffer[51] = (unsigned char)((vdirdate >> 8) & 0xFF);

								gDataBuffer[54] = (unsigned char)(vdirtime & 0xFF);	// time update (ds1307)
								gDataBuffer[55] = (unsigned char)((vdirtime >> 8) & 0xFF);
								gDataBuffer[56] = (unsigned char)(vdirdate & 0xFF);	// date update (ds1307)
								gDataBuffer[57] = (unsigned char)((vdirdate >> 8) & 0xFF);

	  						    gDataBuffer[58] = (unsigned char)(*vclusterdir & 0xFF);
	  						    gDataBuffer[59] = (unsigned char)((*vclusterdir / 0x100) & 0xFF);

	  							gDataBuffer[60] = 0x00;
	  							gDataBuffer[61] = 0x00;
	  							gDataBuffer[62] = 0x00;
	  							gDataBuffer[63] = 0x00;

	  						    if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
	  								return ERRO_D_WRITE_DISK;
	              			}

							vdata = LAST_CLUSTER_FAT16;
							break;
						}

						vdata = LAST_CLUSTER_FAT16;
						break;
					}
				}
				else if (vtype != TYPE_FIRST_ENTRY) {
					if (vdir->Name[0] != DIR_EMPTY && vdir->Name[0] != DIR_DEL) {
						vcomp = 1;
						for (iz = 0; iz <= 10; iz++) {
							if (iz <= 7) {
								if (fnameName[iz] != vdir->Name[iz]) {
									vcomp = 0;
									break;
								}
							}
							else {
							    ikk = iz - 8;
								if (fnameExt[ikk] != vdir->Ext[ikk]) {
									vcomp = 0;
									break;
								}
							}
						}

						if (vcomp) {
							if (vtype == TYPE_ALL || (vtype == TYPE_FILE && vdir->Attr != ATTR_DIRECTORY) || (vtype == TYPE_DIRECTORY && vdir->Attr == ATTR_DIRECTORY)) {
		  						vclusterfile = vdir->FirstCluster;

		  						break;
	  						}
	  						else if (vtype == TYPE_NEXT_ENTRY) {
		  						vtype = TYPE_FIRST_ENTRY;
		  					}
	  						else if (vtype == TYPE_DEL_FILE || vtype == TYPE_DEL_DIR) {
								// Guardando Cluster Atual
								vclusteratual = vdir->FirstCluster;

		  						// Apagando no Diretorio
		                		gDataBuffer[ix] = DIR_DEL;
		                		ikk = ix + 26;
								gDataBuffer[ikk] = 0x00;
		                		ikk = ix + 27;
								gDataBuffer[ikk] = 0x00;

								if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
		          			  		return ERRO_D_WRITE_DISK;

				                // Apagando vestigios na FAT
	          					while (1) {
				                    // Procura Proximo Cluster e ja zera
			           			    vclusterdirnew = fsFindNextCluster(vclusteratual, NEXT_FREE);

					                if (vclusterdirnew >= ERRO_D_START)
					                    return ERRO_D_NOT_FOUND;

					                if (vclusterdirnew == LAST_CLUSTER_FAT16) {
						                vclusterfile = LAST_CLUSTER_FAT16;
						          		vdata = LAST_CLUSTER_FAT16;
						          		break;
					                }

			            			// Tornar cluster atual o proximo
			            			vclusteratual = vclusterdirnew;
	          					}
	  						}
						}
					}
				}

				if (vdir->Name[0] == DIR_EMPTY) {
					vdata = LAST_CLUSTER_FAT16;
					break;
				}
			}

			if (vclusterfile < ERRO_D_START || vdata == LAST_CLUSTER_FAT16)
				break;

			ventrydir++;
			vdata++;
		}

		// Se conseguiu concluir a operacao solicitada, sai do loop
		if (vclusterfile < ERRO_D_START || vdata == LAST_CLUSTER_FAT16)
			break;
		else {
			// Posiciona na FAT, o endereco da pasta atual
			vsecfat = vclusterdirnew / 128;
			vfat = vdisk->fat + vsecfat;

		    if (!fsSectorRead(vfat, gDataBuffer))
				return ERRO_D_READ_DISK;

            vtemp = vclusterdirnew - (128 * vsecfat);
			vpos = vtemp * 4;
            ikk = vpos + 1;
			vclusterdirnew  = (unsigned long)gDataBuffer[ikk] << 8;
            ikk = vpos;
			vclusterdirnew |= (unsigned long)gDataBuffer[ikk];

			if (vclusterdirnew != LAST_CLUSTER_FAT16) {
				// Devolve a proxima posicao para procura/uso
            	vtemp1 = ((vclusterdirnew - 2) * vdisk->SecPerClus);
            	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
            	vdata = vtemp1 + vtemp2;
			}
			else {
				// Se for para criar uma nova entrada no diretorio e nao tem mais espaco
				// Cria uma nova entrada na Fat
				if (vtype == TYPE_EMPTY_ENTRY || vtype == TYPE_CREATE_FILE || vtype == TYPE_CREATE_DIR) {
					vclusterdirnew = fsFindClusterFree(FREE_USE);

					if (vclusterdirnew < ERRO_D_START) {
					    if (!fsSectorRead(vfat, gDataBuffer))
							return ERRO_D_READ_DISK;

					    gDataBuffer[vpos] = (unsigned char)(vclusterdirnew & 0xFF);
					    ikk = vpos + 1;
					    gDataBuffer[ikk] = (unsigned char)((vclusterdirnew / 0x100) & 0xFF);
					    ikk = vpos + 2;

					    if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
							return ERRO_D_WRITE_DISK;

						// Posicionar na nova posicao do diretorio
                    	vtemp1 = ((vclusterdirnew - 2) * vdisk->SecPerClus);
                    	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
                    	vdata = vtemp1 + vtemp2;

						// Limpar novo cluster do diretorio (Zerar)
						memset(gDataBuffer, 0x00, vdisk->sectorSize);

						for (iz = 0; iz < vdisk->SecPerClus; iz++) {
						    if (!fsSectorWrite(vdata, gDataBuffer, FALSE))
								return ERRO_D_WRITE_DISK;
							vdata++;
						}

                    	vtemp1 = ((vclusterdirnew - 2) * vdisk->SecPerClus);
                    	vtemp2 = (vdisk->reserv + vdisk->firsts + (2 * vdisk->fatsize));
                    	vdata = vtemp1 + vtemp2;
					}
					else {
						vclusterdirnew = LAST_CLUSTER_FAT16;
						vclusterfile = ERRO_D_NOT_FOUND;
						vdata = vclusterdirnew;
					}
				}
				else {
					vdata = vclusterdirnew;
				}
			}
		}
	}

	return vclusterfile;
}

//-------------------------------------------------------------------------
unsigned char fsUpdateDir()
{
	unsigned char iy;
	unsigned short ventry, ikk;

	if (!fsSectorRead(vdir->DirClusSec, gDataBuffer))
		return ERRO_B_READ_DISK;

    ventry = vdir->DirEntry;

	for (iy = 0; iy < 8; iy++) {
	    ikk = ventry + iy;
		gDataBuffer[ikk] = vdir->Name[iy];
	}

	for (iy = 0; iy < 3; iy++) {
	    ikk = ventry + 8 + iy;
		gDataBuffer[ikk] = vdir->Ext[iy];
	}

    ikk = ventry + 18;
	gDataBuffer[ikk] = (unsigned char)(vdir->LastAccessDate & 0xFF);	// last access	(ds1307)
    ikk = ventry + 19;
	gDataBuffer[ikk] = (unsigned char)((vdir->LastAccessDate / 0x100) & 0xFF);

    ikk = ventry + 22;
	gDataBuffer[ikk] = (unsigned char)(vdir->UpdateTime & 0xFF);	// time update (ds1307)
    ikk = ventry + 23;
	gDataBuffer[ikk] = (unsigned char)((vdir->UpdateTime / 0x100) & 0xFF);

    ikk = ventry + 24;
	gDataBuffer[ikk] = (unsigned char)(vdir->UpdateDate & 0xFF);	// date update (ds1307)
    ikk = ventry + 25;
	gDataBuffer[ikk] = (unsigned char)((vdir->UpdateDate / 0x100) & 0xFF);

    ikk = ventry + 28;
    gDataBuffer[ikk] = (unsigned char)(vdir->Size & 0xFF);
    ikk = ventry + 29;
    gDataBuffer[ikk] = (unsigned char)((vdir->Size / 0x100) & 0xFF);
    ikk = ventry + 30;
    gDataBuffer[ikk] = (unsigned char)((vdir->Size / 0x10000) & 0xFF);
    ikk = ventry + 31;
    gDataBuffer[ikk] = (unsigned char)((vdir->Size / 0x1000000) & 0xFF);

   if (!fsSectorWrite(vdir->DirClusSec, gDataBuffer, FALSE))
		return ERRO_B_WRITE_DISK;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned short fsFindNextCluster(unsigned short vclusteratual, unsigned char vtype)
{
	unsigned short vfat, vclusternew;
	unsigned short vpos, vsecfat, ikk;

	vsecfat = vclusteratual / 128;
	vfat = vdisk->fat + vsecfat;

	if (!fsSectorRead(vfat, gDataBuffer))
		return ERRO_D_READ_DISK;

	vpos = (vclusteratual - (128 * vsecfat)) * 4;
	ikk = vpos + 1;
	vclusternew  = (unsigned short)gDataBuffer[ikk] << 8;
	vclusternew |= (unsigned short)gDataBuffer[vpos];

	if (vtype != NEXT_FIND) {
		if (vtype == NEXT_FREE) {
			gDataBuffer[vpos] = 0x00;
        	ikk = vpos + 1;
			gDataBuffer[ikk] = 0x00;
		}
		else if (vtype == NEXT_FULL) {
			gDataBuffer[vpos] = 0xFF;
        	ikk = vpos + 1;
			gDataBuffer[ikk] = 0x0FF;
		}

		if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
			return ERRO_D_WRITE_DISK;
	}

  return vclusternew;
}

//-------------------------------------------------------------------------
unsigned short fsFindClusterFree(unsigned char vtype)
{
  	unsigned long vclusterfree = 0x00, cc, vfat;
	unsigned short jj, ikk, ikk2, ikk3;

	vfat = vdisk->fat;

	for (cc = 0; cc <= vdisk->fatsize; cc++) {
	    // LER FAT SECTOR
		if (!fsSectorRead(vfat, gDataBuffer))
			return ERRO_D_READ_DISK;

		// Procura Cluster Livre dentro desse setor
		for (jj = 0; jj < vdisk->sectorSize; jj += 2) {
		    ikk = jj + 1;

			if (gDataBuffer[jj] == 0x00 && gDataBuffer[ikk] == 0x00)
			    break;

			vclusterfree++;
		}

		// Se achou algum setor livre, sai do loop
		if (jj < vdisk->sectorSize)
			break;

		// Soma mais 1 para procurar proximo cluster
		vfat++;
	}

	if (cc > vdisk->fatsize)
		vclusterfree = ERRO_D_DISK_FULL;
	else {
		if (vtype == FREE_USE) {
		    gDataBuffer[jj] = 0xFF;
		    ikk = jj + 1;
		    gDataBuffer[ikk] = 0x0F;

		    if (!fsSectorWrite(vfat, gDataBuffer, FALSE))
				return ERRO_D_WRITE_DISK;
		}
	}

	return (vclusterfree);
}

//-------------------------------------------------------------------------
unsigned char fsFormat (long int serialNumber, char * volumeID)
{
    unsigned short    j;
    unsigned long   secCount, RootDirSectors;
    unsigned long   root, fat, firsts = 0, fatsize, test;
    unsigned long   Index;
	unsigned char    SecPerClus;

    unsigned char *  dataBufferPointer = gDataBuffer;

	//-------------------
	SecPerClus = 1;
	secCount = 0;
	//-------------------

	//-------------------
    fatsize = 0x09;
    fat = 1 + firsts;
    root = fat + (2 * fatsize);
	//-------------------

	// Formata MicroSD
    memset (gDataBuffer, 0x00, MEDIA_SECTOR_SIZE);

    // Non-file system specific values
    gDataBuffer[0] = 0xEB;         //Jump instruction
    gDataBuffer[1] = 0xFE;
    gDataBuffer[2] = 0x90;
    gDataBuffer[3] =  'M';         //OEM Name
    gDataBuffer[4] =  'M';
    gDataBuffer[5] =  'S';
    gDataBuffer[6] =  'J';
    gDataBuffer[7] =  ' ';
    gDataBuffer[8] =  'F';
    gDataBuffer[9] =  'A';
    gDataBuffer[10] = 'T';

    gDataBuffer[11] = 0x00;             //Sector size
    gDataBuffer[12] = 0x02;

    gDataBuffer[13] = SecPerClus;   //Sectors per cluster

    gDataBuffer[14] = 0x01;         //Reserved sector count
    gDataBuffer[15] = 0x00;

	fat = 0x01 + firsts;

    gDataBuffer[16] = 0x02;         //number of FATs

    gDataBuffer[17] = 0x00;          //Max number of root directory entries - 512 files allowed
    gDataBuffer[18] = 0x00;

    gDataBuffer[19] = 0x40;         //total sectors
    gDataBuffer[20] = 0x0B;

    gDataBuffer[21] = 0xF0;         //Media Descriptor

    gDataBuffer[22] = 0x09;         //Sectors per FAT
    gDataBuffer[23] = 0x00;

    gDataBuffer[24] = 0x12;         //Sectors per track
    gDataBuffer[25] = 0x00;

    gDataBuffer[26] = 0x02;         //Number of heads
    gDataBuffer[27] = 0x00;

    // Hidden sectors = sectors between the MBR and the boot sector
    gDataBuffer[28] = 0x00;
    gDataBuffer[29] = 0x00;
    gDataBuffer[30] = 0x00;
    gDataBuffer[31] = 0x00;

    // Total Sectors = same as sectors in the partition from MBR
    gDataBuffer[32] = 0;
    gDataBuffer[33] = 0;
    gDataBuffer[34] = 0;
    gDataBuffer[35] = 0;

	// Sectors per FAT
	gDataBuffer[36] = 0x80;			// Drive Number
    gDataBuffer[37] = 0x00;			// Reserved
    gDataBuffer[38] = 0x29;			// Extended Boot Signature

    gDataBuffer[39] = 0x40;			// Serial Number
    gDataBuffer[40] = 0x0B;
    gDataBuffer[41] = 0x21;
    gDataBuffer[42] = 0x50;

    // Volume ID
    if (volumeID != NULL)
    {
        for (Index = 0; (*(volumeID + Index) != 0) && (Index < 11); Index++)
        {
            gDataBuffer[Index + 43] = *(volumeID + Index);
        }
        while (Index < 11)
        {
            gDataBuffer[43 + Index++] = 0x20;
        }
    }
    else
    {
        for (Index = 0; Index < 11; Index++)
        {
            gDataBuffer[Index + 43] = 0;
        }
    }

    gDataBuffer[54] = 'F';
    gDataBuffer[55] = 'A';
    gDataBuffer[56] = 'T';
    gDataBuffer[57] = '1';
    gDataBuffer[58] = '6';
    gDataBuffer[59] = ' ';
    gDataBuffer[60] = ' ';
    gDataBuffer[61] = ' ';

    gDataBuffer[510] = 0x55;
    gDataBuffer[511] = 0xAA;

	if (!fsSectorWrite(0, gDataBuffer, FALSE))
		return ERRO_B_WRITE_DISK;

    // Erase the FAT
    memset (gDataBuffer, 0x00, MEDIA_SECTOR_SIZE);

    gDataBuffer[0] = 0xF8;          //BPB_Media byte value in its low 8 bits, and all other bits are set to 1
    gDataBuffer[1] = 0xFF;

    gDataBuffer[2] = 0xFF;          //Disk is clean and no read/write errors were encountered
    gDataBuffer[3] = 0xFF;

    gDataBuffer[4]  = 0xFF;         //Root Directory EOF
    gDataBuffer[5]  = 0xFF;

    for (j = 1; j != 0xFFFF; j--)
    {
        if (!fsSectorWrite (fat + (j * fatsize), gDataBuffer, FALSE))
			return ERRO_B_WRITE_DISK;
    }

    memset (gDataBuffer, 0x00, 12);

    for (Index = fat + 1; Index < (fat + fatsize); Index++)
    {
        for (j = 1; j != 0xFFFF; j--)
        {
            if (!fsSectorWrite (Index + (j * fatsize), gDataBuffer, FALSE))
				return ERRO_B_WRITE_DISK;
        }
    }

    // Erase the root directory
    for (Index = 1; Index < SecPerClus; Index++)
    {
        if (!fsSectorWrite (root + Index, gDataBuffer, FALSE))
			return ERRO_B_WRITE_DISK;
    }

    // Create a drive name entry in the root dir
    Index = 0;
    while ((*(volumeID + Index) != 0) && (Index < 11))
    {
        gDataBuffer[Index] = *(volumeID + Index);
        Index++;
    }
    while (Index < 11)
    {
        gDataBuffer[Index++] = ' ';
    }
    gDataBuffer[11] = 0x08;
    gDataBuffer[17] = 0x11;
    gDataBuffer[19] = 0x11;
    gDataBuffer[23] = 0x11;

    if (!fsSectorWrite (root, gDataBuffer, FALSE))
		return ERRO_B_WRITE_DISK;

	return RETURN_OK;
}

//-------------------------------------------------------------------------
unsigned char fsSectorRead(unsigned short vcluster, unsigned char* vbuffer)
{
    unsigned int ix;
    unsigned char sqtdtam[11], vtrack = 0, vhead = 0, vsector = 0;
    unsigned char vByte = 0;
/*printText("Aqui 111.666.0-[");
itoa(vcluster,sqtdtam,16);
printText(sqtdtam);
printText("]\r\n");*/

    fsConvClusterToTHS(vcluster, &vtrack, &vhead, &vsector);

/*printText("Aqui 111.666.1-[");
itoa(vtrack,sqtdtam,16);
printText(sqtdtam);
printText("]-[");
itoa(vsector,sqtdtam,16);
printText(sqtdtam);
printText("]-[");
itoa(vhead,sqtdtam,16);
printText(sqtdtam);
printText("]\r\n");*/

    // Clear Buffer de Recebimento
    while (fsRecSerial(vbuffer) >=0);

	// r<track>,<sector><head>   Ex.: r0,1,0
	if (fsSendSerial('r') < 0) return 0;
    if (fsSendSerial(vtrack) < 0) return 0;
    if (fsSendSerial(vsector) < 0) return 0;
    if (fsSendSerial(vhead) < 0) return 0;

    // Aguarda DDEE para confirmação do comando
    if (fsRecSerial(&vByte) < 0)
        return 0;

    if (vByte != 0xDD)
        return 0;

    if (fsRecSerial(&vByte) < 0)
        return 0;

    if (vByte != 0xEE)
        return 0;

    // Tudo OK, recebe dados
    for(ix = 0; ix < 512; ix++)
    {
		if (fsRecSerial(&vByte) < 0)
    		return 0;

        vbuffer[ix] = vByte;
    }

    return 1;
}

//-------------------------------------------------------------------------
unsigned char fsSectorWrite(unsigned short vcluster, unsigned char* vbuffer, unsigned char vtipo)
{
    unsigned short vpos = 0;
    unsigned char sqtdtam[11], vtrack = 0, vhead = 0, vsector = 0;
    unsigned char vByte = 0;

/*printText("Aqui 000.666.0-[");
itoa(vcluster,sqtdtam,16);
printText(sqtdtam);
printText("]\r\n");*/

	fsConvClusterToTHS(vcluster, &vtrack, &vhead, &vsector);

/*printText("Aqui 000.666.1-[");
itoa(vtrack,sqtdtam,16);
printText(sqtdtam);
printText("]-[");
itoa(vsector,sqtdtam,16);
printText(sqtdtam);
printText("]-[");
itoa(vhead,sqtdtam,16);
printText(sqtdtam);
printText("]\r\n");*/

    // Clear Buffer de Recebimento
    while (fsRecSerial(vbuffer) >=0);

	// w<track>,<sector><head>   Ex.: w0,1,0
    if (fsSendSerial('w') < 0) return 0;
    if (fsSendSerial(vtrack) < 0) return 0;
    if (fsSendSerial(vsector) < 0) return 0;
    if (fsSendSerial(vhead) < 0) return 0;

    // Aguarda DDEE para confirmação do comando
    if (fsRecSerial(&vByte) < 0)
        return 0;

    if (vByte != 0xDD)
        return 0;

    if (fsRecSerial(&vByte) < 0)
        return 0;

    if (vByte != 0xEE)
        return 0;

    // Tudo OK, envia dados
    while (vpos < 512)
    {
    	if (fsSendSerial(vbuffer[vpos]) < 0)
    		return 0;

        vpos++;
    }

    return 1;
}

//-------------------------------------------------------------------------
int fsRecSerial(unsigned char* pByte)
{
	int vTimeOut = 131072;

    while(!(*(vmfp + Reg_RSR) & 0x80))
    {
    	if (--vTimeOut < 0)
    		break;
    }

	if (vTimeOut >= 0)
        *pByte = *(vmfp + Reg_UDR);

    return vTimeOut;
}

//-------------------------------------------------------------------------
int fsSendSerial(unsigned char pByte)
{
	int vTimeOut = 131072;

    while(!(*(vmfp + Reg_TSR) & 0x80))  // Aguarda buffer de transmissao estar vazio
    {
    	if (--vTimeOut < 0)
    		break;
    }

    if (vTimeOut >= 0)
        *(vmfp + Reg_UDR) = pByte;

    return vTimeOut;
}

//-------------------------------------------------------------------------
int fsSendLongSerial(unsigned char *msg)
{
    while (*msg)
    {
    	if (fsSendSerial(*msg++) < 0)
    		return -1;
    }

    return 1;
}

//-------------------------------------------------------------------------
// T = LS ÷ (HeadsPerCylinder (HPC) × SectorsPerTrack (SPT))
// H = (LS ÷ SPT) mod HPC
// S = (LS mod SPT) + 1
//-------------------------------------------------------------------------
void fsConvClusterToTHS(unsigned short cluster, unsigned char* vtrack, unsigned char* vhead, unsigned char* vsector)
{
    *vtrack = cluster / (vdisk->secpertrack * vdisk->numheads);
    *vhead = (cluster / vdisk->secpertrack) % vdisk->numheads;
	*vsector = (cluster % vdisk->secpertrack) + 1;
}


//-------------------------------------------------------------------------
unsigned int bcd2dec(unsigned int bcd)
{
    unsigned int dec=0;
    unsigned int mult;
    for (mult=1; bcd; bcd=bcd>>4,mult*=10)
        dec += (bcd & 0x0f) * mult;
    return dec;
}

//-------------------------------------------------------------------------
// ds1307 array: 0-HH, 1-MM, 2-SS, 3-Dia, 4-Mes, 5-Ano
//-------------------------------------------------------------------------
int getDateTimeAtu(ds1307)
{

    return 0;
}

//-------------------------------------------------------------------------
unsigned short datetimetodir(unsigned char hr_day, unsigned char min_month, unsigned char sec_year, unsigned char vtype)
{
    unsigned short vconv = 0, vtemp;

    if (vtype == CONV_DATA) {
        vtemp = sec_year - 1980;
        vconv  = (unsigned short)(vtemp & 0x7F) << 9;
        vconv |= (unsigned short)(min_month & 0x0F) << 5;
        vconv |= (unsigned short)(hr_day & 0x1F);
    }
    else {
        vconv  = (unsigned short)(hr_day & 0x1F) << 11;
        vconv |= (unsigned short)(min_month & 0x3F) << 5;
        vtemp = sec_year / 2;
        vconv |= (unsigned short)(vtemp & 0x1F);
    }

    return vconv;
}

//-----------------------------------------------------------------------------
unsigned long loadFile(unsigned char *parquivo, unsigned short* xaddress)
{
    unsigned short cc, dd;
    unsigned char vbuffer[512];
    unsigned int vbytegrava = 0;
    unsigned short xdado = 0, xcounter = 0;
    unsigned short vcrc, vcrcpic, vloop;
    unsigned long vsizeR, vsizefile = 0;

    vsizefile = 0;
    *verroSo = 0;

    if (fsOpenFile(parquivo) == RETURN_OK)
    {
        while (1)
        {
            vsizeR = fsReadFile(parquivo, vsizefile, vbuffer, 512);

            if (vsizeR != 0)
            {
                for (dd = 0; dd < 512; dd += 2)
                {
                    vbytegrava = (unsigned short)vbuffer[dd] << 8;
                    vbytegrava = vbytegrava | (vbuffer[dd + 1] & 0x00FF);

                    // Grava Dados na Posição Especificada
                    *xaddress = vbytegrava;
                    xaddress += 1;
                }

                vsizefile += 512;
            }
            else
                break;
        }

        // Fecha o Arquivo
        fsCloseFile(parquivo, 0);
    }
    else
        *verroSo = 1;

    return vsizefile;
}

//-----------------------------------------------------------------------------
void catFile(unsigned char *parquivo)
{
    unsigned short vbytepic;
    unsigned char *mcfgfileptr = mcfgfile, vqtd = 1;
    unsigned char *parqptr = parquivo;
    unsigned long vsizefile;
    unsigned char sqtdtam[10];

    while (*parqptr++)
        vqtd++;

    vsizefile = loadFile(parquivo, (unsigned long*)0x00FF9FF8);   // 12K espaco pra carregar arquivo. Colocar logica pra pegar tamanho e alocar espaco

    if (!*verroSo) {
        itoa(vsizefile, sqtdtam, 10);
        printText(sqtdtam);
        printText("\r\n\0");

        while (vsizefile > 0) {
            itoa(vsizefile, sqtdtam, 10);
            printText(sqtdtam);
            printText("\r\n\0");

            if (*mcfgfileptr == 0x0D) {
                printChar(0x0D, 1);
            }
            else if (*mcfgfileptr == 0x0A) {
                printChar(0x0A, 1);
            }
            else if (*mcfgfileptr == 0x1A || *mcfgfileptr == 0x00) {
            if (*mcfgfileptr == 0x1A)
                    break;
            }
            else {
                if (*mcfgfileptr >= 0x20)
                    printChar(*mcfgfileptr,1);
                else
                    printChar(0x20, 1);
            }

            mcfgfileptr++;
            vsizefile--;
        }
    }
    else {
        printText("Loading file error...\r\n\0");
    }
}