# MacroCore-X Software Interrupt Test
# Tests int (software interrupt) and iret (return from interrupt)
# Requires setting up exception vector table at 0x1000

    # R10 = pass counter
    mov r10, 0

    # === Set up exception vector table at 0x1000 ===
    # Vector 0x10 (software interrupt, vector 16): handler at 0x1040
    # Each vector entry is 8 bytes: jump to handler
    # We'll write the handler code directly

    # Handler code at 0x1080 (vector 0x10 entry):
    # handler: movi r3, 0x1234; add r10, r10, r3; iret
    mov r2, 0x1080

    # movi r3, 0x1234 → 6 bytes: 0x2A, 0x18, 0x34, 0x12, 0x00, 0x00
    movi r3, 0x2A
    stb r3, [r2 + 0]
    movi r3, 0x18
    stb r3, [r2 + 1]
    movi r3, 0x34
    stb r3, [r2 + 2]
    movi r3, 0x12
    stb r3, [r2 + 3]
    stb r0, [r2 + 4]
    stb r0, [r2 + 5]

    # add r10, r10, r3 → 4 bytes (R-type)
    # Rd=R10, Rs1=R10, Rs2=R3
    # byte0=0x00, byte1=(10<<3)|(10>>2)=0x52, byte2=((10&3)<<6)|(3<<1)|0=0xC6, byte3=0
    movi r3, 0x00
    stb r3, [r2 + 6]
    movi r3, 0x52
    stb r3, [r2 + 7]
    movi r3, 0xC6
    stb r3, [r2 + 8]
    stb r0, [r2 + 9]

    # iret → 2 bytes: 0xB3, 0x00
    movi r3, 0xB3
    stb r3, [r2 + 10]
    stb r0, [r2 + 11]

    # Set vector table entry: vector 0x10 at offset 0x10*8 = 0x80 from base
    # Write j instruction to handler: j 0x1080
    movi r2, 0x1000
    movi r3, 0x1080
    # PC at 0x1080, so j offset = 0x1080 - 0x1080 = 0
    # j encoding: byte0=0x60, byte1-3=imm20=0
    movi r4, 0x60
    stb r4, [r2 + 128]    # vector 0x10 at 0x1000 + 0x80
    stb r0, [r2 + 129]
    stb r0, [r2 + 130]
    stb r0, [r2 + 131]

    # Set CSR_IVEC to 0x1000 (exception vector table base)
    movi r3, 0x1000
    wrmsr r3, 0x004

    # === Test 1: Trigger software interrupt vector 0x10 ===
    # The handler adds 0x1234 to R10 and returns via iret
    movi r3, 0x1234    # expected value
    int 0x10
    # After iret, R10 should be 0x1234
    movi r5, 0x1234
    eq r5, r10, r5
    add r10, r10, r5  # R10 = 0x1234 + 1 = 0x1235

    # === Test 2: Trigger int 0x10 again (second interrupt) ===
    int 0x10
    # R10 should now be 0x1234 + 0x1234 + 1 = 0x2469
    movi r5, 0x2469
    eq r5, r10, r5
    mov r10, 0
    add r10, r10, r5  # R10 = 1 if passed

    # === Test 3: Set up a second handler (vector 0x11) ===
    # Handler at 0x10C0: adds 0x5678 to R10
    mov r2, 0x10C0

    # movi r3, 0x5678
    movi r3, 0x2A
    stb r3, [r2 + 0]
    movi r3, 0x18
    stb r3, [r2 + 1]
    movi r3, 0x78
    stb r3, [r2 + 2]
    movi r3, 0x56
    stb r3, [r2 + 3]
    stb r0, [r2 + 4]
    stb r0, [r2 + 5]

    # add r10, r10, r3
    movi r3, 0x00
    stb r3, [r2 + 6]
    movi r3, 0x52
    stb r3, [r2 + 7]
    movi r3, 0xC6
    stb r3, [r2 + 8]
    stb r0, [r2 + 9]

    # iret
    movi r3, 0xB3
    stb r3, [r2 + 10]
    stb r0, [r2 + 11]

    # Set vector 0x11 entry at 0x1000 + 0x11*8 = 0x1088
    movi r2, 0x1000
    # j 0x10C0: PC at 0x1088, offset = 0x10C0 - 0x1088 = 0x38
    # imm20 = 0x38 >> 2 = 0x0E
    movi r4, 0x60
    stb r4, [r2 + 136]    # 0x1000 + 0x88
    # byte1 = imm20[19:12] = 0
    stb r0, [r2 + 137]
    # byte2 = imm20[7:0] = 0x0E
    movi r4, 0x0E
    stb r4, [r2 + 138]
    # byte3 = imm20[11:8] = 0
    stb r0, [r2 + 139]

    # Trigger vector 0x11
    int 0x11
    # R10 should be 1 + 0x5678 = 0x5679
    movi r5, 0x5679
    eq r5, r10, r5
    mov r10, 0
    add r10, r10, r5  # R10 = 1 if passed

    # === Test 4: Trigger vector 0x10 again ===
    int 0x10
    # R10 should be 1 + 0x1234 = 0x1235
    movi r5, 0x1235
    eq r5, r10, r5
    mov r10, 0
    add r10, r10, r5  # R10 = 1 if passed

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0