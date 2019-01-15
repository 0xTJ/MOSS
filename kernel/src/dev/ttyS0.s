.p816
.smart

.macpack generic

.include "functions.inc"
.include "proc.inc"
.include "dev.inc"
.include "mensch.inc"
.include "w65c265s.inc"
.include "isr.inc"

.bss

ttyS0_driver:
        .tag    CharDriver

.rodata

ttyS0_name:
        .asciiz "ttyS0"

.bss

; Useful buffer is actually one less than this.
; Buffer of length 1 will always fail.
rx_buff_length = $100
tx_buff_length = $100

rx_buff:
        .res    rx_buff_length
tx_buff:
        .res    tx_buff_length
        
empty_tx_buff:
        .res    1

.data

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

.interruptor UART3_recv
.proc UART3_recv
        enter_isr

        sep     #$20
        rep     #$10

        ; Read serial data register
        lda     ARTD3

        ; Load tail of RX buffer
        ldx     rx_tail

        ; Increment tail position in RX buffer
        inx
        cpx     #rx_buff_length
        blt     skip_wrap_buff
        ldx     #0
skip_wrap_buff:

        ; Store byte to buffer at tail
        sta     a:rx_buff,x

        ; Compare incremented tail to head
        ; If equal, buffer is full, exit without saving new tail
        ; If buffer is full, new byte is discarded
        cpx     rx_head
        beq     done

        ; Update RX buffer tail
        stx     rx_tail

done:
        exit_isr
        rti
.endproc

.interruptor UART3_trans
.proc UART3_trans
        enter_isr
        
        sep     #$20
        rep     #$10

        ; Load head of TX buffer
        ldx     tx_head

        ; Compare head to tail and exit if empty buffer
        cpx     tx_tail
        beq     empty_buffer
        
        stz     empty_tx_buff

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

        ; Update TX buffer head unconditionally
        stx     tx_head

done:
        exit_isr
        rti
        
empty_buffer:
        ; Get here if we tried to transmit on an empty buffer.
        ; After this, we will need to manually transmit the next byte.
        lda     #1
        sta     empty_tx_buff
        bra     done
.endproc

.constructor dev_ttyS0_init
.proc dev_ttyS0_init
        rep     #$30

        ldx     #ttyS0_driver

        lda     #dev_ttyS0_read
        sta     a:CharDriver::read,x

        lda     #dev_ttyS0_write
        sta     a:CharDriver::write,x

        pea     DEV_TYPE_CHAR
        pea     ttyS0_name
        pea     ttyS0_driver
        jsr     register_driver
        rep     #$30
        ply
        ply
        ply
        
        lda     #UART3_recv
        sta     NAT_IRQAR3
        lda     #UART3_trans
        sta     NAT_IRQAT3

        rts
.endproc

; ssize_t dev_ttyS0_read(struct CharDriver *device, void *buf, size_t nbytes, off_t offset)
.proc dev_ttyS0_read
        setup_frame
        rep     #$30

        ldy     z:7 ; nbytes

        sep     #$20

loop:
        cpy     #0
        beq     done_loop

        ; Load head of RX buffer
        ldx     rx_head

        ; Compare head to tail and loop if empty buffer
        cpx     rx_tail
        beq     loop

        ; Load byte read
        lda     a:rx_buff,x

        ; Increment head to next position
        inx
        cpx     #rx_buff_length
        blt     skip_wrap_buff
        ldx     #0
skip_wrap_buff:

        ; Update RX buffer head
        stx     rx_head

        ; Store received byte in output buffer
        sta     (5) ; *buf

        ; Increment buffer pointer and decrement number of bytes
        inc     z:5 ; buf
        dey

        bra     loop

done_loop:

        rep     #$30
        lda     z:7 ; nbytes

        restore_frame
        rts
.endproc

; ssize_t dev_ttyS0_write(struct CharDriver *device, const void *buf, size_t nbytes, off_t offset)
.proc dev_ttyS0_write
        setup_frame
        rep     #$30

        ldx     z:5 ; buf
        ldy     z:7 ; nbytes

        sep     #$20

loop:
        cpy     #0
        beq     done_loop

        ; Load tail of TX buffer
        ldx     tx_tail

        ; Load a byte from input buffer
        lda     (5) ; *buf

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
        beq     loop

        ; Update TX buffer tail
        stx     tx_tail

        ; Increment buffer pointer and decrement number of bytes
        inc     z:5 ; buf
        dey
        
        ; If the TX buffer was completely emptied,
        ; have to bootstrap transmission
        lda     empty_tx_buff
        bze     skip_bootstrap_transmit
        
        ; Emulate IRQ for UART3 transmit
        lda     #.bankbyte(skip_bootstrap_transmit)
        pha
        pea     skip_bootstrap_transmit
        php
        jmp     UART3_trans
        
skip_bootstrap_transmit:
        bra     loop

done_loop:

        rep     #$30
        lda     z:7 ; nbytes

        restore_frame
        rts
.endproc
