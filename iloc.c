#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "iloc.h"

void appendInstruction(instruction **head, instruction *newInstr) {
    if (newInstr == NULL) {
        return;
    }
    if (*head == NULL) {
        *head = newInstr;
    } else {
        instruction *current = *head;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = newInstr;
    }
}

instruction* createInstruction(const char *opcode, const char *src1, const char *src2, const char *dest) {
    instruction *instr = malloc(sizeof(instruction));
    instr->opcode = strdup(opcode);
    instr->src1 = src1 ? strdup(src1) : NULL;
    instr->src2 = src2 ? strdup(src2) : NULL;
    instr->dest = dest ? strdup(dest) : NULL;
    instr->next = NULL;
    return instr;
}

void printInstructions(instruction *head) {
    instruction *current = head;
    while (current != NULL) {
        if (current->src1 && current->src2 && current->dest) {
            printf("%s %s, %s, %s\n", current->opcode, current->src1, current->src2, current->dest);
        } else if (current->src1 && current->dest) {
            printf("%s %s, %s\n", current->opcode, current->src1, current->dest);
        } else if (current->dest) {
            printf("%s, %s\n", current->opcode, current->dest);
        } else {
            printf("%s\n", current->opcode);
        }
        current = current->next;
    }
}

void freeInstructions(instruction *head) {
    instruction *current = head;
    while (current != NULL) {
        instruction *next = current->next;
        free(current->opcode);
        if (current->src1) {
            free(current->src1);
        }
        if (current->src2) {
            free(current->src2);
        }
        if (current->dest) {
            free(current->dest);
        }
        free(current);
        current = next;
    }
}
