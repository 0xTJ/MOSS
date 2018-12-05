.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

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

        pea     $0D
        jsr     putchar
        rep     #$30
        ply
        
        pea     data_string
        jsr     puts
        rep     #$30
        ply

        jsr     initlib

        pea     init_string
        jsr     puts
        rep     #$30
        ply

        ; Run main
        jsr     main

exit:
        ; jsr     donelib
@brkloop:
        safe_brk
        bra     @brkloop

.rodata

data_string:
        .asciiz "setup data"

init_string:
        .asciiz "initialized system"
