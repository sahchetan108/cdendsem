
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "defs.h"

typedef struct {
    char lhs[MAX_SYM];
    char rhs[MAX_RHS][MAX_SYM];
    int rhsCount;
} Production;

Production prods[MAX_PRODS];
int nProds = 0;

char nonTerminals[MAX_NT][MAX_SYM];
int nNonTerms = 0;

char terminals[MAX_RHS][MAX_SYM];
int nTerms = 0;

/* FIRST and FOLLOW sets */
char first[MAX_NT][MAX_RHS][MAX_SYM];
int fCount[MAX_NT];

char follow[MAX_NT][MAX_RHS][MAX_SYM];
int flCount[MAX_NT];

/* Function declarations */
int findNonTerminal(const char *s);
int findTerminal(const char *s);
int isTerminal(const char *s);
int addToSet(char set[][MAX_SYM], int *count, const char *sym);

void computeAllFIRST(void);
void computeFOLLOW(int ntIndex);
void collectTerminals(void);

void yyerror(const char *s);
int yylex(void);

/* temporaries used by parser actions */
char currentLHS[MAX_SYM];
char tempRHS[MAX_RHS][MAX_SYM];
int tempRHSCount = 0;
%}

%union { char str[64]; }
%token <str> ID
%token ARROW OR SEMICOLON

%%

grammar:
    rules
    ;

rules:
    /* empty */
    | rules rule
    ;

rule:
    ID { strcpy(currentLHS, $1); } ARROW alternatives SEMICOLON
    ;

alternatives:
    alternative
    | alternatives OR alternative
    ;

alternative:
    symbols
    {
        /* copy currentLHS and tempRHS into a production entry */
        strcpy(prods[nProds].lhs, currentLHS);
        prods[nProds].rhsCount = tempRHSCount;
        for (int i = 0; i < tempRHSCount; ++i)
            strcpy(prods[nProds].rhs[i], tempRHS[i]);
        nProds++;

        /* reset tempRHS only (keep currentLHS for next alternative) */
        tempRHSCount = 0;
    }
    ;

symbols:
      ID            { if (tempRHSCount < MAX_RHS) strcpy(tempRHS[tempRHSCount++], $1); }
    | symbols ID    { if (tempRHSCount < MAX_RHS) strcpy(tempRHS[tempRHSCount++], $2); }
    ;

%%

/* Helper functions */

int findNonTerminal(const char *s) {
    for (int i = 0; i < nNonTerms; ++i)
        if (strcmp(nonTerminals[i], s) == 0) return i;
    return -1;
}

int findTerminal(const char *s) {
    for (int i = 0; i < nTerms; ++i)
        if (strcmp(terminals[i], s) == 0) return i;
    return -1;
}

int isTerminal(const char *s) {
    if (strcmp(s, "Ïµ") == 0 || strcmp(s, "e") == 0) return 1;
    return findNonTerminal(s) == -1;
}

int addToSet(char set[][MAX_SYM], int *count, const char *sym) {
    for (int i = 0; i < *count; ++i)
        if (strcmp(set[i], sym) == 0) return 0;
    if (*count >= MAX_RHS) return 0;
    strcpy(set[(*count)++], sym);
    return 1;
}

void collectTerminals(void) {
    nTerms = 0;
    addToSet(terminals, &nTerms, "$"); /* end marker */
    
    for (int p = 0; p < nProds; ++p) {
        for (int i = 0; i < prods[p].rhsCount; ++i) {
            char *sym = prods[p].rhs[i];
            if (isTerminal(sym) && strcmp(sym, "Ïµ") != 0 && strcmp(sym, "e") != 0) {
                addToSet(terminals, &nTerms, sym);
            }
        }
    }
}

void computeAllFIRST(void) {
    int changed = 1;
    int iterations = 0;
    
    for (int i = 0; i < nNonTerms; ++i) {
        fCount[i] = 0;
    }
    
    while (changed && iterations < 100) {
        changed = 0;
        iterations++;
        
        for (int nt = 0; nt < nNonTerms; ++nt) {
            int oldCount = fCount[nt];
            
            for (int p = 0; p < nProds; ++p) {
                if (strcmp(prods[p].lhs, nonTerminals[nt]) != 0) continue;
                
                if (prods[p].rhsCount == 0 || 
                    (prods[p].rhsCount == 1 && 
                     (strcmp(prods[p].rhs[0], "Ïµ") == 0 || strcmp(prods[p].rhs[0], "e") == 0))) {
                    addToSet(first[nt], &fCount[nt], "e");
                    continue;
                }
                
                int allNullable = 1;
                for (int i = 0; i < prods[p].rhsCount; ++i) {
                    char *sym = prods[p].rhs[i];
                    
                    if (strcmp(sym, "Ïµ") == 0 || strcmp(sym, "e") == 0) continue;
                    
                    if (isTerminal(sym)) {
                        addToSet(first[nt], &fCount[nt], sym);
                        allNullable = 0;
                        break;
                    } else {
                        int idx = findNonTerminal(sym);
                        if (idx == -1) break;
                        
                        int hasEps = 0;
                        for (int k = 0; k < fCount[idx]; ++k) {
                            if (strcmp(first[idx][k], "e") == 0 || strcmp(first[idx][k], "Ïµ") == 0) {
                                hasEps = 1;
                            } else {
                                addToSet(first[nt], &fCount[nt], first[idx][k]);
                            }
                        }
                        
                        if (!hasEps) {
                            allNullable = 0;
                            break;
                        }
                    }
                }
                
                if (allNullable && prods[p].rhsCount > 0) {
                    addToSet(first[nt], &fCount[nt], "e");
                }
            }
            
            if (fCount[nt] != oldCount) changed = 1;
        }
    }
}

void computeFOLLOW(int ntIndex) {
    if (ntIndex == 0) addToSet(follow[ntIndex], &flCount[ntIndex], "$");

    for (int p = 0; p < nProds; ++p) {
        for (int i = 0; i < prods[p].rhsCount; ++i) {
            if (strcmp(prods[p].rhs[i], nonTerminals[ntIndex]) != 0) continue;

            int allNullable = 1;
            for (int j = i+1; j < prods[p].rhsCount; ++j) {
                char *next = prods[p].rhs[j];
                
                if (strcmp(next, "Ïµ") == 0 || strcmp(next, "e") == 0) continue;
                
                if (isTerminal(next)) {
                    addToSet(follow[ntIndex], &flCount[ntIndex], next);
                    allNullable = 0;
                    break;
                } else {
                    int idx = findNonTerminal(next);
                    if (idx == -1) break;
                    
                    int hasEps = 0;
                    for (int k = 0; k < fCount[idx]; ++k) {
                        if (strcmp(first[idx][k], "e") == 0 || strcmp(first[idx][k], "Ïµ") == 0) {
                            hasEps = 1;
                        } else {
                            addToSet(follow[ntIndex], &flCount[ntIndex], first[idx][k]);
                        }
                    }
                    if (!hasEps) { 
                        allNullable = 0; 
                        break; 
                    }
                }
            }
            
            if (allNullable) {
                int lhsIdx = findNonTerminal(prods[p].lhs);
                if (lhsIdx != -1 && lhsIdx != ntIndex) {
                    for (int k = 0; k < flCount[lhsIdx]; ++k)
                        addToSet(follow[ntIndex], &flCount[ntIndex], follow[lhsIdx][k]);
                }
            }
        }
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

int main(void) {
    printf("Enter grammar (format: A -> B C | D ; ). Use whitespace between symbols.\n");
    printf("Use 'ε' or 'Ïµ' for epsilon. End with Ctrl+D (Linux/Mac) or Ctrl+Z (Windows).\n\n");
    
    if (yyparse() != 0) { 
        fprintf(stderr, "Parsing failed.\n"); 
        return 1; 
    }

    for (int i = 0; i < nProds; ++i) {
        if (prods[i].lhs[0] != '\0' && findNonTerminal(prods[i].lhs) == -1) {
            if (nNonTerms >= MAX_NT) {
                fprintf(stderr, "Too many non-terminals!\n");
                return 1;
            }
            strcpy(nonTerminals[nNonTerms++], prods[i].lhs);
        }
    }

    collectTerminals();

    printf("\n--- Productions Parsed ---\n");
    for (int i = 0; i < nProds; ++i) {
        printf("%d: %s ->", i, prods[i].lhs);
        if (prods[i].rhsCount == 0 || 
            (prods[i].rhsCount == 1 && 
             (strcmp(prods[i].rhs[0], "e") == 0 || strcmp(prods[i].rhs[0], "Ïµ") == 0))) {
            printf(" e");
        } else {
            for (int j = 0; j < prods[i].rhsCount; ++j)
                printf(" %s", prods[i].rhs[j]);
        }
        printf("\n");
    }

    computeAllFIRST();

    for (int i = 0; i < nNonTerms; ++i) {
        flCount[i] = 0;
    }

    for (int pass = 0; pass < nNonTerms * 2; ++pass)
        for (int i = 0; i < nNonTerms; ++i)
            computeFOLLOW(i);

    printf("\n--- FIRST and FOLLOW Sets ---\n");
    for (int i = 0; i < nNonTerms; ++i) {
        printf("FIRST(%s) = { ", nonTerminals[i]);
        for (int j = 0; j < fCount[i]; ++j) {
            printf("%s ", first[i][j]);
        }
        printf("}\n");
        printf("FOLLOW(%s) = { ", nonTerminals[i]);
        for (int j = 0; j < flCount[i]; ++j) {
            printf("%s ", follow[i][j]);
        }
        printf("}\n");
    }

    return 0;
}
