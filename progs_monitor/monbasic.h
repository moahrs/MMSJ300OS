#define NUM_LAB 100
#define LAB_LEN 10
#define FOR_NEST 25
#define SUB_NEST 25
#define PROG_SIZE 10000

#define DELIMITER  1
#define VARIABLE  2
#define NUMBER    3
#define COMMAND   4
#define STRING    5
#define QUOTE     6

#define PRINT 1
#define INPUT 2
#define IF    3
#define THEN  4
#define FOR   5
#define NEXT  6
#define TO    7
#define GOTO  8
#define EOL   9
#define FINISHED  10
#define GOSUB 11
#define RETURN 12
#define END 13

char *prog;  /* holds expression to be analyzed */
jmp_buf e_buf; /* hold environment for longjmp() */
char *p_buf = 0x00820000;

int variables[26]= {    /* 26 user variables,  A-Z */
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0
};

struct commands { /* keyword lookup table */
  char command[20];
  char tok;
}; 

struct commands table[] = { /* Commands must be entered lowercase */
  {"print", PRINT}, /* in this table. */
  {"input", INPUT},
  {"if", IF},
  {"then", THEN},
  {"goto", GOTO},
  {"for", FOR},
  {"next", NEXT},
  {"to", TO},
  {"gosub", GOSUB},
  {"return", RETURN},
  {"end", END},
  {"", END}  /* mark end of table */
};

char token[80];
char token_type, tok;

struct label {
  char name[LAB_LEN];
  char *p;  /* points to place to go in source file*/
};
struct label label_table[NUM_LAB];

struct for_stack {
  int var; /* counter variable */
  int target;  /* target value */
  char *loc;
};

struct for_stack fstack[FOR_NEST]; /* stack for FOR/NEXT loop */

int ftos;  /* index to top of FOR stack */
int gtos;  /* index to top of GOSUB stack */

char *find_label(char *s);
char *gpop(void);
struct for_stack fpop(void);
char *gstack[SUB_NEST]; /* stack for gosub */
void assignment(void);
void print(void);
void scan_labels(void);
void find_eol(void);
void exec_goto(void);
void exec_if(void);
void exec_for(void);
void next(void);
void fpush(struct for_stack i);
void input(void);
void gosub(void); 
void greturn(void);
void gpush(char *s);
void label_init(void);
void serror(int error); 
void get_exp(int *result);
void putback(void);
void level2(int *result);
void level3(int *result);
void level4(int *result); 
void level5(int *result);
void level6(int *result);
void primitive(int *result);
void unary(char o, int *r);
void arith(char o, int *r, int *h);
int load_program(char *p, char *fname);
int look_up(char *s);
int get_next_label(char *s);
int iswhite(char c);
int isdelim(char c);
int find_var(char *s);
int get_token(void);

