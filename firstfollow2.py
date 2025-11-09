# FIRST and FOLLOW computation (epsilon = 'e')

from collections import defaultdict

# ---------- Define Grammar ----------
grammar = {
    'S': ['a B D h'],
    'B': ['c C'],
    'C': ['b C', 'e'],
    'D': ['E F'],
    'E': ['g', 'e'],
    'F': ['f', 'e']
}
# ------------------------------------

non_terminals = list(grammar.keys())
terminals = set()

# Identify terminals
for head, prods in grammar.items():
    for prod in prods:
        for symbol in prod.split():
            if symbol not in grammar and symbol != 'e':
                terminals.add(symbol)

FIRST = defaultdict(set)
FOLLOW = defaultdict(set)


# ---------- FIRST Computation ----------
def first(symbol):
    # Terminal
    if symbol in terminals:
        return {symbol}
    # Epsilon
    if symbol == 'e':
        return {'e'}
    # Cached
    if FIRST[symbol]:
        return FIRST[symbol]

    first_set = set()
    for production in grammar[symbol]:
        symbols = production.split()
        for sym in symbols:
            sym_first = first(sym)
            first_set |= (sym_first - {'e'})
            if 'e' not in sym_first:
                break
        else:
            first_set.add('e')

    FIRST[symbol] = first_set
    return first_set


# ---------- Compute FIRST for all ----------
for nt in non_terminals:
    first(nt)


# ---------- FOLLOW Computation ----------
def compute_follow():
    start_symbol = non_terminals[0]
    FOLLOW[start_symbol].add('$')

    changed = True
    while changed:
        changed = False
        for head, prods in grammar.items():
            for prod in prods:
                symbols = prod.split()
                for i, sym in enumerate(symbols):
                    if sym in non_terminals:
                        follow_before = set(FOLLOW[sym])

                        # Consider symbols after sym
                        trailer = set()
                        if i + 1 < len(symbols):
                            for next_sym in symbols[i + 1:]:
                                first_next = first(next_sym)
                                trailer |= (first_next - {'e'})
                                if 'e' not in first_next:
                                    break
                            else:
                                trailer |= FOLLOW[head]
                        else:
                            trailer |= FOLLOW[head]

                        FOLLOW[sym] |= trailer

                        if FOLLOW[sym] != follow_before:
                            changed = True


# ---------- Compute FOLLOW ----------
compute_follow()

# ---------- Display Results ----------
print("GRAMMAR:")
for head, prods in grammar.items():
    print(f"  {head} -> {' | '.join(prods)}")

print("\nFIRST sets:")
for nt in non_terminals:
    print(f"  FIRST({nt}) = {{ {', '.join(sorted(FIRST[nt]))} }}")

print("\nFOLLOW sets:")
for nt in non_terminals:
    print(f"  FOLLOW({nt}) = {{ {', '.join(sorted(FOLLOW[nt]))} }}")
