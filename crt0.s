.p816

.macpack generic

.autoimport

.segment "STARTUP"

init:
        ; Setup native 16-bit mode
        cld
        clc
        xce
        rep     #$30
        
        ; Load SP with top of stack, requires 2 bytes on stack
        lda     initial_sp
        tcs
        
        ; Initialize system
        jsr     zerobss
        jsr     copydata
        jsr     initlib
        
        ; Run main
        jsr     main

exit:
        jsr     donelib
@brkloop:
        brk
        brk
        jmp     @brkloop

.rodata

initial_sp:
        .word   __BSS_LOAD__ + __BSS_SIZE__ - 1
