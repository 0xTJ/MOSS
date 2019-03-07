.p816
.smart

.macpack generic

.include "functions.inc"
.include "proc.inc"
.include "fcntl.inc"
.include "sched.inc"
.include "mensch.inc"
.include "w65c265s.inc"
.include "syscall.inc"
.include "o65.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "errcode.inc"

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

.import F_CLK: far

; .import user

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"

.code

.proc setup_systick_timer
        sep     #$20

        ; Disable T2
        lda     #1 << 2
        trb     TER

        ; Clear pending T2 interrupt
        lda     #1 << 2
        sta     TIFR

        ; Load T2 values
        T2Freq  = 10
        lda     #.lobyte((F_CLK / 16) / T2Freq)
        sta     T2CL
        lda     #.hibyte((F_CLK / 16) / T2Freq)
        sta     T2CH

        ; Enable T2 interrupt
        lda     #1 << 2
        tsb     TIER

        ; Enable T2
        lda     #1 << 2
        tsb     TER

        rts
.endproc

.export main
.proc main
        rep     #$30

        ; Load T2 vector
        lda     #sys_tick
        sta     NAT_IRQT2

        ; Load COP vector
        lda     #sys_call
        sta     NAT_IRQCOP

        cli

        ; Setup system tick timer
        jsr     setup_systick_timer

        pea     $2000
        pea     $2200
        pea     $3000
        pea     $3800
        pea     user_o65
        jsr     o65_load
        rep     #$30
        ply
        ply
        ply
        ply

        ; Start running process 1
        pea     0
        pea     0
        pea     $AFFF
        pea     $3800
        jsr     clone
        rep     #$30
        ply
        ply
        ply
        ply

loop:
        bra     loop
.endproc

.rodata

.export user_o65
user_o65:
        .incbin "user.o65"
