# MacroCore-X Extended FP Test
# Tests untested F-type instructions: fsqrt, fmin, fmax, fneg, fabs,
# fcvt.w.s, fcvt.s.w

    # R2 = buffer address for float data
    movi r2, 0x8000

    # R10 = pass counter
    mov r10, 0

    # === Test fsqrt: sqrt(4.0) = 2.0 ===
    # 4.0f = 0x40800000
    movi r3, 0x40800000
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fsqrt f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    # 2.0f = 0x40000000
    movi r5, 0x40000000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 1

    # === Test fsqrt: sqrt(9.0) = 3.0 ===
    # 9.0f = 0x41100000
    movi r3, 0x41100000
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fsqrt f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    # 3.0f = 0x40400000
    movi r5, 0x40400000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 2

    # === Test fmin: min(3.0, 2.0) = 2.0 ===
    # 3.0f = 0x40400000, 2.0f = 0x40000000
    movi r3, 0x40400000
    stw r3, [r2 + 0]
    movi r3, 0x40000000
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmin f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x40000000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 3

    # === Test fmax: max(3.0, 2.0) = 3.0 ===
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmax f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x40400000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # === Test fneg: neg(3.0) = -3.0 ===
    # 3.0f = 0x40400000, -3.0f = 0xC0400000
    fld f0, [r2 + 0]
    fneg f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0xC0400000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === Test fabs: abs(-3.0) = 3.0 ===
    fld f0, [r2 + 32]   # load -3.0
    fabs f1, f0
    fst f1, [r2 + 40]
    ld r4, [r2 + 40]
    movi r5, 0x40400000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 6

    # === Test fcvt.w.s: float to int (3.7 → 3, truncate) ===
    # 3.7f ≈ 0x406CCCCD
    movi r3, 0x406CCCCD
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fcvt.w.s f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    # 3.0f = 0x40400000
    movi r5, 0x40400000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 7

    # === Test fcvt.s.w: int to float (5 → 5.0) ===
    # 5.0f = 0x40A00000
    movi r3, 0x40A00000
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fcvt.w.s f1, f0   # float→int (5.0 → 5.0)
    fcvt.s.w f2, f1   # int→float (5.0 → 5.0)
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x40A00000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 8

    # === Test fmin with negative values ===
    # -5.0f = 0xC0A00000, 2.0f = 0x40000000
    movi r3, 0xC0A00000
    stw r3, [r2 + 0]
    movi r3, 0x40000000
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmin f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0xC0A00000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 9

    # === Test fmax with negative values ===
    fmax f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x40000000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 10

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0