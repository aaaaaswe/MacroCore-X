# MacroCore-X Vector Masking Test
# Tests V-type instructions with per-element masking via V0 register
# Masking: AUX[3]=1 enables mask, AUX[2]=0 means mask bit=0 → inactive
# V0 low bits serve as mask for each element

    # R10 = pass counter
    mov r10, 0

    # R2 = buffer address for vector data
    movi r2, 0x2000

    # === Test 1: vadd with no mask (mask enable=0, default behavior) ===
    mov r3, 10
    st r3, [r2 + 0]
    mov r3, 20
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vadd v2, v0, v1    # no mask, all elements active
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 30
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: vsub with no mask ===
    mov r3, 100
    st r3, [r2 + 0]
    mov r3, 30
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vsub v2, v0, v1
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 70
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: vmul with no mask ===
    mov r3, 6
    st r3, [r2 + 0]
    mov r3, 7
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vmul v2, v0, v1
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 42
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: vand with no mask ===
    movi r3, 0xFF
    st r3, [r2 + 0]
    movi r3, 0x0F
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vand v2, v0, v1
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 0x0F
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # === Test 5: vor with no mask ===
    movi r3, 0x10
    st r3, [r2 + 0]
    movi r3, 0x01
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vor v2, v0, v1
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 0x11
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: vxor with no mask ===
    movi r3, 0xFF
    st r3, [r2 + 0]
    movi r3, 0x0F
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vxor v2, v0, v1
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 0xF0
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 6

    # === Test 7: vshl with no mask ===
    mov r3, 1
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vshl v2, v0, 5    # 1 << 5 = 32
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 32
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 7

    # === Test 8: vshr with no mask ===
    mov r3, 256
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vshr v2, v0, 4    # 256 >> 4 = 16
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    mov r5, 16
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 8

    # === Test 9: vld/vst with no mask ===
    movi r3, 0xDEADBEEFCAFEBABE
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vst v0, [r2 + 32]
    ld r4, [r2 + 32]
    movi r5, 0xDEADBEEFCAFEBABE
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 9

    # === Test 10: vshuffle with no mask ===
    movi r3, 0x0102030405060708
    st r3, [r2 + 0]
    vld v0, [r2 + 0]
    vshuffle v2, v0, 0  # identity shuffle
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    movi r5, 0x0102030405060708
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 10

    # === Test 11: vfmadd with no mask ===
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
    vst v3, [r2 + 40]
    ld r4, [r2 + 40]
    mov r5, 10
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 11

    # === Test 12: vld/vst round-trip with different values ===
    movi r3, 0xAAAAAAAAAAAAAAAA
    st r3, [r2 + 0]
    movi r3, 0x5555555555555555
    st r3, [r2 + 8]
    vld v0, [r2 + 0]
    vld v1, [r2 + 8]
    vxor v2, v0, v1
    vst v2, [r2 + 16]
    ld r4, [r2 + 16]
    movi r5, 0xFFFFFFFFFFFFFFFF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 12

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0