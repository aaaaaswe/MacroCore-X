# MacroCore-X Scalar FP Test (F-type Extension)
# Tests fadd, fsub, fmul, fdiv (f32 precision)
# F-type encoding: byte0=0xA0|Fd, byte1=(Fs1<<4)|Fs2, byte2=funct, byte3=aux

    # R2 = buffer address for float data
    movi r2, 0x8000

    # Load 3.0f (IEEE 754: 0x40400000) into V0
    movi r1, 0x40400000
    stw r1, [r2 + 0]
    vld v0, [r2 + 0]

    # Load 2.0f (IEEE 754: 0x40000000) into V1
    movi r1, 0x40000000
    stw r1, [r2 + 8]
    vld v1, [r2 + 8]

    # Test fadd: V2 = V0 + V1 = 3.0 + 2.0 = 5.0 (0x40A00000)
    fadd v2, v0, v1

    # Test fsub: V3 = V0 - V1 = 3.0 - 2.0 = 1.0 (0x3F800000)
    fsub v3, v0, v1

    # Test fmul: V4 = V0 * V1 = 3.0 * 2.0 = 6.0 (0x40C00000)
    fmul v4, v0, v1

    # Test fdiv: V5 = V0 / V1 = 3.0 / 2.0 = 1.5 (0x3FC00000)
    fdiv v5, v0, v1

    # Test fcmp: compare V0 and V1 (3.0 vs 2.0)
    fcmp v0, v1

    # Store results to memory
    vst v2, [r2 + 32]
    vst v3, [r2 + 40]
    vst v4, [r2 + 48]
    vst v5, [r2 + 56]

    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0