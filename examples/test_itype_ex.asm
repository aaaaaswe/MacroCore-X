# MacroCore-X Extended I-type Test
# Tests untested I-type instructions: muli, sari

    # R10 = pass counter
    mov r10, 0

    # === Test muli: multiply by immediate ===
    mov r3, 10
    muli r3, r3, 5    # 10 * 5 = 50
    mov r5, 50
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # === Test muli: multiply by negative ===
    mov r3, 7
    muli r3, r3, -3   # 7 * -3 = -21
    mov r5, 21
    sub r5, r0, r5    # -21
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # === Test muli: multiply by zero ===
    movi r3, 12345
    muli r3, r3, 0
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 3

    # === Test muli: large immediate ===
    mov r3, 100
    muli r3, r3, 100  # 100 * 100 = 10000
    movi r5, 10000
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 4

    # === Test muli: negative * negative ===
    mov r3, 5
    sub r3, r0, r3    # -5
    muli r3, r3, -2   # -5 * -2 = 10
    mov r5, 10
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 5

    # === Test sari: arithmetic shift right immediate ===
    mov r3, 16
    sub r3, r0, r3    # r3 = -16 (0xFFFFFFFFFFFFFFF0)
    sari r3, r3, 2    # -16 >> 2 = -4
    mov r5, 4
    sub r5, r0, r5    # -4
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === Test sari: positive ===
    mov r3, 128
    sari r3, r3, 4    # 128 >> 4 = 8
    mov r5, 8
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 7

    # === Test sari: shift by 0 ===
    mov r3, 42
    sari r3, r3, 0
    mov r5, 42
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 8

    # === Test sari: large negative number ===
    movi r3, 0x80000000
    shli r3, r3, 32   # r3 = 0x8000000000000000
    sari r3, r3, 63   # 0x8000000000000000 >> 63 = 0xFFFFFFFFFFFFFFFF
    movi r5, 0xFFFFFFFF
    shli r5, r5, 32
    movi r6, 0xFFFFFFFF
    add r5, r5, r6    # 0xFFFFFFFFFFFFFFFF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 9

    # === Test sari: max shift (63) on normal value ===
    mov r3, 1
    sari r3, r3, 63   # 1 >> 63 = 0
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 10

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0