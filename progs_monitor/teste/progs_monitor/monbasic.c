/* A tiny BASIC interpreter */

#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "../mmsj300api.h"
#include "../monitor.h"
#include "monbasic.h"

void main(main)
{
  /* allocate memory for the program */
  /* load the program to execute */

  // logica de digitacao e comandos... p_buf é onde esta o programa

  prog = p_buf;
  scan_labels(); /* find the labels in the program */
  ftos = 0; /* initialize the FOR stack index */
  gtos = 0; /* initialize the GOSUB stack index */
  do {
    token_type = get_token();
    /* check for assignment statement */
    if(token_type==VARIABLE) {
      putback(); /* return the var to the input stream */
      assignment(); /* must be assignment statement */
    }
    else /* is command */
      switch(tok) {
        case PRINT:
	  print();
  	  break;
        case GOTO:
	  exec_goto();
	  break;
	case IF:
	  exec_if();
	  break;
	case FOR:
	  exec_for();
	  break;
	case NEXT:
	  next();
	  break;
  	case INPUT:
	  input();
	  break;
        case GOSUB:
	  gosub();
	  break;
	case RETURN:
	  greturn();
	  break;
        case END:
	  break;
      }
  } while (tok != FINISHED);
}

/* Load a program. */
int load_program(char *p, char *fname)
{
/*  FILE *fp;
  int i=0;

  if(!(fp=fopen(fname, "rb"))) return 0;

  i = 0;
  do {
    *p = getc(fp);
    p++; i++;
  } while(!feof(fp) && i<PROG_SIZE);
  *(p-2) = '\0'; //null terminate the program
  fclose(fp);*/
  return 1;
}

/* Assign a variable a value. */
void assignment(void)
{
  int var, value = 0;

  /* get the variable name */
  get_token();
  if(!isalpha(*token)) {
    serror(4);
  }

  var = toupper(*token)-'A';

  /* get the equals sign */
  get_token();
  if(*token!='=') {
    serror(3);
  }

  /* get the value to assign to var */
  get_exp(&value);

  /* assign the value */
  variables[var] = value;
}

/* Execute a simple version of the BASIC PRINT statement */
void print(void)
{
  int answer=0;
  int len=0, spaces;
  char last_delim;
  unsigned char sqtdtam[10];

  do {
    get_token(); /* get next list item */
    if(tok==EOL || tok==FINISHED) break;
    if(token_type==QUOTE) { /* is string */
      printText(token);
      len += strlen(token);
      get_token();
    }
    else { /* is expression */
      putback();
      get_exp(&answer);
      get_token();
      itoa(answer, sqtdtam, 10);
      len += strlen(sqtdtam);
      printText(sqtdtam);
    }
    last_delim = *token;

    if(*token==';') {
      /* compute number of spaces to move to next tab */
      spaces = 8 - (len % 8);
      len += spaces; /* add in the tabbing position */
      while(spaces) {
	      printText(" ");
        spaces--;
      }
    }
    else if(*token==',') /* do nothing */;
    else if(tok!=EOL && tok!=FINISHED) serror(0);
  } while (*token==';' || *token==',');

  if(tok==EOL || tok==FINISHED) {
    if(last_delim != ';' && last_delim!=',') printText("\n");
  }
  else serror(0); /* error is not , or ; */

}

/* Find all labels. */
void scan_labels(void)
{
  int addr;
  char *temp;

  label_init();  /* zero all labels */
  temp = prog;   /* save pointer to top of program */

  /* if the first token in the file is a label */
  get_token();
  if(token_type==NUMBER) {
    strcpy(label_table[0].name,token);
    label_table[0].p=prog;
  }

  find_eol();
  do {
    get_token();
    if(token_type==NUMBER) {
      addr = get_next_label(token);
      if(addr==-1 || addr==-2) {
          (addr==-1) ?serror(5):serror(6);
      }
      strcpy(label_table[addr].name, token);
      label_table[addr].p = prog;  /* current point in program */
    }
    /* if not on a blank line, find next line */
    if(tok!=EOL) find_eol();
  } while(tok!=FINISHED);
  prog = temp;  /* restore to original */
}

/* Find the start of the next line. */
void find_eol(void)
{
  while(*prog!='\n'  && *prog!='\0') ++prog;
  if(*prog) prog++;
}

/* Return index of next free position in label array.
   A -1 is returned if the array is full.
   A -2 is returned when duplicate label is found.
*/
int get_next_label(char *s)
{
  register int t;

  for(t=0;t<NUM_LAB;++t) {
    if(label_table[t].name[0]==0) return t;
    if(!strcmp(label_table[t].name,s)) return -2; /* dup */
  }

  return -1;
}

/* Find location of given label.  A null is returned if
   label is not found; otherwise a pointer to the position
   of the label is returned.
*/
char *find_label(char *s)
{
  register int t;

  for(t=0; t<NUM_LAB; ++t)
    if(!strcmp(label_table[t].name,s)) return label_table[t].p;
  return '\0'; /* error condition */
}

/* Execute a GOTO statement. */
void exec_goto(void)
{

  char *loc;

  get_token(); /* get label to go to */
  /* find the location of the label */
  loc = find_label(token);
  if(loc=='\0')
    serror(7); /* label not defined */

  else prog=loc;  /* start program running at that loc */
}

/* Initialize the array that holds the labels.
   By convention, a null label name indicates that
   array position is unused.
*/
void label_init(void)
{
  register int t;

  for(t=0; t<NUM_LAB; ++t) label_table[t].name[0]='\0';
}

/* Execute an IF statement. */
void exec_if(void)
{
  int x=0 , y=0, cond;
  char op;

  get_exp(&x); /* get left expression */

  get_token(); /* get the operator */
  if(!strchr("=<>", *token)) {
    serror(0); /* not a legal operator */
    return;
  }
  op=*token;

  get_exp(&y); /* get right expression */

  /* determine the outcome */
  cond = 0;
  switch(op) {
    case '<':
      if(x<y) cond=1;
      break;
    case '>':
      if(x>y) cond=1;
      break;
    case '=':
      if(x==y) cond=1;
      break;
  }
  if(cond) { /* is true so process target of IF */
    get_token();
    if(tok!=THEN) {
      serror(8);
      return;
    }/* else program execution starts on next line */
  }
  else find_eol(); /* find start of next line */
}

/* Execute a FOR loop. */
void exec_for(void)
{
  struct for_stack i;
  int value=0;

  get_token(); /* read the control variable */
  if(!isalpha(*token)) {
    serror(4);
    return;
  }

  i.var=toupper(*token)-'A'; /* save its index */

  get_token(); /* read the equals sign */
  if(*token!='=') {
    serror(3);
    return;
  }

  get_exp(&value); /* get initial value */

  variables[i.var]=value;

  get_token();
  if(tok!=TO) serror(9); /* read and discard the TO */

  get_exp(&i.target); /* get target value */

  /* if loop can execute at least once, push info on stack */
  if(value>=variables[i.var]) {
    i.loc = prog;
    fpush(i);
  }
  else  /* otherwise, skip loop code altogether */
    while(tok!=NEXT) get_token();
}

/* Execute a NEXT statement. */
void next(void)
{
  struct for_stack i;

  i = fpop(); /* read the loop info */

  variables[i.var]++; /* increment control variable */
  if(variables[i.var]>i.target) return;  /* all done */
  fpush(i);  /* otherwise, restore the info */
  prog = i.loc;  /* loop */
}

/* Push function for the FOR stack. */
void fpush(struct for_stack i)
{
   if(ftos>FOR_NEST)
    serror(10);

  fstack[ftos]=i;
  ftos++;
}

struct for_stack fpop(void)
{
  ftos--;
  if(ftos<0) serror(11);
  return(fstack[ftos]);
}

/* Execute a simple form of the BASIC INPUT command */
void input(void)
{
  char var;
  int i=0,ix;
  unsigned *vbufprt=vbuf;
  char inLine[128];
  unsigned int vTec;

  get_token(); /* see if prompt string is present */
  if(token_type==QUOTE) {
    printText(token); /* if so, print it and check for comma */
    get_token();
    if(*token!=',') serror(1);
    get_token();
  }
  else printText("? "); /* otherwise, prompt with / */
  var = toupper(*token)-'A'; /* get the input var */

  vTec=inputLine(128);
  if (*vbuf != 0x00 && (vTec == 0x0D || vTec == 0x0A))
  {
      ix=0;
      while(*vbufprt)
      {
        inLine[ix++]=*vbufprt++;
        inLine[ix]=0;
      }
      *vBufReceived = 0x00;
      *vbuf = '\0';            
      i=atoi(inLine);
  }

  variables[var] = i; /* store it */
}

/* Execute a GOSUB command. */
void gosub(void)
{
  char *loc;

  get_token();
  /* find the label to call */
  loc = find_label(token);
  if(loc=='\0')
    serror(7); /* label not defined */
  else {
    gpush(prog); /* save place to return to */
    prog = loc;  /* start program running at that loc */
  }
}

/* Return from GOSUB. */
void greturn(void)
{
   prog = gpop();
}

/* GOSUB stack push function. */
void gpush(char *s)
{
  gtos++;

  if(gtos==SUB_NEST) {
    serror(12);
    return;
  }

  gstack[gtos]=s;

}

/* GOSUB stack pop function. */
char *gpop(void)
{
  if(gtos==0) {
    serror(13);
    return 0;
  }

  return(gstack[gtos--]);
}

/* Entry point into parser. */
void get_exp(int *result)
{
  get_token();
  if(!*token) {
    serror(2);
    return;
  }
  level2(result);
  putback(); /* return last token read to input stream */
}


/* display an error message */
void serror(int error)
{
  static char *e[]= {
    "syntax error",
    "unbalanced parentheses",
    "no expression present",
    "equals sign expected",
    "not a variable",
    "Label table full",
    "duplicate label",
    "undefined label",
    "THEN expected",
    "TO expected",
    "too many nested FOR loops",
    "NEXT without FOR",
    "too many nested GOSUBs",
    "RETURN without GOSUB"
  };
  printText(e[error]);
  printText("\r\n");
}

/* Get a token. */
int get_token(void)
{

  register char *temp;

  token_type=0; tok=0;
  temp=token;

  if(*prog=='\0') { /* end of file */
    *token=0;
    tok = FINISHED;
    return(token_type=DELIMITER);
  }

  while(iswhite(*prog)) ++prog;  /* skip over white space */

  if(*prog=='\r') { /* crlf */
    ++prog; ++prog;
    tok = EOL; *token='\r';
    token[1]='\n'; token[2]=0;
    return (token_type = DELIMITER);
  }

  if(strchr("+-*^/%=;(),><", *prog)){ /* delimiter */
    *temp=*prog;
    prog++; /* advance to next position */
    temp++;
    *temp=0;
    return (token_type=DELIMITER);
  }

  if(*prog=='"') { /* quoted string */
    prog++;
    while(*prog!='"'&& *prog!='\r') *temp++=*prog++;
    if(*prog=='\r') serror(1);
    prog++;*temp=0;
    return(token_type=QUOTE);
  }

  if(isdigit(*prog)) { /* number */
    while(!isdelim(*prog)) *temp++=*prog++;
    *temp = '\0';
    return(token_type = NUMBER);
  }

  if(isalpha(*prog)) { /* var or command */
    while(!isdelim(*prog)) *temp++=*prog++;
    token_type=STRING;
  }

  *temp = '\0';

  /* see if a string is a command or a variable */
  if(token_type==STRING) {
    tok=look_up(token); /* convert to internal rep */
    if(!tok) token_type = VARIABLE;
    else token_type = COMMAND; /* is a command */
  }
  return token_type;
}



/* Return a token to input stream. */
void putback(void)
{

  char *t;

  t = token;
  for(; *t; t++) prog--;
}

/* Look up a a token's internal representation in the
   token table.
*/
int look_up(char *s)
{
  register int i;
  char *p;

  /* convert to lowercase */
  p = s;
  while(*p){ *p = tolower(*p); p++; }

  /* see if token is in table */
  for(i=0; *table[i].command; i++)
      if(!strcmp(table[i].command, s)) return table[i].tok;
  return 0; /* unknown command */
}

/* Return true if c is a delimiter. */
int isdelim(char c)
{
  if(strchr(" ;,+-<>/*%^=()", c) || c==9 || c=='\r' || c==0)
    return 1;
  return 0;
}

/* Return 1 if c is space or tab. */
int iswhite(char c)
{
  if(c==' ' || c=='\t') return 1;
  else return 0;
}



/*  Add or subtract two terms. */
void level2(int *result)
{
  register char  op;
  int hold;

  level3(result);
  while((op = *token) == '+' || op == '-') {
    get_token();
    level3(&hold);
    arith(op, result, &hold);
  }
}

/* Multiply or divide two factors. */
void level3(int *result)
{
  register char  op;
  int hold;

  level4(result);
  while((op = *token) == '*' || op == '/' || op == '%') {
    get_token();
    level4(&hold);
    arith(op, result, &hold);
  }
}

/* Process integer exponent. */
void level4(int *result)
{
  int hold;

  level5(result);
  if(*token== '^') {
    get_token();
    level4(&hold);
    arith('^', result, &hold);
  }
}

/* Is a unary + or -. */
void level5(int *result)
{
  register char  op;

  op = 0;
  if((token_type==DELIMITER) && *token=='+' || *token=='-') {
    op = *token;
    get_token();
  }
  level6(result);
  if(op)
    unary(op, result);
}

/* Process parenthesized expression. */
void level6(int *result)
{
  if((*token == '(') && (token_type == DELIMITER)) {
    get_token();
    level2(result);
    if(*token != ')')
      serror(1);
    get_token();
  }
  else
    primitive(result);
}

/* Find value of number or variable. */
void primitive(int *result)
{

  switch(token_type) {
  case VARIABLE:
    *result = find_var(token);
    get_token();
    return;
  case NUMBER:
    *result = atoi(token);
    get_token();
    return;
  default:
    serror(0);
  }
}

/* Perform the specified arithmetic. */
void arith(char o, int *r, int *h)
{
  register int t, ex;

  switch(o) {
    case '-':
      *r = *r-*h;
      break;
    case '+':
      *r = *r+*h;
      break;
    case '*':
      *r = *r * *h;
      break;
    case '/':
      *r = (*r)/(*h);
      break;
    case '%':
      t = (*r)/(*h);
      *r = *r-(t*(*h));
      break;
    case '^':
      ex = *r;
      if(*h==0) {
        *r = 1;
        break;
      }
      for(t=*h-1; t>0; --t) *r = (*r) * ex;
      break;
  }
}

/* Reverse the sign. */
void unary(char o, int *r)
{
  if(o=='-') *r = -(*r);
}

/* Find the value of a variable. */
int find_var(char *s)
{
  if(!isalpha(*s)){
    serror(4); /* not a variable */
    return 0;
  }
  return variables[toupper(*token)-'A'];
}