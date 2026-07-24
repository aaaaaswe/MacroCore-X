# MacroCore-X Branch Test
# Tests all conditional branch instructions: j, call, ret, beq, bne,
# blt, ble, bgt, bge, bltu, bgeu (uses R0-R15 only for B-type)

    # R10 = pass counter
    mov r10, 0

    # === Test j (unconditional jump) ===
    mov r1, 0
    j skip_j_test
    mov r1, -1       # should be skipped
skip_j_test:
    addi r1, r1, 1   # R1 = 1

    # === Test beq (branch if equal) ===
    mov r2, 5
    mov r3, 5
    beq r2, r3, beq_taken
    mov r1, -1
beq_taken:
    addi r1, r1, 1   # R1 = 2

    # === Test bne (branch if not equal) ===
    mov r2, 3
    mov r3, 7
    bne r2, r3, bne_taken
    mov r1, -1
bne_taken:
    addi r1, r1, 1   # R1 = 3

    # === Test blt (branch if less than, signed) ===
    mov r3, 10
    mov r2, 5
    sub r2, r0, r2   # r2 = -5 in 64-bit
    blt r2, r3, blt_taken
    mov r1, -1
blt_taken:
    addi r1, r1, 1   # R1 = 4

    # === Test bge (branch if greater or equal, signed) ===
    mov r2, 20
    mov r3, 10
    bge r2, r3, bge_taken
    mov r1, -1
bge_taken:
    addi r1, r1, 1   # R1 = 5

    # === Test ble (branch if less or equal, signed) ===
    mov r2, 10
    mov r3, 10
    ble r2, r3, ble_taken
    mov r1, -1
ble_taken:
    addi r1, r1, 1   # R1 = 6

    # === Test bgt (branch if greater than, signed) ===
    mov r2, 15
    mov r3, 5
    bgt r2, r3, bgt_taken
    mov r1, -1
bgt_taken:
    addi r1, r1, 1   # R1 = 7

    # === Test bltu (branch if less than, unsigned) ===
    movi r2, 0xFFFFFFFE
    mov r3, 1
    bltu r3, r2, bltu_taken
    mov r1, -1
bltu_taken:
    addi r1, r1, 1   # R1 = 8

    # === Test bgeu (branch if greater or equal, unsigned) ===
    movi r2, 0xFFFFFFFF
    mov r3, 0
    bgeu r2, r3, bgeu_taken
    mov r1, -1
bgeu_taken:
    addi r1, r1, 1   # R1 = 9

    # === Test call / ret ===
    call call_target
    # R1 should be 10 after return
    j test_done

call_target:
    addi r1, r1, 1   # R1 = 10
    ret

test_done:
    # Verify R1 = 10 (all 10 tests passed)
    mov r5, 10
    eq r10, r1, r5    # R10 = 1 if all passed

    mov r1, 0
    mov r2, 0
    syscall 0