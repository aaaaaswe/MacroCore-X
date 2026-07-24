# MacroCore-X Pseudo-Instruction Test
# Tests li (load immediate) and la (load address) pseudo-instructions
# li expands to mov (14-bit) or movi (32-bit) depending on value
# la expands to movi with label address

    # R10 = pass counter
    mov r10, 0

    # === Test li: small positive immediate (should use mov) ===
    li r3, 42
    mov r5, 42
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 1

    # === Test li: small negative immediate (should use mov) ===
    li r3, -100
    mov r5, 100
    sub r5, r0, r5
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 2

    # === Test li: maximum 14-bit positive (8191, should use mov) ===
    li r3, 8191
    movi r5, 8191
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # === Test li: beyond 14-bit (should use movi) ===
    li r3, 0x12345678
    movi r5, 0x12345678
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 4

    # === Test li: zero ===
    li r3, 0
    eq r5, r3, r0
    add r10, r10, r5  # R10 = 5

    # === Test li: large 32-bit value ===
    li r3, 0xDEADBEEF
    movi r5, 0xDEADBEEF
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 6

    # === Test la: load address of a label ===
    la r3, test_data
    # Verify R3 points to test_data area (will be at some offset)
    # Store a known value at test_data and verify through R3
    movi r4, 0xCAFEBABE
    st r4, [r3 + 0]
    ld r5, [r3 + 0]
    movi r6, 0xCAFEBABE
    eq r6, r5, r6
    add r10, r10, r6  # R10 = 7

    # === Test la: load address of another label ===
    la r3, data_buffer
    movi r4, 0xFEEDFACE
    st r4, [r3 + 0]
    la r7, data_buffer
    ld r5, [r7 + 0]
    movi r6, 0xFEEDFACE
    eq r6, r5, r6
    add r10, r10, r6  # R10 = 8

    # === Test la: use as base for array access ===
    la r3, array_start
    mov r4, 10
    st r4, [r3 + 0]
    mov r4, 20
    st r4, [r3 + 8]
    # Load back and verify
    ld r5, [r3 + 0]
    mov r6, 10
    eq r6, r5, r6
    add r10, r10, r6  # R10 = 9
    ld r5, [r3 + 8]
    mov r6, 20
    eq r6, r5, r6
    add r10, r10, r6  # R10 = 10

    # === Test li: min negative 14-bit (-8192, should use mov) ===
    li r3, -8192
    mov r5, -8192
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 11

    # === Test li: exactly at boundary (8192, should use movi) ===
    li r3, 8192
    movi r5, 8192
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 12

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0

# === Data section (labels for la test) ===
# Use st r0 to reserve zeroed space at these labels
test_data:
    st r0, [r0 + 0]    # 4 bytes reserved

data_buffer:
    st r0, [r0 + 0]    # 4 bytes reserved

array_start:
    st r0, [r0 + 0]    # 4 bytes reserved
    st r0, [r0 + 0]    # 4 bytes reserved