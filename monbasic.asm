; D:\PROJETOS\MMSJ300\PROGS_MONITOR\MONBASIC.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J.Fondse
; /* A tiny BASIC interpreter */
; #include <ctype.h>
; #include <string.h>
; #include <stdlib.h>
; #include <math.h>
; #include "../mmsj300api.h"
; #include "../monitor.h"
; #include "monbasic.h"
; void main(main)
; {
       section   code
       xdef      _main
_main:
       link      A6,#0
; /* allocate memory for the program */
; /* load the program to execute */
; // logica de digitacao e comandos... p_buf é onde esta o programa
; prog = p_buf;
       move.l    _p_buf.L,_prog.L
; scan_labels(); /* find the labels in the program */
       jsr       _scan_labels
; ftos = 0; /* initialize the FOR stack index */
       clr.l     _ftos.L
; gtos = 0; /* initialize the GOSUB stack index */
       clr.l     _gtos.L
; do {
main_1:
; token_type = get_token();
       jsr       _get_token
       move.b    D0,_token_type.L
; /* check for assignment statement */
; if(token_type==VARIABLE) {
       move.b    _token_type.L,D0
       cmp.b     #2,D0
       bne.s     main_3
; putback(); /* return the var to the input stream */
       jsr       _putback
; assignment(); /* must be assignment statement */
       jsr       _assignment
       bra       main_6
main_3:
; }
; else /* is command */
; switch(tok) {
       move.b    _tok.L,D0
       ext.w     D0
       ext.l     D0
       cmp.l     #6,D0
       beq       main_11
       bgt.s     main_16
       cmp.l     #3,D0
       beq       main_9
       bgt.s     main_17
       cmp.l     #2,D0
       beq       main_12
       bgt       main_6
       cmp.l     #1,D0
       beq       main_7
       bra       main_6
main_17:
       cmp.l     #5,D0
       beq       main_10
       bra       main_6
main_16:
       cmp.l     #12,D0
       beq       main_14
       bgt.s     main_18
       cmp.l     #11,D0
       beq       main_13
       bgt       main_6
       cmp.l     #8,D0
       beq.s     main_8
       bra       main_6
main_18:
       cmp.l     #13,D0
       beq       main_15
       bra       main_6
main_7:
; case PRINT:
; print();
       jsr       _print
; break;
       bra.s     main_6
main_8:
; case GOTO:
; exec_goto();
       jsr       _exec_goto
; break;
       bra.s     main_6
main_9:
; case IF:
; exec_if();
       jsr       _exec_if
; break;
       bra.s     main_6
main_10:
; case FOR:
; exec_for();
       jsr       _exec_for
; break;
       bra.s     main_6
main_11:
; case NEXT:
; next();
       jsr       _next
; break;
       bra.s     main_6
main_12:
; case INPUT:
; input();
       jsr       _input
; break;
       bra.s     main_6
main_13:
; case GOSUB:
; gosub();
       jsr       _gosub
; break;
       bra.s     main_6
main_14:
; case RETURN:
; greturn();
       jsr       _greturn
; break;
       bra       main_6
main_15:
; case END:
; break;
main_6:
       move.b    _tok.L,D0
       cmp.b     #10,D0
       bne       main_1
       unlk      A6
       rts
; }
; } while (tok != FINISHED);
; }
; /* Load a program. */
; int load_program(char *p, char *fname)
; {
       xdef      _load_program
_load_program:
       link      A6,#0
; /*  FILE *fp;
; int i=0;
; if(!(fp=fopen(fname, "rb"))) return 0;
; i = 0;
; do {
; *p = getc(fp);
; p++; i++;
; } while(!feof(fp) && i<PROG_SIZE);
; *(p-2) = '\0'; //null terminate the program
; fclose(fp);*/
; return 1;
       moveq     #1,D0
       unlk      A6
       rts
; }
; /* Assign a variable a value. */
; void assignment(void)
; {
       xdef      _assignment
_assignment:
       link      A6,#-8
; int var, value = 0;
       clr.l     -4(A6)
; /* get the variable name */
; get_token();
       jsr       _get_token
; if(!isalpha(*token)) {
       move.b    _token.L,D0
       ext.w     D0
       move.w    D0,A0
       move.b    1+__ctype(A0),D0
       and.b     #3,D0
       bne.s     assignment_1
; serror(4);
       pea       4
       jsr       _serror
       addq.w    #4,A7
assignment_1:
; }
; var = toupper(*token)-'A';
       move.b    _token.L,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       sub.l     #65,D0
       move.l    D0,-8(A6)
; /* get the equals sign */
; get_token();
       jsr       _get_token
; if(*token!='=') {
       move.b    _token.L,D0
       cmp.b     #61,D0
       beq.s     assignment_3
; serror(3);
       pea       3
       jsr       _serror
       addq.w    #4,A7
assignment_3:
; }
; /* get the value to assign to var */
; get_exp(&value);
       pea       -4(A6)
       jsr       _get_exp
       addq.w    #4,A7
; /* assign the value */
; variables[var] = value;
       move.l    -8(A6),D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       move.l    -4(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; /* Execute a simple version of the BASIC PRINT statement */
; void print(void)
; {
       xdef      _print
_print:
       link      A6,#-16
       movem.l   D2/D3/D4/A2/A3/A4,-(A7)
       lea       _printText.L,A2
       lea       -10(A6),A3
       lea       _get_token.L,A4
; int answer=0;
       clr.l     -14(A6)
; int len=0, spaces;
       clr.l     D2
; char last_delim;
; unsigned char sqtdtam[10];
; do {
print_1:
; get_token(); /* get next list item */
       jsr       (A4)
; if(tok==EOL || tok==FINISHED) break;
       move.b    _tok.L,D0
       cmp.b     #9,D0
       beq.s     print_5
       move.b    _tok.L,D0
       cmp.b     #10,D0
       bne.s     print_3
print_5:
       bra       print_2
print_3:
; if(token_type==QUOTE) { /* is string */
       move.b    _token_type.L,D0
       cmp.b     #6,D0
       bne.s     print_6
; printText(token);
       pea       _token.L
       jsr       (A2)
       addq.w    #4,A7
; len += strlen(token);
       pea       _token.L
       jsr       _strlen
       addq.w    #4,A7
       add.l     D0,D2
; get_token();
       jsr       (A4)
       bra       print_7
print_6:
; }
; else { /* is expression */
; putback();
       jsr       _putback
; get_exp(&answer);
       pea       -14(A6)
       jsr       _get_exp
       addq.w    #4,A7
; get_token();
       jsr       (A4)
; itoa(answer, sqtdtam, 10);
       pea       10
       move.l    A3,-(A7)
       move.l    -14(A6),-(A7)
       jsr       _itoa
       add.w     #12,A7
; len += strlen(sqtdtam);
       move.l    A3,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       add.l     D0,D2
; printText(sqtdtam);
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
print_7:
; }
; last_delim = *token;
       move.b    _token.L,D4
; if(*token==';') {
       move.b    _token.L,D0
       cmp.b     #59,D0
       bne       print_8
; /* compute number of spaces to move to next tab */
; spaces = 8 - (len % 8);
       moveq     #8,D0
       ext.w     D0
       ext.l     D0
       move.l    D2,-(A7)
       pea       8
       jsr       LDIV
       move.l    4(A7),D1
       addq.w    #8,A7
       sub.l     D1,D0
       move.l    D0,D3
; len += spaces; /* add in the tabbing position */
       add.l     D3,D2
; while(spaces) {
print_10:
       tst.l     D3
       beq.s     print_12
; printText(" ");
       pea       @monbasic_1.L
       jsr       (A2)
       addq.w    #4,A7
; spaces--;
       subq.l    #1,D3
       bra       print_10
print_12:
       bra.s     print_15
print_8:
; }
; }
; else if(*token==',') /* do nothing */;
       move.b    _token.L,D0
       cmp.b     #44,D0
       bne.s     print_13
       bra.s     print_15
print_13:
; else if(tok!=EOL && tok!=FINISHED) serror(0);
       move.b    _tok.L,D0
       cmp.b     #9,D0
       beq.s     print_15
       move.b    _tok.L,D0
       cmp.b     #10,D0
       beq.s     print_15
       clr.l     -(A7)
       jsr       _serror
       addq.w    #4,A7
print_15:
       move.b    _token.L,D0
       cmp.b     #59,D0
       beq       print_1
       move.b    _token.L,D0
       cmp.b     #44,D0
       beq       print_1
print_2:
; } while (*token==';' || *token==',');
; if(tok==EOL || tok==FINISHED) {
       move.b    _tok.L,D0
       cmp.b     #9,D0
       beq.s     print_19
       move.b    _tok.L,D0
       cmp.b     #10,D0
       bne.s     print_17
print_19:
; if(last_delim != ';' && last_delim!=',') printText("\n");
       cmp.b     #59,D4
       beq.s     print_20
       cmp.b     #44,D4
       beq.s     print_20
       pea       @monbasic_2.L
       jsr       (A2)
       addq.w    #4,A7
print_20:
       bra.s     print_18
print_17:
; }
; else serror(0); /* error is not , or ; */
       clr.l     -(A7)
       jsr       _serror
       addq.w    #4,A7
print_18:
       movem.l   (A7)+,D2/D3/D4/A2/A3/A4
       unlk      A6
       rts
; }
; /* Find all labels. */
; void scan_labels(void)
; {
       xdef      _scan_labels
_scan_labels:
       link      A6,#-4
       movem.l   D2/A2/A3/A4,-(A7)
       lea       _label_table.L,A2
       lea       _prog.L,A3
       lea       _token.L,A4
; int addr;
; char *temp;
; label_init();  /* zero all labels */
       jsr       _label_init
; temp = prog;   /* save pointer to top of program */
       move.l    (A3),-4(A6)
; /* if the first token in the file is a label */
; get_token();
       jsr       _get_token
; if(token_type==NUMBER) {
       move.b    _token_type.L,D0
       cmp.b     #3,D0
       bne.s     scan_labels_1
; strcpy(label_table[0].name,token);
       move.l    A4,-(A7)
       move.l    A2,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; label_table[0].p=prog;
       move.l    (A3),10(A2)
scan_labels_1:
; }
; find_eol();
       jsr       _find_eol
; do {
scan_labels_3:
; get_token();
       jsr       _get_token
; if(token_type==NUMBER) {
       move.b    _token_type.L,D0
       cmp.b     #3,D0
       bne       scan_labels_5
; addr = get_next_label(token);
       move.l    A4,-(A7)
       jsr       _get_next_label
       addq.w    #4,A7
       move.l    D0,D2
; if(addr==-1 || addr==-2) {
       cmp.l     #-1,D2
       beq.s     scan_labels_9
       cmp.l     #-2,D2
       bne.s     scan_labels_11
scan_labels_9:
; (addr==-1) ?serror(5):serror(6);
       cmp.l     #-1,D2
       bne.s     scan_labels_10
       pea       5
       jsr       _serror
       addq.w    #4,A7
       bra.s     scan_labels_11
scan_labels_10:
       pea       6
       jsr       _serror
       addq.w    #4,A7
scan_labels_11:
; }
; strcpy(label_table[addr].name, token);
       move.l    A4,-(A7)
       move.l    A2,D1
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #14,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
; label_table[addr].p = prog;  /* current point in program */
       move.l    D2,D0
       muls      #14,D0
       lea       0(A2,D0.L),A0
       move.l    (A3),10(A0)
scan_labels_5:
; }
; /* if not on a blank line, find next line */
; if(tok!=EOL) find_eol();
       move.b    _tok.L,D0
       cmp.b     #9,D0
       beq.s     scan_labels_12
       jsr       _find_eol
scan_labels_12:
       move.b    _tok.L,D0
       cmp.b     #10,D0
       bne       scan_labels_3
; } while(tok!=FINISHED);
; prog = temp;  /* restore to original */
       move.l    -4(A6),(A3)
       movem.l   (A7)+,D2/A2/A3/A4
       unlk      A6
       rts
; }
; /* Find the start of the next line. */
; void find_eol(void)
; {
       xdef      _find_eol
_find_eol:
       move.l    A2,-(A7)
       lea       _prog.L,A2
; while(*prog!='\n'  && *prog!='\0') ++prog;
find_eol_1:
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #10,D0
       beq.s     find_eol_3
       move.l    (A2),A0
       move.b    (A0),D0
       beq.s     find_eol_3
       addq.l    #1,(A2)
       bra       find_eol_1
find_eol_3:
; if(*prog) prog++;
       move.l    (A2),A0
       tst.b     (A0)
       beq.s     find_eol_4
       addq.l    #1,(A2)
find_eol_4:
       move.l    (A7)+,A2
       rts
; }
; /* Return index of next free position in label array.
; A -1 is returned if the array is full.
; A -2 is returned when duplicate label is found.
; */
; int get_next_label(char *s)
; {
       xdef      _get_next_label
_get_next_label:
       link      A6,#0
       move.l    D2,-(A7)
; register int t;
; for(t=0;t<NUM_LAB;++t) {
       clr.l     D2
get_next_label_1:
       cmp.l     #100,D2
       bge       get_next_label_3
; if(label_table[t].name[0]==0) return t;
       move.l    D2,D0
       muls      #14,D0
       lea       _label_table.L,A0
       move.b    0(A0,D0.L),D0
       bne.s     get_next_label_4
       move.l    D2,D0
       bra.s     get_next_label_6
get_next_label_4:
; if(!strcmp(label_table[t].name,s)) return -2; /* dup */
       move.l    8(A6),-(A7)
       lea       _label_table.L,A0
       move.l    D2,D1
       muls      #14,D1
       add.l     D1,A0
       move.l    A0,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     get_next_label_7
       moveq     #-2,D0
       bra.s     get_next_label_6
get_next_label_7:
       addq.l    #1,D2
       bra       get_next_label_1
get_next_label_3:
; }
; return -1;
       moveq     #-1,D0
get_next_label_6:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /* Find location of given label.  A null is returned if
; label is not found; otherwise a pointer to the position
; of the label is returned.
; */
; char *find_label(char *s)
; {
       xdef      _find_label
_find_label:
       link      A6,#0
       move.l    D2,-(A7)
; register int t;
; for(t=0; t<NUM_LAB; ++t)
       clr.l     D2
find_label_1:
       cmp.l     #100,D2
       bge       find_label_3
; if(!strcmp(label_table[t].name,s)) return label_table[t].p;
       move.l    8(A6),-(A7)
       lea       _label_table.L,A0
       move.l    D2,D1
       muls      #14,D1
       add.l     D1,A0
       move.l    A0,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     find_label_4
       move.l    D2,D0
       muls      #14,D0
       lea       _label_table.L,A0
       add.l     D0,A0
       move.l    10(A0),D0
       bra.s     find_label_6
find_label_4:
       addq.l    #1,D2
       bra       find_label_1
find_label_3:
; return '\0'; /* error condition */
       clr.l     D0
find_label_6:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /* Execute a GOTO statement. */
; void exec_goto(void)
; {
       xdef      _exec_goto
_exec_goto:
       move.l    D2,-(A7)
; char *loc;
; get_token(); /* get label to go to */
       jsr       _get_token
; /* find the location of the label */
; loc = find_label(token);
       pea       _token.L
       jsr       _find_label
       addq.w    #4,A7
       move.l    D0,D2
; if(loc=='\0')
       clr.b     D0
       and.l     #255,D0
       cmp.l     D0,D2
       bne.s     exec_goto_1
; serror(7); /* label not defined */
       pea       7
       jsr       _serror
       addq.w    #4,A7
       bra.s     exec_goto_2
exec_goto_1:
; else prog=loc;  /* start program running at that loc */
       move.l    D2,_prog.L
exec_goto_2:
       move.l    (A7)+,D2
       rts
; }
; /* Initialize the array that holds the labels.
; By convention, a null label name indicates that
; array position is unused.
; */
; void label_init(void)
; {
       xdef      _label_init
_label_init:
       move.l    D2,-(A7)
; register int t;
; for(t=0; t<NUM_LAB; ++t) label_table[t].name[0]='\0';
       clr.l     D2
label_init_1:
       cmp.l     #100,D2
       bge.s     label_init_3
       move.l    D2,D0
       muls      #14,D0
       lea       _label_table.L,A0
       clr.b     0(A0,D0.L)
       addq.l    #1,D2
       bra       label_init_1
label_init_3:
       move.l    (A7)+,D2
       rts
; }
; /* Execute an IF statement. */
; void exec_if(void)
; {
       xdef      _exec_if
_exec_if:
       link      A6,#-12
       move.l    D2,-(A7)
; int x=0 , y=0, cond;
       clr.l     -10(A6)
       clr.l     -6(A6)
; char op;
; get_exp(&x); /* get left expression */
       pea       -10(A6)
       jsr       _get_exp
       addq.w    #4,A7
; get_token(); /* get the operator */
       jsr       _get_token
; if(!strchr("=<>", *token)) {
       move.b    _token.L,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @monbasic_3.L
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       bne.s     exec_if_1
; serror(0); /* not a legal operator */
       clr.l     -(A7)
       jsr       _serror
       addq.w    #4,A7
; return;
       bra       exec_if_17
exec_if_1:
; }
; op=*token;
       move.b    _token.L,-1(A6)
; get_exp(&y); /* get right expression */
       pea       -6(A6)
       jsr       _get_exp
       addq.w    #4,A7
; /* determine the outcome */
; cond = 0;
       clr.l     D2
; switch(op) {
       move.b    -1(A6),D0
       ext.w     D0
       ext.l     D0
       cmp.l     #61,D0
       beq       exec_if_8
       bgt.s     exec_if_9
       cmp.l     #60,D0
       beq.s     exec_if_6
       bra       exec_if_5
exec_if_9:
       cmp.l     #62,D0
       beq.s     exec_if_7
       bra.s     exec_if_5
exec_if_6:
; case '<':
; if(x<y) cond=1;
       move.l    -10(A6),D0
       cmp.l     -6(A6),D0
       bge.s     exec_if_10
       moveq     #1,D2
exec_if_10:
; break;
       bra.s     exec_if_5
exec_if_7:
; case '>':
; if(x>y) cond=1;
       move.l    -10(A6),D0
       cmp.l     -6(A6),D0
       ble.s     exec_if_12
       moveq     #1,D2
exec_if_12:
; break;
       bra.s     exec_if_5
exec_if_8:
; case '=':
; if(x==y) cond=1;
       move.l    -10(A6),D0
       cmp.l     -6(A6),D0
       bne.s     exec_if_14
       moveq     #1,D2
exec_if_14:
; break;
exec_if_5:
; }
; if(cond) { /* is true so process target of IF */
       tst.l     D2
       beq.s     exec_if_16
; get_token();
       jsr       _get_token
; if(tok!=THEN) {
       move.b    _tok.L,D0
       cmp.b     #4,D0
       beq.s     exec_if_18
; serror(8);
       pea       8
       jsr       _serror
       addq.w    #4,A7
; return;
       bra.s     exec_if_17
exec_if_18:
       bra.s     exec_if_17
exec_if_16:
; }/* else program execution starts on next line */
; }
; else find_eol(); /* find start of next line */
       jsr       _find_eol
exec_if_17:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /* Execute a FOR loop. */
; void exec_for(void)
; {
       xdef      _exec_for
_exec_for:
       link      A6,#-16
       movem.l   A2/A3/A4,-(A7)
       lea       -16(A6),A2
       lea       _get_token.L,A3
       lea       _serror.L,A4
; struct for_stack i;
; int value=0;
       clr.l     -4(A6)
; get_token(); /* read the control variable */
       jsr       (A3)
; if(!isalpha(*token)) {
       move.b    _token.L,D0
       ext.w     D0
       move.w    D0,A0
       move.b    1+__ctype(A0),D0
       and.b     #3,D0
       bne.s     exec_for_1
; serror(4);
       pea       4
       jsr       (A4)
       addq.w    #4,A7
; return;
       bra       exec_for_12
exec_for_1:
; }
; i.var=toupper(*token)-'A'; /* save its index */
       move.b    _token.L,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       sub.l     #65,D0
       move.l    A2,D1
       move.l    D1,A0
       move.l    D0,(A0)
; get_token(); /* read the equals sign */
       jsr       (A3)
; if(*token!='=') {
       move.b    _token.L,D0
       cmp.b     #61,D0
       beq.s     exec_for_4
; serror(3);
       pea       3
       jsr       (A4)
       addq.w    #4,A7
; return;
       bra       exec_for_12
exec_for_4:
; }
; get_exp(&value); /* get initial value */
       pea       -4(A6)
       jsr       _get_exp
       addq.w    #4,A7
; variables[i.var]=value;
       move.l    A2,D0
       move.l    D0,A0
       move.l    (A0),D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       move.l    -4(A6),0(A0,D0.L)
; get_token();
       jsr       (A3)
; if(tok!=TO) serror(9); /* read and discard the TO */
       move.b    _tok.L,D0
       cmp.b     #7,D0
       beq.s     exec_for_6
       pea       9
       jsr       (A4)
       addq.w    #4,A7
exec_for_6:
; get_exp(&i.target); /* get target value */
       moveq     #4,D1
       move.l    D0,-(A7)
       move.l    A2,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _get_exp
       addq.w    #4,A7
; /* if loop can execute at least once, push info on stack */
; if(value>=variables[i.var]) {
       move.l    A2,D0
       move.l    D0,A0
       move.l    (A0),D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       move.l    -4(A6),D1
       cmp.l     0(A0,D0.L),D1
       blt.s     exec_for_8
; i.loc = prog;
       move.l    A2,D0
       move.l    D0,A0
       move.l    _prog.L,8(A0)
; fpush(i);
       move.l    A2,D1
       move.l    D1,A0
       add.w     #12,A0
       moveq     #2,D1
       move.l    -(A0),-(A7)
       dbra      D1,*-2
       jsr       _fpush
       add.w     #12,A7
       bra.s     exec_for_12
exec_for_8:
; }
; else  /* otherwise, skip loop code altogether */
; while(tok!=NEXT) get_token();
exec_for_10:
       move.b    _tok.L,D0
       cmp.b     #6,D0
       beq.s     exec_for_12
       jsr       (A3)
       bra       exec_for_10
exec_for_12:
       movem.l   (A7)+,A2/A3/A4
       unlk      A6
       rts
; }
; /* Execute a NEXT statement. */
; void next(void)
; {
       xdef      _next
_next:
       link      A6,#-12
       move.l    A2,-(A7)
       lea       -12(A6),A2
; struct for_stack i;
; i = fpop(); /* read the loop info */
       move.l    A2,A0
       move.l    A0,-(A7)
       jsr       _fpop
       move.l    (A7)+,A0
       move.l    D0,A1
       moveq     #2,D0
       move.l    (A1)+,(A0)+
       dbra      D0,*-2
; variables[i.var]++; /* increment control variable */
       move.l    A2,D0
       move.l    D0,A0
       move.l    (A0),D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       addq.l    #1,0(A0,D0.L)
; if(variables[i.var]>i.target) return;  /* all done */
       move.l    A2,D0
       move.l    D0,A0
       move.l    (A0),D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       move.l    A2,D1
       move.l    D1,A1
       move.l    0(A0,D0.L),D1
       cmp.l     4(A1),D1
       ble.s     next_1
       bra.s     next_3
next_1:
; fpush(i);  /* otherwise, restore the info */
       move.l    A2,D1
       move.l    D1,A0
       add.w     #12,A0
       moveq     #2,D1
       move.l    -(A0),-(A7)
       dbra      D1,*-2
       jsr       _fpush
       add.w     #12,A7
; prog = i.loc;  /* loop */
       move.l    A2,D0
       move.l    D0,A0
       move.l    8(A0),_prog.L
next_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; /* Push function for the FOR stack. */
; void fpush(struct for_stack i)
; {
       xdef      _fpush
_fpush:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _ftos.L,A2
; if(ftos>FOR_NEST)
       move.l    (A2),D0
       cmp.l     #25,D0
       ble.s     fpush_1
; serror(10);
       pea       10
       jsr       _serror
       addq.w    #4,A7
fpush_1:
; fstack[ftos]=i;
       lea       _fstack.L,A0
       move.l    (A2),D0
       muls      #12,D0
       add.l     D0,A0
       lea       8(A6),A1
       moveq     #2,D0
       move.l    (A1)+,(A0)+
       dbra      D0,*-2
; ftos++;
       addq.l    #1,(A2)
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; struct for_stack fpop(void)
; {
       xdef      _fpop
_fpop:
       move.l    A2,-(A7)
       lea       _ftos.L,A2
; ftos--;
       subq.l    #1,(A2)
; if(ftos<0) serror(11);
       move.l    (A2),D0
       cmp.l     #0,D0
       bge.s     fpop_1
       pea       11
       jsr       _serror
       addq.w    #4,A7
fpop_1:
; return(fstack[ftos]);
       lea       _fstack.L,A0
       move.l    (A2),D0
       muls      #12,D0
       add.l     D0,A0
       move.l    8(A6),A1
       moveq     #2,D0
       move.l    (A0)+,(A1)+
       dbra      D0,*-2
       move.l    8(A6),D0
       move.l    (A7)+,A2
       rts
; }
; /* Execute a simple form of the BASIC INPUT command */
; void input(void)
; {
       xdef      _input
_input:
       link      A6,#-132
       movem.l   D2/D3/D4/D5/A2/A3/A4,-(A7)
       lea       -128(A6),A2
       lea       _get_token.L,A3
       lea       _vbuf.L,A4
; char var;
; int i=0,ix;
       clr.l     D5
; unsigned *vbufprt=vbuf;
       move.l    (A4),D4
; char inLine[128];
; unsigned int vTec;
; get_token(); /* see if prompt string is present */
       jsr       (A3)
; if(token_type==QUOTE) {
       move.b    _token_type.L,D0
       cmp.b     #6,D0
       bne.s     input_1
; printText(token); /* if so, print it and check for comma */
       pea       _token.L
       jsr       _printText
       addq.w    #4,A7
; get_token();
       jsr       (A3)
; if(*token!=',') serror(1);
       move.b    _token.L,D0
       cmp.b     #44,D0
       beq.s     input_3
       pea       1
       jsr       _serror
       addq.w    #4,A7
input_3:
; get_token();
       jsr       (A3)
       bra.s     input_2
input_1:
; }
; else printText("? "); /* otherwise, prompt with / */
       pea       @monbasic_4.L
       jsr       _printText
       addq.w    #4,A7
input_2:
; var = toupper(*token)-'A'; /* get the input var */
       move.b    _token.L,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       sub.l     #65,D0
       move.b    D0,-129(A6)
; vTec=inputLine(128);
       pea       128
       jsr       _inputLine
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D3
; if (*vbuf != 0x00 && (vTec == 0x0D || vTec == 0x0A))
       move.l    (A4),A0
       move.b    (A0),D0
       beq       input_5
       cmp.l     #13,D3
       beq.s     input_7
       cmp.l     #10,D3
       bne       input_5
input_7:
; {
; ix=0;
       clr.l     D2
; while(*vbufprt)
input_8:
       move.l    D4,A0
       tst.l     (A0)
       beq.s     input_10
; {
; inLine[ix++]=*vbufprt++;
       move.l    D4,A0
       addq.l    #4,D4
       move.l    (A0),D0
       move.l    D2,D1
       addq.l    #1,D2
       move.b    D0,0(A2,D1.L)
; inLine[ix]=0;
       clr.b     0(A2,D2.L)
       bra       input_8
input_10:
; }
; *vBufReceived = 0x00;
       move.l    _vBufReceived.L,A0
       clr.b     (A0)
; *vbuf = '\0';            
       move.l    (A4),A0
       clr.b     (A0)
; i=atoi(inLine);
       move.l    A2,-(A7)
       jsr       _atoi
       addq.w    #4,A7
       move.l    D0,D5
input_5:
; }
; variables[var] = i; /* store it */
       move.b    -129(A6),D0
       ext.w     D0
       ext.l     D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       move.l    D5,0(A0,D0.L)
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4
       unlk      A6
       rts
; }
; /* Execute a GOSUB command. */
; void gosub(void)
; {
       xdef      _gosub
_gosub:
       move.l    D2,-(A7)
; char *loc;
; get_token();
       jsr       _get_token
; /* find the label to call */
; loc = find_label(token);
       pea       _token.L
       jsr       _find_label
       addq.w    #4,A7
       move.l    D0,D2
; if(loc=='\0')
       clr.b     D0
       and.l     #255,D0
       cmp.l     D0,D2
       bne.s     gosub_1
; serror(7); /* label not defined */
       pea       7
       jsr       _serror
       addq.w    #4,A7
       bra.s     gosub_2
gosub_1:
; else {
; gpush(prog); /* save place to return to */
       move.l    _prog.L,-(A7)
       jsr       _gpush
       addq.w    #4,A7
; prog = loc;  /* start program running at that loc */
       move.l    D2,_prog.L
gosub_2:
       move.l    (A7)+,D2
       rts
; }
; }
; /* Return from GOSUB. */
; void greturn(void)
; {
       xdef      _greturn
_greturn:
; prog = gpop();
       jsr       _gpop
       move.l    D0,_prog.L
       rts
; }
; /* GOSUB stack push function. */
; void gpush(char *s)
; {
       xdef      _gpush
_gpush:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _gtos.L,A2
; gtos++;
       addq.l    #1,(A2)
; if(gtos==SUB_NEST) {
       move.l    (A2),D0
       cmp.l     #25,D0
       bne.s     gpush_1
; serror(12);
       pea       12
       jsr       _serror
       addq.w    #4,A7
; return;
       bra.s     gpush_3
gpush_1:
; }
; gstack[gtos]=s;
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _gstack.L,A0
       move.l    8(A6),0(A0,D0.L)
gpush_3:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; /* GOSUB stack pop function. */
; char *gpop(void)
; {
       xdef      _gpop
_gpop:
; if(gtos==0) {
       move.l    _gtos.L,D0
       bne.s     gpop_1
; serror(13);
       pea       13
       jsr       _serror
       addq.w    #4,A7
; return 0;
       clr.l     D0
       bra.s     gpop_3
gpop_1:
; }
; return(gstack[gtos--]);
       move.l    _gtos.L,D0
       subq.l    #1,_gtos.L
       lsl.l     #2,D0
       lea       _gstack.L,A0
       move.l    0(A0,D0.L),D0
gpop_3:
       rts
; }
; /* Entry point into parser. */
; void get_exp(int *result)
; {
       xdef      _get_exp
_get_exp:
       link      A6,#0
; get_token();
       jsr       _get_token
; if(!*token) {
       tst.b     _token.L
       bne.s     get_exp_1
; serror(2);
       pea       2
       jsr       _serror
       addq.w    #4,A7
; return;
       bra.s     get_exp_3
get_exp_1:
; }
; level2(result);
       move.l    8(A6),-(A7)
       jsr       _level2
       addq.w    #4,A7
; putback(); /* return last token read to input stream */
       jsr       _putback
get_exp_3:
       unlk      A6
       rts
; }
; /* display an error message */
; void serror(int error)
; {
       xdef      _serror
_serror:
       link      A6,#0
; static char *e[]= {
; "syntax error",
; "unbalanced parentheses",
; "no expression present",
; "equals sign expected",
; "not a variable",
; "Label table full",
; "duplicate label",
; "undefined label",
; "THEN expected",
; "TO expected",
; "too many nested FOR loops",
; "NEXT without FOR",
; "too many nested GOSUBs",
; "RETURN without GOSUB"
; };
; printText(e[error]);
       move.l    8(A6),D1
       lsl.l     #2,D1
       lea       serror_e.L,A0
       move.l    0(A0,D1.L),-(A7)
       jsr       _printText
       addq.w    #4,A7
; printText("\r\n");
       pea       @monbasic_19.L
       jsr       _printText
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /* Get a token. */
; int get_token(void)
; {
       xdef      _get_token
_get_token:
       movem.l   D2/A2/A3,-(A7)
       lea       _prog.L,A2
       lea       _token.L,A3
; register char *temp;
; token_type=0; tok=0;
       clr.b     _token_type.L
       clr.b     _tok.L
; temp=token;
       move.l    A3,D2
; if(*prog=='\0') { /* end of file */
       move.l    (A2),A0
       move.b    (A0),D0
       bne.s     get_token_1
; *token=0;
       clr.b     (A3)
; tok = FINISHED;
       move.b    #10,_tok.L
; return(token_type=DELIMITER);
       move.b    #1,_token_type.L
       moveq     #1,D0
       bra       get_token_3
get_token_1:
; }
; while(iswhite(*prog)) ++prog;  /* skip over white space */
get_token_4:
       move.l    (A2),A0
       move.b    (A0),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _iswhite
       addq.w    #4,A7
       tst.l     D0
       beq.s     get_token_6
       addq.l    #1,(A2)
       bra       get_token_4
get_token_6:
; if(*prog=='\r') { /* crlf */
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #13,D0
       bne.s     get_token_7
; ++prog; ++prog;
       addq.l    #1,(A2)
       addq.l    #1,(A2)
; tok = EOL; *token='\r';
       move.b    #9,_tok.L
       move.b    #13,(A3)
; token[1]='\n'; token[2]=0;
       move.b    #10,1(A3)
       clr.b     2(A3)
; return (token_type = DELIMITER);
       move.b    #1,_token_type.L
       moveq     #1,D0
       bra       get_token_3
get_token_7:
; }
; if(strchr("+-*^/%=;(),><", *prog)){ /* delimiter */
       move.l    (A2),A0
       move.b    (A0),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @monbasic_20.L
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       beq.s     get_token_9
; *temp=*prog;
       move.l    (A2),A0
       move.l    D2,A1
       move.b    (A0),(A1)
; prog++; /* advance to next position */
       addq.l    #1,(A2)
; temp++;
       addq.l    #1,D2
; *temp=0;
       move.l    D2,A0
       clr.b     (A0)
; return (token_type=DELIMITER);
       move.b    #1,_token_type.L
       moveq     #1,D0
       bra       get_token_3
get_token_9:
; }
; if(*prog=='"') { /* quoted string */
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #34,D0
       bne       get_token_11
; prog++;
       addq.l    #1,(A2)
; while(*prog!='"'&& *prog!='\r') *temp++=*prog++;
get_token_13:
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #34,D0
       beq.s     get_token_15
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #13,D0
       beq.s     get_token_15
       move.l    (A2),A0
       addq.l    #1,(A2)
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
       bra       get_token_13
get_token_15:
; if(*prog=='\r') serror(1);
       move.l    (A2),A0
       move.b    (A0),D0
       cmp.b     #13,D0
       bne.s     get_token_16
       pea       1
       jsr       _serror
       addq.w    #4,A7
get_token_16:
; prog++;*temp=0;
       addq.l    #1,(A2)
       move.l    D2,A0
       clr.b     (A0)
; return(token_type=QUOTE);
       move.b    #6,_token_type.L
       moveq     #6,D0
       bra       get_token_3
get_token_11:
; }
; if(isdigit(*prog)) { /* number */
       move.l    (A2),A0
       move.b    (A0),D0
       ext.w     D0
       move.w    D0,A0
       move.b    1+__ctype(A0),D0
       and.b     #4,D0
       beq       get_token_18
; while(!isdelim(*prog)) *temp++=*prog++;
get_token_20:
       move.l    (A2),A0
       move.b    (A0),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _isdelim
       addq.w    #4,A7
       tst.l     D0
       bne.s     get_token_22
       move.l    (A2),A0
       addq.l    #1,(A2)
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
       bra       get_token_20
get_token_22:
; *temp = '\0';
       move.l    D2,A0
       clr.b     (A0)
; return(token_type = NUMBER);
       move.b    #3,_token_type.L
       moveq     #3,D0
       bra       get_token_3
get_token_18:
; }
; if(isalpha(*prog)) { /* var or command */
       move.l    (A2),A0
       move.b    (A0),D0
       ext.w     D0
       move.w    D0,A0
       move.b    1+__ctype(A0),D0
       and.b     #3,D0
       beq       get_token_23
; while(!isdelim(*prog)) *temp++=*prog++;
get_token_25:
       move.l    (A2),A0
       move.b    (A0),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _isdelim
       addq.w    #4,A7
       tst.l     D0
       bne.s     get_token_27
       move.l    (A2),A0
       addq.l    #1,(A2)
       move.l    D2,A1
       addq.l    #1,D2
       move.b    (A0),(A1)
       bra       get_token_25
get_token_27:
; token_type=STRING;
       move.b    #5,_token_type.L
get_token_23:
; }
; *temp = '\0';
       move.l    D2,A0
       clr.b     (A0)
; /* see if a string is a command or a variable */
; if(token_type==STRING) {
       move.b    _token_type.L,D0
       cmp.b     #5,D0
       bne.s     get_token_31
; tok=look_up(token); /* convert to internal rep */
       move.l    A3,-(A7)
       jsr       _look_up
       addq.w    #4,A7
       move.b    D0,_tok.L
; if(!tok) token_type = VARIABLE;
       tst.b     _tok.L
       bne.s     get_token_30
       move.b    #2,_token_type.L
       bra.s     get_token_31
get_token_30:
; else token_type = COMMAND; /* is a command */
       move.b    #4,_token_type.L
get_token_31:
; }
; return token_type;
       move.b    _token_type.L,D0
       ext.w     D0
       ext.l     D0
get_token_3:
       movem.l   (A7)+,D2/A2/A3
       rts
; }
; /* Return a token to input stream. */
; void putback(void)
; {
       xdef      _putback
_putback:
       move.l    D2,-(A7)
; char *t;
; t = token;
       lea       _token.L,A0
       move.l    A0,D2
; for(; *t; t++) prog--;
putback_1:
       move.l    D2,A0
       tst.b     (A0)
       beq.s     putback_3
       subq.l    #1,_prog.L
       addq.l    #1,D2
       bra       putback_1
putback_3:
       move.l    (A7)+,D2
       rts
; }
; /* Look up a a token's internal representation in the
; token table.
; */
; int look_up(char *s)
; {
       xdef      _look_up
_look_up:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _table.L,A2
; register int i;
; char *p;
; /* convert to lowercase */
; p = s;
       move.l    8(A6),D3
; while(*p){ *p = tolower(*p); p++; }
look_up_1:
       move.l    D3,A0
       tst.b     (A0)
       beq.s     look_up_3
       move.l    D3,A0
       move.b    (A0),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.l    D3,A0
       move.b    D0,(A0)
       addq.l    #1,D3
       bra       look_up_1
look_up_3:
; /* see if token is in table */
; for(i=0; *table[i].command; i++)
       clr.l     D2
look_up_4:
       move.l    D2,D0
       muls      #21,D0
       tst.b     0(A2,D0.L)
       beq       look_up_6
; if(!strcmp(table[i].command, s)) return table[i].tok;
       move.l    8(A6),-(A7)
       move.l    A2,D1
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #21,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcmp
       addq.w    #8,A7
       tst.l     D0
       bne.s     look_up_7
       move.l    D2,D0
       muls      #21,D0
       lea       0(A2,D0.L),A0
       move.b    20(A0),D0
       ext.w     D0
       ext.l     D0
       bra.s     look_up_9
look_up_7:
       addq.l    #1,D2
       bra       look_up_4
look_up_6:
; return 0; /* unknown command */
       clr.l     D0
look_up_9:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; /* Return true if c is a delimiter. */
; int isdelim(char c)
; {
       xdef      _isdelim
_isdelim:
       link      A6,#0
       move.l    D2,-(A7)
       move.b    11(A6),D2
       ext.w     D2
       ext.l     D2
; if(strchr(" ;,+-<>/*%^=()", c) || c==9 || c=='\r' || c==0)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       pea       @monbasic_21.L
       jsr       _strchr
       addq.w    #8,A7
       tst.l     D0
       bne       isdelim_3
       cmp.b     #9,D2
       bne.s     isdelim_4
       moveq     #1,D0
       bra.s     isdelim_5
isdelim_4:
       clr.l     D0
isdelim_5:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       bne       isdelim_3
       cmp.b     #13,D2
       bne.s     isdelim_6
       moveq     #1,D0
       bra.s     isdelim_7
isdelim_6:
       clr.l     D0
isdelim_7:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       bne.s     isdelim_3
       tst.b     D2
       bne.s     isdelim_8
       moveq     #1,D0
       bra.s     isdelim_9
isdelim_8:
       clr.l     D0
isdelim_9:
       ext.w     D0
       ext.l     D0
       tst.l     D0
       beq.s     isdelim_1
isdelim_3:
; return 1;
       moveq     #1,D0
       bra.s     isdelim_10
isdelim_1:
; return 0;
       clr.l     D0
isdelim_10:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /* Return 1 if c is space or tab. */
; int iswhite(char c)
; {
       xdef      _iswhite
_iswhite:
       link      A6,#0
; if(c==' ' || c=='\t') return 1;
       move.b    11(A6),D0
       cmp.b     #32,D0
       beq.s     iswhite_3
       move.b    11(A6),D0
       cmp.b     #9,D0
       bne.s     iswhite_1
iswhite_3:
       moveq     #1,D0
       bra.s     iswhite_4
iswhite_1:
; else return 0;
       clr.l     D0
iswhite_4:
       unlk      A6
       rts
; }
; /*  Add or subtract two terms. */
; void level2(int *result)
; {
       xdef      _level2
_level2:
       link      A6,#-4
       move.l    D2,-(A7)
; register char  op;
; int hold;
; level3(result);
       move.l    8(A6),-(A7)
       jsr       _level3
       addq.w    #4,A7
; while((op = *token) == '+' || op == '-') {
level2_1:
       move.b    _token.L,D2
       move.b    _token.L,D0
       cmp.b     #43,D0
       beq.s     level2_4
       cmp.b     #45,D2
       bne.s     level2_3
level2_4:
; get_token();
       jsr       _get_token
; level3(&hold);
       pea       -4(A6)
       jsr       _level3
       addq.w    #4,A7
; arith(op, result, &hold);
       pea       -4(A6)
       move.l    8(A6),-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _arith
       add.w     #12,A7
       bra       level2_1
level2_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; /* Multiply or divide two factors. */
; void level3(int *result)
; {
       xdef      _level3
_level3:
       link      A6,#-4
       move.l    D2,-(A7)
; register char  op;
; int hold;
; level4(result);
       move.l    8(A6),-(A7)
       jsr       _level4
       addq.w    #4,A7
; while((op = *token) == '*' || op == '/' || op == '%') {
level3_1:
       move.b    _token.L,D2
       move.b    _token.L,D0
       cmp.b     #42,D0
       beq.s     level3_4
       cmp.b     #47,D2
       beq.s     level3_4
       cmp.b     #37,D2
       bne.s     level3_3
level3_4:
; get_token();
       jsr       _get_token
; level4(&hold);
       pea       -4(A6)
       jsr       _level4
       addq.w    #4,A7
; arith(op, result, &hold);
       pea       -4(A6)
       move.l    8(A6),-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _arith
       add.w     #12,A7
       bra       level3_1
level3_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; /* Process integer exponent. */
; void level4(int *result)
; {
       xdef      _level4
_level4:
       link      A6,#-4
; int hold;
; level5(result);
       move.l    8(A6),-(A7)
       jsr       _level5
       addq.w    #4,A7
; if(*token== '^') {
       move.b    _token.L,D0
       cmp.b     #94,D0
       bne.s     level4_1
; get_token();
       jsr       _get_token
; level4(&hold);
       pea       -4(A6)
       jsr       _level4
       addq.w    #4,A7
; arith('^', result, &hold);
       pea       -4(A6)
       move.l    8(A6),-(A7)
       pea       94
       jsr       _arith
       add.w     #12,A7
level4_1:
       unlk      A6
       rts
; }
; }
; /* Is a unary + or -. */
; void level5(int *result)
; {
       xdef      _level5
_level5:
       link      A6,#0
       move.l    D2,-(A7)
; register char  op;
; op = 0;
       clr.b     D2
; if((token_type==DELIMITER) && *token=='+' || *token=='-') {
       move.b    _token_type.L,D0
       cmp.b     #1,D0
       bne.s     level5_4
       move.b    _token.L,D0
       cmp.b     #43,D0
       beq.s     level5_3
level5_4:
       move.b    _token.L,D0
       cmp.b     #45,D0
       bne.s     level5_1
level5_3:
; op = *token;
       move.b    _token.L,D2
; get_token();
       jsr       _get_token
level5_1:
; }
; level6(result);
       move.l    8(A6),-(A7)
       jsr       _level6
       addq.w    #4,A7
; if(op)
       tst.b     D2
       beq.s     level5_5
; unary(op, result);
       move.l    8(A6),-(A7)
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       _unary
       addq.w    #8,A7
level5_5:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /* Process parenthesized expression. */
; void level6(int *result)
; {
       xdef      _level6
_level6:
       link      A6,#0
; if((*token == '(') && (token_type == DELIMITER)) {
       move.b    _token.L,D0
       cmp.b     #40,D0
       bne.s     level6_1
       move.b    _token_type.L,D0
       cmp.b     #1,D0
       bne.s     level6_1
; get_token();
       jsr       _get_token
; level2(result);
       move.l    8(A6),-(A7)
       jsr       _level2
       addq.w    #4,A7
; if(*token != ')')
       move.b    _token.L,D0
       cmp.b     #41,D0
       beq.s     level6_3
; serror(1);
       pea       1
       jsr       _serror
       addq.w    #4,A7
level6_3:
; get_token();
       jsr       _get_token
       bra.s     level6_2
level6_1:
; }
; else
; primitive(result);
       move.l    8(A6),-(A7)
       jsr       _primitive
       addq.w    #4,A7
level6_2:
       unlk      A6
       rts
; }
; /* Find value of number or variable. */
; void primitive(int *result)
; {
       xdef      _primitive
_primitive:
       link      A6,#0
; switch(token_type) {
       move.b    _token_type.L,D0
       ext.w     D0
       ext.l     D0
       cmp.l     #3,D0
       beq.s     primitive_4
       bgt       primitive_1
       cmp.l     #2,D0
       beq.s     primitive_3
       bra.s     primitive_1
primitive_3:
; case VARIABLE:
; *result = find_var(token);
       pea       _token.L
       jsr       _find_var
       addq.w    #4,A7
       move.l    8(A6),A0
       move.l    D0,(A0)
; get_token();
       jsr       _get_token
; return;
       bra.s     primitive_6
primitive_4:
; case NUMBER:
; *result = atoi(token);
       pea       _token.L
       jsr       _atoi
       addq.w    #4,A7
       move.l    8(A6),A0
       move.l    D0,(A0)
; get_token();
       jsr       _get_token
; return;
       bra.s     primitive_6
primitive_1:
; default:
; serror(0);
       clr.l     -(A7)
       jsr       _serror
       addq.w    #4,A7
primitive_6:
       unlk      A6
       rts
; }
; }
; /* Perform the specified arithmetic. */
; void arith(char o, int *r, int *h)
; {
       xdef      _arith
_arith:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    12(A6),D4
       move.l    16(A6),D5
; register int t, ex;
; switch(o) {
       move.b    11(A6),D0
       ext.w     D0
       ext.l     D0
       cmp.l     #45,D0
       beq       arith_3
       bgt.s     arith_9
       cmp.l     #42,D0
       beq       arith_5
       bgt.s     arith_10
       cmp.l     #37,D0
       beq       arith_7
       bra       arith_2
arith_10:
       cmp.l     #43,D0
       beq.s     arith_4
       bra       arith_2
arith_9:
       cmp.l     #94,D0
       beq       arith_8
       bgt       arith_2
       cmp.l     #47,D0
       beq       arith_6
       bra       arith_2
arith_3:
; case '-':
; *r = *r-*h;
       move.l    D4,A0
       move.l    D5,A1
       move.l    (A1),D0
       sub.l     D0,(A0)
; break;
       bra       arith_2
arith_4:
; case '+':
; *r = *r+*h;
       move.l    D4,A0
       move.l    D5,A1
       move.l    (A1),D0
       add.l     D0,(A0)
; break;
       bra       arith_2
arith_5:
; case '*':
; *r = *r * *h;
       move.l    D4,A0
       move.l    D5,A1
       move.l    (A0),-(A7)
       move.l    (A1),-(A7)
       jsr       LMUL
       move.l    (A7),(A0)
       addq.w    #8,A7
; break;
       bra       arith_2
arith_6:
; case '/':
; *r = (*r)/(*h);
       move.l    D4,A0
       move.l    D5,A1
       move.l    (A0),-(A7)
       move.l    (A1),-(A7)
       jsr       LDIV
       move.l    (A7),(A0)
       addq.w    #8,A7
; break;
       bra       arith_2
arith_7:
; case '%':
; t = (*r)/(*h);
       move.l    D4,A0
       move.l    D5,A1
       move.l    (A0),-(A7)
       move.l    (A1),-(A7)
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,D3
; *r = *r-(t*(*h));
       move.l    D4,A0
       move.l    D5,A1
       move.l    D3,-(A7)
       move.l    (A1),-(A7)
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       sub.l     D0,(A0)
; break;
       bra       arith_2
arith_8:
; case '^':
; ex = *r;
       move.l    D4,A0
       move.l    (A0),D2
; if(*h==0) {
       move.l    D5,A0
       move.l    (A0),D0
       bne.s     arith_11
; *r = 1;
       move.l    D4,A0
       move.l    #1,(A0)
; break;
       bra.s     arith_2
arith_11:
; }
; for(t=*h-1; t>0; --t) *r = (*r) * ex;
       move.l    D5,A0
       move.l    (A0),D0
       subq.l    #1,D0
       move.l    D0,D3
arith_13:
       cmp.l     #0,D3
       ble.s     arith_15
       move.l    D4,A0
       move.l    (A0),-(A7)
       move.l    D2,-(A7)
       jsr       LMUL
       move.l    (A7),(A0)
       addq.w    #8,A7
       subq.l    #1,D3
       bra       arith_13
arith_15:
; break;
arith_2:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; }
; /* Reverse the sign. */
; void unary(char o, int *r)
; {
       xdef      _unary
_unary:
       link      A6,#0
; if(o=='-') *r = -(*r);
       move.b    11(A6),D0
       cmp.b     #45,D0
       bne.s     unary_1
       move.l    12(A6),A0
       move.l    (A0),D0
       neg.l     D0
       move.l    12(A6),A0
       move.l    D0,(A0)
unary_1:
       unlk      A6
       rts
; }
; /* Find the value of a variable. */
; int find_var(char *s)
; {
       xdef      _find_var
_find_var:
       link      A6,#0
; if(!isalpha(*s)){
       move.l    8(A6),A0
       move.b    (A0),D0
       ext.w     D0
       move.w    D0,A0
       move.b    1+__ctype(A0),D0
       and.b     #3,D0
       bne.s     find_var_1
; serror(4); /* not a variable */
       pea       4
       jsr       _serror
       addq.w    #4,A7
; return 0;
       clr.l     D0
       bra.s     find_var_3
find_var_1:
; }
; return variables[toupper(*token)-'A'];
       move.b    _token.L,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       sub.l     #65,D0
       lsl.l     #2,D0
       lea       _variables.L,A0
       move.l    0(A0,D0.L),D0
find_var_3:
       unlk      A6
       rts
; }
       section   const
@monbasic_1:
       dc.b      32,0
@monbasic_2:
       dc.b      10,0
@monbasic_3:
       dc.b      61,60,62,0
@monbasic_4:
       dc.b      63,32,0
@monbasic_5:
       dc.b      115,121,110,116,97,120,32,101,114,114,111,114
       dc.b      0
@monbasic_6:
       dc.b      117,110,98,97,108,97,110,99,101,100,32,112,97
       dc.b      114,101,110,116,104,101,115,101,115,0
@monbasic_7:
       dc.b      110,111,32,101,120,112,114,101,115,115,105,111
       dc.b      110,32,112,114,101,115,101,110,116,0
@monbasic_8:
       dc.b      101,113,117,97,108,115,32,115,105,103,110,32
       dc.b      101,120,112,101,99,116,101,100,0
@monbasic_9:
       dc.b      110,111,116,32,97,32,118,97,114,105,97,98,108
       dc.b      101,0
@monbasic_10:
       dc.b      76,97,98,101,108,32,116,97,98,108,101,32,102
       dc.b      117,108,108,0
@monbasic_11:
       dc.b      100,117,112,108,105,99,97,116,101,32,108,97
       dc.b      98,101,108,0
@monbasic_12:
       dc.b      117,110,100,101,102,105,110,101,100,32,108,97
       dc.b      98,101,108,0
@monbasic_13:
       dc.b      84,72,69,78,32,101,120,112,101,99,116,101,100
       dc.b      0
@monbasic_14:
       dc.b      84,79,32,101,120,112,101,99,116,101,100,0
@monbasic_15:
       dc.b      116,111,111,32,109,97,110,121,32,110,101,115
       dc.b      116,101,100,32,70,79,82,32,108,111,111,112,115
       dc.b      0
@monbasic_16:
       dc.b      78,69,88,84,32,119,105,116,104,111,117,116,32
       dc.b      70,79,82,0
@monbasic_17:
       dc.b      116,111,111,32,109,97,110,121,32,110,101,115
       dc.b      116,101,100,32,71,79,83,85,66,115,0
@monbasic_18:
       dc.b      82,69,84,85,82,78,32,119,105,116,104,111,117
       dc.b      116,32,71,79,83,85,66,0
@monbasic_19:
       dc.b      13,10,0
@monbasic_20:
       dc.b      43,45,42,94,47,37,61,59,40,41,44,62,60,0
@monbasic_21:
       dc.b      32,59,44,43,45,60,62,47,42,37,94,61,40,41,0
       section   data
       xdef      _vmfp
_vmfp:
       dc.l      4194336
       xdef      _vvdgd
_vvdgd:
       dc.l      4194369
       xdef      _vvdgc
_vvdgc:
       dc.l      4194371
       xdef      _vdest
_vdest:
       dc.l      0
       xdef      _fgcolor
_fgcolor:
       dc.l      6356992
       xdef      _bgcolor
_bgcolor:
       dc.l      6363136
       xdef      _videoBufferQtdY
_videoBufferQtdY:
       dc.l      6363138
       xdef      _color_table_size
_color_table_size:
       dc.l      6363140
       xdef      _color_table
_color_table:
       dc.l      6363142
       xdef      _sprite_attribute_table
_sprite_attribute_table:
       dc.l      6363150
       xdef      _videoFontes
_videoFontes:
       dc.l      6363158
       xdef      _videoCursorPosCol
_videoCursorPosCol:
       dc.l      6363166
       xdef      _videoCursorPosRow
_videoCursorPosRow:
       dc.l      6363168
       xdef      _videoCursorPosColX
_videoCursorPosColX:
       dc.l      6363170
       xdef      _videoCursorPosRowY
_videoCursorPosRowY:
       dc.l      6363172
       xdef      _videoCursorBlink
_videoCursorBlink:
       dc.l      6363174
       xdef      _videoCursorShow
_videoCursorShow:
       dc.l      6363176
       xdef      _name_table
_name_table:
       dc.l      6363178
       xdef      _vdp_mode
_vdp_mode:
       dc.l      6363186
       xdef      _videoScroll
_videoScroll:
       dc.l      6363188
       xdef      _videoScrollDir
_videoScrollDir:
       dc.l      6363190
       xdef      _pattern_table
_pattern_table:
       dc.l      6363192
       xdef      _sprite_size_sel
_sprite_size_sel:
       dc.l      6363200
       xdef      _vdpMaxCols
_vdpMaxCols:
       dc.l      6363202
       xdef      _sprite_pattern_table
_sprite_pattern_table:
       dc.l      6363204
       xdef      _vdpMaxRows
_vdpMaxRows:
       dc.l      6363206
       xdef      _kbdKeyPntr
_kbdKeyPntr:
       dc.l      6331163
       xdef      _kbdKeyBuffer
_kbdKeyBuffer:
       dc.l      6331164
       xdef      _kbdvprim
_kbdvprim:
       dc.l      6331196
       xdef      _kbdvmove
_kbdvmove:
       dc.l      6331198
       xdef      _kbdvshift
_kbdvshift:
       dc.l      6331200
       xdef      _kbdvctrl
_kbdvctrl:
       dc.l      6331202
       xdef      _kbdvalt
_kbdvalt:
       dc.l      6331204
       xdef      _kbdvcaps
_kbdvcaps:
       dc.l      6331206
       xdef      _kbdvnum
_kbdvnum:
       dc.l      6331208
       xdef      _kbdvscr
_kbdvscr:
       dc.l      6331210
       xdef      _kbdvreleased
_kbdvreleased:
       dc.l      6331212
       xdef      _kbdve0
_kbdve0:
       dc.l      6331214
       xdef      _kbdScanCodeBuf
_kbdScanCodeBuf:
       dc.l      6331216
       xdef      _kbdScanCodeCount
_kbdScanCodeCount:
       dc.l      6331234
       xdef      _kbdClockCount
_kbdClockCount:
       dc.l      6331236
       xdef      _scanCode
_scanCode:
       dc.l      6331238
       xdef      _vxmaxold
_vxmaxold:
       dc.l      6331240
       xdef      _vymaxold
_vymaxold:
       dc.l      6331242
       xdef      _voverx
_voverx:
       dc.l      6331244
       xdef      _vovery
_vovery:
       dc.l      6331246
       xdef      _vparamstr
_vparamstr:
       dc.l      6331248
       xdef      _vparam
_vparam:
       dc.l      6331504
       xdef      _vbbutton
_vbbutton:
       dc.l      6331562
       xdef      _vkeyopen
_vkeyopen:
       dc.l      6331564
       xdef      _vbytetec
_vbytetec:
       dc.l      6331566
       xdef      _pposx
_pposx:
       dc.l      6331568
       xdef      _pposy
_pposy:
       dc.l      6331570
       xdef      _vbuttonwiny
_vbuttonwiny:
       dc.l      6331574
       xdef      _vbuttonwin
_vbuttonwin:
       dc.l      6331576
       xdef      _vpostx
_vpostx:
       dc.l      6331584
       xdef      _vposty
_vposty:
       dc.l      6331586
       xdef      _next_pos
_next_pos:
       dc.l      6331598
       xdef      _vdir
_vdir:
       dc.l      6331600
       xdef      _vdisk
_vdisk:
       dc.l      6331648
       xdef      _vclusterdir
_vclusterdir:
       dc.l      6331872
       xdef      _vclusteros
_vclusteros:
       dc.l      6331880
       xdef      _gDataBuffer
_gDataBuffer:
       dc.l      6331888
       xdef      _mcfgfile
_mcfgfile:
       dc.l      6332408
       xdef      _viconef
_viconef:
       dc.l      6332408
       xdef      _vcorf
_vcorf:
       dc.l      6344700
       xdef      _vcorb
_vcorb:
       dc.l      6344702
       xdef      _vcol
_vcol:
       dc.l      6344704
       xdef      _vlin
_vlin:
       dc.l      6344706
       xdef      _voutput
_voutput:
       dc.l      6344708
       xdef      _vxmax
_vxmax:
       dc.l      6344742
       xdef      _vymax
_vymax:
       dc.l      6344744
       xdef      _xpos
_xpos:
       dc.l      6344746
       xdef      _ypos
_ypos:
       dc.l      6344748
       xdef      _verro
_verro:
       dc.l      6344750
       xdef      _vdiratu
_vdiratu:
       dc.l      6344752
       xdef      _vdiratup
_vdiratup:
       dc.l      6344752
       xdef      _vinip
_vinip:
       dc.l      6344896
       xdef      _vbufk
_vbufk:
       dc.l      6344898
       xdef      _vbufkptr
_vbufkptr:
       dc.l      6344898
       xdef      _vbufkmove
_vbufkmove:
       dc.l      6344898
       xdef      _vbufkatu
_vbufkatu:
       dc.l      6344898
       xdef      _vbufkbios
_vbufkbios:
       dc.l      6344930
       xdef      _inten
_inten:
       dc.l      6344944
       xdef      _vxgmax
_vxgmax:
       dc.l      6344946
       xdef      _vygmax
_vygmax:
       dc.l      6344950
       xdef      _vmtaskatu
_vmtaskatu:
       dc.l      6348708
       xdef      _vmtask
_vmtask:
       dc.l      6348708
       xdef      _vmtaskup
_vmtaskup:
       dc.l      6348708
       xdef      _intpos
_intpos:
       dc.l      6348792
       xdef      _vtotmem
_vtotmem:
       dc.l      6348796
       xdef      _v10ms
_v10ms:
       dc.l      6348798
       xdef      _vPS2
_vPS2:
       dc.l      6348800
       xdef      _vBufXmitEmpty
_vBufXmitEmpty:
       dc.l      6348802
       xdef      _vBufReceived
_vBufReceived:
       dc.l      6348804
       xdef      _vbuf
_vbuf:
       dc.l      6348806
       xdef      _ascii
_ascii:
       dc.b      97,98,99,100,101,102,103,104,105,106,107,108
       dc.b      109,110,111,112,113,114,115,116,117,118,119
       dc.b      120,121,122,48,49,50,51,52,53,54,55,56,57,59
       dc.b      61,46,44,47,39,91,93,96,45,32,0
       xdef      _ascii2
_ascii2:
       dc.b      65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
       dc.b      80,81,82,83,84,85,86,87,88,89,90,41,33,64,35
       dc.b      36,37,94,38,42,40,58,43,62,60,63,32,123,125
       dc.b      126,95,32,0
       xdef      _ascii3
_ascii3:
       dc.b      65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
       dc.b      80,81,82,83,84,85,86,87,88,89,90,48,49,50,51
       dc.b      52,53,54,55,56,57,59,61,46,44,47,39,91,93,96
       dc.b      45,32,0
       xdef      _ascii4
_ascii4:
       dc.b      97,98,99,100,101,102,103,104,105,106,107,108
       dc.b      109,110,111,112,113,114,115,116,117,118,119
       dc.b      120,121,122,41,33,64,35,36,37,94,38,42,40,58
       dc.b      43,62,60,63,32,123,125,126,95,32,0
       xdef      _keyCode
_keyCode:
       dc.b      28,50,33,35,36,43,52,51,67,59,66,75,58,49,68
       dc.b      77,21,45,27,44,60,42,29,34,53,26,69,22,30,38
       dc.b      37,46,54,61,62,70,76,85,73,65,74,82,84,91,14
       dc.b      78,41,0
       xdef      _Reg_UCR
_Reg_UCR:
       dc.l      5121
       xdef      _Reg_UDR
_Reg_UDR:
       dc.l      5889
       xdef      _Reg_RSR
_Reg_RSR:
       dc.l      5377
       xdef      _Reg_TSR
_Reg_TSR:
       dc.l      5633
       xdef      _Reg_VR
_Reg_VR:
       dc.l      2817
       xdef      _Reg_IERA
_Reg_IERA:
       dc.l      769
       xdef      _Reg_IERB
_Reg_IERB:
       dc.l      1025
       xdef      _Reg_IPRA
_Reg_IPRA:
       dc.l      1281
       xdef      _Reg_IPRB
_Reg_IPRB:
       dc.l      1537
       xdef      _Reg_IMRA
_Reg_IMRA:
       dc.l      2305
       xdef      _Reg_IMRB
_Reg_IMRB:
       dc.l      2561
       xdef      _Reg_ISRA
_Reg_ISRA:
       dc.l      1793
       xdef      _Reg_ISRB
_Reg_ISRB:
       dc.l      2049
       xdef      _Reg_TADR
_Reg_TADR:
       dc.l      3841
       xdef      _Reg_TBDR
_Reg_TBDR:
       dc.l      4097
       xdef      _Reg_TCDR
_Reg_TCDR:
       dc.l      4353
       xdef      _Reg_TDDR
_Reg_TDDR:
       dc.l      4609
       xdef      _Reg_TACR
_Reg_TACR:
       dc.l      3073
       xdef      _Reg_TBCR
_Reg_TBCR:
       dc.l      3329
       xdef      _Reg_TCDCR
_Reg_TCDCR:
       dc.l      3585
       xdef      _Reg_GPDR
_Reg_GPDR:
       dc.l      1
       xdef      _Reg_AER
_Reg_AER:
       dc.l      257
       xdef      _Reg_DDR
_Reg_DDR:
       dc.l      513
       xdef      _p_buf
_p_buf:
       dc.l      8519680
       xdef      _variables
_variables:
       dc.l      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       dc.l      0,0,0,0,0,0
       xdef      _table
_table:
       dc.b      112,114,105,110,116,0
       ds.b      14
       dc.b      1,105,110,112,117,116,0
       ds.b      14
       dc.b      2,105,102,0
       ds.b      17
       dc.b      3,116,104,101,110,0
       ds.b      15
       dc.b      4,103,111,116,111,0
       ds.b      15
       dc.b      8,102,111,114,0
       ds.b      16
       dc.b      5,110,101,120,116,0
       ds.b      15
       dc.b      6,116,111,0
       ds.b      17
       dc.b      7,103,111,115,117,98,0
       ds.b      14
       dc.b      11,114,101,116,117,114,110,0
       ds.b      13
       dc.b      12,101,110,100,0
       ds.b      16
       dc.b      13,0
       ds.b      19
       dc.b      13
serror_e:
       dc.l      @monbasic_5,@monbasic_6,@monbasic_7,@monbasic_8
       dc.l      @monbasic_9,@monbasic_10,@monbasic_11,@monbasic_12
       dc.l      @monbasic_13,@monbasic_14,@monbasic_15,@monbasic_16
       dc.l      @monbasic_17,@monbasic_18
       section   bss
       xdef      _WORD
_WORD:
       ds.b      4
       xdef      _prog
_prog:
       ds.b      4
       xdef      _jmp_buf
_jmp_buf:
       ds.b      4
       xdef      _e_buf
_e_buf:
       ds.b      4
       xdef      _token
_token:
       ds.b      80
       xdef      _token_type
_token_type:
       ds.b      1
       xdef      _tok
_tok:
       ds.b      1
       xdef      _label_table
_label_table:
       ds.b      1400
       xdef      _fstack
_fstack:
       ds.b      300
       xdef      _ftos
_ftos:
       ds.b      4
       xdef      _gtos
_gtos:
       ds.b      4
       xdef      _gstack
_gstack:
       ds.b      100
       xref      _inputLine
       xref      _strcpy
       xref      _itoa
       xref      LDIV
       xref      LMUL
       xref      _atoi
       xref      _strlen
       xref      _tolower
       xref      _toupper
       xref      _strchr
       xref      _printText
       xref      _strcmp
       xref      __ctype
