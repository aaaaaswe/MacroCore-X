# MacroCore-X ISA Specification v1.0

## 1. Overview

| Item | Description |
|------|-------------|
| ISA Name | MacroCore-X |
| Version | v1.0 |
| Design Philosophy | CISC features retained (variable-length encoding, composite operations, rich addressing), legacy baggage pruned |
| Total Instructions | 98 (excluding 6 vector placeholders) |
| Encoding Length | 1-12 bytes (variable-length) |
| Addressing Modes | 5 modes (register / immediate / direct memory / base+offset / base+index+scale) |
| General-Purpose Registers | 16 × 64-bit (RAX–RBP, R8–R15) |
| Vector Registers (reserved) | 32 × 128-bit (V0–V31) |
| FLAGS | CF, ZF, SF, OF, AF, PF |

---

## 2. Complete Instruction Set Tables

### Category 1: Data Transfer (18 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| mov | Data Transfer | reg/mem, reg/imm | 2-8 | 88/8A/8B/8C/8E/B0-BF/C6/C7 | Yes | Opt | Opt | Opt | No | 1 | Yes |
| movzx | Data Transfer | reg, reg/mem (zero-extend) | 3-8 | 0F B6/B7 | Yes | Opt | Opt | No | No | 1 | Yes |
| movsx | Data Transfer | reg, reg/mem (sign-extend) | 3-8 | 0F BE/BF | Yes | Opt | Opt | No | No | 1 | Yes |
| movabs | Data Transfer | reg, imm64 | 10 | 48 B8-BF | No | No | No | 64-bit | No | 1 | No |
| lea | Data Transfer | reg, mem (address calc) | 3-8 | 8D | Yes | Opt | Opt | No | No | 1 | Yes |
| push | Data Transfer | reg/mem/imm | 2-5 | 50-57/68/6A/FF | Opt | No | No | Opt | No | 2-3 | Yes |
| pop | Data Transfer | reg/mem | 2-4 | 58-5F/8F | Opt | No | Opt | No | No | 2-3 | Yes |
| pusha | Data Transfer | none | 2 | 60 | No | No | No | No | No | 8 | No |
| popa | Data Transfer | none | 2 | 61 | No | No | No | No | No | 8 | No |
| load | Data Transfer | reg, mem | 2-7 | 8A/8B | Yes | Opt | Opt | No | No | 1 | Yes |
| store | Data Transfer | mem, reg | 2-7 | 88/89 | Yes | Opt | Opt | No | No | 1 | Yes |
| xchg | Data Transfer | reg/mem, reg | 2-4 | 86/87 | Yes | Opt | Opt | No | No | 2-3 | No |
| cmovcc | Data Transfer | reg, reg/mem | 3-8 | 0F 40-4F | Yes | Opt | Opt | No | No | 1 | No |
| bswap | Data Transfer | reg | 2 | 0F C8-CF | No | No | No | No | No | 1 | No |
| movsxd | Data Transfer | reg, reg/mem (32→64 sign-ext) | 3-8 | 63 | Yes | Opt | Opt | No | No | 1 | Yes |
| pext | Data Transfer | reg, reg/mem, reg | 4-8 | 0F 38 F5 | Yes | No | No | No | No | 2 | No |
| pdep | Data Transfer | reg, reg/mem, reg | 4-8 | 0F 38 F6 | Yes | No | No | No | No | 2 | No |
| prefetch | Data Transfer | mem | 3-7 | 0F 18 | No | Opt | Opt | No | No | 1 | No |

---

### Category 2: Integer Arithmetic (16 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| add | Arithmetic | reg/mem, reg/imm | 2-8 | 00/01/02/03/04/05/80/81/83 | Yes | Opt | Opt | Opt | All | 1 | Yes |
| add.m | Arithmetic | mem, reg/imm (mem composite) | 3-9 | 0F 01 00-03 | Yes | Opt | Opt | Opt | All | 3 | No |
| sub | Arithmetic | reg/mem, reg/imm | 2-8 | 28/29/2A/2B/2C/2D/80/81/83 | Yes | Opt | Opt | Opt | All | 1 | Yes |
| mul | Arithmetic | reg/mem (unsigned) | 2-7 | F7 (subcode 4) | Yes | Opt | Opt | No | CF, OF, ZF, SF, PF | 3 | No |
| imul | Arithmetic | reg/mem / reg,reg/mem / reg,reg/mem,imm | 2-8 | F7 (subcode 5)/0F AF/6B/69 | Yes | Opt | Opt | Opt | CF, OF, ZF, SF, PF | 2-3 | Yes |
| div | Arithmetic | reg/mem (unsigned) | 2-7 | F7 (subcode 6) | Yes | Opt | Opt | No | ZF, SF, PF | 4 | No |
| idiv | Arithmetic | reg/mem (signed) | 2-7 | F7 (subcode 7) | Yes | Opt | Opt | No | ZF, SF, PF | 4 | No |
| inc | Arithmetic | reg/mem | 2-4 | FE (subcode 0)/40-47 | Yes | Opt | Opt | No | OF, ZF, SF, AF, PF | 1 | Yes |
| dec | Arithmetic | reg/mem | 2-4 | FE (subcode 1)/48-4F | Yes | Opt | Opt | No | OF, ZF, SF, AF, PF | 1 | Yes |
| neg | Arithmetic | reg/mem | 2-7 | F7 (subcode 3) | Yes | Opt | Opt | No | All | 1 | No |
| adc | Arithmetic | reg/mem, reg/imm | 2-8 | 10/11/12/13/14/15/80/81/83 | Yes | Opt | Opt | Opt | All | 1 | No |
| sbb | Arithmetic | reg/mem, reg/imm | 2-8 | 18/19/1A/1B/1C/1D/80/81/83 | Yes | Opt | Opt | Opt | All | 1 | No |
| cmp | Compare | reg/mem, reg/imm | 2-8 | 38/39/3A/3B/3C/3D/80/81/83 | Yes | Opt | Opt | Opt | All | 1 | Yes |
| cmp.m | Compare | mem, reg/imm (mem composite) | 3-9 | 0F 01 08-0B | Yes | Opt | Opt | Opt | All | 2 | No |
| test | Test | reg/mem, reg/imm | 2-8 | 84/85/A8/A9/F6/F7 | Yes | Opt | Opt | Opt | ZF, SF, PF | 1 | Yes |
| test.m | Test | mem, reg/imm | 3-9 | 0F 01 10-13 | Yes | Opt | Opt | Opt | ZF, SF, PF | 2 | No |

---

### Category 3: Logic & Bit Operations (12 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| and | Logic | reg/mem, reg/imm | 2-8 | 20/21/22/23/24/25/80/81/83 | Yes | Opt | Opt | Opt | ZF, SF, PF, CF(0), OF(0) | 1 | Yes |
| or | Logic | reg/mem, reg/imm | 2-8 | 08/09/0A/0B/0C/0D/80/81/83 | Yes | Opt | Opt | Opt | ZF, SF, PF, CF(0), OF(0) | 1 | Yes |
| xor | Logic | reg/mem, reg/imm | 2-8 | 30/31/32/33/34/35/80/81/83 | Yes | Opt | Opt | Opt | ZF, SF, PF, CF(0), OF(0) | 1 | Yes |
| not | Logic | reg/mem | 2-7 | F7 (subcode 2) | Yes | Opt | Opt | No | No | 1 | No |
| shl | Shift | reg/mem, imm8/cl | 2-7 | C0/C1/D0/D1/D2/D3 | Yes | Opt | Opt | Opt | CF, ZF, SF, OF, PF | 1 | Yes |
| shr | Shift | reg/mem, imm8/cl | 2-7 | C0/C1/D0/D1/D2/D3 | Yes | Opt | Opt | Opt | CF, ZF, SF, OF, PF | 1 | Yes |
| sar | Shift | reg/mem, imm8/cl | 2-7 | C0/C1/D0/D1/D2/D3 | Yes | Opt | Opt | Opt | CF, ZF, SF, OF, PF | 1 | Yes |
| rol | Rotate | reg/mem, imm8/cl | 2-7 | C0/C1/D0/D1/D2/D3 | Yes | Opt | Opt | Opt | CF, OF | 1 | No |
| ror | Rotate | reg/mem, imm8/cl | 2-7 | C0/C1/D0/D1/D2/D3 | Yes | Opt | Opt | Opt | CF, OF | 1 | No |
| bt | Bit Test | reg/mem, reg/imm | 3-8 | 0F A3/A4/BA | Yes | Opt | Opt | Opt | CF | 1 | No |
| btr | Bit Test & Reset | reg/mem, reg/imm | 3-8 | 0F B3/BA | Yes | Opt | Opt | Opt | CF | 2 | No |
| bts | Bit Test & Set | reg/mem, reg/imm | 3-8 | 0F AB/BA | Yes | Opt | Opt | Opt | CF | 2 | No |

---

### Category 4: Control Transfer (14 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| jmp | Control Transfer | rel8/16/32 / reg/mem | 2-7 | EB/E9/FF (subcode 4) | Opt | No | 8/16/32 | No | No | 1-2 | Yes |
| jcc | Control Transfer | rel8/16/32 | 2-6 | 70-7F / 0F 80-8F | No | No | 8/16/32 | No | No | 1 | Yes |
| call | Control Transfer | rel32 / reg/mem | 3-7 | E8/FF (subcode 2) | Opt | No | 32 | No | No | 3-4 | Yes |
| ret | Control Transfer | imm16 (opt) | 1-3 | C3/C2 | No | No | No | Opt | No | 2-3 | Yes |
| retf | Control Transfer | imm16 (opt) | 2-4 | CB/CA | No | No | No | Opt | No | 4 | No |
| loop | Control Transfer | rel8 | 2 | E0-E2 | No | No | 8 | No | No | 1-2 | No |
| jrcxz | Control Transfer | rel8 | 2 | E3 | No | No | 8 | No | No | 1 | No |
| int | Control Transfer | imm8 | 2 | CD | No | No | No | 8 | No | 5+ | No |
| int3 | Control Transfer | none | 1 | CC | No | No | No | No | No | 1 | No |
| iret | Control Transfer | none | 2 | CF | No | No | No | No | All | 6 | No |
| syscall | System | none | 2 | 0F 05 | No | No | No | No | No | 4 | No |
| sysret | System | none | 2 | 0F 07 | No | No | No | No | No | 4 | No |
| xbegin | Control Transfer | rel16/32 | 4-8 | 0F C7 (subcode 6) | No | No | 16/32 | No | No | 2 | No |
| xend | Control Transfer | none | 3 | 0F 01 D5 | No | No | No | No | No | 1 | No |

---

### Category 5: System / Privileged Instructions (10 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| cpuid | System | none | 2 | 0F A2 | No | No | No | No | No | 3 | No |
| rdmsr | System | none | 2 | 0F 32 | No | No | No | No | No | 4 | No |
| wrmsr | System | none | 2 | 0F 30 | No | No | No | No | No | 4 | No |
| rdtsc | System | none | 2 | 0F 31 | No | No | No | No | No | 2 | No |
| hlt | System | none | 2 | F4 | No | No | No | No | No | 1 | No |
| cli | System | none | 2 | FA | No | No | No | No | No | 1 | No |
| sti | System | none | 2 | FB | No | No | No | No | No | 1 | No |
| in | System | reg, imm8/DX | 2-6 | E4/E5/EC/ED | No | No | No | Opt | No | 2 | No |
| out | System | imm8/DX, reg | 2-6 | E6/E7/EE/EF | No | No | No | Opt | No | 2 | No |
| lmsw | System | reg/mem | 3-7 | 0F 01 (subcode 6) | Yes | Opt | Opt | No | No | 2 | No |

---

### Category 6: Flag Operations (6 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| clc | Flag | none | 1 | F8 | No | No | No | No | CF=0 | 1 | No |
| stc | Flag | none | 1 | F9 | No | No | No | No | CF=1 | 1 | No |
| cmc | Flag | none | 1 | F5 | No | No | No | No | CF=~CF | 1 | No |
| cld | Flag | none | 1 | FC | No | No | No | No | DF=0 | 1 | No |
| std | Flag | none | 1 | FD | No | No | No | No | DF=1 | 1 | No |
| lahf | Flag | none | 1 | 9F | No | No | No | No | No | 1 | No |
| sahf | Flag | none | 1 | 9E | No | No | No | No | ZF, SF, CF, AF, PF | 1 | No |

---

### Category 7: String / Block Operations (6 instructions)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| movs | String | none | 2 | A4/A5 | No | No | No | No | No | 2+ | No |
| cmps | String | none | 2 | A6/A7 | No | No | No | No | ZF, SF, CF, OF, PF, AF | 2+ | No |
| scas | String | none | 2 | AE/AF | No | No | No | No | ZF, SF, CF, OF, PF, AF | 2+ | No |
| stos | String | none | 2 | AA/AB | No | No | No | No | No | 1+ | No |
| lods | String | none | 2 | AC/AD | No | No | No | No | No | 1+ | No |
| rep | Prefix | none | 1 | F2/F3 | No | No | No | No | Depends on parent | Variable | No |

---

### Category 8: Vector Extension Placeholders (6 instructions, reserved)

| Mnemonic | Category | Operands | Enc. Length | Opcode | ModR/M | SIB | Disp | Imm | FLAGS | µops | Hot |
|----------|----------|----------|-------------|--------|--------|-----|------|-----|-------|------|-----|
| vload | Vector (reserved) | Vreg, mem | 5-8 | 0F 38 80 | Yes | Opt | Opt | No | No | TBD | No |
| vstore | Vector (reserved) | mem, Vreg | 5-8 | 0F 38 81 | Yes | Opt | Opt | No | No | TBD | No |
| vadd | Vector (reserved) | Vreg, Vreg, Vreg | 5-7 | 0F 38 82 | Yes | No | No | No | No | TBD | No |
| vsub | Vector (reserved) | Vreg, Vreg, Vreg | 5-7 | 0F 38 83 | Yes | No | No | No | No | TBD | No |
| vmul | Vector (reserved) | Vreg, Vreg, Vreg | 5-7 | 0F 38 84 | Yes | No | No | No | No | TBD | No |
| vshuffle | Vector (reserved) | Vreg, Vreg, imm8 | 6-8 | 0F 3A 85 | Yes | No | No | 8 | No | TBD | No |

---

## 3. Addressing Mode Encoding Details

### ModR/M Byte Format

| Bit | 7-6 | 5-3 | 2-0 |
|-----|-----|-----|-----|
| Field | mod | reg/opcode | r/m |

**mod Field:**
- 00: Memory [base] (no displacement)
- 01: Memory [base + disp8] (8-bit displacement)
- 10: Memory [base + disp32] (32-bit displacement)
- 11: Register direct

**reg/opcode Field:**
- Operand register number (0-7), or extended opcode

**r/m Field:**
- mod=00-10: Memory base register or SIB encoding
- mod=11: Register number

### SIB Byte Format

| Bit | 7-6 | 5-3 | 2-0 |
|-----|-----|-----|-----|
| Field | scale | index | base |

- scale: 0=×1, 1=×2, 2=×4, 3=×8
- index: Index register number
- base: Base register number

### REX Prefix (for 64-bit extensions)

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|---|---|---|---|---|---|---|---|
| Field | 0x4 | 0x8 | W | R | X | B | 0 | 0 |

- W: 64-bit operand size
- R: Extends reg field bit 4
- X: Extends index field bit 4
- B: Extends r/m/base field bit 4

### Addressing Mode Examples

| Assembly Syntax | Encoding Example | Description |
|-----------------|------------------|-------------|
| `mov rax, rbx` | 48 8B C3 | REX.W + mov r,r (mod=11, reg=0, r/m=3) |
| `mov rax, [rbx]` | 48 8B 03 | REX.W + mov r,m (mod=00, reg=0, r/m=3) |
| `mov rax, [rbx+8]` | 48 8B 43 08 | mod=01, disp8=08 |
| `mov rax, [rbx+rcx*2]` | 48 8B 04 4B | SIB: scale=1, index=1, base=3 |
| `mov rax, [rip+0x1234]` | 48 8B 05 34 12 00 00 | RIP-relative addressing (mod=00, r/m=5) |
| `add [rax], rbx` | 48 01 18 | Memory composite: mod=00, reg=3, r/m=0 |
| `imul rax, [rbx], 0x10` | 48 6B 03 10 | 3-operand multiply: imm8=0x10 |

---

## 4. Opcode Allocation Overview

### Single-Byte Opcode (0x00-0xFF) Allocation Summary

| Range | Purpose | Count |
|-------|---------|-------|
| 00-05 | add (various operand combinations) | 6 |
| 08-0D | or | 6 |
| 10-15 | adc | 6 |
| 18-1D | sbb | 6 |
| 20-25 | and | 6 |
| 28-2D | sub | 6 |
| 30-35 | xor | 6 |
| 38-3D | cmp | 6 |
| 40-4F | inc/dec (register-specific) | 16 |
| 50-57 | push (register) | 8 |
| 58-5F | pop (register) | 8 |
| 60-61 | pusha/popa | 2 |
| 63 | movsxd | 1 |
| 68-6A | push imm | 3 |
| 70-7F | jcc (short 8-bit) | 16 |
| 80-83 | Multi-purpose (add/sub/and/or/xor/cmp, imm) | 4 |
| 84-85 | test | 2 |
| 86-87 | xchg | 2 |
| 88-8B | mov | 4 |
| 8C-8E | mov (segment registers) | 3 |
| 8D | lea | 1 |
| 8F | pop (mem) | 1 |
| 9E-9F | sahf/lahf | 2 |
| A4-A5 | movs | 2 |
| A6-A7 | cmps | 2 |
| A8-A9 | test (imm) | 2 |
| AA-AB | stos | 2 |
| AC-AD | lods | 2 |
| AE-AF | scas | 2 |
| B0-BF | mov (imm to reg) | 16 |
| C2-C3 | ret | 2 |
| C6-C7 | mov (mem/reg, imm) | 2 |
| CA-CB | retf | 2 |
| CC-CD | int3/int | 2 |
| CF | iret | 1 |
| D0-D3 | Shifts (1/cl) | 4 |
| E0-E2 | loop | 3 |
| E3 | jrcxz | 1 |
| E4-E5 | in (imm8) | 2 |
| E6-E7 | out (imm8) | 2 |
| E8 | call | 1 |
| E9 | jmp (rel32) | 1 |
| EA | jmp (far) | 1 |
| EB | jmp (rel8) | 1 |
| EC-ED | in/out (DX) | 2 |
| EE-EF | out/in (DX) | 2 |
| F4 | hlt | 1 |
| F5 | cmc | 1 |
| F6-F7 | test/not/neg/mul/div (multi-purpose) | 2 |
| F8 | clc | 1 |
| F9 | stc | 1 |
| FA | cli | 1 |
| FB | sti | 1 |
| FC | cld | 1 |
| FD | std | 1 |
| FE-FF | inc/dec/call/jmp (mem) | 2 |

### 2-Byte Opcode (0F XX) Allocation

| Range | Purpose |
|-------|---------|
| 0F 00-0F 0F | System/control (lmsw, xgetbv, etc.) |
| 0F 01 | System (partial) |
| 0F 05 | syscall |
| 0F 07 | sysret |
| 0F 18 | prefetch |
| 0F 30-31 | wrmsr/rdtsc |
| 0F 32 | rdmsr |
| 0F 38 XX | **Vector extension reserved (0F 38 80-FF)** |
| 0F 3A XX | **Vector extension reserved (0F 3A 80-FF)** |
| 0F 40-4F | cmovcc |
| 0F 80-8F | jcc (rel32) |
| 0F A2 | cpuid |
| 0F A3-A4 | bt |
| 0F AB | bts |
| 0F AF | imul |
| 0F B3 | btr |
| 0F B6-B7 | movzx |
| 0F BA | bt/btr/bts (imm) |
| 0F BE-BF | movsx |
| 0F C7 | xbegin |
| 0F C8-CF | bswap |

### Vector Extension Reserved Space

| Opcode | Purpose | Status |
|--------|---------|--------|
| 0F 38 80 | vload | Reserved |
| 0F 38 81 | vstore | Reserved |
| 0F 38 82 | vadd | Reserved |
| 0F 38 83 | vsub | Reserved |
| 0F 38 84 | vmul | Reserved |
| 0F 3A 85 | vshuffle | Reserved |
| 0F 38 86-FF | Future vector extensions | Reserved |
| 0F 3A 86-FF | Future vector extensions | Reserved |

---

## 5. Design Summary

### Statistics

| Metric | Value |
|--------|-------|
| Total Instructions (excluding vector placeholders) | **98** |
| Vector Placeholders | 6 |
| Hot Instructions (single-byte opcode) | 32 |
| Average µops (weighted) | ≈1.6 |
| Maximum µops (non-system) | 4 (mul/div) |
| Microcode-Assisted Instructions | int, syscall, sysret, pusha, popa |

### Pruning Rationale

Compared to traditional x86-64, this精简 version removes:
- BCD/decimal adjust instructions (DAA, DAS, AAA, AAS, AAM, AAD) → unused by modern compilers
- Most segmentation model instructions (except far jmp/call/retf retained for system use)
- Floating-point x87 instructions → superseded by vector extensions
- Redundant string instruction variants → retaining 6 core instructions
- Obsolete system instructions (e.g., into, bound)
- Partially simplified obsolete I/O instructions

### Average µop Estimate

| Instruction Type | Avg µops | Est. Mix | Weighted Contribution |
|------------------|----------|----------|----------------------|
| Simple ALU (reg-reg) | 1 | 40% | 0.40 |
| Load/Store (single) | 1 | 25% | 0.25 |
| Memory Composite (add [mem], reg) | 3 | 5% | 0.15 |
| Branches/Jumps | 1-2 | 15% | 0.23 |
| Multiply/Divide | 2-4 | 5% | 0.15 |
| System/Privileged | 2-6 | 5% | 0.20 |
| String | 2+ | 5% | 0.15 |
| **Weighted Average** | **≈1.53** | 100% | **1.53** |

### Vector Extension Recommendations

- **Register File**: 32 independent registers (V0–V31), each 128-bit wide (extendable to 256/512-bit in future)
- **Encoding Space**: Reserved 0F 38 80-FF and 0F 3A 80-FF
- **FLAGS**: Vector instructions do not update FLAGS (consistent with AVX design)
- **Recommended Extension Modules**: Basic SIMD (add/sub/mul/div), shuffle/permute, compare, type conversion, floating-point, cryptographic extensions

---

**This completes the MacroCore-X ISA v1.0 specification.**
