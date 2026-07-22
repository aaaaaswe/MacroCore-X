# MacroCore-X v2.0 Instruction Set Architecture Specification

**Version**: 2.0  
**Status**: Draft  
**Target**: General-purpose 64-bit desktop/server processors  
**Encoding**: Variable-length (2/4/6/8 bytes)  
**Endianness**: Little-Endian

---

## Chapter 1: Overall Architecture

### 1.1 Execution State

| Component | Count | Width | Description |
|-----------|-------|-------|-------------|
| General-purpose registers (GR) | 32 | 64-bit | R0–R31 |
| Vector registers (VR) | 32 | 256-bit | V0–V31 |
| Program counter (PC) | 1 | 64-bit | Points to current instruction's first byte |
| Stack pointer (SP) | 1 | 64-bit | Software convention: R2 (not hardwired) |
| Flags register (FLAGS) | 1 | 4-bit | CF / ZF / SF / OF |
| Mode register (MODE) | 1 | 64-bit | Privilege level, vector length, alignment policy, etc. |

### 1.2 Register Definitions

**R0**: Hardwired to zero. Writes are ignored; reads return 0.  
**R1–R7**: Parameter passing (caller-saved).  
**R8–R15**: Temporary / local variables (caller-saved).  
**R16–R23**: Callee-saved.  
**R24–R30**: General-purpose reserved.  
**R31**: **Return Address Register (RA)**. `call`/`callreg` automatically write PC + current instruction length; `ret` jumps to the contents of R31.

> Note: SP is conventionally R2, but the ISA does **not** hardwire this—compilers are free to choose any register as the stack pointer.

### 1.3 Vector Registers

V0–V31, 256 bits wide, capable of holding:
- 4 × 64-bit integers/floats
- 8 × 32-bit integers/floats
- 16 × 16-bit integers
- 32 × 8-bit integers

Vector operations operate on **element width** as specified by the instruction suffix/encoding.

---

## Chapter 2: Instruction Encoding

### 2.1 Length Determination (Hard Decoding Rule)

The **top 2 bits** of the first byte of each instruction determine its total length:

| `byte0[7:6]` | Instruction Length | Category Range |
|--------------|-------------------|----------------|
| `00` | 2 bytes | R-type (opcodes 0x00–0x1F) |
| `01` | 4 bytes | I/L/B-type (opcodes 0x20–0x7F) |
| `10` | 6 bytes | V/C extended types (opcodes 0x80–0xBF) |
| `11` | 8 bytes | Long instructions (opcodes 0xC0–0xFF) |

**Decoders must determine the length in the first cycle solely from bits[7:6] of byte0, without parsing subsequent bytes.**

### 2.2 Instruction Field Definitions

| Field | Abbr. | Width (bits) | Description |
|-------|-------|--------------|-------------|
| Opcode | OP | 2–8 | Instruction functionality |
| Destination register | Rd | 4 | GR number (0–31) |
| Source register 1 | Rs1 | 4 | GR number |
| Source register 2 | Rs2 | 4 | GR number |
| Immediate | IMM | 5–32 | Sign- or zero-extended |
| Offset | OFF | 12–21 | Relative jump / memory offset |
| Extension flags | X | 1–4 | Width / atomic / condition modifiers |

### 2.3 Opcode Map (Complete)

| Opcode Range | Category | Length | Primary Use |
|--------------|----------|--------|-------------|
| 0x00–0x1F | **R-type** | 2 bytes | Register–register operations |
| 0x20–0x3F | **I-type** | 4 bytes | Immediate operations / loads |
| 0x40–0x5F | **L-type** | 4/6 bytes | Load / store |
| 0x60–0x7F | **B-type** | 4 bytes | Branches / jumps |
| 0x80–0x8F | **V-type** | 6/8 bytes | Vector operations |
| 0x90–0x9F | **C-type** | 6/8 bytes | Composite memory operations |
| 0xA0–0xBF | **System-type** | 2/4 bytes | Privileged / management |
| 0xC0–0xFF | **Reserved** | variable | Future extensions |

---

## Chapter 3: Instruction Definitions

### 3.1 R-type Instructions (2 bytes, OP 0x00–0x1F)

**Format**:
```
Bits:   7:4       3:0
        ┌─────────┬─────────┐
byte0   │ OP      │ subtype │
        ├─────────┼─────────┤
byte1   │ Rs1     │ Rs2     │
        └─────────┴─────────┘
```
Note: Rd = Rs1 (destination = source 1), or implied by subtype.

#### R-type Instruction List

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x00 | `add` | Rs1, Rs2 | R[Rs1] ← R[Rs1] + R[Rs2] |
| 0x01 | `sub` | Rs1, Rs2 | R[Rs1] ← R[Rs1] - R[Rs2] |
| 0x02 | `mul` | Rs1, Rs2 | R[Rs1] ← R[Rs1] × R[Rs2] (low 64 bits) |
| 0x03 | `div` | Rs1, Rs2 | R[Rs1] ← R[Rs1] ÷ R[Rs2] (signed, truncate toward zero) |
| 0x04 | `divu` | Rs1, Rs2 | R[Rs1] ← R[Rs1] ÷ R[Rs2] (unsigned) |
| 0x05 | `and` | Rs1, Rs2 | R[Rs1] ← R[Rs1] & R[Rs2] |
| 0x06 | `or` | Rs1, Rs2 | R[Rs1] ← R[Rs1] \| R[Rs2] |
| 0x07 | `xor` | Rs1, Rs2 | R[Rs1] ← R[Rs1] ^ R[Rs2] |
| 0x08 | `shl` | Rs1, Rs2 | R[Rs1] ← R[Rs1] << (R[Rs2] & 0x3F) |
| 0x09 | `shr` | Rs1, Rs2 | R[Rs1] ← R[Rs1] >> (R[Rs2] & 0x3F) (logical) |
| 0x0A | `sar` | Rs1, Rs2 | R[Rs1] ← R[Rs1] >> (R[Rs2] & 0x3F) (arithmetic) |
| 0x0B | `eq` | Rs1, Rs2 | R[Rs1] ← (R[Rs1] == R[Rs2]) ? 1 : 0 |
| 0x0C | `lt` | Rs1, Rs2 | R[Rs1] ← (R[Rs1] < R[Rs2]) ? 1 : 0 (signed) |
| 0x0D | `ltu` | Rs1, Rs2 | R[Rs1] ← (R[Rs1] < R[Rs2]) ? 1 : 0 (unsigned) |
| 0x0E | `max` | Rs1, Rs2 | R[Rs1] ← max(R[Rs1], R[Rs2]) (signed) |
| 0x0F | `min` | Rs1, Rs2 | R[Rs1] ← min(R[Rs1], R[Rs2]) (signed) |
| 0x10 | `ror` | Rs1, Rs2 | R[Rs1] ← R[Rs1] rotate right (R[Rs2] & 0x3F) |
| 0x11 | `rol` | Rs1, Rs2 | R[Rs1] ← R[Rs1] rotate left (R[Rs2] & 0x3F) |
| 0x12 | `clz` | Rs1 | R[Rs1] ← count leading zeros of R[Rs1] |

> All R-type instructions update FLAGS: CF/ZF/SF/OF (for arithmetic/logic); `eq`/`lt`/`ltu` update only ZF; `clz` does not update flags.

---

### 3.2 I-type Instructions (4 bytes, OP 0x20–0x3F)

**Format** (pseudocode representation; actual bit packing is compact):
```
byte0: [OP 6 bits][Rd high 2 bits]
byte1: [Rd low 2 bits][Rs1 4 bits][X 2 bits]
byte2-3: IMM16 (little-endian)
```

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x20 | `addi` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] + sext(imm16) |
| 0x21 | `subi` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] - sext(imm16) |
| 0x22 | `muli` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] × sext(imm16) |
| 0x23 | `andi` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] & zext(imm16) |
| 0x24 | `ori` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] \| zext(imm16) |
| 0x25 | `xori` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] ^ zext(imm16) |
| 0x26 | `shli` | Rd, Rs1, imm5 | R[Rd] ← R[Rs1] << imm5 (IMM[4:0]) |
| 0x27 | `shri` | Rd, Rs1, imm5 | R[Rd] ← R[Rs1] >> imm5 (logical) |
| 0x28 | `sari` | Rd, Rs1, imm5 | R[Rd] ← R[Rs1] >> imm5 (arithmetic) |
| 0x29 | `mov` | Rd, imm16 | R[Rd] ← sext(imm16) |
| 0x2A | `movi` | Rd, imm32 | R[Rd] ← zext(imm32) (6-byte extension) |
| 0x2B-0x3F | *Reserved* | — | — |

> Flag update rules same as R-type.

---

### 3.3 L-type Instructions (Load/Store, 4/6 bytes, OP 0x40–0x5F)

**Format (4-byte)**:
```
byte0: [OP 4 bits][Rd 4 bits]
byte1: [Rs1 4 bits][SZ 2 bits][X 2 bits]
byte2-3: OFF16 (little-endian, signed offset)
```

**Format (6-byte indexed addressing, OP 0x50–0x5F)**:
```
byte0-1: same as above
byte2-3: OFF16
byte4-5: Rn (index register number) + scale (2 bits)
```

**SZ field (bits[3:2])**:
- `00` = 8-bit
- `01` = 16-bit
- `10` = 32-bit
- `11` = 64-bit

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x40 | `ld` | Rd, [Rs1 + off] | R[Rd] ← zext(Mem[Rs1+off, 64]) |
| 0x41 | `ldu` | Rd, [Rs1 + off] | R[Rd] ← zext(Mem[Rs1+off, SZ]) (SZ=10/01/00) |
| 0x42 | `lds` | Rd, [Rs1 + off] | R[Rd] ← sext(Mem[Rs1+off, SZ]) (SZ≠11) |
| 0x43 | `st` | Rs1, [Rs2 + off] | Mem[Rs2+off, 64] ← R[Rs1] |
| 0x44 | `stw` | Rs1, [Rs2 + off] | Mem[Rs2+off, 32] ← R[Rs1] (low 32 bits) |
| 0x45 | `stb` | Rs1, [Rs2 + off] | Mem[Rs2+off, 8] ← R[Rs1] (low 8 bits) |
| 0x46 | `lda` | Rd, Rs1, Rs2, scale | R[Rd] ← R[Rs1] + R[Rs2] × scale (scale=1/2/4/8) |
| 0x50 | `ldr` | Rd, [Rs1 + Rn*scale + off] | R[Rd] ← Mem[Rs1 + Rn×scale + off, 64] (6 bytes) |
| 0x51 | `str` | Rs1, [Rs2 + Rn*scale + off] | Mem[Rs2 + Rn×scale + off, 64] ← R[Rs1] (6 bytes) |
| 0x52-0x5F | *Reserved* | — | — |

> L-type instructions do **not** update FLAGS.

---

### 3.4 B-type Instructions (Branch/Jump, 4 bytes, OP 0x60–0x7F)

**Format**:
```
byte0:   [OP 4 bits][Rs1 4 bits]
byte1:   [Rs2 4 bits][IMM12 high 4 bits]
byte2-3: IMM12 low 8 bits + padding
```

**Offset calculation**: `target = PC + sign_ext(IMM12) << 2` (conditional branches)  
`target = PC + sign_ext(IMM20) << 2` (`j`/`call`, using all 20 bits)

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x60 | `j` | target20 | PC ← PC + sext(imm20)<<2 |
| 0x61 | `call` | target20 | R31 ← PC + 4; PC ← PC + sext(imm20)<<2 |
| 0x62 | `ret` | — | PC ← R[31] |
| 0x63 | `beq` | Rs1, Rs2, target12 | if (R[Rs1] == R[Rs2]) PC ← PC + sext(imm12)<<2 |
| 0x64 | `bne` | Rs1, Rs2, target12 | if (R[Rs1] != R[Rs2]) PC ← PC + sext(imm12)<<2 |
| 0x65 | `blt` | Rs1, Rs2, target12 | if (R[Rs1] < R[Rs2]) PC ← PC + sext(imm12)<<2 (signed) |
| 0x66 | `ble` | Rs1, Rs2, target12 | if (R[Rs1] ≤ R[Rs2]) PC ← PC + sext(imm12)<<2 (signed) |
| 0x67 | `bgt` | Rs1, Rs2, target12 | if (R[Rs1] > R[Rs2]) PC ← PC + sext(imm12)<<2 (signed) |
| 0x68 | `bge` | Rs1, Rs2, target12 | if (R[Rs1] ≥ R[Rs2]) PC ← PC + sext(imm12)<<2 (signed) |
| 0x69 | `bltu` | Rs1, Rs2, target12 | if (R[Rs1] < R[Rs2]) PC ← PC + sext(imm12)<<2 (unsigned) |
| 0x6A | `bgeu` | Rs1, Rs2, target12 | if (R[Rs1] ≥ R[Rs2]) PC ← PC + sext(imm12)<<2 (unsigned) |
| 0x6B | `jreg` | Rs1 | PC ← R[Rs1] |
| 0x6C | `callreg` | Rs1 | R31 ← PC + 4; PC ← R[Rs1] |
| 0x6D-0x7F | *Reserved* | — | — |

> `call` and `callreg` store `PC + 4` in R31 because all B-type instructions are 4 bytes. `ret` does **not** validate R[31]—software must ensure it is valid.

---

### 3.5 V-type Instructions (Vector, 6/8 bytes, OP 0x80–0x8F)

**Format (6-byte)**:
```
byte0:   [0x8 4 bits][Vd 4 bits]
byte1:   [Vs1 4 bits][Vs2 4 bits]
byte2:   FUNCT8 (operation code)
byte3:   AUX (precision / mask / shuffle control)
byte4-5: EXT (offset for vld/vst, Vs3 for vfmadd)
```

**Format (8-byte fused multiply-add)**:
```
byte0-5: same as above
byte4-5: Vs3 (for vfmadd, byte6-7 re-purposed as Vs3)
```

For vector instructions, element width is specified by the low 2 bits of AUX (byte3):
- `00` = 8-bit
- `01` = 16-bit
- `10` = 32-bit
- `11` = 64-bit

For scalar FP instructions, AUX (byte3) encodes precision and rounding mode:
- AUX[0]: precision (0 = f32, 1 = f64)
- AUX[2:1]: rounding mode (0 = RNE, 1 = RTZ, 2 = RDN, 3 = RUP)

| FUNCT | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x00 | `vadd` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] + V[Vs2][i] |
| 0x01 | `vsub` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] - V[Vs2][i] |
| 0x02 | `vmul` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] × V[Vs2][i] |
| 0x03 | `vand` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] & V[Vs2][i] |
| 0x04 | `vor` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] \| V[Vs2][i] |
| 0x05 | `vxor` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] ^ V[Vs2][i] |
| 0x06 | `vld` | Vd, [Rs1 + off16] | V[Vd] ← Mem[Rs1+off, 256] (aligned) |
| 0x07 | `vst` | Vd, [Rs1 + off16] | Mem[Rs1+off, 256] ← V[Vd] (aligned) |
| 0x08 | `vshl` | Vd, Vs1, imm5 | V[Vd][i] ← V[Vs1][i] << imm5 (element-wise) |
| 0x09 | `vshr` | Vd, Vs1, imm5 | V[Vd][i] ← V[Vs1][i] >> imm5 (logical) |
| 0x0A | `vshuffle` | Vd, Vs1, imm8 | V[Vd][i] ← V[Vs1][ imm8[i] ] (byte shuffle, 8 bytes) |
| 0x0B | `vfmadd` | Vd, Vs1, Vs2, Vs3 | V[Vd][i] ← V[Vs1][i]×V[Vs2][i]+V[Vs3][i] (8 bytes) |
| 0x0C | `vfadd.s` | Vd, Vs1, Vs2 | V[Vd] ← float(V[Vs1]) + float(V[Vs2]) (scalar IEEE 754) |
| 0x0D | `vfsub.s` | Vd, Vs1, Vs2 | V[Vd] ← float(V[Vs1]) - float(V[Vs2]) (scalar IEEE 754) |
| 0x0E | `vfmul.s` | Vd, Vs1, Vs2 | V[Vd] ← float(V[Vs1]) × float(V[Vs2]) (scalar IEEE 754) |
| 0x0F | `vfdiv.s` | Vd, Vs1, Vs2 | V[Vd] ← float(V[Vs1]) ÷ float(V[Vs2]) (scalar IEEE 754) |
| 0x10-0xFF | *Reserved* | — | — |

---

### 3.6 C-type Instructions (Composite CISC, 6/8 bytes, OP 0x90–0x9F)

All C-type instructions are decomposed into multiple µops at the microarchitecture level, but are **atomic** at the ISA level (unless explicitly noted).

| OP | Mnemonic | Operands | Semantics | µop decomposition |
|----|----------|----------|-----------|-------------------|
| 0x90 | `addm` | Rs1, [Rs2 + off] | Mem[Rs2+off] ← Mem[Rs2+off] + R[Rs1] | ld→add→st |
| 0x91 | `subm` | Rs1, [Rs2 + off] | Mem[Rs2+off] ← Mem[Rs2+off] - R[Rs1] | ld→sub→st |
| 0x92 | `xchg` | Rs1, [Rs2 + off] | Exchange R[Rs1] ↔ Mem[Rs2+off] (atomic) | ld→st |
| 0x93 | `cmpxchg` | Rs1, Rs2, [Rs3+off] | if (Mem[Rs3+off] == R[Rs1]) Mem←R[Rs2] (atomic, 8 bytes) | ld→cmp→st |
| 0x94 | `push` | Rs1 | SP←SP-8; Mem[SP,64] ← R[Rs1] | sub→st |
| 0x95 | `pop` | Rs1 | R[Rs1] ← Mem[SP,64]; SP←SP+8 | ld→add |
| 0x96 | `enter` | imm16 | SP←SP-imm16; Mem[SP,64]←R[30] (save RBP) | sub→st |
| 0x97 | `leave` | — | SP←R[30]+8; R[30]←Mem[SP-8,64] | ld→add |
| 0x98-0x9F | *Reserved* | — | — |

> `push`/`pop` use **R2 as SP** (convention); `enter` uses R30 as the frame pointer (convention). Neither is enforced by the ISA.

---

### 3.7 System Instructions (2/4 bytes, OP 0xA0–0xBF)

| OP | Mnemonic | Operands | Semantics | Length |
|----|----------|----------|-----------|--------|
| 0xA0 | `syscall` | imm8 | Raise system call (imm8 → syscall number, enter kernel mode) | 2 |
| 0xA1 | `sysret` | — | Return from system call (restore user mode) | 2 |
| 0xA2 | `int` | imm8 | Software interrupt (imm8 → interrupt vector) | 2 |
| 0xA3 | `iret` | — | Return from interrupt | 2 |
| 0xA4 | `rdmsr` | Rs1, imm12 | R[Rs1] ← MSR[imm12] | 4 |
| 0xA5 | `wrmsr` | Rs1, imm12 | MSR[imm12] ← R[Rs1] | 4 |
| 0xA6 | `cpuid` | — | Fill R0:R1:R2:R3 with vendor/features/cache/version info | 2 |
| 0xA7 | `hlt` | — | Halt execution until interrupt | 2 |
| 0xA8 | `cli` | — | Clear interrupt enable flag (IF=0) | 2 |
| 0xA9 | `sti` | — | Set interrupt enable flag (IF=1) | 2 |
| 0xAA | `nop` | — | No operation (PC ← PC + 2) | 2 |
| 0xAB | `ecall` | imm8 | Environment call (emulator/debug entry point) | 2 |
| 0xAC-0xBF | *Reserved* | — | — | variable |

---

## Chapter 4: Exceptions and Interrupts

### 4.1 Exception Vector Table

| Vector | Name | Trigger Condition |
|--------|------|-------------------|
| 0x00 | Divide-by-zero | `div`/`divu` with divisor 0 |
| 0x01 | Illegal instruction | Undefined opcode |
| 0x02 | Alignment fault | Unaligned access and MODE.ALIGN=1 |
| 0x03 | Page fault | MMU page missing / permission violation |
| 0x04 | Breakpoint | `ecall` instruction |
| 0x05 | System call | `syscall` instruction |
| 0x06 | External interrupt | Hardware IRQ |
| 0x07-0x1F | Reserved | Custom usage |

### 4.2 Exception Handling Flow

1. Save current PC to the **exception return register (ERR)** (internal, not visible);
2. Save current FLAGS to **EF (exception flags)**;
3. Enter privileged mode (MODE.PRIV=0);
4. PC ← exception vector base + vector × 8;
5. Execute exception handler.

`iret` restores from exception: FLAGS ← EF, PC ← ERR.

---

## Chapter 5: Memory Model

### 5.1 Address Space

- 64-bit flat address space, virtual address width **48 bits** (current implementation), physical address width **52 bits** (configurable).
- Supports 4KB, 2MB, and 1GB pages (implementation-defined by MMU).

### 5.2 Alignment Policy

The MODE.ALIGN bit controls behavior:
- `0`: Unaligned accesses are permitted (handled by microarchitecture)
- `1`: Unaligned accesses raise #alignment fault

### 5.3 Memory Ordering

**Weak Memory Model** — no ordering guarantees. A `fence` instruction (reserved opcode 0xAC) is required to enforce ordering.

`fence` instruction format is reserved (encoding not yet assigned).

---

## Chapter 6: Assembly Syntax

### 6.1 Syntax Style (Simplified AT&T)

```
<instruction> <dest>, <src1>, <src2>
```

**Examples**:
```
add r1, r2          # R-type: r1 = r1 + r2
addi r3, r1, 0x100  # I-type: r3 = r1 + 256
ld r4, [r2 + 0x8]   # Load 64-bit
st r5, [r3 - 0x4]   # Store 64-bit
call 0x10000        # Function call
vadd v1, v2, v3     # Vector addition
push r6             # Push to stack
syscall 0x1         # System call
```

### 6.2 Pseudo-Instructions

| Pseudo | Expansion |
|--------|-----------|
| `li Rd, imm` | `mov Rd, imm` (if imm ≤ 16 bits) or `movi Rd, imm` (if imm > 16 bits) |
| `la Rd, label` | `lda Rd, PC, label, 1` (address calculation) |
| `nop` | `add r0, r0` (or dedicated `nop`) |

---

## Chapter 7: Ecosystem Integration

### 7.1 ELF File Format

Requires definition of:
- **EM_MACROCORE** machine code (pending assignment)
- **Relocation types**: R_MACRO_32, R_MACRO_64, R_MACRO_PC20, R_MACRO_PC12
- **ABI version**: Macro-kernel (Linux-style) or micro-kernel

### 7.2 System Call ABI

Convention (Linux x86_64 compatible, simplified):
- System call number: R1
- Arguments 1–6: R2–R7
- Return value: R1
- System call instruction: `syscall 0x0` (uses syscall number from R1)

---

## Appendix A: Instruction Encoding Table (Byte-level, Partial)

| Mnemonic | byte0 (hex) | Length | Format |
|----------|-------------|--------|--------|
| `add` | 0x00 | 2 | R |
| `sub` | 0x01 | 2 | R |
| `mul` | 0x02 | 2 | R |
| `div` | 0x03 | 2 | R |
| `divu` | 0x04 | 2 | R |
| ... (full table omitted for brevity) | | | |
| `syscall` | 0xA0 | 2 | SYS |
| `cpuid` | 0xA6 | 2 | SYS |
| `nop` | 0xAA | 2 | SYS |

> Complete encoding tables require operand packers; this document provides the authoritative reference.

---

## Appendix B: Design Decision Log

| Decision | Rationale |
|----------|-----------|
| 2/4/6/8-byte variable length | Decoder determines length in first cycle via top 2 bits—balances density and decode speed |
| R0 hardwired to zero | Simplifies compiler (common zero value) and common code patterns |
| R31 hardware return address | Eliminates extra `jalr` instruction—`call`/`ret` more efficient |
| No scalar floating-point instructions | Unified vector instructions handle FP (V-type supports FP) |
| Weak memory model | Suitable for multi-core; `fence` reserved for future ordering |


2. **Disassembly table** — byte-stream to mnemonic mapping;
3. **GNU Binutils `.md` file** (opcodes description for `gas` port);
4. **QEMU target description framework** (for full-system emulation).
