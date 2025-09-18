CFLAGS  := -std=c99 -Wall -O2 -D_REENTRANT
LIBS    := -lpthread -lm -lcrypto -lssl

TARGET  := $(shell uname -s | tr '[A-Z]' '[a-z]' 2>/dev/null || echo unknown)

ifeq ($(TARGET), linux)
    CFLAGS  += -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE
    LIBS    += -ldl
    LDFLAGS += -Wl,-E
endif

# ----------------------------
# LuaJIT 路径
# ----------------------------
LUAJIT_INC := /usr/include/luajit-2.1
LUAJIT_LIB := /usr/lib

CFLAGS  += -I$(LUAJIT_INC)
CFLAGS += -I/usr/include/luajit-2.1 -I./src
LDFLAGS += -L$(LUAJIT_LIB)
LIBS    := -lluajit-5.1 $(LIBS)

# ----------------------------
# 源码和目标
# ----------------------------
SRC  := wrk.c net.c ssl.c aprintf.c stats.c script.c units.c \
        ae.c zmalloc.c http_parser.c tinymt64.c hdr_histogram.c
BIN  := wrk
ODIR := obj
OBJ  := $(patsubst %.c,$(ODIR)/%.o,$(SRC)) $(ODIR)/bytecode.o

# ----------------------------
# Make 规则
# ----------------------------
all: $(BIN)

clean:
	$(RM) -rf $(BIN) obj/*

$(BIN): $(OBJ)
	@echo LINK $(BIN)
	@$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(OBJ): config.h Makefile | $(ODIR)

$(ODIR):
	@mkdir -p $@

# Lua 脚本 bytecode
$(ODIR)/bytecode.o: src/wrk.lua
	@echo LUAJIT $<
	@luajit -b $(CURDIR)/$< $(CURDIR)/$@

# 编译 C 源码
$(ODIR)/%.o : %.c
	@echo CC $<
	@$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all clean
.SUFFIXES:
.SUFFIXES: .c .o .lua

vpath %.c   src
vpath %.h   src
vpath %.lua scripts
