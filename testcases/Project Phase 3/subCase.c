int a = 2;
int b = 4;
int c = b - a;
/*Expected result:
loadI 2, r1 // a = 2
loadI 3, r2 // b = 3
sub r2, r1, r3 // b - a = c => r3
*/
