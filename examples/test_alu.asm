# MacroCore-X ALU Test
# Tests basic arithmetic and logical operations (uses R0-R15 only)
# R-type now uses 4 bytes with explicit Rd, Rs1, Rs2 operands

    # Test addi: R1 = -5 + 10 = 5
    mov r1, -5
    addi r1, r1, 10

    # Test subi: R2 = 20 - 8 = 12
    mov r2, 20
    subi r2, r2, 8

    # Test add: R3 = R1 + R2 = 17
    mov r3, 0
    add r3, r3, r1       # R3 = 0 + 5 = 5
    add r3, r3, r2       # R3 = 5 + 12 = 17

    # Test mul: R4 = 6 * 7 = 42
    mov r4, 6
    mov r5, 7
    mul r4, r4, r5

    # Test div: R6 = 100 / 7 = 14
    mov r6, 100
    mov r7, 7
    div r6, r6, r7

    # Test and: R8 = 0xFF & 0x0F = 0x0F
    movi r8, 0xFF
    movi r9, 0x0F
    and r8, r8, r9

    # Test or: R10 = 0x10 | 0x01 = 0x11
    movi r10, 0x10
    movi r11, 0x01
    or r10, r10, r11

    # Test xor: R12 = 0xFF ^ 0x0F = 0xF0
    movi r12, 0xFF
    mov r13, 0x0F
    xor r12, r12, r13

    # Test shl: R13 = 1 << 4 = 16
    mov r13, 1
    mov r14, 4
    shl r13, r13, r14

    # Test shr: R14 = 128 >> 3 = 16
    mov r14, 128
    mov r15, 3
    shr r14, r14, r15

    # Test eq: R13 = (R13 == R14)?  (16 == 16) → 1
    eq r13, r13, r14

    # Exit
    mov r1, 0         # syscall: exit
    mov r2, 0         # exit code
    syscall 0