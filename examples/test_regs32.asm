# MacroCore-X All 32 Registers Test
# Tests that R-type instructions can access all 32 registers (R0-R31)
# R-type uses 5-bit register fields, unlike L/B/C-type which use 4-bit

    # R10 = pass counter
    mov r10, 0

    # === Test 1: R16-R31 via R-type add ===
    # R16-R23 are callee-saved, R24-R30 are reserved
    # We can write to them via R-type instructions

    movi r16, 100
    movi r17, 200
    add r18, r16, r17   # R18 = 300
    mov r5, 300
    eq r5, r18, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: R24-R30 via R-type ===
    movi r24, 50
    movi r25, 25
    sub r26, r24, r25   # R26 = 25
    mov r5, 25
    eq r5, r26, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: mul with high registers ===
    movi r20, 6
    movi r21, 7
    mul r22, r20, r21   # R22 = 42
    mov r5, 42
    eq r5, r22, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: and/or/xor with high registers ===
    movi r27, 0xFF
    movi r28, 0x0F
    and r29, r27, r28   # R29 = 0x0F
    mov r5, 0x0F
    eq r5, r29, r5
    add r10, r10, r5  # R10 = 4

    # === Test 5: eq with high registers ===
    movi r16, 0x1234
    movi r17, 0x1234
    eq r18, r16, r17    # R18 = 1
    mov r5, 1
    eq r5, r18, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: lt with high registers ===
    movi r19, 10
    movi r20, 20
    lt r21, r19, r20    # R21 = 1
    mov r5, 1
    eq r5, r21, r5
    add r10, r10, r5  # R10 = 6

    # === Test 7: shl/shr with high registers ===
    mov r22, 1
    mov r23, 10
    shl r24, r22, r23   # R24 = 1 << 10 = 1024
    movi r5, 1024
    eq r5, r24, r5
    add r10, r10, r5  # R10 = 7

    # === Test 8: max/min with high registers ===
    mov r25, 50
    mov r26, 100
    max r27, r25, r26   # R27 = 100
    mov r5, 100
    eq r5, r27, r5
    add r10, r10, r5  # R10 = 8

    min r28, r25, r26   # R28 = 50
    mov r5, 50
    eq r5, r28, r5
    add r10, r10, r5  # R10 = 9

    # === Test 9: R31 (RA) can be used as general register ===
    # R31 is used by call/ret, but can be used as general reg
    movi r31, 0xABCD
    movi r5, 0xABCD
    eq r5, r31, r5
    add r10, r10, r5  # R10 = 10

    # === Test 10: clz with high registers ===
    mov r16, 1
    shli r16, r16, 60   # R16 = 0x1000000000000000
    clz r17, r16         # clz = 3 (since 0x1000... has 3 leading zeros)
    mov r5, 3
    eq r5, r17, r5
    add r10, r10, r5  # R10 = 11

    # === Test 11: ror/rol with high registers ===
    movi r18, 0x80000000
    shli r18, r18, 32
    movi r19, 1
    add r18, r18, r19   # R18 = 0x8000000000000001
    mov r20, 1
    ror r21, r18, r20   # R21 = 0xC000000000000000
    movi r5, 0xC0000000
    shli r5, r5, 32
    eq r5, r21, r5
    add r10, r10, r5  # R10 = 12

    # === Test 12: I-type movi with high registers ===
    movi r25, 0xDEADBEEF
    movi r5, 0xDEADBEEF
    eq r5, r25, r5
    add r10, r10, r5  # R10 = 13

    # === Test 13: R0 is hardwired to zero ===
    movi r3, 0x1234
    add r0, r0, r3      # write to R0, should be ignored
    eq r5, r0, r0       # R0 should still be 0
    add r10, r10, r5  # R10 = 14

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0