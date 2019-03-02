.macro mutex_lock mutex
        php
        rep     #$20
        lda     #1
        
        .local  lock_loop
lock_loop:
        inc     mutex
        cmp     mutex
        beq     lock_done
        dec     mutex
        bra     lock_loop
        
        .local  lock_done
lock_done:
        plp
.endmacro

.macro mutex_unlock mutex
        dec     mutex
.endmacro
