int a = 2;
int b = 3;
int c = a * b;
/*Expected result:
loadI 2, r1 // a = 2
loadI 3, r2 // b = 3
mult r1, r2, r3 // a * b = c => r3
*/
