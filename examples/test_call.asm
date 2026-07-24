# Test call/ret instructions
# Calls a function that increments R1, returns, then exits

    movi  R1, 0
    movi  R2, 0x1234
    call  my_func
    # R1 should be 1 after return
    movi  R3, 0x5678
    syscall 0x0

my_func:
    addi  R1, R1, 1
    ret