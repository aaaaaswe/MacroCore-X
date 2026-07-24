# MacroCore-X String Operations Test
# Tests strlen, strcpy, memset, memcmp as library-style subroutines

    # R10 = pass counter
    mov r10, 0

    # R2 = data buffer
    movi r2, 0x2000

    # === Test 1: strlen ===
    # "Hello" = 0x6F6C6C6548 in little-endian bytes
    movi r3, 0x6F6C6C6548   # "Hello" (little-endian)
    st r3, [r2 + 0]
    st r0, [r2 + 8]          # null terminator (byte 5)
    mov r3, 0
    add r3, r3, r2           # r3 = address of "Hello"
    call strlen
    mov r5, 5
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 1

    # === Test 2: strlen of empty string ===
    st r0, [r2 + 16]
    movi r3, 0x2010
    call strlen
    eq r5, r1, r0
    add r10, r10, r5  # R10 = 2

    # === Test 3: strcpy ===
    # Copy "World" to another location
    movi r3, 0x646C726F57   # "World" (little-endian)
    st r3, [r2 + 32]
    st r0, [r2 + 40]          # null terminator
    mov r3, 0
    add r3, r3, r2
    movi r3, 0x2020           # src = 0x2020
    movi r4, 0x2100           # dst = 0x2100
    call strcpy
    # Verify dst
    movi r3, 0x2100
    ld r4, [r3 + 0]
    movi r5, 0x646C726F57
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 3

    # === Test 4: memset ===
    # Set 8 bytes at 0x2200 to 0xAB
    movi r3, 0x2200
    movi r4, 0xAB
    mov r5, 8
    call memset
    # Verify
    movi r3, 0x2200
    ld r4, [r3 + 0]
    movi r5, 0xABABABABABABABAB
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 4

    # === Test 5: memset partial (4 bytes) ===
    movi r3, 0x2210
    movi r4, 0xCD
    mov r5, 4
    call memset
    movi r3, 0x2210
    ld r4, [r3 + 0]
    movi r5, 0xCDCDCDCD
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 5

    # === Test 6: memcmp — equal buffers ===
    movi r3, 0x1234567890ABCDEF
    movi r4, 0x2300
    st r3, [r4 + 0]
    movi r4, 0x2400
    st r3, [r4 + 0]
    movi r3, 0x2300
    movi r4, 0x2400
    mov r5, 8
    call memcmp
    eq r5, r1, r0     # return 0 means equal
    add r10, r10, r5  # R10 = 6

    # === Test 7: memcmp — different buffers ===
    movi r3, 0xAAAAAAAAAAAAAAAA
    movi r4, 0x2500
    st r3, [r4 + 0]
    movi r3, 0xBBBBBBBBBBBBBBBB
    movi r4, 0x2600
    st r3, [r4 + 0]
    movi r3, 0x2500
    movi r4, 0x2600
    mov r5, 8
    call memcmp
    mov r5, 1
    eq r5, r1, r5     # non-zero means different
    add r10, r10, r5  # R10 = 7

    # === Test 8: memcmp — different at first byte ===
    movi r3, 0x00000000000000FF
    movi r4, 0x2700
    st r3, [r4 + 0]
    movi r3, 0x0000000000000000
    movi r4, 0x2800
    st r3, [r4 + 0]
    movi r3, 0x2700
    movi r4, 0x2800
    mov r5, 8
    call memcmp
    mov r5, 1
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 8

    # === Test 9: memcmp — first N bytes equal, diff at N+1 ===
    movi r3, 0x00000000000000FF
    movi r4, 0x2900
    st r3, [r4 + 0]
    movi r3, 0x0000000000000000
    movi r4, 0x2A00
    st r3, [r4 + 0]
    movi r3, 0x2900
    movi r4, 0x2A00
    mov r5, 7     # first 7 bytes are zero for both
    call memcmp
    eq r5, r1, r0     # should be equal
    add r10, r10, r5  # R10 = 9

    # === Test 10: strcpy + strlen verification ===
    movi r3, 0x2B00
    movi r4, 0x2C00
    call strcpy
    # Now strlen of 0x2C00 should be 0 (empty string)
    movi r3, 0x2C00
    call strlen
    eq r5, r1, r0
    add r10, r10, r5  # R10 = 10

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0
    nop              # pad to 4-byte alignment for jump targets

# === strlen: R1 = length of string at R3 ===
# Scans bytes until null terminator (0x00)
strlen:
    mov r1, 0           # length = 0
strlen_loop:
    mov r4, 0
    add r4, r4, r3
    add r4, r4, r1      # addr = str + len
    ldu r5, [r4 + 0]    # load 32-bit (zero-extended)
    andi r5, r5, 0xFF   # mask to byte
    eq r6, r5, r0       # is byte == 0?
    mov r7, 1
    eq r6, r6, r7
    mov r7, 0
    bne r6, r7, strlen_done
    addi r1, r1, 1
    j strlen_loop
strlen_done:
    ret

# === strcpy: copy string from R3 to R4 ===
strcpy:
    push r3
    push r4
strcpy_loop:
    ldu r5, [r3 + 0]    # load byte from src
    andi r5, r5, 0xFF
    stb r5, [r4 + 0]    # store byte to dst
    eq r6, r5, r0       # is it null?
    mov r7, 1
    eq r6, r6, r7
    mov r7, 0
    bne r6, r7, strcpy_done
    addi r3, r3, 1
    addi r4, r4, 1
    j strcpy_loop
strcpy_done:
    pop r4
    pop r3
    ret

# === memset: fill R5 bytes at [R3] with byte R4 ===
# R3 = dst, R4 = byte value, R5 = count
memset:
    mov r6, 0            # offset = 0
memset_loop:
    bge r6, r5, memset_done
    mov r7, 0
    add r7, r7, r3
    add r7, r7, r6
    stb r4, [r7 + 0]
    addi r6, r6, 1
    j memset_loop
memset_done:
    ret

# === memcmp: compare R5 bytes at [R3] and [R4] ===
# Returns 0 if equal, non-zero if different
memcmp:
    mov r6, 0             # offset = 0
memcmp_loop:
    bge r6, r5, memcmp_equal
    # Load byte from each buffer
    mov r7, 0
    add r7, r7, r3
    add r7, r7, r6
    ldu r8, [r7 + 0]
    andi r8, r8, 0xFF
    mov r7, 0
    add r7, r7, r4
    add r7, r7, r6
    ldu r9, [r7 + 0]
    andi r9, r9, 0xFF
    # Compare
    bne r8, r9, memcmp_diff
    addi r6, r6, 1
    j memcmp_loop
memcmp_equal:
    mov r1, 0
    ret
memcmp_diff:
    mov r1, 1
    ret