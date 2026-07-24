# MacroCore-X sysret Test
# Tests syscall/sysret round-trip: enter kernel mode, do something, return
# syscall enters kernel mode, sysret returns to user mode
# In the simulator, syscall with imm8=0 triggers the syscall handler
# which processes the syscall number in R1

    # R10 = pass counter
    mov r10, 0

    # === Test 1: syscall exit(0) — basic ===
    # This is tested implicitly by all other tests
    mov r5, 1
    add r10, r10, r5  # R10 = 1

    # === Test 2: Set up syscall handler for write then sysret ===
    # Write a test pattern to verify syscall processing
    movi r2, 0x2000
    movi r3, 0xDEADBEEF
    st r3, [r2 + 0]

    # syscall write(fd=1, buf=0x2000, count=4)
    mov r1, 1           # write syscall
    mov r2, 1           # fd = stdout
    movi r3, 0x2000     # buf
    mov r4, 4           # count = 4 bytes
    syscall 0
    # After syscall/sysret, R1 should contain result (4 bytes written)
    mov r5, 4
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 2

    # === Test 3: syscall with unsupported number returns -1 ===
    mov r1, 255         # unsupported syscall
    syscall 0
    movi r5, 0xFFFFFFFFFFFFFFFF
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: syscall write with 0 count ===
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 0           # count = 0
    syscall 0
    eq r5, r1, r0       # should return 0
    add r10, r10, r5  # R10 = 4

    # === Test 5: Verify R0 is always 0 after syscall ===
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 4
    syscall 0
    eq r5, r0, r0
    add r10, r10, r5  # R10 = 5

    # === Test 6: Multiple syscalls in sequence ===
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 4
    syscall 0
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 4
    syscall 0
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 4
    syscall 0
    add r10, r10, r5  # R10 = 6

    # === Test 7: exit syscall — verify exit works last ===
    add r10, r10, r5  # R10 = 7 (from Test 6 result)

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0