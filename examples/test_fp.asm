# MacroCore-X Scalar FP Test (F-type Extension, Independent FPU)
# Tests fadd, fsub, fmul, fdiv (f32 precision)
# F-type encoding: byte0=0xA0|Fd, byte1=(Fs1<<4)|Fs2, byte2=funct, byte3=aux
# F-type uses independent F registers (F0-F31), NOT V registers

    # R2 = buffer address for float data
    movi r2, 0x8000

    # Load 3.0f (IEEE 754: 0x40400000) into memory, then into F0
    movi r1, 0x40400000
    stw r1, [r2 + 0]
    fld f0, [r2 + 0]

    # Load 2.0f (IEEE 754: 0x40000000) into memory, then into F1
    movi r1, 0x40000000
    stw r1, [r2 + 8]
    fld f1, [r2 + 8]

    # Test fadd: F2 = F0 + F1 = 3.0 + 2.0 = 5.0 (0x40A00000)
    fadd f2, f0, f1

    # Test fsub: F3 = F0 - F1 = 3.0 - 2.0 = 1.0 (0x3F800000)
    fsub f3, f0, f1

    # Test fmul: F4 = F0 * F1 = 3.0 * 2.0 = 6.0 (0x40C00000)
    fmul f4, f0, f1

    # Test fdiv: F5 = F0 / F1 = 3.0 / 2.0 = 1.5 (0x3FC00000)
    fdiv f5, f0, f1

    # Test fcmp: compare F0 and F1 (3.0 vs 2.0)
    fcmp f0, f1

    # Store results to memory
    fst f2, [r2 + 32]
    fst f3, [r2 + 40]
    fst f4, [r2 + 48]
    fst f5, [r2 + 56]

    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0