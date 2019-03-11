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

O65_SIZE = 2000

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

; int runO65(uint8_t *o65)
.proc runO65
        enter
        rep     #$30

        ; Allocate space for stack variables
        tsc
        sub     #10
        tcs

        ; 1: void *text_base
        ; 3: void *data_base
        ; 5: void *bss_base
        ; 7: void *zero_base
        ; 9: void *stack_init

        ; Allocate text space and store pointer to stack
        ldx     z:3
        lda     a:O65Header::tlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     1,s ; text_base

        ; Allocate data space and store pointer to stack
        ldx     z:3
        lda     a:O65Header::dlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     3,s ; data_base

        ; Allocate bss space and store pointer to stack
        ldx     z:3
        lda     a:O65Header::blen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     5,s ; bss_base

        ; Allocate zero space and store pointer to stack
        ldx     z:3
        lda     a:O65Header::zlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     7,s ; zero_base

        ; Allocate stack space and store pointer to stack
        ldx     z:3
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
        sta     9,s ; stack_init

        ; Call o65 loader
        lda     7,s ; zero_base
        pha
        lda     7,s ; bss_base
        pha
        lda     7,s ; data_base
        pha
        lda     7,s ; text_base
        pha
        lda     z:3 ; o65
        pha
        jsr     o65_load
        rep     #$30
        ply
        ply
        ply
        ply
        ply

        ; Load parameters for clone
        lda     9,s ; stack_base
        tax
        lda     1,s ; text_base

        ; Create new process with clone
        pea     0
        pea     0
        phx
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

        ; Open prgload device
        pea     O_RDONLY
        pea     dev_prgload_path
        cop     3
        rep     #$30
        ply
        ply

        ; Loop forever on failure
        cmp     #0
        blt     loop

        ; Push prgload fd for later
        pha

        ; Allocate temporary load buffer
        pea     O65_SIZE
        jsr     malloc
        rep     #$30
        ply

        ; Loop forever on failure
        cmp     #0
        beq     loop

        ; Load prgload fd to X and push allocated buffer twice to run and free
        plx
        pha
        pha
        phx

        ; Read program to buffer
        pea     O65_SIZE
        pha
        phx
        jsr     read
        rep     #$30
        ply
        ply
        ply

        ; Loop forever on failure
        cmp     #.sizeof(O65Header)
        blt     loop

        ; Close prgload fd
        jsr     close
        rep     #$30
        ply

        ; Run program
        jsr     runO65
        rep     #$30
        ply

        ; Free load buffer
        jsr     free
        rep     #$30
        ply

loop:
        bra     loop
.endproc

.rodata

dev_prgload_path:
        .asciiz "/dev/prgload"
