.p816
.smart

.macpack generic

.include "uart.inc"
.include "functions.inc"
.include "proc.inc"
.include "w65c265s.inc"
.include "isr.inc"
.include "vectors.inc"

.bss

; Useful buffer is actually one less than this.
; Buffer of length 1 will always fail.
rx_buff_length = $20
tx_buff_length = $20

rx_buff:
        .res    rx_buff_length
tx_buff:
        .res    tx_buff_length

; Tail of these buffers is the address of the next item to be added
rx_head:
        .word   0
rx_tail:
        .word   0
tx_head:
        .word   0
tx_tail:
        .word   0

.code

; void UART3_init(void)
.constructor UART3_init, 1
.proc UART3_init
        enter
        sep     #$20

        ; Setup Timer 3

        ; Disable T3
        lda     #1 << 3
        trb     TER

        ; Disable T3 interrupt
        lda     #1 << 3
        trb     TIER

        ; Clear pending T3 interrupt
        lda     #1 << 3
        sta     TIFR

        ; Load T3 latch and counter values
        lda     #.lobyte($0017)
        sta     T3LL
        lda     #.hibyte($0017)
        sta     T3CH

        ; Enable T3
        lda     #1 << 3
        tsb     TER

        ; Setup UART 3

        ; Set UART3 timer to T3
        lda     #1 << 7
        trb     TCR

        rep     #$20

        ; Setup interrupt vectors
        lda     #UART3_recv
        sta     vectors + VectTab::Nat + NatVect::IRQAR3
        lda     #UART3_trans
        sta     vectors + VectTab::Nat + NatVect::IRQAT3

        sep     #$20

        ; Enable UART3 TX and RX interrupts
        lda     #(1 << 7) | (1 << 6)
        tsb     UIER

        ; Set 8-bit, RX Enable
        lda     #$24
        sta     ACSR3

        ; Clear input buffer
        lda     ARTD3

        leave
        rts
.endproc

.interruptor UART3_recv
.proc UART3_recv
        enter_isr

        sep     #$20
        rep     #$10

        ; Clear interrupt
        lda     #$40
        sta     UIFR

        ; Read serial byte
        lda     ARTD3

        ; If received char is ESC, reset system
        cmp     #$1B
        bne     no_reset
        hard_reset
no_reset:

        ; Load tail of RX buffer
        ldx     rx_tail

        ; Transfer tail to Y
        txy

        ; Increment tail position in RX buffer
        iny
        cpy     #rx_buff_length
        blt     skip_wrap_buff
        ldy     #0
skip_wrap_buff:

        ; Compare incremented tail to head
        ; If equal, buffer is full, exit without saving new tail
        ; If buffer is full, new byte is discarded
        cpy     rx_head
        beq     done

        ; Store byte to buffer at tail
        sta     a:rx_buff,x

        ; Update RX buffer tail
        sty     rx_tail

done:
        leave_isr
        rti
.endproc

.interruptor UART3_trans
.proc UART3_trans
        enter_isr

        sep     #$20
        rep     #$10

        ; Clear UART3T interrupt
        lda     #$80
        sta     UIFR

        ; Load head of TX buffer
        ldx     tx_head

        ; Compare head to tail and exit if empty buffer
        cpx     tx_tail
        beq     empty_buffer

        ; Enable transmitter
        lda     #(1 << 0)
        tsb     ACSR3

        ; Set empty data register interrupt
        lda     #(1 << 1)
        trb     ACSR3

        ; Load byte to send from head
        lda     a:tx_buff,x

        ; Write byte to serial data
        sta     ARTD3

        ; Increment head to next position
        inx
        cpx     #tx_buff_length
        blt     skip_wrap_buff
        ldx     #0
skip_wrap_buff:

        ; Update TX buffer head
        stx     tx_head

done:
        ; Return
        leave_isr
        rti

empty_buffer:
        sep     #$20

        ; Branch to turn_off if already in shutdown mode
        lda     ACSR3
        and     #(1 << 1)
        bnz     turn_off

        ; Set shutdown mode
        lda     #(1 << 1)
        tsb     ACSR3

        bra     done

turn_off:
        ; Set TX3 pin high
        lda     #(1 << 7)
        tsb     PD6

        ; Disable TX on UART3
        lda     #(1 << 0)
        trb     ACSR3

        bra     done
.endproc

; char UART3_getchar(void)
.proc UART3_getchar
        enter
        sep     #$20

wait_loop:
        ; Load head of RX buffer
        ldx     rx_head

        ; Compare head to tail and loop if empty buffer
        cpx     rx_tail
        beq     wait_loop

        ; Load byte read
        lda     a:rx_buff,x

        ; Increment head to next position
        inx
        cpx     #rx_buff_length
        blt     skip_wrap_buff
        ldx     #0
skip_wrap_buff:
        stx     rx_head

        ; Extend to 16-bit
        rep     #$20
        and     #$00FF

        leave
        rts
.endproc

; void UART3_putchar(char val)
.proc UART3_putchar
        enter
        sep     #$20

wait_loop:
        ; Load a byte from input buffer
        lda     z:arg 0 ; val

        ; Load tail of TX buffer
        ldx     tx_tail

        ; Store byte to buffer at tail
        sta     a:tx_buff,x

        ; Increment tail position in TX buffer
        inx
        cpx     #tx_buff_length
        blt     skip_wrap_buff
        ldx     #0
skip_wrap_buff:

        ; Compare new tail to head and loop if full buffer
        ; Keep writing to the last byte in buffer until space is made
        ; to continue
        cpx     tx_head
        beq     wait_loop

        ; Update TX buffer tail
        stx     tx_tail

        ; Bootstrap transmission by enabling transmitter
        lda     #(1 << 0)
        tsb     ACSR3

        leave
        rts
.endproc
