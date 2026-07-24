# MacroCore-X Memory Operations Test
# Tests all load/store instructions: ld, st, stw, stb, ldu, lds, lda

    # R2 = base address for data
    movi r2, 0x2000

    # === Test st / ld (64-bit store/load) ===
    movi r3, 0xDEADBEEFCAFEBABE
    st r3, [r2 + 0]
    ld r4, [r2 + 0]
    # R4 should equal R3
    eq r5, r3, r4
    # R10 = pass count
    mov r10, 0
    add r10, r10, r5  # R10 = 1 if passed

    # === Test stw / ldu (32-bit store, zero-extend load) ===
    movi r3, 0x12345678
    stw r3, [r2 + 8]
    ldu r4, [r2 + 8]
    # R4 should be 0x0000000012345678
    movi r5, 0x12345678
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 2 if passed

    # === Test stw / lds (32-bit store, sign-extend negative load) ===
    movi r3, 0xFFFFFFFF80000000  # negative 32-bit value
    stw r3, [r2 + 16]
    lds r4, [r2 + 16]
    # R4 should be sign-extended: 0xFFFFFFFF80000000
    movi r6, 0xFFFFFFFF80000000
    # Use r6 for comparison
    eq r5, r4, r6
    add r10, r10, r5  # R10 = 3 if passed

    # === Test stb (8-bit store) and reload ===
    movi r3, 0xAB
    stb r3, [r2 + 24]
    ld r4, [r2 + 24]
    andi r4, r4, 0xFF   # mask to 8 bits
    movi r5, 0xAB
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4 if passed

    # === Test lda (load effective address with scale) ===
    movi r6, 0x2000
    lda r4, r0, r6, 1  # R4 = R0 + R6*1 = 0x2000
    eq r5, r4, r6
    add r10, r10, r5  # R10 = 5 if passed

    # lda with scale=4: R4 = R3 + R3*4 = 100 + 400 = 500
    mov r3, 100
    lda r4, r3, r3, 4
    mov r6, 500
    eq r5, r4, r6
    add r10, r10, r5  # R10 = 6 if passed

    # lda with scale=8: R4 = R3 + R3*8 = 100 + 800 = 900
    lda r4, r3, r3, 8
    mov r6, 900
    eq r5, r4, r6
    add r10, r10, r5  # R10 = 7 if passed

    # === Test overlapping ld/st ===
    movi r3, 0xAAAAAAAAAAAAAAAA
    st r3, [r2 + 64]
    stw r0, [r2 + 64]     # zero out low 32 bits
    ld r4, [r2 + 64]
    movi r6, 0xAAAAAAAA00000000
    eq r5, r4, r6
    add r10, r10, r5  # R10 = 8 if passed

    # === Test multiple stores and loads ===
    movi r3, 0x1111111111111111
    movi r4, 0x2222222222222222
    st r3, [r2 + 80]
    st r4, [r2 + 88]
    ld r5, [r2 + 80]
    ld r6, [r2 + 88]
    movi r7, 0x1111111111111111
    eq r7, r5, r7
    add r10, r10, r7  # R10 = 9 if passed
    movi r7, 0x2222222222222222
    eq r7, r6, r7
    add r10, r10, r7  # R10 = 10 if passed

    # === Test stw partial write + ld reload ===
    movi r3, 0xFFFFFFFFFFFFFFFF
    st r3, [r2 + 96]
    movi r3, 0x00000000
    stw r3, [r2 + 96]    # write zeros to low 32 bits
    ld r4, [r2 + 96]
    movi r6, 0xFFFFFFFF00000000
    eq r5, r4, r6
    add r10, r10, r5  # R10 = 11 if passed

    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0