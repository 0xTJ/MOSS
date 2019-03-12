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
        enter   2
        rep     #$30

        pea     1       ; read 1 byte
        tdc
        add     #var 0  ; Space for read value
        pha
        ldx     z:arg 0 ; stream
        lda     a:FILE::fd,x
        pha             ; File Descriptor
        jsr     read
        rep     #$30
        ply
        ply
        ply

        ; If read returned -1, return EOF
        cmp     #$FFFF
        beq     failed

        ; Load read value for return
        lda     z:var 0

done:
        leave
        rts

failed:
        lda     #EOF
        bra     done
.endproc

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

; int fputc(int c, FILE *stream)
.proc fputc
        enter
        rep     #$30

        pea     1       ; write 1 byte
        tdc
        add     #arg 0  ; &c
        pha
        ldx     z:arg 2 ; stream
        lda     a:FILE::fd,x
        pha             ; File Descriptor
        jsr     write

        leave
        rts
.endproc

; int fputs(const char *s, FILE * stream)
.proc fputs
        enter
        rep     #$30

        lda     z:arg 0 ; s
        pha
        jsr     strlen
        rep     #$30
        ply

        pha             ; strlen(s)
        lda     z:arg 0 ; s
        pha
        ldx     z:arg 2 ; stream
        lda     a:FILE::fd,x
        pha             ; File Descriptor
        jsr     write

        leave
        rts
.endproc

; int getc(FILE *stream)
getc    := fgetc

; int getchar(void)
.proc getchar
        enter
        rep     #$30

        pea     stdin
        jsr     fgetc

done:
        leave
        rts
.endproc

; char *gets(char *str)
.proc gets
        enter
        rep     #$30

        pea     stdin
        lda     z:arg 0 ; str
        pha
        jsr     fgets

done:
        leave
        rts
.endproc

; int putc(int c, FILE *stream)
putc    := fputc

; int putchar(int c)
.proc putchar
        enter
        rep     #$30

        pea     stdout
        lda     z:arg 0 ; c
        pha
        jsr     fputc

        leave
        rts
.endproc

; int puts(const char *s)
.proc puts
        enter
        rep     #$30

        pea     stdout
        lda     z:arg 0 ; s
        pha
        jsr     fputs
        rep     #$30
        ply
        ply

        pea     stdout
        pea     $0A     ; LF
        jsr     putchar

        leave
        rts
.endproc
