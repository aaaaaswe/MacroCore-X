#!/usr/bin/env python3
"""
MacroCore-X MMU Large Page Test
Tests 2MB large page mapping in the 4-level page table.
"""

import sys
sys.path.insert(0, '.')
from simulator import CPU, load_binary, simulate
from assembler import Assembler, tokenize, parse


def assemble_code(asm_source: str, assembler: Assembler) -> bytes:
    tokens = tokenize(asm_source)
    instructions = parse(tokens)
    assembler.output = bytearray()
    assembler.offset = 0
    assembler.labels = {}
    assembler.pending = []
    return assembler.assemble(instructions)


def write64(mem, addr, val):
    mem[addr:addr+8] = val.to_bytes(8, 'little')


def make_pte(ppn, flags):
    return (ppn << 12) | (flags & 0xFF)


def test_large_page():
    """
    Test 2MB large page mapping.
    
    A large page is identified by setting the leaf PTE at Level 1
    (instead of pointing to Level 0). This maps a 2MB region with
    a single PTE.
    
    Maps VA 0x200000-0x3FFFFF → PA 0x200000-0x3FFFFF
    """
    print(f"{'='*60}")
    print(f"  Test: MMU 2MB Large Page")
    print(f"{'='*60}")
    
    cpu = CPU(memory_size=0x400000)  # 4MB
    asm = Assembler()
    
    L3_ADDR = 0x10000
    L2_ADDR = 0x11000
    L1_ADDR = 0x12000
    
    leaf_flags = 0b01001111  # V|R|X|W|U
    ptr_flags = 0b00000001   # V only
    
    # Level 3: entry 0 → L2
    write64(cpu.mem, L3_ADDR + 0, make_pte(L2_ADDR >> 12, ptr_flags))
    
    # Level 2: entry 0 → L1
    write64(cpu.mem, L2_ADDR + 0, make_pte(L1_ADDR >> 12, ptr_flags))
    
    # Level 1: leaf entry for VPN[1]=1 → PA 0x200000 (2MB page)
    # PPN for 2MB page: PA[51:21], so PPN = 0x200000 >> 21 = 0x1
    write64(cpu.mem, L1_ADDR + 1 * 8, make_pte(0x1, leaf_flags))
    
    cpu.csr_cr3 = L3_ADDR
    
    # Write test data at PA 0x200000
    test_val = 0xDEADBEEFCAFEBABE
    cpu.mem[0x200000:0x200008] = test_val.to_bytes(8, 'little')
    
    # Main program: read from VA 0x200000 through MMU
    main_asm = """
    # Enable MMU
    movi r3, 0x10000
    wrmsr r3, 0x003      # CSR_CR3
    mov r3, 1
    wrmsr r3, 0x002      # CSR_MODE = user mode
    
    # Read from VA 0x200000 (should map to PA 0x200000 via 2MB page)
    movi r2, 0x200000
    ld r1, [r2 + 0]
    
    # Write to VA 0x200008
    movi r3, 0xCAFEBABEDEADBEEF
    st r3, [r2 + 8]
    
    # Read back
    ld r4, [r2 + 8]
    
    # Exit
    mov r1, 0
    mov r2, 0
    syscall 0
    """
    
    binary = assemble_code(main_asm, asm)
    program_base = 0x1000
    cpu.mem[program_base:program_base + len(binary)] = binary
    cpu.pc = program_base
    cpu.r[2] = cpu.mem_size - 0x1000
    
    simulate(cpu, max_steps=100, trace=False)
    
    # Verify
    passed = True
    if cpu.r[1] != test_val:
        print(f"[FAIL] Load from VA 0x200000: R1=0x{cpu.r[1]:016x} (expected 0x{test_val:016x})")
        passed = False
    else:
        print(f"[PASS] Load from VA 0x200000: R1=0x{cpu.r[1]:016x}")
    
    expected = 0xCAFEBABEDEADBEEF
    if cpu.r[4] != expected:
        print(f"[FAIL] Load from VA 0x200008: R4=0x{cpu.r[4]:016x} (expected 0x{expected:016x})")
        passed = False
    else:
        print(f"[PASS] Load from VA 0x200008: R4=0x{cpu.r[4]:016x}")
    
    # Verify data is at physical address
    actual_pa = int.from_bytes(cpu.mem[0x200008:0x200010], 'little')
    if actual_pa != expected:
        print(f"[FAIL] Memory at PA 0x200008: 0x{actual_pa:016x} (expected 0x{expected:016x})")
        passed = False
    else:
        print(f"[PASS] Memory at PA 0x200008: 0x{actual_pa:016x}")
    
    if passed:
        print(f"\n[PASS] All 2MB large page tests passed!")
    else:
        print(f"\n[FAIL] Some tests failed")
    
    return passed


def test_page_permission():
    """
    Test page permission violations.
    
    Maps a page as read-only and attempts to write to it,
    which should trigger a page fault.
    """
    print(f"\n{'='*60}")
    print(f"  Test: MMU Page Permission Violation")
    print(f"{'='*60}")
    
    cpu = CPU(memory_size=0x100000)
    asm = Assembler()
    
    L3_ADDR = 0x10000
    L2_ADDR = 0x11000
    L1_ADDR = 0x12000
    L0_ADDR = 0x13000
    
    ptr_flags = 0b00000001  # V only
    ro_flags = 0b01000011   # V|R|U (read-only, no write)
    
    write64(cpu.mem, L3_ADDR + 0, make_pte(L2_ADDR >> 12, ptr_flags))
    write64(cpu.mem, L2_ADDR + 0, make_pte(L1_ADDR >> 12, ptr_flags))
    write64(cpu.mem, L1_ADDR + 0, make_pte(L0_ADDR >> 12, ptr_flags))
    # Map VPN[0]=8 → PA 0x8000 as read-only
    write64(cpu.mem, L0_ADDR + 8 * 8, make_pte(0x8, ro_flags))
    
    cpu.csr_cr3 = L3_ADDR
    
    # Set up page fault handler at 0x9000
    handler_addr = 0x9000
    handler_code = bytearray()
    handler_code.extend(bytes([0x2A, 0x50, 0x01, 0x00, 0x00, 0x00]))  # movi r10, 1
    handler_code.extend(bytes([0xB4, 0xB0, 0x00, 0x00]))              # rdmsr r11, 0x000
    handler_code.extend(bytes([0x20, 0x5A, 0xC0, 0x04]))              # addi r11, r11, 4
    handler_code.extend(bytes([0xB5, 0xB0, 0x00, 0x00]))              # wrmsr r11, 0x000
    handler_code.extend(bytes([0xB3, 0x00]))                          # iret
    handler_code.extend(bytes([0xBA, 0x00]))                          # nop
    cpu.mem[handler_addr:handler_addr + len(handler_code)] = handler_code
    
    main_asm = """
    # Set exception vector table
    movi r3, 0x9000
    wrmsr r3, 0x004
    
    mov r10, 0
    
    # Enable MMU
    movi r3, 0x10000
    wrmsr r3, 0x003
    mov r3, 1
    wrmsr r3, 0x002
    
    # Try to write to read-only page at VA 0x8000
    movi r2, 0x8000
    movi r3, 0xDEAD
    st r3, [r2 + 0]     # PAGE FAULT (write to read-only page)
    
    # After handler: R10 should be 1
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
        print(f"\n[PASS] Page permission test: R10={cpu.r[10]} (expected {expected_r10})")
        return True
    else:
        print(f"\n[FAIL] Page permission test: R10={cpu.r[10]} (expected {expected_r10})")
        return False


def main():
    results = []
    results.append(("2MB Large Page", test_large_page()))
    results.append(("Page Permission", test_page_permission()))
    
    print(f"\n{'='*60}")
    print(f"  MMU Large Page Test Results")
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