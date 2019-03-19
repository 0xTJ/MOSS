PROC_MAX_FILES = 8

PROC_NUM = 8

PROCESS_CREATED = 0
PROCESS_READY = 1
PROCESS_TERMINATED = 2
PROCESS_WAIT_VFORK = 3

.struct Process
        stack_p .word

        pid     .word
        ppid    .word

        state   .word

        ret_val .word

        next    .addr

        text_base   .addr
        data_base   .addr
        bss_base    .addr
        zero_base   .addr
        stack_base  .addr

        files_p .addr 8

        ; The following are used to replace the stack pointer and stack base when returning from syscall
        new_stack_p .word
        new_stack_base .word
.endstruct

.global sys_tick
.global current_process_p
.global proc_table
; Used to keep scheduler from loading other processes.
; The current process's data will still be accesses and modified.
; Disable interrupts when modifying the current process.
.global disable_scheduler
; struct Process *clone_current_proc()
; Properly setting SP must be managed by calling function.
; Set to not running.
.global clone_current_proc
; void replace_current_proc(void *initial_sp, void *initial_pc)
.global replace_current_proc
; void setup_proc(struct Process *proc, void *initial_sp, void *initial_pc)
; Assumes Program Bank is $00
.global setup_proc
; struct Process *create_proc(void)
.global create_proc
; struct Process *find_previous_proc(struct Process *proc)
.global find_previous_proc
; void term_proc(int pid)
.global term_proc
; void destroy_proc(int pid)
.global destroy_proc
; void _exit(int status)
.global _exit
