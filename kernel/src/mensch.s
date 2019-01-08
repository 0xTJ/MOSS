.p816

.include "mensch.inc"

CLK                     = 32768
F_CLK                   = 3686400

Alter_Memory            := $00E000
BACKSPACE               := $00E003
                                ;  $00E006
CONTROL_TONES           := $00E009
DO_LOW_POWER_PGM        := $00E00C
DUMPREGS                := $00E00F
DumpS28                 := $00E012
Dump_1_line_to_Output   := $00E015
Dump_1_line_to_Screen   := $00E018
Dump_to_Output          := $00E01B
Dump_to_Printer         := $00E01E
Dump_to_Screen          := $00E021
Dump_to_Screen_ASCII    := $00E024
Dump_It                 := $00E027
FILL_Memory             := $00E02A
GET_3BYTE_ADDR          := $00E02D
GET_ALARM_STATUS        := $00E030
GET_BYTE_FROM_PC        := $00E033
GET_CHR                 := $00E036
GET_HEX                 := $00E039
GET_PUT_CHR             := $00E03C
GET_STR                 := $00E03F
Get_Address             := $00E042
Get_E_Address           := $00E045
Get_S_Address           := $00E048
PUT_CHR                 := $00E04B
PUT_STR                 := $00E04E
READ_ALARM              := $00E051
READ_DATE               := $00E054
READ_TIME               := $00E057
RESET_ALARM             := $00E05A
SBREAK                  := $00E05D
SELECT_COMMON_BAUD_RATE := $00E060
SEND_BYTE_TO_PC         := $00E063
SEND_CR                 := $00E066
SEND_SPACE              := $00E069
SEND_HEX_OUT            := $00E06C
SET_ALARM               := $00E06F
SET_Breakpoint          := $00E072
SET_DATE                := $00E075
SET_TIME                := $00E078
VERSION                 := $00E07B
WR_3_ADDRESS            := $00E07E
XS28IN                  := $00E081
RESET                   := $00E084
ASCBIN                  := $00E087
BIN2DEC                 := $00E08B
BINASC                  := $00E08F
HEXIN                   := $00E093
IFASC                   := $00E097
ISDECIMAL               := $00E09B
ISHEX                   := $00E09F
UPPER_CASE              := $00E0A3
                                ;  $00E0A7

TMP0        := $00005D  ; Used by:  
                                ;   Dump_It
                                ;   WR_3_Address

TMP2        := $000063  ; Used by:  
                                ;   Dump_It
                                ;   GET_3BYTE_ADDRESS
                                ;   Get_Address
                                ;   Get_E_Address
                                ;   Get_S_Address

TEMP        := $000070  ; Used by:  
                                ;   ASCBIN

; TEMP+1    := $000071  ; Used by:  
                                ;   BINASC

; Vectors
UBRK        := $000100  ; USER -- BREAK VECTOR
UNMI        := $000104  ; USER -- NMI VECTOR
UNIRQ       := $000108  ; USER -- IRQ VECTOR
COPIRQ      := $00010C  ; USER -- CO-PROCESSOR IRQ
IABORT      := $000110  ; USER -- ABORT POINTER
PIBIRQ      := $000114  ; PERIPHERAL INTERFACE IRQ
EDGEIRQS    := $000118  ; ALL EDGE IRQS
UNIRQT7     := $00011C  ; USER -- TIMER 7 IRQ
UNIRQT2     := $000120  ; USER -- TIMER 2 IRQ
UNIRQT1     := $000124  ; USER -- TIMER 1 IRQ
UNIRQT0     := $000128  ; USER -- TIMER 0 IRQ
USER_CMD    := $00012C  ; USER -- COMMAND PROCESSOR
URESTART    := $000130  ; USER -- POWER UP RESTART VECTOR
UALRMIRQ    := $000134  ; USER -- ALARM WAKEUPCALL
