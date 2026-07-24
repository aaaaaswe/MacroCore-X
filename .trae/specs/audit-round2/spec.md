# 第二轮代码审查 Spec

## Why
第一轮审查修复了 8 个问题后，第二轮更深入的审查发现了 3 个严重 bug、3 个 ISA 规范错误、以及若干中低优先级问题。

## What Changes

### 严重 Bug
- **`div` 指令有符号除法 bug**：两个问题：(1) 操作数未做符号扩展，导致负数被当作巨大的正数；(2) Python `//` 是 floor division，ISA 规范要求 truncate-toward-zero
- **ISA 规范 R-type 编码过时**：规范说"Rd = Rs1（累加器风格）"，但实际实现使用显式三操作数
- **ISA 规范 L-type/B-type 编码错误**：规范中 byte0/byte1 的位布局与实际实现不一致

### 中等问题
- **`fp_compare` 代码重复**：f32/f64 分支完全重复，与 `fp_execute_f` 已修复的问题相同
- **_`emit_f` 汇编器 aux 始终为 0**：丢失 f64 精度支持，无法在汇编时指定精度
- **`andi`/`ori`/`xori` 用 `& 0xFFFF` 掩码**：规范说 14 位零扩展，代码用了 16 位掩码

### 低优先级
- **`divu` 表达式 `% 0x10000000000000000`**：2^64 不是 2^64-1，表达式令人困惑
- **`lda` scale 无校验**：非法 scale 值会抛出 KeyError 而非友好错误
- **`parse_mem_operand` 符号处理**：`[r2 + -8]` 这类负偏移解析可能出错

## Impact
- Affected specs: `isa-v1.0.md`（需修正编码描述）
- Affected code: `simulator.py`（div 修复、fp_compare 重构、andi/ori/xori 掩码、divu 清理）、`assembler.py`（lda scale 校验、parse_mem_operand 修复）

## ADDED Requirements

### Requirement: Signed Division Must Use Truncate-Toward-Zero
The `div` instruction SHALL sign-extend both operands and use truncate-toward-zero division.

#### Scenario: Negative division
- **WHEN** R[rs1] = -5 (stored as 0xFFFFFFFFFFFFFFFB), R[rs2] = 2
- **THEN** R[rd] = -2 (truncate-toward-zero), NOT -3 (floor) and NOT a huge positive number

#### Scenario: Positive division
- **WHEN** R[rs1] = 10, R[rs2] = 3
- **THEN** R[rd] = 3 (same as floor for positive numbers)

## MODIFIED Requirements

### Requirement: ISA Spec R-type Encoding
The ISA spec SHALL document the actual 3-operand encoding used by the implementation:
- byte0 = full opcode (0x00-0x1F)
- byte1 = (Rd<<3) | (Rs1>>2)
- byte2 = ((Rs1&3)<<6) | (Rs2<<1) | X
- Remove the "Rd = Rs1 (accumulator convention)" note

### Requirement: ISA Spec L-type Encoding
The ISA spec SHALL match the actual implementation:
- byte0 = full opcode (0x40-0x46)
- byte1 = (Rd<<4) | Rs1
- NOT: byte0 = [OP 4 bits][Rd 4 bits]

### Requirement: ISA Spec B-type Encoding
The ISA spec SHALL match the actual implementation:
- For conditional branches: byte0 = opcode, byte1 = (Rs1<<4) | Rs2
- NOT: byte0 = [OP 4 bits][Rs1 4 bits]

### Requirement: andi/ori/xori Use 14-bit Zero-Extend
The `andi`/`ori`/`xori` instructions SHALL use `imm & 0x3FFF` (14-bit) instead of `imm & 0xFFFF` (16-bit).

### Requirement: fp_compare Must Not Duplicate f32/f64
The `fp_compare` function SHALL use the same pattern as `fp_execute_f` (select conversion functions first, then apply logic once).