# MacroCore-X Fence/Memory Barrier Comprehensive Test
# Tests all fence variants: full fence, store-store, load-load, load-store
# Also tests xchg/cmpxchg implicit barriers

    # R10 = pass counter
    mov r10, 0

    # === Test 1: fence (full barrier, PI=0xF, PO=0xF) ===
    fence
    mov r5, 1
    add r10, r10, r5  # R10 = 1

    # === Test 2: fence with explicit PI/PO (full barrier) ===
    fence 0xF, 0xF
    add r10, r10, r5  # R10 = 2

    # === Test 3: fence w, w (store-store barrier, PI=0x2, PO=0x2) ===
    fence 0x2, 0x2
    add r10, r10, r5  # R10 = 3

    # === Test 4: fence r, r (load-load barrier, PI=0x1, PO=0x1) ===
    fence 0x1, 0x1
    add r10, r10, r5  # R10 = 4

    # === Test 5: fence rw, rw (load+store barrier, PI=0x3, PO=0x3) ===
    fence 0x3, 0x3
    add r10, r10, r5  # R10 = 5

    # === Test 6: fence before store ===
    movi r2, 0x3000
    movi r3, 0xDEADBEEFCAFEBABE
    st r3, [r2 + 0]
    fence
    st r3, [r2 + 8]
    ld r4, [r2 + 0]
    ld r5, [r2 + 8]
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 6

    # === Test 7: fence between load and store ===
    movi r3, 0xAAAAAAAAAAAAAAAA
    st r3, [r2 + 16]
    ld r4, [r2 + 16]
    fence 0x3, 0x3
    movi r3, 0xBBBBBBBBBBBBBBBB
    st r3, [r2 + 24]
    ld r4, [r2 + 24]
    movi r5, 0xBBBBBBBBBBBBBBBB
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 7

    # === Test 8: Multiple fences in sequence ===
    fence
    fence 0x2, 0x2
    fence 0x1, 0x1
    fence 0x3, 0x3
    add r10, r10, r5  # R10 = 8

    # === Test 9: xchg implicit barrier followed by load ===
    movi r3, 0x1111
    st r3, [r2 + 32]
    movi r4, 0x2222
    xchg r4, [r2 + 32]    # implicit full barrier
    ld r5, [r2 + 32]
    movi r6, 0x2222
    eq r6, r5, r6
    add r10, r10, r6  # R10 = 9

    # === Test 10: cmpxchg implicit barrier ===
    movi r3, 0xCCCC
    st r3, [r2 + 40]
    movi r4, 0xCCCC
    movi r5, 0xDDDD
    cmpxchg r4, r5, [r2 + 40]   # implicit full barrier
    ld r5, [r2 + 40]
    movi r6, 0xDDDD
    eq r6, r5, r6
    add r10, r10, r6  # R10 = 10

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0