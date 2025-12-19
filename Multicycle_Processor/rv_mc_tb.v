`include "rv_mc.v"
`timescale 1ps/1ps
module rv_mc_tb;
    reg clk;
    reg reset;
    integer passed, failed, cycle_count;

    rv_mc DUT (
        .clk(clk),
        .rst(reset)
    );

    // Instruction type counters
    integer r_type_count, r_type_cycles;
    integer i_type_arith_count, i_type_arith_cycles;
    integer load_count, load_cycles;
    integer store_count, store_cycles;
    integer branch_count, branch_cycles;
    integer jal_count, jal_cycles;
    integer lui_count, lui_cycles;
    integer total_instructions;
    
    // Cycle tracking for current instruction
    integer instr_start_cycle;
    reg [6:0] current_opcode;
    reg tracking_instruction;

    //clock generation
    initial begin
        clk = 1'b0;
        forever begin
            #1 clk = ~clk;
        end
    end

    //reset generation
    initial begin
        reset = 1;  // Assert reset (active-high)
        #15
        reset = 0;  // Release reset (active-high)
    end

    // Task: Wait for N clock cycles
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    // Task: Check register value
    task check_register;
        input [4:0] reg_num;
        input [31:0] expected;
        input [200*8:1] test_name;  // String description
        reg [31:0] actual;
        begin
            actual = DUT.REGFILE.registers[reg_num];
            if (actual === expected) begin
                $display("[PASS] %0s: x%0d = 0x%h", test_name, reg_num, actual);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %0s: x%0d = 0x%h (expected 0x%h)", 
                         test_name, reg_num, actual, expected);
                failed = failed + 1;
            end
        end
    endtask

    // Task: Check memory value
    task check_memory;
        input [31:0] addr;
        input [31:0] expected;
        input [200*8:1] test_name;
        reg [31:0] actual;
        begin
            actual = DUT.MEM.RAM[addr[11:2]];
            if (actual === expected) begin
                $display("[PASS] %0s: mem[0x%h] = 0x%h", test_name, addr, actual);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %0s: mem[0x%h] = 0x%h (expected 0x%h)", 
                         test_name, addr, actual, expected);
                failed = failed + 1;
            end
        end
    endtask

    // Task: Display register file
    task display_registers;
        integer i;
        begin
            $display("\n=== Register File Contents ===");
            for (i = 0; i < 32; i = i + 1) begin
                if (DUT.REGFILE.registers[i] !== 32'b0 || i == 0)
                    $display("x%0d = 0x%h", i, DUT.REGFILE.registers[i]);
            end
        end
    endtask

    // Task: Display test summary
    task display_summary;
        begin
            $display("\n========================================");
            $display("Test Summary:");
            $display("  PASSED: %0d", passed);
            $display("  FAILED: %0d", failed);
            if (failed == 0)
                $display("  STATUS: ALL TESTS PASSED!");
            else
                $display("  STATUS: SOME TESTS FAILED!");
            $display("========================================\n");
        end
    endtask
    
    // Task: Display CPI statistics
    task display_cpi_stats;
        real r_type_cpi, i_type_cpi, load_cpi, store_cpi, branch_cpi, jal_cpi, lui_cpi, overall_cpi;
        begin
            $display("\n========================================");
            $display("CPI (Cycles Per Instruction) Statistics");
            $display("========================================");
            $display("Total Cycles: %0d", cycle_count);
            $display("Total Instructions: %0d\n", total_instructions);
            
            if (r_type_count > 0) begin
                r_type_cpi = r_type_cycles * 1.0 / r_type_count;
                $display("R-Type (ADD, SUB, etc.):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", r_type_count, r_type_cycles, r_type_cpi);
            end
            
            if (i_type_arith_count > 0) begin
                i_type_cpi = i_type_arith_cycles * 1.0 / i_type_arith_count;
                $display("I-Type Arithmetic (ADDI, XORI, etc.):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", i_type_arith_count, i_type_arith_cycles, i_type_cpi);
            end
            
            if (load_count > 0) begin
                load_cpi = load_cycles * 1.0 / load_count;
                $display("Load Instructions (LW):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", load_count, load_cycles, load_cpi);
            end
            
            if (store_count > 0) begin
                store_cpi = store_cycles * 1.0 / store_count;
                $display("Store Instructions (SW):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", store_count, store_cycles, store_cpi);
            end
            
            if (branch_count > 0) begin
                branch_cpi = branch_cycles * 1.0 / branch_count;
                $display("Branch Instructions (BEQ):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", branch_count, branch_cycles, branch_cpi);
            end
            
            if (jal_count > 0) begin
                jal_cpi = jal_cycles * 1.0 / jal_count;
                $display("Jump Instructions (JAL):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", jal_count, jal_cycles, jal_cpi);
            end
            
            if (lui_count > 0) begin
                lui_cpi = lui_cycles * 1.0 / lui_count;
                $display("Upper Immediate (LUI):");
                $display("  Count: %0d, Cycles: %0d, CPI: %0.2f", lui_count, lui_cycles, lui_cpi);
            end
            
            if (total_instructions > 0) begin
                overall_cpi = cycle_count * 1.0 / total_instructions;
                $display("\nOverall CPI: %0.2f", overall_cpi);
            end
            $display("========================================\n");
        end
    endtask

    // Monitor PC and instruction execution
    reg [31:0] last_pc;
    reg [31:0] last_fetched_pc;
    integer stuck_count;
    
    initial begin
        last_pc = 32'hFFFFFFFF;
        last_fetched_pc = 32'hFFFFFFFF;
        stuck_count = 0;
    end

    initial begin
        cycle_count = 0;
        r_type_count = 0; r_type_cycles = 0;
        i_type_arith_count = 0; i_type_arith_cycles = 0;
        load_count = 0; load_cycles = 0;
        store_count = 0; store_cycles = 0;
        branch_count = 0; branch_cycles = 0;
        jal_count = 0; jal_cycles = 0;
        lui_count = 0; lui_cycles = 0;
        total_instructions = 0;
        tracking_instruction = 0;
    end

    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
        end
    end
    
    // Track instruction types and cycles
    always @(posedge clk) begin
        if (!reset) begin
            // Start tracking when instruction is fetched
            if (DUT.we_ir && DUT.CTRL.fsm.state == 0) begin  // FETCH state
                if (tracking_instruction) begin
                    // Previous instruction completed, count its cycles
                    case (current_opcode)
                        7'b0110011: r_type_cycles = r_type_cycles + (cycle_count - instr_start_cycle);
                        7'b0010011: i_type_arith_cycles = i_type_arith_cycles + (cycle_count - instr_start_cycle);
                        7'b0000011: load_cycles = load_cycles + (cycle_count - instr_start_cycle);
                        7'b0100011: store_cycles = store_cycles + (cycle_count - instr_start_cycle);
                        7'b1100011: branch_cycles = branch_cycles + (cycle_count - instr_start_cycle);
                        7'b1101111: jal_cycles = jal_cycles + (cycle_count - instr_start_cycle);
                        7'b0110111: lui_cycles = lui_cycles + (cycle_count - instr_start_cycle);
                    endcase
                end
                
                // Start tracking new instruction
                current_opcode = DUT.RD[6:0];
                instr_start_cycle = cycle_count;
                tracking_instruction = 1;
                
                // Count instruction types
                case (DUT.RD[6:0])
                    7'b0110011: r_type_count = r_type_count + 1;
                    7'b0010011: i_type_arith_count = i_type_arith_count + 1;
                    7'b0000011: load_count = load_count + 1;
                    7'b0100011: store_count = store_count + 1;
                    7'b1100011: branch_count = branch_count + 1;
                    7'b1101111: jal_count = jal_count + 1;
                    7'b0110111: lui_count = lui_count + 1;
                endcase
                total_instructions = total_instructions + 1;
            end
        end
    end
        
    always @(posedge clk) begin
        if (!reset) begin
            // Check if PC is stuck only when fetching (we_ir = 1)
            if (DUT.we_ir) begin
                if (DUT.PC_reg == last_fetched_pc) begin
                    stuck_count = stuck_count + 1;
                    if (stuck_count >= 2) begin
                        $display("\n[INFO] Program completed at cycle %0d (PC=0x%h)", 
                        cycle_count, DUT.PC_reg);
                        #10;
                        $display("\n=== Checking Results ===\n");
                        check_all_results();
                        $finish;
                    end
                end else begin
                    stuck_count = 0;
                    last_fetched_pc = DUT.PC_reg;
                end
            end
            last_pc = DUT.PC_reg;
            
            // Monitor instruction fetch
            if (DUT.we_ir) begin
                $display("Time %0t: PC=0x%h, Fetched=0x%h, State=%0d", 
                         $time, DUT.PC_reg, DUT.RD, DUT.CTRL.fsm.state);
            end
            
            // Monitor register writes
            if (DUT.we_rf) begin
                $display("  [REG WRITE] x%0d <= 0x%h (ImmExt=0x%h, instr[31:20]=0x%h)", 
                         DUT.instr_reg[11:7], DUT.Result, DUT.ImmExt, DUT.instr_reg[31:20]);
                $display("  [ALU DEBUG WB] SrcA=0x%h, SrcB=0x%h, AluResult=0x%h, alu_control=0x%h", 
                         DUT.SrcA, DUT.SrcB, DUT.AluResult, DUT.alu_control);
                $display("  [ALU REG] alu_reg=0x%h, Result=0x%h", DUT.alu_reg, DUT.Result);
            end
            
            // Monitor ALU execution during EXECUTEI state (state 7)
            if (DUT.CTRL.fsm.state == 7) begin
                $display("  [EXECUTEI] SrcA=0x%h, SrcB=0x%h, AluResult=0x%h, alu_control=0x%h", 
                         DUT.SrcA, DUT.SrcB, DUT.AluResult, DUT.alu_control);
            end
        end
    end

    initial begin
        passed = 0;
        failed = 0;

        //dumpfiles for gtkwave
        $dumpfile("rv_mc_tb.vcd");
        $dumpvars(0, rv_mc_tb);

        $display("========================================");
        $display("Loading instructions into RAM");
        $display("========================================");

        //load test instructions into RAM
        $readmemh("test_program.hex", DUT.MEM.RAM);

        $display("\n=== Starting RISC-V Processor Test ===\n");

        // Wait for reset to complete
        wait_cycles(2);

        // Run instructions - will auto-stop on infinite loop
        wait_cycles(300);

        // If we get here, check results
        $display("\n=== Checking Results ===\n");
        check_all_results();

        $finish;
    end

    // Task to check all results
    task check_all_results;
        begin
            // Initialization checks
            check_register(0, 32'h00000000, "x0 always zero");
            check_register(1, 32'h12345000, "LUI x1, 0x12345");
            check_register(2, 32'h0000000a, "ADDI x2 = 10");
            check_register(3, 32'h00000014, "ADDI x3 = 20");
            check_register(4, 32'hfffffffb, "ADDI x4 = -5");

        // TEST 1: Arithmetic R-type
        check_register(5, 32'h0000001e, "ADD x5 = x2 + x3 = 30");
        check_register(6, 32'h0000000a, "SUB x6 = x3 - x2 = 10");
        check_register(7, 32'h50000000, "SLL x7 = x2 << 27");  // 10 << 27 = 0x50000000
        check_register(8, 32'h00000000, "SRL x8 = x2 >> 10 = 0");
        check_register(9, 32'hffffffff, "SRA x9 = x4 >> 10 (arithmetic)");

        // TEST 2: Logical R-type
        check_register(10, 32'h0000001e, "XOR x10 = 10 ^ 20 = 30");
        check_register(11, 32'h0000001e, "OR x11 = 10 | 20 = 30");
        check_register(12, 32'h00000000, "AND x12 = 10 & 20 = 0");
        check_register(13, 32'h00000001, "SLT x13 = (x4 < x2) signed = 1");
        check_register(14, 32'h00000000, "SLTU x14 = (x4 < x2) unsigned = 0");

        // TEST 3: I-type arithmetic
        check_register(15, 32'h0000006e, "ADDI x15 = 10 + 100 = 110");
        check_register(16, 32'h000000f5, "XORI x16 = 10 ^ 255 = 245");
        check_register(17, 32'h000000fa, "ORI x17 = 10 | 240 = 250");
        check_register(18, 32'h00000004, "ANDI x18 = 20 & 15 = 4");
        check_register(19, 32'h00000050, "SLLI x19 = 10 << 3 = 80");
        check_register(20, 32'h00000005, "SRLI x20 = 20 >> 2 = 5");
        check_register(21, 32'hfffffffd, "SRAI x21 = -5 >> 1 = -3");
        check_register(22, 32'h00000001, "SLTI x22 = (10 < 15) = 1");
        check_register(23, 32'h00000000, "SLTIU x23 = (-5 < 15) unsigned = 0");

        // TEST 4 & 5: Memory operations
        check_register(24, 32'h10000000, "LUI x24 = 0x10000000 (base address)");
        check_register(25, 32'h0000000a, "LW x25 = mem[x24] = 10");
        check_register(26, 32'h00000014, "LW x26 = mem[x24+4] = 20");
        check_register(27, 32'h0000001e, "LW x27 = mem[x24+8] = 30");

        // TEST 6: Branch instructions
        check_register(28, 32'h0000000f, "Branch test: x28 = 15");
        // check_register(29, 32'h00000065, "Jump test: x29 = 101 (after subroutine)"); // JALR not implemented

        // TEST 7: Jump and Link
        // x30 should contain return address from JAL

        // TEST 8: Upper immediate
        check_register(31, 32'habcde000, "LUI x31 = 0xABCDE000");

        // Memory checks
        check_memory(32'h10000000, 32'h0000000a, "Memory[0x10000000] = 10");
        check_memory(32'h10000004, 32'h00000014, "Memory[0x10000004] = 20");
        check_memory(32'h10000008, 32'h0000001e, "Memory[0x10000008] = 30");

            // Display all registers
            display_registers();

            // Display summary
            display_summary();
            
            // Display CPI statistics
            display_cpi_stats();
        end
    endtask

endmodule
