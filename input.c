/* This is a sample test file
   It contains loops, expressions,
   multi-line comments, and conditionals */

int main() {
    int a = 10, b = 5, c;
    int result;

    // arithmetic and assignment
    c = a + b * 2;

    // while loop
    while (a > b) {
        a = a - 1;
    }

    // do-while loop
    do {
        b = b + 2;
    } while (b < 20);

    // for loop
    for (int i = 0; i < 5; i = i + 1) {
        c = c + i;
    }

    // if-else
    if (c > 20) {
        result = c ? c : 20;   /* conditional operator */
    } else {
        result = 0;
    }

    return 0;
}
