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
.include "stdio.inc"
.include "errcode.inc"

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

.import F_CLK: far

.import user

.code

.global test_str
test_str:
.asciiz "test"

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

        ; Start running process 1
        pea     0
        pea     0
        pea     $7fff
        pea     user
        jsr     clone
        rep     #$30
        ply
        ply
        ply
        ply

loop:
        bra     loop
.endproc
