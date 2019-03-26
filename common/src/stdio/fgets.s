.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; char *fgets(char *str, int num, FILE * stream)
.proc fgets
        enter
        rep     #$30

        ; Push original string pointer
        lda     z:arg 0 ; str
        pha

loop:
        lda     z:arg 2 ; num
        cmp     #1
        ble     done_loop

        ; Get a character from file stream
        lda     z:arg 4 ; stream
        pha
        jsr     fgetc
        rep     #$30
        ply

        cmp     #$FFFF  ; EOF
        beq     done_loop

        ; Store character to buffer
        ldx     z:arg 0 ; str
        sep     #$20
        sta     a:0,x

        inc     z:arg 0 ; str
        dec     z:arg 2 ; num

        cmp     #$0A
        rep     #$20
        beq     done_loop

        bra     loop

done_loop:

        ; Load original string pointer
        pla

        ; If we haven't added anything, return NULL
        cmp     1,s
        bne     done
        lda     #$0000

done:
        leave
        rts
.endproc
