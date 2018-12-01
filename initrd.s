.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "filesys.inc"

; struct FSNode *initrd_create(struct Device *dev)
.proc initrd_init
        rep     #$30

        ; Allocate memory for file-system node
        pea     .sizeof(FSNode)
        jsr     malloc
        rep     #$30
        ply

        ; Fail and exit if we couldn't allocate
        cmp     #0
        beq     failed

        ; Put address of node into X
        tax

        ; 0-length name
        sep     #$20
        stz     FSNode::name,x
        rep     #$20

        ; Is a plain directory
        lda     #FS_DIRECTORY
        sta     FSNode::flags,x

        ; Set to inode 0
        stz     FSNode::inode,x

        ; Write Functions
        stz     FSNode::read,x
        stz     FSNode::write,x
        stz     FSNode::open,x
        stz     FSNode::close,x
        lda     initrd_readdir
        sta     FSNode::readdir,x
        lda     initrd_finddir
        sta     FSNode::finddir,x

        ; Zero the pointer
        stz     FSNode::ptr,x

        ; Put address of node into A
        txa
        
failed: ; When we branch here due to failure, A will already be 0
        rts
.endproc

; struct DirEnt *initrd_readdir(struct FSNode *node, unsigned int index)
.proc initrd_readdir
        setup_frame

        rep     #$20
        lda     #0

        restore_frame
        rts
.endproc

; struct FSNode *initrd_finddir(struct FSNode *node, char *name)
.proc initrd_finddir
        setup_frame

        rep     #$20
        lda     #0

        restore_frame
        rts
.endproc
