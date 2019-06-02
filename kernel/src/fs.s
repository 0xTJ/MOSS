.p816
.smart

.macpack generic

.include "fs.inc"
.include "functions.inc"

.bss

; struct fs *fs_list
fs_list:
        .addr   0

.code

; int register_fs(struct fs *fs_prop)
.proc register_fs
        enter

        lda     fs_list
        ldx     #fs_list

list_loop:
        cmp     #0
        bze     done_list_loop
        add     #fs::next
        tax
        lda     a:0,x
        bra     list_loop
done_list_loop:

        lda     z:arg 0 ;   fs_prop
        sta     a:0,x
        
        lda     #0

        leave
        rts
.endproc
