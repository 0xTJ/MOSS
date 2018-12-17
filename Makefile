AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g --create-dep $(<:.s=.d) --asm-define KERNEL --asm-include-dir .
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst) --create-dep $(<:.c=.d)
LDFLAGS = --cpu 65816 -C mensch.cfg -m $(@).map --no-target-lib -vm

TARGET = moss.bin
AS_SRC := $(wildcard *.s) $(wildcard */*.s)
C_SRC := $(wildcard *.c)
OBJS := $(AS_SRC:.s=.o)
DEPS := $(OBJS:.o=.d)
DEL := $(patsubst %,"%",$(subst /,\,$(wildcard *.bin) $(wildcard *.mot) $(wildcard *.o) $(wildcard */*.o) $(wildcard *.d) $(wildcard *\*.d) $(wildcard *.lst) $(wildcard *\*.lst) $(wildcard *.map) $(wildcard *\*.map)))

all: $(TARGET).mot

$(TARGET).mot: $(TARGET)
	bin2mot -O0x6000 -L0xE00 -2 -H $<

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean:
	del $(DEL) 2>NUL

-include $(DEPS)
