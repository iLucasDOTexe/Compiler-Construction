int a;
a = 2;
int b = 3;
int c = 1;
int d = a + b + c;

if (d > c) {
   int e = a;
   b = a;
}
else {
   int f;
   f = a;
   b = a;
}
int g = b;

/*
test.ir (one of possible irs)

<BB0>
loadI 2, r1
loadI 3, r2
loadI 1, r3
add r1, r2, r4
add r4, r3, r5
cmp_GT r5, r3, r6
cbr r6, L0, L1

<BB1>
L0:
i2i r1, r7
i2i r1, r2
jumpI L2

<BB2>
L1:
i2i r1, r8
i2i r1, r2

<BB3>
L2:
i2i r2, r9

*/

/*Actual Output:
loadI 2, r1
loadI 3, r2
loadI 1, r3
add r1, r2, r5
add r5, r3, r4
cmp_GT r4, r3, r7
cbr r7, L0, L1

L0:
i2i r1, r5
i2i r1, r2
jumpI L2

L1:
i2i r1, r6
i2i r1, r2

L2:
i2i r2, r7
*/