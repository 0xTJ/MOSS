.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "proc.inc"
.include "fcntl.inc"

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

.import F_CLK: far

.code

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

.proc proc1_init
        ; Open stdin 
        pea     O_RDONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Open stdout
        pea     O_WRONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Open stderr
        pea     O_WRONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

loop:   bra     loop
.endproc

.proc setup_system_timer
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

        ; Enable T2
        lda     TER
        ora     #1 << 2
        sta     TER
        
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
        
        ; Show PD7 on LEDS
        stz     PCS7

        ; Setup T2 for system tick timer
        jsr     setup_system_timer

        ; Create process with PID 1, and run
        jsr     create_proc
        pea     proc1_init
        pea     $7fff
        pha
        jsr     setup_proc
        rep     #$30
        plx
        ply
        ply
        lda     #1
        sta     a:Process::running,x
        
loop:
        safe_brk
        bra     loop
.endproc

.rodata

dev_null_path:
        .asciiz "/dev/null"
dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
test0_string:
        .asciiz "test0"
test1_string:
        .asciiz "test1"
