.p816

.export Alter_Memory            := $00E000
.export BACKSPACE               := $00E003
                                ;  $00E006
.export CONTROL_TONES           := $00E009
.export DO_LOW_POWER_PGM        := $00E00C
.export DUMPREGS                := $00E00F
.export DumpS28                 := $00E012
.export Dump_1_line_to_Output   := $00E015
.export Dump_1_line_to_Screen   := $00E018
.export Dump_to_Output          := $00E01B
.export Dump_to_Printer         := $00E01E
.export Dump_to_Screen          := $00E021
.export Dump_to_Screen_ASCII    := $00E024
.export Dump_It                 := $00E027
.export FILL_Memory             := $00E02A
.export GET_3BYTE_ADDR          := $00E02D
.export GET_ALARM_STATUS        := $00E030
.export GET_BYTE_FROM_PC        := $00E033
.export GET_CHR                 := $00E036
.export GET_HEX                 := $00E039
.export GET_PUT_CHR             := $00E03C
.export GET_STR                 := $00E03F
.export Get_Address             := $00E042
.export Get_E_Address           := $00E045
.export Get_S_Address           := $00E048
.export PUT_CHR                 := $00E04B
.export PUT_STR                 := $00E04E
.export READ_ALARM              := $00E051
.export READ_DATE               := $00E054
.export READ_TIME               := $00E057
.export RESET_ALARM             := $00E05A
.export SBREAK                  := $00E05D
.export SELECT_COMMON_BAUD_RATE := $00E060
.export SEND_BYTE_TO_PC         := $00E063
.export SEND_CR                 := $00E066
.export SEND_SPACE              := $00E069
.export SEND_HEX_OUT            := $00E06C
.export SET_ALARM               := $00E06F
.export SET_Breakpoint          := $00E072
.export SET_DATE                := $00E075
.export SET_TIME                := $00E078
.export VERSION                 := $00E07B
.export WR_3_ADDRESS            := $00E07E
.export XS28IN                  := $00E081
.export RESET                   := $00E084
.export ASCBIN                  := $00E087
.export BIN2DEC                 := $00E08B
.export BINASC                  := $00E08F
.export HEXIN                   := $00E093
.export IFASC                   := $00E097
.export ISDECIMAL               := $00E09B
.export ISHEX                   := $00E09F
.export UPPER_CASE              := $00E0A3
                                ;  $00E0A7

.export TMP0        := $00005D  ; Used by:  
                                ;   Dump_It
                                ;   WR_3_Address

.export TMP2        := $000063  ; Used by:  
                                ;   Dump_It
                                ;   GET_3BYTE_ADDRESS
                                ;   Get_Address
                                ;   Get_E_Address
                                ;   Get_S_Address

.export TEMP        := $000070  ; Used by:  
                                ;   ASCBIN

; .export TEMP+1    := $000071  ; Used by:  
                                ;   BINASC

; Vectors
.export UBRK        := $000100  ; USER -- BREAK VECTOR
.export UNMI        := $000104  ; USER -- NMI VECTOR
.export UNIRQ       := $000108  ; USER -- IRQ VECTOR
.export COPIRQ      := $00010C  ; USER -- CO-PROCESSOR IRQ
.export IABORT      := $000110  ; USER -- ABORT POINTER
.export PIBIRQ      := $000114  ; PERIPHERAL INTERFACE IRQ
.export EDGEIRQS    := $000118  ; ALL EDGE IRQS
.export UNIRQT7     := $00011C  ; USER -- TIMER 7 IRQ
.export UNIRQT2     := $000120  ; USER -- TIMER 2 IRQ
.export UNIRQT1     := $000124  ; USER -- TIMER 1 IRQ
.export UNIRQT0     := $000128  ; USER -- TIMER 0 IRQ
.export USER_CMD    := $00012C  ; USER -- COMMAND PROCESSOR
.export URESTART    := $000130  ; USER -- POWER UP RESTART VECTOR
.export UALRMIRQ    := $000134  ; USER -- ALARM WAKEUPCALL
