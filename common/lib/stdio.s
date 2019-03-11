.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.data

stdin:
        .word 0
stdout:
        .word 1
stderr:
        .word 2

.code

; int fgetc(FILE *stream)
.proc fgetc
        enter_nostackvars
        rep     #$30

        ; Create stack space for read value
        pea     0
        tsc
        inc

        pea     1   ; read 1 byte
        pha         ; Space for read value
        ldx     z:3 ; stream
        lda     a:FILE::fd,x
        pha         ; File Descriptor
        jsr     read
        rep     #$30
        ply
        ply
        ply

        ; If read returned -1, return EOF
        cmp     #$FFFF
        beq     failed

        ; Load read value for return
        pla

done:
        leave_nostackvars
        rts

failed:
        lda     #EOF
        bra     done
.endproc

; char *fgets(char *str, int num, FILE * stream)
.proc fgets
        enter_nostackvars
        rep     #$30

        ; Push original string pointer
        lda     z:3 ; str
        pha

loop:
        lda     z:5 ; num
        cmp     #1
        ble     done_loop

        ; Get a character from file stream
        lda     z:7 ; stream
        pha
        jsr     fgetc
        rep     #$30
        ply

        cmp     #$FFFF  ; EOF
        beq     done_loop

        ; Store character to buffer
        ldx     z:3 ; str
        sep     #$20
        sta     a:0,x

        inc     z:3 ; str
        dec     z:5 ; num

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
        leave_nostackvars
        rts
.endproc

; int fputc(int c, FILE *stream)
.proc fputc
        enter_nostackvars
        rep     #$30

        pea     1   ; write 1 byte
        tdc
        add     #3
        pha         ; &c
        ldx     z:5 ; stream
        lda     a:FILE::fd,x
        pha         ; File Descriptor
        jsr     write

        leave_nostackvars
        rts
.endproc

; int fputs(const char *s, FILE * stream)
.proc fputs
        enter_nostackvars
        rep     #$30

        lda     z:3 ; s
        pha
        jsr     strlen
        rep     #$30
        ply

        pha         ; strlen(s)
        lda     z:3 ; s
        pha
        ldx     z:5 ; stream
        lda     a:FILE::fd,x
        pha         ; File Descriptor
        jsr     write

        leave_nostackvars
        rts
.endproc

; int getc(FILE *stream)
getc    := fgetc

; int getchar(void)
.proc getchar
        enter_nostackvars
        rep     #$30

        pea     stdin
        jsr     fgetc

done:
        leave_nostackvars
        rts
.endproc

; char *gets(char *str)
.proc gets
        enter_nostackvars
        rep     #$30

        pea     stdin
        lda     z:3 ; str
        pha
        jsr     fgets

done:
        leave_nostackvars
        rts
.endproc

; int putc(int c, FILE *stream)
putc    := fputc

; int putchar(int c)
.proc putchar
        enter_nostackvars
        rep     #$30

        pea     stdout
        lda     z:3 ; c
        pha
        jsr     fputc

        leave_nostackvars
        rts
.endproc

; int puts(const char *s)
.proc puts
        enter_nostackvars
        rep     #$30

        pea     stdout
        lda     z:3 ; s
        pha
        jsr     fputs
        rep     #$30
        ply
        ply

        pea     stdout
        pea     a:10    ; NL
        jsr     putchar

        leave_nostackvars
        rts
.endproc
