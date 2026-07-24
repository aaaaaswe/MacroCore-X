#!/usr/bin/env python3
"""
MacroCore-X MMU Test
Sets up a 4-level page table with 1:1 identity mapping for virtual 0x1000–0x1FFF
and 0x8000–0x8FFF, then runs user-mode code through the MMU.
"""

import sys
sys.path.insert(0, '.')
from simulator import CPU, load_binary, simulate, csr_write

PAGE_SIZE = 0x1000

def write64(mem, addr, val):
    mem[addr:addr+8] = val.to_bytes(8, 'little')

def make_pte(ppn, flags):
    """Create a 64-bit PTE: flags[7:0] | PPN[51:12]"""
    return (ppn << 12) | (flags & 0xFF)

def setup_page_tables(cpu: CPU):
    """Set up 4-level page table with 1:1 identity mapping.
    
    Maps: VA 0x1000-0x1FFF → PA 0x1000-0x1FFF (code)
          VA 0x8000-0x8FFF → PA 0x8000-0x8FFF (data)
    
    Page table layout in physical memory:
      L3 (root) at 0x2000
      L2 at 0x3000
      L1 at 0x4000
      L0 at 0x5000
    """
    mem = cpu.mem
    L3_ADDR = 0x2000
    L2_ADDR = 0x3000
    L1_ADDR = 0x4000
    L0_ADDR = 0x5000

    # PTE flags: V=1, R=1, X=1, W=1, U=1 (user accessible)
    leaf_flags = 0b01001111  # V|R|X|W|U = 0x4F
    # PTE flags for non-leaf: V=1 only (pointers)
    ptr_flags = 0b00000001  # V only

    # Level 3: entry 0 → L2
    write64(mem, L3_ADDR + 0, make_pte(L2_ADDR >> 12, ptr_flags))

    # Level 2: entry 0 → L1
    write64(mem, L2_ADDR + 0, make_pte(L1_ADDR >> 12, ptr_flags))

    # Level 1: entry 0 → L0
    write64(mem, L1_ADDR + 0, make_pte(L0_ADDR >> 12, ptr_flags))

    # Level 0: leaf entries
    # VPN[0]=1 → PA 0x1000 (code page)
    write64(mem, L0_ADDR + 1 * 8, make_pte(0x1, leaf_flags))
    # VPN[0]=8 → PA 0x8000 (data page)
    write64(mem, L0_ADDR + 8 * 8, make_pte(0x8, leaf_flags))

    # Set CR3 to point to L3
    cpu.csr_cr3 = L3_ADDR
    cpu._mmu_update()

def main():
    cpu = CPU(memory_size=0x100000)
    
    # Load test program at physical 0x1000
    # This program runs in user mode:
    #   movi r1, 0x1234
    #   stw r1, [r2 + 0]     ; write to VA 0x8000 (should be translated)
    #   ld r3, [r2 + 0]      ; read back from VA 0x8000
    #   movi r1, 0   ; exit code
    #   syscall 0
    program_base = 0x1000
    
    # Write test program directly to memory
    code = bytearray()
    # movi r2, 0x8000  (R2 = data base virtual address)
    code.extend(bytes([0x2A, 0x10, 0x00, 0x80, 0x00, 0x00]))
    # movi r1, 0x12345678
    code.extend(bytes([0x2A, 0x08, 0x78, 0x56, 0x34, 0x12]))
    # stw r1, [r2 + 0]  (store to VA 0x8000)
    code.extend(bytes([0x44, 0x12, 0x00, 0x00]))
    # ld r3, [r2 + 0]   (load from VA 0x8000)
    code.extend(bytes([0x40, 0x32, 0x00, 0x00]))
    # movi r1, 0
    code.extend(bytes([0x2A, 0x08, 0x00, 0x00, 0x00, 0x00]))
    # syscall 0  (exit)
    code.extend(bytes([0xB0, 0x00]))
    
    cpu.mem[program_base:program_base + len(code)] = code
    cpu.pc = program_base
    cpu.r[2] = cpu.mem_size - 0x1000  # stack pointer
    
    # Set up page tables
    setup_page_tables(cpu)
    
    # Switch to user mode (PRIV=1) to enable MMU
    cpu.priv = 1
    cpu._mmu_update()
    
    print(f"{'='*60}")
    print(f"  MacroCore-X MMU Test")
    print(f"{'='*60}")
    print(f"  CR3: 0x{cpu.csr_cr3:016x}")
    print(f"  PRIV: {cpu.priv}")
    print(f"  MMU enabled: {cpu.mmu_enabled}")
    print(f"  PC: 0x{cpu.pc:04x}")
    print(f"  Page tables at PA 0x2000-0x5FFF")
    print(f"  Identity mapping: VA 0x1000 → PA 0x1000 (code)")
    print(f"                    VA 0x8000 → PA 0x8000 (data)")
    print(f"{'='*60}\n")
    
    # Run simulation with trace
    simulate(cpu, max_steps=100, trace=True)
    
    # Verify result
    # R3 should be 0x12345678 (loaded from VA 0x8000, which maps to PA 0x8000)
    expected = 0x12345678
    if cpu.r[3] == expected:
        print(f"\n[PASS] MMU test passed: R3=0x{cpu.r[3]:08x} (expected 0x{expected:08x})")
    else:
        print(f"\n[FAIL] MMU test failed: R3=0x{cpu.r[3]:08x} (expected 0x{expected:08x})")
    
    # Verify data at PA 0x8000
    val = int.from_bytes(cpu.mem[0x8000:0x8004], 'little')
    if val == expected:
        print(f"[PASS] Memory at PA 0x8000 = 0x{val:08x} (correct)")
    else:
        print(f"[FAIL] Memory at PA 0x8000 = 0x{val:08x} (expected 0x{expected:08x})")

if __name__ == '__main__':
    main()