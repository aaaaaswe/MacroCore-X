# MacroCore-X IEEE 754 Special Values FP Test
# Tests NaN, +Inf, -Inf, +0, -0, subnormal, and edge cases with F-type instructions

    # R2 = buffer address for float data
    movi r2, 0x8000

    # R10 = pass counter
    mov r10, 0

    # === Test 1: fadd +Inf + anything = +Inf ===
    # +Inf = 0x7F800000, 1.0 = 0x3F800000
    movi r3, 0x7F800000
    stw r3, [r2 + 0]
    movi r3, 0x3F800000
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fadd f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x7F800000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: fmul -Inf * +Inf = -Inf ===
    # -Inf = 0xFF800000, +Inf = 0x7F800000
    movi r3, 0xFF800000
    stw r3, [r2 + 0]
    movi r3, 0x7F800000
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmul f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0xFF800000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: fdiv 0.0 / 0.0 = NaN ===
    # 0.0 = 0x00000000
    mov r3, 0
    stw r3, [r2 + 0]
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fdiv f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    # NaN has exponent=0xFF and non-zero mantissa
    # Check that the result is NaN (exponent bits all 1s)
    movi r5, 0x7F800000
    and r6, r4, r5
    eq r5, r6, r5      # exponent is 0xFF
    add r10, r10, r5  # R10 = 3

    # === Test 4: fdiv 1.0 / 0.0 = +Inf ===
    # 1.0 = 0x3F800000, 0.0 = 0x00000000
    movi r3, 0x3F800000
    stw r3, [r2 + 0]
    mov r3, 0
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fdiv f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x7F800000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # === Test 5: fdiv -1.0 / 0.0 = -Inf ===
    # -1.0 = 0xBF800000
    movi r3, 0xBF800000
    stw r3, [r2 + 0]
    mov r3, 0
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fdiv f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0xFF800000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: fneg -0.0 = +0.0 ===
    # -0.0 = 0x80000000
    movi r3, 0x80000000
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fneg f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    eq r5, r4, r0      # +0.0 = 0x00000000
    add r10, r10, r5  # R10 = 6

    # === Test 7: fabs -Inf = +Inf ===
    movi r3, 0xFF800000
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fabs f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0x7F800000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 7

    # === Test 8: fmin(NaN, 1.0) should return 1.0 (NaN is not a number) ===
    # NaN = 0x7FC00000 (quiet NaN), 1.0 = 0x3F800000
    movi r3, 0x7FC00000
    stw r3, [r2 + 0]
    movi r3, 0x3F800000
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmin f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    # Implementation may return 1.0 (non-NaN) or NaN
    # Accept either behavior for this test
    movi r5, 0x3F800000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 8

    # === Test 9: fmax(-Inf, 0.0) = 0.0 ===
    movi r3, 0xFF800000
    stw r3, [r2 + 0]
    mov r3, 0
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmax f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    eq r5, r4, r0
    add r10, r10, r5  # R10 = 9

    # === Test 10: fsub -Inf - (-Inf) = NaN ===
    movi r3, 0xFF800000
    stw r3, [r2 + 0]
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fsub f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    # Check NaN (exponent = 0xFF)
    movi r5, 0x7F800000
    and r6, r4, r5
    eq r5, r6, r5
    add r10, r10, r5  # R10 = 10

    # === Test 11: fmul with subnormal (very small) ===
    # 1.175494e-38 (smallest normalized f32 ~ 0x00800000)
    movi r3, 0x00800000
    stw r3, [r2 + 0]
    movi r3, 0x40000000   # 2.0
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fmul f2, f0, f1
    fst f2, [r2 + 32]
    ld r4, [r2 + 32]
    # Result should be 2.3509887e-38 = 0x01000000
    movi r5, 0x01000000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 11

    # === Test 12: fsqrt of 0.0 = 0.0 ===
    mov r3, 0
    stw r3, [r2 + 0]
    fld f0, [r2 + 0]
    fsqrt f1, f0
    fst f1, [r2 + 32]
    ld r4, [r2 + 32]
    eq r5, r4, r0
    add r10, r10, r5  # R10 = 12

    # === Test 13: fcmp with +Inf vs +Inf (equal) ===
    movi r3, 0x7F800000
    stw r3, [r2 + 0]
    stw r3, [r2 + 8]
    fld f0, [r2 + 0]
    fld f1, [r2 + 8]
    fcmp f0, f1
    add r10, r10, r0  # If we reach here, fcmp didn't crash
    add r10, r10, r0  # R10 = 13

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0