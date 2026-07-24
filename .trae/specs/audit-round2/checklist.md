# Checklist

- [x] `div` 指令对负数操作数返回 truncate-toward-zero 结果（如 -5/2 = -2）
- [x] `div` 指令对正数操作数结果不变（如 10/3 = 3）
- [x] `div` 指令除以零时触发异常（行为不变）
- [x] ISA 规范 R-type 编码描述与实际实现一致
- [x] ISA 规范 L-type 编码描述与实际实现一致
- [x] ISA 规范 B-type 编码描述与实际实现一致
- [x] ISA 规范版本号统一（文件名与标题一致）
- [x] `fp_compare` 不再有 f32/f64 重复代码
- [x] `andi`/`ori`/`xori` 使用 `& 0x3FFF` 掩码
- [x] `divu` 表达式使用 `& 0xFFFFFFFFFFFFFFFF` 而非 `% 0x10000000000000000`
- [x] `lda` scale 非法值给出 ValueError 而非 KeyError
- [x] `parse_mem_operand` 对 `[r2 + -8]` 正确解析 offset=-8
- [x] fibonacci.asm 组装并运行通过
- [x] test_alu.asm 组装并运行通过
- [x] test_fp.asm 组装并运行通过
- [x] test_mmu.py 运行通过