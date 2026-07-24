# MacroCore-X Atomic Operations Test
# Tests cmpxchg-based lock-free atomic increment
# Uses R0-R15 only for C-type instructions

    # R10 = pass counter
    mov r10, 0

    # R2 = shared data buffer
    movi r2, 0x3000

    # === Test 1: cmpxchg loop for atomic increment ===
    # Initialize counter to 0
    mov r3, 0
    st r3, [r2 + 0]

    # Atomic increment loop (simulate 5 increments)
    mov r6, 5           # loop counter
atomic_inc_loop:
    ld r3, [r2 + 0]     # load current value
    mov r4, 0
    add r4, r3, r0      # r4 = expected = current
    addi r5, r3, 1      # r5 = new = current + 1
    cmpxchg r4, r5, [r2 + 0]  # if Mem==r4, Mem=r5
    subi r6, r6, 1
    mov r7, 0
    bne r6, r7, atomic_inc_loop

    # Verify counter = 5
    ld r3, [r2 + 0]
    mov r5, 5
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: cmpxchg atomic swap ===
    movi r3, 0xAAAA
    st r3, [r2 + 8]
    movi r4, 0xAAAA    # expected
    movi r5, 0xBBBB    # new value
    cmpxchg r4, r5, [r2 + 8]
    ld r3, [r2 + 8]
    movi r5, 0xBBBB
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: cmpxchg fails on mismatch ===
    movi r3, 0xCCCC
    st r3, [r2 + 16]
    movi r4, 0xDDDD    # expected (doesn't match)
    movi r5, 0xEEEE    # new value (should NOT be written)
    cmpxchg r4, r5, [r2 + 16]
    ld r3, [r2 + 16]
    movi r5, 0xCCCC    # should still be 0xCCCC
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: xchg as atomic swap ===
    movi r3, 0x1111
    st r3, [r2 + 24]
    movi r4, 0x2222
    xchg r4, [r2 + 24]
    # r4 should now be 0x1111, mem should be 0x2222
    movi r5, 0x1111
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    ld r3, [r2 + 24]
    movi r5, 0x2222
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 5

    # === Test 5: addm as non-atomic read-modify-write ===
    movi r3, 100
    st r3, [r2 + 32]
    mov r4, 25
    addm r4, [r2 + 32]
    ld r3, [r2 + 32]
    mov r5, 125
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === Test 6: subm as non-atomic read-modify-write ===
    movi r3, 200
    st r3, [r2 + 40]
    mov r4, 50
    subm r4, [r2 + 40]
    ld r3, [r2 + 40]
    mov r5, 150
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 7

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0