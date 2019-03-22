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

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

.import F_CLK: far

O65_SIZE = 3000

.bss
tmp_str:
        .res 10

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

; int runO65(uint8_t *o65)
.proc runO65
        enter   10

        ; 0: void *text_base
        ; 2: void *data_base
        ; 4: void *bss_base
        ; 6: void *zero_base
        ; 8: void *stack_init

        ; Allocate text space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::tlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 0 ; text_base

        ; Allocate data space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::dlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 2 ; data_base

        ; Allocate bss space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::blen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 4 ; bss_base

        ; Allocate zero space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::zlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 6 ; zero_base

        ; Allocate stack space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::stack,x
        bnz     not_zero_stack
        lda     #$200
not_zero_stack:
        add     #$80
        pha
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        add     1,s
        ply
        sta     z:var 8 ; stack_init

        ; Call o65 loader
        lda     z:var 6 ; zero_base
        pha
        lda     z:var 4 ; bss_base
        pha
        lda     z:var 2 ; data_base
        pha
        lda     z:var 0 ; text_base
        pha
        lda     z:arg 0 ; o65
        pha
        jsr     o65_load
        rep     #$30
        ply
        ply
        ply
        ply
        ply

        ; Create new process with clone
        pea     0
        pea     0
        lda     z:var 8 ; stack_base
        pha
        lda     z:var 0 ; text_base
        pha
        jsr     clone
        rep     #$30
        ply
        ply
        ply
        ply

done:
        leave
        rts

failed:
        lda     #0
        bra     done
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

        ; Setup stdin
        pea     O_RDONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Setup stdout
        pea     O_WRONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Setup stderr
        pea     O_WRONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        cop     $0D

        pea     dev_prgload_path
        cop     $0C

loop:
        bra     loop
.endproc

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
dev_prgload_path:
        .asciiz "/dev/prgload"
