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

**MacroCore-X v1.0** — Initial release, stable core ISA with vector extension placeholders reserved.

- ✅ Core integer ISA (98 instructions)
- ✅ Data transfer, arithmetic, logic, control transfer, system, flags, string operations
- ⏳ Vector/SIMD extension (under design)
- ⏳ Decoder RTL (planned)
- ⏳ Assembler & toolchain (planned)

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

**MacroCore-X v1.0** — 初始版本，核心 ISA 稳定，向量扩展占位已预留。

- ✅ 核心整数 ISA（98 条指令）
- ✅ 数据传输、算术、逻辑、控制转移、系统、标志位、字符串操作
- ⏳ 向量/SIMD 扩展（设计中）
- ⏳ 解码器 RTL（计划中）
- ⏳ 汇编器与工具链（计划中）

---

## 联系方式

如有疑问或贡献意愿，请在本仓库提交 Issue 或 Pull Request。
