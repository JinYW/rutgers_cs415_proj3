%{

#include <stdio.h>
#include "attr.h"
#include "instrutil.h"
int yylex();
void yyerror(char * s);

#include "symtab.h"

FILE *outfile;
char *CommentBuffer;
 
%}

%union {tokentype token;
        regInfo targetReg;
        labelInfo labelType;
        }

%token PROG PERIOD VAR 
%token INT BOOL ARRAY RANGE OF WRITELN THEN IF 
%token BEG END ASG DO FOR
%token EQ NEQ LT LEQ 
%token AND OR XOR NOT TRUE FALSE 
%token ELSE
%token WHILE
%token <token> ID ICONST 

%type <targetReg> exp  lvalue  condexp
%type <labelType> ifhead

%start program

%nonassoc EQ NEQ LT LEQ 
%left '+' '-' 
%left '*' 

%nonassoc THEN
%nonassoc ELSE


%%
program : {emitComment("Assign STATIC_AREA_ADDRESS to register \"r0\"");
           emit(NOLABEL, LOADI, STATIC_AREA_ADDRESS, 0, EMPTY); } 
           PROG ID ';' block PERIOD { }
	;

block	: variables cmpdstmt { }
	;

variables: /* empty */
	| VAR vardcls { }
	;

vardcls	: vardcls vardcl ';' { }
	| vardcl ';' { }
	| error ';' { yyerror("***Error: illegal variable declaration\n");}  
	;

vardcl	: idlist ':' INT { } /* incorrect rule */
	;

idlist	: idlist ',' ID { 
                            //add variable check 
                            insert($3.str, STATIC_AREA_ADDRESS + NextOffset());
                        }
	| ID		{    //add variable check 
                    insert($1.str, STATIC_AREA_ADDRESS + NextOffset()); 
                }
	;

stmtlist : stmtlist ';' stmt { }
	| stmt { }
        | error { yyerror("***Error: illegal statement \n");}
	;

stmt    : ifstmt { }
	| wstmt { }
	| fstmt { }
	| astmt { }
	| writestmt { }
	| cmpdstmt { }
	;

cmpdstmt: BEG stmtlist END { }
	;


ifstmt :   ifhead THEN
            {
                    emit(NOLABEL, CBR, $1.targetRegister, $1.thenLabel, $1.exitLabel);
                    emit($1.thenLabel, NOP, EMPTY, EMPTY, EMPTY);
                    emitComment("This is the \"true\" branch");
                    }
             stmt { 
                    //emitComment("This is the \"false\" branch");
                    emitComment("Exist this branch");
                    emit(NOLABEL, BR, $1.exitLabel, EMPTY, EMPTY);
                    emit($1.exitLabel, NOP, EMPTY, EMPTY, EMPTY);
                    } 
        | ifhead THEN
            {
                    emit(NOLABEL, CBR, $1.targetRegister, $1.thenLabel, $1.elseLabel);
                    emit($1.thenLabel, NOP, EMPTY, EMPTY, EMPTY);
                    emitComment("This is the \"true\" branch");
                    }
         withelse {
                    emit(NOLABEL, BR, $1.exitLabel, EMPTY, EMPTY);
                    emit($1.elseLabel, NOP, EMPTY, EMPTY, EMPTY); 
            } 
            ELSE { emitComment("This is the \"false\" branch"); }
          stmt { 
                    emit(NOLABEL, BR, $1.exitLabel, EMPTY, EMPTY);
                    emit($1.exitLabel, NOP, EMPTY, EMPTY, EMPTY);
          }
	;

withelse : ifhead THEN {
                    emit(NOLABEL, CBR, $1.targetRegister, $1.thenLabel, $1.elseLabel);
                    emit($1.thenLabel, NOP, EMPTY, EMPTY, EMPTY);
                    emitComment("This is the \"true\" branch");
                }

            withelse 
                {
                        emit(NOLABEL, BR, $1.exitLabel, EMPTY, EMPTY);
                        emit($1.elseLabel, NOP, EMPTY, EMPTY, EMPTY); 
                } 
            ELSE 
                { emitComment("This is the \"false\" branch"); }
            withelse{
                emit(NOLABEL, BR, $1.exitLabel, EMPTY, EMPTY);
                emit($1.exitLabel, NOP, EMPTY, EMPTY, EMPTY);

            };

        |   astmt{};

ifhead : IF condexp {   
                        
                        int label1 = NextLabel();
                        int label2 = NextLabel();
                        int label3 = NextLabel();

                        $$.targetRegister = $2.targetRegister;
                        $$.thenLabel = label1;
                        $$.elseLabel = label2;
                        $$.exitLabel = label3;

                        //emitComment("This is the \"true\" branch"); 

                        }
        ;

writestmt: WRITELN '(' exp ')' {    
                                    //if exp = a+b. we can not do lookup(a+b)

                                    varMapEntry *entry = lookup($3.str);
                                    int offset = entry->offset;
                                    // store data to MEM[1024], then output 1024
                                    emit(NOLABEL, OUTPUT, offset, EMPTY, EMPTY);
                                }
	;

wstmt	: WHILE  { emitComment("Control code for \"WHILE DO\"");}
          condexp { emitComment("Body of \"WHILE\" construct starts here");}
          DO stmt  { }
	;


fstmt : FOR ID ASG ICONST ',' ICONST DO astmt { }
	;

astmt : lvalue ASG exp { emit(NOLABEL, STORE, $3.targetRegister, $1.targetRegister, EMPTY); }
	;

lvalue	: ID { 
            int newReg1 = NextRegister();
            varMapEntry *entry = lookup($1.str);

            if (entry) {
                    
                    $$.targetRegister = newReg1;
                    int offset = entry->offset;

                    sprintf(CommentBuffer, "Compute address of variable \"%s\" at offset %d in register %d", $1.str, offset, newReg1);
                    emitComment(CommentBuffer);
                    emit(NOLABEL, LOADI, offset, newReg1, EMPTY);
                    
                }
            else {
                printf("\n*** ERROR ***: Variable %s not declared.\n", $1.str);
            }

        }
        |  ID '[' exp ']' { }
        ;

exp	: exp '+' exp		{ int newReg = NextRegister();
                                  $$.targetRegister = newReg;
                                  emit(NOLABEL, 
                                       ADD, 
                                       $1.targetRegister, 
                                       $3.targetRegister, 
                                       newReg);
                                }

        | exp '-' exp		{ int newReg = NextRegister(); 
                                  $$.targetRegister = newReg;
                                  emit(NOLABEL, 
                                       SUB, 
                                       $1.targetRegister, 
                                       $3.targetRegister, 
                                       newReg);
                                }

	| exp '*' exp		{ int newReg = NextRegister(); 
                                  $$.targetRegister = newReg;
                                  emit(NOLABEL, 
                                       MULT, 
                                       $1.targetRegister, 
                                       $3.targetRegister, 
                                       newReg);
                                }

        | ID			{   int newReg = NextRegister();

                            varMapEntry *entry = lookup($1.str);

                            if (entry) {
                                    
                                    $$.targetRegister = newReg;
                                    $$.str = $1.str;
                                    int offset = entry->offset;

                                    sprintf(CommentBuffer, "Compute address of variable \"%s\" at offset %d in register %d", $1.str, offset, newReg);
                                    emitComment(CommentBuffer);
                                    emit(NOLABEL, LOADAI, EMPTY, offset-1024, newReg);
                                    
                                }
                            else {
                                printf("\n*** ERROR ***: Variable %s not declared.\n", $1.str);
                            }
	                    }

        | ID '[' exp ']'	{ }


	| ICONST                { int newReg = NextRegister();
	                          $$.targetRegister = newReg;
	                          emit(NOLABEL, LOADI, $1.num, newReg, EMPTY); }

	| error { yyerror("***Error: illegal expression\n");}  
	;

condexp	: exp NEQ exp		{ 
                                int newReg = NextRegister();
                                $$.targetRegister = newReg;
                                emit(NOLABEL, CMPNE, $1.targetRegister, $3.targetRegister, newReg);
                              }
	| exp EQ exp	{ 
                                int newReg = NextRegister();
                                $$.targetRegister = newReg;
                                emit(NOLABEL, CMPEQ, $1.targetRegister, $3.targetRegister, newReg);
                              }
	| exp LT exp	{ 
                                int newReg = NextRegister();
                                $$.targetRegister = newReg;
                                emit(NOLABEL, CMPLT, $1.targetRegister, $3.targetRegister, newReg);
                              }
	| exp LEQ exp	{ 
                                int newReg = NextRegister();
                                $$.targetRegister = newReg;
                                emit(NOLABEL, CMPLE, $1.targetRegister, $3.targetRegister, newReg);
                              }
	| error { yyerror("***Error: illegal conditional expression\n");}  
        ;

%%

void yyerror(char* s) {
        fprintf(stderr,"%s\n",s);
	fflush(stderr);
        }

int main() {
  printf("\n          CS415 Spring 2016\n           Code Generator\n");
  printf("    Version 1.0, Monday, April 1 \n\n");
  
  outfile = fopen("iloc.out", "w");
  if (outfile == NULL) { 
    printf("ERROR: cannot open output file \"iloc.out\".\n");
    return -1;
  }

  CommentBuffer = (char *) malloc(500);  
  InitSymbolTable();

  printf("1\t");
  yyparse();
  printf("\n");
  
  PrintSymbolTable();

  /*** START: THIS IS BOGUS AND NEEDS TO BE REMOVED ***/    
  /***
  emitComment("LOTS MORE BOGUS CODE");
  emit(1, NOP, EMPTY, EMPTY, EMPTY);
  emit(NOLABEL, LOADI, 12, 1, EMPTY);
  emit(NOLABEL, LOADI, 1024, 2, EMPTY);
  emit(NOLABEL, STORE, 1, 2, EMPTY);
  emit(NOLABEL, OUTPUT, 1024, EMPTY, EMPTY);
  emit(NOLABEL, LOADI, -5, 3, EMPTY);
  emit(NOLABEL, CMPLT, 1, 3, 4);
  emit(NOLABEL, STORE, 4, 2, EMPTY);
  emit(NOLABEL, OUTPUT, 1024, EMPTY, EMPTY);
  emit(NOLABEL, CBR, 4, 1, 2);
  emit(2, NOP, EMPTY, EMPTY, EMPTY);
  ***/
  /*** END: THIS IS BOGUS AND NEEDS TO BE REMOVED ***/    

  fclose(outfile);
  
  return 1;
}




