.p816

.global CLK
.global F_CLK: far

.global Alter_Memory
.global BACKSPACE
.global CONTROL_TONES
.global DO_LOW_POWER_PGM
.global DUMPREGS
.global DumpS28
.global Dump_1_line_to_Output
.global Dump_1_line_to_Screen
.global Dump_to_Output
.global Dump_to_Printer
.global Dump_to_Screen
.global Dump_to_Screen_ASCII
.global Dump_It
.global FILL_Memory
.global GET_3BYTE_ADDR
.global GET_ALARM_STATUS
.global GET_BYTE_FROM_PC
.global GET_CHR
.global GET_HEX
.global GET_PUT_CHR
.global GET_STR
.global Get_Address
.global Get_E_Address
.global Get_S_Address
.global PUT_CHR
.global PUT_STR
.global READ_ALARM
.global READ_DATE
.global READ_TIME
.global RESET_ALARM
.global SBREAK
.global SELECT_COMMON_BAUD_RATE
.global SEND_BYTE_TO_PC
.global SEND_CR
.global SEND_SPACE
.global SEND_HEX_OUT
.global SET_ALARM
.global SET_Breakpoint
.global SET_DATE
.global SET_TIME
.global VERSION
.global WR_3_ADDRESS
.global XS28IN
.global RESET
.global ASCBIN
.global BIN2DEC
.global BINASC
.global HEXIN
.global IFASC
.global ISDECIMAL
.global ISHEX
.global UPPER_CASE

.global TMP0
                                ;   Dump_It
                                ;   WR_3_Address

.global TMP2
                                ;   Dump_It
                                ;   GET_3BYTE_ADDRESS
                                ;   Get_Address
                                ;   Get_E_Address
                                ;   Get_S_Address

.global TEMP
                                ;   ASCBIN

; .global TEMP+1
                                ;   BINASC

; Vectors
.global UBRK
.global UNMI
.global UNIRQ
.global COPIRQ
.global IABORT
.global PIBIRQ
.global EDGEIRQS
.global UNIRQT7
.global UNIRQT2
.global UNIRQT1
.global UNIRQT0
.global USER_CMD
.global URESTART
.global UALRMIRQ
