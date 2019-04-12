.p816
.smart

.macpack generic
.macpack longbranch

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
.include "unistd.inc"
.include "errcode.inc"
.include "vectors.inc"

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

.import F_CLK: far

.rodata

init_path:
        .asciiz "/init"
root_path:
        .asciiz "/"

.code

.proc setup_systick_timer
        enter

        sep     #$20

        ; Disable T2
        lda     #1 << 2
        trb     TER

        ; Clear pending T2 interrupt
        lda     #1 << 2
        sta     TIFR

        ; Load T2 values
        T2Freq  = 100
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

        leave
        rts
.endproc

.export main
.proc main
        rep     #$30

        ; Load T2 vector
        lda     #sys_tick
        sta     vectors + VectTab::Nat + NatVect::IRQT2

        ; Load COP vector
        lda     #sys_call
        sta     vectors + VectTab::Nat + NatVect::IRQCOP

        cli

        ; Setup system tick timer
        jsr     setup_systick_timer

        cop     $0D
        cmp     #0
        bne     loop
        
        pea     root_path
        jsr     chdir
        rep     #$30
        ply

        pea     init_path
        cop     $0C

loop:
        ; cop     2
        bra     loop
.endproc
