#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "iloc.h"

static int labelCounter = 0;

void appendInstruction(instruction **head, instruction *newInstr) {
    if (newInstr == NULL) {
        return;
    }
    if (*head == NULL) {
        *head = newInstr;
    } else {
        (*head)->tail->next = newInstr;
        (*head)->tail = newInstr->tail;
    }
}

instruction* createInstruction(const char *opcode, const char *src1, const char *src2, const char *dest) {
    instruction *instr = malloc(sizeof(instruction));
    instr->label = NULL;
    instr->opcode = strdup(opcode);
    instr->src1 = src1 ? strdup(src1) : NULL;
    instr->src2 = src2 ? strdup(src2) : NULL;
    instr->dest = dest ? strdup(dest) : NULL;
    instr->next = NULL;
    instr->tail = instr;
    return instr;
}

char* createRegisterName(int regNum) {
    char *regName = malloc(10);
    sprintf(regName, "r%d", regNum);
    return regName;
}

void printInstructions(instruction *head, FILE *out) {
    instruction *current = head;
    while (current != NULL) {
        if (current->label) {
            fprintf(out, "%s:\n", current->label);
        }
        if (current->opcode) {
            if (current->src1 && current->src2 && current->dest) {
                fprintf(out, "%s %s, %s, %s\n", current->opcode, current->src1, current->src2, current->dest);
            } else if (current->src1 && current->dest) {
                fprintf(out, "%s %s, %s\n", current->opcode, current->src1, current->dest);
            } else if (current->dest) {
                fprintf(out, "%s %s\n", current->opcode, current->dest);
            } else {
                fprintf(out, "%s\n", current->opcode);
            }
        }
        current = current->next;
    }
}

void freeInstructions(instruction *head) {
    instruction *current = head;
    while (current != NULL) {
        instruction *next = current->next;
        if (current->opcode) free(current->opcode);
        if (current->label) free(current->label);
        if (current->src1) free(current->src1);
        if (current->src2) free(current->src2);
        if (current->dest) free(current->dest);
        free(current);
        current = next;
    }
}

instruction* createLabelInstruction(const char *label) {
    instruction *instr = malloc(sizeof(instruction));
    instr->label = strdup(label);
    instr->opcode = NULL;
    instr->src1 = NULL;
    instr->src2 = NULL;
    instr->dest = NULL;
    instr->next = NULL;
    instr->tail = instr;
    return instr;
}

void appendLabelInstruction(instruction **head, const char *label) {
    instruction *instr = createLabelInstruction(label);
    appendInstruction(head, instr);
}

char* createNewLabel() {
    char *labelName = malloc(10);
    sprintf(labelName, "L%d", labelCounter++);
    return labelName;
}