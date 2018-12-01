.p816
.smart

.macpack generic

.autoimport

.export STACK_SIZE = 1024

.segment "STACK"

        .res    STACK_SIZE

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

        pea     init_string
        jsr     puts
        rep     #$30
        ply

        ; Run main
        ; jsr     main

exit:
        ; jsr     donelib
@brkloop:
        brk
        brk
        bra     @brkloop

.rodata

.export init_string
init_string:
        .byte   $0D
        .asciiz "initialized system"

.data

test:
        .asciiz "initialized system"
