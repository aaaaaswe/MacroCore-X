# MacroCore-X Fibonacci Sequence
# Computes first 10 Fibonacci numbers and stores them at memory 0x2000
# Uses 5-bit register fields (R0-R31)

    # R1 = counter (10 iterations)
    mov r1, 10

    # R2 = base address for storing results
    movi r2, 0x2000

    # R3 = F(0) = 0
    mov r3, 0

    # R4 = F(1) = 1
    mov r4, 1

    # Store F(0) and F(1)
    st r3, [r2 + 0]
    st r4, [r2 + 8]

    # R5 = loop counter (starting from 2)
    mov r5, 2

    # R6 = offset into array (16 = 2 * 8)
    mov r6, 16

fib_loop:
    # Compute next Fibonacci: R7 = R3 + R4
    mov r7, 0
    add r7, r7, r3
    add r7, r7, r4

    # Store result at [r2 + r6]
    # Compute address: R8 = R2 + R6
    mov r8, 0
    add r8, r8, r2
    add r8, r8, r6
    st r7, [r8 + 0]

    # Shift for next: R3 = R4, R4 = R7
    xor r3, r3, r3
    add r3, r3, r4
    xor r4, r4, r4
    add r4, r4, r7

    # Increment counter and offset
    addi r5, r5, 1
    addi r6, r6, 8

    # Loop if R5 < R1
    blt r5, r1, fib_loop

    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0