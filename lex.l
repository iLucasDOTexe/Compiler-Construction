%{
#include "parser.tab.h"
#include "symbol_table.h"
#include "iloc.h"

extern FILE *yyin;
%}

%%
"int" { return INT; }
"float" { return FLOAT; }
"char" { return CHAR; }
"long" { return LONG; }
"short" { return SHORT; }
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.sval = strdup(yytext);
    return IDENTIFIER; }
[0-9]+[lL]? { 
    yylval.ival = atoi(yytext);
    return INTEGER; }
[0-9]+"."[0-9]* { 
    yylval.fval = atof(yytext);
    return FLOATING; }
"'"[^']"'" {
    yylval.sval = strndup(yytext + 1, 1);
    return CHAR_LITERAL;}
"=" { return ASSIGN; }
"+" { return ADD; }
"-" { return SUB; }
"*" { return MUL; }
"/" { return DIV; }
";" { return SEMICOLON; }
[ \t\n]+ ; // Ignore whitespaces
"//".* ; //Ignore single line comments
"/*"([^\*]|\*+[^*/])*\*+"/" ; //Ignore multi line comments
.           { return yytext[0]; }
%%
int yywrap() {
    return 1;
}