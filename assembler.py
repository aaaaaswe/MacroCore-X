#!/usr/bin/env python3
"""
MacroCore-X Assembler v1.0
Converts MacroCore-X assembly source to binary machine code.

Usage:
    python3 assembler.py input.asm -o output.bin
    python3 assembler.py input.asm          # outputs to input.bin
"""

import sys
import struct
import re
from dataclasses import dataclass
from typing import List, Tuple, Optional, Dict


# =============================================================================
# Token & AST
# =============================================================================

@dataclass
class Token:
    type: str        # 'label', 'mnemonic', 'reg', 'vreg', 'imm', 'mem', 'comma', 'eol'
    value: str
    line: int

@dataclass
class Instruction:
    mnemonic: str
    operands: List[str]
    line: int
    label: Optional[str] = None


# =============================================================================
# Opcode Tables
# =============================================================================

# R-type: 2 bytes, byte0 = opcode, byte1 = (Rs1<<4)|Rs2
R_TYPE = {
    'add': 0x00, 'sub': 0x01, 'mul': 0x02, 'div': 0x03, 'divu': 0x04,
    'and': 0x05, 'or': 0x06, 'xor': 0x07, 'shl': 0x08, 'shr': 0x09,
    'sar': 0x0A, 'eq': 0x0B, 'lt': 0x0C, 'ltu': 0x0D, 'max': 0x0E,
    'min': 0x0F, 'ror': 0x10, 'rol': 0x11, 'clz': 0x12,
}

# I-type: 4 bytes, byte0 = 0x40 | (opcode - 0x20), byte1 = packed, byte2-3 = imm16 LE
I_TYPE = {
    'addi': 0x20, 'subi': 0x21, 'muli': 0x22, 'andi': 0x23, 'ori': 0x24,
    'xori': 0x25, 'shli': 0x26, 'shri': 0x27, 'sari': 0x28, 'mov': 0x29,
    'movi': 0x2A,
}

# L-type: 4 bytes, byte0 = opcode, byte1 = (Rs1<<4)|(SZ<<2)|X, byte2-3 = off16 LE
L_TYPE_4 = {
    'ld': 0x40, 'ldu': 0x41, 'lds': 0x42, 'st': 0x43, 'stw': 0x44,
    'stb': 0x45, 'lda': 0x46,
}

# L-type indexed: 6 bytes, additional byte4-5 = (Rn<<14)|(scale<<12) as LE16
L_TYPE_6 = {
    'ldr': 0x50, 'str': 0x51,
}

# B-type: 4 bytes, byte0 = opcode, byte1 = (Rs2<<4)|imm_high, byte2-3 = imm LE
B_TYPE = {
    'j': 0x60, 'call': 0x61, 'ret': 0x62, 'beq': 0x63, 'bne': 0x64,
    'blt': 0x65, 'ble': 0x66, 'bgt': 0x67, 'bge': 0x68, 'bltu': 0x69,
    'bgeu': 0x6A, 'jreg': 0x6B, 'callreg': 0x6C,
}

# V-type: 6 bytes, byte0 = opcode, byte1 = (Vs1<<4)|Vs2, byte2-3 = imm16, byte4-5 = 0
V_TYPE = {
    'vadd': 0x80, 'vsub': 0x81, 'vmul': 0x82, 'vand': 0x83, 'vor': 0x84,
    'vxor': 0x85, 'vld': 0x86, 'vst': 0x87, 'vshl': 0x88, 'vshr': 0x89,
    'vshuffle': 0x8A, 'vfmadd': 0x8B,
}

# C-type: 6 bytes, byte0 = opcode, byte1-5 = varies
C_TYPE = {
    'addm': 0x90, 'subm': 0x91, 'xchg': 0x92, 'cmpxchg': 0x93,
    'push': 0x94, 'pop': 0x95, 'enter': 0x96, 'leave': 0x97,
}

# System: 2 or 4 bytes
SYS_TYPE_2 = {
    'syscall': 0xA0, 'sysret': 0xA1, 'int': 0xA2, 'iret': 0xA3,
    'cpuid': 0xA6, 'hlt': 0xA7, 'cli': 0xA8, 'sti': 0xA9,
    'nop': 0xAA, 'ecall': 0xAB,
}

SYS_TYPE_4 = {
    'rdmsr': 0xA4, 'wrmsr': 0xA5,
}

# Pseudo-instructions
PSEUDO = {
    'li': None,   # expands to mov or movi
    'la': None,   # expands to lda
}


# =============================================================================
# Lexer
# =============================================================================

def tokenize(source: str) -> List[Token]:
    tokens = []
    for line_no, raw_line in enumerate(source.split('\n'), 1):
        # Remove comments
        line = raw_line.split('#')[0].strip()
        if not line:
            tokens.append(Token('eol', '', line_no))
            continue

        # Check for label
        if ':' in line:
            label_part, _, rest = line.partition(':')
            tokens.append(Token('label', label_part.strip(), line_no))
            line = rest.strip()
            if not line:
                tokens.append(Token('eol', '', line_no))
                continue

        # Split into parts
        parts = re.findall(r'[\[\],+\-]|\w+\.?\w*|0x[0-9a-fA-F]+|\d+', line)
        for part in parts:
            if part == ',':
                tokens.append(Token('comma', ',', line_no))
            elif part == '[':
                tokens.append(Token('mem', '[', line_no))
            elif part == ']':
                tokens.append(Token('mem', ']', line_no))
            elif part == '+':
                tokens.append(Token('mem', '+', line_no))
            elif part == '-':
                tokens.append(Token('mem', '-', line_no))
            elif part.startswith('r') or part.startswith('R'):
                tokens.append(Token('reg', part.lower(), line_no))
            elif part.startswith('v') or part.startswith('V'):
                tokens.append(Token('vreg', part.lower(), line_no))
            elif part.startswith('0x') or part.startswith('-0x') or part.lstrip('-').isdigit():
                tokens.append(Token('imm', part, line_no))
            else:
                tokens.append(Token('mnemonic', part.lower(), line_no))
        tokens.append(Token('eol', '', line_no))
    return tokens


# =============================================================================
# Parser
# =============================================================================

def parse(tokens: List[Token]) -> List[Instruction]:
    instructions = []
    current_label = None
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t.type == 'label':
            current_label = t.value
            i += 1
            continue
        if t.type == 'mnemonic':
            mnemonic = t.value
            operands = []
            i += 1
            while i < len(tokens) and tokens[i].type != 'eol':
                if tokens[i].type == 'comma':
                    i += 1
                    continue
                if tokens[i].type == 'mem':
                    # Handle standalone '-' as negative sign for immediate
                    if tokens[i].value == '-' and i + 1 < len(tokens) and tokens[i + 1].type == 'imm':
                        operands.append('-' + tokens[i + 1].value)
                        i += 2
                        continue
                    # Collect memory operand: [reg + offset] or [reg + reg*scale + offset]
                    mem_parts = []
                    i += 1
                    while i < len(tokens) and tokens[i].type != 'eol':
                        if tokens[i].value == ']':
                            i += 1
                            break
                        mem_parts.append(tokens[i].value)
                        i += 1
                    operands.append('[' + ' '.join(mem_parts) + ']')
                else:
                    operands.append(tokens[i].value)
                    i += 1
            instructions.append(Instruction(
                mnemonic=mnemonic,
                operands=operands,
                line=t.line,
                label=current_label
            ))
            current_label = None
        i += 1
    return instructions


# =============================================================================
# Helpers
# =============================================================================

def parse_reg(s: str) -> int:
    """Parse r0-r31 → 0-31"""
    return int(s[1:])

def parse_vreg(s: str) -> int:
    """Parse v0-v31 → 0-31"""
    return int(s[1:])

def parse_imm(s: str) -> int:
    """Parse immediate value, supports hex and decimal"""
    s = s.strip()
    if s.startswith('0x') or s.startswith('-0x'):
        val = int(s, 16)
    else:
        val = int(s)
    return val & 0xFFFFFFFFFFFFFFFF  # 64-bit mask

def sext(val: int, bits: int) -> int:
    """Sign-extend value to 64 bits"""
    sign_bit = 1 << (bits - 1)
    mask = (1 << bits) - 1
    val = val & mask
    if val & sign_bit:
        val = val | ((-1 << bits) & 0xFFFFFFFFFFFFFFFF)
    return val

def pack_i16(val: int) -> bytes:
    """Pack signed 16-bit value as little-endian bytes"""
    val = val & 0xFFFF
    if val >= 0x8000:
        val = val - 0x10000
    return struct.pack('<h', val)

def pack_u16(val: int) -> bytes:
    """Pack unsigned 16-bit value as little-endian bytes"""
    return struct.pack('<H', val & 0xFFFF)

def pack_u32(val: int) -> bytes:
    """Pack unsigned 32-bit value as little-endian bytes"""
    return struct.pack('<I', val & 0xFFFFFFFF)


# =============================================================================
# Memory Operand Parser
# =============================================================================

def parse_mem_operand(op: str) -> Tuple[int, int, int, int]:
    """
    Parse memory operand string.
    Returns (base_reg, offset, index_reg, scale)
    For [rs + off]: index_reg=0, scale=0
    For [rs + rn*scale + off]: all set
    """
    # Strip brackets
    inner = op.strip('[]').strip()
    base_reg = 0
    offset = 0
    index_reg = 0
    scale = 0

    # Split by + and -
    # Handle cases like "r2 + 0x8" or "r2 + r3*4 + 0x10"
    parts = re.split(r'\s*([+-])\s*', inner)
    # parts will be like ['r2', '+', '0x8'] or ['r2', '+', 'r3*4', '+', '0x10']

    sign = 1
    i = 0
    while i < len(parts):
        part = parts[i].strip()
        if not part:
            i += 1
            continue
        if part == '+':
            sign = 1
            i += 1
            continue
        elif part == '-':
            sign = -1
            i += 1
            continue

        if '*' in part:
            # index register with scale
            reg_part, scale_part = part.split('*')
            index_reg = parse_reg(reg_part.strip())
            scale = int(scale_part.strip())
        elif part.startswith('r') or part.startswith('R'):
            if base_reg == 0:
                base_reg = parse_reg(part)
            else:
                index_reg = parse_reg(part)
        elif part.startswith('0x') or part.lstrip('-').isdigit():
            offset = sign * parse_imm(part)
        i += 1

    return base_reg, offset, index_reg, scale


# =============================================================================
# Assembler Core
# =============================================================================

class Assembler:
    def __init__(self):
        self.labels: Dict[str, int] = {}     # label → offset
        self.pending: List[Tuple[str, int, str]] = []  # (label, offset, type)
        self.output: bytearray = bytearray()
        self.offset = 0

    def assemble(self, instructions: List[Instruction]) -> bytes:
        # Pass 1: collect labels and emit code
        for inst in instructions:
            if inst.label:
                self.labels[inst.label] = self.offset
            self._emit_instruction(inst)

        # Pass 2: resolve pending label references
        for label, patch_offset, inst_type in self.pending:
            if label not in self.labels:
                raise ValueError(f"Undefined label: {label}")
            target = self.labels[label]
            if inst_type == 'b12':
                # 12-bit branch offset: patch at byte2-3
                # patch_offset = offset of byte2 in output
                pc = patch_offset - 2  # PC of the instruction
                imm12 = (target - pc) >> 2
                imm12 = sext(imm12, 12)
                self.output[patch_offset] = (imm12 >> 8) & 0xFF
                self.output[patch_offset + 1] = imm12 & 0xFF
            elif inst_type == 'b20':
                # 20-bit jump offset: patch at byte1-3
                pc = patch_offset - 1  # PC of the instruction
                imm20 = (target - pc) >> 2
                imm20 = sext(imm20, 20)
                self.output[patch_offset] = (imm20 >> 16) & 0xFF
                self.output[patch_offset + 1] = (imm20 >> 8) & 0xFF
                self.output[patch_offset + 2] = imm20 & 0xFF

        return bytes(self.output)

    def _emit_instruction(self, inst: Instruction):
        mnemonic = inst.mnemonic
        ops = inst.operands

        if mnemonic in R_TYPE:
            self._emit_r(mnemonic, ops)
        elif mnemonic in I_TYPE:
            self._emit_i(mnemonic, ops)
        elif mnemonic in L_TYPE_4:
            self._emit_l4(mnemonic, ops)
        elif mnemonic in L_TYPE_6:
            self._emit_l6(mnemonic, ops)
        elif mnemonic in B_TYPE:
            self._emit_b(mnemonic, ops, inst)
        elif mnemonic in V_TYPE:
            self._emit_v(mnemonic, ops)
        elif mnemonic in C_TYPE:
            self._emit_c(mnemonic, ops)
        elif mnemonic in SYS_TYPE_2:
            self._emit_sys2(mnemonic, ops)
        elif mnemonic in SYS_TYPE_4:
            self._emit_sys4(mnemonic, ops)
        elif mnemonic == 'li':
            self._emit_li(ops)
        elif mnemonic == 'la':
            self._emit_la(ops, inst)
        else:
            raise ValueError(f"Unknown mnemonic '{mnemonic}' at line {inst.line}")

    # ---- R-type ----
    def _emit_r(self, mnemonic, ops):
        if mnemonic == 'clz':
            # clz rs1  (1 operand)
            rs1 = parse_reg(ops[0])
            rs2 = 0
        else:
            rs1 = parse_reg(ops[0])
            rs2 = parse_reg(ops[1])
        opcode = R_TYPE[mnemonic]
        self.output.append(opcode)
        self.output.append((rs1 << 4) | rs2)
        self.offset += 2

    # ---- I-type ----
    def _emit_i(self, mnemonic, ops):
        opcode = I_TYPE[mnemonic]
        rd = parse_reg(ops[0])

        if mnemonic in ('shli', 'shri', 'sari'):
            rs1 = parse_reg(ops[1])
            imm = parse_imm(ops[2]) & 0x1F
        elif mnemonic == 'mov':
            rs1 = 0  # unused
            imm = parse_imm(ops[1])
        elif mnemonic == 'movi':
            # 6-byte I-type extension
            rd = parse_reg(ops[0])
            imm = parse_imm(ops[1])
            self._emit_movi(rd, imm)
            return
        else:
            rs1 = parse_reg(ops[1])
            imm = parse_imm(ops[2])

        # byte0 = opcode, byte1 = (rd << 4) | (rs1 & 0xF)
        self.output.append(opcode)
        self.output.append(((rd & 0xF) << 4) | (rs1 & 0xF))
        # byte2-3 = imm16 LE
        self.output.extend(pack_i16(imm))
        self.offset += 4

    def _emit_movi(self, rd, imm):
        """movi: 6-byte instruction for 32-bit immediate"""
        opcode = I_TYPE['movi']
        self.output.append(opcode)
        self.output.append(((rd & 0xF) << 4) | 0)  # rs1 unused
        self.output.extend(pack_u32(imm))
        self.offset += 6

    # ---- L-type 4-byte ----
    def _emit_l4(self, mnemonic, ops):
        opcode = L_TYPE_4[mnemonic]

        if mnemonic == 'lda':
            # lda Rd, Rs1, Rs2, scale
            rd = parse_reg(ops[0])
            rs1 = parse_reg(ops[1])
            rs2 = parse_reg(ops[2])
            scale = int(ops[3])
            scale_bits = {1: 0, 2: 1, 4: 2, 8: 3}[scale]
            self.output.append(opcode)
            self.output.append(((rd & 0xF) << 4) | (rs1 & 0xF))
            self.output.extend(pack_u16(((rs2 & 0xF) << 2) | scale_bits))
            self.offset += 4
            return

        # Parse memory operand
        if ops[0].startswith('[') or ops[0].startswith('r'):
            # st*, stw, stb: rs1, [rs2 + off]
            if mnemonic.startswith('st'):
                rs1 = parse_reg(ops[0])
                base, off, _, _ = parse_mem_operand(ops[1])
                rd = rs1  # source register stored in Rd field for stores
                rs1_field = base
            else:
                # ld, ldu, lds: rd, [rs1 + off]
                rd = parse_reg(ops[0])
                base, off, _, _ = parse_mem_operand(ops[1])
                rs1_field = base
        else:
            raise ValueError(f"Invalid operand format for {mnemonic}: {ops}")

        # SZ field
        sz = 3  # default 64-bit
        if mnemonic == 'stb':
            sz = 0  # 8-bit
        elif mnemonic == 'stw':
            sz = 2  # 32-bit
        elif mnemonic in ('ldu', 'lds'):
            sz = 2  # 32-bit

        self.output.append(opcode)
        self.output.append(((rd & 0xF) << 4) | (rs1_field & 0xF))
        self.output.extend(pack_i16(off))
        self.offset += 4

    # ---- L-type 6-byte indexed ----
    def _emit_l6(self, mnemonic, ops):
        opcode = L_TYPE_6[mnemonic]

        if mnemonic == 'ldr':
            rd = parse_reg(ops[0])
            base, off, idx_reg, scale = parse_mem_operand(ops[1])
            rs1_field = base
        else:  # str
            rs1 = parse_reg(ops[0])
            base, off, idx_reg, scale = parse_mem_operand(ops[1])
            rd = rs1
            rs1_field = base

        scale_bits = {1: 0, 2: 1, 4: 2, 8: 3}.get(scale, 0)

        self.output.append(opcode)
        self.output.append(((rd & 0xF) << 4) | (rs1_field & 0xF))
        self.output.extend(pack_i16(off))
        self.output.extend(pack_u16(((idx_reg & 0xF) << 2) | scale_bits))
        self.offset += 6

    # ---- B-type ----
    def _emit_b(self, mnemonic, ops, inst):
        opcode = B_TYPE[mnemonic]

        if mnemonic == 'ret':
            self.output.append(opcode)  # byte0 = opcode
            self.output.extend(b'\x00\x00\x00')
            self.offset += 4
            return

        if mnemonic in ('j', 'call'):
            # 20-bit immediate (target) - may be label or immediate
            target_str = ops[0]
            if target_str.startswith('0x') or target_str.lstrip('-').isdigit():
                target = parse_imm(target_str)
                pc = self.offset
                imm20 = (target - pc) >> 2
                imm20 = sext(imm20, 20)
                self.output.append(opcode)
                self.output.append((imm20 >> 16) & 0xFF)
                self.output.append((imm20 >> 8) & 0xFF)
                self.output.append(imm20 & 0xFF)
            else:
                # Label reference
                self.output.append(opcode)
                self.output.append(0)  # placeholder byte1
                self.output.append(0)  # placeholder byte2
                self.output.append(0)  # placeholder byte3
                self.pending.append((target_str, self.offset + 1, 'b20'))  # patch at byte1
            self.offset += 4
            return

        if mnemonic in ('jreg', 'callreg'):
            rs1 = parse_reg(ops[0])
            self.output.append(opcode)
            self.output.append((rs1 & 0xF) << 4)
            self.output.extend(b'\x00\x00')
            self.offset += 4
            return

        # Conditional branches: beq, bne, blt, ble, bgt, bge, bltu, bgeu
        rs1 = parse_reg(ops[0])
        rs2 = parse_reg(ops[1])
        target_str = ops[2]

        self.output.append(opcode)
        self.output.append(((rs1 & 0xF) << 4) | (rs2 & 0xF))

        if target_str.startswith('0x') or target_str.lstrip('-').isdigit():
            target = parse_imm(target_str)
            pc = self.offset
            imm12 = (target - pc) >> 2
            imm12 = sext(imm12, 12)
            self.output.append((imm12 >> 8) & 0xFF)
            self.output.append(imm12 & 0xFF)
        else:
            # Label reference
            self.output.append(0)  # placeholder byte2
            self.output.append(0)  # placeholder byte3
            self.pending.append((target_str, self.offset + 2, 'b12'))  # patch at byte2
        self.offset += 4

    # ---- V-type ----
    def _emit_v(self, mnemonic, ops):
        opcode = V_TYPE[mnemonic]

        if mnemonic in ('vld', 'vst'):
            # vld Vd, [Rs1 + off16] / vst Vd, [Rs1 + off16]
            vd = parse_vreg(ops[0])
            base, off, _, _ = parse_mem_operand(ops[1])
            vs1 = base
            vs2 = 0
            elem_width = 3  # 64-bit default
        elif mnemonic in ('vshl', 'vshr'):
            vd = parse_vreg(ops[0])
            vs1 = parse_vreg(ops[1])
            vs2 = parse_imm(ops[2]) & 0x1F
            elem_width = 0
        elif mnemonic == 'vshuffle':
            vd = parse_vreg(ops[0])
            vs1 = parse_vreg(ops[1])
            vs2 = parse_imm(ops[2]) & 0xFF
            elem_width = 0
        elif mnemonic == 'vfmadd':
            vd = parse_vreg(ops[0])
            vs1 = parse_vreg(ops[1])
            vs2 = parse_vreg(ops[2])
            vs3 = parse_vreg(ops[3])
            elem_width = 0
            self.output.append(opcode)
            self.output.append(((vs1 & 0xF) << 4) | vs2)
            self.output.extend(pack_u16(elem_width))
            self.output.extend(pack_u16(vs3))  # Vs3 in byte6-7
            self.offset += 8
            return
        else:
            vd = parse_vreg(ops[0])
            vs1 = parse_vreg(ops[1])
            vs2 = parse_vreg(ops[2])
            elem_width = 0

        self.output.append(opcode)
        self.output.append(((vs1 & 0xF) << 4) | (vs2 & 0xF))
        self.output.extend(pack_u16(elem_width))
        self.output.extend(b'\x00\x00')
        self.offset += 6

    # ---- C-type ----
    def _emit_c(self, mnemonic, ops):
        opcode = C_TYPE[mnemonic]

        if mnemonic in ('addm', 'subm'):
            rs1 = parse_reg(ops[0])
            base, off, _, _ = parse_mem_operand(ops[1])
            self.output.append(opcode)
            self.output.append(((rs1 & 0xF) << 4) | (base & 0xF))
            self.output.extend(pack_i16(off))
            self.output.extend(b'\x00\x00')
            self.offset += 6

        elif mnemonic == 'xchg':
            rs1 = parse_reg(ops[0])
            base, off, _, _ = parse_mem_operand(ops[1])
            self.output.append(opcode)
            self.output.append(((rs1 & 0xF) << 4) | (base & 0xF))
            self.output.extend(pack_i16(off))
            self.output.extend(b'\x00\x00')
            self.offset += 6

        elif mnemonic == 'cmpxchg':
            rs1 = parse_reg(ops[0])
            rs2 = parse_reg(ops[1])
            base, off, _, _ = parse_mem_operand(ops[2])
            self.output.append(opcode)
            self.output.append(((rs1 & 0xF) << 4) | (rs2 & 0xF))
            self.output.extend(pack_i16(off))
            self.output.extend(pack_u16(base & 0xF))
            self.offset += 6

        elif mnemonic in ('push', 'pop'):
            rs1 = parse_reg(ops[0])
            self.output.append(opcode)
            self.output.append(((rs1 & 0xF) << 4) | 0)
            self.output.extend(b'\x00\x00\x00\x00')
            self.offset += 6

        elif mnemonic == 'enter':
            imm = parse_imm(ops[0])
            self.output.append(opcode)
            self.output.append(0)
            self.output.extend(pack_i16(imm))
            self.output.extend(b'\x00\x00')
            self.offset += 6

        elif mnemonic == 'leave':
            self.output.append(opcode)
            self.output.extend(b'\x00\x00\x00\x00\x00')
            self.offset += 6

    # ---- System 2-byte ----
    def _emit_sys2(self, mnemonic, ops):
        opcode = SYS_TYPE_2[mnemonic]
        if ops and mnemonic in ('syscall', 'int', 'ecall'):
            imm8 = parse_imm(ops[0]) & 0xFF
            self.output.append(opcode)
            self.output.append(imm8)
        else:
            self.output.append(opcode)
            self.output.append(0)
        self.offset += 2

    # ---- System 4-byte ----
    def _emit_sys4(self, mnemonic, ops):
        opcode = SYS_TYPE_4[mnemonic]
        rs1 = parse_reg(ops[0])
        imm12 = parse_imm(ops[1]) & 0xFFF
        self.output.append(opcode)
        self.output.append(((rs1 & 0xF) << 4) | ((imm12 >> 8) & 0xF))
        self.output.append(imm12 & 0xFF)
        self.output.append(0)
        self.offset += 4

    # ---- Pseudo ----
    def _emit_li(self, ops):
        rd = parse_reg(ops[0])
        imm = parse_imm(ops[1])
        if -32768 <= imm <= 32767:
            self._emit_i('mov', [ops[0], ops[1]])
        else:
            self._emit_movi(rd, imm)

    def _emit_la(self, ops, inst):
        # la Rd, label → lda Rd, PC, 0, 1
        # This is a simplified version; label resolution would need a real linker
        rd = parse_reg(ops[0])
        target = parse_imm(ops[1])
        self._emit_l4('lda', [ops[0], 'r0', 'r0', '1'])


# =============================================================================
# Main
# =============================================================================

def assemble_file(input_path: str, output_path: str):
    with open(input_path, 'r') as f:
        source = f.read()

    tokens = tokenize(source)
    instructions = parse(tokens)
    assembler = Assembler()
    binary = assembler.assemble(instructions)

    with open(output_path, 'wb') as f:
        f.write(binary)

    print(f"Assembled {len(instructions)} instructions → {len(binary)} bytes")
    print(f"Output: {output_path}")

    # Print hex dump
    print("\nHex dump:")
    for i in range(0, len(binary), 16):
        chunk = binary[i:i+16]
        hex_str = ' '.join(f'{b:02x}' for b in chunk)
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        print(f"  {i:04x}: {hex_str:<48s} {ascii_str}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 assembler.py input.asm [-o output.bin]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = input_path.rsplit('.', 1)[0] + '.bin'

    if '-o' in sys.argv:
        idx = sys.argv.index('-o')
        output_path = sys.argv[idx + 1]

    assemble_file(input_path, output_path)