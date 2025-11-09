%{
#include <string.h>
#include "y.tab.h"
%}

%%

"->"            { return ARROW; }
"|"             { return OR; }
";"             { return SEMICOLON; }
[ \t\n]+        { /* skip whitespace */ }
"e"             { strcpy(yylval.str, "e"); return ID; }

":="            { strcpy(yylval.str, ":="); return ID; }
"=="            { strcpy(yylval.str, "=="); return ID; }
"<"             { strcpy(yylval.str, "<"); return ID; }
">"             { strcpy(yylval.str, ">"); return ID; }
"("             { strcpy(yylval.str, "("); return ID; }
")"             { strcpy(yylval.str, ")"); return ID; }
"*"             { strcpy(yylval.str, "*"); return ID; }
"+"             { strcpy(yylval.str, "+"); return ID; }
[a-zA-Z_][a-zA-Z0-9_']* { strcpy(yylval.str, yytext); return ID; }
.               { /* ignore other characters */ }

%%

int yywrap(void) { return 1; }      


//create defs.h and paste:
// #ifndef DEFS_H
// #define DEFS_H

// #define MAX_SYM 64
// #define MAX_RHS 10
// #define MAX_PRODS 100
// #define MAX_NT 50

// #endif
