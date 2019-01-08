.p816
.smart

.macpack generic

.include "functions.inc"
.include "lib.inc"

.export STACK_SIZE = 1024

.segment "STACK"

        .res    STACK_SIZE

.import __STACK_LOAD__
.import main
        
.segment "STARTUP"

.export init
init:
        ; Setup native 16-bit mode
        cld
        clc
        xce
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
        safe_brk
        bra     @brkloop

.rodata
