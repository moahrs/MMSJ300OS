// MFP MC68901p Definitions
// ------------------------------
// AAAAAAAAAAAAA
// 1119876543210 
// 210  
// -------------
// RRRRR00000001
// SSSSS
// 54321
//
// A0 = Always 1 to activate LDS
// A1 - A7 = Always 0
// -----------------------------

// MFP MC68901p USART Registers
WORD Reg_UCR   =  0x1401;  // 0x29
WORD Reg_UDR   =  0x1701;  // 0x2F
WORD Reg_RSR   =  0x1501;  // 0x2B
WORD Reg_TSR   =  0x1601;  // 0x2D

// MFP MC68901p Interrupt Registers
WORD Reg_VR    =  0x0B01;  // 0x17
WORD Reg_IERA  =  0x0301;  // 0x07
WORD Reg_IERB  =  0x0401;  // 0x09
WORD Reg_IPRA  =  0x0501;  // 0x0B
WORD Reg_IPRB  =  0x0601;  // 0x0D
WORD Reg_IMRA  =  0x0901;  // 0x13
WORD Reg_IMRB  =  0x0A01;  // 0x15
WORD Reg_ISRA  =  0x0701;  // 0x0F
WORD Reg_ISRB  =  0x0801;  // 0x11

// MFP MC68901p Timers Registers
WORD Reg_TADR  =  0x0F01;  // 0x1F
WORD Reg_TBDR  =  0x1001;  // 0x21
WORD Reg_TCDR  =  0x1101;  // 0x23
WORD Reg_TDDR  =  0x1201;  // 0x25
WORD Reg_TACR  =  0x0C01;  // 0x19
WORD Reg_TBCR  =  0x0D01;  // 0x1B
WORD Reg_TCDCR =  0x0E01;  // 0x1D

// MFP MC68901p GPIO Registers
WORD Reg_GPDR  =  0x0001;  // 0x01
WORD Reg_AER   =  0x0101;  // 0x03
WORD Reg_DDR   =  0x0201;  // 0x05

//#define __MON_SERIAL__
//#define __MON_SERIAL_VDG__
//#define __MON_SERIAL_KBD__
#define __TMS9xxx__
#define __KEYPS2_EXT__

void delayms(int pTimeMS);
void delayus(int pTimeUS);
void clearScr(void);
void clearScrAlt(void);
void printChar(unsigned char pchr, unsigned char pmove);
void printText(unsigned char *msg);
void readChar(void);
unsigned char inputLine(unsigned int pQtdInput, unsigned char pTipo);
int processCmd(void);
void writeSerial(unsigned char pchr);
void writeLongSerial(unsigned char *msg);
unsigned char loadSerialToMem(unsigned char *pEnder, unsigned char ptipo);
void runMem(unsigned long pEnder);
void pokeMem(unsigned char *pEnder, unsigned char *pByte);
void dumpMem (unsigned char *pEnder, unsigned char *pqtd, unsigned char *pCols);
void dumpMem2 (unsigned char *pEnder, unsigned char *pqtd);
void basicFuncBios(void);
unsigned long hexToLong(char *pHex);
unsigned long pow(int val, int pot);
int hex2int(char ch);
void asctohex(unsigned char a, unsigned char *s);
void runCmd(void);

void setRegister(unsigned char registerIndex, unsigned char value);
unsigned char read_status_reg(void);
void setWriteAddress(unsigned int address);
void setReadAddress(unsigned int address);

/**
 * @brief initialize the VDP
 * Not all parameters are useful for all modes. Refer to documentation
 * 
 * @param mode VDP_MODE_G1 | VDP_MODE_G2 | VDP_MODE_MULTICOLOR | VDP_MODE_TEXT
 * @param color 
 * @param big_sprites true: Use 16x16 sprites false: use 8x8 sprites
 * @param magnify true: Scale sprites up by 2
 * @return int 
 */
int vdp_init(unsigned char mode, unsigned char color, unsigned char big_sprites, unsigned char magnify);

/**
 * @brief Initializes the VDP in text mode
 * 
 * @param fgcolor Text color default: default black
 * @param bgcolor Background color: default white
 * @returns VDP_ERROR | VDP_SUCCESS 
 */
int vdp_init_textmode(unsigned char fg, unsigned char bg);


/**
 * @brief Initializes the VDP in Graphic Mode 1
 * 
 * @param fgcolor Text color default: default black
 * @param bgcolor Background color: default white
 * @returns VDP_ERROR | VDP_SUCCESS 
 * @deprecated Not really useful if more than 4k Video ram is available
 */
int vdp_init_g1(unsigned char fg, unsigned char bg); 

/**
 * @brief Initializes the VDP in Graphic Mode 2
 * 
 * @param big_sprites true: use 16x16 sprites false: use 8x8 sprites
 * @param scale_sprites Scale sprites up by 2
 * @returns VDP_ERROR | VDP_SUCCESS 
 */
int vdp_init_g2(unsigned char big_sprites, unsigned char scale_sprites); 

/**
 * @brief Initializes the VDP in 64x48 Multicolor Mode 
 * 
 * @returns VDP_ERROR | VDP_SUCCESS 
 * @deprecated Not really useful if more than 4k Video ram is available
 */
int vdp_init_multicolor(void);


/**
 * @brief Set foreground and background color of the pattern at the current cursor position
 * Only available in Graphic mode 2
 * @param fgcolor Foreground color
 * @param bgcolor Background color
 */
void vdp_colorize(unsigned char fg, unsigned char bg);

/**
 * @brief Plot a point at position (x,y), where x <= 255. The full resolution of 256 by 192 is available.
 * Only two different colors are possible whithin 8 neighboring pixels
 * VDP_MODE G2 only
 * 
 * @param x 
 * @param y 
 * @param color1 Color of pixel at (x,y). If NULL, plot a pixel with color2
 * @param color2 Color of the pixels not set or color of pixel at (x,y) when color1 == NULL
 */
void vdp_plot_hires(unsigned char x, unsigned char y, unsigned char color1, unsigned char color2);

/**
 * @brief Plot a point at position (x,y), where x <= 64. In Graphics mode2, the resolution is 64 by 192 pixels, neighboring pixels can have different colors.
 * In Multicolor  mode, the resolution is 64 by 48 pixels
 * 
 * @param x 
 * @param y 
 * @param color 
 */
void vdp_plot_color(unsigned char x, unsigned char y, unsigned char color);

/**
 * @brief Print string at current cursor position. These Escape sequences are supported:
 * <ul>
 * <li>\\n (newline) </li>
 * <li>\\r (carriage return)</li>
 * <li>Graphic Mode 2 only: \\033[<fg>;[<bg>]m sets the colors and optionally the background of the subsequent characters </li>
 * </ul>
 * Example: vdp_print("\033[4m Dark blue on transparent background\n\r\033[4;14m dark blue on gray background");
 * @param text Text to print
 */
//void vdp_print(unsigned char *text);

/**
 * @brief Set backdrop color
 *
 * @param color
 */
void vdp_set_bdcolor(unsigned char color);

/**
 * @brief Set the color of patterns at the cursor position
 *
 * @param index VDP_MODE_G2: Number of pattern to set the color, VDP_MODE_G1: one of 32 groups of 8 subsequent patterns
 * @param fg Pattern foreground color
 * @param bg Pattern background color
 */
void vdp_set_pattern_color(unsigned int index, unsigned char fg, unsigned char bg);

/**
 * @brief Position the cursor at the specified position
 *
 * @param col column
 * @param row row
 */
void vdp_set_cursor(unsigned char pcol, unsigned char prow);

/**
 * @brief Move the cursor along the specified direction
 *
 * @param direction {VDP_CSR_UP|VDP_CSR_DOWN|VDP_CSR_LEFT|VDP_CSR_RIGHT}
 */
void vdp_set_cursor_pos(unsigned char direction);

/**
 * @brief set foreground and background color of the characters printed after this function has been called. 
 * In Text Mode and Graphics Mode 1, all characters are changed. In Graphics Mode 2, the escape sequence \\033[<fg>;<bg>m can be used instead.
 * See vdp_print()
 *
 * @param fg Foreground color
 * @param bg Background color
 */
void vdp_textcolor(unsigned char fg, unsigned char bg);

/**
 * @brief Write ASCII character at current cursor position
 *
 * @param chr Pattern at the respective location of the  pattern memory. Graphic Mode 1 and Text Mode: Ascii code of character 
 */
void vdp_write(unsigned char chr);

/**
 * @brief Write a sprite into the sprite pattern table
 * 
 * @param name Reference of sprite 0-255 for 8x8 sprites, 0-63 for 16x16 sprites
 * @param sprite Array with sprite data. Type unsigned char[8] for 8x8 sprites, unsigned char[32] for 16x16 sprites 
 */
void vdp_set_sprite_pattern(unsigned char number, const unsigned char *sprite);

/**
 * @brief Set the sprite color
 * 
 * @param addr Sprite Handle returned by vdp_sprite_init()
 * @param color 
 */
void vdp_sprite_color(unsigned int addr, unsigned char color);

/**
 * @brief Get the sprite attributes
 * 
 * @param addr Sprite Handle returned by vdp_sprite_init()
 * @return Sprite_attributes 
 */
Sprite_attributes vdp_sprite_get_attributes(unsigned int addr);

/**
 * @brief Get the current position of a sprite
 * 
 * @param addr Sprite Handle returned by vdp_sprite_init()
 * @param xpos Reference to x-position
 * @param ypos Reference to y-position
 */
Sprite_attributes vdp_sprite_get_position(unsigned int addr);

/**
 * @brief Activate a sprite
 * 
 * @param name Number of the sprite as defined in vdp_set_sprite()
 * @param priority 0: Highest priority; 31: Lowest priority
 * @param color 
 * @returns     Sprite Handle 
 */
unsigned int vdp_sprite_init(unsigned char name, unsigned char priority, unsigned char color);

/**
 * @brief Set position of a sprite
 * 
 * @param addr  Sprite Handle returned by vdp_sprite_init()
 * @param x 
 * @param y 
 * @returns     true: In case of a collision with other sprites
 */
unsigned char vdp_sprite_set_position(unsigned int addr, unsigned int x, unsigned char y);

void geraScroll(void);
void hideCursor(void);
void showCursor(void);
void modeVideo(unsigned char *pMode);
void printCharBuffer(unsigned char *pCharMade);

#ifdef __KEYPS2__
    unsigned char convertCode(unsigned char codeToFind,unsigned char *source, unsigned char *destination);
    void processCode(void);
    void sendByte(unsigned char b);
#endif
