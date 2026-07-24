# MacroCore-X Multiplication Edge Cases Test
# Tests multiplication overflow, zero, large operands, and negative values

    # R10 = pass counter
    mov r10, 0

    # === Test 1: mul overflow (64-bit wrap) ===
    # 0x1000000000000000 * 0x10 = 0x0000000000000000 (overflow)
    movi r3, 0x10000000
    shli r3, r3, 32    # r3 = 0x1000000000000000
    mov r4, 16
    mul r3, r3, r4     # overflow: 0x10000000000000000 & 0xFFFFFFFFFFFFFFFF = 0
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 1

    # === Test 2: mul large * large (known result) ===
    # 0x100000000 * 0x100000000 = 0x0000000000000000 (overflow)
    movi r3, 0x10000000
    shli r3, r3, 32    # r3 = 0x1000000000000000
    movi r4, 0x10000000
    shli r4, r4, 32    # r4 = 0x1000000000000000
    mul r3, r3, r4     # overflow, low 64 bits = 0
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 2

    # === Test 3: mul by zero ===
    movi r3, 0x7FFFFFFFFFFFFFFF
    mov r4, 0
    mul r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 3

    # === Test 4: mul by one ===
    movi r3, 0x1234567890ABCDEF
    mov r4, 1
    mul r3, r3, r4
    movi r5, 0x1234567890ABCDEF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 4

    # === Test 5: mul negative * positive ===
    mov r3, 100
    sub r3, r0, r3    # r3 = -100
    mov r4, 50
    mul r3, r3, r4     # -100 * 50 = -5000
    mov r5, 5000
    sub r5, r0, r5    # r5 = -5000
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: mul negative * negative ===
    mov r3, 100
    sub r3, r0, r3    # r3 = -100
    mov r4, 50
    sub r4, r0, r4    # r4 = -50
    mul r3, r3, r4     # -100 * -50 = 5000
    mov r5, 5000
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === Test 7: mul power of two ===
    mov r3, 1
    mov r4, 35
    shl r3, r3, r4    # r3 = 1 << 35 = 0x800000000
    mov r4, 8
    mul r3, r3, r4     # (1<<35) * 8 = 1 << 38 = 0x4000000000
    mov r5, 3
    shli r5, r5, 38    # Actually can't do this directly, use movi+shli
    # Let's compute: 1 << 38 = 0x4000000000
    mov r5, 1
    mov r6, 38
    shl r5, r5, r6    # r5 = 1 << 38 = 0x4000000000
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 7

    # === Test 8: mul max positive * 2 ===
    # 0x7FFFFFFFFFFFFFFF * 2 = 0xFFFFFFFFFFFFFFFE
    movi r3, 0x7FFFFFFF
    shli r3, r3, 32
    movi r6, 0xFFFFFFFF
    add r3, r3, r6    # r3 = 0x7FFFFFFFFFFFFFFF
    mov r4, 2
    mul r3, r3, r4
    movi r5, 0xFFFFFFFE
    movi r6, 0xFFFFFFFF
    shli r6, r6, 32
    add r5, r5, r6    # r5 = 0xFFFFFFFFFFFFFFFE
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 8

    # === Test 9: mul with large multiplier ===
    # 0xFFFF * 0x10000 = 0xFFFF0000
    movi r3, 0xFFFF
    movi r4, 0x10000
    mul r3, r3, r4
    movi r5, 0xFFFF0000
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 9

    # === Test 10: mul commutative property ===
    # a * b == b * a
    movi r3, 0x12345678
    movi r4, 0x9ABCDEF0
    mul r5, r3, r4
    mul r6, r4, r3
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 10

    # === Test 11: muli edge case — max 14-bit immediate ===
    mov r3, 100
    muli r3, r3, 8191   # 100 * 8191 = 819100
    movi r5, 819100
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 11

    # === Test 12: muli with negative min 14-bit ===
    mov r3, 10
    muli r3, r3, -8192  # 10 * -8192 = -81920
    movi r5, 81920
    sub r5, r0, r5
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 12

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0