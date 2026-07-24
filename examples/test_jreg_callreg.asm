# MacroCore-X jreg / callreg Indirect Jump Test
# Tests jreg, callreg with indirect dispatch via register
# Uses call to get absolute addresses, avoiding la limitations

    # R10 = pass counter
    mov r10, 0

    # === Test 1: jreg — simple indirect jump to a label ===
    # Use call to get the absolute address of target1
    call get_target1_addr
get_target1_addr:
    # R31 = absolute address of get_target1_addr
    # target1 is at get_target1_addr + offset
    mov r3, r31
    movi r4, 28          # offset from get_target1_addr to target1 (in bytes)
    add r3, r3, r4       # r3 = absolute address of target1
    mov r1, 0
    jreg r3
    # Should not reach here
    mov r1, -1

skip1:
    j test_jreg2

target1:
    addi r1, r1, 1
    j skip1

test_jreg2:
    # Verify R1 = 1
    mov r5, 1
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: jreg — dispatch table (simulated switch/case) ===
    # Set up dispatch table at 0x3000
    movi r2, 0x3000

    # Get absolute address of case0
    call get_case0_addr
get_case0_addr:
    mov r3, r31
    movi r4, 20
    add r3, r3, r4
    st r3, [r2 + 0]     # dispatch[0] = case0

    # Get absolute address of case1
    call get_case1_addr
get_case1_addr:
    mov r3, r31
    movi r4, 24
    add r3, r3, r4
    st r3, [r2 + 8]     # dispatch[1] = case1

    # Get absolute address of case2
    call get_case2_addr
get_case2_addr:
    mov r3, r31
    movi r4, 28
    add r3, r3, r4
    st r3, [r2 + 16]    # dispatch[2] = case2

    # Dispatch to case 1
    mov r1, 0
    movi r4, 0x3008
    ld r4, [r4 + 0]
    jreg r4
    # Should not reach here
    mov r1, -1

case0:
    mov r1, 100
    j dispatch_done
case1:
    mov r1, 200
    j dispatch_done
case2:
    mov r1, 300
    j dispatch_done

dispatch_done:
    mov r5, 200
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: callreg — indirect function call ===
    # Get address of mul_func
    call get_mul_addr
get_mul_addr:
    mov r3, r31
    movi r4, 44
    add r3, r3, r4
    mov r1, 6
    mov r2, 7
    callreg r3
    # After return, R1 should be 42
    mov r5, 42
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: callreg — virtual function table ===
    movi r2, 0x3100

    # Get add_func address
    call get_add_addr
get_add_addr:
    mov r3, r31
    movi r4, 28
    add r3, r3, r4
    st r3, [r2 + 0]    # vtable[0] = add_func

    # Get mul_func address
    call get_mul_addr2
get_mul_addr2:
    mov r3, r31
    movi r4, 40
    add r3, r3, r4
    st r3, [r2 + 8]    # vtable[1] = mul_func

    # Call vtable[0] = add_func(10, 20) → 30
    movi r4, 0x3100
    ld r4, [r4 + 0]
    mov r1, 10
    mov r2, 20
    callreg r4
    mov r5, 30
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 4

    # Call vtable[1] = mul_func(5, 6) → 30
    movi r4, 0x3108
    ld r4, [r4 + 0]
    mov r1, 5
    mov r2, 6
    callreg r4
    mov r5, 30
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 5

    # === Test 5: jreg within same function (forward jump) ===
    call get_jreg_target
get_jreg_target:
    mov r3, r31
    movi r4, 16
    add r3, r3, r4
    jreg r3
    mov r1, -1

jreg_safe_target:
    mov r5, 5
    eq r5, r10, r5
    add r10, r10, r5  # R10 = 6

    # === Test 6: nested callreg ===
    call get_outer_addr
get_outer_addr:
    mov r3, r31
    movi r4, 52
    add r3, r3, r4
    callreg r3
    mov r5, 100
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 7

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0

# === Helper functions ===
mul_func:
    # R1 = R1 * R2
    mul r1, r1, r2
    ret

add_func:
    # R1 = R1 + R2
    add r1, r1, r2
    ret

inner_func:
    mov r1, 100
    ret

outer_func:
    # Call inner_func via callreg
    call get_inner_addr
get_inner_addr:
    mov r3, r31
    movi r4, 20
    add r3, r3, r4
    callreg r3
    ret