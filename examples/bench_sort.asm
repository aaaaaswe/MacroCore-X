# MacroCore-X Bubble Sort Algorithm Test
# Sorts an array of 10 integers using bubble sort
# Demonstrates nested loops, array access, conditional branches

    # R10 = pass counter
    mov r10, 0

    # R2 = array base address
    movi r2, 0x2000

    # Initialize array: [9, 3, 7, 1, 5, 8, 2, 6, 4, 0]
    mov r3, 9
    st r3, [r2 + 0]
    mov r3, 3
    st r3, [r2 + 8]
    mov r3, 7
    st r3, [r2 + 16]
    mov r3, 1
    st r3, [r2 + 24]
    mov r3, 5
    st r3, [r2 + 32]
    mov r3, 8
    st r3, [r2 + 40]
    mov r3, 2
    st r3, [r2 + 48]
    mov r3, 6
    st r3, [r2 + 56]
    mov r3, 4
    st r3, [r2 + 64]
    mov r3, 0
    st r3, [r2 + 72]

    # === Bubble Sort ===
    # R3 = n = 10 (array size)
    mov r3, 10

    # R4 = i (outer loop counter, 0 to n-1)
    mov r4, 0

outer_loop:
    # if i >= n-1, done
    mov r5, 9
    bge r4, r5, sort_done

    # R5 = j (inner loop counter, 0 to n-i-2)
    mov r5, 0

    # R6 = n - i - 1 (upper bound for j)
    mov r6, 0
    add r6, r6, r3       # r6 = n
    sub r6, r6, r4       # r6 = n - i
    subi r6, r6, 1       # r6 = n - i - 1

inner_loop:
    bge r5, r6, inner_done

    # Load arr[j] and arr[j+1]
    # R7 = j * 8 (byte offset)
    mov r7, 0
    add r7, r7, r5
    shli r7, r7, 3

    # R8 = address of arr[j]
    mov r8, 0
    add r8, r8, r2
    add r8, r8, r7

    ld r9, [r8 + 0]     # r9 = arr[j]
    ld r11, [r8 + 8]    # r11 = arr[j+1]

    # If arr[j] <= arr[j+1], skip swap
    ble r9, r11, no_swap

    # Swap arr[j] and arr[j+1]
    st r11, [r8 + 0]
    st r9, [r8 + 8]

no_swap:
    addi r5, r5, 1
    j inner_loop

inner_done:
    addi r4, r4, 1
    j outer_loop

sort_done:
    # === Verify sorted array: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] ===
    ld r4, [r2 + 0]
    eq r5, r4, r0       # arr[0] == 0
    add r10, r10, r5

    ld r4, [r2 + 8]
    mov r5, 1
    eq r5, r4, r5       # arr[1] == 1
    add r10, r10, r5

    ld r4, [r2 + 16]
    mov r5, 2
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 24]
    mov r5, 3
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 32]
    mov r5, 4
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 40]
    mov r5, 5
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 48]
    mov r5, 6
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 56]
    mov r5, 7
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 64]
    mov r5, 8
    eq r5, r4, r5
    add r10, r10, r5

    ld r4, [r2 + 72]
    mov r5, 9
    eq r5, r4, r5
    add r10, r10, r5  # R10 = 10

    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0