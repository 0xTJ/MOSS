AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g --create-dep $(<:.s=.d) --asm-define KERNEL --asm-include-dir include --asm-include-dir ../common/include
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst) --create-dep $(<:.c=.d)
LDFLAGS = --cpu 65816 -C mensch.cfg -m $(@).map --no-target-lib -vm

TARGET = moss.bin
AS_SRC := $(wildcard src/*.s) $(wildcard src/*/*.s) $(wildcard ../common/lib/*.s) $(wildcard ../common/lib/*/*.s)
OBJS := $(AS_SRC:.s=.o)
DEPS := $(OBJS:.o=.d)
DEL := $(patsubst %,"%",$(subst /,\,$(wildcard src/*.o) $(wildcard src/*/*.o) $(wildcard src/*.d) $(wildcard src/*\*.d) $(wildcard src/*.lst) $(wildcard src/*\*.lst)))

all: $(TARGET).mot

$(TARGET).mot: $(TARGET) user.bin
	bin2mot -O0x006000 -L0x001200 -2 -H $<
	bin2mot -O0x008000 -L0x000500 -2 -H -A user.bin $<.mot

$(TARGET) user.bin: $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean:
	del $(DEL) 2>NUL

-include $(DEPS)
