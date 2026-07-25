# MacroCore-X LDR/STR Indexed Addressing Test
# Tests ldr and str with indexed addressing mode (R0-R15 only)

    # R10 = pass counter
    mov r10, 0

    # R2 = buffer base address
    movi r2, 0x2000

    # === Test str / ldr with scale=1 ===
    # Fill array with values
    movi r3, 0xAAAAAAAAAAAAAAAA
    st r3, [r2 + 0]
    movi r3, 0xBBBBBBBBBBBBBBBB
    st r3, [r2 + 8]
    movi r3, 0xCCCCCCCCCCCCCCCC
    st r3, [r2 + 16]

    # ldr with r6=0, scale=1, off=0 → loads from r2+0
    mov r6, 0
    ldr r4, [r2 + r6*1 + 0]
    movi r5, 0xAAAAAAAAAAAAAAAA
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 1

    # ldr with r6=1, scale=8, off=0 → loads from r2+8
    mov r6, 1
    ldr r4, [r2 + r6*8 + 0]
    movi r5, 0xBBBBBBBBBBBBBBBB
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 2

    # ldr with r6=2, scale=8, off=0 → loads from r2+16
    mov r6, 2
    ldr r4, [r2 + r6*8 + 0]
    movi r5, 0xCCCCCCCCCCCCCCCC
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 3

    # === Test str with indexed addressing ===
    movi r3, 0xDEADBEEFCAFEBABE
    mov r6, 4
    str r3, [r2 + r6*8 + 0]  # store at r2+32

    # Verify with ldr
    mov r6, 4
    ldr r4, [r2 + r6*8 + 0]
    movi r5, 0xDEADBEEFCAFEBABE
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # === Test ldr with scale=2 ===
    movi r3, 0x1111111111111111
    st r3, [r2 + 64]
    movi r3, 0x2222222222222222
    st r3, [r2 + 72]

    mov r6, 32     # index = 32
    ldr r4, [r2 + r6*2 + 0]  # r2 + 32*2 = r2 + 64
    movi r5, 0x1111111111111111
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === Test ldr with scale=4 ===
    movi r3, 0x3333333333333333
    st r3, [r2 + 80]
    mov r6, 20
    ldr r4, [r2 + r6*4 + 0]  # r2 + 20*4 = r2 + 80
    movi r5, 0x3333333333333333
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 6

    # === Test ldr with offset ===
    movi r3, 0x9876543210ABCDEF
    st r3, [r2 + 100]
    mov r6, 12
    ldr r4, [r2 + r6*8 + 4]  # r2 + 12*8 + 4 = r2 + 100
    movi r5, 0x9876543210ABCDEF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 7

    # === Test str with offset ===
    movi r3, 0xFEDCBA0987654321
    mov r6, 10
    str r3, [r2 + r6*8 + 16]  # r2 + 10*8 + 16 = r2 + 96
    ld r4, [r2 + 96]
    movi r5, 0xFEDCBA0987654321
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 8

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0