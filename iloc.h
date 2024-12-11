#ifndef ILOC_H
#define ILOC_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct instruction {
    char *label;
    char *opcode;
    char *src1;
    char *src2;
    char *dest;
    struct instruction *next;
    struct instruction *tail;
} instruction;

void appendInstruction(instruction **head, instruction *newInstr);
instruction* createInstruction(const char *opcode, const char *src1, const char *src2, const char *dest);
void printInstructions(instruction *head, FILE *out);
void freeInstructions(instruction *head);
int getNewRegister();
char* createRegisterName(int regNum);
char* createNewLabel();
instruction* createLabelInstruction(const char *label);
void appendLabelInstruction(instruction **head, const char *label);

#endif