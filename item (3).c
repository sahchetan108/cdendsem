#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_PRODUCTIONS 50
#define MAX_SYMBOLS 20
#define MAX_ITEMS 200
#define MAX_STATES 100
#define MAX_LEN 50

typedef struct {
    char lhs;                    
    char rhs[MAX_LEN];          
} Production;

typedef struct {
    int prod_num;               
    int dot_pos;                
} Item;

typedef struct {
    Item items[MAX_ITEMS];
    int count;
} ItemSet;

typedef struct {
    int from_state;
    int to_state;
    char symbol;
} Transition;

Production productions[MAX_PRODUCTIONS];
int prod_count = 0;
ItemSet states[MAX_STATES];
int state_count = 0;
Transition transitions[MAX_STATES * MAX_SYMBOLS];
int trans_count = 0;
char start_symbol;
char non_terminals[MAX_SYMBOLS];
char terminals[MAX_SYMBOLS];
int nt_count = 0, t_count = 0;

void read_grammar();
void identify_symbols();
void print_grammar();
void print_item(Item item);
void print_item_set(int state_num);
bool is_non_terminal(char c);
bool item_exists(ItemSet *set, Item item);
void add_item(ItemSet *set, Item item);
void closure(ItemSet *set);
ItemSet goto_operation(ItemSet *set, char symbol);
bool item_sets_equal(ItemSet *s1, ItemSet *s2);
int find_existing_state(ItemSet *new_set);
void construct_canonical_collection();
void print_transitions();

int main() {
    printf("=== LR(0) Canonical Collection Generator ===\n\n");
    
    read_grammar();
    identify_symbols();
    
    printf("\n--- Grammar Read Successfully ---\n");
    print_grammar();
    
    printf("\n--- Constructing Canonical Collection ---\n");
    construct_canonical_collection();
    
    printf("\n--- Canonical LR(0) Item Sets ---\n");
    for (int i = 0; i < state_count; i++) {
        print_item_set(i);
    }
    
    printf("\n--- Transitions ---\n");
    print_transitions();
    
    return 0;
}

void read_grammar() {
    printf("Enter the number of productions: ");
    scanf("%d", &prod_count);
    getchar(); 
    
    printf("\nEnter the augmented grammar:\n");
    
    for (int i = 0; i < prod_count; i++) {
        char line[MAX_LEN];
        printf("Production %d: ", i);
        fgets(line, MAX_LEN, stdin);
        line[strcspn(line, "\n")] = 0; 
        int j = 0;
        productions[i].lhs = line[j++];
        while (j < strlen(line) && (line[j] == '-' || line[j] == '>')) j++;
        int k = 0;
        while (j < strlen(line)) {
            productions[i].rhs[k++] = line[j++];
        }
        productions[i].rhs[k] = '\0';
    }
    start_symbol = productions[0].lhs; 
}

void identify_symbols() {
    bool nt_found[256] = {false};
    bool t_found[256] = {false};
    for (int i = 0; i < prod_count; i++) {
        if (!nt_found[(unsigned char)productions[i].lhs]) {
            nt_found[(unsigned char)productions[i].lhs] = true;
            non_terminals[nt_count++] = productions[i].lhs;
        }
    }
    for (int i = 0; i < prod_count; i++) {
        for (int j = 0; j < strlen(productions[i].rhs); j++) {
            char c = productions[i].rhs[j];
            if (c != '.' && !nt_found[(unsigned char)c] && !t_found[(unsigned char)c]) {
                t_found[(unsigned char)c] = true;
                terminals[t_count++] = c;
            }
        }
    }
}

void print_grammar() {
    printf("\nProductions:\n");
    for (int i = 0; i < prod_count; i++) {
        printf("%d: %c -> %s\n", i, productions[i].lhs, productions[i].rhs);
    }
    printf("\nNon-terminals: ");
    for (int i = 0; i < nt_count; i++) {
        printf("%c ", non_terminals[i]);
    }
    printf("\nTerminals: ");
    for (int i = 0; i < t_count; i++) {
        printf("%c ", terminals[i]);
    }
    printf("\n");
}

void print_item(Item item) {
    Production prod = productions[item.prod_num];
    printf("%c -> ", prod.lhs);
    int len = strlen(prod.rhs);
    for (int i = 0; i <= len; i++) {
        if (i == item.dot_pos) {
            printf("·");
        }
        if (i < len) {
            printf("%c", prod.rhs[i]);
        }
    }
}

void print_item_set(int state_num) {
    printf("\nI%d:\n", state_num);
    for (int i = 0; i < states[state_num].count; i++) {
        printf("  ");
        print_item(states[state_num].items[i]);
        printf("\n");
    }
}

bool is_non_terminal(char c) {
    for (int i = 0; i < nt_count; i++) {
        if (non_terminals[i] == c) return true;
    }
    return false;
}

bool item_exists(ItemSet *set, Item item) {
    for (int i = 0; i < set->count; i++) {
        if (set->items[i].prod_num == item.prod_num &&
            set->items[i].dot_pos == item.dot_pos) {
            return true;
        }
    }
    return false;
}

void add_item(ItemSet *set, Item item) {
    if (!item_exists(set, item)) {
        set->items[set->count++] = item;
    }
}

void closure(ItemSet *set) {
    bool added = true;
    while (added) {
        added = false;
        int current_count = set->count;
        for (int i = 0; i < current_count; i++) {
            Item item = set->items[i];
            Production prod = productions[item.prod_num];
            if (item.dot_pos < strlen(prod.rhs)) {
                char next_symbol = prod.rhs[item.dot_pos];
                if (is_non_terminal(next_symbol)) {
                    for (int j = 0; j < prod_count; j++) {
                        if (productions[j].lhs == next_symbol) {
                            Item new_item = {j, 0};
                            if (!item_exists(set, new_item)) {
                                add_item(set, new_item);
                                added = true;
                            }
                        }
                    }
                }
            }
        }
    }
}

ItemSet goto_operation(ItemSet *set, char symbol) {
    ItemSet result = {.count = 0};
    for (int i = 0; i < set->count; i++) {
        Item item = set->items[i];
        Production prod = productions[item.prod_num];
        if (item.dot_pos < strlen(prod.rhs) &&
            prod.rhs[item.dot_pos] == symbol) {
            Item new_item = {item.prod_num, item.dot_pos + 1};
            add_item(&result, new_item);
        }
    }
    closure(&result);
    return result;
}

bool item_sets_equal(ItemSet *s1, ItemSet *s2) {
    if (s1->count != s2->count) return false;
    for (int i = 0; i < s1->count; i++) {
        if (!item_exists(s2, s1->items[i])) {
            return false;
        }
    }
    return true;
}

int find_existing_state(ItemSet *new_set) {
    for (int i = 0; i < state_count; i++) {
        if (item_sets_equal(&states[i], new_set)) {
            return i;
        }
    }
    return -1;
}

void construct_canonical_collection() {
    states[0].count = 0;
    Item initial_item = {0, 0};
    add_item(&states[0], initial_item);
    closure(&states[0]);
    state_count = 1;
    int processed = 0;
    while (processed < state_count) {
        ItemSet current = states[processed];
        for (int i = 0; i < nt_count; i++) {
            ItemSet new_set = goto_operation(&current, non_terminals[i]);
            if (new_set.count > 0) {
                int existing = find_existing_state(&new_set);
                if (existing == -1) {
                    states[state_count] = new_set;
                    transitions[trans_count].from_state = processed;
                    transitions[trans_count].to_state = state_count;
                    transitions[trans_count].symbol = non_terminals[i];
                    trans_count++;
                    state_count++;
                } else {
                    transitions[trans_count].from_state = processed;
                    transitions[trans_count].to_state = existing;
                    transitions[trans_count].symbol = non_terminals[i];
                    trans_count++;
                }
            }
        }
        for (int i = 0; i < t_count; i++) {
            ItemSet new_set = goto_operation(&current, terminals[i]);   
            if (new_set.count > 0) {
                int existing = find_existing_state(&new_set);
                if (existing == -1) {
                    states[state_count] = new_set;
                    transitions[trans_count].from_state = processed;
                    transitions[trans_count].to_state = state_count;
                    transitions[trans_count].symbol = terminals[i];
                    trans_count++;
                    state_count++;
                } else {
                    transitions[trans_count].from_state = processed;
                    transitions[trans_count].to_state = existing;
                    transitions[trans_count].symbol = terminals[i];
                    trans_count++;
                }
            }
        }
        processed++;
    }
}

void print_transitions() {
    for (int i = 0; i < trans_count; i++) {
        printf("GOTO(I%d, %c) = I%d\n",
               transitions[i].from_state,
               transitions[i].symbol,
               transitions[i].to_state);
    }
}