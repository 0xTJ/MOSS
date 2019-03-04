AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g --create-dep $(<:.s=.d) --asm-include-dir include --asm-include-dir ../common/include
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst) --create-dep $(<:.c=.d)
LDFLAGS = --cpu 65816 -C user.cfg -m $(@).map --no-target-lib -vm

TARGET = user.bin
AS_SRC := $(wildcard src/*.s) $(wildcard src/*/*.s) $(wildcard lib/*.s) $(wildcard lib/*/*.s) $(wildcard ../common/lib/*.s) $(wildcard ../common/lib/*/*.s)
OBJS := $(AS_SRC:.s=.o)
DEPS := $(OBJS:.o=.d)
DEL := $(patsubst %,"%",$(subst /,\,$(wildcard src/*.o) $(wildcard src/*/*.o) $(wildcard src/*.d) $(wildcard src/*\*.d) $(wildcard src/*.lst) $(wildcard src/*\*.lst)))

all: $(TARGET).mot

$(TARGET).mot: $(TARGET)
	bin2mot -O0x8000 -L0x1000 -2 -H $<

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean:
	del $(DEL) 2>NUL

-include $(DEPS)
