/********************************************************************************
*    Programa    : flashprog.c
*    Objetivo    : Rotina para gravar memoria flash no modulo MMSJ300 - SERIAL
*    Criado em   : 31/08/2022
*    Programador : Moacir Jr.
*--------------------------------------------------------------------------------
*   ------------------------------------------
*   PROTOCOLO DE COMUNICACAO:
*   ------------------------------------------
*   SENTIDO  
*    PC/PIC  COMANDO  FUNÇÃO
*       ->   DDDD     INICIA COMUNICACAO
*    <-      DDDD     COMUNICACAO ESTABELECIDA
*    <- ->   DDdd     RECEBE OU ENVIA DADO (dd)
*       ->   EE00     DADO VERIFICADO COM SUCESSO
*       ->   EE01     ERRO NA VERIFICAÇÃO DO DADO
*    <-      EE69     ENVIAR BYTE
*    <-      EE70     INICIO DO PROCESSO DE GRAVAÇÃO
*    <-      EE71     GRAVAÇÃO BYTE OK
*    <-      EE72     GRAVAÇÃO BYTE COM ERRO
*    <-      EE73     TERMINO DO PROCESSO DE GRAVAÇÃO
*       ->   EEDD     ENCERRA COMUNICACAO
*   ------------------------------------------
*   
*   ------------------------------------------
*   SENDROM deve enviar de 2 em 2 (0x00, 0x02, 0x04 ou 0x01, 0x03, 0x05 e etc...)
*   ------------------------------------------
*--------------------------------------------------------------------------------
* Data        Responsavel  Motivo
* 31/08/2022  Moacir Jr.   Desenvolvimento
********************************************************************************/

#define OUT_RW      49  // PL0
#define OUT_AS      48  // PL1
#define OUT_LDS     47  // PL2
#define OUT_UDS     46  // PL3
#define OUT_BG      45  // PL4  <-
#define OUT_BR      44  // PL5  ->
#define OUT_BGACK   43  // PL6  ->

#define Pin_D0      22  // PA0
#define Pin_D1      23  // PA1
#define Pin_D2      24  // PA2
#define Pin_D3      25  // PA3
#define Pin_D4      26  // PA4
#define Pin_D5      27  // PA5
#define Pin_D6      28  // PA6
#define Pin_D7      29  // PA7
#define Pin_D8      37  // PC0
#define Pin_D9      36  // PC1
#define Pin_D10     35  // PC2
#define Pin_D11     34  // PC3
#define Pin_D12     33  // PC4
#define Pin_D13     32  // PC5
#define Pin_D14     31  // PC6
#define Pin_D15     30  // PC7

#define OUT_A1      A1  // PF1
#define OUT_A2      A2  // PF2
#define OUT_A3      A3  // PF3
#define OUT_A4      A4  // PF4
#define OUT_A5      A5  // PF5
#define OUT_A6      A6  // PF6
#define OUT_A7      A7  // PF7
#define OUT_A8      A8  // PK0
#define OUT_A9      A9  // PK1
#define OUT_A10     A10 // PK2
#define OUT_A11     A11 // PK3
#define OUT_A12     A12 // PK4
#define OUT_A13     A13 // PK5
#define OUT_A14     A14 // PK6
#define OUT_A15     A15 // PK7
#define OUT_A16     21  // PD0
#define OUT_A17     20  // PD1
#define OUT_A18     17  // PH0

#define OUT_A21     2   // PE4
#define OUT_A22     3   // PE5
#define OUT_A23     7   // PE5

#define OUT_FC0      4  // PE6
#define OUT_FC1      5  // PE7
#define OUT_FC2      6  // PE8

//--- Constante para Gravação Final ou Testes na FLASH ATMEL AT29C020
#define __AT29C020__
#define __INVERT__

//--- VARIAVEIS DE USO GLOBAL
unsigned char pbyteler0[129];
unsigned char pbyteler1[129];
unsigned char pbyteler2[129];
unsigned char pbyteler3[129];
unsigned char vendmsb, vendmsb2, vendlsb;
unsigned char pDMA = 0;

void setup() {
  DDRA = 0b00000000;
  DDRC = 0b00000000;
  DDRF = 0b00000000;
  DDRK = 0b00000000;

  pinMode(OUT_RW,INPUT);
  pinMode(OUT_AS,INPUT);
  pinMode(OUT_LDS,INPUT);
  pinMode(OUT_UDS,INPUT);
  pinMode(OUT_FC0,INPUT);
  pinMode(OUT_FC1,INPUT);
  pinMode(OUT_FC2,INPUT);
  pinMode(OUT_BR,OUTPUT);
  digitalWrite(OUT_BR,HIGH);
  pinMode(OUT_BG,INPUT);
  pinMode(OUT_BGACK,OUTPUT);
  digitalWrite(OUT_BGACK,HIGH);

  pinMode(OUT_A16,INPUT);
  pinMode(OUT_A17,INPUT);
  pinMode(OUT_A18,INPUT);
  pinMode(OUT_A21,INPUT);
  pinMode(OUT_A22,INPUT);
  pinMode(OUT_A23,INPUT);

  Serial.begin(9600);
  Serial1.begin(19200);

  Serial.println("Start....");
}

void loop() {
  ComunicarSerial();
}

//------------------------------------------------------------
void ComunicarSerial(void)
{
  unsigned char inputBuffer, vdados, vcom, vinicio, vvar;
  unsigned char vendlsba, vendmsba, vendmsba2, vreclsb, vrecmsb;
  unsigned int cc, dd, vcont;

  inputBuffer = 0;
  vinicio = 0x00;
  vdados = 0;
  vcom = 1;
  vcont = 0x01;
  vreclsb = 0;
  vrecmsb = 0;
  vvar = 1;

  vendlsb = 0x00;
  vendmsb = 0x00;
  vendmsb2 = 0x00;

  while(vcom)
  {
    inputBuffer = 0;

    while(!(Serial1.available() > 0));

    inputBuffer = Serial1.read();

    if (vdados == 0 && inputBuffer == 0xDD) {
      if (vinicio == 0x00)
        vinicio = 0x01;
      else if (vinicio == 0x01) {
        vinicio = 0x02;

        Serial1.write(0xDD);
        Serial1.write(0xDD);
      }
      else if (vinicio == 0x02)
        vdados = 1;
      else if (vinicio == 0x03)
        vcom = 0;
    }
    else if (vdados == 0 && inputBuffer == 0x00) {
      // Comparação nos Bytes PC OK
      vinicio = 0x02;

      if (!vreclsb) {
        vreclsb = 1;

        Serial1.write(0xEE);  // Avisa PC para continuar enviando Byte's
        Serial1.write(0x69);
      }
      else if (!vrecmsb) {
        vrecmsb = 1;

        Serial1.write(0xEE);  // Avisa PC para continuar enviando Byte's
        Serial1.write(0x69);
      }
      else if (vreclsb && vrecmsb) {
        if (vvar == 4 && vcont == 128) {
          EnviarDados();
  
          vcont = 1;
          vvar = 1;
        }
        else {
          Serial1.write(0xEE);  // Avisa PC para continuar enviando Byte's
          Serial1.write(0x69);
          
          vcont++;

          if (vcont == 129) {
              vvar += 1;
              vcont = 1;
          }       
        }
      }
    }
    else if (vdados == 0 && inputBuffer == 0x01) {
      // Erro de Comparação nos Bytes PC
      vinicio = 0x02;
    }
    else if (vdados == 1) {
      vdados = 0;

      if (!vreclsb) {
        vendlsb = inputBuffer;
        char buf2[80];
        snprintf(buf2, 80, "Start Address LSB: %02X - ", vendlsb);
        Serial.println(buf2);
      }
      else if (!vrecmsb) {
        vendmsb = inputBuffer;
        char buf2[80];
        snprintf(buf2, 80, "Start Address MSB: %02X - ", vendmsb);
        Serial.println(buf2);
      }
      else if (vreclsb && vrecmsb) {
        switch (vvar) {
          case 1:
            pbyteler0[vcont] = inputBuffer;
            break;
          case 2:
            pbyteler1[vcont] = inputBuffer;
            break;
          case 3:
            pbyteler2[vcont] = inputBuffer;
            break;
          case 4:
            pbyteler3[vcont] = inputBuffer;
            break;
        }   
      }
            
      Serial1.write(0xDD);
      Serial1.write(inputBuffer);
    }
    else if (vdados == 0 && inputBuffer == 0xEE)
      vinicio = 0x03;
  }

  if (vcont != 0x01) {
    vcont--;
    EnviarDados();
  }
  else{
    Serial1.write(0xEE);  // Avisa PC para continuar enviando Byte's
    Serial1.write(0x69);
  }
}

//------------------------------------------------------------
void EnviarDados(void)
{
  unsigned char vbytelsb, vbytemsb, verro, verroc, vqtda;
  unsigned char vendlsba, vendmsba, vendmsba2, vendlsbr, vendmsbr, vendmsbr2;
  unsigned char cc, dd;
  unsigned int vbyte, vdado;

  if (!pDMA)
  {
    if (digitalRead(OUT_BG))
      Serial.println("BG High....");
    else
      Serial.println("BG Low....");

    Serial.println("Bus Requesting....");
    
    // Ativa BR
    digitalWrite(OUT_BR,LOW);

    // Aguarda BG
    while (digitalRead(OUT_BG));

    Serial.println("Bus Granted....");

    // Ativa BGACK
    digitalWrite(OUT_BGACK,LOW);

    pDMA = 1;

    delay(2);

    DDRF = 0b11111111;
    DDRK = 0b11111111;

    pinMode(OUT_A16,OUTPUT);
    pinMode(OUT_A17,OUTPUT);
    pinMode(OUT_A18,OUTPUT);    
    pinMode(OUT_A21,OUTPUT);
    pinMode(OUT_A22,OUTPUT);
    pinMode(OUT_A23,OUTPUT);
    pinMode(OUT_FC0,OUTPUT);
    pinMode(OUT_FC1,OUTPUT);
    pinMode(OUT_FC2,OUTPUT);
    pinMode(OUT_RW,OUTPUT);
    pinMode(OUT_AS,OUTPUT);
    pinMode(OUT_LDS,OUTPUT);
    pinMode(OUT_UDS,OUTPUT);

    digitalWrite(OUT_A16,LOW);
    digitalWrite(OUT_A17,LOW);
    digitalWrite(OUT_A18,LOW);
    digitalWrite(OUT_A21,LOW);
    digitalWrite(OUT_A22,LOW);
    digitalWrite(OUT_A23,LOW);
    digitalWrite(OUT_FC0,LOW);
    digitalWrite(OUT_FC1,LOW);
    digitalWrite(OUT_FC2,LOW);
    digitalWrite(OUT_RW,HIGH);
    digitalWrite(OUT_AS,HIGH);
    digitalWrite(OUT_LDS,HIGH);
    digitalWrite(OUT_UDS,HIGH);
  }

  Serial1.write(0xEE);  // Avisa PC que iniciou o processo de gravação
  Serial1.write(0x70);

  verro = 1;

  vendlsba = vendlsb;
  vendmsba = vendmsb;
  vendmsba2 = vendmsb2;

  // Gravando Chip  
  while (verro) {
    //--- PORTA A e C como Saida
    DDRA = 0b11111111;
    DDRC = 0b11111111;

    //--- Inicia Gravação de 256 bytes em Sequencia
    vendlsb = vendlsba;
    vendmsb = vendmsba;
    vendmsb2 = vendmsba2;

    for (dd = 1; dd <= 4; dd++){
        for (cc = 1; cc <= 127; cc += 2){
          //--- Envia Dados
          switch (dd) {
            case 1:
              GravaDado(pbyteler0[cc], pbyteler0[cc + 1]);
              break;
            case 2:
              GravaDado(pbyteler1[cc], pbyteler1[cc + 1]);
              break;
            case 3:
              GravaDado(pbyteler2[cc], pbyteler2[cc + 1]);
              break;
            case 4:
              GravaDado(pbyteler3[cc], pbyteler3[cc + 1]);
              break;
          }

          if (dd != 4 || cc != 127) {
            if (vendlsb == 0xFE && vendmsb == 0xFF)
            {
              vendmsb2++;
              vendmsb = 0x00;
              vendlsb = 0x00;
            }

            if (vendlsb == 0xFE)
            {
              vendmsb++;
              vendlsb = 0x00;
            }
            else
              vendlsb += 2;
          }
        }
    }       
        
    #ifdef __AT29C020__ 
      // delay de 50mS
      delay(50);

      //--- Verifica se Processo de Gravação Terminou
      verroc = 1;
      vqtda = 0;

      SetaEndereco();

      //--- PORTA A e C como Entrada
      DDRA = 0b00000000;
      DDRC = 0b00000000;

      while (verroc && vqtda <= 0x7F) {
        digitalWrite(OUT_LDS,LOW);
        digitalWrite(OUT_UDS,LOW);
        digitalWrite(OUT_RW,HIGH);
        digitalWrite(OUT_AS,LOW);
        asm("nop");
        asm("nop");

        #ifdef __INVERT__
          vbytemsb = PINA;
          vbytelsb = PINC;
        #else
          vbytelsb = PINA;
          vbytemsb = PINC;
        #endif

        asm("nop");
        digitalWrite(OUT_AS,HIGH);
        digitalWrite(OUT_LDS,HIGH);
        digitalWrite(OUT_UDS,HIGH);
    
        //--- Compara se IO7 = IO7 do byte gravado
        if ((vbytelsb & 0x80) == (pbyteler3[127] & 0x80) && (vbytemsb & 0x80) == (pbyteler3[128] & 0x80)) 
        {
          //--- Compara se byte lido = byte recebido
          if (vbytelsb == pbyteler3[127] && vbytemsb == pbyteler3[128])
            verroc = 0;
        }
        vqtda++;
      }
    #endif

    if (vendlsb == 0xFE && vendmsb == 0xFF)
    {
      vendmsb2++;
      vendmsb = 0x00;
      vendlsb = 0x00;
    }

    if (vendlsb == 0xFE)
    {
      vendmsb++;
      vendlsb = 0x00;
    }
    else
      vendlsb += 2;

    //--- Inicia Leitura dos 256 Bytes Gravados pra ver se Esta OK
    verro = 0;

    vendlsbr = vendlsb;
    vendmsbr = vendmsb;
    vendmsbr2 = vendmsb2;

    vendlsb = vendlsba;
    vendmsb = vendmsba;
    vendmsb2 = vendmsba2;

    for (dd = 1; dd <= 4; dd++){
        for (cc = 1; cc <= 127; cc += 2){
          SetaEndereco();
      
          //--- PORTA A e C como Entrada
          DDRA = 0b00000000;
          DDRC = 0b00000000;
      
          digitalWrite(OUT_LDS,LOW);
          digitalWrite(OUT_UDS,LOW);
          digitalWrite(OUT_RW,HIGH);
          digitalWrite(OUT_AS,LOW);
          asm("nop");
          asm("nop");
          asm("nop");

/*          if (vendmsb == 0x05 && vendlsb == 0x5A )
          {
            Serial.println("Stopped");
            for (;;);
          }*/

          #ifdef __INVERT__
            vbytemsb = PINA;
            vbytelsb = PINC;
          #else
            vbytelsb = PINA;
            vbytemsb = PINC;
          #endif

          asm("nop");
          digitalWrite(OUT_AS,HIGH);
          digitalWrite(OUT_LDS,HIGH);
          digitalWrite(OUT_UDS,HIGH);
      
          //--- Compara se byte lido = byte recebido
          switch (dd) {
            case 1:
                vdado = (pbyteler0[cc] | (pbyteler0[cc + 1] << 8));
                break;
            case 2:
                vdado = (pbyteler1[cc] | (pbyteler1[cc + 1] << 8));
                break;
            case 3:
                vdado = (pbyteler2[cc] | (pbyteler2[cc + 1] << 8));
                break;
            case 4:
                vdado = (pbyteler3[cc] | (pbyteler3[cc + 1] << 8));
                break;
          }

          vbyte = (vbytelsb | (vbytemsb << 8));
                
//          if (vbyte > 0 && vbyte != vdado) for(;;);

          if (vbyte != vdado)
          {
            verro = 1;
            char buf2[80];
            snprintf(buf2, 80, "Error At Addr: %02X%02X%02X - ", vendmsb2, vendmsb, vendlsb);
            Serial.print(buf2);
            snprintf(buf2, 80, "Write: %02X, Read: %02X", vdado, vbyte );
            Serial.println(buf2);
//            break;
          }
    
          if (vendlsb == 0xFE && vendmsb == 0xFF)
          {
            vendmsb2++;
            vendmsb = 0x00;
            vendlsb = 0x00;
          }

          if (vendlsb == 0xFE)
          {
            vendmsb++;
            vendlsb = 0x00;
          }
          else
            vendlsb += 2;
        }

/*        if (verro)
          break;*/
    } 

    if (verro) {
      Serial1.write(0xEE);  // Avisa PC que Gravação Byte Falhou, Tentando Novamente
      Serial1.write(0x72);
      Serial1.write(0xEE);
      Serial1.write(vendlsb);
      Serial1.write(0xEE);
      Serial1.write(vbyte);
      Serial1.write(0xEE);
      Serial1.write((unsigned char) (vdado & 0x00FF) );
    }
    else {
      Serial1.write(0xEE);  // Avisa PC que Gravação Byte OK
      Serial1.write(0x71);
    }

    vendlsb = vendlsbr;
    vendmsb = vendmsbr;
    vendmsb2 = vendmsbr2;
  }   

  Serial1.write(0xEE);  // Avisa PC que acabou gravação e que pode enviar mais 256 Bytes
  Serial1.write(0x73);
}

//------------------------------------------------------------
void SetaEndereco(void)
{
  //--- Envia Endereço LSB
  PORTF = vendlsb;
  PORTK = vendmsb;
  digitalWrite(OUT_A16, (vendmsb2 & 0x01));
  digitalWrite(OUT_A17, ((vendmsb2 & 0x02) >> 1));
  digitalWrite(OUT_A18, ((vendmsb2 & 0x04) >> 2));  
}

//------------------------------------------------------------
void GravaDado(unsigned char vbytelsb, unsigned char vbytemsb)
{
  SetaEndereco();

  #ifdef __INVERT__
    PORTA = vbytemsb;
    PORTC = vbytelsb;
  #else
    PORTA = vbytelsb;
    PORTC = vbytemsb;
  #endif

  digitalWrite(OUT_RW,LOW);
  digitalWrite(OUT_LDS,LOW);
  digitalWrite(OUT_UDS,LOW);
  digitalWrite(OUT_AS,LOW);
  asm("nop");
  asm("nop");
  asm("nop");
  //if (vbyte != 0x00) for(;;);
  digitalWrite(OUT_AS,HIGH);
  digitalWrite(OUT_LDS,HIGH);
  digitalWrite(OUT_UDS,HIGH);
  digitalWrite(OUT_RW,HIGH);
}
