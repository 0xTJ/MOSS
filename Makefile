AS = cl65
ASFLAGS = --cpu 65816 -c -l $(<:.s=.lst) -g
CC = cl65
CFLAGS = --cpu 65816 -l $(<:.c=.lst)
LDFLAGS = --cpu 65816 -C mensch.cfg -m $(@).map --no-target-lib -vm

TARGET = moss.bin
AS_SRC = $(wildcard *.s)
C_SRC = $(wildcard *.c)
OBJS = $(AS_SRC:.s=.o)

all: $(TARGET).mot

$(TARGET).mot: $(TARGET)
	bin2mot -O0x6000 -L0x650 -2 -H $<

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean:
	del *.map *.lst *.o $(TARGET) 2>NUL
