# MacroCore-X v2.0 指令集架构规范

**版本**：2.0  
**状态**：草案（Draft）  
**目标**：通用桌面/服务器64位处理器  
**编码**：变长（2/4/6/8字节）  
**字节序**：小端（Little-Endian）

---

## 第一章 整体架构

### 1.0 模块化架构

MacroCore-X v2.0 采用**模块化分层**设计：

**核心层（MacroCore-X，必选）** — 任何实现都必须包含：
- **R型**：标量整数运算（add, sub, mul, div, and, or, xor, shl, shr 等）
- **I型**：立即数运算（addi, subi, muli, movi, mov 等）
- **L型**：加载/存储（ld, st, ldw, stw, ldb, stb 等）
- **B型**：分支与跳转（beq, bne, jmp, call, ret, jreg 等）
- **C型**：复合操作（addm, subm, xchg, push, pop, enter, leave 等）
- **系统型**：系统控制与调试（syscall, int, cpuid, hlt, cli, sti, ecall 等）

**扩展层（可选）** — 按需裁剪：
- **F型（标量浮点扩展）**：fadd, fsub, fmul, fdiv, fcmp, fsqrt, fcvt, fmin, fmax, fneg, fabs
- **V型（向量扩展）**：vadd, vsub, vmul, vld, vst, vshuffle, vfmadd 等
- **矩阵加速扩展（预留）**：mmul, macc 等

> 层级关系：MacroCore-X 核心层 = 系统控制 + 标量整数 + 内存 + 分支 + 复合操作 + 调试，必选；扩展层 = 标量浮点 / 向量 / 矩阵，可选。

### 1.1 执行状态

| 组件 | 数量 | 宽度 | 说明 |
|------|------|------|------|
| 通用寄存器（GR） | 32 | 64位 | R0–R31 |
| 向量寄存器（VR） | 32 | 256位 | V0–V31 |
| 程序计数器（PC） | 1 | 64位 | 指向当前指令首字节 |
| 栈指针（SP） | 1 | 64位 | 软件约定使用R2，非硬连线 |
| 标志寄存器（FLAGS） | 1 | 4位 | CF/ZF/SF/OF |
| 模式寄存器（MODE） | 1 | 64位 | 特权级、向量长度、对齐策略等 |

### 1.2 寄存器详细定义

**R0**：硬连线为零。写入被忽略，读取返回0。  
**R1–R7**：参数传递（调用者保存）。  
**R8–R15**：临时/局部变量（调用者保存）。  
**R16–R23**：被调用者保存（Callee-Saved）。  
**R24–R30**：通用保留。  
**R31**：**返回地址寄存器（RA）**。`call`/`callreg`自动写入PC+当前指令长度；`ret`自动跳转到R31内容。

> 注：SP由软件约定为R2，但ISA不做硬编码，允许编译器自由选择栈指针寄存器。

### 1.3 向量寄存器

V0–V31，256位宽，可存放：
- 4个64位整数/浮点
- 8个32位整数/浮点
- 16个16位整数
- 32个8位整数

向量操作按**元素宽度**由指令后缀决定。

---

## 第二章 指令编码

### 2.1 长度判定（硬解码规则）

每条指令首字节的**高2位**决定指令总长度：

| `byte0[7:6]` | 指令长度 | 类别区间 |
|--------------|----------|----------|
| `00` | 2字节 | R型（操作码0x00–0x1F） |
| `01` | 4/6字节 | I/L/B型（0x20–0x6F, 4字节）；F型（0x70–0x7F, 6字节） |
| `10` | 6/8字节 | V/C扩展型（操作码0x80–0xBF） |
| `11` | 8字节 | 长指令（操作码0xC0–0xFF） |

> 注：F型（0x70–0x7F）虽然首字节高2位为`01`，但实际固定为6字节。解码器需根据具体操作码区间确定精确长度，而非仅依赖高2位。

### 2.2 指令通用结构

所有指令由以下字段按类型组合：

| 字段名 | 缩写 | 宽度（位） | 说明 |
|--------|------|-----------|------|
| 操作码 | OP | 2–8 | 指令功能编码 |
| 目标寄存器 | Rd | 4 | 通用寄存器编号（0–31） |
| 源寄存器1 | Rs1 | 4 | 通用寄存器编号 |
| 源寄存器2 | Rs2 | 4 | 通用寄存器编号 |
| 立即数 | IMM | 5–32 | 符号或零扩展 |
| 偏移量 | OFF | 12–21 | 相对跳转/内存偏移 |
| 扩展标志 | X | 1–4 | 宽度/原子/条件修饰 |

### 2.3 操作码映射表（完整）

| 操作码区间 | 指令类别 | 长度 | 主要用途 |
|-----------|----------|------|----------|
| 0x00–0x1F | **R型** | 2字节 | 寄存器-寄存器运算 |
| 0x20–0x3F | **I型** | 4字节 | 立即数运算/加载 |
| 0x40–0x5F | **L型** | 4/6字节 | 加载/存储 |
| 0x60–0x6F | **B型** | 4字节 | 分支/跳转 |
| 0x70–0x7F | **F型** | 6字节 | 标量浮点扩展（可选） |
| 0x80–0x8F | **V型** | 6/8字节 | 向量扩展（可选） |
| 0x90–0x9F | **C型** | 6/8字节 | 复合存储器操作 |
| 0xA0–0xBF | **系统型** | 2/4字节 | 特权/管理 |
| 0xC0–0xFF | **保留** | 各长度 | 未来扩展 |

---

## 第三章 指令定义

### 3.1 R型指令（2字节，OP 0x00–0x1F）

**格式**：
```
位:   7:4     3:0
      ┌──────┬──────┐
字节0 │ OP   │ 子类 │
      ├──────┼──────┤
字节1 │ Rs1  │ Rs2  │
      └──────┴──────┘
```
注：Rd = Rs1（目标=源1），或由子类隐含。

#### R型指令列表

| OP | 助记符 | 操作数 | 语义 |
|----|--------|--------|------|
| 0x00 | `add` | Rs1, Rs2 | R[Rs1] ← R[Rs1] + R[Rs2] |
| 0x01 | `sub` | Rs1, Rs2 | R[Rs1] ← R[Rs1] - R[Rs2] |
| 0x02 | `mul` | Rs1, Rs2 | R[Rs1] ← R[Rs1] × R[Rs2]（低64位） |
| 0x03 | `div` | Rs1, Rs2 | R[Rs1] ← R[Rs1] ÷ R[Rs2]（有符号，向零舍入） |
| 0x04 | `divu` | Rs1, Rs2 | R[Rs1] ← R[Rs1] ÷ R[Rs2]（无符号） |
| 0x05 | `and` | Rs1, Rs2 | R[Rs1] ← R[Rs1] & R[Rs2] |
| 0x06 | `or` | Rs1, Rs2 | R[Rs1] ← R[Rs1] \| R[Rs2] |
| 0x07 | `xor` | Rs1, Rs2 | R[Rs1] ← R[Rs1] ^ R[Rs2] |
| 0x08 | `shl` | Rs1, Rs2 | R[Rs1] ← R[Rs1] << (R[Rs2] & 0x3F) |
| 0x09 | `shr` | Rs1, Rs2 | R[Rs1] ← R[Rs1] >> (R[Rs2] & 0x3F)（逻辑） |
| 0x0A | `sar` | Rs1, Rs2 | R[Rs1] ← R[Rs1] >> (R[Rs2] & 0x3F)（算术） |
| 0x0B | `eq` | Rs1, Rs2 | R[Rs1] ← (R[Rs1] == R[Rs2]) ? 1 : 0 |
| 0x0C | `lt` | Rs1, Rs2 | R[Rs1] ← (R[Rs1] < R[Rs2]) ? 1 : 0（有符号） |
| 0x0D | `ltu` | Rs1, Rs2 | R[Rs1] ← (R[Rs1] < R[Rs2]) ? 1 : 0（无符号） |
| 0x0E | `max` | Rs1, Rs2 | R[Rs1] ← max(R[Rs1], R[Rs2])（有符号） |
| 0x0F | `min` | Rs1, Rs2 | R[Rs1] ← min(R[Rs1], R[Rs2])（有符号） |
| 0x10 | `ror` | Rs1, Rs2 | R[Rs1] ← R[Rs1] 循环右移 (R[Rs2] & 0x3F) |
| 0x11 | `rol` | Rs1, Rs2 | R[Rs1] ← R[Rs1] 循环左移 (R[Rs2] & 0x3F) |
| 0x12 | `clz` | Rs1 | R[Rs1] ← 前导零计数（R[Rs1]） |

> 所有R型指令更新标志位：CF/ZF/SF/OF（算术/逻辑指令）；`eq`/`lt`/`ltu`仅更新ZF；`clz`不更新标志。

---

### 3.2 I型指令（4字节，OP 0x20–0x3F）

**格式**：
```
字节0: [OP 6位][Rd 2位] ← Rd的高2位放这里
字节1: [Rd低2位][Rs1 4位][X 2位]
字节2-3: IMM16（小端）
```
实际编码使用紧凑压缩，解码器按位重组。为简化阅读，以下用伪格式表示。

| OP | 助记符 | 操作数 | 语义 |
|----|--------|--------|------|
| 0x20 | `addi` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] + sext(imm16) |
| 0x21 | `subi` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] - sext(imm16) |
| 0x22 | `muli` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] × sext(imm16) |
| 0x23 | `andi` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] & zext(imm16) |
| 0x24 | `ori` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] \| zext(imm16) |
| 0x25 | `xori` | Rd, Rs1, imm16 | R[Rd] ← R[Rs1] ^ zext(imm16) |
| 0x26 | `shli` | Rd, Rs1, imm5 | R[Rd] ← R[Rs1] << imm5（IMM[4:0]） |
| 0x27 | `shri` | Rd, Rs1, imm5 | R[Rd] ← R[Rs1] >> imm5（逻辑） |
| 0x28 | `sari` | Rd, Rs1, imm5 | R[Rd] ← R[Rs1] >> imm5（算术） |
| 0x29 | `mov` | Rd, imm16 | R[Rd] ← sext(imm16) |
| 0x2A | `movi` | Rd, imm32 | R[Rd] ← zext(imm32)（6字节扩展） |
| 0x2B-0x3F | *保留* | — | — |

> 标志更新规则同R型。

---

### 3.3 L型指令（加载/存储，4/6字节，OP 0x40–0x5F）

**格式（4字节）**：
```
字节0: [OP 4位][Rd 4位]
字节1: [Rs1 4位][SZ 2位][X 2位]
字节2-3: OFF16（小端有符号偏移）
```

**格式（6字节索引寻址，OP 0x50–0x5F）**：
```
字节0-1: 同上
字节2-3: OFF16
字节4-5: Rn（索引寄存器编号）+ 缩放因子（2位）
```

**SZ字段（位[3:2]）**：
- `00` = 8位
- `01` = 16位  
- `10` = 32位
- `11` = 64位

| OP | 助记符 | 操作数 | 语义 |
|----|--------|--------|------|
| 0x40 | `ld` | Rd, [Rs1 + off] | R[Rd] ← zext(Mem[Rs1+off, 64]) |
| 0x41 | `ldu` | Rd, [Rs1 + off] | R[Rd] ← zext(Mem[Rs1+off, SZ])（SZ=10/01/00） |
| 0x42 | `lds` | Rd, [Rs1 + off] | R[Rd] ← sext(Mem[Rs1+off, SZ])（SZ≠11） |
| 0x43 | `st` | Rs1, [Rs2 + off] | Mem[Rs2+off, 64] ← R[Rs1] |
| 0x44 | `stw` | Rs1, [Rs2 + off] | Mem[Rs2+off, 32] ← R[Rs1]（低32位） |
| 0x45 | `stb` | Rs1, [Rs2 + off] | Mem[Rs2+off, 8] ← R[Rs1]（低8位） |
| 0x46 | `lda` | Rd, Rs1, Rs2, scale | R[Rd] ← R[Rs1] + R[Rs2] × scale（scale=1/2/4/8） |
| 0x50 | `ldr` | Rd, [Rs1 + Rn*scale + off] | R[Rd] ← Mem[Rs1 + Rn×scale + off, 64]（6字节） |
| 0x51 | `str` | Rs1, [Rs2 + Rn*scale + off] | Mem[Rs2 + Rn×scale + off, 64] ← R[Rs1]（6字节） |
| 0x52-0x5F | *保留* | — | — |

> L型指令不更新标志位。

---

### 3.4 B型指令（分支/跳转，4字节，OP 0x60–0x7F）

**格式**：
```
字节0:   [OP 4位][Rs1 4位]
字节1:   [Rs2 4位][IMM12高4位]
字节2-3: IMM12低8位 + 填充
```

**偏移计算**：`target = PC + sign_ext(IMM12) << 2`（条件分支）  
`target = PC + sign_ext(IMM20) << 2`（`j`/`call`，使用全部20位）

| OP | 助记符 | 操作数 | 语义 |
|----|--------|--------|------|
| 0x60 | `j` | target20 | PC ← PC + sext(imm20)<<2 |
| 0x61 | `call` | target20 | R31 ← PC + 4; PC ← PC + sext(imm20)<<2 |
| 0x62 | `ret` | — | PC ← R[31] |
| 0x63 | `beq` | Rs1, Rs2, target12 | if (R[Rs1] == R[Rs2]) PC ← PC + sext(imm12)<<2 |
| 0x64 | `bne` | Rs1, Rs2, target12 | if (R[Rs1] != R[Rs2]) PC ← PC + sext(imm12)<<2 |
| 0x65 | `blt` | Rs1, Rs2, target12 | if (R[Rs1] < R[Rs2]) PC ← PC + sext(imm12)<<2（有符号） |
| 0x66 | `ble` | Rs1, Rs2, target12 | if (R[Rs1] ≤ R[Rs2]) PC ← PC + sext(imm12)<<2（有符号） |
| 0x67 | `bgt` | Rs1, Rs2, target12 | if (R[Rs1] > R[Rs2]) PC ← PC + sext(imm12)<<2（有符号） |
| 0x68 | `bge` | Rs1, Rs2, target12 | if (R[Rs1] ≥ R[Rs2]) PC ← PC + sext(imm12)<<2（有符号） |
| 0x69 | `bltu` | Rs1, Rs2, target12 | if (R[Rs1] < R[Rs2]) PC ← PC + sext(imm12)<<2（无符号） |
| 0x6A | `bgeu` | Rs1, Rs2, target12 | if (R[Rs1] ≥ R[Rs2]) PC ← PC + sext(imm12)<<2（无符号） |
| 0x6B | `jreg` | Rs1 | PC ← R[Rs1] |
| 0x6C | `callreg` | Rs1 | R31 ← PC + 4; PC ← R[Rs1] |
| 0x6D-0x6F | *保留* | — | — |

> 注意：`call`和`callreg`写入R31时，保存的返回地址是**当前PC + 4**（即`call`指令本身4字节长度），因为所有B型指令都是4字节。`ret`不检查R[31]有效性，由软件保证。

---

### 3.5 F型指令（标量浮点扩展，可选，6字节，OP 0x70–0x7F）

**格式（6字节）**：
```
字节0:   [0x7 4位][Fd 4位]
字节1:   [Fs1 4位][Fs2 4位]
字节2:   FUNCT8（操作码）
字节3:   AUX  [rm 3位][prec 2位][rsv 3位]
字节4-5: 保留
```

- **Fd**：目标 V 寄存器（标量浮点结果）
- **Fs1, Fs2**：源 V 寄存器（标量浮点操作数）
- **FUNCT8**：操作码
- **AUX**：精度和舍入模式
  - `prec`（位[2:1]）：0 = f32，1 = f64
  - `rm`（位[6:3]）：舍入模式（0 = RNE，1 = RTZ，2 = RDN，3 = RUP）

| FUNCT | 助记符 | 操作数 | 语义 |
|----|--------|--------|------|
| 0x00 | `fadd` | Fd, Fs1, Fs2 | V[Fd] ← float(V[Fs1]) + float(V[Fs2]) |
| 0x01 | `fsub` | Fd, Fs1, Fs2 | V[Fd] ← float(V[Fs1]) - float(V[Fs2]) |
| 0x02 | `fmul` | Fd, Fs1, Fs2 | V[Fd] ← float(V[Fs1]) × float(V[Fs2]) |
| 0x03 | `fdiv` | Fd, Fs1, Fs2 | V[Fd] ← float(V[Fs1]) ÷ float(V[Fs2]) |
| 0x04 | `fsqrt` | Fd, Fs1 | V[Fd] ← sqrt(float(V[Fs1])) |
| 0x05 | `fcmp` | Fs1, Fs2 | ZF ← (V[Fs1]==V[Fs2]); CF ← (V[Fs1]<V[Fs2]) |
| 0x06 | `fcvt.w.s` | Fd, Fs1 | V[Fd] ← int(float(V[Fs1]))（向零截断） |
| 0x07 | `fcvt.s.w` | Fd, Fs1 | V[Fd] ← float(int(V[Fs1])) |
| 0x08 | `fmin` | Fd, Fs1, Fs2 | V[Fd] ← min(float(V[Fs1]), float(V[Fs2])) |
| 0x09 | `fmax` | Fd, Fs1, Fs2 | V[Fd] ← max(float(V[Fs1]), float(V[Fs2])) |
| 0x0A | `fneg` | Fd, Fs1 | V[Fd] ← -float(V[Fs1]) |
| 0x0B | `fabs` | Fd, Fs1 | V[Fd] ← abs(float(V[Fs1])) |
| 0x0C-0xFF | *保留* | — | — |

> F型复用 V 寄存器文件（与向量扩展共用）。标量浮点操作将 V 寄存器的低32位（f32）或完整64位（f64）解释为 IEEE 754 浮点值。

---

### 3.6 V型指令（向量扩展，可选，6/8字节，OP 0x80–0x8F）

**格式（6字节）**：
```
字节0:   [0x8 4位][Vd 4位]
字节1:   [Vs1 4位][Vs2 4位]
字节2:   FUNCT8（操作码）
字节3:   AUX（元素宽度 / 掩码 / 混洗控制）
字节4-5: EXT（vld/vst的偏移量，vfmadd的Vs3）
```

**格式（8字节融合乘加）**：
```
字节0-5: 同上
字节4-5: Vs3（vfmadd的第三个源寄存器）
```

所有向量指令元素宽度由AUX字节的低2位指定：
- `00` = 8位
- `01` = 16位
- `10` = 32位
- `11` = 64位

| FUNCT | 助记符 | 操作数 | 语义 |
|----|--------|--------|------|
| 0x00 | `vadd` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] + V[Vs2][i] |
| 0x01 | `vsub` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] - V[Vs2][i] |
| 0x02 | `vmul` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] × V[Vs2][i] |
| 0x03 | `vand` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] & V[Vs2][i] |
| 0x04 | `vor` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] \| V[Vs2][i] |
| 0x05 | `vxor` | Vd, Vs1, Vs2 | V[Vd][i] ← V[Vs1][i] ^ V[Vs2][i] |
| 0x06 | `vld` | Vd, [Rs1 + off16] | V[Vd] ← Mem[Rs1+off, 256]（对齐） |
| 0x07 | `vst` | Vd, [Rs1 + off16] | Mem[Rs1+off, 256] ← V[Vd]（对齐） |
| 0x08 | `vshl` | Vd, Vs1, imm5 | V[Vd][i] ← V[Vs1][i] << imm5（逐元素） |
| 0x09 | `vshr` | Vd, Vs1, imm5 | V[Vd][i] ← V[Vs1][i] >> imm5（逻辑） |
| 0x0A | `vshuffle` | Vd, Vs1, imm8 | V[Vd][i] ← V[Vs1][ imm8[i] ]（按字节打乱，8字节） |
| 0x0B | `vfmadd` | Vd, Vs1, Vs2, Vs3 | V[Vd][i] ← V[Vs1][i]×V[Vs2][i]+V[Vs3][i]（8字节） |
| 0x0C-0xFF | *保留* | — | — |

---

### 3.7 C型指令（复合CISC，6/8字节，OP 0x90–0x9F）

所有C型指令在微架构层面分解为多个µop，但在ISA层面保证**原子性**（除特别注明）。

| OP | 助记符 | 操作数 | 语义 | µop分解 |
|----|--------|--------|------|---------|
| 0x90 | `addm` | Rs1, [Rs2 + off] | Mem[Rs2+off] ← Mem[Rs2+off] + R[Rs1] | ld→add→st |
| 0x91 | `subm` | Rs1, [Rs2 + off] | Mem[Rs2+off] ← Mem[Rs2+off] - R[Rs1] | ld→sub→st |
| 0x92 | `xchg` | Rs1, [Rs2 + off] | 交换 R[Rs1] ↔ Mem[Rs2+off]（原子） | ld→st |
| 0x93 | `cmpxchg` | Rs1, Rs2, [Rs3+off] | if (Mem[Rs3+off] == R[Rs1]) Mem←R[Rs2]（原子，8字节） | ld→cmp→st |
| 0x94 | `push` | Rs1 | SP←SP-8; Mem[SP,64] ← R[Rs1] | sub→st |
| 0x95 | `pop` | Rs1 | R[Rs1] ← Mem[SP,64]; SP←SP+8 | ld→add |
| 0x96 | `enter` | imm16 | SP←SP-imm16; Mem[SP,64]←R[30]（保存RBP） | sub→st |
| 0x97 | `leave` | — | SP←R[30]+8; R[30]←Mem[SP-8,64] | ld→add |
| 0x98-0x9F | *保留* | — | — |

> `push`/`pop`使用**R2作为SP**（约定），`enter`使用R30作为帧指针（约定），但ISA不强制。

---

### 3.8 系统指令（2/4字节，OP 0xA0–0xBF）

| OP | 助记符 | 操作数 | 语义 | 长度 |
|----|--------|--------|------|------|
| 0xA0 | `syscall` | imm8 | 触发系统调用（imm8→系统调用号，进入内核态） | 2 |
| 0xA1 | `sysret` | — | 从系统调用返回（恢复用户态） | 2 |
| 0xA2 | `int` | imm8 | 软件中断（imm8→中断向量） | 2 |
| 0xA3 | `iret` | — | 从中断返回 | 2 |
| 0xA4 | `rdmsr` | Rs1, imm12 | R[Rs1] ← MSR[imm12] | 4 |
| 0xA5 | `wrmsr` | Rs1, imm12 | MSR[imm12] ← R[Rs1] | 4 |
| 0xA6 | `cpuid` | — | 填充R0:R1:R2:R3 = 厂商/特性/缓存/版本信息 | 2 |
| 0xA7 | `hlt` | — | 暂停执行，直到中断 | 2 |
| 0xA8 | `cli` | — | 清除中断使能标志（IF=0） | 2 |
| 0xA9 | `sti` | — | 设置中断使能标志（IF=1） | 2 |
| 0xAA | `nop` | — | 空操作（PC ← PC + 2） | 2 |
| 0xAB | `ecall` | imm8 | 环境调用（模拟器/调试入口） | 2 |
| 0xAC-0xBF | *保留* | — | — | 各长度 |

---

## 第四章 异常与中断

### 4.1 异常向量表

| 向量号 | 名称 | 触发条件 |
|--------|------|----------|
| 0x00 | 除零异常 | `div`/`divu` 除数为0 |
| 0x01 | 非法指令 | 未定义操作码 |
| 0x02 | 对齐错误 | 未对齐访问且MODE.ALIGN=1 |
| 0x03 | 页错误 | MMU缺页/权限违规 |
| 0x04 | 断点 | `ecall` 指令 |
| 0x05 | 系统调用 | `syscall` 指令 |
| 0x06 | 外部中断 | 硬件IRQ |
| 0x07-0x1F | 保留 | 自定义 |

### 4.2 异常处理流程

1. 保存当前PC到**异常返回寄存器（ERR）**（内部不可见）；
2. 保存当前FLAGS到**EF（异常标志）**；
3. 进入特权模式（MODE.PRIV=0）；
4. PC ← 异常向量表基址 + 向量号×8；
5. 执行异常处理程序。

`iret` 指令从异常返回：恢复FLAGS ← EF，PC ← ERR。

---

## 第五章 内存模型

### 5.1 地址空间

- 64位平坦地址空间，虚拟地址宽**48位**（当前实现），物理地址宽**52位**（可配置）。
- 支持4KB、2MB、1GB页（由MMU实现定义）。

### 5.2 对齐策略

MODE.ALIGN位控制：
- `0`：允许非对齐访问（由微架构处理）
- `1`：非对齐访问触发#对齐异常

### 5.3 内存排序

**弱内存模型（Weak Memory Model）**，不保证顺序，需使用`fence`指令（保留操作码空间0xAC）来强制执行顺序。

`fence`指令格式（保留，暂未分配具体编码）。

---

## 第六章 汇编语法

### 6.1 语法风格（类AT&T，但简化）

```
<指令> <目标>, <源1>, <源2>
```

**示例**：
```
add r1, r2          # R型，r1 = r1 + r2
addi r3, r1, 0x100  # I型，r3 = r1 + 256
ld r4, [r2 + 0x8]   # 加载64位
st r5, [r3 - 0x4]   # 存储64位
call 0x10000        # 调用函数
fadd v2, v0, v1     # F型标量浮点加法
fcmp v0, v1         # F型浮点比较
vadd v1, v2, v3     # V型向量加法
push r6             # 压栈
syscall 0x1         # 系统调用
```

### 6.2 伪指令

| 伪指令 | 展开 |
|--------|------|
| `li Rd, imm` | `mov Rd, imm`（若imm≤16位）或`movi Rd, imm`（若imm>16位） |
| `la Rd, label` | `lda Rd, PC, label, 1`（地址计算） |
| `nop` | `add r0, r0`（实际编码为`xor r0, r0`？不，有独立`nop`） |

---

## 第七章 与现有生态的对接

### 7.1 ELF文件格式

需要定义：
- **EM_MACROCORE** 机器码（申请值待定）
- **重定位类型**：R_MACRO_32、R_MACRO_64、R_MACRO_PC20、R_MACRO_PC12
- **ABI版本**：宏内核（Linux风格）或微内核

### 7.2 系统调用ABI

约定（与Linux x86_64兼容简化版）：
- 系统调用号：R1
- 参数1–6：R2–R7
- 返回值：R1
- 系统调用指令：`syscall 0x0`（使用R1中的号码）

---

## 附录A：指令编码完整表（字节级）

| 助记符 | 字节0（hex） | 长度 | 格式 |
|--------|-------------|------|------|
| `add` | 0x00 | 2 | R |
| `sub` | 0x01 | 2 | R |
| `mul` | 0x02 | 2 | R |
| `div` | 0x03 | 2 | R |
| `divu` | 0x04 | 2 | R |
| ...（完整表略） | | | |
| `syscall` | 0xA0 | 2 | SYS |
| `cpuid` | 0xA6 | 2 | SYS |
| `nop` | 0xAA | 2 | SYS |

> 完整编码表需配合操作数编码器生成，本文档提供查表依据。

---

## 附录B：设计决策记录

| 决策 | 理由 |
|------|------|
| 2/4/6/8字节变长 | 解码器首周期通过高2位定长，兼顾密度与速度 |
| R0硬连线0 | 简化编译器（常见零值）和通用代码（`xor`指令） |
| R31硬件返回地址 | 去掉`jalr`的额外指令，`call`/`ret`更高效 |
| 无浮点标量指令 | F型扩展提供独立的标量浮点指令（fadd/fsub/fmul/fdiv等），与向量扩展（V型）分离，各为可选模块 |
| 弱内存模型 | 适用于多核，保留`fence`扩展位置 |
