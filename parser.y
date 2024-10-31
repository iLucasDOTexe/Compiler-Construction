%code requires {
#include "iloc.h"
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"
#include "iloc.h"
#define YYDEBUG 1

SymbolTable symTable;
int errorFlag = 0;
instruction *codeHead = NULL;
int regCounter = 1;

extern FILE *yyin;
void yyerror(const char *s);
int yylex(void);
int getNewRegister();
char* createRegisterName(int);
%}

/* Declare the precedence and associativity of operators */
%left ADD SUB
%left MUL DIV

%union {
    int ival;
    float fval;
    char *sval;
    struct {
        char *type;
        char *place;
        instruction *code;
    } expr_attr;
}

%token <sval> INT FLOAT CHAR LONG SHORT IDENTIFIER
%token <ival> INTEGER
%token <fval> FLOATING
%token <sval> CHAR_LITERAL
%token ASSIGN ADD SUB MUL DIV SEMICOLON

%type <expr_attr> expression
%type <sval> type

%define parse.error verbose

%%

program:
    program statement
    | //empty
    ;

statement:
    declaration SEMICOLON
    | assignment SEMICOLON
    | expression SEMICOLON
    ;

declaration:
    type IDENTIFIER {
        char *regName = createRegisterName(getNewRegister());
        addSymbol(&symTable, $2, $1, 0, NULL); // Add uninitialized variable
    }
    | type IDENTIFIER ASSIGN expression {
        addSymbol(&symTable, $2, $1, 1, $4.place); // Add and initialize
        checkTypeMismatch(&symTable, $2, $4.type);
        if (errorFlag != 0) {
            YYABORT;
        }
        instruction *code = $4.code;
        appendInstruction(&codeHead, code);
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        const char *identifierType = getSymbolType(&symTable, $1);
        if (identifierType != NULL) {
            checkTypeMismatch(&symTable, $1, $3.type);
            if (errorFlag != 0) {
                YYABORT;
            }
            setSymbolInitialized(&symTable, $1);
            checkUseAfterDeclaration(&symTable, $1);
            char *regName = getSymbolRegister(&symTable, $1);
            instruction *code = NULL;
            appendInstruction(&code, $3.code);
            if (strcmp(regName, $3.place) != 0) {
                instruction *instr = createInstruction("i2i", $3.place, NULL, regName);
                appendInstruction(&code, instr);
            }
            appendInstruction(&codeHead, code);
        } else {
            fprintf(stderr, "Error: Variable %s not declared.\n", $1);
        }
    }
    ;

type:
    INT { $$ = "int"; }
    | FLOAT { $$ = "float"; }
    | CHAR { $$ = "char"; }
    | LONG { $$ = "long"; }
    | SHORT { $$ = "short"; }
    ;

expression:
    expression ADD expression {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        instruction *code = NULL;
        appendInstruction(&code, $1.code);
        appendInstruction(&code, $3.code);
        instruction *instr = createInstruction("add", $1.place, $3.place, resultReg);
        appendInstruction(&code, instr);
        $$ = (typeof($$)){.type = "int", .place = resultReg, .code = code};
    }
    | expression SUB expression {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        instruction *code = NULL;
        appendInstruction(&code, $1.code);
        appendInstruction(&code, $3.code);
        instruction *instr = createInstruction("sub", $1.place, $3.place, resultReg);
        appendInstruction(&code, instr);
        $$ = (typeof($$)){.type = "int", .place = resultReg, .code = code};
    }
    | expression MUL expression {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        instruction *code = NULL;
        appendInstruction(&code, $1.code);
        appendInstruction(&code, $3.code);
        instruction *instr = createInstruction("mult", $1.place, $3.place, resultReg);
        appendInstruction(&code, instr);
        $$ = (typeof($$)){.type = "int", .place = resultReg, .code = code};

    }
    | expression DIV expression {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        instruction *code = NULL;
        appendInstruction(&code, $1.code);
        appendInstruction(&code, $3.code);
        instruction *instr = createInstruction("div", $1.place, $3.place, resultReg);
        appendInstruction(&code, instr);
        $$ = (typeof($$)){.type = "int", .place = resultReg, .code = code};
    }
    | IDENTIFIER {
        if (checkUseAfterDeclaration(&symTable, $1) != 0) {
            YYABORT;
        }
        char *regName = getSymbolRegister(&symTable, $1);
        $$ = (typeof($$)){.type = getSymbolType(&symTable, $1), .place = strdup(regName), .code = NULL};
    }
    | INTEGER { 
        char valueStr[20];
        sprintf(valueStr, "%i", $1);
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        instruction *instr = createInstruction("loadI", valueStr, NULL, resultReg);
        instruction *code = NULL;
        appendInstruction(&code, instr);
        $$ = (typeof($$)){.type  = "int", .place = resultReg, .code = instr};
    }
    | FLOATING {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        char valueStr[20];
        sprintf(valueStr, "%f", $1);
        instruction *instr = createInstruction("loadI", valueStr, NULL, resultReg);
        $$ = (typeof($$)){.type  = "float", .place = resultReg, .code = instr};
    }
    | CHAR_LITERAL {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        char valueStr[20];
        sprintf(valueStr, "%s", $1);
        instruction *instr = createInstruction("loadI", valueStr, NULL, resultReg);
        $$ = (typeof($$)){.type  = "char", .place = resultReg, .code = instr};

    }
    ;
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int getNewRegister() {
    return regCounter++;
}

char* createRegisterName(int regNum) {
    char *regName = malloc(10);
    sprintf(regName, "r%d", regNum);
    return regName;
}

int main(int argc, char **argv) {
    extern int yydebug;
    yydebug = 0;
    
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            fprintf(stderr, "Error: Could not open file %s\n", argv[1]);
            return 1;
        }
        yyin = file;
    }
    
    initSymbolTable(&symTable);
    
    if (yyparse() != 0 || errorFlag != 0) {
        return 1;
    }

    printInstructions(codeHead);
    freeInstructions(codeHead);

    return 0;
}
