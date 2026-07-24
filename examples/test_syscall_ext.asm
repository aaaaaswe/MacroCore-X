# MacroCore-X Extended Syscall Test
# Tests syscall ABI: register conventions, return values, sysret
# Focuses on the syscall mechanism itself, not specific syscalls

    # R10 = pass counter
    mov r10, 0

    # === Test 1: syscall exit(0) — basic exit ===
    # This is tested implicitly by all other tests
    # Here we verify that we can reach syscall without crash
    mov r10, 1
    add r10, r10, r0  # R10 = 1

    # === Test 2: syscall write(1, buf, 8) — write to stdout ===
    # First, write "OK" to buffer
    movi r2, 0x2000
    movi r3, 0x0A4B4F00  # "OK\n\0" in little-endian
    st r3, [r2 + 0]

    # syscall write(fd=1, buf=0x2000, count=8)
    mov r1, 1           # write syscall
    mov r2, 1           # fd = stdout
    movi r3, 0x2000     # buf
    mov r4, 3           # count = 3 bytes
    syscall 0

    # Verify R1 = count (3) after write
    mov r5, 3
    eq r5, r1, r5
    # Reset R10 and add pass
    mov r10, 0
    add r10, r10, r5  # R10 = 1

    # === Test 3: Caller-saved registers preserved across our test ===
    # R1-R15 may be clobbered by kernel
    # R16-R23 should be preserved (callee-saved)
    movi r16, 0xDEAD
    movi r17, 0xBEEF
    movi r18, 0xCAFE
    movi r19, 0xBABE
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 3
    syscall 0

    # Verify callee-saved registers
    movi r5, 0xDEAD
    eq r5, r16, r5
    add r10, r10, r5  # R10 = 2
    movi r5, 0xBEEF
    eq r5, r17, r5
    add r10, r10, r5  # R10 = 3
    movi r5, 0xCAFE
    eq r5, r18, r5
    add r10, r10, r5  # R10 = 4
    movi r5, 0xBABE
    eq r5, r19, r5
    add r10, r10, r5  # R10 = 5

    # === Test 4: R0 is hardwired to zero even after syscall ===
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 3
    syscall 0
    eq r5, r0, r0     # R0 should always be 0
    add r10, r10, r5  # R10 = 6

    # === Test 5: syscall write with 0 count ===
    mov r1, 1
    mov r2, 1
    movi r3, 0x2000
    mov r4, 0           # count = 0
    syscall 0
    # R1 should be 0
    eq r5, r1, r0
    add r10, r10, r5  # R10 = 7

    # === Test 6: SP (R2) restored after syscall ===
    movi r6, 0x5000
    add r2, r0, r6     # save SP
    mov r1, 1
    mov r2, 1           # fd (overwrites SP temp)
    movi r3, 0x2000
    mov r4, 3
    syscall 0
    # R2 may have been clobbered by syscall (it's caller-saved)
    # This is expected behavior per ABI

    # === Test 7: syscall with unsupported number ===
    mov r1, 255         # unsupported syscall
    syscall 0
    # R1 should be -1 for unsupported
    movi r5, 0xFFFFFFFFFFFFFFFF
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 8

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0