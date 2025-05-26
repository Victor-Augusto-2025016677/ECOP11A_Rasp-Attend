CC = gcc
CFLAGS = -Wall -Wextra -g -std=c99 
# Use -std=c99 ou -std=c11 para garantir compatibilidade com strdup, strtok_r se usados, e declarações de variáveis no meio do bloco.
# No entanto, o código acima tenta evitar coisas muito específicas de C99/C11 para maior portabilidade ANSI C89,
# mas popen é POSIX, não estritamente ANSI C89.

TARGET_DIR = bin
TARGET = $(TARGET_DIR)/monitor_c

SRCS = src/main.c
# OBJS = $(SRCS:.c=.o) # Se você separar em múltiplos .c

all: $(TARGET)

$(TARGET): $(SRCS)
	@mkdir -p $(TARGET_DIR)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

clean:
	rm -f $(TARGET) $(TARGET_DIR)/* src/*.o

run: all
	./$(TARGET)

.PHONY: all clean run