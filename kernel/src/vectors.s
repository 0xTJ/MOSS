.p816
.smart

.include "w65c265s.inc"
.include "syscall.inc"

.macpack generic

.segment "VECTORS"

.org    $FF00

.res    NAT_IRQCOP - *
.addr   sys_call
