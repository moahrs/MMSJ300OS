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

unsigned char endlsb;
unsigned char endmsb;
unsigned char RetInput;	     // Para armazenar o valor recebido da Porta Paralela.
unsigned char RetByte;       // Para armazenar o valor recebido da Porta Paralela.

//Declaração dos ponteiros para função. 
typedef short _stdcall (*PtrInp)(short EndPorta); 
typedef void _stdcall (*PtrOut)(short EndPorta, short valor);

HINSTANCE hLib; //Instância para a DLL inpout32.dll.
PtrInp inportb;     //Instância para a função Imp32().
PtrOut outportb;  //Instância para a função Out32().

void tempo(unsigned int ttempo);
void memoria(int vsel);
void GravarDados(unsigned char xdados);
void GravarComandosDados(unsigned char xdados);
int LerDados();

// Programa Principal
int main(int argc, char *argv[])
{
    FILE *fp;
	char xfilebin[100] = "c:\\moacir\\";
	int vnumFF = 0, verro, vnumerros, verrosprog, vprogfim;
	unsigned char dados, dadosrec, vbit5, vbit6a, vbit6b, vbit7;
	unsigned char aendlsb, aendmsb;

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
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta

	memoria(0);

	// Resetar Memoria Flash
	// Trazer Informações da Memoria Flash em Uso
	endlsb = 0x00;
	endmsb = 0x00;
	GravarDados(0xF0);
	tempo(10000);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0xAA);
	endlsb = 0xAA;
	endmsb = 0x02;
	GravarDados(0x55);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0x90);
	endlsb = 0x00;
	endmsb = 0x00;
	dadosrec = LerDados();
	printf("Manufacturer ID  -->  %02X\n",dadosrec);
	endlsb = 0x00;
	endmsb = 0x00;
	GravarDados(0xF0);
	tempo(10000);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0xAA);
	endlsb = 0xAA;
	endmsb = 0x02;
	GravarDados(0x55);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0x90);
	endlsb = 0x01;
	endmsb = 0x00;
	dadosrec = LerDados();
	printf("Device ID  -->  %02X\n",dadosrec);
	endlsb = 0x00;
	endmsb = 0x00;
	GravarDados(0xF0);
	tempo(10000);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0xAA);
	endlsb = 0xAA;
	endmsb = 0x02;
	GravarDados(0x55);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0x90);
	endlsb = 0x03;
	endmsb = 0x00;
	dadosrec = LerDados();
	printf("Continuation ID  -->  %02X\n",dadosrec);
	endlsb = 0x00;
	endmsb = 0x00;
	GravarDados(0xF0);
	tempo(10000);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0xAA);
	endlsb = 0xAA;
	endmsb = 0x02;
	GravarDados(0x55);
	endlsb = 0x55;
	endmsb = 0x05;
	GravarDados(0x90);
	endlsb = 0x02;
	endmsb = 0x00;
	dadosrec = LerDados();
	printf("Sector 00h Protect Verify  -->  %02X\n",dadosrec);
 //amic--------------------	write "f0"h to exit Auto select mode
  endlsb = 0x00;
	endmsb = 0x00;
	GravarDados(0xF0);
	tempo(10000);
 //-------------------------
	// Apagar Setor 00 (primeiros 32k)
	printf(">Apagando Primeiros 32KB Memoria Flash.\n");
	verro = 1;	
	while (verro)
	{
		//printf(">Apagando Primeiros 32KB Memoria Flash.\n");
		//endlsb = 0x00;
		//endmsb = 0x00;
		//GravarDados(0xF0);
		//tempo(10000);
		
		endlsb = 0x55;
		endmsb = 0x05;
		GravarDados(0xAA);
		
		endlsb = 0xAA;
		endmsb = 0x02;
		GravarDados(0x55);
		
		endlsb = 0x55;
		endmsb = 0x05;
		GravarDados(0x80);
		
		endlsb = 0x55;
		endmsb = 0x05;
		GravarDados(0xAA);
		
		endlsb = 0xAA;
		endmsb = 0x02;
		GravarDados(0x55);
		
		endlsb = 0x00;
		endmsb = 0x00;
		GravarDados(0x30);
		
		//sleep(2);  //amic (don't need delay)

		// Verifica se Erase Sector Terminou 
		// Primeira Leitura
		//endlsb = 0xFF;
		//endmsb = 0x7F;
		endlsb = 0x00;  //amic
		endmsb = 0x00;
		dadosrec = LerDados();
		//vbit6a = dadosrec & 0x40;
		vprogfim = 1;
		while (vprogfim)
		{
			// Segunda Leitura
			dadosrec = LerDados();
			//vbit5 = dadosrec & 0x20;
			//vbit6b = dadosrec & 0x40;

			// verifica se Bit IO6 mudou
			//if (vbit6a == vbit6b)
			if(dadosrec == 0xff)
			{
				vprogfim = 0;
				verro = 0;
			}
			else
			{
				//if (vbit5 == 0x20)
				if((dadosrec & 0x20)==0x20)
				{
					// Primeira Leitura
					dadosrec = LerDados();
					//vbit6a = dadosrec & 0x40;

					// Segunda Leitura
					//dadosrec = LerDados();
					//vbit6b = dadosrec & 0x40;
		
					// verifica se Bit IO6 mudou
					//if (vbit6a == vbit6b)
					if(dadosrec == 0xff)
					{
						// Se nao mudou, envia novo pedido de Erase Sector
						vprogfim = 0;
						verro = 0;
					}
					else
					 {
						vprogfim = 0;
						endlsb = 0x00;
	          endmsb = 0x00;
	          GravarDados(0xF0);
	          tempo(10000);
					 }
				}
			}
		}
	}

	// Gravar Dados
	printf(">Enviando Dados.\n");
	vnumerros = 0;
	endlsb = 0x00;
	endmsb = 0x00;
	while ((!feof(fp)) && (vnumFF <= 20))
	{
		// Ler primeiro byte do arquivo a ser gravado
		dados = getc(fp);
		
		// Se tiver mais de 20 FFh, encerra leitura
		if (dados == 0xFF)
			vnumFF += 1;

		if (dados != 0xFF)
			vnumFF = 0;
		
		// Inicia Gravação do byte lido do arquivo
		verrosprog = 0;
		
		verro = 1;

		//if (endmsb == 0x05 && endlsb == 0x55)
		//	verro = 0;
		
		while (verro)
		{
			// Envia Comandos e Dados para Gravar
			printf(">%02X",endmsb);
			printf("%02X",endlsb);
			printf(" : %02X",dados);
			GravarComandosDados(dados);

			// Verifica se Algoritimo de Programacao da Flash Terminou
			vprogfim = 1;
			while (vprogfim)
			{
				// Ler Status
				dadosrec = LerDados();
				//vbit7 = dadosrec & 0x80;
				//vbit6a = dadosrec & 0x40;

				// Verifica se bit IO7 = Bit 7 do dado enviado
				//if (vbit7 == (dados & 0x80))
				if (dadosrec == dados )
					vprogfim = 0;
				else
				{
					// Bit IO7 <> bit 7 dados, verifica bit IO6
					//if (vbit6a == 0x40)
					if ((dadosrec & 0x20) == 0x20)
					{
						// Bit IO6 ativado, verifica denovo bit IO7
						dadosrec = LerDados();
						//vbit7 = dadosrec & 0x80;
						
						// Verifica se bit IO7 = Bit 7 do dado enviado
						//if (vbit7 == (dados & 0x80))
						if (dadosrec == dados )
							vprogfim = 0;
						else
						{
							// Bit IO7 <> bit 7, gera erro de gravação
							vprogfim = 0;
							verro = 2;
							GravarDados(0xF0);
				      tempo(10000);
						}
					}
				}
			}
			
			// Verifica se houve erro, se sim, reinicia nova gravação mesmo byte
			if (verro == 2) {
				printf("  -->  ERRO DE GRAVACAO\n");
				verro = 1;
			}
			else
			{
				// Verificar dado Gravado
				GravarDados(0xF0);
				tempo(10000);
				dadosrec = LerDados();
				printf("  -->  %02X\n",dadosrec);

				// Verifica dados iguais, se nao, reinicia nova gravação mesmo byte
				if (dados == dadosrec)
				{
					verro = 0;
					vnumerros++;
				}
			}

			if (verro)
				verrosprog++;

//			if (verrosprog >= 40)
//				verro = 0;
		}

		// Soma endereço para o proximo a ser gravado
		if (endlsb == 0xFF)
		{
			endmsb++;
			endlsb = 0x00;
		}
		else
			endlsb++;
	}
	printf(">Dados Enviados.\n");
	fclose(fp);
	
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
	printf(">Modulo Reinicializado. Bom Teste.\n");

	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	FreeLibrary(hLib); //Libera memória alocada pela DLL.
	return(0);
}

void tempo(unsigned int ttempo)
{
	for (unsigned int i = 0; i <= ttempo; i++);
}

void memoria(int vsel)
{
	if (vsel)
	{
		// Envia endereço LSB
		outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
		outportb(LPT1od, endlsb);	 // Saida Para a Porta
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta

		// Envia endereço MSB
		outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
		outportb(LPT1od, endmsb);	 // Saida Para a Porta
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	}
	else {
		// Envia endereço MSB Para Deselecionar a Memoria
		outportb(LPT1oc, ADCSA8A15);	 // Saida Para a Porta
		outportb(LPT1od, 0xFF);	 // Saida Para a Porta
		outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	}
}

void GravarComandosDados(unsigned char xdados)
{
	outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
	outportb(LPT1od, 0x00);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
	outportb(LPT1od, 0x00);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1od, 0xF0);		 // Saida Para a Porta
	outportb(LPT1oc, CSWR);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);
	outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
	outportb(LPT1od, 0x55);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
	outportb(LPT1od, 0x05);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1od, 0xAA);		 // Saida Para a Porta
	outportb(LPT1oc, CSWR);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);
	outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
	outportb(LPT1od, 0xAA);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
	outportb(LPT1od, 0x02);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1od, 0x55);		 // Saida Para a Porta
	outportb(LPT1oc, CSWR);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);
	outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
	outportb(LPT1od, 0x55);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
	outportb(LPT1od, 0x05);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1od, 0xA0);		 // Saida Para a Porta
	outportb(LPT1oc, CSWR);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);
	outportb(LPT1oc, ADCSA0A7);	 // Saida Para a Porta
	outportb(LPT1od, endlsb);	 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1oc, ADCSA8A15); // Saida Para a Porta
	outportb(LPT1od, endmsb);	 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	outportb(LPT1od, xdados);	 // Saida Para a Porta
	outportb(LPT1oc, CSWR);	     // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);
}

void GravarDados(unsigned char xdados)
{
	// Grava Dados
	memoria(1);
	outportb(LPT1od, xdados);	 // Saida Para a Porta
	outportb(LPT1oc, CSWR);		 // Saida Para a Porta
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);
}

int LerDados()
{
	unsigned char xdadosrec;

	memoria(1);
	outportb(LPT1oc, CSRDMsb);	 // Saida Para a Porta
	RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
	RetByte = RetInput & RetDados;
	RetByte <<= 1;
	xdadosrec = RetByte;
	outportb(LPT1oc, CSRDLsb);	 // Saida Para a Porta
	RetInput = inportb(LPT1ic);  //Ler um byte da Porta Paralela.
	RetByte = RetInput & RetDados;
	RetByte >>= 3;
	xdadosrec = xdadosrec | RetByte;
	outportb(LPT1oc, Desativa);	 // Saida Para a Porta
	memoria(0);

	return xdadosrec;
}
