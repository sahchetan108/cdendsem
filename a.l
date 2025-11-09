%{
#include "y.tab.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

void yyerror(const char *s);

/* keep track of comment count */
int comment_count = 0;
%}

%option noyywrap
%option yylineno

%x COMMENT

%%

"/*" {
        comment_count++;
        printf("Detected multiline comment start at line %d\n", yylineno);
        BEGIN(COMMENT);
     }

<COMMENT>"*/" {
        printf("Multiline comment ended at line %d\n", yylineno);
        BEGIN(INITIAL);
     }

<COMMENT>\n      { /* new line inside comment */ }
<COMMENT>.       { /* eat comment content */ }


"//".*           { printf("Single-line comment detected at line %d\n", yylineno); }


[ \t\r]+         { }
\n               { }


"int"            { return TYPE; }
"float"          { return TYPE; }
"double"         { return TYPE; }
"char"           { return TYPE; }
"void"           { return TYPE; }
"return"         { return RETURN; }

"for"            { return FOR; }
"while"          { return WHILE; }
"do"             { return DO; }
"if"             { return IF; }
"else"           { return ELSE; }


"?"              { return '?'; }
":"              { return ':'; }

"=="             { return EQ; }
"!="             { return NEQ; }
"<="             { return LE; }
">="             { return GE; }
"&&"             { return AND; }
"||"             { return OR; }

"("              { return '('; }
")"              { return ')'; }
"{"              { return '{'; }
"}"              { return '}'; }
";"              { return ';'; }
","              { return ','; }
"+"              { return '+'; }
"-"              { return '-'; }
"*"              { return '*'; }
"/"              { return '/'; }
"<"              { return '<'; }
">"              { return '>'; }
"="              { return '='; }


[0-9]+           {
                    yylval.ival = atoi(yytext);
                    return NUMBER;
                 }


[a-zA-Z_][a-zA-Z0-9_]* {
                    yylval.sval = strdup(yytext);
                    return IDENTIFIER;
                 }

.                { return yytext[0]; }

%%


