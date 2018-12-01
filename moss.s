.p816
.smart

.macpack generic

.autoimport

; Hardware interrupt routines must accept being started in emulation mode.
; Software interrupts must accept being run in emulation mode, but are only required to perform their action when run in native mode.

.code

; void install_user_vector(void * far user_vector_loc, void (*vector_isr)(void) far) far
.proc install_user_vector_jsr_abs
        rep     #$30
        
        lda     #$4C ; JMP ABS
        ldy     #0
        sta     (3,s),y
        
        lda     5,s
        ldy     #1
        sta     (3,s),y
        
        rts
.endproc

.export main
.proc main
        rep     #$30

        ; Load vectors
        pea     sys_tick
        pea     UNIRQT2
        jsr     install_user_vector_jsr_abs
        ply
        ply
        pea     sys_call
        pea     COPIRQ
        jsr     install_user_vector_jsr_abs
        ply
        ply
        
        ; Disable T2
        ; lda     TCR
        ; and     #.lobyte(~(1 << 2))
        ; sta     TCR
        ; Clear pending T2 interrupt
        ; lda     #1 << 2
        ; sta     TIFR
        ; Enable T2 interrupt
        ; lda     TCR
        ; ora     #1 << 2
        ; sta     TCR
        ; Load T2 values
        ; lda     #.lobyte(4000)
        ; sta     T2CL
        ; lda     #.hibyte(4000)
        ; sta     T2CH
        
        ; Enable T2
        ; lda     TCR
        ; ora     #1 << 2
        ; sta     TCR
        
loop:   jmp     loop
.endproc
