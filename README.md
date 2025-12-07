# RISC-V Single-Cycle Processor

A complete single-cycle implementation of a RISC-V processor in Verilog, supporting a subset of the RV32I instruction set architecture.

## Features

- **Architecture**: Single-cycle datapath with Harvard architecture (separate instruction and data memory)
- **Word Size**: 32-bit
- **Memory**: 32 words each for instruction and data memory
- **Register File**: 32 general-purpose registers (x0-x31)
- **Instructions Supported**: 
  - R-type: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT
  - I-type: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, LW
  - S-type: SW
  - B-type: BEQ
  - U-type: LUI
  - J-type: JAL

## Module Hierarchy

```
top_module_sc.v (riscv_single_cycle)
├── program_counter.v (PC)
├── instr_mem.v (Instruction Memory)
├── reg_file.v (Register File)
├── data_mem.v (Data Memory)
├── alu.v (ALU with Zero flag)
├── controller.v (Control Unit)
├── sign_extender.v (Immediate Generator)
└── multiplexer.v (2:1 MUX)
```

## Datapath Description

### Key Components

1. **Program Counter (PC)**
   - Tracks current instruction address
   - Supports sequential execution and branches/jumps
   - Active-low reset to address 0x00000000

2. **Instruction Memory**
   - ROM holding program instructions
   - Loaded via `$readmemh` from hex file
   - No reset signal (instructions persist)
   - Word-addressed (PC[31:2])

3. **Register File**
   - 32 registers × 32 bits
   - Dual read ports, single write port
   - x0 hardwired to 0
   - Synchronous write, asynchronous read

4. **ALU**
   - Operations: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT
   - Zero flag output for branch comparison
   - 4-bit control signal

5. **Data Memory**
   - 32 words × 32 bits
   - Synchronous read/write
   - Word-addressed

6. **Controller**
   - Two-level decoder
   - Generates all control signals
   - Distinguishes between R-type and Branch instructions using opcode

7. **Sign Extender**
   - Supports 5 immediate formats:
     - I-type (12-bit): Loads, ADDI, etc.
     - S-type (12-bit): Stores
     - B-type (12-bit): Branches (shift left by 1)
     - U-type (20-bit): LUI (upper 20 bits)
     - J-type (20-bit): JAL (shift left by 1)

### Control Signals

| Signal | Width | Description |
|--------|-------|-------------|
| `alu_control` | 4 bits | ALU operation selector |
| `sel_ext` | 3 bits | Immediate format selector |
| `sel_alu_src_b` | 1 bit | ALU input B: 0=register, 1=immediate |
| `rf_we` | 1 bit | Register file write enable |
| `dmem_we` | 1 bit | Data memory write enable |
| `sel_result` | 2 bits | Result mux: 00=ALU, 01=Memory, 10=PC+4, 11=Immediate |

### Special Features

#### Branch Execution (BEQ)
- ALU performs subtraction (rs1 - rs2)
- Zero flag set if equal
- Branch logic: `branch_taken = (opcode == BRANCH) && Zero`
- PC updates to: `pc_next = branch_taken ? (PC + offset) : (PC + 4)`

#### Jump and Link (JAL)
- Unconditionally jumps to PC + offset
- Saves return address (PC+4) to destination register
- Uses 4-input result mux to select PC+4

#### Load Upper Immediate (LUI)
- Bypasses ALU entirely
- Sign extender output goes directly to register file
- Loads 20-bit immediate into upper bits (lower 12 bits = 0)

## File Structure

```
riscv_single_processor/
├── README.md                    # This file
├── top_module_sc.v              # Top-level integration
├── top_module_tb.v              # System testbench
├── instructions.hex             # Program memory (hex format)
├── program_counter.v            # PC module
├── instr_mem.v                  # Instruction memory
├── reg_file.v                   # Register file
├── data_mem.v                   # Data memory
├── alu.v                        # Arithmetic Logic Unit
├── controller.v                 # Control unit
├── sign_extender.v              # Immediate generator
├── multiplexer.v                # 2:1 multiplexer
└── testbenches/                 # Individual module testbenches
    ├── alu_tb.v
    ├── controller_tb.v
    ├── data_mem_tb.v
    ├── instr_mem_tb.v
    ├── multiplexer_tb.v
    ├── program_counter_tb.v
    ├── reg_file_tb.v
    └── signextender_tb.v
```

## Building and Running

### Prerequisites
- Icarus Verilog (iverilog)
- VVP simulator
- GTKWave (optional, for waveform viewing)

### Compile and Run

```powershell
# Navigate to processor directory
cd riscv_single_processor

# Compile the design
iverilog -o sim top_module_tb.v

# Run simulation
vvp sim

# View waveforms (optional)
gtkwave top_module_tb.vcd
```

### Running Individual Module Tests

```powershell
cd testbenches

# Example: Test ALU
iverilog -o sim alu_tb.v
vvp sim
gtkwave alu_tb.vcd
```

## Programming the Processor

### Instruction Format

Create a hex file (e.g., `instructions.hex`) with one 32-bit instruction per line:

```
00500093  // ADDI x1, x0, 5    -> x1 = 5
00A00113  // ADDI x2, x0, 10   -> x2 = 10
002081B3  // ADD  x3, x1, x2   -> x3 = 15
40110233  // SUB  x4, x2, x1   -> x4 = 5
0020F2B3  // AND  x5, x1, x2   -> x5 = 0
0020E333  // OR   x6, x1, x2   -> x6 = 15
00102023  // SW   x1, 0(x0)    -> MEM[0] = 5
00002383  // LW   x7, 0(x0)    -> x7 = 5
00108463  // BEQ  x1, x1, 8    -> Branch taken
06300413  // ADDI x8, x0, 99   -> Skipped
04D00493  // ADDI x9, x0, 77   -> x9 = 77
```

Comments (starting with `//`) are automatically ignored by `$readmemh`.

### Example Programs

The provided `instructions.hex` demonstrates:
1. **Immediate operations**: Loading constants
2. **Arithmetic**: Addition and subtraction
3. **Logic operations**: AND, OR
4. **Memory access**: Store and load
5. **Control flow**: Conditional branch

## Testing

The main testbench (`top_module_tb.v`):
- Loads instructions from `instructions.hex`
- Applies reset sequence (active-low)
- Runs for 20 clock cycles
- Displays register and memory states
- Verifies expected results

### Expected Output
```
=== Final Register State ===
x1 =          5 (Expected: 5)
x2 =         10 (Expected: 10)
x3 =         15 (Expected: 15)
x4 =          5 (Expected: 5)
x5 = 00000000 (Expected: 0)
x6 = 0000000f (Expected: F)
x7 =          5 (Expected: 5)
x8 =          0 (Expected: 0, should be skipped)
x9 =         77 (Expected: 77)

=== Memory State ===
Data Memory[0] = 00000005 (Expected: 00000005)
```

## Design Decisions

### Reset Strategy
- **Active-low reset** (`reset_n`) for sequential elements
- PC, register file, and data memory reset to 0
- Instruction memory has **no reset** (ROM behavior)

### ALU Operations Encoding
- `0001`: OR
- `0010`: ADD
- `0011`: XOR
- `0100`: SLL (Shift Left Logical)
- `0101`: SRL (Shift Right Logical)
- `0110`: SUB
- `0111`: SLT (Set Less Than)
- `1000`: SRA (Shift Right Arithmetic)
- `1110`: AND

### Result Multiplexer (4-input)
- `2'b00`: ALU output (R-type, I-type arithmetic)
- `2'b01`: Data memory output (LW)
- `2'b10`: PC+4 (JAL for return address)
- `2'b11`: Sign extender output (LUI bypass)

### Memory Addressing
- **PC uses byte addressing** (0x00, 0x04, 0x08, ...)
- **Memory uses word addressing** (divide by 4 via `[31:2]`)
- Supports up to 128 bytes (32 words)

## Limitations

- Single-cycle only (no pipelining)
- Limited instruction set (subset of RV32I)
- No interrupts or exceptions
- No system calls
- Fixed 32-word memory size
- No cache hierarchy

## Future Enhancements

Potential improvements:
- [ ] Multi-cycle or pipelined implementation
- [ ] Full RV32I instruction set support
- [ ] Hazard detection and forwarding
- [ ] Larger/configurable memory
- [ ] UART interface for I/O
- [ ] Interrupt handling
- [ ] Performance counters

## References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- Patterson & Hennessy: *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition)*

## License

Educational use only.

## Author

Created as part of a digital design course project.
