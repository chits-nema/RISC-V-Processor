# RISC-V Processor Implementation

A complete RISC-V processor implementation in Verilog, featuring both single-cycle and multicycle architectures. This project demonstrates fundamental computer architecture concepts including instruction execution, pipelining alternatives, and performance analysis.

## Features

- **Dual Architecture Implementation**
  - Single-cycle processor
  - Multicycle processor with FSM-based control
- **RV32I Base Instruction Set**
  - R-type: ADD, SUB, SLL, SRL, SRA, XOR, OR, AND, SLT, SLTU
  - I-type: ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU, LW
  - S-type: SW
  - B-type: BEQ, BNE
  - J-type: JAL
  - U-type: LUI
- **Comprehensive Testing**
  - 72 test instructions
  - 33 validation checks
  - Edge case coverage (overflow, underflow, x0 immutability, etc.)
  - CPI (Cycles Per Instruction) analysis

## Performance Metrics

### Multicycle Processor CPI Results

| Instruction Type | Count | Cycles | CPI |
|-----------------|-------|--------|-----|
| R-Type | 20 | 80 | 4.00 |
| I-Type Arithmetic | 30 | 120 | 4.00 |
| Load (LW) | 4 | 20 | 5.00 |
| Store (SW) | 4 | 16 | 4.00 |
| Branch | 7 | 18 | 2.57 |
| Jump (JAL) | 1 | 4 | 4.00 |
| Upper Immediate (LUI) | 6 | 24 | 4.00 |
| **Overall** | **72** | **282** | **3.92** |

## Project Structure

```
RISC-V-Processor/
├── Multicycle_Processor/
│   ├── alu.v                 # Arithmetic Logic Unit
│   ├── controller.v          # Multicycle control unit
│   ├── main_fsm.v            # Finite State Machine
│   ├── mem.v                 # Unified memory
│   ├── multiplexer.v         # Multiplexer components
│   ├── register_file.v       # Register file
│   ├── sign_extender.v       # Immediate sign extender
│   ├── rv_mc.v               # Top-level multicycle module
│   ├── rv_mc_tb.v            # Comprehensive testbench
│   ├── test_program.s        # Assembly test program
│   └── test_program.hex      # Machine code (hex format)
│
└── README.md
```

## Requirements

- **Verilog Simulator**: Icarus Verilog (iverilog)
- **Waveform Viewer**: GTKWave (optional, for debugging)
- **RISC-V Toolchain** (optional, for assembling custom programs)

## Getting Started

### Running the Multicycle Processor

```powershell
cd Multicycle_Processor
iverilog -o rv_mc_tb.vvp rv_mc_tb.v
vvp rv_mc_tb.vvp
```

### Running the Single-Cycle Processor

```powershell
cd Single_Processor
iverilog -o top_module_tb.vvp top_module_tb.v
vvp top_module_tb.vvp
```

### Viewing Waveforms

```powershell
gtkwave rv_mc_tb.vcd
```

## Testing

The testbench includes comprehensive tests for:

### Basic Functionality
- Arithmetic operations (ADD, SUB)
- Logical operations (AND, OR, XOR)
- Shift operations (SLL, SRL, SRA)
- Memory operations (LW, SW)
- Control flow (BEQ, BNE, JAL)

### Edge Cases
- x0 register immutability
- Arithmetic overflow/underflow
- Shift by 0 and maximum (31)
- Signed vs unsigned comparisons
- Load-after-store hazards
- Backward branches (loops)
- All-zeros and all-ones patterns

## Architecture Comparison

| Feature | Single-Cycle | Multicycle |
|---------|-------------|------------|
| **CPI** | 1.00 | 3.92 (average) |
| **Clock Period** | Longest instruction | Shortest state |
| **Hardware Complexity** | Higher (parallel paths) | Lower (reused components) |
| **Extensibility** | Harder (affects all instructions) | Easier (add FSM states) |
| **Performance** | Better for simple programs | Better for complex instructions |

## Key Design Decisions

### Multicycle Advantages
- **Flexible timing**: Complex instructions can take more cycles without slowing down simple ones
- **Hardware reuse**: ALU and memory are reused across cycles
- **Easier ISA extension**: New instructions add FSM states, not new hardware paths

### FSM States (Multicycle)
1. **FETCH**: Load instruction from memory
2. **DECODE**: Decode instruction and compute branch target
3. **EXECUTE**: Execute ALU operation or compute memory address
4. **MEMORY**: Access data memory (loads/stores)
5. **WRITEBACK**: Write results to register file

## Instruction Format Support

- **R-type**: `funct7 | rs2 | rs1 | funct3 | rd | opcode`
- **I-type**: `imm[11:0] | rs1 | funct3 | rd | opcode`
- **S-type**: `imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode`
- **B-type**: `imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode`
- **U-type**: `imm[31:12] | rd | opcode`
- **J-type**: `imm[20|10:1|11|19:12] | rd | opcode`

## Known Issues

- **BNE backward branch**: Loop counter shows incomplete execution (x22=1 instead of 3)
- **Memory addressing**: Limited to 12-bit word-aligned addresses

## References

- [RISC-V Instruction Set Manual](https://riscv.org/technical/specifications/)
- Patterson & Hennessy - *Computer Organization and Design: The Hardware/Software Interface*

## Contributing

This is an educational project. Suggestions and improvements are welcome!

## License

This project is open source and available for educational purposes.

---

**Author**: Computer Architecture Course Project  
**Last Updated**: December 2025
