# LR(0) Canonical Collection Generator (Corrected)

from collections import defaultdict

# Read grammar from user
def read_grammar():
    grammar = defaultdict(list)
    n = int(input("Enter number of productions: "))
    print("Enter productions (use '|' for multiple productions in one line):")
    for _ in range(n):
        prod = input()
        lhs, rhs = prod.split("=")
        lhs = lhs.strip()
        rhs_list = rhs.strip().split("|")
        for r in rhs_list:
            grammar[lhs].append(r.strip())
    return grammar

# Augment grammar (S' -> S)
def augment_grammar(grammar):
    start_symbol = list(grammar.keys())[0]
    augmented_start = start_symbol + "'"
    grammar[augmented_start] = [start_symbol]
    return augmented_start

# Compute CLOSURE of an item set
def closure(items_set, grammar):
    closure_set = set(items_set)
    added = True
    while added:
        added = False
        new_items = set()
        for item in closure_set:
            dot_pos = item.find('.')
            if dot_pos < len(item) - 1:
                symbol_after_dot = item[dot_pos + 1]
                if symbol_after_dot in grammar:  # Non-terminal
                    for prod in grammar[symbol_after_dot]:
                        new_item = symbol_after_dot + '->.' + prod
                        if new_item not in closure_set:
                            new_items.add(new_item)
                            added = True
        closure_set.update(new_items)
    return closure_set

# Compute GOTO of an item set for a given symbol
def goto(items_set, symbol, grammar):
    goto_set = set()
    for item in items_set:
        dot_pos = item.find('.')
        if dot_pos < len(item) - 1 and item[dot_pos + 1] == symbol:
            moved_dot_item = item[:dot_pos] + symbol + '.' + item[dot_pos + 2:]
            goto_set.add(moved_dot_item)
    return closure(goto_set, grammar)

# Build Canonical Collection of LR(0) Item Sets
def canonical_collection(grammar, start_symbol):
    initial_item = start_symbol + '->.' + grammar[start_symbol][0]
    I0 = closure({initial_item}, grammar)
    C = [I0]
    transitions = {}

    added = True
    while added:
        added = False
        for I in C:
            symbols_after_dot = set()
            for item in I:
                dot_pos = item.find('.')
                if dot_pos < len(item) - 1:
                    symbols_after_dot.add(item[dot_pos + 1])
            for symbol in symbols_after_dot:
                new_set = goto(I, symbol, grammar)
                if new_set and new_set not in C:
                    C.append(new_set)
                    added = True
                if new_set:
                    transitions[(frozenset(I), symbol)] = new_set
    return C, transitions

# Display item sets and transitions
def display_canonical_collection(C, transitions):
    print("\nCanonical Collection of LR(0) Item Sets:")
    for idx, I in enumerate(C):
        print(f"I{idx} :")
        for item in sorted(I):
            print(" ", item)
        for (from_I, symbol), to_I in transitions.items():
            if frozenset(I) == from_I:
                to_idx = C.index(to_I)
                print(f"GOTO(I{idx}, {symbol}) = I{to_idx}")
        print("-" * 40)

# Main function
def main():
    grammar = read_grammar()
    augmented_start = augment_grammar(grammar)

    print("\nAugmented Grammar :")
    for lhs in grammar:
        print(f"{lhs} -> {' | '.join(grammar[lhs])}")

    C, transitions = canonical_collection(grammar, augmented_start)
    display_canonical_collection(C, transitions)

if __name__ == "__main__":
    main()
