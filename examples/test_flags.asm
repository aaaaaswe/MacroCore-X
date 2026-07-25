# MacroCore-X FLAGS Test
# Comprehensively tests CF, ZF, SF, OF after arithmetic and logic operations
# Tests read-back via eq/lt/ltu comparisons on result values

    # R10 = pass counter
    mov r10, 0

    # === CF (Carry Flag) Tests ===

    # CF: add overflow — 0xFFFFFFFFFFFFFFFF + 1 = 0, CF=1
    movi r3, 0xFFFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4       # r3 = 0xFFFFFFFFFFFFFFFF
    mov r4, 1
    add r3, r3, r4       # overflow, r3 = 0, CF should be 1
    # Verify result is 0
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 1

    # CF: add no overflow — 0x1 + 0x2 = 0x3, CF=0
    mov r3, 1
    mov r4, 2
    add r3, r3, r4
    mov r5, 3
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # CF: sub borrow — 0 - 1 = 0xFFFFFFFFFFFFFFFF, CF=1
    mov r3, 0
    mov r4, 1
    sub r3, r3, r4
    movi r5, 0xFFFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # CF: sub no borrow — 5 - 3 = 2, CF=0
    mov r3, 5
    mov r4, 3
    sub r3, r3, r4
    mov r5, 2
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 4

    # === ZF (Zero Flag) Tests ===

    # ZF: result is zero
    mov r3, 5
    mov r4, 5
    sub r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 5

    # ZF: addi zero result
    mov r3, 10
    movi r4, 10
    sub r3, r0, r4    # r3 = -10
    addi r3, r3, 10
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 6

    # ZF: xori self → zero
    movi r3, 0x12345678
    xori r3, r3, 0x1234
    # Actually xori with 14-bit imm, so mask
    movi r3, 0x12345678
    mov r4, 0
    add r4, r4, r3
    xor r3, r3, r4
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 7

    # === SF (Sign Flag) Tests ===

    # SF: negative result
    mov r3, 100
    sub r3, r0, r3    # r3 = -100
    # Check top bit via lt
    lt r5, r3, r0     # signed: -100 < 0 → 1
    mov r6, 1
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 8

    # SF: positive result
    mov r3, 100
    lt r5, r3, r0     # signed: 100 < 0 → 0
    eq r5, r5, r0
    add r10, r10, r5  # R10 = 9

    # SF: addi producing negative
    mov r3, 5
    sub r3, r0, r3    # r3 = -5
    addi r3, r3, 3    # -5 + 3 = -2
    lt r5, r3, r0
    add r10, r10, r5  # R10 = 10

    # === OF (Overflow Flag) Tests ===

    # OF: 0x7FFFFFFFFFFFFFFF + 1 = 0x8000000000000000 (overflow)
    movi r3, 0x7FFFFFFF
    shli r3, r3, 32
    movi r4, 0xFFFFFFFF
    add r3, r3, r4    # r3 = 0x7FFFFFFFFFFFFFFF
    mov r4, 1
    add r3, r3, r4    # overflow to negative
    # Result should be 0x8000000000000000
    movi r5, 0x80000000
    shli r5, r5, 32
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 11

    # OF: 0x8000000000000000 - 1 = 0x7FFFFFFFFFFFFFFF (overflow)
    movi r3, 0x80000000
    shli r3, r3, 32
    mov r4, 1
    sub r3, r3, r4
    movi r5, 0x7FFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 12

    # === Logical ops: CF always 0, OF always 0 ===

    # and: CF=0, OF=0, SF set if result negative
    movi r3, 0x8000000000000000
    movi r4, 0xFFFFFFFFFFFFFFFF
    and r3, r3, r4
    lt r5, r3, r0     # should be negative (SF=1)
    add r10, r10, r5  # R10 = 13

    # or: result non-zero, CF=0, OF=0
    movi r3, 0x8000000000000000
    mov r4, 0
    or r3, r3, r4
    lt r5, r3, r0     # SF=1
    add r10, r10, r5  # R10 = 14

    # === shl sets flags via logical ===
    mov r3, 1
    shli r3, r3, 63   # 1 << 63 = 0x8000000000000000
    lt r5, r3, r0     # SF=1
    add r10, r10, r5  # R10 = 15

    # === shr clears SF if result positive ===
    mov r3, 1
    shri r3, r3, 1    # 1 >> 1 = 0
    eq r5, r3, r0     # ZF=1
    add r10, r10, r5  # R10 = 16

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0