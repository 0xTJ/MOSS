.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

; char *strcpy(char *dest, const char *src)
.export strcpy
.proc strcpy
        setup_frame

        sep     #$20    ; Set main data to 8-bit
        rep     #$10    ; Set index registers to 16-bit

        ; Load Y with dest, X with src
        ldy     z:3
        ldx     z:5

        bra     skip_first_inc

loop:
        inx
        iny
skip_first_inc:
        lda     a:0,x
        sta     a:0,y
        bnz     loop

        lda     z:3

        restore_frame
        rts
.endproc

; size_t strlen(const char *str)
.export strlen
.proc strlen
        setup_frame

        ; Load initial values
        rep     #$10
        sep     #$20
        ldy     #0      ; Count variable
        ldx     z:3     ; Pointer within string

        bra     skip_first_inc

loop:
        inx
        iny
skip_first_inc:
        lda     a:0,x
        bnz     loop

done:
        rep     #$30
        tya

        restore_frame
        rts
.endproc

;int strcmp (const char *str1, const char *str2)
.export strcmp
.proc strcmp
        setup_frame

        rep     #$10
        sep     #$20
        ldy     #0

loop:
        lda     (3),y
        sub     (5),y
        bnz     sign_extend

        lda     (3),y
        bze     sign_extend

        iny

        bra     loop

sign_extend:
        ; Sign-extend A
        rep     #$30
        bit     #$80    ; Negative bit
        bze     clear_upper_byte
set_upper_byte:
        ora     #$FF00
        bra     done
clear_upper_byte:
        and     #$00FF
done:
        restore_frame
        rts
.endproc

; void *memset(void *s, int c, size_t n)
.export memset
.proc memset
        setup_frame
        rep     #$30

        ldx     z:7 ; n
        bze     done

        lda     z:5 ; c

        ; Manually store once, will be used as source for copy
        sep     #$20
        sta     (3) ; *s
        dex     ; n - 1
        bze     done
        rep     #$30

        txa     ; n - 1
        dec     ; n - 2
        ldx     z:3 ; s
        txy     ; s
        iny     ; s + 1

        ; Run mvn with:
        ; A: n - 2
        ; X: s (source of MVN)
        ; Y: s + 1 (destination of MVN)
        ; Src and dst banks 0
        mvn     0, 0

done:
        rep    #$30
        restore_frame
        rts
.endproc

; void *memcpy(void *dest, const void *src, size_t n)
.export memcpy
.proc memcpy
        setup_frame
        rep     #$30

        ; Put n - 1 into A, or done if n == 0
        lda     z:7 ; n
        bze     done
        dec

        ; Load dest and src to Y and X
        ldy     z:3 ; dest
        ldx     z:5 ; src

        ; Run mvn with:
        ; A: n - 1
        ; X: src
        ; Y: dest
        ; Src and dst banks 0
        mvn     0, 0

done:
        restore_frame
        rts
.endproc

; void *memmove(void *dest, const void *src, size_t n)
.export memmove
.proc memmove
        setup_frame
        rep     #$30

        ; Done if n == 0
        lda     z:7 ; n
        bze     done

        ; Load compare dest to src
        lda     z:3 ; dest
        cpa     z:5 ; src

        ; If equal, we're done
        beq     done

        ; If destination is greater than source
        bgt    copy_pos

        ; If destination if less than source
        blt     copy_neg

copy_pos:
        ; Load src + n - 1 to X
        lda     z:5 ; src
        add     z:7 ; n
        dec
        tax
        
        ; Load dest + n - 1 to X
        lda     z:3 ; dest
        add     z:7 ; n
        dec
        tax
        
        ; Load n - 1 to A
        ldx     z:7 ; n
        dec

        ; Run mvn with:
        ; A: n - 1
        ; X: src + n - 1
        ; Y: dest + n - 1
        ; Src and dst banks 0
        mvp     0, 0
        bra     done

copy_neg:
        ; Load destination to Y
        ldy     z:3 ; src
        
        ; Load source to X
        ldx     z:5 ; src
        
        ; Load n - 1 to A
        ldx     z:7 ; n
        dec

        ; Run mvn with:
        ; A: n - 1
        ; X: src
        ; Y: dest
        ; Src and dst banks 0
        mvn     0, 0
        bra     done

done:
        restore_frame
        rts
.endproc
