#include "symbol_table.h"

extern int errorFlag;

void initSymbolTable(SymbolTable *table) {
    table->count = 0;
    table->capacity = 10;
    table->symbols = malloc(table->capacity * sizeof(Symbol));
}

int addSymbol(SymbolTable *table, const char *name, const char *type, int initialized, char *regName) {
    //DEBUG
    if (name == NULL || type == NULL) {
        fprintf(stderr, "Error: Null pointer passed to addSymbol: name=%s, type=%s\n", name, type);
        return 1;
    }
    if (table->count == table->capacity) {
        table->capacity *= 2;
        table->symbols = realloc(table->symbols, table->capacity * sizeof(Symbol));
    }

    for (int i = 0; i < table->count; ++i) {
        if (strcmp(table->symbols[i].name, name) == 0) {
            fprintf(stderr, "Error: Variable %s already declared.\n", name);
            return -1;
        }
    }
    //DEBUG
    //printf("Adding symbol: name=%s, type=%s, initialized=%d\n", name, type, initialized);
    table->symbols[table->count].name = strdup(name);
    table->symbols[table->count].type = strdup(type);
    table->symbols[table->count].initialized = initialized;
    table->symbols[table->count].regName = regName;
    ++table->count;
    return 0;
}

int findSymbol(SymbolTable *table, const char *name) {
    for (int i = 0; i < table->count; ++i) {
        if (strcmp(table->symbols[i].name, name) == 0) {
            return i;
        }
    }
    fprintf(stderr, "Error: Variable %s not declared.\n", name);
    return -1;
}

int checkUseAfterDeclaration(SymbolTable *table, const char *name) {
    int index = findSymbol(table, name);
    if (index != -1 && !table->symbols[index].initialized) {
        fprintf(stderr, "Error: Variable %s used without initialization.\n", name);
        return 1;
    }
    return 0;
}

void checkTypeMismatch(SymbolTable *table, const char *name, const char *type) {
    int index = findSymbol(table, name);
    if (index == -1) {
        errorFlag = 1;
        return;
    }
    if (type == NULL) {
        fprintf(stderr, "Error: Type for expression is unknown or invalid.\n");
        errorFlag = 1;
    }
    const char *varType = table->symbols[index].type;
    if (strcmp(varType, type) == 0) {
        return;
    }
    if (strcmp(type, "int") == 0) {
        if (strcmp(varType, "short") == 0 || strcmp(varType, "long") == 0 /*|| strcmp(varType, "float") == 0*/) {
            return;
        }
    }
    if (strcmp(type, "short") == 0) {
        if (strcmp(varType, "int") == 0 || strcmp(varType, "long") == 0) {
            return;
        }
    }
    fprintf(stderr, "Error: Type mismatch for variable %s (expected %s but got %s).\n", name, varType, type);
    errorFlag = 1;
}

char* getSymbolType(SymbolTable *table, const char *name) {
    int index = findSymbol(table, name);
    if (index == -1) {
        fprintf(stderr, "Error: Variable %s not found for that type retrieval.\n", name);
        return NULL;
    }
    return table->symbols[index].type;
}

void setSymbolInitialized(SymbolTable *table, const char *name) {
    int index = findSymbol(table, name);
    if (index != -1) {
        table->symbols[index].initialized = 1;
    }
}

char* getSymbolRegister(SymbolTable *table, const char *name) {
    int index = findSymbol(table, name);
    if (index != -1) {
        return table->symbols[index].regName;
    } else {
        fprintf(stderr, "Error: Varaible %s not declared.\n", name);
        return NULL;
    }
}