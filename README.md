# MacroCore-X

A permanent, evolving CISC instruction set architecture for the Cascade-series microarchitectures.

---

## Overview

**MacroCore-X** is a modern CISC ISA designed with a "macro-micro decoupling" philosophy:

- **Frontend**: Complex CISC instructions (variable-length encoding, composite operations, rich addressing modes)
- **Backend**: Simple RISC-style µops (µFlex) for efficient pipelined execution
- **Target**: High code density with streamlined execution, designed for the Cascade microarchitecture family

This repository contains the ISA specification and related documentation.

---

## Repository Contents

| File | Description |
|------|-------------|
| `isa-v1.0.md` | MacroCore-X ISA v1.0 specification (English, official) |
| `isa-v1.0ch.md` | MacroCore-X ISA v1.0 specification (Chinese reference translation) |
| `assembler.py` | Python assembler for MacroCore-X assembly to binary |
| `simulator.py` | Python behavioral simulator / emulator |
| `examples/` | Example assembly programs (ALU, FP, Fibonacci, MMU) |
| `LICENSE` | Creative Commons Attribution 4.0 International License |

---

## Versioning Strategy

| Component | Lifecycle | Update Method |
|-----------|-----------|---------------|
| **MacroCore-X (ISA)** | Permanent, stable | Version increments (v1.0 → v1.1 → v2.0) |
| **Cascade (microarchitecture)** | Iterative per generation | Cascade, Cascade 2, Cascade 3, ... |

---

## License

This specification is licensed under the **Creative Commons Attribution 4.0 International License (CC BY 4.0)**.

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material for any purpose, even commercially

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made.

See the full license text in the [`LICENSE`](LICENSE) file or at:  
[https://creativecommons.org/licenses/by/4.0/](https://creativecommons.org/licenses/by/4.0/)

---

## Status

**MacroCore-X v1.0** — Modular ISA with mandatory core and optional extensions.

## Architecture

**MacroCore-X Core (Mandatory)** — all implementations must include:
- R-type: Scalar integer arithmetic (add, sub, mul, and, or, xor, etc.)
- I-type: Immediate operations (movi, addi, subi, etc.)
- L-type: Load/store (ld, st, ldw, stw, ldb, stb, etc.)
- B-type: Branch and jump (beq, bne, jmp, call, ret, etc.)
- C-type: Composite operations (addm, subm, xchg, push, pop, etc.)
- System-type: System control and debug (syscall, int, cpuid, hlt, etc.)

**Optional Extensions:**
- F-type (Scalar FP): fadd, fsub, fmul, fdiv, fcmp, fsqrt, fcvt, fmin, fmax, fneg, fabs
- V-type (Vector): vadd, vsub, vmul, vld, vst, vshuffle, vfmadd, etc.
- Matrix (Reserved): mmul, macc, etc.

## ✅ Assembler
- Full assembler in Python (`assembler.py`): converts MacroCore-X assembly to binary machine code
- Supports all core ISA types: R-type, I-type, L-type, B-type, C-type, System
- F-type extension: fadd, fsub, fmul, fdiv, fcmp, fsqrt, fcvt, fmin, fmax, fneg, fabs (f32/f64, IEEE 754)
- V-type extension: vadd, vsub, vmul, vld, vst, vshuffle, vfmadd
- Supports labels and branch target resolution
- Generates hex dump of output binary

## ✅ Simulator / Emulator
- Behavioral simulator in Python (`simulator.py`): executes MacroCore-X binary programs
- Full register file (R0-R31) with R0 hardwired to zero
- Independent FPU register file (F0-F31, 64-bit)
- Vector register file (V0-V31, 256-bit)
- Memory model with configurable size
- MMU with 4-level page table, 16-entry TLB, user/kernel mode
- Flag register (CF, ZF, SF, OF)
- CSR support (CR3, MODE, IVEC)
- System call support (exit, write, print integer)
- Disassembly trace mode (`-d` flag)
- Max step limit (`-s N` flag)
- Standalone disassembler mode (`--dis` flag)

## 📁 Examples
- `examples/test_alu.asm`: Tests arithmetic, logical, shift, and comparison operations
- `examples/fibonacci.asm`: Computes first 10 Fibonacci numbers and stores them in memory
- `examples/test_fp.asm`: Tests scalar FP operations (fadd, fsub, fmul, fdiv, fcmp)
- `examples/test_mmu.py`: Tests MMU with identity mapping and user-mode execution

## 🚀 Quick Start
```bash
# Assemble
python3 assembler.py examples/fibonacci.asm -o fibonacci.bin

# Run with trace
python3 simulator.py fibonacci.bin -d

# Run with step limit
python3 simulator.py fibonacci.bin -s 100

# Disassemble only
python3 simulator.py fibonacci.bin --dis
```

---

## Contact

For questions or contributions, please open an issue or pull request on this repository.

---

---

# MacroCore-X

一个为 Cascade 系列微架构设计的、永久演进中的 CISC 指令集架构。

---

## 概述

**MacroCore-X** 是一个现代 CISC 指令集，遵循“宏微分离”的设计理念：

- **前端**：复杂的 CISC 指令（变长编码、复合操作、丰富寻址模式）
- **后端**：精简的 RISC 风格微操作（µFlex），实现高效流水线执行
- **目标**：高代码密度与精简执行相结合，专为 Cascade 微架构家族设计

本仓库包含 ISA 规范及相关文档。

---

## 仓库内容

| 文件 | 描述 |
|------|------|
| `isa-v1.0.md` | MacroCore-X ISA v1.0 规范（英文，官方版） |
| `isa-v1.0ch.md` | MacroCore-X ISA v1.0 规范（中文参考翻译） |
| `assembler.py` | Python 汇编器，将 MacroCore-X 汇编转为二进制 |
| `simulator.py` | Python 行为级模拟器 / 仿真器 |
| `examples/` | 示例汇编程序（ALU、FP、Fibonacci、MMU） |
| `LICENSE` | 知识共享署名 4.0 国际许可证 |

---

## 版本策略

| 组件 | 生命周期 | 更新方式 |
|------|----------|----------|
| **MacroCore-X（ISA）** | 永久稳定 | 版本号递增（v1.0 → v1.1 → v2.0） |
| **Cascade（微架构）** | 每代迭代 | Cascade、Cascade 2、Cascade 3…… |

---

## 许可证

本规范采用 **知识共享署名 4.0 国际许可证（CC BY 4.0）** 授权。

您有权：
- **分享** — 以任何媒介或格式复制和分发本材料
- **改编** — 对本材料进行混编、转换和二次创作，甚至用于商业目的

但需遵守以下条款：
- **署名** — 您必须给出适当的署名，提供许可证链接，并说明是否做了修改。

完整许可证文本请参阅 [`LICENSE`](LICENSE) 文件或访问：  
[https://creativecommons.org/licenses/by/4.0/](https://creativecommons.org/licenses/by/4.0/)

---

## 状态

**MacroCore-X v1.0** — 模块化 ISA，包含强制核心层与可选扩展。

- ✅ 核心整数 ISA（R/I/L/B/C/System 类型）
- ✅ 标量浮点扩展（F-type，独立 FPU，f32/f64 IEEE 754）
- ✅ 向量扩展（V-type，预留）
- ✅ 行为级模拟器（Python）
- ✅ 汇编器与工具链（Python）

---

## 联系方式

如有疑问或贡献意愿，请在本仓库提交 Issue 或 Pull Request。
