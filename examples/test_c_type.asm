# MacroCore-X C-type Composite Instructions Test
# Tests addm, subm, xchg, cmpxchg, push, pop, enter, leave

    # R10 = pass counter
    mov r10, 0

    # R2 = data buffer address
    movi r2, 0x3000

    # === Test addm: Mem[addr] += R[rs1] ===
    movi r3, 100
    st r3, [r2 + 0]
    mov r4, 50
    addm r4, [r2 + 0]
    ld r5, [r2 + 0]
    mov r6, 150
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 1

    # === Test subm: Mem[addr] -= R[rs1] ===
    movi r3, 200
    st r3, [r2 + 8]
    mov r4, 30
    subm r4, [r2 + 8]
    ld r5, [r2 + 8]
    mov r6, 170
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 2

    # === Test xchg: swap R[rs1] <-> Mem[addr] ===
    movi r3, 0xAAAA
    st r3, [r2 + 16]
    movi r4, 0xBBBB
    xchg r4, [r2 + 16]
    # Now R4 should be 0xAAAA, Mem should be 0xBBBB
    movi r5, 0xAAAA
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 3

    ld r6, [r2 + 16]
    movi r5, 0xBBBB
    eq r5, r6, r5
    add r10, r10, r5  # R10 = 4

    # === Test cmpxchg: if Mem == R[rs1], Mem = R[rs2] ===
    movi r3, 0xCCCC
    st r3, [r2 + 24]
    movi r4, 0xCCCC   # expected value (matches)
    movi r5, 0xDDDD   # new value
    cmpxchg r4, r5, [r2 + 24]
    ld r6, [r2 + 24]
    movi r7, 0xDDDD
    eq r7, r6, r7
    add r10, r10, r7  # R10 = 5

    # cmpxchg: no match -> no write
    st r3, [r2 + 32]     # Mem = 0xCCCC again
    movi r4, 0xEEEE      # expected (does NOT match 0xCCCC)
    movi r5, 0xFFFF      # new value (should NOT be written)
    cmpxchg r4, r5, [r2 + 32]
    ld r6, [r2 + 32]
    movi r7, 0xCCCC
    eq r7, r6, r7
    add r10, r10, r7  # R10 = 6

    # === Test push / pop ===
    movi r3, 0x123456789ABCDEF0
    push r3
    mov r3, 0
    pop r3
    movi r4, 0x123456789ABCDEF0
    eq r4, r3, r4
    add r10, r10, r4  # R10 = 7

    # Push multiple and pop in reverse order
    movi r8, 0x1111
    movi r9, 0x2222
    push r8
    push r9
    pop r3
    pop r4
    movi r5, 0x2222
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 8
    movi r5, 0x1111
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 9

    # === Test enter / leave ===
    # Save current SP (R2) and set up frame
    movi r2, 0x4000       # set SP to a known area
    add r30, r0, r2       # R30 = frame pointer = SP
    enter 32              # SP -= 32, Mem[SP] = old R30
    # Now SP = 0x4000 - 32 = 0x3FE0
    movi r5, 0x3FE0
    eq r5, r2, r5
    add r10, r10, r5  # R10 = 10

    leave
    # SP restored to R30+8, R30 restored from frame
    movi r5, 0x4008
    eq r5, r2, r5
    add r10, r10, r5  # R10 = 11

    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0