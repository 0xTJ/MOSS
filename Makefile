AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g --create-dep $(<:.s=.d) -DKERNEL
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst) --create-dep $(<:.c=.d)
LDFLAGS = --cpu 65816 -C mensch.cfg -m $(@).map --no-target-lib -vm

TARGET = moss.bin
AS_SRC = $(wildcard *.s)
C_SRC = $(wildcard *.c)
OBJS = $(AS_SRC:.s=.o)
DEPS := $(OBJS:.o=.d)

all: $(TARGET).mot

$(TARGET).mot: $(TARGET)
	bin2mot -O0x6000 -L0xE00 -2 -H $<

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean:
	del *.map *.lst *.o *.d $(TARGET) $(TARGET).mot 2>NUL

-include $(DEPS)
