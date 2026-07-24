# MacroCore-X v0.0.1 Instruction Set Architecture Specification

**Version**: 0.0.1  
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
| Floating-point registers (FR) | 32 | 64-bit | F0–F31 |
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

### 1.3 Floating-Point Registers

F0–F31, 64 bits wide, independent scalar floating-point register file. F-type instructions (fadd, fsub, fmul, etc.) perform IEEE 754 scalar floating-point operations on F registers. F registers are completely independent from V registers (vector registers) — there is no overlap or interference between the two.

### 1.4 Vector Registers

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
| `00` | 4 bytes | R-type (opcodes 0x00–0x1F) |
| `01` | 4/6 bytes | I/L/B-type (opcodes 0x20–0x7F) |
| `10` | 6/8 bytes | V/C/F extended types (opcodes 0x80–0xBF) |
| `11` | 8 bytes | Long instructions (opcodes 0xC0–0xFF) |

**Decoders must determine the length in the first cycle solely from bits[7:6] of byte0, without parsing subsequent bytes.**

> Note: In the `01` range, `movi` (0x2A) and select L-type indexed variants (0x50–0x5F) are 6 bytes. The decoder distinguishes these via the full opcode byte after the initial length-class determination. In the `10` range, System-type instructions (0xB0–0xBF) are 2 or 4 bytes.

### 2.2 Instruction Field Definitions

| Field | Abbr. | Width (bits) | Description |
|-------|-------|--------------|-------------|
| Opcode | OP | 2–8 | Instruction functionality |
| Destination register | Rd | 5 | GR number (0–31) |
| Source register 1 | Rs1 | 5 | GR number |
| Source register 2 | Rs2 | 5 | GR number |
| Immediate | IMM | 5–32 | Sign- or zero-extended |
| Offset | OFF | 12–21 | Relative jump / memory offset |
| Extension flags | X | 1–4 | Width / atomic / condition modifiers |

### 2.3 Opcode Map (Complete)

| Opcode Range | Category | Length | Primary Use |
|--------------|----------|--------|-------------|
| 0x00–0x1F | **R-type** | 4 bytes | Register–register operations |
| 0x20–0x3F | **I-type** | 4/6 bytes | Immediate operations / loads |
| 0x40–0x5F | **L-type** | 4/6 bytes | Load / store |
| 0x60–0x7F | **B-type** | 4 bytes | Branches / jumps |
| 0x80–0x8F | **V-type** | 6/8 bytes | Vector operations |
| 0x90–0x9F | **C-type** | 6/8 bytes | Composite memory operations |
| 0xA0–0xAF | **F-type** | 6 bytes | Scalar FP operations |
| 0xB0–0xBF | **System-type** | 2/4 bytes | Privileged / management |
| 0xC0–0xFF | **Reserved** | variable | Future extensions |

---

## Chapter 3: Instruction Definitions

### 3.1 R-type Instructions (4 bytes, OP 0x00–0x1F)

**Format (4-byte)**:
```
Bits:   7..0         7..0         7..0         7..0
        ┌───────────┬───────────┬───────────┬───────────┐
byte0   │ OP[7:0]               │   Full opcode 0x00–0x1F
        ├───────────┼───────────┼───────────┼───────────┤
byte1   │ Rd[4:0]       │ Rs1[4:2]      │   Rd (5 bits) + Rs1 high 3 bits
        ├───────────┼───────────┼───────────┼───────────┤
byte2   │ Rs1[1:0]  │ Rs2[4:0]      │X│   Rs1 low 2 bits + Rs2 (5 bits) + X
        ├───────────┼───────────┼───────────┼───────────┤
byte3   │ Reserved (0x00)                       │
        └───────────┴───────────┴───────────┴───────────┘
```

- **Rd**: destination register (5 bits, 0–31)
- **Rs1**: source register 1 (5 bits, 0–31)
- **Rs2**: source register 2 (5 bits, 0–31)
- **X**: extension flag (reserved for future use; must be 0)

R-type uses an explicit 3-operand format: Rd, Rs1, and Rs2 are all independently specified.
Encoding: byte0 = full opcode, byte1 = (Rd<<3) | (Rs1>>2), byte2 = ((Rs1&3)<<6) | (Rs2<<1) | X.

#### R-type Instruction List

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x00 | `add` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] + R[Rs2] |
| 0x01 | `sub` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] - R[Rs2] |
| 0x02 | `mul` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] × R[Rs2] (low 64 bits) |
| 0x03 | `div` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] ÷ R[Rs2] (signed, truncate toward zero) |
| 0x04 | `divu` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] ÷ R[Rs2] (unsigned) |
| 0x05 | `and` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] & R[Rs2] |
| 0x06 | `or` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] \| R[Rs2] |
| 0x07 | `xor` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] ^ R[Rs2] |
| 0x08 | `shl` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] << (R[Rs2] & 0x3F) |
| 0x09 | `shr` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] >> (R[Rs2] & 0x3F) (logical) |
| 0x0A | `sar` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] >> (R[Rs2] & 0x3F) (arithmetic) |
| 0x0B | `eq` | Rd, Rs1, Rs2 | R[Rd] ← (R[Rs1] == R[Rs2]) ? 1 : 0 |
| 0x0C | `lt` | Rd, Rs1, Rs2 | R[Rd] ← (R[Rs1] < R[Rs2]) ? 1 : 0 (signed) |
| 0x0D | `ltu` | Rd, Rs1, Rs2 | R[Rd] ← (R[Rs1] < R[Rs2]) ? 1 : 0 (unsigned) |
| 0x0E | `max` | Rd, Rs1, Rs2 | R[Rd] ← max(R[Rs1], R[Rs2]) (signed) |
| 0x0F | `min` | Rd, Rs1, Rs2 | R[Rd] ← min(R[Rs1], R[Rs2]) (signed) |
| 0x10 | `ror` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] rotate right (R[Rs2] & 0x3F) |
| 0x11 | `rol` | Rd, Rs1, Rs2 | R[Rd] ← R[Rs1] rotate left (R[Rs2] & 0x3F) |
| 0x12 | `clz` | Rd, Rs1 | R[Rd] ← count leading zeros of R[Rs1] |

> All R-type instructions update FLAGS: CF/ZF/SF/OF (for arithmetic/logic); `eq`/`lt`/`ltu` update only ZF; `clz` does not update flags.

---

### 3.2 I-type Instructions (4/6 bytes, OP 0x20–0x3F)

**Format (4-byte)**:
```
byte0: [OP 8 bits]
byte1: [Rd[4:0] 5 bits][Rs1[4:2] 3 bits]
byte2: [Rs1[1:0] 2 bits][IMM[13:8] 6 bits]
byte3: [IMM[7:0] 8 bits]
```
IMM is a 14-bit immediate (byte2[5:0]||byte3[7:0]), sign-extended to 64 bits for most instructions.

**Format (6-byte, `movi` only)**:
```
byte0: [OP 8 bits = 0x2A]
byte1: [Rd[4:0] 5 bits][000 3 bits]
byte2-5: IMM32 (little-endian, zero-extended)
```

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x20 | `addi` | Rd, Rs1, imm14 | R[Rd] ← R[Rs1] + sext(imm14) |
| 0x21 | `subi` | Rd, Rs1, imm14 | R[Rd] ← R[Rs1] - sext(imm14) |
| 0x22 | `muli` | Rd, Rs1, imm14 | R[Rd] ← R[Rs1] × sext(imm14) |
| 0x23 | `andi` | Rd, Rs1, imm14 | R[Rd] ← R[Rs1] & zext(imm14) |
| 0x24 | `ori` | Rd, Rs1, imm14 | R[Rd] ← R[Rs1] \| zext(imm14) |
| 0x25 | `xori` | Rd, Rs1, imm14 | R[Rd] ← R[Rs1] ^ zext(imm14) |
| 0x26 | `shli` | Rd, Rs1, imm6 | R[Rd] ← R[Rs1] << imm6 (IMM[5:0]) |
| 0x27 | `shri` | Rd, Rs1, imm6 | R[Rd] ← R[Rs1] >> imm6 (logical) |
| 0x28 | `sari` | Rd, Rs1, imm6 | R[Rd] ← R[Rs1] >> imm6 (arithmetic) |
| 0x29 | `mov` | Rd, imm14 | R[Rd] ← sext(imm14) |
| 0x2A | `movi` | Rd, imm32 | R[Rd] ← zext(imm32) (6-byte extension) |
| 0x2B-0x3F | *Reserved* | — | — |

> Flag update rules same as R-type.

---

### 3.3 L-type Instructions (Load/Store, 4/6 bytes, OP 0x40–0x5F)

**Format (4-byte)**:
```
byte0: [OP 8 bits]          (full opcode 0x40–0x46)
byte1: [Rd 4 bits][Rs1 4 bits]
byte2-3: OFF16 (little-endian, signed offset)
```

> Note: L-type, B-type conditional branches, and C-type instructions use 4-bit register fields (Rd, Rs1, Rs2), limiting them to registers R0–R15. R-type and I-type instructions use 5-bit register fields, supporting all 32 registers (R0–R31).

**Format (6-byte indexed addressing, OP 0x50–0x5F)**:
```
byte0-1: same as above
byte2-3: OFF16
byte4-5: Rn (index register number) + scale (2 bits)
```

Load/store width is determined by the opcode: `ld`/`st` = 64-bit, `ldu`/`lds` = 32-bit (sign/zero-extended), `stw` = 32-bit, `stb` = 8-bit.

| OP | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x40 | `ld` | Rd, [Rs1 + off] | R[Rd] ← zext(Mem[Rs1+off, 64]) |
| 0x41 | `ldu` | Rd, [Rs1 + off] | R[Rd] ← zext(Mem[Rs1+off, 32]) |
| 0x42 | `lds` | Rd, [Rs1 + off] | R[Rd] ← sext(Mem[Rs1+off, 32]) |
| 0x43 | `st` | Rs1, [Rs2 + off] | Mem[Rs2+off, 64] ← R[Rs1] |
| 0x44 | `stw` | Rs1, [Rs2 + off] | Mem[Rs2+off, 32] ← R[Rs1] (low 32 bits) |
| 0x45 | `stb` | Rs1, [Rs2 + off] | Mem[Rs2+off, 8] ← R[Rs1] (low 8 bits) |
| 0x46 | `lda` | Rd, Rs1, Rs2, scale | R[Rd] ← R[Rs1] + R[Rs2] × scale (scale=1/2/4/8) |

> Note: `lda` reuses the OFF16 field (byte2-3) to encode Rs2 and scale: byte2-3 = (Rs2 << 2) | scale_bits, where scale_bits = 0/1/2/3 for scale 1/2/4/8. Scaling is performed by the microarchitecture, not by the LEA logic.
| 0x50 | `ldr` | Rd, [Rs1 + Rn*scale + off] | R[Rd] ← Mem[Rs1 + Rn×scale + off, 64] (6 bytes) |
| 0x51 | `str` | Rs1, [Rs2 + Rn*scale + off] | Mem[Rs2 + Rn×scale + off, 64] ← R[Rs1] (6 bytes) |
| 0x52-0x5F | *Reserved* | — | — |

> L-type instructions do **not** update FLAGS.

---

### 3.4 B-type Instructions (Branch/Jump, 4 bytes, OP 0x60–0x7F)

**Format (conditional branches, OP 0x63–0x6A)**:
```
byte0:   [OP 8 bits]          (full opcode 0x63–0x6A)
byte1:   [Rs1 4 bits][Rs2 4 bits]
byte2-3: IMM12 (little-endian, signed offset)
```

**Format (`j`/`call`, OP 0x60/0x61)**:
```
byte0:   [OP 8 bits]          (full opcode 0x60/0x61)
byte1:   imm20[19:12]
byte2-3: imm20[11:0] (little-endian, signed offset)
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
| 0x6D-0x6F | *Reserved* | — | — |

> `call` and `callreg` store `PC + 4` in R31 because all B-type instructions are 4 bytes. `ret` does **not** validate R[31]—software must ensure it is valid.

---

### 3.5 F-type Instructions (Scalar FP Extension, Optional, 6 bytes, OP 0xA0–0xAF)

**Format (6-byte)**:
```
byte0:   [0xA 4 bits][Fd 4 bits]
byte1:   [Fs1 4 bits][Fs2 4 bits]
byte2:   FUNCT8 (operation code)
byte3:   AUX  [rm 3 bits][prec 2 bits][rsv 3 bits]
byte4-5: Reserved
```

- **Fd**: destination F register (scalar float result, 0–31)
- **Fs1, Fs2**: source F registers (scalar float operands, 0–31)
- **FUNCT8**: operation code
- **AUX**: precision and rounding mode
  - `prec` (bits [2:1]): 0 = f32, 1 = f64
  - `rm` (bits [6:3]): rounding mode (0 = RNE, 1 = RTZ, 2 = RDN, 3 = RUP)

#### F-type Register Model: Independent Floating-Point Register File

F-type scalar floating-point instructions use a **dedicated F register file** (F0–F31, 64-bit each):

- The F register file contains 32 × 64-bit registers, dedicated exclusively to scalar floating-point operations.
- F-type instructions operate only on F registers, and are **completely independent** from V registers (vector registers, 256-bit).
- Floating-point data is transferred between F registers and memory via `fld`/`fst` instructions, or between integer and floating-point via `fcvt` instructions.
- This design avoids register file reuse and enables true parallel execution of scalar FP and vector operations.

> Independent FPU design: F registers and V registers are fully decoupled. F-type instructions do not depend on V registers, and V-type instructions do not depend on F registers. Compilers can freely allocate both register files, and hardware can implement independent floating-point and vector execution units.

| FUNCT | Mnemonic | Operands | Semantics |
|----|----------|----------|-----------|
| 0x00 | `fadd` | Fd, Fs1, Fs2 | F[Fd] ← float(F[Fs1]) + float(F[Fs2]) |
| 0x01 | `fsub` | Fd, Fs1, Fs2 | F[Fd] ← float(F[Fs1]) - float(F[Fs2]) |
| 0x02 | `fmul` | Fd, Fs1, Fs2 | F[Fd] ← float(F[Fs1]) × float(F[Fs2]) |
| 0x03 | `fdiv` | Fd, Fs1, Fs2 | F[Fd] ← float(F[Fs1]) ÷ float(F[Fs2]) |
| 0x04 | `fsqrt` | Fd, Fs1 | F[Fd] ← sqrt(float(F[Fs1])) |
| 0x05 | `fcmp` | Fs1, Fs2 | ZF ← (F[Fs1]==F[Fs2]); CF ← (F[Fs1]<F[Fs2]) |
| 0x06 | `fcvt.w.s` | Fd, Fs1 | F[Fd] ← int(float(F[Fs1])) (truncate) |
| 0x07 | `fcvt.s.w` | Fd, Fs1 | F[Fd] ← float(int(F[Fs1])) |
| 0x08 | `fmin` | Fd, Fs1, Fs2 | F[Fd] ← min(float(F[Fs1]), float(F[Fs2])) |
| 0x09 | `fmax` | Fd, Fs1, Fs2 | F[Fd] ← max(float(F[Fs1]), float(F[Fs2])) |
| 0x0A | `fneg` | Fd, Fs1 | F[Fd] ← -float(F[Fs1]) |
| 0x0B | `fabs` | Fd, Fs1 | F[Fd] ← abs(float(F[Fs1])) |
| 0x0C | `fld` | Fd, [Rs1 + off] | F[Fd] ← Mem[Rs1+off, 64] |
| 0x0D | `fst` | Fd, [Rs1 + off] | Mem[Rs1+off, 64] ← F[Fd] |
| 0x0E-0xFF | *Reserved* | — | — |

> F[Fd] denotes the Fd-th register in the F register file (64-bit).

#### 3.5.1 Floating-Point Status Register (CSR_FSR, 0x00A)

The FSR captures floating-point exception flags:

| Bit | Name | Description |
|-----|------|-------------|
| 0 | NV | Invalid operation (e.g., 0/0, sqrt(-1), ∞−∞) |
| 1 | DZ | Divide by zero |
| 2 | OF | Overflow (result too large) |
| 3 | UF | Underflow (result too small, subnormal) |
| 4 | NX | Inexact (result rounded) |
| 7:5 | Rsv | Reserved |

- FSR flags are **sticky** — once set, they remain set until cleared by writing 0 to the corresponding bit via `wrmsr`.
- Floating-point exceptions do **not** raise #FP exception by default. Software must poll CSR_FSR or configure trapping via a future CSR_FCR (floating-point control register).
- When an FP operation produces NaN, infinite, or a subnormal, the corresponding FSR flag is set and the operation proceeds with the IEEE 754 default result.

---

### 3.6 V-type Instructions (Vector Extension, Optional, 6/8 bytes, OP 0x80–0x8F)

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
| 0x0C-0xFF | *Reserved* | — | — |

#### 3.6.1 Vector Masking

Vector instructions support per-element masking via the AUX byte (byte3):

- **AUX[3]** (mask enable): 0 = no masking (all elements active), 1 = masking enabled
- **AUX[2]** (mask polarity): 0 = mask=0 means element inactive, 1 = mask=0 means element active
- When masking is enabled, the **mask register** is implicitly **V0**. Each bit of the V0 register's low N bits (where N = 256 / element_width) controls whether the corresponding element of the destination is written.
  - Mask bit = 0: element is **inactive** (destination element preserved, no exception from masked element)
  - Mask bit = 1: element is **active** (normal operation)
- Mask polarity (AUX[2]) can invert this: 0 = active, 1 = inactive.

> Example: For a 32-bit element vector operation (8 elements), V0[7:0] serves as the mask bits. If V0 = 0x0000...0005 (bits 0 and 2 set), only elements 0 and 2 are active.

---

### 3.7 C-type Instructions (Composite CISC, 6/8 bytes, OP 0x90–0x9F)

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

### 3.8 System Instructions (2/4 bytes, OP 0xB0–0xBF)

| OP | Mnemonic | Operands | Semantics | Length |
|----|----------|----------|-----------|--------|
| 0xB0 | `syscall` | imm8 | Raise system call (imm8 → syscall number, enter kernel mode) | 2 |
| 0xB1 | `sysret` | — | Return from system call (restore user mode) | 2 |
| 0xB2 | `int` | imm8 | Software interrupt (imm8 → interrupt vector) | 2 |
| 0xB3 | `iret` | — | Return from interrupt | 2 |
| 0xB4 | `rdmsr` | Rs1, imm12 | R[Rs1] ← MSR[imm12] | 4 |
| 0xB5 | `wrmsr` | Rs1, imm12 | MSR[imm12] ← R[Rs1] | 4 |
| 0xB6 | `cpuid` | — | Fill R0:R1:R2:R3 with vendor/features/cache/version info | 2 |
| 0xB7 | `hlt` | — | Halt execution until interrupt | 2 |
| 0xB8 | `cli` | — | Clear interrupt enable flag (IF=0) | 2 |
| 0xB9 | `sti` | — | Set interrupt enable flag (IF=1) | 2 |
| 0xBA | `nop` | — | No operation (PC ← PC + 2) | 2 |
| 0xBB | `ecall` | imm8 | Environment call (emulator/debug entry point) | 2 |
| 0xBC | `fence` | — | Memory fence / barrier (see §5.3) | 2 |
| 0xBD | `bkpt` | imm8 | Hardware breakpoint (debug) | 2 |
| 0xBE-0xBF | *Reserved* | — | — | variable |

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

### 4.3 Control and Status Registers (CSRs)

CSRs are accessed via `rdmsr` (0xB4) and `wrmsr` (0xB5) instructions. The CSR address space is 12 bits (0x000–0xFFF).

| CSR# | Name | Width | Description |
|------|------|-------|-------------|
| 0x000 | `CSR_ERR` | 64 | Exception return PC (saved on exception, restored by `iret`) |
| 0x001 | `CSR_EF` | 8 | Exception flags (saved FLAGS on exception) |
| 0x002 | `CSR_MODE` | 64 | Mode register: PRIV[0], ALIGN[1], VLEN[3:2], reserved[63:4] |
| 0x003 | `CSR_CR3` | 64 | Page table base address (physical address of root page table) |
| 0x004 | `CSR_IVEC` | 64 | Exception vector table base address (default: 0x0000) |
| 0x005 | `CSR_IE` | 32 | Interrupt enable mask (bit-per-interrupt, see §4.4) |
| 0x006 | `CSR_IP` | 32 | Interrupt pending register (read-only) |
| 0x007 | `CSR_IPI` | 64 | Inter-processor interrupt: write to send IPI to target core |
| 0x008 | `CSR_TIMER` | 64 | Timer counter (counts up at a fixed frequency) |
| 0x009 | `CSR_TIMECMP` | 64 | Timer compare: interrupt when CSR_TIMER >= CSR_TIMECMP |
| 0x00A | `CSR_FSR` | 8 | Floating-point status register (see §3.5.1) |
| 0x00B | `CSR_DBGCTL` | 64 | Debug control register (see §4.5) |
| 0x00C–0x01F | `CSR_PMC0`–`CSR_PMC19` | 64 | Performance monitor counters 0–19 (see §4.6) |
| 0x020–0x03F | *Reserved* | — | Future standard CSRs |
| 0x040–0xFFF | *Vendor-defined* | — | Implementation-specific CSRs |

#### CSR Field Details

**CSR_MODE (0x002)**:
- bit [0]: PRIV — 0 = kernel, 1 = user
- bit [1]: ALIGN — 0 = allow unaligned access, 1 = trap on unaligned
- bit [3:2]: VLEN — vector length: 00 = 128-bit, 01 = 256-bit, 10 = 512-bit, 11 = reserved
- bit [63:4]: Reserved (must be 0)

**CSR_CR3 (0x003)**:
- bit [63:12]: Physical page number (PPN) of the root page table
- bit [11:0]: Reserved (must be 0, ensures 4KB alignment)

### 4.4 Interrupt Controller

#### 4.4.1 Interrupt Numbers

| IRQ# | Type | Description |
|------|------|-------------|
| 0 | Timer | Timer interrupt (CSR_TIMER >= CSR_TIMECMP) |
| 1 | IPI | Inter-processor interrupt (from another core) |
| 2–15 | External | External hardware IRQ lines (platform-defined) |
| 16–31 | Software | Software-generated interrupts (`int` instruction) |

#### 4.4.2 Interrupt Control

- **CSR_IE** (0x005): Each bit controls whether the corresponding interrupt is enabled (1 = enabled). Bit 0 = Timer, bit 1 = IPI, bits 2–15 = external IRQs.
- **CSR_IP** (0x006): Read-only register indicating pending interrupts. Bit layout matches CSR_IE.
- **CSR_IPI** (0x007): Writing (core_id << 16) | (vector & 0xF) sends an IPI to the specified core. The receiving core sees CSR_IP bit 1 set.

#### 4.4.3 Interrupt Priority

Decreasing priority order:
1. Machine check (non-maskable)
2. External interrupts (IRQ 2–15) — highest IRQ# = highest priority
3. Timer (IRQ 0)
4. IPI (IRQ 1)
5. Software interrupts (IRQ 16–31)

### 4.5 Debug Interface

#### 4.5.1 Debug Mode Entry

- **Hardware Breakpoint**: `bkpt imm8` instruction (0xBD) triggers entry to debug mode if CSR_DBGCTL[0] (DBE) = 1.
- **Single-step**: When CSR_DBGCTL[1] (SSE) = 1, the CPU enters debug mode after executing each instruction.
- Debug mode saves PC to CSR_ERR and FLAGS to CSR_EF, then jumps to the debug handler at CSR_DBGCTL[63:12] << 12.

#### 4.5.2 Debug Control Register (CSR_DBGCTL, 0x00B)

| Bit | Name | Description |
|-----|------|-------------|
| 0 | DBE | Debug enable (1 = respond to `bkpt`) |
| 1 | SSE | Single-step enable |
| 63:12 | DBGHADDR | Debug handler base address (page-aligned) |

### 4.6 Performance Counters (PMC)

20 performance monitor counters (CSR_PMC0–CSR_PMC19, CSRs 0x00C–0x01F) for hardware performance monitoring:

| CSR# | Counter | Default Event |
|------|---------|---------------|
| 0x00C | PMC0 | Instructions retired |
| 0x00D | PMC1 | CPU cycles |
| 0x00E | PMC2 | Branch instructions |
| 0x00F | PMC3 | Branch mispredictions |
| 0x010 | PMC4 | L1 data cache accesses |
| 0x011 | PMC5 | L1 data cache misses |
| 0x012 | PMC6 | L1 instruction cache accesses |
| 0x013 | PMC7 | L1 instruction cache misses |
| 0x014 | PMC8 | TLB misses |
| 0x015 | PMC9 | Page faults |
| 0x016 | PMC10 | FP operations |
| 0x017 | PMC11 | Vector operations |
| 0x018 | PMC12 | Store buffer full stalls |
| 0x019 | PMC13 | Load-use interlock stalls |
| 0x01A–0x01F | PMC14–PMC19 | Implementation-defined |

> All PMCs are 64-bit wraparound counters. They are readable via `rdmsr` and can be reset by writing 0 via `wrmsr`.

---

## Chapter 5: Memory Model

### 5.1 Address Space

- 64-bit flat address space, virtual address width **48 bits** (current implementation), physical address width **52 bits** (configurable).
- Supports 4KB, 2MB, and 1GB pages.

### 5.2 Page Table Format

MacroCore-X uses a 4-level hierarchical page table (similar to x86_64 and RISC-V Sv39/Sv48).

#### 5.2.1 Page Table Entry (PTE) Format

Each PTE is 8 bytes (64 bits):

```
Bits:  63:52         51:12          11:9  8   7   6   5   4   3   2   1   0
       ┌─────────────┬───────────────┬─────┬───┬───┬───┬───┬───┬───┬───┬───┐
       │ Reserved    │ PPN[51:12]    │ Rsv │ G │ U │ A │ D │ W │ X │ R │ V │
       └─────────────┴───────────────┴─────┴───┴───┴───┴───┴───┴───┴───┴───┘
```

| Bit | Name | Description |
|-----|------|-------------|
| 0 | V | Valid — 1 = PTE is valid |
| 1 | R | Readable — 1 = read access allowed |
| 2 | X | Executable — 1 = execute access allowed |
| 3 | W | Writable — 1 = write access allowed |
| 4 | D | Dirty — set by hardware on first write to the page |
| 5 | A | Accessed — set by hardware on first access to the page |
| 6 | U | User — 1 = accessible in user mode (PRIV=1) |
| 7 | G | Global — 1 = global mapping (not flushed on TLB context switch) |
| 11:8 | Rsv | Reserved for future use |
| 51:12 | PPN | Physical page number (40 bits for 4KB pages) |
| 63:52 | Rsv | Reserved (must be 0) |

#### 5.2.2 Page Sizes

| Page Size | PPN Bits Used | PTE Level | Identifier |
|-----------|---------------|-----------|------------|
| 4KB | PPN[51:12] | Level 0 (leaf) | Standard page |
| 2MB | PPN[51:21] | Level 1 (leaf) | Large page (PTE[51:21]) |
| 1GB | PPN[51:30] | Level 2 (leaf) | Huge page (PTE[51:30]) |

Large/huge pages are identified by setting the leaf PTE at the corresponding level (not as a pointer to the next level).

#### 5.2.3 Virtual Address Breakdown (4KB pages)

```
Bits:  63:48         47:39       38:30       29:21       20:12       11:0
       ┌─────────────┬───────────┬───────────┬───────────┬───────────┬──────┐
       │ Sign-ext    │ VPN[3]    │ VPN[2]    │ VPN[1]    │ VPN[0]    │ Off  │
       └─────────────┴───────────┴───────────┴───────────┴───────────┴──────┘
          (16 bits)    (9 bits)    (9 bits)    (9 bits)    (9 bits)    (12 bits)
```

- VPN[3] indexes the Level 3 (root) page table
- VPN[2] indexes the Level 2 page table
- VPN[1] indexes the Level 1 page table
- VPN[0] indexes the Level 0 (leaf) page table
- CSR_CR3 points to the physical base of the Level 3 page table

### 5.3 Alignment Policy

The CSR_MODE.ALIGN bit controls behavior:
- `0`: Unaligned accesses are permitted (handled by microarchitecture)
- `1`: Unaligned accesses raise #alignment fault

### 5.4 Memory Ordering

**Weak Memory Model** — no ordering guarantees between different memory accesses unless explicitly enforced.

#### 5.4.1 fence Instruction

**Format (2-byte)**:
```
byte0: 0xBC
byte1: [PI 4 bits][PO 4 bits]
```

- **PI** (Predecessor Input): memory operations that must complete before the fence
- **PO** (Predecessor Output): memory operations that must complete before the fence
- `PI`/`PO` encoding: bit 0 = Load, bit 1 = Store, bits 2–3 = reserved

| Encoding | Mnemonic | Semantics |
|----------|----------|-----------|
| `fence` (PI=0xF, PO=0xF) | Full barrier | All previous loads and stores complete before any subsequent loads/stores |
| `fence w, w` (PI=0x2, PO=0x2) | Store-store barrier | All previous stores complete before subsequent stores |
| `fence r, r` (PI=0x1, PO=0x1) | Load-load barrier | All previous loads complete before subsequent loads |
| `fence rw, rw` (PI=0x3, PO=0x3) | Load+store barrier | All previous loads/stores complete before subsequent loads/stores |

#### 5.4.2 Atomic Instructions and Memory Ordering

- **`xchg`** (0x92): Implicit **full memory barrier** (acquire + release). Equivalent to a `fence rw, rw` embedded in the instruction.
- **`cmpxchg`** (0x93): Implicit **full memory barrier**. Both the load-compare and conditional-store phases are atomic with respect to other memory operations.
- **`addm`** / **`subm`** (0x90–0x91): These are **NOT atomic** at the ISA level (decomposed into ld→alu→st µops). Use `cmpxchg` in a loop for atomic read-modify-write.

> Rationale: `xchg` and `cmpxchg` provide implicit full barriers (similar to x86 `lock` prefix) to simplify lock-free programming. Software that requires weaker ordering should use regular loads/stores with explicit `fence` instructions.

---

## Chapter 6: Assembly Syntax

### 6.1 Syntax Style (Simplified AT&T)

```
<instruction> <dest>, <src1>, <src2>
```

**Examples**:
```
add r1, r1, r2       # R-type: r1 = r1 + r2
addi r3, r1, 0x100    # I-type: r3 = r1 + 256
ld r4, [r2 + 0x8]     # Load 64-bit
st r5, [r3 - 0x4]     # Store 64-bit
call 0x10000          # Function call
fadd f2, f0, f1       # F-type scalar FP addition
vadd v1, v2, v3       # V-type vector addition
push r6               # Push to stack
syscall 0x1           # System call
fence                 # Full memory barrier
bkpt 0                # Breakpoint with debug code 0
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
- **Return value**: R1 (success = 0 or positive; failure = negative errno, e.g., -ENOMEM)
- **Error indication**: Return value in range [-4095, -1] indicates an error. The absolute value is the errno.
- **Caller-saved registers**: R1–R15 (may be clobbered by the kernel)
- **Callee-saved registers**: R16–R23, R30–R31 (preserved across syscall)
- **R0**: Always 0 (hardwired)
- **SP (R2)**: Should be valid; kernel may access user stack for certain syscalls (e.g., `execve`)
- System call instruction: `syscall 0x0` (uses syscall number from R1)
- No vsyscall/vDSO in the current version; fast syscalls may be implemented via the kernel's syscall page in future versions.

#### Standard Syscall Numbers

| # | Name | R2 | R3 | R4 | Description |
|---|------|----|----|----|-------------|
| 0 | `exit` | status | — | — | Terminate process |
| 1 | `write` | fd | buf | count | Write to file descriptor |
| 2 | `read` | fd | buf | count | Read from file descriptor |
| 3 | `open` | path | flags | mode | Open file |
| 4 | `close` | fd | — | — | Close file descriptor |
| 5 | `mmap` | addr | len | prot/flags/fd/off | Map memory |
| 6 | `munmap` | addr | len | — | Unmap memory |
| 7 | `brk` | addr | — | — | Change program break |
| 8 | `fork` | — | — | — | Create child process |
| 9 | `execve` | path | argv | envp | Execute program |
| 10 | `waitpid` | pid | status | options | Wait for child |
| 11–63 | *Reserved* | — | — | — | POSIX-compatible |
| 64–255 | *Custom* | — | — | — | Implementation-defined |

---

## Appendix A: Instruction Encoding Table (Byte-level, Partial)

| Mnemonic | byte0 (hex) | Length | Format |
|----------|-------------|--------|--------|
| `add` | 0x00 | 4 | R |
| `sub` | 0x01 | 4 | R |
| `mul` | 0x02 | 4 | R |
| `div` | 0x03 | 4 | R |
| `divu` | 0x04 | 4 | R |
| ... (full table omitted for brevity) | | | |
| `syscall` | 0xB0 | 2 | SYS |
| `cpuid` | 0xB6 | 2 | SYS |
| `nop` | 0xBA | 2 | SYS |
| `fence` | 0xBC | 2 | SYS |
| `bkpt` | 0xBD | 2 | SYS |

> Complete encoding tables require operand packers; this document provides the authoritative reference.

---

## Appendix B: Design Decision Log

| Decision | Rationale |
|----------|-----------|
| 2/4/6/8-byte variable length | Decoder determines length in first cycle via top 2 bits—balances density and decode speed |
| R0 hardwired to zero | Simplifies compiler (common zero value) and common code patterns |
| R31 hardware return address | Eliminates extra `jalr` instruction—`call`/`ret` more efficient |
| R-type 4 bytes (v2.1) | Extended from 2 bytes to support full 32-register file (5-bit fields); resolves v2.0 density vs. register count contradiction |
| F-type at 0xA0–0xAF (v2.1) | Moved from 0x70–0x7F to the `10` range (6-byte zone) to maintain the "top 2 bits = length" hard decoding rule |
| F-type uses independent F register file | Scalar FP and vector operations are fully decoupled, enabling true parallel execution; F and V registers are independent, with no reuse |
| Weak memory model | Suitable for multi-core; `fence` and implicit barriers in `xchg`/`cmpxchg` provide ordering control |
| Implicit full barriers in atomics | `xchg`/`cmpxchg` include full memory barriers (like x86 `lock`) to simplify lock-free programming |
| 4-level page table | Compatible with Linux kernel's page table walker; 48-bit virtual, 52-bit physical addresses |
| CSR-based system control | Unified CSR space for ERR, MODE, CR3, FSR, PMC, etc.; accessed via `rdmsr`/`wrmsr` |

---

## Appendix C: Deliverables (Toolchain)

1. **ISA specification** (this document)
2. **Assembler** (`assembler.py`) — assembly to binary
3. **Simulator** (`simulator.py`) — behavioral emulation
4. **GNU Binutils `.md` file** (opcodes description for `gas` port) — pending
5. **QEMU target description framework** (for full-system emulation) — pending
