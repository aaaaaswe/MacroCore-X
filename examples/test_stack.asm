# MacroCore-X Stack and Function Call Test
# Tests nested function calls, stack frames, parameter passing, and recursion

    # R10 = pass counter
    mov r10, 0

    # Initialize stack pointer
    movi r2, 0x5000

    # === Test 1: Simple call/ret ===
    movi r1, 0x1234
    call simple_func
    # After return, R1 should be 0x1234 + 1 = 0x1235
    movi r5, 0x1235
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: Nested call (3 levels deep) ===
    mov r1, 0
    call level1
    mov r5, 3
    eq r5, r1, r5    # R1 should be 3 (incremented 3 times)
    add r10, r10, r5  # R10 = 2

    # === Test 3: Parameter passing via caller-saved registers ===
    mov r3, 10
    mov r4, 20
    call sum_func
    # R1 should be 30
    mov r5, 30
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: Recursive factorial (5! = 120) ===
    mov r1, 5
    call factorial
    mov r5, 120
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 4

    # === Test 5: Stack frame with enter/leave ===
    movi r2, 0x5000
    add r30, r0, r2
    call frame_func
    mov r5, 42
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: Multi-arg function via registers ===
    mov r3, 5
    mov r4, 6
    mov r5, 7
    call sum3_func
    # R1 should be 5+6+7 = 18
    mov r6, 18
    eq r6, r1, r6
    add r10, r10, r6  # R10 = 6

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0

# === Subroutines ===

simple_func:
    addi r1, r1, 1
    ret

level1:
    addi r1, r1, 1
    call level2
    ret

level2:
    addi r1, r1, 1
    call level3
    ret

level3:
    addi r1, r1, 1
    ret

sum_func:
    # R1 = R3 + R4
    mov r1, 0
    add r1, r1, r3
    add r1, r1, r4
    ret

sum3_func:
    # R1 = R3 + R4 + R5
    mov r1, 0
    add r1, r1, r3
    add r1, r1, r4
    add r1, r1, r5
    ret

factorial:
    # R1 = n (input and output)
    # Base case: if n <= 1, return 1
    mov r6, 1
    ble r1, r6, fact_base
    # Save n on stack
    push r1
    # Recurse with n-1
    subi r1, r1, 1
    call factorial
    # R1 = factorial(n-1), pop saved n
    pop r6
    mul r1, r6, r1
    ret
fact_base:
    mov r1, 1
    ret

frame_func:
    enter 16
    # Use local variable space (SP+0 to SP+15)
    mov r3, 42
    st r3, [r2 + 0]
    ld r1, [r2 + 0]
    leave
    ret