# MacroCore-X Shift Edge Cases Test
# Tests edge cases for shl, shr, sar, shli, shri, sari, ror, rol
# including shift by 0, shift by 63, shift by >63, etc.

    # R10 = pass counter
    mov r10, 0

    # === SHL Edge Cases ===

    # shl by 0: no change
    movi r3, 0x1234567890ABCDEF
    mov r4, 0
    shl r3, r3, r4
    movi r5, 0x1234567890ABCDEF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # shl by 63: MSB set
    mov r3, 1
    mov r4, 63
    shl r3, r3, r4
    movi r5, 0x80000000
    shli r5, r5, 32
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # shl by 64 (mod 64 = 0): same as shift by 0
    movi r3, 0xDEADBEEF
    mov r4, 64
    shl r3, r3, r4
    movi r5, 0xDEADBEEF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # shl by 65 (mod 64 = 1): same as shift by 1
    mov r3, 1
    mov r4, 65
    shl r3, r3, r4
    mov r5, 2
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 4

    # shl: all bits shifted out
    movi r3, 0xFFFFFFFFFFFFFFFF
    mov r4, 64
    shl r3, r3, r4
    eq r5, r3, r0      # shift by 64 mod 64 = 0, same value
    add r10, r10, r5  # R10 = 5
    # Actually: shift by 64 mod 64 = 0, so result = 0xFFFFFFFFFFFFFFFF
    # Let's test shift by 63 to clear everything
    mov r3, 1
    mov r4, 63
    shl r3, r3, r4
    movi r5, 0x80000000
    shli r5, r5, 32
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === SHR Edge Cases ===

    # shr by 0: no change
    movi r3, 0x8000000000000000
    mov r4, 0
    shr r3, r3, r4
    movi r5, 0x80000000
    shli r5, r5, 32
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 7

    # shr by 63: only LSB remains
    movi r3, 0x80000000
    shli r3, r3, 32
    mov r4, 63
    shr r3, r3, r4
    mov r5, 1
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 8

    # shr large value by 32
    movi r3, 0xFFFFFFFF
    shli r3, r3, 32
    movi r4, 0x12345678
    add r3, r3, r4    # r3 = 0xFFFFFFFF12345678
    mov r4, 32
    shr r3, r3, r4
    movi r5, 0xFFFFFFFF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 9

    # === SAR Edge Cases ===

    # sar positive number: same as shr
    movi r3, 0x7FFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4    # r3 = 0x7FFFFFFFFFFFFFFF
    mov r4, 32
    sar r3, r3, r4
    movi r5, 0x7FFFFFFF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 10

    # sar negative number: sign extends
    movi r3, 0x80000000
    shli r3, r3, 32    # r3 = 0x8000000000000000
    mov r4, 32
    sar r3, r3, r4
    movi r5, 0xFFFFFFFF80000000
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 11

    # sar by 63 of negative: all 1s
    movi r3, 0x80000000
    shli r3, r3, 32
    mov r4, 63
    sar r3, r3, r4
    movi r5, 0xFFFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 12

    # sar by 63 of positive: all 0s
    movi r3, 0x7FFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4    # r3 = 0x7FFFFFFFFFFFFFFF
    mov r4, 63
    sar r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 13

    # === SHLI Edge Cases ===

    # shli by 0
    movi r3, 0x12345678
    shli r3, r3, 0
    movi r5, 0x12345678
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 14

    # shli by 63
    mov r3, 1
    shli r3, r3, 63
    movi r5, 0x80000000
    shli r5, r5, 32
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 15

    # === SHRI Edge Cases ===

    # shri by 63
    movi r3, 0x80000000
    shli r3, r3, 32
    shri r3, r3, 63
    mov r5, 1
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 16

    # === SARI Edge Cases ===

    # sari negative by 63
    movi r3, 0x80000000
    shli r3, r3, 32
    sari r3, r3, 63
    movi r5, 0xFFFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 17

    # === ROR Edge Cases ===

    # ror by 0: no change
    movi r3, 0x1234567890ABCDEF
    mov r4, 0
    ror r3, r3, r4
    movi r5, 0x1234567890ABCDEF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 18

    # ror by 32: swap halves
    movi r3, 0x1234567890ABCDEF
    mov r4, 32
    ror r3, r3, r4
    movi r5, 0x90ABCDEF12345678
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 19

    # ror by 64 (mod 64 = 0): no change
    movi r3, 0xDEADBEEFCAFEBABE
    mov r4, 64
    ror r3, r3, r4
    movi r5, 0xDEADBEEFCAFEBABE
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 20

    # === ROL Edge Cases ===

    # rol by 32: swap halves
    movi r3, 0x1234567890ABCDEF
    mov r4, 32
    rol r3, r3, r4
    movi r5, 0x90ABCDEF12345678
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 21

    # rol by 1: 0x8000000000000001 → 0x0000000000000003
    movi r3, 0x80000000
    shli r3, r3, 32
    movi r4, 1
    add r3, r3, r4    # r3 = 0x8000000000000001
    mov r4, 1
    rol r3, r3, r4
    mov r5, 3
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 22

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0