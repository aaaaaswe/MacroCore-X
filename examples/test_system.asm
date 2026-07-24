# MacroCore-X System Instructions Test
# Tests cpuid, rdmsr, wrmsr, fence, cli, sti, nop, bkpt

    # R10 = pass counter
    mov r10, 0

    # === Test cpuid ===
    # CPUID fills R0:R1:R2:R3 with vendor/features/cache/version info
    cpuid
    # R0 should be "MCXM" = 0x4D43584D
    movi r5, 0x4D43584D
    eq r5, r0, r5
    add r10, r10, r5  # R10 = 1

    # R1 should be version 2.0 = 0x00020000
    movi r5, 0x00020000
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 2

    # R3 should be 1 (cache info)
    mov r5, 1
    eq r5, r3, r5
    add r10, r10, r5  # R10 = 3

    # === Test rdmsr / wrmsr ===
    # Write value to CSR_ERR (0x000) and read back
    movi r3, 0xDEADBEEF
    wrmsr r3, 0x000      # write to CSR_ERR
    rdmsr r4, 0x000      # read back
    movi r5, 0xDEADBEEF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # Write to CSR_EF (0x001) and read back
    mov r3, 0xAB
    wrmsr r3, 0x001
    rdmsr r4, 0x001
    mov r5, 0xAB
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === Test fence (memory barrier) ===
    # fence is a no-op in the single-core simulator
    # but should execute without error
    fence
    mov r5, 1
    add r10, r10, r5  # R10 = 6

    # fence with specific PI/PO
    fence 0x3, 0x3
    add r10, r10, r5  # R10 = 7

    # === Test cli / sti ===
    # cli clears interrupt enable, sti sets it
    # These don't have visible effects in the simulator
    # but should execute without error
    cli
    sti
    add r10, r10, r5  # R10 = 8

    # === Test nop ===
    nop
    nop
    add r10, r10, r5  # R10 = 9

    # Exit (skip bkpt test since it halts)
    mov r1, 0
    add r2, r0, r10
    syscall 0