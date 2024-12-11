%code requires {
#include "iloc.h"
extern int globalRegCounter;
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"
#include "iloc.h"
#define YYDEBUG 1

SymbolTable *symTable;
int errorFlag = 0;
instruction *codeHead = NULL;
int regCounter = 1;

extern FILE *yyin;
void yyerror(const char *s);
int yylex(void);
int getNewRegister();
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
    struct {
        instruction *code;
    } stmt_attr;
    struct {
        char *place;
        instruction *code;
    } cond_attr;
}

%token <sval> INT FLOAT CHAR LONG SHORT IDENTIFIER
%token <ival> INTEGER
%token <fval> FLOATING
%token <sval> CHAR_LITERAL
%token ASSIGN ADD SUB MUL DIV SEMICOLON
%token IF ELSE FOR
%token GT LT GE LE EQ NE

%type <expr_attr> expression
%type <sval> type
%type <stmt_attr> program statement statements if_statement for_statement assignment declaration
%type <cond_attr> condition

%define parse.error verbose

%%

program:
    program statement {
        if ($1.code == NULL) {
            $$.code = $2.code;
        } else {
            appendInstruction(&($1.code), $2.code);
            $$.code = $1.code;
        }
        codeHead = $$.code;
    }
    | { $$.code = NULL; }
    ;

statement:
    declaration SEMICOLON { $<stmt_attr>$.code = $1.code; }
    | assignment SEMICOLON { $<stmt_attr>$.code = $1.code; }
    | expression SEMICOLON { $<stmt_attr>$.code = $1.code; }
    | if_statement { $<stmt_attr>$.code = $1.code; }
    | for_statement { $<stmt_attr>$.code = $1.code; }
    ;

statements:
    statement { $$.code = $1.code; }
    | statements statement {
        if ($1.code == NULL) {
            $$.code = $2.code;
        } else {
            appendInstruction(&($1.code), $2.code);
            $$.code = $1.code;
        }
    }
    ;

if_statement:
    IF '(' condition ')' '{' { enterScope(&symTable); } statements '}' { exitScope(&symTable); } ELSE '{' { enterScope(&symTable); } statements '}' { exitScope(&symTable); } {
        char *L_true = createNewLabel();
        char *L_false = createNewLabel();
        char *L_end = createNewLabel();
        instruction *code = NULL;

        appendInstruction(&code, $3.code);

        instruction *cbr = createInstruction("cbr", $3.place, L_true, L_false);
        appendInstruction(&code, cbr);
        
        instruction *label_true = createLabelInstruction(L_true);
        appendInstruction(&code, label_true);
        appendInstruction(&code, $7.code);
        instruction *jump_end = createInstruction("jumpI", NULL, NULL, L_end);
        appendInstruction(&code, jump_end);
        
        instruction *label_false = createLabelInstruction(L_false);
        appendInstruction(&code, label_false);
        appendInstruction(&code, $13.code);

        instruction *label_end = createLabelInstruction(L_end);
        appendInstruction(&code, label_end);

        $$.code = code;
    }
    ;

for_statement:
    FOR '(' assignment ';' condition ';' expression ')' '{' statement '}' {
        char *L_cond = createNewLabel();
        char *L_body = createNewLabel();
        char *L_end = createNewLabel();
        instruction *code = NULL;
        appendInstruction(&code, $3.code);
        appendLabelInstruction(&code, L_cond);
        appendInstruction(&code, $5.code);
        instruction *cbr = createInstruction("cbr", $5.place, L_body, L_end);
        appendInstruction(&code, cbr);
        appendLabelInstruction(&code, L_body);
        appendInstruction(&code, $10.code);
        appendInstruction(&code, $7.code);
        instruction *jump_cond = createInstruction("jumpI", NULL, NULL, L_cond);
        appendInstruction(&code, jump_cond);
        appendLabelInstruction(&code, L_end);
        $$ = (typeof($$)){.code = code};
    }
    ;

condition:
    expression GT expression {
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
        instruction *code = NULL;
        appendInstruction(&code, $1.code);
        appendInstruction(&code, $3.code);
        instruction *instr = createInstruction("cmp_GT", $1.place, $3.place, resultReg);
        appendInstruction(&code, instr);
        $$.place = resultReg;
        $$.code = code;
    }
    | expression LT expression {}
    | expression GE expression {}
    | expression LE expression {}
    | expression EQ expression {}
    | expression NE expression {}
    ;

declaration:
    type IDENTIFIER {
        //char *regName = createRegisterName(getNewRegister());
        int res = addSymbol(symTable, $2, $1, 0);
        if (res != 0) {
            YYABORT;
        }
        $$.code = NULL;
    }
    | type IDENTIFIER ASSIGN expression {
        //char *regName = createRegisterName(getNewRegister());
        int res = addSymbol(symTable, $2, $1, 1);
        if (res != 0) {
            YYABORT;
        }
        Symbol *symbol = findSymbol(symTable, $2);
        char *regName = symbol->regName;
        checkTypeMismatch(symTable, $2, $4.type);
        if (errorFlag != 0) {
            YYABORT;
        }
        instruction *code = $4.code;
        if (code && code->tail && code->tail->dest) {
            instruction *lastInstr = code->tail;
            free(lastInstr->dest);
            lastInstr->dest = strdup(regName);
            $$.code = code;
        } else {
            if ($4.place && strcmp(regName, $4.place) != 0) {
                instruction *instr = createInstruction("i2i", $4.place, NULL, regName);
                appendInstruction(&code, instr);
            }
            $$.code = code;
        }
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        Symbol *symbol = findSymbol(symTable, $1);
        if (symbol) {
            checkTypeMismatch(symTable, $1, $3.type);
            if (errorFlag != 0) {
                YYABORT;
            }
            setSymbolInitialized(symTable, $1);
            checkUseAfterDeclaration(symTable, $1);
            char *regName = symbol->regName;
            instruction *code = $3.code;
            if (code && code->tail && code->tail->dest) {
                instruction *lastInstr = code->tail;
                free(lastInstr->dest);
                lastInstr->dest = strdup(regName);
                $$.code = code;
            } else {
                if ($3.place && strcmp(regName, $3.place) != 0) {
                    instruction *instr = createInstruction("i2i", $3.place, NULL, regName);
                    appendInstruction(&code, instr);
                }
            }
            $$.code = code;
        } else {
            fprintf(stderr, "Error: Variable %s not declared.\n", $1);
            YYABORT;
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
        instruction *code = NULL;
        appendInstruction(&code, $1.code);
        appendInstruction(&code, $3.code);
        int regNum = getNewRegister();
        char *resultReg = createRegisterName(regNum);
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
        Symbol *symbol = findSymbol(symTable, $1);
        if (symbol == NULL) {
            fprintf(stderr, "Error: Variable %s not declared.\n", $1);
            YYABORT;
        }
        if (checkUseAfterDeclaration(symTable, $1) != 0) {
            YYABORT;
        }
        $$ = (typeof($$)){.type = symbol->type, .place = strdup(symbol->regName), .code = NULL};
    }
    | INTEGER { 
        int regNum = getNewRegister();
        char *regName = createRegisterName(regNum);
        char valueStr[20];
        sprintf(valueStr, "%i", $1);
        instruction *instr = createInstruction("loadI", valueStr, NULL, regName);
        $$ = (typeof($$)){.type  = "int", .place = regName, .code = instr};
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
    if (regCounter < globalRegCounter) {
        regCounter = globalRegCounter;
    }
    return regCounter++;
}

int main(int argc, char **argv) {
    extern int yydebug;
    yydebug = 1;
    
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            fprintf(stderr, "Error: Could not open file %s\n", argv[1]);
            return 1;
        }
        yyin = file;
    }
    symTable = malloc(sizeof(SymbolTable));
    initSymbolTable(symTable);
    codeHead = NULL;
    
    if (yyparse() != 0 || errorFlag != 0) {
        return 1;
    }

    printInstructions(codeHead);
    freeInstructions(codeHead);

    return 0;
}
