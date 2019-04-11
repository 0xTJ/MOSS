AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g --create-dep $(<:.s=.d) --asm-include-dir include --asm-include-dir ../common/include
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst) --create-dep $(<:.c=.d)

TARGET = clib.lib
COMMON_LIB = ../common/common.lib
AS_SRC := $(wildcard src/*.s) $(wildcard src/*/*.s) $(wildcard src/*/*/*.s)
OBJS := $(AS_SRC:.s=.o)
DEPS := $(OBJS:.o=.d)
DEL := $(patsubst %,"%",$(subst /,\,$(wildcard src/*.o) $(wildcard src/*/*.o) $(wildcard src/*.d) $(wildcard src/*/*.d) $(wildcard src/*.lst) $(wildcard src/*/*.lst))) $(TARGET)

all: $(TARGET)

$(TARGET): $(OBJS)
	copy $(subst /,\,$(COMMON_LIB) $(TARGET))
	ar65 r $@ $^

.PHONY: clean
clean:
	del $(DEL) 2>NUL

-include $(DEPS)
