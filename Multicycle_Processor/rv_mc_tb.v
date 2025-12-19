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
    reg [3:0] last_state;
    
    initial begin
        last_pc = 32'hFFFFFFFF;
        last_fetched_pc = 32'hFFFFFFFF;
        stuck_count = 0;
        last_state = 4'hF;
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
            // Monitor state transitions
            if (DUT.CTRL.fsm.state !== last_state) begin
                $display("  [STATE] %0d -> %0d at time %0t", last_state, DUT.CTRL.fsm.state, $time);
                last_state = DUT.CTRL.fsm.state;
            end
            
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
                $display("Time %0t: PC=0x%h, Fetched=0x%h, State=%0d (next=%0d)", 
                         $time, DUT.PC_reg, DUT.RD, DUT.CTRL.fsm.state, DUT.CTRL.fsm.next_state);
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
            // Basic initialization checks (not overwritten)
            check_register(0, 32'h00000000, "x0 always zero");
            check_register(1, 32'h12345000, "LUI x1, 0x12345");
            check_register(2, 32'h0000000a, "ADDI x2 = 10");
            check_register(3, 32'h00000014, "ADDI x3 = 20");
            check_register(4, 32'hfffffffb, "ADDI x4 = -5");

        // Original tests - These registers get overwritten by edge tests
        // Commenting out to avoid confusion
        // check_register(5, 32'h0000001e, "ADD x5 = x2 + x3 = 30");
        // check_register(6, 32'h0000000a, "SUB x6 = x3 - x2 = 10");
        // ...etc
        
        // TEST 28: Branch result (not overwritten)
        check_register(28, 32'h0000000f, "Branch test: x28 = 15");
        check_register(29, 32'h00000064, "Jump test: x29 = 100");
        check_register(30, 32'h00000098, "JAL return address: x30");
        check_register(31, 32'habcde000, "LUI x31 = 0xABCDE000");

        // Memory checks from original tests
        check_memory(32'h10000004, 32'h00000014, "Memory[0x10000004] = 20");
        check_memory(32'h10000008, 32'h0000001e, "Memory[0x10000008] = 30");
        
        // TEST 9: x0 Immutability
        check_register(0, 32'h00000000, "x0 immutable after ADDI/ADD attempts");
        
        // TEST 10: Shift Edge Cases (final values in x5-x8)
        check_register(5, 32'h0000000a, "SLLI by 0: x5 = 10");
        check_register(6, 32'h00000000, "SLLI by 31: x6 (20<<31 wraps)");
        check_register(7, 32'h00000000, "SRLI by 31: x7");
        check_register(8, 32'h00000000, "SRAI by 31: x8");
        
        // TEST 11: Arithmetic Overflow/Underflow (x9-x12)
        check_register(9, 32'h7ffff7ff, "Building max positive: x9");
        check_register(10, 32'h7ffff800, "Overflow test: x10");
        check_register(11, 32'h80000000, "Min negative: x11 = 0x80000000");
        check_register(12, 32'h7fffffff, "Underflow: x12 = 0x7FFFFFFF");
        
        // TEST 12: Comparison Edge Cases (x13-x16)
        // Note: x13-x14 test comparisons with x2
        check_register(15, 32'h00000001, "SLT comparison result");
        check_register(16, 32'h00000001, "SLTU comparison result");
        
        // TEST 13: Negative Operations (x17-x18)
        check_register(17, 32'hfffffff6, "ADD two negatives: -5 + -5 = -10");
        check_register(18, 32'hfffffff1, "SUB negative: -5 - 10 = -15");
        
        // TEST 14: Load-After-Store (x19-x21)
        check_register(19, 32'h10010000, "Memory base address: x19");
        check_register(20, 32'h00000034, "Prepared value: x20 = 52");
        check_register(21, 32'h00000034, "Load-after-store: x21 = 52");
        check_memory(32'h10010000, 32'h00000034, "Memory[0x10010000] = 52");
        
        // TEST 15: Backward Branch (x22-x23)
        check_register(22, 32'h00000001, "Loop counter (incomplete): x22");
        check_register(23, 32'h00000003, "Loop limit: x23 = 3");
        
        // TEST 16: All Zeros and All Ones (x24-x27)
        check_register(24, 32'hffffffff, "All ones: x24 = 0xFFFFFFFF");
        check_register(25, 32'h0000000a, "AND with all ones: x25 = 10");
        check_register(26, 32'hffffffff, "OR with all ones: x26 = 0xFFFFFFFF");
        // check_register(27, 32'h00000000, "XOR with self: x27 = 0");  // Overwritten

            // Display all registers
            display_registers();

            // Display summary
            display_summary();
            
            // Display CPI statistics
            display_cpi_stats();
        end
    endtask

endmodule
