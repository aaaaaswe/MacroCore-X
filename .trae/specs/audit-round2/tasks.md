# Tasks

- [x] Task 1: 修复 `div` 指令有符号除法（严重 Bug）
  - [x] 用 `sign_extend_64` 对 val1、val2 做符号扩展
  - [x] 用 `int(s1 / s2)` 替代 Python `//`（floor division），实现 truncate-toward-zero
  - [x] 验证：`div r1, r2, r3` 当 r2=-5、r3=2 时 r1=-2

- [x] Task 2: 修复 ISA 规范编码描述（R-type / L-type / B-type）
  - [x] 修正 R-type 编码：删除"累加器风格"注释，写明实际三操作数编码
  - [x] 修正 L-type 编码：byte0=完整 opcode，byte1=(Rd<<4)|Rs1
  - [x] 修正 B-type 编码：byte0=完整 opcode，byte1=(Rs1<<4)|Rs2
  - [x] 决定版本号：统一为 v1.0

- [x] Task 3: 重构 `fp_compare` 消除 f32/f64 重复
  - [x] 提取 `to_float` 函数指针，与 `fp_execute_f` 一致的模式
  - [x] 验证：FP 测试程序仍正常通过

- [x] Task 4: 修复 `andi`/`ori`/`xori` 掩码
  - [x] 将 `& 0xFFFF` 改为 `& 0x3FFF`（14 位零扩展，符合 ISA 规范）
  - [x] 同步修改汇编器的 `_emit_i` 编码逻辑

- [x] Task 5: 清理 `divu` 表达式
  - [x] 将 `val1 % 0x10000000000000000` 改为清晰的 `val1 & 0xFFFFFFFFFFFFFFFF`
  - [x] 将 `val2 % 0x10000000000000000` 同理修改

- [x] Task 6: 汇编器完善
  - [x] `_emit_l4` 中 `lda` 添加 scale 值校验（仅允许 1/2/4/8），给出友好错误信息
  - [x] 修复 `parse_mem_operand` 中负偏移 `[r2 + -8]` 的符号处理

- [x] Task 7: 回归测试
  - [x] 运行 fibonacci、test_alu、test_fp、test_mmu 确保全部通过

# Task Dependencies
- Task 2 独立于所有任务
- Task 3、4、5、6 可并行执行
- Task 1 和 Task 4 涉及同一文件不同区域，可并行但不建议
- Task 7 依赖所有其他任务