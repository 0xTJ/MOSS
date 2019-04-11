AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g --create-dep $(<:.s=.d) --asm-include-dir include --asm-include-dir ../common/include
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst) --create-dep $(<:.c=.d)
LDFLAGS = --cpu 65816 -C user.cfg -m $(@:.o65=.map) --no-target-lib -vm

TARGET = sh.o65
LIB = ../lib/clib.lib
AS_SRC := $(wildcard src/*.s) $(wildcard src/**/*.s)
OBJS := $(AS_SRC:.s=.o)
DEPS := $(OBJS:.o=.d)
DEL := $(patsubst %,"%",$(subst /,\,$(wildcard src/*.o) $(wildcard src/**/*.o) $(wildcard src/*.d) $(wildcard src/**/*.d) $(wildcard src/*.lst) $(wildcard src/**/*.lst) $(wildcard ../common/lib/*.o) $(wildcard ../common/lib/*.d) $(wildcard ../common/lib/*.lst))) $(TARGET)

all: $(TARGET)

$(TARGET): $(OBJS) $(LIB)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean:
	del $(DEL) 2>NUL

-include $(DEPS)
