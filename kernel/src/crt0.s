.p816
.smart

.macpack generic

.include "functions.inc"
.include "lib.inc"
.include "w65c265s.inc"

.export STACK_SIZE = 1024

.segment "STACK"

        .res    STACK_SIZE

.import __STACK_LOAD__
.import main

.segment "STARTUP"

.export init
init:
        ; Setup native 16-bit mode
        sei
        cld
        clc
        xce

        sep     #$20

        ; Use external memory
        lda     #(1 << 7)
        tsb     BCR

        ; Clear timers and interrupt enables
        stz     TCR
        stz     TER
        stz     TIER
        stz     EIER
        stz     UIER

        ; Clear interrupt flags
        lda     #$FF
        sta     TIFR
        sta     EIFR
        sta     UIFR

        ; Show P7 on LEDS
        stz     PCS7

        rep     #$30

        ; Load SP with top of stack, requires 2 bytes on stack
        lda     #__STACK_LOAD__ + STACK_SIZE - 1
        tcs

        ; Initialize system
        jsr     zerobss
        jsr     copydata
        jsr     initlib

        ; Run main
        jsr     main

exit:
        ; jsr     donelib
@brkloop:
        bra     @brkloop

.rodata
