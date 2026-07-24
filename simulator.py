#!/usr/bin/env python3
"""
MacroCore-X Simulator / Emulator
A behavioral simulator for the MacroCore-X ISA.

Usage:
    python3 simulator.py program.bin           # execute binary
    python3 simulator.py program.bin -d        # execute with disassembly trace
    python3 simulator.py program.bin -s 1000   # execute max 1000 steps
"""

import sys
import struct
from typing import Dict, Tuple, Optional


# =============================================================================
# Register State
# =============================================================================

class CPU:
    def __init__(self, memory_size: int = 0x100000):  # 1MB default
        # General-purpose registers R0-R31
        self.r = [0] * 32
        # Vector registers V0-V31 (256-bit each, stored as list of ints)
        self.v = [0] * 32  # simplified: store as scalar for now
        # Scalar FP registers F0-F31 (64-bit each, independent FPU)
        self.f = [0] * 32
        # Program counter
        self.pc = 0
        # Flags: CF, ZF, SF, OF
        self.cf = 0
        self.zf = 0
        self.sf = 0
        self.of = 0
        # Memory
        self.mem = bytearray(memory_size)
        self.mem_size = memory_size
        # Interrupt enable
        self.iflag = 1
        # Privilege mode (0=kernel, 1=user)
        self.priv = 1
        # Exception return register
        self.err = 0
        self.ef = 0
        # Halt flag
        self.halted = False
        # Step counter
        self.steps = 0
        # Instruction count for disassembly
        self.inst_count = 0

    def read_mem(self, addr: int, size: int, signed: bool = False) -> int:
        """Read from memory."""
        if addr < 0 or addr + size > self.mem_size:
            raise Exception(f"Memory access out of bounds: 0x{addr:x}")
        data = int.from_bytes(self.mem[addr:addr+size], 'little', signed=signed)
        return data

    def write_mem(self, addr: int, size: int, value: int):
        """Write to memory."""
        if addr < 0 or addr + size > self.mem_size:
            raise Exception(f"Memory access out of bounds: 0x{addr:x}")
        self.mem[addr:addr+size] = value.to_bytes(size, 'little', signed=False)

    def read_byte(self, addr: int) -> int:
        return self.mem[addr]

    def read_u16(self, addr: int) -> int:
        return struct.unpack_from('<H', self.mem, addr)[0]

    def read_u32(self, addr: int) -> int:
        return struct.unpack_from('<I', self.mem, addr)[0]

    def read_i16(self, addr: int) -> int:
        return struct.unpack_from('<h', self.mem, addr)[0]


# =============================================================================
# Instruction Decoder / Disassembler
# =============================================================================

# R-type mnemonic reverse map
R_MNEMONICS = {
    0x00: 'add', 0x01: 'sub', 0x02: 'mul', 0x03: 'div', 0x04: 'divu',
    0x05: 'and', 0x06: 'or', 0x07: 'xor', 0x08: 'shl', 0x09: 'shr',
    0x0A: 'sar', 0x0B: 'eq', 0x0C: 'lt', 0x0D: 'ltu', 0x0E: 'max',
    0x0F: 'min', 0x10: 'ror', 0x11: 'rol', 0x12: 'clz',
}

I_MNEMONICS = {
    0x20: 'addi', 0x21: 'subi', 0x22: 'muli', 0x23: 'andi', 0x24: 'ori',
    0x25: 'xori', 0x26: 'shli', 0x27: 'shri', 0x28: 'sari', 0x29: 'mov',
    0x2A: 'movi',
}

L4_MNEMONICS = {
    0x40: 'ld', 0x41: 'ldu', 0x42: 'lds', 0x43: 'st', 0x44: 'stw',
    0x45: 'stb', 0x46: 'lda',
}

L6_MNEMONICS = {0x50: 'ldr', 0x51: 'str'}

B_MNEMONICS = {
    0x60: 'j', 0x61: 'call', 0x62: 'ret', 0x63: 'beq', 0x64: 'bne',
    0x65: 'blt', 0x66: 'ble', 0x67: 'bgt', 0x68: 'bge', 0x69: 'bltu',
    0x6A: 'bgeu', 0x6B: 'jreg', 0x6C: 'callreg',
}

V_MNEMONICS = {
    0x00: 'vadd', 0x01: 'vsub', 0x02: 'vmul', 0x03: 'vand', 0x04: 'vor',
    0x05: 'vxor', 0x06: 'vld', 0x07: 'vst', 0x08: 'vshl', 0x09: 'vshr',
    0x0A: 'vshuffle', 0x0B: 'vfmadd',
}

F_MNEMONICS = {
    0x00: 'fadd', 0x01: 'fsub', 0x02: 'fmul', 0x03: 'fdiv',
    0x04: 'fsqrt', 0x05: 'fcmp', 0x06: 'fcvt.w.s', 0x07: 'fcvt.s.w',
    0x08: 'fmin', 0x09: 'fmax', 0x0A: 'fneg', 0x0B: 'fabs',
    0x0C: 'fld', 0x0D: 'fst',
}

C_MNEMONICS = {
    0x90: 'addm', 0x91: 'subm', 0x92: 'xchg', 0x93: 'cmpxchg',
    0x94: 'push', 0x95: 'pop', 0x96: 'enter', 0x97: 'leave',
}

SYS2_MNEMONICS = {
    0xB0: 'syscall', 0xB1: 'sysret', 0xB2: 'int', 0xB3: 'iret',
    0xB6: 'cpuid', 0xB7: 'hlt', 0xB8: 'cli', 0xB9: 'sti',
    0xBA: 'nop', 0xBB: 'ecall', 0xBC: 'fence', 0xBD: 'bkpt',
}

SYS4_MNEMONICS = {0xB4: 'rdmsr', 0xB5: 'wrmsr'}


def get_inst_length(cpu: CPU, opcode: int, pc: int) -> int:
    """Determine instruction length from opcode byte."""
    if opcode <= 0x1F:
        return 4  # R-type (4 bytes)
    if opcode == 0x2A:  # movi (6-byte I-type)
        return 6
    if 0x20 <= opcode <= 0x29:
        return 4  # I-type
    if 0x40 <= opcode <= 0x46:
        return 4  # L-type 4-byte
    if 0x50 <= opcode <= 0x51:
        return 6  # L-type 6-byte
    if 0x60 <= opcode <= 0x6C:
        return 4  # B-type
    if (opcode & 0xF0) == 0x80:
        # V-type: check funct for vfmadd (8 bytes)
        if len(cpu.mem) > pc + 2:
            funct = cpu.read_byte(pc + 2)
            if funct == 0x0B:  # vfmadd
                return 8
        return 6
    if (opcode & 0xF0) == 0xA0:
        return 6  # F-type scalar FP
    if 0x90 <= opcode <= 0x97:
        return 6  # C-type
    if opcode in (0xB0, 0xB1, 0xB2, 0xB3, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD):
        return 2  # System 2-byte
    if opcode in (0xB4, 0xB5):
        return 4  # System 4-byte
    return 2  # default


def disassemble_one(cpu: CPU, pc: int) -> Tuple[str, int]:
    """Disassemble one instruction at PC. Returns (string, length)."""
    opcode = cpu.read_byte(pc)
    length = get_inst_length(cpu, opcode, pc)

    if opcode <= 0x1F:
        # R-type: 4-byte, byte0=opcode, byte1=(Rd<<3)|(Rs1>>2), byte2=((Rs1&3)<<6)|(Rs2<<1)|X, byte3=0
        byte1 = cpu.read_byte(pc + 1)
        byte2 = cpu.read_byte(pc + 2)
        rd = (byte1 >> 3) & 0x1F
        rs1 = ((byte1 & 0x7) << 2) | ((byte2 >> 6) & 0x3)
        rs2 = (byte2 >> 1) & 0x1F
        mnem = R_MNEMONICS.get(opcode, f'???')
        if opcode == 0x12:  # clz
            return f"{mnem} r{rd}, r{rs1}", length
        return f"{mnem} r{rd}, r{rs1}, r{rs2}", length

    elif 0x20 <= opcode <= 0x29:
        # I-type 4-byte: byte0=opcode, byte1=[Rd 5 bits][Rs1[4:2] 3 bits], byte2=[Rs1[1:0] 2 bits][IMM[13:8] 6 bits], byte3=IMM[7:0]
        byte1 = cpu.read_byte(pc + 1)
        byte2 = cpu.read_byte(pc + 2)
        byte3 = cpu.read_byte(pc + 3)
        rd = (byte1 >> 3) & 0x1F
        rs1 = ((byte1 & 0x7) << 2) | ((byte2 >> 6) & 0x3)
        imm = (((byte2 & 0x3F) << 8) | byte3)  # 14-bit unsigned
        imm = sign_extend_64(imm, 14)
        mnem = I_MNEMONICS.get(opcode, f'???')
        if mnem in ('shli', 'shri', 'sari'):
            return f"{mnem} r{rd}, r{rs1}, {imm & 0x3F}", length
        if mnem == 'mov':
            return f"{mnem} r{rd}, {imm}", length
        return f"{mnem} r{rd}, r{rs1}, {imm}", length

    elif opcode == 0x2A:
        # movi (6-byte): byte0=0x2A, byte1=[Rd 5 bits][000], byte2-5=imm32 LE
        byte1 = cpu.read_byte(pc + 1)
        rd = (byte1 >> 3) & 0x1F
        imm = cpu.read_u32(pc + 2)
        return f"movi r{rd}, 0x{imm:x}", length

    elif 0x40 <= opcode <= 0x46:
        # L-type 4-byte: byte0=opcode, byte1=(rd<<4)|rs1, byte2-3=off16
        byte1 = cpu.read_byte(pc + 1)
        rd = (byte1 >> 4) & 0xF
        rs1 = byte1 & 0xF
        off = cpu.read_i16(pc + 2)
        mnem = L4_MNEMONICS.get(opcode, f'???')

        if mnem == 'lda':
            extra = cpu.read_u16(pc + 2)
            rs2 = (extra >> 2) & 0xF
            scale = 1 << (extra & 0x3)
            return f"lda r{rd}, r{rs1}, r{rs2}, {scale}", length

        if mnem.startswith('st'):
            return f"{mnem} r{rd}, [r{rs1} + {off}]", length
        return f"{mnem} r{rd}, [r{rs1} + {off}]", length

    elif 0x50 <= opcode <= 0x51:
        # L-type 6-byte indexed: byte0=opcode, byte1=(rd<<4)|rs1, byte2-3=off16, byte4-5=(rn<<2)|scale
        byte1 = cpu.read_byte(pc + 1)
        rd = (byte1 >> 4) & 0xF
        rs1 = byte1 & 0xF
        off = cpu.read_i16(pc + 2)
        extra = cpu.read_u16(pc + 4)
        rn = (extra >> 2) & 0xF
        scale = 1 << (extra & 0x3)
        mnem = L6_MNEMONICS.get(opcode, f'???')
        if mnem == 'str':
            return f"{mnem} r{rd}, [r{rs1} + r{rn}*{scale} + {off}]", length
        return f"{mnem} r{rd}, [r{rs1} + r{rn}*{scale} + {off}]", length

    elif 0x60 <= opcode <= 0x6C:
        # B-type: byte0=opcode, byte1=(rs1<<4)|rs2, byte2-3=imm
        byte1 = cpu.read_byte(pc + 1)
        mnem = B_MNEMONICS.get(opcode, f'???')

        if mnem == 'ret':
            return "ret", length

        if mnem in ('j', 'call'):
            imm_hi = byte1 & 0xFF
            imm_mid = cpu.read_byte(pc + 2)
            imm_lo = cpu.read_byte(pc + 3)
            imm20 = (imm_hi << 16) | (imm_mid << 8) | imm_lo
            imm20 = sign_extend_64(imm20, 20)
            target = pc + (imm20 << 2)
            return f"{mnem} 0x{target:x}", length

        if mnem in ('jreg', 'callreg'):
            rs1 = (byte1 >> 4) & 0xF
            return f"{mnem} r{rs1}", length

        # Conditional branch
        rs1 = (byte1 >> 4) & 0xF
        rs2 = byte1 & 0xF
        imm_hi = cpu.read_byte(pc + 2)
        imm_lo = cpu.read_byte(pc + 3)
        imm12 = (imm_hi << 8) | imm_lo
        imm12 = sign_extend_64(imm12, 12)
        target = pc + (imm12 << 2)
        return f"{mnem} r{rs1}, r{rs2}, 0x{target:x}", length

    elif (opcode & 0xF0) == 0x80:
        # V-type (new encoding): byte0=0x80|Vd, byte1=(Vs1<<4)|Vs2, byte2=funct, byte3=aux, byte4-5=ext
        byte1 = cpu.read_byte(pc + 1)
        vd = opcode & 0xF
        vs1 = (byte1 >> 4) & 0xF
        vs2 = byte1 & 0xF
        funct = cpu.read_byte(pc + 2)
        aux = cpu.read_byte(pc + 3)
        ext = cpu.read_u16(pc + 4)
        mnem = V_MNEMONICS.get(funct, f'v???({funct:02x})')

        if mnem in ('vld', 'vst'):
            off = sign_extend_64(ext, 16)
            return f"{mnem} v{vd}, [r{vs1} + {off}]", length
        if mnem in ('vshl', 'vshr'):
            return f"{mnem} v{vd}, v{vs1}, {vs2}", length
        if mnem == 'vshuffle':
            return f"{mnem} v{vd}, v{vs1}, {aux}", length
        if mnem == 'vfmadd':
            vs3 = ext & 0xF
            return f"{mnem} v{vd}, v{vs1}, v{vs2}, v{vs3}", length
        return f"{mnem} v{vd}, v{vs1}, v{vs2}", length

    elif (opcode & 0xF0) == 0xA0:
        # F-type scalar FP (independent FPU registers)
        byte1 = cpu.read_byte(pc + 1)
        fd = opcode & 0xF
        fs1 = (byte1 >> 4) & 0xF
        fs2 = byte1 & 0xF
        funct = cpu.read_byte(pc + 2)
        aux = cpu.read_byte(pc + 3)
        mnem = F_MNEMONICS.get(funct, f'f???({funct:02x})')
        prec = 'f64' if (aux & 0x06) else 'f32'  # prec in bits [2:1]

        if mnem in ('fsqrt', 'fneg', 'fabs', 'fcvt.w.s', 'fcvt.s.w'):
            return f"{mnem} f{fd}, f{fs1}", length
        if mnem == 'fcmp':
            return f"{mnem} f{fs1}, f{fs2}", length
        if mnem == 'fld':
            off = cpu.read_i16(pc + 4)
            return f"{mnem} f{fd}, [r{fs1} + {off}]", length
        if mnem == 'fst':
            off = cpu.read_i16(pc + 4)
            return f"{mnem} f{fd}, [r{fs1} + {off}]", length
        return f"{mnem} f{fd}, f{fs1}, f{fs2}", length

    elif 0x90 <= opcode <= 0x97:
        # C-type
        byte1 = cpu.read_byte(pc + 1)
        rd = opcode & 0xF
        rs1 = (byte1 >> 4) & 0xF
        rs2 = byte1 & 0xF
        mnem = C_MNEMONICS.get(opcode, f'???')

        if mnem in ('addm', 'subm', 'xchg'):
            off = cpu.read_i16(pc + 2)
            return f"{mnem} r{rd}, [r{rs2} + {off}]", length
        if mnem == 'cmpxchg':
            off = cpu.read_i16(pc + 2)
            base = cpu.read_u16(pc + 4) & 0xF
            return f"{mnem} r{rd}, r{rs2}, [r{base} + {off}]", length
        if mnem in ('push', 'pop'):
            return f"{mnem} r{rd}", length
        if mnem == 'enter':
            imm = cpu.read_i16(pc + 2)
            return f"{mnem} {imm}", length
        if mnem == 'leave':
            return "leave", length
        return f"{mnem}", length

    elif opcode in (0xB0, 0xB1, 0xB2, 0xB3, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD):
        # System 2-byte
        mnem = SYS2_MNEMONICS.get(opcode, f'???')
        imm8 = cpu.read_byte(pc + 1)
        if mnem in ('syscall', 'int', 'ecall', 'bkpt'):
            return f"{mnem} {imm8}", length
        if mnem == 'fence':
            pi = (imm8 >> 4) & 0xF
            po = imm8 & 0xF
            return f"{mnem} 0x{pi:x}, 0x{po:x}", length
        return mnem, length

    elif opcode in (0xB4, 0xB5):
        # System 4-byte
        mnem = SYS4_MNEMONICS.get(opcode, f'???')
        byte1 = cpu.read_byte(pc + 1)
        rs1 = (byte1 >> 4) & 0xF
        imm_hi = byte1 & 0xF
        imm_lo = cpu.read_byte(pc + 2)
        imm12 = (imm_hi << 8) | imm_lo
        return f"{mnem} r{rs1}, {imm12}", length

    return f"??? 0x{opcode:02x}", length


# =============================================================================
# Execution Engine
# =============================================================================

def sign_extend_64(val: int, bits: int) -> int:
    """Sign-extend to 64 bits, returning a Python int (may be negative)."""
    mask = (1 << bits) - 1
    val = val & mask
    if val & (1 << (bits - 1)):
        val = val - (1 << bits)
    return val

def set_flags_arith(cpu: CPU, result: int, op1: int, op2: int, is_sub: bool = False):
    """Set flags after arithmetic operation."""
    result = result & 0xFFFFFFFFFFFFFFFF
    cpu.zf = 1 if result == 0 else 0
    cpu.sf = 1 if (result >> 63) & 1 else 0
    # Carry flag
    if is_sub:
        cpu.cf = 1 if op1 < op2 else 0
    else:
        cpu.cf = 1 if (op1 + op2) > 0xFFFFFFFFFFFFFFFF else 0
    # Overflow flag
    if is_sub:
        cpu.of = 1 if ((op1 ^ op2) & (op1 ^ result) & 0x8000000000000000) else 0
    else:
        cpu.of = 1 if ((~(op1 ^ op2)) & (op1 ^ result) & 0x8000000000000000) else 0

def set_flags_logical(cpu: CPU, result: int):
    """Set flags after logical operation."""
    result = result & 0xFFFFFFFFFFFFFFFF
    cpu.zf = 1 if result == 0 else 0
    cpu.sf = 1 if (result >> 63) & 1 else 0
    cpu.cf = 0
    cpu.of = 0


# =============================================================================
# Scalar FP Helpers
# =============================================================================

def int_to_f32(val: int) -> float:
    """Convert 64-bit integer (low 32 bits) to IEEE 754 single-precision float."""
    return struct.unpack('<f', struct.pack('<I', val & 0xFFFFFFFF))[0]

def f32_to_int(val: float) -> int:
    """Convert IEEE 754 single-precision float to 64-bit integer (zero-extended)."""
    return struct.unpack('<I', struct.pack('<f', val))[0]

def int_to_f64(val: int) -> float:
    """Convert 64-bit integer to IEEE 754 double-precision float."""
    return struct.unpack('<d', struct.pack('<Q', val))[0]

def f64_to_int(val: float) -> int:
    """Convert IEEE 754 double-precision float to 64-bit integer."""
    return struct.unpack('<Q', struct.pack('<d', val))[0]

def fp_execute_f(cpu: CPU, fd: int, fs1: int, fs2: int, funct: int, aux: int):
    """Execute F-type scalar FP operation on independent F registers.
    aux byte: [rm 3 bits][prec 2 bits][rsv 3 bits]
    prec: bits [2:1] — 0=f32, 1=f64
    """
    is_f64 = ((aux >> 1) & 0x3) == 1
    if is_f64:
        a = int_to_f64(cpu.f[fs1])
        b = int_to_f64(cpu.f[fs2]) if funct not in (0x04, 0x06, 0x07) else 0.0
        if funct == 0x00:  # fadd
            result = a + b
        elif funct == 0x01:  # fsub
            result = a - b
        elif funct == 0x02:  # fmul
            result = a * b
        elif funct == 0x03:  # fdiv
            result = a / b if b != 0.0 else float('inf')
        elif funct == 0x04:  # fsqrt
            result = a ** 0.5 if a >= 0.0 else float('nan')
        elif funct == 0x06:  # fcvt.w.s (float→int)
            result = float(int(a))  # truncate toward zero
        elif funct == 0x07:  # fcvt.s.w (int→float)
            result = float(a)
        elif funct == 0x08:  # fmin
            result = a if a < b else b
        elif funct == 0x09:  # fmax
            result = a if a > b else b
        else:
            result = 0.0
        cpu.f[fd] = f64_to_int(result)
    else:
        a = int_to_f32(cpu.f[fs1])
        b = int_to_f32(cpu.f[fs2]) if funct not in (0x04, 0x06, 0x07) else 0.0
        if funct == 0x00:  # fadd
            result = a + b
        elif funct == 0x01:  # fsub
            result = a - b
        elif funct == 0x02:  # fmul
            result = a * b
        elif funct == 0x03:  # fdiv
            result = a / b if b != 0.0 else float('inf')
        elif funct == 0x04:  # fsqrt
            result = a ** 0.5 if a >= 0.0 else float('nan')
        elif funct == 0x06:  # fcvt.w.s (float→int)
            result = float(int(a))
        elif funct == 0x07:  # fcvt.s.w (int→float)
            result = float(a)
        elif funct == 0x08:  # fmin
            result = a if a < b else b
        elif funct == 0x09:  # fmax
            result = a if a > b else b
        else:
            result = 0.0
        cpu.f[fd] = f32_to_int(result)


def fp_compare(cpu: CPU, fs1: int, fs2: int, aux: int):
    """Execute F-type fcmp: set CPU flags based on float comparison."""
    is_f64 = ((aux >> 1) & 0x3) == 1
    if is_f64:
        a = int_to_f64(cpu.f[fs1])
        b = int_to_f64(cpu.f[fs2])
    else:
        a = int_to_f32(cpu.f[fs1])
        b = int_to_f32(cpu.f[fs2])
    cpu.zf = 1 if a == b else 0
    cpu.cf = 1 if a < b else 0
    cpu.sf = 0
    cpu.of = 0


def fp_unary(cpu: CPU, fd: int, fs1: int, aux: int, negate: bool):
    """Execute F-type unary FP operation: fneg or fabs."""
    is_f64 = ((aux >> 1) & 0x3) == 1
    if is_f64:
        a = int_to_f64(cpu.f[fs1])
        if negate:
            result = -a
        else:
            result = abs(a)
        cpu.f[fd] = f64_to_int(result)
    else:
        a = int_to_f32(cpu.f[fs1])
        if negate:
            result = -a
        else:
            result = abs(a)
        cpu.f[fd] = f32_to_int(result)


def execute_one(cpu: CPU, trace: bool = False) -> bool:
    """
    Execute one instruction. Returns True if execution should continue.
    """
    pc = cpu.pc
    opcode = cpu.read_byte(pc)
    length = get_inst_length(cpu, opcode, pc)

    if trace:
        disasm, _ = disassemble_one(cpu, pc)
        print(f"  [{cpu.steps:6d}] 0x{pc:04x}: {disasm}")

    # ---- R-type (4 bytes) ----
    if opcode <= 0x1F:
        byte1 = cpu.read_byte(pc + 1)
        byte2 = cpu.read_byte(pc + 2)
        rd = (byte1 >> 3) & 0x1F
        rs1 = ((byte1 & 0x7) << 2) | ((byte2 >> 6) & 0x3)
        rs2 = (byte2 >> 1) & 0x1F
        val1 = cpu.r[rs1]
        val2 = cpu.r[rs2]

        if opcode == 0x00:  # add
            result = (val1 + val2) & 0xFFFFFFFFFFFFFFFF
            set_flags_arith(cpu, result, val1, val2)
            cpu.r[rd] = result
        elif opcode == 0x01:  # sub
            result = (val1 - val2) & 0xFFFFFFFFFFFFFFFF
            set_flags_arith(cpu, result, val1, val2, True)
            cpu.r[rd] = result
        elif opcode == 0x02:  # mul
            result = (val1 * val2) & 0xFFFFFFFFFFFFFFFF
            set_flags_arith(cpu, result, val1, val2)
            cpu.r[rd] = result
        elif opcode == 0x03:  # div
            if val2 == 0:
                raise_exception(cpu, 0x00)
                return True
            result = (val1 // val2) & 0xFFFFFFFFFFFFFFFF  # signed
            cpu.r[rd] = result
            cpu.zf = 1 if result == 0 else 0
            cpu.sf = 1 if (result >> 63) & 1 else 0
        elif opcode == 0x04:  # divu
            if val2 == 0:
                raise_exception(cpu, 0x00)
                return True
            result = (val1 % 0x10000000000000000) // (val2 % 0x10000000000000000)
            cpu.r[rd] = result
            cpu.zf = 1 if result == 0 else 0
            cpu.sf = 1 if (result >> 63) & 1 else 0
        elif opcode == 0x05:  # and
            result = val1 & val2
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x06:  # or
            result = val1 | val2
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x07:  # xor
            result = val1 ^ val2
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x08:  # shl
            shift = val2 & 0x3F
            result = (val1 << shift) & 0xFFFFFFFFFFFFFFFF
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x09:  # shr
            shift = val2 & 0x3F
            result = val1 >> shift
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x0A:  # sar
            shift = val2 & 0x3F
            result = (val1 & 0xFFFFFFFFFFFFFFFF) >> shift
            if val1 & 0x8000000000000000:
                result |= ((-1 << (64 - shift)) & 0xFFFFFFFFFFFFFFFF)
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x0B:  # eq
            cpu.r[rd] = 1 if val1 == val2 else 0
            cpu.zf = 1 if cpu.r[rd] == 0 else 0
        elif opcode == 0x0C:  # lt
            # Actually need signed comparison
            s1 = val1 if (val1 >> 63) == 0 else val1 - 0x10000000000000000
            s2 = val2 if (val2 >> 63) == 0 else val2 - 0x10000000000000000
            cpu.r[rd] = 1 if s1 < s2 else 0
            cpu.zf = 1 if cpu.r[rd] == 0 else 0
        elif opcode == 0x0D:  # ltu
            cpu.r[rd] = 1 if val1 < val2 else 0
            cpu.zf = 1 if cpu.r[rd] == 0 else 0
        elif opcode == 0x0E:  # max
            s1 = val1 if (val1 >> 63) == 0 else val1 - 0x10000000000000000
            s2 = val2 if (val2 >> 63) == 0 else val2 - 0x10000000000000000
            cpu.r[rd] = val1 if s1 > s2 else val2
        elif opcode == 0x0F:  # min
            s1 = val1 if (val1 >> 63) == 0 else val1 - 0x10000000000000000
            s2 = val2 if (val2 >> 63) == 0 else val2 - 0x10000000000000000
            cpu.r[rd] = val1 if s1 < s2 else val2
        elif opcode == 0x10:  # ror
            shift = val2 & 0x3F
            result = ((val1 >> shift) | (val1 << (64 - shift))) & 0xFFFFFFFFFFFFFFFF
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x11:  # rol
            shift = val2 & 0x3F
            result = ((val1 << shift) | (val1 >> (64 - shift))) & 0xFFFFFFFFFFFFFFFF
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x12:  # clz
            result = 0
            v = val1
            for i in range(63, -1, -1):
                if (v >> i) & 1:
                    break
                result += 1
            cpu.r[rd] = result

        cpu.pc += length
        cpu.r[0] = 0  # R0 is hardwired to zero
        cpu.steps += 1
        return True

    # ---- I-type (4 bytes) ----
    if 0x20 <= opcode <= 0x29:
        byte1 = cpu.read_byte(pc + 1)
        byte2 = cpu.read_byte(pc + 2)
        byte3 = cpu.read_byte(pc + 3)
        rd = (byte1 >> 3) & 0x1F
        rs1 = ((byte1 & 0x7) << 2) | ((byte2 >> 6) & 0x3)
        imm = (((byte2 & 0x3F) << 8) | byte3)
        imm = sign_extend_64(imm, 14)

        if opcode == 0x20:  # addi
            result = (cpu.r[rs1] + imm) & 0xFFFFFFFFFFFFFFFF
            set_flags_arith(cpu, result, cpu.r[rs1], imm)
            cpu.r[rd] = result
        elif opcode == 0x21:  # subi
            result = (cpu.r[rs1] - imm) & 0xFFFFFFFFFFFFFFFF
            set_flags_arith(cpu, result, cpu.r[rs1], imm, True)
            cpu.r[rd] = result
        elif opcode == 0x22:  # muli
            result = (cpu.r[rs1] * imm) & 0xFFFFFFFFFFFFFFFF
            set_flags_arith(cpu, result, cpu.r[rs1], imm)
            cpu.r[rd] = result
        elif opcode == 0x23:  # andi
            result = cpu.r[rs1] & (imm & 0xFFFF)
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x24:  # ori
            result = cpu.r[rs1] | (imm & 0xFFFF)
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x25:  # xori
            result = cpu.r[rs1] ^ (imm & 0xFFFF)
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x26:  # shli
            result = (cpu.r[rs1] << (imm & 0x3F)) & 0xFFFFFFFFFFFFFFFF
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x27:  # shri
            result = cpu.r[rs1] >> (imm & 0x3F)
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x28:  # sari
            shift = imm & 0x3F
            result = cpu.r[rs1] >> shift
            if cpu.r[rs1] & 0x8000000000000000:
                result |= ((-1 << (64 - shift)) & 0xFFFFFFFFFFFFFFFF)
            set_flags_logical(cpu, result)
            cpu.r[rd] = result
        elif opcode == 0x29:  # mov
            cpu.r[rd] = sign_extend_64(imm, 14)
            set_flags_logical(cpu, cpu.r[rd])

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- movi (6-byte) ----
    if opcode == 0x2A:
        byte1 = cpu.read_byte(pc + 1)
        rd = (byte1 >> 3) & 0x1F
        imm = cpu.read_u32(pc + 2)
        cpu.r[rd] = imm
        set_flags_logical(cpu, imm)
        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- L-type 4-byte ----
    if 0x40 <= opcode <= 0x46:
        byte1 = cpu.read_byte(pc + 1)
        rd = (byte1 >> 4) & 0xF
        rs1 = byte1 & 0xF
        off = cpu.read_i16(pc + 2)
        addr = (cpu.r[rs1] + off) & 0xFFFFFFFFFFFFFFFF

        if opcode == 0x40:  # ld
            cpu.r[rd] = cpu.read_mem(addr, 8)
        elif opcode == 0x41:  # ldu
            cpu.r[rd] = cpu.read_mem(addr, 4)
        elif opcode == 0x42:  # lds
            cpu.r[rd] = cpu.read_mem(addr, 4, signed=True)
        elif opcode == 0x43:  # st
            cpu.write_mem(addr, 8, cpu.r[rd])
        elif opcode == 0x44:  # stw
            cpu.write_mem(addr, 4, cpu.r[rd] & 0xFFFFFFFF)
        elif opcode == 0x45:  # stb
            cpu.write_mem(addr, 1, cpu.r[rd] & 0xFF)
        elif opcode == 0x46:  # lda
            extra = cpu.read_u16(pc + 2)
            rs2 = (extra >> 2) & 0xF
            scale_bits = extra & 0x3
            scale = 1 << scale_bits
            cpu.r[rd] = (cpu.r[rs1] + cpu.r[rs2] * scale) & 0xFFFFFFFFFFFFFFFF

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- L-type 6-byte indexed ----
    if 0x50 <= opcode <= 0x51:
        byte1 = cpu.read_byte(pc + 1)
        rd = (byte1 >> 4) & 0xF
        rs1 = byte1 & 0xF
        off = cpu.read_i16(pc + 2)
        extra = cpu.read_u16(pc + 4)
        rn = (extra >> 2) & 0xF
        scale_bits = extra & 0x3
        scale = 1 << scale_bits
        addr = (cpu.r[rs1] + cpu.r[rn] * scale + off) & 0xFFFFFFFFFFFFFFFF

        if opcode == 0x50:  # ldr
            cpu.r[rd] = cpu.read_mem(addr, 8)
        elif opcode == 0x51:  # str
            cpu.write_mem(addr, 8, cpu.r[rd])

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- B-type ----
    if 0x60 <= opcode <= 0x6C:
        byte1 = cpu.read_byte(pc + 1)

        if opcode == 0x62:  # ret
            cpu.pc = cpu.r[31]
            cpu.r[0] = 0
            cpu.steps += 1
            return True

        if opcode == 0x60:  # j
            imm_hi = byte1 & 0xFF
            imm_mid = cpu.read_byte(pc + 2)
            imm_lo = cpu.read_byte(pc + 3)
            imm20 = (imm_hi << 16) | (imm_mid << 8) | imm_lo
            imm20 = sign_extend_64(imm20, 20)
            cpu.pc = (pc + (imm20 << 2)) & 0xFFFFFFFFFFFFFFFF
            cpu.r[0] = 0
            cpu.steps += 1
            return True

        if opcode == 0x61:  # call
            imm_hi = byte1 & 0xFF
            imm_mid = cpu.read_byte(pc + 2)
            imm_lo = cpu.read_byte(pc + 3)
            imm20 = (imm_hi << 16) | (imm_mid << 8) | imm_lo
            imm20 = sign_extend_64(imm20, 20)
            cpu.r[31] = pc + 4
            cpu.pc = (pc + (imm20 << 2)) & 0xFFFFFFFFFFFFFFFF
            cpu.r[0] = 0
            cpu.steps += 1
            return True

        if opcode == 0x6B:  # jreg
            rs1 = (byte1 >> 4) & 0xF
            cpu.pc = cpu.r[rs1]
            cpu.r[0] = 0
            cpu.steps += 1
            return True

        if opcode == 0x6C:  # callreg
            rs1 = (byte1 >> 4) & 0xF
            cpu.r[31] = pc + 4
            cpu.pc = cpu.r[rs1]
            cpu.r[0] = 0
            cpu.steps += 1
            return True

        # Conditional branches
        rs1 = (byte1 >> 4) & 0xF
        rs2 = byte1 & 0xF
        imm_hi = cpu.read_byte(pc + 2)
        imm_lo = cpu.read_byte(pc + 3)
        imm12 = (imm_hi << 8) | imm_lo
        imm12 = sign_extend_64(imm12, 12)
        target = (pc + (imm12 << 2)) & 0xFFFFFFFFFFFFFFFF

        taken = False
        v1 = cpu.r[rs1]
        v2 = cpu.r[rs2]

        if opcode == 0x63:  # beq
            taken = v1 == v2
        elif opcode == 0x64:  # bne
            taken = v1 != v2
        elif opcode == 0x65:  # blt
            s1 = v1 if (v1 >> 63) == 0 else v1 - 0x10000000000000000
            s2 = v2 if (v2 >> 63) == 0 else v2 - 0x10000000000000000
            taken = s1 < s2
        elif opcode == 0x66:  # ble
            s1 = v1 if (v1 >> 63) == 0 else v1 - 0x10000000000000000
            s2 = v2 if (v2 >> 63) == 0 else v2 - 0x10000000000000000
            taken = s1 <= s2
        elif opcode == 0x67:  # bgt
            s1 = v1 if (v1 >> 63) == 0 else v1 - 0x10000000000000000
            s2 = v2 if (v2 >> 63) == 0 else v2 - 0x10000000000000000
            taken = s1 > s2
        elif opcode == 0x68:  # bge
            s1 = v1 if (v1 >> 63) == 0 else v1 - 0x10000000000000000
            s2 = v2 if (v2 >> 63) == 0 else v2 - 0x10000000000000000
            taken = s1 >= s2
        elif opcode == 0x69:  # bltu
            taken = v1 < v2
        elif opcode == 0x6A:  # bgeu
            taken = v1 >= v2

        if taken:
            cpu.pc = target
        else:
            cpu.pc = pc + length

        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- V-type ----
    if (opcode & 0xF0) == 0x80:
        byte1 = cpu.read_byte(pc + 1)
        vd = opcode & 0xF
        vs1 = (byte1 >> 4) & 0xF
        vs2 = byte1 & 0xF
        funct = cpu.read_byte(pc + 2)
        aux = cpu.read_byte(pc + 3)
        ext = cpu.read_u16(pc + 4)

        if funct == 0x00:  # vadd
            cpu.v[vd] = (cpu.v[vs1] + cpu.v[vs2]) & 0xFFFFFFFFFFFFFFFF
        elif funct == 0x01:  # vsub
            cpu.v[vd] = (cpu.v[vs1] - cpu.v[vs2]) & 0xFFFFFFFFFFFFFFFF
        elif funct == 0x02:  # vmul
            cpu.v[vd] = (cpu.v[vs1] * cpu.v[vs2]) & 0xFFFFFFFFFFFFFFFF
        elif funct == 0x03:  # vand
            cpu.v[vd] = cpu.v[vs1] & cpu.v[vs2]
        elif funct == 0x04:  # vor
            cpu.v[vd] = cpu.v[vs1] | cpu.v[vs2]
        elif funct == 0x05:  # vxor
            cpu.v[vd] = cpu.v[vs1] ^ cpu.v[vs2]
        elif funct == 0x06:  # vld
            off = sign_extend_64(ext, 16)
            addr = (cpu.r[vs1] + off) & 0xFFFFFFFFFFFFFFFF
            cpu.v[vd] = cpu.read_mem(addr, 8)
        elif funct == 0x07:  # vst
            off = sign_extend_64(ext, 16)
            addr = (cpu.r[vs1] + off) & 0xFFFFFFFFFFFFFFFF
            cpu.write_mem(addr, 8, cpu.v[vd])
        elif funct == 0x08:  # vshl
            cpu.v[vd] = (cpu.v[vs1] << (vs2 & 0x1F)) & 0xFFFFFFFFFFFFFFFF
        elif funct == 0x09:  # vshr
            cpu.v[vd] = cpu.v[vs1] >> (vs2 & 0x1F)
        elif funct == 0x0A:  # vshuffle
            cpu.v[vd] = cpu.v[vs1]  # simplified
        elif funct == 0x0B:  # vfmadd
            vs3 = ext & 0xF
            cpu.v[vd] = (cpu.v[vs1] * cpu.v[vs2] + cpu.v[vs3]) & 0xFFFFFFFFFFFFFFFF

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- F-type (Scalar FP) ----
    if (opcode & 0xF0) == 0xA0:
        byte1 = cpu.read_byte(pc + 1)
        fd = opcode & 0xF
        fs1 = (byte1 >> 4) & 0xF
        fs2 = byte1 & 0xF
        funct = cpu.read_byte(pc + 2)
        aux = cpu.read_byte(pc + 3)

        if funct in (0x00, 0x01, 0x02, 0x03, 0x08, 0x09):
            # fadd, fsub, fmul, fdiv, fmin, fmax — two-source
            fp_execute_f(cpu, fd, fs1, fs2, funct, aux)
        elif funct == 0x04:  # fsqrt
            fp_execute_f(cpu, fd, fs1, 0, funct, aux)
        elif funct == 0x05:  # fcmp
            fp_compare(cpu, fs1, fs2, aux)
        elif funct == 0x06:  # fcvt.w.s: float→int
            fp_execute_f(cpu, fd, fs1, 0, funct, aux)
        elif funct == 0x07:  # fcvt.s.w: int→float
            fp_execute_f(cpu, fd, fs1, 0, funct, aux)
        elif funct == 0x0A:  # fneg
            fp_unary(cpu, fd, fs1, aux, negate=True)
        elif funct == 0x0B:  # fabs
            fp_unary(cpu, fd, fs1, aux, negate=False)
        elif funct == 0x0C:  # fld: load from memory into F register
            off = cpu.read_i16(pc + 4)
            addr = (cpu.r[fs1] + off) & 0xFFFFFFFFFFFFFFFF
            cpu.f[fd] = cpu.read_mem(addr, 8)
        elif funct == 0x0D:  # fst: store F register to memory
            off = cpu.read_i16(pc + 4)
            addr = (cpu.r[fs1] + off) & 0xFFFFFFFFFFFFFFFF
            cpu.write_mem(addr, 8, cpu.f[fd])

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- C-type ----
    if 0x90 <= opcode <= 0x97:
        byte1 = cpu.read_byte(pc + 1)
        rd = opcode & 0xF
        rs1 = (byte1 >> 4) & 0xF
        rs2 = byte1 & 0xF

        if opcode == 0x90:  # addm
            off = cpu.read_i16(pc + 2)
            addr = (cpu.r[rs2] + off) & 0xFFFFFFFFFFFFFFFF
            val = cpu.read_mem(addr, 8)
            cpu.write_mem(addr, 8, (val + cpu.r[rd]) & 0xFFFFFFFFFFFFFFFF)
        elif opcode == 0x91:  # subm
            off = cpu.read_i16(pc + 2)
            addr = (cpu.r[rs2] + off) & 0xFFFFFFFFFFFFFFFF
            val = cpu.read_mem(addr, 8)
            cpu.write_mem(addr, 8, (val - cpu.r[rd]) & 0xFFFFFFFFFFFFFFFF)
        elif opcode == 0x92:  # xchg
            off = cpu.read_i16(pc + 2)
            addr = (cpu.r[rs2] + off) & 0xFFFFFFFFFFFFFFFF
            val = cpu.read_mem(addr, 8)
            cpu.write_mem(addr, 8, cpu.r[rd])
            cpu.r[rd] = val
        elif opcode == 0x93:  # cmpxchg
            off = cpu.read_i16(pc + 2)
            base = cpu.read_u16(pc + 4) & 0xF
            addr = (cpu.r[base] + off) & 0xFFFFFFFFFFFFFFFF
            val = cpu.read_mem(addr, 8)
            if val == cpu.r[rd]:
                cpu.write_mem(addr, 8, cpu.r[rs2])
        elif opcode == 0x94:  # push
            cpu.r[2] = (cpu.r[2] - 8) & 0xFFFFFFFFFFFFFFFF
            cpu.write_mem(cpu.r[2], 8, cpu.r[rd])
        elif opcode == 0x95:  # pop
            cpu.r[rd] = cpu.read_mem(cpu.r[2], 8)
            cpu.r[2] = (cpu.r[2] + 8) & 0xFFFFFFFFFFFFFFFF
        elif opcode == 0x96:  # enter
            imm = cpu.read_i16(pc + 2)
            cpu.r[2] = (cpu.r[2] - imm) & 0xFFFFFFFFFFFFFFFF
            cpu.write_mem(cpu.r[2], 8, cpu.r[30])
        elif opcode == 0x97:  # leave
            cpu.r[2] = (cpu.r[30] + 8) & 0xFFFFFFFFFFFFFFFF
            cpu.r[30] = cpu.read_mem((cpu.r[2] - 8) & 0xFFFFFFFFFFFFFFFF, 8)

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- System 2-byte ----
    if opcode in (0xB0, 0xB1, 0xB2, 0xB3, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD):
        imm8 = cpu.read_byte(pc + 1)

        if opcode == 0xB0:  # syscall
            syscall_handler(cpu, imm8)
            if cpu.halted:
                cpu.pc += length
                cpu.r[0] = 0
                cpu.steps += 1
                return False
        elif opcode == 0xB1:  # sysret
            cpu.priv = 1
            cpu.pc = cpu.err
        elif opcode == 0xB2:  # int
            raise_exception(cpu, imm8)
        elif opcode == 0xB3:  # iret
            cpu.pc = cpu.err
            cpu.priv = 1
        elif opcode == 0xB6:  # cpuid
            cpu.r[0] = 0x4D43584D  # "MCXM"
            cpu.r[1] = 0x00020000  # version 2.0
            cpu.r[2] = 0x00000000  # features
            cpu.r[3] = 0x00000001  # cache info
        elif opcode == 0xB7:  # hlt
            cpu.halted = True
            cpu.pc += length
            cpu.r[0] = 0
            cpu.steps += 1
            return False
        elif opcode == 0xB8:  # cli
            cpu.iflag = 0
        elif opcode == 0xB9:  # sti
            cpu.iflag = 1
        elif opcode == 0xBA:  # nop
            pass
        elif opcode == 0xBB:  # ecall
            # Environment call - used as exit in our simulator
            print(f"\n[ecall] exit code: {imm8}")
            cpu.pc += length
            cpu.r[0] = 0
            cpu.steps += 1
            return False
        elif opcode == 0xBC:  # fence
            # Memory fence — no-op in single-core simulator
            pass
        elif opcode == 0xBD:  # bkpt
            # Hardware breakpoint — halt or enter debug mode
            print(f"\n[bkpt] breakpoint {imm8} at PC=0x{cpu.pc:x}")
            cpu.pc += length
            cpu.r[0] = 0
            cpu.steps += 1
            return False

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # ---- System 4-byte ----
    if opcode in (0xB4, 0xB5):
        byte1 = cpu.read_byte(pc + 1)
        rs1 = (byte1 >> 4) & 0xF
        imm_hi = byte1 & 0xF
        imm_lo = cpu.read_byte(pc + 2)
        imm12 = (imm_hi << 8) | imm_lo

        if opcode == 0xA4:  # rdmsr
            cpu.r[rs1] = 0  # simplified
        elif opcode == 0xA5:  # wrmsr
            pass  # simplified

        cpu.pc += length
        cpu.r[0] = 0
        cpu.steps += 1
        return True

    # Unknown opcode
    raise_exception(cpu, 0x01)  # Illegal instruction
    return True


def raise_exception(cpu: CPU, vector: int):
    """Handle exception."""
    cpu.err = cpu.pc
    # Save flags
    ef = (cpu.cf) | (cpu.zf << 1) | (cpu.sf << 2) | (cpu.of << 3)
    cpu.ef = ef
    cpu.priv = 0
    # Jump to exception handler at vector table (simplified: at 0x1000)
    cpu.pc = 0x1000 + vector * 8


def syscall_handler(cpu: CPU, imm8: int):
    """Handle syscall."""
    syscall_num = cpu.r[1]  # syscall number in R1
    if syscall_num == 0:  # exit
        print(f"\n[syscall] exit({cpu.r[2]})")
        cpu.halted = True
        return
    elif syscall_num == 1:  # write
        fd = cpu.r[2]
        buf = cpu.r[3]
        count = cpu.r[4]
        if fd == 1:  # stdout
            data = bytes(cpu.mem[buf:buf+count])
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
            cpu.r[1] = count
    elif syscall_num == 2:  # print integer
        val = cpu.r[2]
        print(val, end='')
        cpu.r[1] = 0
    else:
        cpu.r[1] = -1  # unsupported


# =============================================================================
# Simulator Main
# =============================================================================

def load_binary(cpu: CPU, path: str, base_addr: int = 0x1000):
    """Load binary file into memory."""
    with open(path, 'rb') as f:
        data = f.read()
    cpu.mem[base_addr:base_addr + len(data)] = data
    cpu.pc = base_addr
    # Set up stack pointer (R2) at top of memory
    cpu.r[2] = cpu.mem_size - 0x1000
    # Set up frame pointer (R30)
    cpu.r[30] = cpu.r[2]


def simulate(cpu: CPU, max_steps: int = 0, trace: bool = False):
    """Run simulation."""
    if trace:
        print(f"\n{'='*60}")
        print(f"  MacroCore-X Simulator Trace")
        print(f"{'='*60}")
        print(f"  PC    : 0x{cpu.pc:04x}")
        print(f"  SP (R2): 0x{cpu.r[2]:016x}")
        print(f"  FP (R30): 0x{cpu.r[30]:016x}")
        print(f"{'='*60}\n")

    while not cpu.halted:
        if max_steps > 0 and cpu.steps >= max_steps:
            print(f"\n[sim] max steps ({max_steps}) reached")
            break

        if cpu.pc < 0 or cpu.pc >= cpu.mem_size:
            print(f"\n[sim] PC out of bounds: 0x{cpu.pc:x}")
            break

        try:
            cont = execute_one(cpu, trace)
            if not cont:
                break
        except Exception as e:
            print(f"\n[sim] Exception at PC=0x{cpu.pc:x}: {e}")
            break

    # Print final state
    print(f"\n{'='*60}")
    print(f"  Simulation Complete — {cpu.steps} steps")
    print(f"{'='*60}")
    print(f"  Registers:")
    for i in range(0, 32, 4):
        regs = '  '.join(f"R{i+j:2d}=0x{cpu.r[i+j]:016x}" for j in range(4))
        print(f"  {regs}")
    print(f"  Flags: CF={cpu.cf} ZF={cpu.zf} SF={cpu.sf} OF={cpu.of}")
    print(f"  F-Registers:")
    for i in range(0, 32, 4):
        fregs = '  '.join(f"F{i+j:2d}=0x{cpu.f[i+j]:016x}" for j in range(4))
        print(f"  {fregs}")
    print(f"{'='*60}")


def disassemble_binary(path: str, base_addr: int = 0x1000):
    """Disassemble a binary file."""
    with open(path, 'rb') as f:
        data = f.read()

    cpu = CPU()
    cpu.mem[base_addr:base_addr + len(data)] = data
    pc = base_addr
    end = base_addr + len(data)

    print(f"\n{'='*60}")
    print(f"  MacroCore-X Disassembly")
    print(f"{'='*60}")
    print(f"  File: {path}")
    print(f"  Size: {len(data)} bytes")
    print(f"{'='*60}\n")

    while pc < end:
        try:
            disasm, length = disassemble_one(cpu, pc)
            bytes_hex = ' '.join(f'{cpu.mem[pc+i]:02x}' for i in range(min(length, end - pc)))
            print(f"  {pc:04x}: {bytes_hex:<20s} {disasm}")
            pc += length
        except Exception as e:
            print(f"  {pc:04x}: <error: {e}>")
            break


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 simulator.py program.bin         # execute")
        print("  python3 simulator.py program.bin -d      # execute with trace")
        print("  python3 simulator.py program.bin -s N    # max N steps")
        print("  python3 simulator.py program.bin --dis   # disassemble only")
        sys.exit(1)

    path = sys.argv[1]
    trace = '-d' in sys.argv
    dis_only = '--dis' in sys.argv
    max_steps = 0

    if '-s' in sys.argv:
        idx = sys.argv.index('-s')
        max_steps = int(sys.argv[idx + 1])

    if dis_only:
        disassemble_binary(path)
    else:
        cpu = CPU()
        load_binary(cpu, path)
        simulate(cpu, max_steps=max_steps, trace=trace)