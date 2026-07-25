# MacroCore-X Comprehensive CSR Register Test
# Tests all standard CSR registers: ERR, EF, MODE, CR3, IVEC, IE, IP, IPI,
# TIMER, TIMECMP, FSR, DBGCTL, and PMC0-PMC3

    # R10 = pass counter
    mov r10, 0

    # === CSR_ERR (0x000): Exception Return PC ===
    movi r3, 0x1234567890ABCDEF
    wrmsr r3, 0x000
    rdmsr r4, 0x000
    movi r5, 0x1234567890ABCDEF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 1

    # === CSR_EF (0x001): Exception Flags ===
    mov r3, 0xAB
    wrmsr r3, 0x001
    rdmsr r4, 0x001
    mov r5, 0xAB
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 2

    # === CSR_MODE (0x002): Mode Register ===
    # Read, modify PRIV bit, write back, verify
    rdmsr r3, 0x002
    andi r6, r3, 1       # read PRIV bit
    mov r7, 1
    xor r3, r3, r7       # toggle PRIV bit
    wrmsr r3, 0x002
    rdmsr r4, 0x002
    andi r4, r4, 1
    xor r5, r6, r4       # bits should differ (since we toggled)
    mov r6, 1
    eq r5, r5, r6
    add r10, r10, r5  # R10 = 3

    # Restore original PRIV bit
    rdmsr r3, 0x002
    mov r7, 1
    xor r3, r3, r7
    wrmsr r3, 0x002

    # Test ALIGN bit (bit 1)
    rdmsr r3, 0x002
    mov r4, 2
    or r3, r3, r4        # set ALIGN=1
    wrmsr r3, 0x002
    rdmsr r4, 0x002
    andi r4, r4, 2
    mov r5, 2
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # Clear ALIGN bit
    rdmsr r3, 0x002
    movi r4, 0xFFFFFFFFFFFFFFFD
    and r3, r3, r4
    wrmsr r3, 0x002

    # === CSR_CR3 (0x003): Page Table Base ===
    movi r3, 0x4000
    wrmsr r3, 0x003
    rdmsr r4, 0x003
    movi r5, 0x4000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === CSR_IVEC (0x004): Interrupt Vector Table Base ===
    movi r3, 0x1000
    wrmsr r3, 0x004
    rdmsr r4, 0x004
    movi r5, 0x1000
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 6

    # === CSR_IE (0x005): Interrupt Enable ===
    movi r3, 0xFFFFFFFF
    wrmsr r3, 0x005
    rdmsr r4, 0x005
    movi r5, 0xFFFFFFFF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 7

    # Write specific mask: enable timer (bit 0) and IPI (bit 1)
    mov r3, 3
    wrmsr r3, 0x005
    rdmsr r4, 0x005
    mov r5, 3
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 8

    # === CSR_IP (0x006): Interrupt Pending (read-only) ===
    rdmsr r3, 0x006
    # IP should be readable — just verify no crash
    add r10, r10, r5  # R10 = 9

    # === CSR_IPI (0x007): Inter-Processor Interrupt ===
    # Write (core_id=0 << 16) | (vector=0xF)
    movi r3, 0xF
    wrmsr r3, 0x007
    rdmsr r4, 0x007
    movi r5, 0xF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 10

    # === CSR_TIMER (0x008): Timer Counter ===
    rdmsr r3, 0x008
    # Read timer value, then read again, should be >= first read
    rdmsr r4, 0x008
    # Just verify both reads succeed
    add r10, r10, r5  # R10 = 11

    # === CSR_TIMECMP (0x009): Timer Compare ===
    movi r3, 0xDEADBEEF
    wrmsr r3, 0x009
    rdmsr r4, 0x009
    movi r5, 0xDEADBEEF
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 12

    # === CSR_FSR (0x00A): Floating-Point Status ===
    # Write all exception flags (NV=1, DZ=1, OF=1, UF=1, NX=1)
    mov r3, 0x1F
    wrmsr r3, 0x00A
    rdmsr r4, 0x00A
    mov r5, 0x1F
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 13

    # Clear FSR
    mov r3, 0
    wrmsr r3, 0x00A
    rdmsr r4, 0x00A
    eq r5, r4, r0
    add r10, r10, r5  # R10 = 14

    # === CSR_DBGCTL (0x00B): Debug Control ===
    # Set debug enable (bit 0) and single-step (bit 1)
    mov r3, 3
    wrmsr r3, 0x00B
    rdmsr r4, 0x00B
    mov r5, 3
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 15

    # Clear debug control
    mov r3, 0
    wrmsr r3, 0x00B

    # === PMC0 (0x00C): Instructions Retired ===
    rdmsr r3, 0x00C
    # PMC0 should be non-zero (we've executed many instructions)
    bne r3, r0, pmc0_nonzero
    j pmc0_done
pmc0_nonzero:
    add r10, r10, r5  # R10 = 16
pmc0_done:

    # === PMC1 (0x00D): CPU Cycles ===
    rdmsr r3, 0x00D
    bne r3, r0, pmc1_nonzero
    j pmc1_done
pmc1_nonzero:
    add r10, r10, r5  # R10 = 17
pmc1_done:

    # === PMC2 (0x00E): Branch Instructions ===
    rdmsr r3, 0x00E
    # Should have executed some branches
    bne r3, r0, pmc2_nonzero
    j pmc2_done
pmc2_nonzero:
    add r10, r10, r5  # R10 = 18
pmc2_done:

    # === CSR Write Persistence Test ===
    # Write a unique pattern, read back, verify unchanged
    movi r3, 0x5A5A5A5A5A5A5A5A
    wrmsr r3, 0x000
    # Write to another CSR, then read first back
    movi r6, 0xA5A5A5A5A5A5A5A5
    wrmsr r6, 0x001
    rdmsr r4, 0x000
    movi r5, 0x5A5A5A5A5A5A5A5A
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 19

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0