# MacroCore-X Mini OS — DOS-style system demo
# Demonstrates: boot sequence, memory management, interrupt-like
# dispatch table, and basic system program structure.
# All values are hardcoded (no .string directive available).

# Memory layout:
#   0x1000: code start
#   0x2000: data scratch space
#   0x4000: stack top
#   0x5000: command dispatch table (4 entries x 16 bytes)

    # === BOOT SEQUENCE ===
    # Initialize stack pointer
    movi r2, 0x4000

    # Initialize dispatch table at 0x5000
    # Each entry: [handler_addr 8 bytes][handler_id 8 bytes]
    # Handler 0: help
    la r3, help_handler
    movi r4, 0x5000
    st r3, [r4 + 0]
    # Handler 1: ver
    la r3, ver_handler
    st r3, [r4 + 16]
    # Handler 2: status
    la r3, status_handler
    st r3, [r4 + 32]
    # Handler 3: shutdown
    la r3, shutdown_handler
    st r3, [r4 + 48]

    # === BOOT SELF-TEST ===
    # Test basic ALU at boot
    mov r3, 100
    mov r4, 50
    add r3, r3, r4       # R3 = 150
    mov r5, 150
    eq r5, r3, r5
    # R10 = 1 if self-test passed
    mov r10, 0
    add r10, r10, r5

    # Test memory R/W at boot
    movi r6, 0xDEADBEEFCAFEBABE
    st r6, [r2 + 0]
    ld r7, [r2 + 0]
    eq r5, r6, r7
    add r10, r10, r5    # R10 = 2 if passed

    # === MAIN KERNEL LOOP ===
    # Dispatch to command 0 (help) as default
    mov r1, 0           # command ID = 0
    call dispatch

    # Dispatch to command 1 (ver)
    mov r1, 1
    call dispatch

    # Dispatch to command 2 (status)
    mov r1, 2
    call dispatch

    # Dispatch to command 3 (shutdown)
    mov r1, 3
    call dispatch

    # Should not reach here
    mov r1, 0
    add r2, r0, r10
    syscall 0

# === dispatch: call handler[R1] from dispatch table at 0x5000 ===
dispatch:
    # Calculate offset: R1 * 16
    mov r3, 0
    add r3, r3, r1
    shli r3, r3, 4      # R3 = R1 * 16
    movi r4, 0x5000
    add r4, r4, r3
    ld r5, [r4 + 0]     # load handler address
    jreg r5

# === Handler 0: help — prints available commands ===
help_handler:
    # Store help info at 0x2000
    movi r3, 0x2000
    movi r4, 0x68656C70  # "help" in ASCII (little endian)
    st r4, [r3 + 0]
    movi r4, 0x76657200  # "ver\0"
    st r4, [r3 + 8]
    movi r4, 0x73746174  # "stat"
    st r4, [r3 + 16]
    movi r4, 0x65786974  # "exit"
    st r4, [r3 + 24]
    ret

# === Handler 1: ver — version info ===
ver_handler:
    movi r3, 0x2000
    movi r4, 0x76302E30  # "v0.0"
    st r4, [r3 + 0]
    movi r4, 0x2E310000  # ".1\0\0"
    st r4, [r3 + 8]
    ret

# === Handler 2: status — system status dump ===
status_handler:
    movi r3, 0x2000
    # Store boot test result count
    st r10, [r3 + 0]
    # Store SP value
    st r2, [r3 + 8]
    ret

# === Handler 3: shutdown — clean exit ===
shutdown_handler:
    mov r1, 0
    add r2, r0, r10
    syscall 0