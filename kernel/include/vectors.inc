.struct NatVect
                .addr   $40
        IRQT0   .addr
        IRQT1   .addr
        IRQT2   .addr
        IRQT3   .addr
        IRQT4   .addr
        IRQT5   .addr
        IRQT6   .addr
        IRQT7   .addr
        IRPE56  .addr
        IRNE57  .addr
        IRPE60  .addr
        IRPE62  .addr
        IRNE64  .addr
        IRNE66  .addr
        IRQPIB  .addr
        IRQ     .addr
        IRQAR0  .addr
        IRQAT0  .addr
        IRQAR1  .addr
        IRQAT1  .addr
        IRQAR2  .addr
        IRQAT2  .addr
        IRQAR3  .addr
        IRQAT3  .addr
                .addr
                .addr
        IRQCOP  .addr
        IRQBRK  .addr
        IABORT  .addr
        IRQNMI  .addr
                .addr
                .addr
.endstruct

.struct EmuVect
        IRQT0   .addr
        IRQT1   .addr
        IRQT2   .addr
        IRQT3   .addr
        IRQT4   .addr
        IRQT5   .addr
        IRQT6   .addr
        IRQT7   .addr
        IRPE56  .addr
        IRNE57  .addr
        IRPE60  .addr
        IRPE62  .addr
        IRNE64  .addr
        IRNE66  .addr
        IRQPIB  .addr
        IRQ     .addr
        IRQAR0  .addr
        IRQAT0  .addr
        IRQAR1  .addr
        IRQAT1  .addr
        IRQAR2  .addr
        IRQAT2  .addr
        IRQAR3  .addr
        IRQAT3  .addr
                .addr
                .addr
        IRQCOP  .addr
                .addr
        IABORT  .addr
        IRQNMI  .addr
        IRQRES  .addr
        IRQBRK  .addr
.endstruct

.struct VectTab
        Nat .tag NatVect
        Emu .tag EmuVect
.endstruct

.global vectors
