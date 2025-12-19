.global _boot
.text

_boot:                    /* x0  = 0    0x000 */
    # Initialize registers with test values
    lui x1, 0x12345          # x1 = 0x12345000
    addi x2, x0, 10          # x2 = 10
    addi x3, x0, 20          # x3 = 20
    addi x4, x0, -5          # x4 = -5

# TEST 1: Arithmetic R-type instructions
test_arithmetic:
    add x5, x2, x3           # x5 = 10 + 20 = 30
    sub x6, x3, x2           # x6 = 20 - 10 = 10
    sll x7, x2, x4           # x7 = x2 << (x4 & 0x1F) = 10 << 27
    srl x8, x2, x2           # x8 = x2 >> (x2 & 0x1F) = 10 >> 10 = 0
    sra x9, x4, x2           # x9 = x4 >> (x2 & 0x1F) (arithmetic)
    
# TEST 2: Logical R-type instructions
test_logical:
    xor x10, x2, x3          # x10 = 10 ^ 20 = 30
    or x11, x2, x3           # x11 = 10 | 20 = 30
    and x12, x2, x3          # x12 = 10 & 20 = 0
    slt x13, x4, x2          # x13 = (x4 < x2) = 1 (signed)
    sltu x14, x4, x2         # x14 = (x4 < x2) unsigned

# TEST 3: Arithmetic I-type instructions
test_imm_arithmetic:
    addi x15, x2, 100        # x15 = 10 + 100 = 110
    xori x16, x2, 0xFF       # x16 = 10 ^ 255 = 245
    ori x17, x2, 0xF0        # x17 = 10 | 240 = 250
    andi x18, x3, 0x0F       # x18 = 20 & 15 = 4
    slli x19, x2, 3          # x19 = 10 << 3 = 80
    srli x20, x3, 2          # x20 = 20 >> 2 = 5
    srai x21, x4, 1          # x21 = -5 >> 1 (arithmetic)
    slti x22, x2, 15         # x22 = (10 < 15) = 1
    sltiu x23, x4, 15        # x23 = (x4 < 15) unsigned

# TEST 4: Memory operations (Store)
test_store:
    lui x24, 0x10000         # Base address for memory
    sw x2, 0(x24)            # Store x2 (10) at address
    sw x3, 4(x24)            # Store x3 (20) at address+4
    sw x5, 8(x24)            # Store x5 (30) at address+8

# TEST 5: Memory operations (Load)
test_load:
    lw x25, 0(x24)           # Load from address, x25 = 10
    lw x26, 4(x24)           # Load from address+4, x26 = 20
    lw x27, 8(x24)           # Load from address+8, x27 = 30

# TEST 6: Branch instructions
test_branch:
    addi x28, x0, 0          # x28 = 0 (counter)
    beq x2, x2, branch_taken # Branch if x2 == x2 (always true)
    addi x28, x28, 1         # Should be skipped
branch_taken:
    addi x28, x28, 10        # x28 = 10
    
    beq x2, x3, skip1        # Branch if 10 == 20 (false)
    addi x28, x28, 5         # x28 = 15 (executed)
skip1:
    addi x29, x0, 0          # x29 = 0

# TEST 7: Jump and Link
test_jump:
    jal x30, subroutine      # Jump to subroutine, save return address
    
    jal x0, test_upper       # Jump to next test

subroutine:
    addi x29, x29, 100       # x29 = 100

# TEST 8: Upper Immediate
test_upper:
    lui x31, 0xABCDE         # x31 = 0xABCDE000

# TEST 9: Edge Cases - x0 Immutability
test_x0:
    addi x0, x0, 100         # Try to write to x0 (should remain 0)
    add x0, x2, x3           # Try R-type write to x0 (should remain 0)

# TEST 10: Shift Edge Cases
test_shift_edges:
    slli x5, x2, 0           # Shift by 0, x5 = 10 (unchanged)
    slli x6, x3, 31          # Shift by 31, x6 = 20 << 31 = 0x80000000
    srli x7, x6, 31          # Shift 0x80000000 >> 31 = 1
    srai x8, x6, 31          # Arithmetic shift 0x80000000 >> 31 = 0xFFFFFFFF

# TEST 11: Arithmetic Overflow/Underflow
test_overflow:
    lui x9, 0x7FFFF          # x9 = 0x7FFFF000
    addi x9, x9, 0x7FF       # x9 = 0x7FFFFFFF (max positive)
    addi x10, x9, 1          # x10 = 0x80000000 (overflow to min negative)
    
    lui x11, 0x80000         # x11 = 0x80000000 (min negative)
    addi x12, x11, -1        # x12 = 0x7FFFFFFF (underflow to max positive)

# TEST 12: Comparison Edge Cases
test_compare_edges:
    slt x13, x2, x2          # Compare equal (10 < 10) = 0
    sltu x14, x2, x2         # Compare equal unsigned = 0
    slt x15, x9, x10         # Compare 0x7FFFFFFF < 0x80000000 (signed) = 0
    sltu x16, x9, x10        # Compare 0x7FFFFFFF < 0x80000000 (unsigned) = 1

# TEST 13: Negative Number Operations
test_negative:
    add x17, x4, x4          # Add two negatives: -5 + -5 = -10
    sub x18, x4, x2          # Subtract positive from negative: -5 - 10 = -15

# TEST 14: Load-After-Store (RAW Hazard)
test_raw_hazard:
    lui x19, 0x10010         # Different memory address
    addi x20, x2, 42         # x20 = 52
    sw x20, 0(x19)           # Store 52
    lw x21, 0(x19)           # Load immediately after store, x21 = 52

# TEST 15: Backward Branch
test_backward_branch:
    addi x22, x0, 0          # x22 = 0 (counter)
    addi x23, x0, 3          # x23 = 3 (limit)
loop_start:
    addi x22, x22, 1         # x22++
    bne x22, x23, loop_start # Branch backward if x22 != 3
    # After loop: x22 = 3

# TEST 16: All Zeros and All Ones Patterns
test_patterns:
    addi x24, x0, -1         # x24 = 0xFFFFFFFF (all ones)
    and x25, x24, x2         # 0xFFFFFFFF & 10 = 10
    or x26, x0, x24          # 0 | 0xFFFFFFFF = 0xFFFFFFFF
    xor x27, x24, x24        # 0xFFFFFFFF ^ 0xFFFFFFFF = 0

end_test:
    # Infinite loop to end execution
    beq x0, x0, end_test

.data
# Data section for testing memory operations
test_data:
    .word 0x11111111
    .word 0x22222222
    .word 0x33333333
   
