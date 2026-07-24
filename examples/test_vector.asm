# MacroCore-X Vector Instructions Test
# Tests V-type instructions: vadd, vsub, vmul, vand, vor, vxor,
# vld, vst, vshl, vshr, vshuffle, vfmadd

    # R10 = pass counter
    mov r10, 0

    # R2 = buffer address for vector data
    movi r2, 0x2000

    # === Test vadd ===
    movi r3, 100
    movi r4, 50
    # Load values into V registers (using simplified scalar-like storage)
    st r3, [r2 + 0]
    st r4, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vadd v2, v0, v1
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 150
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 1

    # === Test vsub ===
    movi r3, 200
    movi r4, 30
    st r3, [r2 + 0]
    st r4, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vsub v2, v0, v1
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 170
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 2

    # === Test vmul ===
    mov r3, 6
    mov r4, 7
    st r3, [r2 + 0]
    st r4, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vmul v2, v0, v1
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 42
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 3

    # === Test vand ===
    movi r3, 0xFF
    movi r4, 0x0F
    st r3, [r2 + 0]
    st r4, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vand v2, v0, v1
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 0x0F
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 4

    # === Test vor ===
    movi r3, 0x10
    movi r4, 0x01
    st r3, [r2 + 0]
    st r4, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vor v2, v0, v1
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 0x11
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 5

    # === Test vxor ===
    movi r3, 0xFF
    movi r4, 0x0F
    st r3, [r2 + 0]
    st r4, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vxor v2, v0, v1
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 0xF0
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 6

    # === Test vshl ===
    mov r3, 1
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vshl v2, v0, 4    # 1 << 4 = 16
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 16
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 7

    # === Test vshr ===
    mov r3, 128
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vshr v2, v0, 3    # 128 >> 3 = 16
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    mov r6, 16
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 8

    # === Test vshuffle ===
    movi r3, 0x0102030405060708
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vshuffle v2, v0, 0  # identity shuffle
    vst v2, [r2 + 16]
    ld r5, [r2 + 16]
    movi r6, 0x0102030405060708
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 9

    # === Test vfmadd ===
    mov r3, 2
    st r3, [r2 + 0]
    mov r3, 3
    st r3, [r2 + 8]
    mov r3, 4
    st r3, [r2 + 16]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vld v2, [r2 + 16]
    vfmadd v3, v0, v1, v2  # 2*3 + 4 = 10
    vst v3, [r2 + 32]
    ld r5, [r2 + 32]
    mov r6, 10
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 10

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0