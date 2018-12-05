.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "proc.inc"

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

; void install_user_vector(void * far user_vector_loc, void (*vector_isr)(void) far) far
.proc install_user_vector_jsr_abs
        rep     #$30

        lda     #$5C ; JMP far
        ldy     #0
        sta     (3,s),y

        lda     5,s
        ldy     #1
        sta     (3,s),y

        rts
.endproc

.proc proc1
loop:
        jsr     delay
        pea     test0_string
        jsr     puts
        rep     #$30
        ply
        bra     loop
.endproc

.proc proc2
loop:
        jsr     delay
        pea     test1_string
        jsr     puts
        rep     #$30
        ply
        bra     loop
.endproc

.proc delay
        rep     #$30
        lda     #$FFFF
loop:
        dec
        bnz     loop

        rts
.endproc

.export main
.proc main
        rep     #$30

        ; Load T2 vector
        pea     sys_tick
        pea     UNIRQT2
        jsr     install_user_vector_jsr_abs
        rep     #$30
        ply
        ply

        ; Load COP vector
        pea     sys_call
        pea     COPIRQ
        jsr     install_user_vector_jsr_abs
        rep     #$30
        ply
        ply

        ; Disable T2
        sep     #$20
        lda     TER
        and     #.lobyte(~(1 << 2))
        sta     TER
        ; Clear pending T2 interrupt
        lda     #1 << 2
        sta     TIFR
        ; Enable T2 interrupt
        lda     TIER
        ora     #1 << 2
        sta     TIER
        ; Load T2 values
        T2Freq  = 10
        lda     #.lobyte((F_CLK / 16) / T2Freq)
        sta     T2CL
        lda     #.hibyte((F_CLK / 16) / T2Freq)
        sta     T2CH

        ; Show P7 on LEDS
        stz     PCS7

        ; Enable T2
        lda     TER
        ora     #1 << 2
        sta     TER

        jsr     create_proc

        pea     proc1
        pea     $7fff
        pha
        jsr     setup_proc
        rep     #$30
        plx
        ply
        ply

        lda     #1
        sta     a:Process::running,x

        jsr     create_proc

        pea     proc2
        pea     $77ff
        pha
        jsr     setup_proc
        rep     #$30
        plx
        ply
        ply

        jsr     dev_null_init
        
        lda     #1
        sta     a:Process::running,x

loop:   
        safe_brk
        bra     loop
.endproc

.rodata

test0_string:
        .asciiz "test0"
test1_string:
        .asciiz "test1"
