# MacroCore-X ISA Specification v1.0

## 1. Introduction

MacroCore-X is a modern CISC instruction set architecture designed for the Cascade-series microarchitectures. It follows the "macro-micro decoupling" philosophy: complex variable-length CISC instructions are decoded into simple RISC-style µops (µFlex) for efficient backend execution.

### 1.1 Key Features

- **Variable-length encoding**: 1–12 bytes per instruction
- **Rich addressing modes**: 5 modes (register, immediate, direct memory, base+offset, base+index+scale)
- **16 general-purpose registers**: 64-bit (RAX–RBP, R8–R15)
- **32 vector registers (reserved)**: 128-bit (V0–V31)
- **Flags**: CF, ZF, SF, OF, AF, PF
- **98 core instructions** (excluding 6 vector placeholders)
- **CISC-style composite operations**: e.g., `add [mem], reg` performs load-add-store in one instruction

### 1.2 Design Philosophy

| Principle | Description |
|-----------|-------------|
| Code Density | High-frequency instructions use short (1-byte) opcodes |
| Composite Operations | Single instruction can perform memory load + ALU op + store |
| Rich Addressing | Multiple addressing modes reduce instruction count in loops |
| Pruned Legacy | Removed BCD, segment model, x87 FPU, obsolete system instructions |
| Vector-Ready | Reserved opcode space for future SIMD/vector extensions |

---

## 2. Registers and Data Types

### 2.1 General-Purpose Registers (GPRs)

| Register | 64-bit Name | Purpose |
|----------|-------------|---------|
| RAX | 64-bit | Accumulator / Return value |
| RCX | 64-bit | Counter / Loop index |
| RDX | 64-bit | Data / I/O pointer |
| RBX | 64-bit | Base register (callee-saved) |
| RSP | 64-bit | Stack pointer |
| RBP | 64-bit | Frame pointer (callee-saved) |
| RSI | 64-bit | Source index |
| RDI | 64-bit | Destination index |
| R8–R15 | 64-bit | General-purpose (scratch) |
| RIP | 64-bit | Instruction pointer (not directly accessible) |
| RFLAGS | 64-bit | Status flags register |

### 2.2 Vector Registers (Reserved)

| Register Set | Width | Count | Purpose |
|--------------|-------|-------|---------|
| V0–V31 | 128-bit (extendable to 512-bit) | 32 | SIMD/Vector operations |

### 2.3 Flags (RFLAGS)

| Flag | Bit | Meaning | Set By |
|------|-----|---------|--------|
| CF | 0 | Carry Flag | Arithmetic (unsigned overflow) |
| PF | 2 | Parity Flag | Result parity check |
| AF | 4 | Auxiliary Carry | BCD operations (legacy) |
| ZF | 6 | Zero Flag | Result == 0 |
| SF | 7 | Sign Flag | Result < 0 (signed) |
| OF | 11 | Overflow Flag | Arithmetic (signed overflow) |
| DF | 10 | Direction Flag | String operations (set by CLD/STD) |

---

## 3. Instruction Encoding Format

### 3.1 Overall Structure
| Prefixes (optional) | Opcode (1–3 bytes) | ModR/M (optional) | SIB (optional) | Displacement (optional) | Immediate (optional) |
| 0–1 bytes | 1–3 bytes | 0–1 bytes | 0–1 bytes | 0–4 bytes | 0–8 bytes |


Total length: 1–12 bytes.

### 3.2 Prefixes

| Prefix | Value | Purpose |
|--------|-------|---------|
| LOCK | F0 | Atomic operation (bus lock) |
| REP/REPE/REPZ | F2/F3 | String repeat |
| REX | 40–4F | 64-bit operand / extended registers |

### 3.3 Opcode Formats

| Format | Length | Example |
|--------|--------|---------|
| 1-byte | 0x00–0xFF | 0x90 (NOP) |
| 2-byte | 0x0F 0xXX | 0x0F 0xA2 (CPUID) |
| 3-byte | 0x0F 0x38 0xXX / 0x0F 0x3A 0xXX | Vector extensions |

### 3.4 ModR/M Byte

| Bit | 7–6 | 5–3 | 2–0 |
|-----|-----|-----|-----|
| Field | Mod | Reg/Opcode | R/M |

| Mod | Meaning |
|-----|---------|
| 00 | Memory [base] (no displacement) |
| 01 | Memory [base + disp8] |
| 10 | Memory [base + disp32] |
| 11 | Register direct |

### 3.5 SIB Byte (Scale-Index-Base)

| Bit | 7–6 | 5–3 | 2–0 |
|-----|-----|-----|-----|
| Field | Scale | Index | Base |

| Scale | Factor |
|-------|--------|
| 00 | ×1 |
| 01 | ×2 |
| 10 | ×4 |
| 11 | ×8 |

### 3.6 REX Prefix (64-bit extensions)

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|---|---|---|---|---|---|---|---|
| Field | 0x4 | 0x8 | W | R | X | B | 0 | 0 |

- **W**: 64-bit operand size
- **R**: Extends Reg field bit 4
- **X**: Extends Index field bit 4
- **B**: Extends R/M / Base field bit 4

---

## 4. Addressing Modes

| Mode | Syntax | Encoding | Example |
|------|--------|----------|---------|
| Register direct | `reg` | mod=11, r/m=reg | `mov rax, rbx` |
| Immediate | `imm` | Immediate operand | `add rax, 0x10` |
| Memory direct | `[addr]` | disp32, mod=00, r/m=6 | `mov rax, [0x1000]` |
| Base + offset | `[base + disp]` | mod=01/10, r/m=base | `mov rax, [rbx+0x8]` |
| Base + index + scale | `[base + index*scale + disp]` | SIB byte | `mov rax, [rbx+rcx*2+0x8]` |
| RIP-relative | `[rip + disp]` | mod=00, r/m=5 | `mov rax, [rip+0x1234]` |

---

## 5. Instruction Set Reference

### 5.1 Data Transfer (18 instructions)

| Mnemonic | Operands | Opcode | FLAGS | µops | Description |
|----------|----------|--------|-------|------|-------------|
| `mov` | reg/mem, reg/imm | 88/8A/8B/8C/8E/B0-BF/C6/C7 | - | 1 | Move data |
| `movzx` | reg, reg/mem (zero-extend) | 0F B6/B7 | - | 1 | Move with zero extension |
| `movsx` | reg, reg/mem (sign-extend) | 0F BE/BF | - | 1 | Move with sign extension |
| `movabs` | reg, imm64 | 48 B8-BF | - | 1 | Move 64-bit immediate |
| `lea` | reg, mem | 8D | - | 1 | Load effective address |
| `push` | reg/mem/imm | 50-57/68/6A/FF | - | 2-3 | Push onto stack |
| `pop` | reg/mem | 58-5F/8F | - | 2-3 | Pop from stack |
| `pusha` | none | 60 | - | 8 | Push all registers |
| `popa` | none | 61 | - | 8 | Pop all registers |
| `load` | reg, mem | 8A/8B | - | 1 | Load from memory |
| `store` | mem, reg | 88/89 | - | 1 | Store to memory |
| `xchg` | reg/mem, reg | 86/87 | - | 2-3 | Exchange data |
| `cmovcc` | reg, reg/mem | 0F 40-4F | - | 1 | Conditional move |
| `bswap` | reg | 0F C8-CF | - | 1 | Byte swap |
| `movsxd` | reg, reg/mem (32→64) | 63 | - | 1 | Sign-extend 32-bit to 64-bit |
| `pext` | reg, reg/mem, reg | 0F 38 F5 | - | 2 | Parallel bit extract |
| `pdep` | reg, reg/mem, reg | 0F 38 F6 | - | 2 | Parallel bit deposit |
| `prefetch` | mem | 0F 18 | - | 1 | Prefetch data into cache |

### 5.2 Integer Arithmetic (16 instructions)

| Mnemonic | Operands | Opcode | FLAGS | µops | Description |
|----------|----------|--------|-------|------|-------------|
| `add` | reg/mem, reg/imm | 00/01/02/03/04/05/80/81/83 | All | 1 | Integer addition |
| `add.m` | mem, reg/imm | 0F 01 00-03 | All | 3 | Memory composite addition |
| `sub` | reg/mem, reg/imm | 28/29/2A/2B/2C/2D/80/81/83 | All | 1 | Integer subtraction |
| `mul` | reg/mem (unsigned) | F7 (code 4) | CF, OF, ZF, SF, PF | 3 | Unsigned multiply |
| `imul` | reg/mem / reg,reg/mem / reg,reg/mem,imm | F7(code 5)/0F AF/6B/69 | CF, OF, ZF, SF, PF | 2-3 | Signed multiply |
| `div` | reg/mem (unsigned) | F7 (code 6) | ZF, SF, PF | 4 | Unsigned divide |
| `idiv` | reg/mem (signed) | F7 (code 7) | ZF, SF, PF | 4 | Signed divide |
| `inc` | reg/mem | FE(code 0)/40-47 | OF, ZF, SF, AF, PF | 1 | Increment by 1 |
| `dec` | reg/mem | FE(code 1)/48-4F | OF, ZF, SF, AF, PF | 1 | Decrement by 1 |
| `neg` | reg/mem | F7 (code 3) | All | 1 | Two's complement negation |
| `adc` | reg/mem, reg/imm | 10/11/12/13/14/15/80/81/83 | All | 1 | Add with carry |
| `sbb` | reg/mem, reg/imm | 18/19/1A/1B/1C/1D/80/81/83 | All | 1 | Subtract with borrow |
| `cmp` | reg/mem, reg/imm | 38/39/3A/3B/3C/3D/80/81/83 | All | 1 | Compare |
| `cmp.m` | mem, reg/imm | 0F 01 08-0B | All | 2 | Memory composite compare |
| `test` | reg/mem, reg/imm | 84/85/A8/A9/F6/F7 | ZF, SF, PF | 1 | Logical AND test |
| `test.m` | mem, reg/imm | 0F 01 10-13 | ZF, SF, PF | 2 | Memory composite test |

### 5.3 Logic and Bit Operations (12 instructions)

| Mnemonic | Operands | Opcode | FLAGS | µops | Description |
|----------|----------|--------|-------|------|-------------|
| `and` | reg/mem, reg/imm | 20/21/22/23/24/25/80/81/83 | ZF, SF, PF, CF=0, OF=0 | 1 | Bitwise AND |
| `or` | reg/mem, reg/imm | 08/09/0A/0B/0C/0D/80/81/83 | ZF, SF, PF, CF=0, OF=0 | 1 | Bitwise OR |
| `xor` | reg/mem, reg/imm | 30/31/32/33/34/35/80/81/83 | ZF, SF, PF, CF=0, OF=0 | 1 | Bitwise XOR |
| `not` | reg/mem | F7 (code 2) | - | 1 | Bitwise NOT |
| `shl` | reg/mem, imm8/cl | C0/C1/D0/D1/D2/D3 | CF, ZF, SF, OF, PF | 1 | Shift left logical |
| `shr` | reg/mem, imm8/cl | C0/C1/D0/D1/D2/D3 | CF, ZF, SF, OF, PF | 1 | Shift right logical |
| `sar` | reg/mem, imm8/cl | C0/C1/D0/D1/D2/D3 | CF, ZF, SF, OF, PF | 1 | Shift right arithmetic |
| `rol` | reg/mem, imm8/cl | C0/C1/D0/D1/D2/D3 | CF, OF | 1 | Rotate left |
| `ror` | reg/mem, imm8/cl | C0/C1/D0/D1/D2/D3 | CF, OF | 1 | Rotate right |
| `bt` | reg/mem, reg/imm | 0F A3/A4/BA | CF | 1 | Bit test |
| `btr` | reg/mem, reg/imm | 0F B3/BA | CF | 2 | Bit test and reset |
| `bts` | reg/mem, reg/imm | 0F AB/BA | CF | 2 | Bit test and set |

### 5.4 Control Transfer (14 instructions)

| Mnemonic | Operands | Opcode | µops | Description |
|----------|----------|--------|------|-------------|
| `jmp` | rel8/16/32 / reg/mem | EB/E9/FF(code 4) | 1-2 | Unconditional jump |
| `jcc` | rel8/16/32 | 70-7F / 0F 80-8F | 1 | Conditional jump |
| `call` | rel32 / reg/mem | E8/FF(code 2) | 3-4 | Call procedure |
| `ret` | imm16 (optional) | C3/C2 | 2-3 | Return from procedure |
| `retf` | imm16 (optional) | CB/CA | 4 | Far return |
| `loop` | rel8 | E0-E2 | 1-2 | Loop with RCX counter |
| `jrcxz` | rel8 | E3 | 1 | Jump if RCX == 0 |
| `int` | imm8 | CD | 5+ | Software interrupt |
| `int3` | none | CC | 1 | Breakpoint trap |
| `iret` | none | CF | 6 | Interrupt return |
| `syscall` | none | 0F 05 | 4 | System call |
| `sysret` | none | 0F 07 | 4 | Return from system call |
| `xbegin` | rel16/32 | 0F C7(code 6) | 2 | Transactional begin |
| `xend` | none | 0F 01 D5 | 1 | Transactional end |

### 5.5 System/Privileged Instructions (10 instructions)

| Mnemonic | Operands | Opcode | µops | Description |
|----------|----------|--------|------|-------------|
| `cpuid` | none | 0F A2 | 3 | CPU identification |
| `rdmsr` | none | 0F 32 | 4 | Read MSR |
| `wrmsr` | none | 0F 30 | 4 | Write MSR |
| `rdtsc` | none | 0F 31 | 2 | Read timestamp counter |
| `hlt` | none | F4 | 1 | Halt processor |
| `cli` | none | FA | 1 | Clear interrupt flag |
| `sti` | none | FB | 1 | Set interrupt flag |
| `in` | reg, imm8/DX | E4/E5/EC/ED | 2 | Input from port |
| `out` | imm8/DX, reg | E6/E7/EE/EF | 2 | Output to port |
| `lmsw` | reg/mem | 0F 01(code 6) | 2 | Load machine status word |

### 5.6 Flag Operations (6 instructions)

| Mnemonic | Operands | Opcode | FLAGS | µops | Description |
|----------|----------|--------|-------|------|-------------|
| `clc` | none | F8 | CF=0 | 1 | Clear carry flag |
| `stc` | none | F9 | CF=1 | 1 | Set carry flag |
| `cmc` | none | F5 | CF=~CF | 1 | Complement carry flag |
| `cld` | none | FC | DF=0 | 1 | Clear direction flag |
| `std` | none | FD | DF=1 | 1 | Set direction flag |
| `lahf` | none | 9F | - | 1 | Load AH from flags |
| `sahf` | none | 9E | ZF, SF, CF, AF, PF | 1 | Store AH to flags |

### 5.7 String/Block Operations (6 instructions)

| Mnemonic | Operands | Opcode | FLAGS | µops | Description |
|----------|----------|--------|-------|------|-------------|
| `movs` | none | A4/A5 | - | 2+ | Move string |
| `cmps` | none | A6/A7 | ZF, SF, CF, OF, PF, AF | 2+ | Compare string |
| `scas` | none | AE/AF | ZF, SF, CF, OF, PF, AF | 2+ | Scan string |
| `stos` | none | AA/AB | - | 1+ | Store string |
| `lods` | none | AC/AD | - | 1+ | Load string |
| `rep` | prefix | F2/F3 | Varies | Variable | Repeat prefix |

### 5.8 Vector Extension Placeholders (6 instructions)

| Mnemonic | Operands | Opcode | FLAGS | µops | Description |
|----------|----------|--------|-------|------|-------------|
| `vload` | Vreg, mem | 0F 38 80 | - | TBD | Vector load |
| `vstore` | mem, Vreg | 0F 38 81 | - | TBD | Vector store |
| `vadd` | Vreg, Vreg, Vreg | 0F 38 82 | - | TBD | Vector addition |
| `vsub` | Vreg, Vreg, Vreg | 0F 38 83 | - | TBD | Vector subtraction |
| `vmul` | Vreg, Vreg, Vreg | 0F 38 84 | - | TBD | Vector multiplication |
| `vshuffle` | Vreg, Vreg, imm8 | 0F 3A 85 | - | TBD | Vector shuffle |

---

## 6. Opcode Allocation Map

### 6.1 Single-Byte Opcodes (0x00–0xFF)

| Range | Purpose | Count |
|-------|---------|-------|
| 00–05 | `add` (various operand combinations) | 6 |
| 08–0D | `or` | 6 |
| 10–15 | `adc` | 6 |
| 18–1D | `sbb` | 6 |
| 20–25 | `and` | 6 |
| 28–2D | `sub` | 6 |
| 30–35 | `xor` | 6 |
| 38–3D | `cmp` | 6 |
| 40–4F | `inc`/`dec` (register-specific) | 16 |
| 50–57 | `push` (register) | 8 |
| 58–5F | `pop` (register) | 8 |
| 60–61 | `pusha`/`popa` | 2 |
| 63 | `movsxd` | 1 |
| 68–6A | `push` (immediate) | 3 |
| 70–7F | `jcc` (short, 8-bit) | 16 |
| 80–83 | Multi-purpose (add/sub/and/or/xor/cmp with imm) | 4 |
| 84–85 | `test` | 2 |
| 86–87 | `xchg` | 2 |
| 88–8B | `mov` | 4 |
| 8C–8E | `mov` (segment registers) | 3 |
| 8D | `lea` | 1 |
| 8F | `pop` (mem) | 1 |
| 9E–9F | `sahf`/`lahf` | 2 |
| A4–A5 | `movs` | 2 |
| A6–A7 | `cmps` | 2 |
| A8–A9 | `test` (immediate) | 2 |
| AA–AB | `stos` | 2 |
| AC–AD | `lods` | 2 |
| AE–AF | `scas` | 2 |
| B0–BF | `mov` (immediate to register) | 16 |
| C2–C3 | `ret` | 2 |
| C6–C7 | `mov` (mem/reg, immediate) | 2 |
| CA–CB | `retf` | 2 |
| CC–CD | `int3`/`int` | 2 |
| CF | `iret` | 1 |
| D0–D3 | Shifts (by 1 or CL) | 4 |
| E0–E2 | `loop` | 3 |
| E3 | `jrcxz` | 1 |
| E4–E5 | `in` (immediate port) | 2 |
| E6–E7 | `out` (immediate port) | 2 |
| E8 | `call` | 1 |
| E9 | `jmp` (rel32) | 1 |
| EA | `jmp` (far) | 1 |
| EB | `jmp` (rel8) | 1 |
| EC–ED | `in`/`out` (DX port) | 2 |
| EE–EF | `out`/`in` (DX port) | 2 |
| F4 | `hlt` | 1 |
| F5 | `cmc` | 1 |
| F6–F7 | `test`/`not`/`neg`/`mul`/`div` (multi-purpose) | 2 |
| F8 | `clc` | 1 |
| F9 | `stc` | 1 |
| FA | `cli` | 1 |
| FB | `sti` | 1 |
| FC | `cld` | 1 |
| FD | `std` | 1 |
| FE–FF | `inc`/`dec`/`call`/`jmp` (memory) | 2 |

### 6.2 Two-Byte Opcodes (0F XX)

| Range | Purpose |
|-------|---------|
| 0F 00–0F 0F | System / Control (lmsw, xgetbv, etc.) |
| 0F 01 | System (partial, including xend) |
| 0F 05 | `syscall` |
| 0F 07 | `sysret` |
| 0F 18 | `prefetch` |
| 0F 30–31 | `wrmsr`/`rdtsc` |
| 0F 32 | `rdmsr` |
| **0F 38 XX** | **Vector extension reserved (0F 38 80–FF)** |
| **0F 3A XX** | **Vector extension reserved (0F 3A 80–FF)** |
| 0F 40–4F | `cmovcc` |
| 0F 80–8F | `jcc` (rel32) |
| 0F A2 | `cpuid` |
| 0F A3–A4 | `bt` |
| 0F AB | `bts` |
| 0F AF | `imul` |
| 0F B3 | `btr` |
| 0F B6–B7 | `movzx` |
| 0F BA | `bt`/`btr`/`bts` (with immediate) |
| 0F BE–BF | `movsx` |
| 0F C7 | `xbegin` (subcode 6) |
| 0F C8–CF | `bswap` |
| 0F 01 D5 | `xend` |

### 6.3 Vector Extension Reserved Space

| Opcode | Purpose | Status |
|--------|---------|--------|
| 0F 38 80 | `vload` | Reserved |
| 0F 38 81 | `vstore` | Reserved |
| 0F 38 82 | `vadd` | Reserved |
| 0F 38 83 | `vsub` | Reserved |
| 0F 38 84 | `vmul` | Reserved |
| 0F 3A 85 | `vshuffle` | Reserved |
| 0F 38 86–FF | Future vector extensions | Reserved |
| 0F 3A 86–FF | Future vector extensions | Reserved |

---

## 7. Design Summary

### 7.1 Statistics

| Metric | Value |
|--------|-------|
| Total instructions (excluding vector placeholders) | **98** |
| Vector placeholders | 6 |
| Hot instructions (single-byte opcode) | 32 |
| Average µops (weighted) | ≈1.6 |
| Maximum µops (non-system) | 4 (`mul`/`div`) |
| Microcode-assisted instructions | `int`, `syscall`, `sysret`, `pusha`, `popa` |

### 7.2 Pruning Rationale

Compared to traditional x86-64, this streamlined version removes:

- BCD/decimal adjust instructions (DAA, DAS, AAA, AAS, AAM, AAD) – unused by modern compilers
- Most segmentation model instructions (except far jump/call/retf retained for system use)
- Floating-point x87 instructions – superseded by vector extensions
- Redundant string instruction variants – retaining 6 core instructions
- Obsolete system instructions (e.g., `into`, `bound`)
- Partially simplified obsolete I/O instructions

### 7.3 Average µop Estimate

| Instruction Type | Avg µops | Est. Mix | Weighted Contribution |
|------------------|----------|----------|----------------------|
| Simple ALU (reg-reg) | 1 | 40% | 0.40 |
| Load/Store (single) | 1 | 25% | 0.25 |
| Memory Composite (`add [mem]`, reg) | 3 | 5% | 0.15 |
| Branches/Jumps | 1–2 | 15% | 0.23 |
| Multiply/Divide | 2–4 | 5% | 0.15 |
| System/Privileged | 2–6 | 5% | 0.20 |
| String | 2+ | 5% | 0.15 |
| **Weighted Average** | **≈1.53** | 100% | **1.53** |

### 7.4 Vector Extension Recommendations

| Item | Recommendation |
|------|----------------|
| Register File | 32 independent registers (V0–V31), each 128-bit wide (extendable to 256/512-bit) |
| Encoding Space | Reserved 0F 38 80–FF and 0F 3A 80–FF |
| FLAGS | Vector instructions do not update FLAGS (consistent with AVX design) |
| Recommended Extensions | Basic SIMD (add/sub/mul/div), shuffle/permute, compare, type conversion, floating-point, cryptographic extensions |

---

**This completes the MacroCore-X ISA v1.0 specification.**
