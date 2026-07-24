# MacroCore-X Extended R-type Test
# Tests untested R-type instructions: sar, lt, ltu, max, min, ror, rol, clz

    # R10 = pass counter
    mov r10, 0

    # === Test sar (arithmetic shift right) ===
    # sar -16 by 2 → -4
    mov r3, 16
    sub r3, r0, r3    # r3 = -16 (0xFFFFFFFFFFFFFFF0)
    mov r4, 2
    sar r3, r3, r4
    mov r5, 4
    sub r5, r0, r5    # r5 = -4
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # === Test sar: positive value ===
    mov r3, 64
    mov r4, 3
    sar r3, r3, r4    # 64 >> 3 = 8
    mov r5, 8
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # === Test lt (signed less than) ===
    mov r3, 5
    sub r3, r0, r3    # r3 = -5
    mov r4, 10
    lt r5, r3, r4     # -5 < 10 → 1
    mov r6, 1
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 3

    # === Test lt: false case ===
    mov r3, 20
    mov r4, 10
    lt r5, r3, r4     # 20 < 10 → 0
    eq r5, r5, r0
    add r10, r10, r5  # R10 = 4

    # === Test ltu (unsigned less than) ===
    mov r3, 5
    mov r4, 10
    ltu r5, r3, r4    # 5 < 10 → 1
    mov r6, 1
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 5

    # === Test ltu: large unsigned, 0xFFFFFFFF > 10 → false ===
    movi r3, 0xFFFFFFFF
    mov r4, 10
    ltu r5, r3, r4    # 0xFFFFFFFF < 10 → 0
    eq r5, r5, r0
    add r10, r10, r5  # R10 = 6

    # === Test max (signed) ===
    mov r3, 10
    sub r3, r0, r3    # r3 = -10
    mov r4, 5
    max r5, r3, r4    # max(-10, 5) = 5
    eq r5, r5, r4
    add r10, r10, r5  # R10 = 7

    # === Test max: both negative ===
    mov r3, 50
    sub r3, r0, r3    # r3 = -50
    mov r4, 10
    sub r4, r0, r4    # r4 = -10
    max r5, r3, r4    # max(-50, -10) = -10
    eq r5, r5, r4
    add r10, r10, r5  # R10 = 8

    # === Test min (signed) ===
    mov r3, 10
    sub r3, r0, r3    # r3 = -10
    mov r4, 5
    min r5, r3, r4    # min(-10, 5) = -10
    eq r5, r5, r3
    add r10, r10, r5  # R10 = 9

    # === Test min: positive numbers ===
    mov r3, 100
    mov r4, 50
    min r5, r3, r4    # min(100, 50) = 50
    eq r5, r5, r4
    add r10, r10, r5  # R10 = 10

    # === Test ror (rotate right) ===
    # Build 0x8000000000000001: high=0x80000000, low=0x00000001
    movi r3, 0x80000000
    shli r3, r3, 32    # r3 = 0x8000000000000000
    movi r6, 1
    add r3, r3, r6     # r3 = 0x8000000000000001
    mov r4, 1
    ror r5, r3, r4     # rotate right by 1 → 0xC000000000000000
    # Build expected: 0xC000000000000000
    movi r6, 0xC0000000
    shli r6, r6, 32
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 11

    # === Test rol (rotate left) ===
    # Rebuild 0x8000000000000001
    movi r3, 0x80000000
    shli r3, r3, 32
    movi r6, 1
    add r3, r3, r6     # r3 = 0x8000000000000001
    mov r4, 1
    rol r5, r3, r4     # rotate left by 1 → 0x0000000000000003
    mov r6, 3
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 12

    # === Test clz (count leading zeros) ===
    mov r3, 1
    clz r5, r3         # clz(1) = 63
    mov r6, 63
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 13

    # === Test clz: zero → 64 ===
    mov r3, 0
    clz r5, r3         # clz(0) = 64
    mov r6, 64
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 14

    # === Test clz: 0x8000000000000000 → 0 ===
    movi r3, 0x80000000
    shli r3, r3, 32
    clz r5, r3         # clz(0x8000000000000000) = 0
    eq r5, r5, r0
    add r10, r10, r5  # R10 = 15

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0