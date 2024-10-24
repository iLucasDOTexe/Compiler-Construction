# Compiler and flags
CC = gcc
CFLAGS = -Wall -g

# Flex and Bison tools
FLEX = flex
BISON = bison

# Source files
LEX_FILE = lex.l
YACC_FILE = parser.y
SYMBOL_TABLE_SRC = symbol_table.c

# Output files
LEX_OUTPUT = lex.yy.c
YACC_OUTPUT = parser.tab.c
YACC_HEADER = parser.tab.h
EXECUTABLE = FrontEnd

# Default target
all: $(EXECUTABLE)

# Compile the compiler
$(EXECUTABLE): $(YACC_OUTPUT) $(LEX_OUTPUT) $(SYMBOL_TABLE_SRC)
	$(CC) $(CFLAGS) -o $(EXECUTABLE) $(YACC_OUTPUT) $(LEX_OUTPUT) $(SYMBOL_TABLE_SRC)

# Generate the parser from the yacc file
$(YACC_OUTPUT): $(YACC_FILE)
	$(BISON) -d $(YACC_FILE)

# Generate the lexer from the lex file
$(LEX_OUTPUT): $(LEX_FILE)
	$(FLEX) $(LEX_FILE)

# Clean up generated files
clean:
	rm -f $(LEX_OUTPUT) $(YACC_OUTPUT) $(YACC_HEADER) $(EXECUTABLE)

# PHONY target ensures clean is always run when requested
.PHONY: clean all
