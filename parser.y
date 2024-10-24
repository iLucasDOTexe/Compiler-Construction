%{
#include <stdio.h>
#include "symbol_table.h"
#define YYDEBUG 1

SymbolTable symTable;
int errorFlag = 0;

extern FILE *yyin;
void yyerror(const char *s);
int yylex(void);
%}

/* Declare the precedence and associativity of operators */
%left ADD SUB
%left MUL DIV

%union {
    int ival;
    float fval;
    char *sval;
}

%token <sval> INT FLOAT CHAR LONG SHORT IDENTIFIER
%token <ival> INTEGER
%token <fval> FLOATING
%token <sval> CHAR_LITERAL
%token ASSIGN ADD SUB MUL DIV SEMICOLON

%type <sval> type expression

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
        addSymbol(&symTable, $2, $1, 0); // Add uninitialized variable
    }
    | type IDENTIFIER ASSIGN expression {
        addSymbol(&symTable, $2, $1, 1); // Add and initialize
        checkTypeMismatch(&symTable, $2, $4);
        if (errorFlag != 0) {
            YYABORT;
        }
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        const char *identifierType = getSymbolType(&symTable, $1);
        if (identifierType != NULL) {
            checkTypeMismatch(&symTable, $1, $3);
            if (errorFlag != 0) {
                YYABORT;
            }
            setSymbolInitialized(&symTable, $1);
            checkUseAfterDeclaration(&symTable, $1);
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
    expression ADD expression
    | expression SUB expression
    | expression MUL expression
    | expression DIV expression
    | IDENTIFIER {
        if (checkUseAfterDeclaration(&symTable, $1) != 0) {
            YYABORT;
        }
        $$ = getSymbolType(&symTable, $1);
    }
    | INTEGER { $$ = "int"; }
    | FLOATING { $$ = "float"; }
    | CHAR_LITERAL { $$ = "char"; }
    ;
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
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
    return 0;
}
