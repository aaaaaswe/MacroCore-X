# MacroCore-X Extended Unsigned Division Edge Cases Test
# Tests divu with 64-bit unsigned values, max values, and boundary conditions

    # R10 = pass counter
    mov r10, 0

    # === Test 1: divu large 64-bit / 1 ===
    # 0xFFFFFFFFFFFFFFFF / 1 = 0xFFFFFFFFFFFFFFFF
    movi r3, 0xFFFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4    # r3 = 0xFFFFFFFFFFFFFFFF
    mov r4, 1
    divu r3, r3, r4
    movi r5, 0xFFFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: divu large 64-bit / small ===
    # 0xFFFFFFFFFFFFFFFF / 2 = 0x7FFFFFFFFFFFFFFF
    movi r3, 0xFFFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4
    mov r4, 2
    divu r3, r3, r4
    movi r5, 0x7FFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: divu by power of two ===
    # 0x8000000000000000 / 0x100000000 = 0x80000000
    movi r3, 0x80000000
    shli r3, r3, 32    # r3 = 0x8000000000000000
    movi r4, 0x10000000
    divu r3, r3, r4
    movi r5, 0x80000000
    shli r5, r5, 32
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: divu zero / non-zero ===
    mov r3, 0
    mov r4, 999
    divu r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 4

    # === Test 5: divu with remainder ===
    # 100 / 7 = 14 (unsigned)
    mov r3, 100
    mov r4, 7
    divu r3, r3, r4
    mov r5, 14
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: divu exact division ===
    # 0x10000 / 0x100 = 0x100
    movi r3, 0x10000
    movi r4, 0x100
    divu r3, r3, r4
    movi r5, 0x100
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === Test 7: divu dividend < divisor ===
    # 5 / 10 = 0
    mov r3, 5
    mov r4, 10
    divu r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 7

    # === Test 8: divu large divisor ===
    # 0x1000000000000000 / 0x1000000000000000 = 1
    movi r3, 0x10000000
    shli r3, r3, 32
    mov r4, 0
    add r4, r3, r0    # r4 = r3
    divu r3, r3, r4
    mov r5, 1
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 8

    # === Test 9: divu 32-bit max / 2 ===
    movi r3, 0xFFFFFFFF
    mov r4, 2
    divu r3, r3, r4
    movi r5, 0x7FFFFFFF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 9

    # === Test 10: divu 0xFFFF / 0xFF ===
    movi r3, 0xFFFF
    movi r4, 0xFF
    divu r3, r3, r4
    movi r5, 0x101
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 10

    # === Test 11: divu by 3 ===
    # 0xFFFFFFFFFFFFFFFF / 3 = 0x5555555555555555
    movi r3, 0xFFFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4
    mov r4, 3
    divu r3, r3, r4
    movi r5, 0x55555555
    shli r5, r5, 32
    movi r6, 0x55555555
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 11

    # === Test 12: divu by 0x100000000 (32-bit overflow divisor) ===
    movi r3, 0xABCDEF00
    shli r3, r3, 32
    movi r4, 0x10000000
    divu r3, r3, r4
    movi r5, 0xABCDEF00
    shli r5, r5, 32
    shr r5, r5, r0     # just verify: r5 >> 0 = r5
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 12

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0