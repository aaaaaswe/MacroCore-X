# MacroCore-X memcpy Benchmark
# Copies a block of memory using a simple loop
# Tests memory throughput, loop efficiency, and ld/st correctness

    # R10 = pass counter
    mov r10, 0

    # R2 = source address
    movi r2, 0x2000
    # R3 = destination address
    movi r3, 0x3000

    # === Initialize source data with pattern ===
    mov r4, 0

fill_loop:
    mov r5, 64
    bge r4, r5, fill_done

    # Store value = 0x100000000 + index
    movi r6, 0x10000000
    shli r6, r6, 32
    add r6, r6, r4

    # Compute offset: r4 * 8
    mov r7, 0
    add r7, r7, r4
    shli r7, r7, 3
    add r7, r7, r2       # r7 = source + offset
    st r6, [r7 + 0]

    addi r4, r4, 1
    j fill_loop

fill_done:
    # === memcpy: copy 64 qwords (512 bytes) from source to dest ===
    mov r4, 0

copy_loop:
    mov r5, 64
    bge r4, r5, copy_done

    # Compute offset
    mov r6, 0
    add r6, r6, r4
    shli r6, r6, 3

    # Load from source, store to dest
    mov r7, 0
    add r7, r7, r2
    add r7, r7, r6
    ld r8, [r7 + 0]

    mov r9, 0
    add r9, r9, r3
    add r9, r9, r6
    st r8, [r9 + 0]

    addi r4, r4, 1
    j copy_loop

copy_done:
    # === Verify copy: check all 64 entries ===
    mov r4, 0

verify_loop:
    mov r5, 64
    bge r4, r5, verify_done

    # Compute expected value
    movi r6, 0x10000000
    shli r6, r6, 32
    add r6, r6, r4

    # Load from dest
    mov r7, 0
    add r7, r7, r4
    shli r7, r7, 3
    mov r8, 0
    add r8, r8, r3
    add r8, r8, r7
    ld r9, [r8 + 0]

    eq r5, r6, r9
    add r10, r10, r5

    addi r4, r4, 1
    j verify_loop

verify_done:
    # R10 should be 64 (all entries matched)

    # === Test memcpy with overlap (non-overlapping regions) ===
    # Copy from 0x2000 to 0x2000+64*8 = 0x2200
    movi r3, 0x2200
    mov r4, 0

copy2_loop:
    mov r5, 16
    bge r4, r5, copy2_done

    mov r6, 0
    add r6, r6, r4
    shli r6, r6, 3

    mov r7, 0
    add r7, r7, r2
    add r7, r7, r6
    ld r8, [r7 + 0]

    mov r9, 0
    add r9, r9, r3
    add r9, r9, r6
    st r8, [r9 + 0]

    addi r4, r4, 1
    j copy2_loop

copy2_done:
    # Verify first 16 entries at 0x2200
    mov r4, 0

verify2_loop:
    mov r5, 16
    bge r4, r5, verify2_done

    movi r6, 0x10000000
    shli r6, r6, 32
    add r6, r6, r4

    mov r7, 0
    add r7, r7, r4
    shli r7, r7, 3
    mov r8, 0
    add r8, r8, r3
    add r8, r8, r7
    ld r9, [r8 + 0]

    eq r5, r6, r9
    add r10, r10, r5

    addi r4, r4, 1
    j verify2_loop

verify2_done:
    # R10 should be 64 + 16 = 80

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0