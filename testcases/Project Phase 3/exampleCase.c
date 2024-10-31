int a = 2;
int b = 3;
int c = 1;
int d = a + b + c;
/*Expected result:
loadI 2, r1 // a = 2
loadI 3, r2 // b = 3
loadI 1, r3 // c = 1
add r1, r2, r4 // a + b = 5 => r4
add r4, r3, r5 // r4 + c = 6 => r5
*/
