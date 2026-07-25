# MacroCore-X Division Edge Cases Test
# Tests signed and unsigned division with various edge cases
# NOTE: mov uses 14-bit sign-extended immediate; negative values
# from mov don't match 64-bit arithmetic results. Use sub from r0.

    # R10 = pass counter
    mov r10, 0

    # === Test div: positive / positive ===
    mov r3, 100
    mov r4, 7
    div r3, r3, r4
    mov r5, 14      # 100/7 = 14 truncate toward zero
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # === Test div: negative / positive (truncate toward zero) ===
    mov r3, 100
    sub r3, r0, r3   # r3 = -100 in 64-bit
    mov r4, 7
    div r3, r3, r4
    mov r6, 14
    sub r5, r0, r6   # r5 = -14 in 64-bit
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # === Test div: positive / negative (truncate toward zero) ===
    mov r3, 100
    mov r4, 7
    sub r4, r0, r4   # r4 = -7 in 64-bit
    div r3, r3, r4
    mov r6, 14
    sub r5, r0, r6   # r5 = -14 in 64-bit
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # === Test div: negative / negative ===
    mov r3, 100
    sub r3, r0, r3   # r3 = -100
    mov r4, 7
    sub r4, r0, r4   # r4 = -7
    div r3, r3, r4
    mov r5, 14       # (-100)/(-7) = 14
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 4

    # === Test div: zero / non-zero ===
    mov r3, 0
    mov r4, 5
    div r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 5

    # === Test div: edge case - large positive (within 32-bit) ===
    movi r3, 0x7FFFFFFF
    mov r4, 1
    div r3, r3, r4
    movi r5, 0x7FFFFFFF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === Test divu: unsigned division (max 32-bit) ===
    movi r3, 0xFFFFFFFF
    mov r4, 2
    divu r3, r3, r4
    movi r5, 0x7FFFFFFF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 7

    # === Test divu: small unsigned ===
    mov r3, 9
    mov r4, 4
    divu r3, r3, r4
    mov r5, 2
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 8

    # === Test div: exact division (no remainder) ===
    mov r3, 256
    mov r4, 16
    div r3, r3, r4
    mov r5, 16
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 9

    # === Test div: rounding toward zero for -1 / 2 ===
    mov r3, 1
    sub r3, r0, r3   # r3 = -1
    mov r4, 2
    div r3, r3, r4
    eq r5, r3, r0     # -1/2 = 0 (truncate toward zero)
    add r10, r10, r5  # R10 = 10

    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0