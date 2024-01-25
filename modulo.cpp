//------------------------------------------------------------------------------------------------------------- 
// & - E para bits 
// ^ - OU para bits 
//------------------------------------------------------------------------------------------------------------- 
#include <stdio.h> 
#include <conio.h> 
#include <dos.h> 
#include <string.h> 
#include <windows.h>  //Necessário para: LoadLibrary(), GetProcAddress() e HINSTANCE.

#define LPT1od 0x378 // Saida Paralela 
#define LPT1oc 0x37A // Saida Paralela 
#define LPT1ic 0x379 // Leitura Paralela

#define Bursq      0x0C       // Em binario: 000011x0 
#define ADCSA0A7   0x05       // Em binario: 000001x1 
#define ADCSA8A15  0x04       // Em binario: 000001x0 
#define CSWR       0x00       // Em binario: 000000x0 
#define CSRDLsb    0x09       // Em binario: 000010x1 
#define CSRDMsb    0x08       // Em binario: 000010x0 
#define Desativa   0x01       // Em binario: 000000x1 

#define RetBusack  0x40       
#define RetReset   0x80
#define RetDados   0x78

unsigned char endlsb, endlsb_bkp;
unsigned char endmsb, endmsb_bkp;
unsigned char RetInput;	     // Para armazenar o valor recebido da Porta Paralela.
unsigned char RetByte;       // Para armazenar o valor recebido da Porta Paralela.

//Declaração dos ponteiros para função. 
typedef short _stdcall (*PtrInp)(short EndPorta); 
typedef void _stdcall (*PtrOut)(short EndPorta, short valor);

HINSTANCE hLib; //Instância para a DLL inpout32.dll.
PtrInp inportb;     //Instância para a função Imp32().
PtrOut outportb;  //Instância para a função Out32().

void delay(unsigned int ttempo);
void memoria(int vsel);
void GravarDados(unsigned char xdados);
int LerDados();

// Programa Principal
int main(int argc, char *argv[])
{
    FILE *fp;
	char xfilebin[100] = "c:\\moacir\\";
	int vnumFF = 0;
	int verro, verro2 = 0;
	int vnumerros;

	if (argc < 2)
	{
		printf("Erro. Nao foi passado o programa a ser enviado.\n");
		printf("Sintaxe: modulo <nome do arquivo>\n");
		return 0;
	}
	
    //Carrega a DLL na memória.
    hLib = LoadLibrary("inpout32.dll");

    if(hLib == NULL) //Verifica se houve erro.
    {
      printf("Erro. O arquivo inpout32.dll não foi encontrado.\n");
      getch();
      return -1;
    }

    //Obtém o endereço da função Inp32 contida na DLL.
    inportb = (PtrInp) GetProcAddress(hLib, "Inp32");

    if(inportb == NULL) //Verifica se houve erro.
    {
      printf("Erro. A função Inp32 não foi encontrada.\n");
      getch();
      return -1;
    }

    //Obtém o endereço da função Out32 contida na DLL.
    outportb = (PtrOut) GetProcAddress(hLib, "Out32");

    if(outportb == NULL) //Verifica se houve erro.
    {
       printf("Erro. A função Out32 não foi encontrada.\n");
       getch();
       return -1;
    }

	// Variaveis de Saida
	unsigned char dados;
	unsigned char dadosrec;

	clrscr();

	// Inicio da Rotina
	printf(">Iniciando Programação do Modulo. Usando %s.\n", argv[1]);
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	
	// Enviando Pedido de Bus Request (BURSQ)
	printf(">Enviando Pedido de DMA.\n");
	outportb(LPT1oc, Bursq);	 // Saida Para a Porta

	// Aguardando Bus Acknolange (BUSACK)
	RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
    RetByte = RetInput & RetBusack;
	while (RetByte != 0x00) {
		RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
	    RetByte = RetInput & RetBusack;
	}
	
	// Enviando Dados (Adress LSB -> MSB -> Dados)
	printf(">CPU em DMA.\n");
	strcat(xfilebin,argv[1]);
	fp = fopen(xfilebin,"rb");
	endlsb = 0x00;
	endmsb = 0x00;
	printf(">Enviando Dados.\n");
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta

	memoria(0);

	// Gravar Dados
	while ((!feof(fp)) && (vnumFF <= 20))
	{
		dados = getc(fp);
		
		if (dados == 0xFF)
			vnumFF += 1;

		if (dados != 0xFF)
			vnumFF = 0;
		
		verro = 0;
		while (verro == 0)
		{
			// Grava Dados
			printf(">%02X",endmsb);
			printf("%02X",endlsb);
			printf(" : %02X",dados);
			GravarDados(dados);

			// Verificar dado Gravado
			dadosrec = LerDados();
			printf("  -->  %02X\n",dadosrec);

			if (dados != dadosrec)
				verro = 0;
			else
				verro = 1;
		}
		
		if (endlsb == 0xFF)
		{
			endmsb += 1;
			endlsb = 0x00;
		}
		else
			endlsb += 1;
	}
	printf(">Dados Enviados.\n");
	fclose(fp);
	
	// Verifica Gravação
	vnumerros = 1;
	while (vnumerros != 0)
	{
		fp = fopen(xfilebin,"rb");
		endlsb = 0x00;
		endmsb = 0x00;
		vnumFF = 0;
		vnumerros = 0;
		printf(">Verificando Dados Gravados.\n");
		while ((!feof(fp)) && (vnumFF <= 20))
		{
			dados = getc(fp);
			
			if (dados == 0xFF)
				vnumFF += 1;

			if (dados != 0xFF)
				vnumFF = 0;

			// Verificar dados Gravados
			verro = 0;
			while (verro == 0)
			{
				dadosrec = LerDados();


				if (dados != dadosrec) 
				{
					printf(">%02X",endmsb);
					printf("%02X",endlsb);
					printf(" : %02X",dados);
					printf("  -->  %02X\n",dadosrec);
					GravarDados(dados);
					vnumerros++;
					verro = 0;
					verro2 = 1;
				}
				else {
					if (verro2 == 1)
					{
						printf(">%02X",endmsb);
						printf("%02X",endlsb);
						printf(" : %02X",dados);
						printf("  -->  %02X\n",dadosrec);
					}
					verro = 1;
					verro2 = 0;
				}
			}

			if (endlsb == 0xFF)
			{
				endmsb += 1;
				endlsb = 0x00;
			}
			else
				endlsb += 1;
		}
		fclose(fp);
	}

	// Fim do Envio, Aguardando Reinicialização do modulo (RESET)
	printf(">Numero de Erros de Leitura: %i\n", vnumerros);
	printf(">Reinicialize o Modulo para Iniciar o Processamento.\n");
	RetByte = 0xFF;
	while (RetByte != 0x00)
	{
	  RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
	  RetByte = ~RetInput & RetReset;
	}

	// Fim da Rotina
	if (vnumerros == 0)
		printf(">Modulo Reinicializado. Bom Teste.\n");
	else
		printf(">Gravação com Problemas. Verifique.\n");

	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	FreeLibrary(hLib); //Libera memória alocada pela DLL.
	return(0);
}

void delay(unsigned int ttempo)
{
	for (unsigned int i = 0; i <= ttempo; i++);
}

void memoria(int vsel)
{
	if (vsel == 0)
	{
		// Envia endereço LSB Para Deselecionar a Memoria
		outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
		outportb(LPT1od, 0xFF);	 // Saida Para a Porta
		delay(10000);
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta
		delay(10000);

		// Envia endereço MSB Para Deselecionar a Memoria
		outportb(LPT1oc, ADCSA8A15);	 // Saida Para a Porta
		outportb(LPT1od, 0xFF);	 // Saida Para a Porta
		delay(10000);
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta
		delay(10000);
	}
	else {
		// Envia endereço LSB
		outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
		outportb(LPT1od, endlsb);	 // Saida Para a Porta
		delay(10000);
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta
		delay(10000);
//sleep(1);

		// Envia endereço MSB
		outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
		outportb(LPT1od, endmsb);	 // Saida Para a Porta
		delay(10000);
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta
		delay(10000);
//sleep(1);
	}
}

void GravarDados(unsigned char xdados)
{
	// Envia Dados
	memoria(1);
	outportb(LPT1oc, CSWR);	 // Saida Para a Porta
//sleep(10);
	outportb(LPT1od, xdados);	 // Saida Para a Porta
	delay(10000);
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	delay(10000);
	memoria(0);
	delay(10000);
}

int LerDados()
{
	unsigned char xdadosrec;

	memoria(1);
	outportb(LPT1oc, CSRDMsb);	 // Saida Para a Porta
//sleep(5);
	delay(10000);
	RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
	RetByte = RetInput & RetDados;
	RetByte <<= 1;
	xdadosrec = RetByte;
	outportb(LPT1oc, CSRDLsb);	 // Saida Para a Porta
//sleep(10);
	delay(10000);
	RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
	RetByte = RetInput & RetDados;
	RetByte >>= 3;
	xdadosrec = xdadosrec | RetByte;
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);

	return xdadosrec;
}
