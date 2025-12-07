# Controller Decoding Tables

## First Level Decoder (Main Decoder)

Decodes the 7-bit opcode to generate control signals and intermediate `alu_op` signal.

| Opcode (7-bit) | Instruction Type | alu_op | sel_ext | sel_alu_src_b | rf_we | dmem_we | sel_result |
|----------------|------------------|--------|---------|---------------|-------|---------|------------|
| `0110011`      | R-type           | `01`   | `000`   | `0`           | `1`   | `0`     | `00`       |
| `0010011`      | I-type (ALU)     | `10`   | `000`   | `1`           | `1`   | `0`     | `00`       |
| `0000011`      | I-type (Load)    | `00`   | `000`   | `1`           | `1`   | `0`     | `01`       |
| `0100011`      | S-type (Store)   | `00`   | `001`   | `1`           | `0`   | `1`     | `00`       |
| `1100011`      | B-type (Branch)  | `01`   | `010`   | `0`           | `0`   | `0`     | `00`       |
| `1101111`      | J-type (JAL)     | `00`   | `100`   | `0`           | `1`   | `0`     | `10`       |
| `0110111`      | U-type (LUI)     | `--`   | `011`   | `-`           | `1`   | `0`     | `11`       |

### Control Signal Definitions (First Level)

- **alu_op**: Intermediate signal for second-level decoder
  - `00`: ADD operation (Load/Store/JAL)
  - `01`: R-type or Branch (use funct3/funct7)
  - `10`: I-type ALU operations (use funct3)
  - `11`: LUI (not used since LUI bypasses ALU)

- **sel_ext**: Sign extender format selector
  - `000`: I-type (12-bit immediate)
  - `001`: S-type (12-bit immediate)
  - `010`: B-type (12-bit immediate, shift left by 1)
  - `011`: U-type (20-bit upper immediate)
  - `100`: J-type (20-bit immediate, shift left by 1)

- **sel_alu_src_b**: ALU input B source
  - `0`: Register file read data 2 (rs2)
  - `1`: Sign extender output (immediate)

- **rf_we**: Register file write enable
  - `1`: Write to destination register
  - `0`: No register write

- **dmem_we**: Data memory write enable
  - `1`: Write to memory (Store)
  - `0`: No memory write

- **sel_result**: Result multiplexer selector (4-input)
  - `00`: ALU output
  - `01`: Data memory output (Load)
  - `10`: PC+4 (JAL return address)
  - `11`: Sign extender output (LUI bypass)

---

## Second Level Decoder (ALU Decoder)

Decodes the `alu_op` signal along with funct3 and funct7[5] to generate the 4-bit `alu_control` signal.

### Case 1: alu_op = `00` (Load/Store/JAL)

| alu_op | alu_control | ALU Operation | Used By |
|--------|-------------|---------------|---------|
| `00`   | `0010`      | ADD           | LW, SW, JAL (address calculation) |

### Case 2: alu_op = `01` (R-type and Branch)

#### Branch Instructions (opcode = `1100011`)
| Opcode Check | alu_control | ALU Operation | Notes |
|--------------|-------------|---------------|-------|
| opcode == `1100011` | `0110` | SUB | All branches use SUB to compare rs1 - rs2 and set Zero flag |

#### R-type Instructions (opcode = `0110011`)
| funct7[5] | funct3 | {funct7[5], funct3} | alu_control | ALU Operation | Instruction |
|-----------|--------|---------------------|-------------|---------------|-------------|
| `0`       | `000`  | `0000`              | `0010`      | ADD           | ADD         |
| `1`       | `000`  | `1000`              | `0110`      | SUB           | SUB         |
| `0`       | `111`  | `0111`              | `1110`      | AND           | AND         |
| `0`       | `110`  | `0110`              | `0001`      | OR            | OR          |
| `0`       | `100`  | `0100`              | `0011`      | XOR           | XOR         |
| `0`       | `001`  | `0001`              | `0100`      | SLL           | SLL         |
| `0`       | `101`  | `0101`              | `0101`      | SRL           | SRL         |
| `1`       | `101`  | `1101`              | `1000`      | SRA           | SRA         |
| `0`       | `010`  | `0010`              | `0111`      | SLT           | SLT         |

### Case 3: alu_op = `10` (I-type ALU Operations)

| funct3 | funct7[5] | alu_control | ALU Operation | Instruction |
|--------|-----------|-------------|---------------|-------------|
| `000`  | `-`       | `0010`      | ADD           | ADDI        |
| `111`  | `-`       | `1110`      | AND           | ANDI        |
| `110`  | `-`       | `0001`      | OR            | ORI         |
| `100`  | `-`       | `0011`      | XOR           | XORI        |
| `001`  | `-`       | `0100`      | SLL           | SLLI        |
| `101`  | `0`       | `0101`      | SRL           | SRLI        |
| `101`  | `1`       | `1000`      | SRA           | SRAI        |
| `010`  | `-`       | `0111`      | SLT           | SLTI        |

### Case 4: alu_op = `11` (LUI - Legacy, not used)

| alu_op | alu_control | ALU Operation | Notes |
|--------|-------------|---------------|-------|
| `11`   | `1111`      | Pass-through B | Not used - LUI now bypasses ALU via sel_result = `11` |

---

## ALU Control Signal Encoding

| alu_control | Operation | Function |
|-------------|-----------|----------|
| `0000`      | NOP       | No operation |
| `0001`      | OR        | A \| B |
| `0010`      | ADD       | A + B |
| `0011`      | XOR       | A ^ B |
| `0100`      | SLL       | A << B[4:0] |
| `0101`      | SRL       | A >> B[4:0] |
| `0110`      | SUB       | A - B |
| `0111`      | SLT       | (A < B) ? 1 : 0 |
| `1000`      | SRA       | A >>> B[4:0] |
| `1110`      | AND       | A & B |
| `1111`      | PASS_B    | B (legacy, not used) |

---

## Complete Instruction Mapping

| Instruction | Opcode    | funct3 | funct7[5] | alu_control | sel_result | Notes |
|-------------|-----------|--------|-----------|-------------|------------|-------|
| **R-type**  |           |        |           |             |            |       |
| ADD         | `0110011` | `000`  | `0`       | `0010`      | `00`       | rd = rs1 + rs2 |
| SUB         | `0110011` | `000`  | `1`       | `0110`      | `00`       | rd = rs1 - rs2 |
| AND         | `0110011` | `111`  | `0`       | `1110`      | `00`       | rd = rs1 & rs2 |
| OR          | `0110011` | `110`  | `0`       | `0001`      | `00`       | rd = rs1 \| rs2 |
| XOR         | `0110011` | `100`  | `0`       | `0011`      | `00`       | rd = rs1 ^ rs2 |
| SLL         | `0110011` | `001`  | `0`       | `0100`      | `00`       | rd = rs1 << rs2[4:0] |
| SRL         | `0110011` | `101`  | `0`       | `0101`      | `00`       | rd = rs1 >> rs2[4:0] |
| SRA         | `0110011` | `101`  | `1`       | `1000`      | `00`       | rd = rs1 >>> rs2[4:0] |
| SLT         | `0110011` | `010`  | `0`       | `0111`      | `00`       | rd = (rs1 < rs2) ? 1 : 0 |
| **I-type**  |           |        |           |             |            |       |
| ADDI        | `0010011` | `000`  | `-`       | `0010`      | `00`       | rd = rs1 + imm |
| ANDI        | `0010011` | `111`  | `-`       | `1110`      | `00`       | rd = rs1 & imm |
| ORI         | `0010011` | `110`  | `-`       | `0001`      | `00`       | rd = rs1 \| imm |
| XORI        | `0010011` | `100`  | `-`       | `0011`      | `00`       | rd = rs1 ^ imm |
| SLLI        | `0010011` | `001`  | `-`       | `0100`      | `00`       | rd = rs1 << imm[4:0] |
| SRLI        | `0010011` | `101`  | `0`       | `0101`      | `00`       | rd = rs1 >> imm[4:0] |
| SRAI        | `0010011` | `101`  | `1`       | `1000`      | `00`       | rd = rs1 >>> imm[4:0] |
| SLTI        | `0010011` | `010`  | `-`       | `0111`      | `00`       | rd = (rs1 < imm) ? 1 : 0 |
| LW          | `0000011` | `010`  | `-`       | `0010`      | `01`       | rd = MEM[rs1 + imm] |
| **S-type**  |           |        |           |             |            |       |
| SW          | `0100011` | `010`  | `-`       | `0010`      | `--`       | MEM[rs1 + imm] = rs2 |
| **B-type**  |           |        |           |             |            |       |
| BEQ         | `1100011` | `000`  | `-`       | `0110`      | `--`       | if (rs1 == rs2) PC += imm |
| **U-type**  |           |        |           |             |            |       |
| LUI         | `0110111` | `-`    | `-`       | `----`      | `11`       | rd = imm << 12 (bypass ALU) |
| **J-type**  |           |        |           |             |            |       |
| JAL         | `1101111` | `-`    | `-`       | `0010`      | `10`       | rd = PC+4; PC += imm |

---

## Notes

1. **Branch Implementation**: All branches use SUB operation to compare registers. The Zero flag from ALU indicates equality for BEQ.

2. **LUI Optimization**: LUI bypasses the ALU entirely. The sign extender output goes directly to the register file via `sel_result = 11`.

3. **Two-Level Decoding**: The controller uses a two-level approach:
   - Level 1: Decode opcode → generate high-level control signals
   - Level 2: Decode alu_op + funct fields → generate ALU control

4. **Sensitivity List**: The second decoder uses `always @(*)` to ensure it updates whenever any input changes (opcode, funct3, funct7[5], alu_op).
