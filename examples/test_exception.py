#!/usr/bin/env python3
"""
MacroCore-X Exception Handling Test
Tests div-by-zero exception with custom exception vector table.
Also tests page fault exception via MMU.
"""

import sys
sys.path.insert(0, '.')
from simulator import CPU, load_binary, simulate, csr_write, csr_read
from assembler import Assembler, tokenize, parse


def assemble_code(asm_source: str, assembler: Assembler) -> bytes:
    """Assemble inline assembly source."""
    tokens = tokenize(asm_source)
    instructions = parse(tokens)
    assembler.output = bytearray()
    assembler.offset = 0
    assembler.labels = {}
    assembler.pending = []
    return assembler.assemble(instructions)


def test_div_zero_exception():
    """
    Test div-by-zero exception handling.
    
    Sets up an exception vector table at 0x5000, writes a handler
    that catches the exception, increments a counter, skips the
    faulting instruction, and returns via iret.
    """
    print(f"{'='*60}")
    print(f"  Test 1: Div-by-Zero Exception")
    print(f"{'='*60}")
    
    cpu = CPU(memory_size=0x100000)
    asm = Assembler()
    
    # Set exception vector table base to 0x5000
    # Write handler code at 0x5000 (div-by-zero is vector 0)
    handler_addr = 0x5000
    
    # Build exception handler code manually:
    # The handler should:
    #   1. movi r10, 1        — mark exception caught
    #   2. rdmsr r11, 0x000   — read CSR_ERR (faulting PC)
    #   3. addi r11, r11, 4   — skip faulting div instruction
    #   4. wrmsr r11, 0x000   — write back CSR_ERR
    #   5. iret               — return from exception
    
    code = bytearray()
    # movi r10, 1 (6 bytes)
    code.extend(bytes([0x2A, 0x50, 0x01, 0x00, 0x00, 0x00]))
    # rdmsr r11, 0x000 (4 bytes)
    code.extend(bytes([0xB4, 0xB0, 0x00, 0x00]))
    # addi r11, r11, 4 (4 bytes)
    code.extend(bytes([0x20, 0x5A, 0xC0, 0x04]))
    # wrmsr r11, 0x000 (4 bytes)
    code.extend(bytes([0xB5, 0xB0, 0x00, 0x00]))
    # iret (2 bytes)
    code.extend(bytes([0xB3, 0x00]))
    # nop padding (2 bytes)
    code.extend(bytes([0xBA, 0x00]))
    
    # Write handler to memory at 0x5000
    cpu.mem[handler_addr:handler_addr + len(code)] = code
    
    # Main test program
    main_asm = """
    # Test div-by-zero exception
    # First, set CSR_IVEC to 0x5000
    movi r3, 0x5000
    wrmsr r3, 0x004
    
    # Verify CSR_IVEC was set
    rdmsr r4, 0x004
    movi r5, 0x5000
    eq r5, r4, r5
    mov r10, 0
    add r10, r10, r5  # R10 = 1 if CSR_IVEC is correct
    
    # Now trigger div-by-zero
    mov r1, 100
    mov r2, 0
    div r1, r1, r2   # DIVIDE BY ZERO → exception
    
    # After exception handler returns, R10 should be 2
    # (handler set it to 1, then incremented)
    movi r5, 2
    eq r5, r10, r5
    add r10, r10, r5  # R10 = 3 if exception was handled
    
    # Verify R1 is preserved
    mov r5, 100
    eq r5, r1, r5
    add r10, r10, r5  # R10 = 4 if R1 is preserved
    
    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0
    """
    
    binary = assemble_code(main_asm, asm)
    program_base = 0x1000
    cpu.mem[program_base:program_base + len(binary)] = binary
    cpu.pc = program_base
    cpu.r[2] = cpu.mem_size - 0x1000
    
    simulate(cpu, max_steps=200, trace=False)
    
    # Check results
    expected_r10 = 4
    if cpu.r[10] == expected_r10:
        print(f"\n[PASS] Div-by-zero exception test: R10={cpu.r[10]} (expected {expected_r10})")
    else:
        print(f"\n[FAIL] Div-by-zero exception test: R10={cpu.r[10]} (expected {expected_r10})")
    
    return cpu.r[10] == expected_r10


def test_page_fault_exception():
    """
    Test page fault exception.
    
    Enables MMU with a page table that only maps the code page.
    Accessing unmapped memory should trigger a page fault.
    """
    print(f"\n{'='*60}")
    print(f"  Test 2: Page Fault Exception")
    print(f"{'='*60}")
    
    cpu = CPU(memory_size=0x100000)
    asm = Assembler()
    
    # Set up page tables: only map VA 0x1000-0x1FFF → PA 0x1000-0x1FFF
    PAGE_SIZE = 0x1000
    
    def write64(mem, addr, val):
        mem[addr:addr+8] = val.to_bytes(8, 'little')
    
    def make_pte(ppn, flags):
        return (ppn << 12) | (flags & 0xFF)
    
    L3_ADDR = 0x2000
    L2_ADDR = 0x3000
    L1_ADDR = 0x4000
    L0_ADDR = 0x5000
    
    leaf_flags = 0b01001111  # V|R|X|W|U
    ptr_flags = 0b00000001   # V only
    
    write64(cpu.mem, L3_ADDR + 0, make_pte(L2_ADDR >> 12, ptr_flags))
    write64(cpu.mem, L2_ADDR + 0, make_pte(L1_ADDR >> 12, ptr_flags))
    write64(cpu.mem, L1_ADDR + 0, make_pte(L0_ADDR >> 12, ptr_flags))
    # Only map VPN[0]=1 → PA 0x1000
    write64(cpu.mem, L0_ADDR + 1 * 8, make_pte(0x1, leaf_flags))
    
    cpu.csr_cr3 = L3_ADDR
    
    # Set up page fault handler (exception vector 3) at 0x9000
    handler_addr = 0x9000
    
    # Page fault handler:
    #   1. movi r10, 1       — mark fault caught
    #   2. rdmsr r11, 0x000  — read CSR_ERR
    #   3. addi r11, r11, 4  — skip faulting instruction
    #   4. wrmsr r11, 0x000  — write back
    #   5. iret
    handler_code = bytearray()
    handler_code.extend(bytes([0x2A, 0x50, 0x01, 0x00, 0x00, 0x00]))  # movi r10, 1
    handler_code.extend(bytes([0xB4, 0xB0, 0x00, 0x00]))              # rdmsr r11, 0x000
    handler_code.extend(bytes([0x20, 0x5A, 0xC0, 0x04]))              # addi r11, r11, 4
    handler_code.extend(bytes([0xB5, 0xB0, 0x00, 0x00]))              # wrmsr r11, 0x000
    handler_code.extend(bytes([0xB3, 0x00]))                          # iret
    handler_code.extend(bytes([0xBA, 0x00]))                          # nop
    
    cpu.mem[handler_addr:handler_addr + len(handler_code)] = handler_code
    
    # Main program
    main_asm = """
    # Set exception vector table to 0x9000
    movi r3, 0x9000
    wrmsr r3, 0x004
    
    mov r10, 0
    
    # Enable MMU by setting CR3 and switching to user mode
    movi r3, 0x2000
    wrmsr r3, 0x003       # CSR_CR3 = 0x2000
    mov r3, 1
    wrmsr r3, 0x002       # CSR_MODE = 1 (user mode)
    
    # Access unmapped memory at VA 0x8000 → page fault
    movi r2, 0x8000
    ld r1, [r2 + 0]       # PAGE FAULT
    
    # After handler returns, R10 should be 1
    mov r5, 1
    eq r5, r10, r5
    add r10, r10, r5  # R10 = 2
    
    # Exit
    mov r1, 0
    add r2, r0, r10
    syscall 0
    """
    
    binary = assemble_code(main_asm, asm)
    program_base = 0x1000
    cpu.mem[program_base:program_base + len(binary)] = binary
    cpu.pc = program_base
    cpu.r[2] = cpu.mem_size - 0x1000
    
    simulate(cpu, max_steps=200, trace=False)
    
    expected_r10 = 2
    if cpu.r[10] == expected_r10:
        print(f"\n[PASS] Page fault exception test: R10={cpu.r[10]} (expected {expected_r10})")
    else:
        print(f"\n[FAIL] Page fault exception test: R10={cpu.r[10]} (expected {expected_r10})")
    
    return cpu.r[10] == expected_r10


def main():
    results = []
    results.append(("Div-by-Zero Exception", test_div_zero_exception()))
    results.append(("Page Fault Exception", test_page_fault_exception()))
    
    print(f"\n{'='*60}")
    print(f"  Exception Test Results")
    print(f"{'='*60}")
    passed = 0
    for name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"  [{status}] {name}")
        if result:
            passed += 1
    print(f"\n  {passed}/{len(results)} tests passed")
    print(f"{'='*60}")


if __name__ == '__main__':
    main()