#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char *name;        // Variable name
    char *type;        // Data type as a string (e.g., "int", "float")
    int initialized;   // Initialization status (0: not initialized, 1: initialized)
    char *regName;
} Symbol;

typedef struct {
    Symbol *symbols;
    int count;
    int capacity;
} SymbolTable;

void initSymbolTable(SymbolTable *table);
int addSymbol(SymbolTable *table, const char *name, const char *type, int initialized, char *regName);
int findSymbol(SymbolTable *table, const char *name);
int checkUseAfterDeclaration(SymbolTable *table, const char *name);
void checkTypeMismatch(SymbolTable *table, const char *name, const char *type);
char* getSymbolType(SymbolTable *table, const char *name);
void setSymbolInitialized(SymbolTable *table, const char *name);
char* getSymbolRegister(SymbolTable *table, const char *name);

#endif
