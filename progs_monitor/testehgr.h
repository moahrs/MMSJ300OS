typedef struct  {
  unsigned char nameVar[3];  // variable name
  long endVar; // address off the counter variable
  int target;  // target value
  int step; // step inc/dec
  int progPosPointerRet;
} for_stack;

void setWriteAddress(unsigned int address);
void setReadAddress(unsigned int address);
void uvdp_plot_hires(unsigned char x, unsigned char y, unsigned char color1, unsigned char color2);
