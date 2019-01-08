.p816
.smart

.macpack generic

.include "functions.inc"

; void mutex_take(int *mutex_p)
.export mutex_take
.proc mutex_take
        setup_frame

        rep     #$30

        ldx     z:3     ; mutex_p

loop:
        ; Used for comparison
        lda     #0

        ; while (*mutex_p != 0)
wait_for_free:
        cmp     a:0,x
        bne     wait_for_free

        ; Used for comparison
        lda     #1

        ; Increment mutex
        inc     a:0,x

        ; Check if the mutex is exactly 1
        cmp     a:0,x
        beq     done

        ; Try again
        dec     a:0,x
        bra     loop

done:
        restore_frame
        rts
.endproc

; void mutex_give(int *mutex_p)
.export mutex_give
.proc mutex_give
        setup_frame

        rep     #$30
        ldx     z:3     ; mutex_p
        dec     a:0,x

        restore_frame
        rts
.endproc
