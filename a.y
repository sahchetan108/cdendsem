%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex(void);
extern int yylineno;
extern FILE *yyin;
void yyerror(const char *s);

/* Simple symbol table: flat table of (name, line) */
#define MAX_SYMBOLS 2000
typedef struct {
    char *name;
    int line;
} Symbol;
static Symbol symtab[MAX_SYMBOLS];
static int symcount = 0;

void add_symbol(const char *name, int line) {
    if (!name) return;
    for (int i = 0; i < symcount; ++i) {
        if (strcmp(symtab[i].name, name) == 0) return; /* already present */
    }
    if (symcount < MAX_SYMBOLS) {
        symtab[symcount].name = strdup(name);
        symtab[symcount].line = line;
        symcount++;
    } else {
        fprintf(stderr, "Symbol table full, cannot add %s\n", name);
    }
}

void print_symbol_table() {
    printf("\n--- Symbol Table ---\n");
    printf("%-30s %s\n", "Identifier", "Line");
    printf("-------------------------------\n");
    for (int i = 0; i < symcount; ++i) {
        printf("%-30s %d\n", symtab[i].name, symtab[i].line);
    }
    printf("-------------------------------\n");
}

void free_symbol_table() {
    for (int i = 0; i < symcount; ++i) free(symtab[i].name);
}
%}

/* union for token values */
%union {
    int ival;
    char *sval;
}

/* token declarations (only once) */
%token <sval> IDENTIFIER
%token <ival> NUMBER
%token TYPE RETURN
%token FOR WHILE DO IF ELSE
%token EQ NEQ LE GE AND OR

%left OR
%left AND
%left EQ NEQ
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/'

/* dangling else fix */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start program

%%

program:
      /* empty */
    | program external_decl
    ;

external_decl:
      function_def
    | stmt
    ;

function_def:
      TYPE IDENTIFIER '(' param_list_opt ')' compound_stmt
        {
            /* record function name */
            add_symbol($2, yylineno);
            free($2);
            printf("Recognized function definition at line %d\n", yylineno);
        }
    ;

param_list_opt:
      /* empty */
    | param_list
    ;

param_list:
     
    ;

compound_stmt:
      '{' stmt_list '}'
    ;

stmt_list:
      /* empty */
    | stmt_list stmt
    ;

stmt:
      compound_stmt
    | simple_stmt
    | iteration_stmt
    | selection_stmt
    | declaration
    ;

simple_stmt:
      expr_stmt
    | ';'
    ;

expr_stmt:
      expression ';'
    | RETURN expression ';'
    ;

declaration:
      TYPE init_declarator_list ';'
        {
            /* init_declarator_list handler already added symbols */
        }
    ;

init_declarator_list:
      init_declarator
    | init_declarator_list ',' init_declarator
    ;

init_declarator:
      IDENTIFIER
        {
            add_symbol($1, yylineno);
            free($1);
        }
    | IDENTIFIER '=' expression
        {
            add_symbol($1, yylineno);
            free($1);
        }
    ;

iteration_stmt:
      WHILE '(' expression ')' stmt                       { printf("Recognized while loop at line %d\n", yylineno); }
    | DO stmt WHILE '(' expression ')' ';'                { printf("Recognized do-while loop at line %d\n", yylineno); }
    | FOR '(' for_init expr_opt ';' expr_opt ')' stmt     { printf("Recognized for loop at line %d\n", yylineno); }
    ;

for_init:
      /* empty */
    | declaration
    | expr_stmt
    ;

expr_opt:
      /* empty */
    | expression
    ;

selection_stmt:
      IF '(' expression ')' stmt %prec LOWER_THAN_ELSE    { printf("Recognized if at line %d\n", yylineno); }
    | IF '(' expression ')' stmt ELSE stmt               { printf("Recognized if-else at line %d\n", yylineno); }
    ;

expression:
      assignment_expression
    ;

assignment_expression:
      conditional_expression
    | IDENTIFIER '=' assignment_expression
        {
            /* assignment — make sure identifier is in symbol table (useful if assigned before declared in this simple grammar) */
            add_symbol($1, yylineno);
            free($1);
        }
    ;

conditional_expression:
      logical_or_expression
    | logical_or_expression '?' expression ':' conditional_expression
        {
            printf("Recognized conditional operator at line %d\n", yylineno);
        }
    ;

logical_or_expression:
      logical_and_expression
    | logical_or_expression OR logical_and_expression
    ;

logical_and_expression:
      equality_expression
    | logical_and_expression AND equality_expression
    ;

equality_expression:
      relational_expression
    | equality_expression EQ relational_expression
    | equality_expression NEQ relational_expression
    ;

relational_expression:
      additive_expression
    | relational_expression '<' additive_expression
    | relational_expression '>' additive_expression
    | relational_expression LE additive_expression
    | relational_expression GE additive_expression
    ;

additive_expression:
      multiplicative_expression
    | additive_expression '+' multiplicative_expression
    | additive_expression '-' multiplicative_expression
    ;

multiplicative_expression:
      primary_expression
    | multiplicative_expression '*' primary_expression
    | multiplicative_expression '/' primary_expression
    ;

primary_expression:
      IDENTIFIER
        {
            add_symbol($1, yylineno);
            free($1);
        }
    | NUMBER
    | '(' expression ')'
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, yylineno);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) {
            perror("fopen");
            return 1;
        }
        yyin = f;
    }
    int parse_res = yyparse();
    print_symbol_table();
    free_symbol_table();
    return parse_res;
}
