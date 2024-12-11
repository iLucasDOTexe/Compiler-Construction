#include "symbol_table.h"
#include "iloc.h"

extern int errorFlag;
int globalRegCounter = 1;

void initSymbolTable(SymbolTable *table) {
    table->count = 0;
    table->capacity = 10;
    table->symbols = malloc(table->capacity * sizeof(Symbol));
    table->parent = NULL;
}

int addSymbol(SymbolTable *table, const char *name, const char *type, int initialized) {
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
    char *regName = createRegisterName(globalRegCounter++);
    table->symbols[table->count].name = strdup(name);
    table->symbols[table->count].type = strdup(type);
    table->symbols[table->count].initialized = initialized;
    table->symbols[table->count].regName = regName;
    ++table->count;
    return 0;
}

Symbol* findSymbol(SymbolTable *table, const char *name) {
    for (int i = 0; i < table->count; ++i) {
        if (strcmp(table->symbols[i].name, name) == 0) {
            return &(table->symbols[i]);
        }
    }
    if (table->parent != NULL) {
        return findSymbol(table->parent, name);
    }
    fprintf(stderr, "Error: Variable %s not declared.\n", name);
    return NULL;
}

int checkUseAfterDeclaration(SymbolTable *table, const char *name) {
    Symbol *symbol = findSymbol(table, name);
    if (symbol != NULL) {
        if (!symbol->initialized) {
            fprintf(stderr, "Error: Variable %s used without initialization.\n", name);
            return 1;
        }
        return 0;
    } else {
        fprintf(stderr, "Error: Variable %s not declared.\n", name);
        return 1;
    }
}

void checkTypeMismatch(SymbolTable *table, const char *name, const char *type) {
    Symbol *symbol = findSymbol(table, name);
    if (symbol == NULL) {
        errorFlag = 1;
        return;
    }
    if (type == NULL) {
        fprintf(stderr, "Error: Type for expression is unknown or invalid.\n");
        errorFlag = 1;
    }
    const char *varType = symbol->type;
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
    Symbol *symbol = findSymbol(table, name);
    if (symbol == NULL) {
        fprintf(stderr, "Error: Variable %s not found for that type retrieval.\n", name);
        return NULL;
    }
    return symbol->type;
}

void setSymbolInitialized(SymbolTable *table, const char *name) {
    Symbol *symbol = findSymbol(table, name);
    if (symbol != NULL) {
        symbol->initialized = 1;
    }
}

char* getSymbolRegister(SymbolTable *table, const char *name) {
    Symbol *symbol = findSymbol(table, name);
    if (symbol != NULL) {
        return symbol->regName;
    } else {
        fprintf(stderr, "Error: Varaible %s not declared.\n", name);
        return NULL;
    }
}

void freeSymbolTable(SymbolTable *table) {
    for (int i = 0; i < table->count; i++) {
        free(table->symbols[i].name);
        free(table->symbols[i].type);
        if (table->symbols[i].regName) {
            free(table->symbols[i].regName);
        }
    }
    free(table->symbols);
    free(table);
}

void enterScope(SymbolTable **currentTable) {
    SymbolTable *newTable = malloc(sizeof(SymbolTable));
    initSymbolTable(newTable);
    newTable->parent = *currentTable;
    *currentTable = newTable;
}

void exitScope(SymbolTable **currentTable) {
    SymbolTable *oldTable = *currentTable;
    *currentTable = oldTable->parent;
    freeSymbolTable(oldTable);
}