#ifndef ILOC_H
#define ILOC_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct instruction {
    char *opcode;
    char *src1;
    char *src2;
    char *dest;
    struct instruction *next;
} instruction;

void appendInstruction(instruction **head, instruction *newInstr);
instruction* createInstruction(const char *opcode, const char *src1, const char *src2, const char *dest);
void printInstructions(instruction *head);
void freeInstructions(instruction *head);
int getNewRegister();
char* createRegisterName(int regNum);

#endif