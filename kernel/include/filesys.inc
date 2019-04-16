; struct VNode *follow_mounts(struct VNode *node)
.global follow_mounts
; int traverse_rel_path(struct VNode *node, char *path, struct VNode *result)
.global traverse_rel_path
; int traverse_abs_path(char *path, struct VNode *result)
.global traverse_abs_path
; void mount_fs(struct VNode *mount_point, struct VNode *mounted)
.global mount_fs
; unsigned int read_fs(struct VNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.global read_fs
; unsigned int write_fs(struct VNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.global write_fs
; int open_fs(struct VNode *node, uint8_t read, uint8_t write)
.global open_fs
; void close_fs(struct VNode *node)
.global close_fs
; int readdir_fs(struct VNode *node, unsigned int index, struct DirEnt *result)
.global readdir_fs
; int finddir_fs(struct VNode *node, char *name, struct VNode **result)
.global finddir_fs
