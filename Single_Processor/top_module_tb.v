`include "top_module_sc.v"
`timescale 1ns / 1ps

module top_module_tb;
    reg clk;
    reg reset;

    // Instantiate the top module
    riscv_single_cycle DUT (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test sequence
    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);

        // Load test instructions BEFORE reset
        $readmemh("instructions.hex", DUT.IM.memory);
        
        // Debug: Check if instructions loaded
        $display("Loaded instructions:");
        $display("mem[0] = %h", DUT.IM.memory[0]);
        $display("mem[1] = %h", DUT.IM.memory[1]);
        $display("mem[2] = %h", DUT.IM.memory[2]);

        // Apply reset (active low)
        reset = 0;
        #15; // Hold reset for 1.5 clock cycles
        reset = 1; // Release reset
        
        // Debug: Check after reset
        $display("\nAfter reset:");
        $display("mem[0] = %h", DUT.IM.memory[0]);
        $display("mem[1] = %h", DUT.IM.memory[1]);
        $display("PC = %h", DUT.pc_out);

        $display("\n=== Starting RISC-V Processor Test ===\n");

        // Run for enough cycles to execute all instructions
        repeat(20) begin
            #1; // Small delay to see stable values
            $display("PC=%h | Instr=%h | alu_ctrl=%b | alu_out=%h | wd=%h | x1=%d x2=%d x3=%d x4=%d x5=%d", 
                     DUT.pc_out, DUT.instr_out, DUT.alu_control, DUT.alu_out, DUT.result_to_rf,
                     DUT.RF.registers[1], DUT.RF.registers[2], DUT.RF.registers[3], 
                     DUT.RF.registers[4], DUT.RF.registers[5]);
            @(posedge clk);
        end

        $display("\n=== Final Register State ===");
        $display("x1 = %d (Expected: 5)", DUT.RF.registers[1]);
        $display("x2 = %d (Expected: 10)", DUT.RF.registers[2]);
        $display("x3 = %d (Expected: 15)", DUT.RF.registers[3]);
        $display("x4 = %d (Expected: 5)", DUT.RF.registers[4]);
        $display("x5 = %h (Expected: 0)", DUT.RF.registers[5]);
        $display("x6 = %h (Expected: F)", DUT.RF.registers[6]);
        $display("x7 = %d (Expected: 5)", DUT.RF.registers[7]);
        $display("x8 = %d (Expected: 0, should be skipped)", DUT.RF.registers[8]);
        $display("x9 = %d (Expected: 77)", DUT.RF.registers[9]);

        $display("\n=== Memory State ===");
        $display("Data Memory[0] = %h (Expected: 00000005)", DUT.DM.memory[0]);

        $finish;
    end
endmodule
