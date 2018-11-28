.p816

.segment "IO"

; I/O Registers
.export PD0     := $00DF00
.export PD1     := $00DF01
.export PD2     := $00DF02
.export PD3     := $00DF03
.export PDD0    := $00DF04
.export PDD1    := $00DF05
.export PDD2    := $00DF06
.export PDD3    := $00DF07
.export CS0     := $00DF00
.export PD4     := $00DF20
.export PD5     := $00DF21
.export PD6     := $00DF22
.export PD7     := $00DF23
.export PDD4    := $00DF24
.export PDD5    := $00DF25
.export PDD6    := $00DF26
.export PDD7    := $00DF27
.export CS1     := $00DFC0

; Control and Status Registers
.export BCR     := $00DF40
.export SSCR    := $00DF41
.export TCR     := $00DF42
.export TER     := $00DF43
.export TIFR    := $00DF44
.export EIFR    := $00DF45
.export TIER    := $00DF46
.export EIER    := $00DF47
.export UIFR    := $00DF48
.export UIER    := $00DF49

; Timer Registers
.export T0LL    := $00DF50
.export T0LH    := $00DF51
.export T1LL    := $00DF52
.export T1LH    := $00DF53
.export T2LL    := $00DF54
.export T2LH    := $00DF55
.export T3LL    := $00DF56
.export T3LH    := $00DF57
.export T4LL    := $00DF58
.export T4LH    := $00DF59
.export T5LL    := $00DF5A
.export T5LH    := $00DF5B
.export T6LL    := $00DF5C
.export T6LH    := $00DF5D
.export T7LL    := $00DF5E
.export T7LH    := $00DF5F
.export T0CL    := $00DF60
.export T0CH    := $00DF61
.export T1CL    := $00DF62
.export T1CH    := $00DF63
.export T2CL    := $00DF64
.export T2CH    := $00DF65
.export T3CL    := $00DF66
.export T3CH    := $00DF67
.export T4CL    := $00DF68
.export T4CH    := $00DF69
.export T5CL    := $00DF6A
.export T5CH    := $00DF6B
.export T6CL    := $00DF6C
.export T6CH    := $00DF6D
.export T7CL    := $00DF6E
.export T7CH    := $00DF6F

; Communication Registers
.export ACSRO       := $00DF70
.export ARTD0       := $00DF71
.export ACSR1       := $00DF72
.export ARTD1       := $00DF73
.export ACSR2       := $00DF74
.export ARTD2       := $00DF75
.export ACSR3       := $00DF76
.export ARTD3       := $00DF77
.export PIBFR       := $00DF78
.export PIBER       := $00DF79
.export PIR2        := $00DF7A
.export PIR3        := $00DF7B
.export PIR4        := $00DF7C
.export PIR5        := $00DF7D
.export PIR6        := $00DF7E
.export PIR7        := $00DF7F
.export RAM         := $00DF80

; Native Mode Vector Table
.export NAT_IRQT0   := $00FF80
.export NAT_IRQT1   := $00FF82
.export NAT_IRQT2   := $00FF84
.export NAT_IRQT3   := $00FF86
.export NAT_IRQT4   := $00FF88
.export NAT_IRQT5   := $00FF8A
.export NAT_IRQT6   := $00FF8C
.export NAT_IRQT7   := $00FF8E
.export NAT_IRPE56  := $00FF90
.export NAT_IRNE57  := $00FF92
.export NAT_IRPE60  := $00FF94
.export NAT_IRPE62  := $00FF96
.export NAT_IRNE64  := $00FF98
.export NAT_IRNE66  := $00FF9A
.export NAT_IRQPIB  := $00FF9C
.export NAT_IRQ     := $00FF9E
.export NAT_IRQAR0  := $00FFA0
.export NAT_IRQAT0  := $00FFA2
.export NAT_IRQAR1  := $00FFA4
.export NAT_IRQAT1  := $00FFA6
.export NAT_IRQAR2  := $00FFA8
.export NAT_IRQAT2  := $00FFAA
.export NAT_IRQAR3  := $00FFAC
.export NAT_IRQAT3  := $00FFAE
.export NAT_IRQRVD0 := $00FFB0
.export NAT_IRQRVD1 := $00FFB2
.export NAT_IRQCOP  := $00FFB4
.export NAT_IRQBRK  := $00FFB6
.export NAT_IABORT  := $00FFB8
.export NAT_IRQNMI  := $00FFBA
.export NAT_IRQRVD2 := $00FFBC
.export NAT_IRQRVD3 := $00FFBE

; Emulation Mode Vector Table
.export EMU_IRQT0   := $00FFC0
.export EMU_IRQT1   := $00FFC2
.export EMU_IRQT2   := $00FFC4
.export EMU_IRQT3   := $00FFC6
.export EMU_IRQT4   := $00FFC8
.export EMU_IRQT5   := $00FFCA
.export EMU_IRQT6   := $00FFCC
.export EMU_IRQT7   := $00FFCE
.export EMU_IRPE56  := $00FFD0
.export EMU_IRNE57  := $00FFD2
.export EMU_IRPE60  := $00FFD4
.export EMU_IRPE62  := $00FFD6
.export EMU_IRNE64  := $00FFD8
.export EMU_IRNE66  := $00FFDA
.export EMU_IRQPIB  := $00FFDC
.export EMU_IRQ     := $00FFDE
.export EMU_IRQAR0  := $00FFE0
.export EMU_IRQAT0  := $00FFE2
.export EMU_IRQAR1  := $00FFE4
.export EMU_IRQAT1  := $00FFE6
.export EMU_IRQAR2  := $00FFE8
.export EMU_IRQAT2  := $00FFEA
.export EMU_IRQAR3  := $00FFEC
.export EMU_IRQAT3  := $00FFEE
.export EMU_IRQRVD0 := $00FFF0
.export EMU_IRQRVD1 := $00FFF2
.export EMU_IRQCOP  := $00FFF4
.export EMU_IRQRVD2 := $00FFF6
.export EMU_IABORT  := $00FFF8
.export EMU_IRQNMI  := $00FFFA
.export EMU_IRQRES  := $00FFFC
.export EMU_IRQBRK  := $00FFFE
