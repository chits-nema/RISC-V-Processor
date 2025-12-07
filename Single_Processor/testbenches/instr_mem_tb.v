`include "../instr_mem.v"
`timescale 1ns / 1ps

module instr_mem_tb;
    reg [31:0] read_address;
    wire [31:0] instr_out;

    // Instantiate the instruction_mem module
    instruction_mem IM (
        .read_address(read_address),
        .instr_out(instr_out)
    );

    task init();
        begin
        // Initialize signals
        read_address = 0;
        end
    endtask

    initial begin
        $dumpfile("instr_mem_tb.vcd");
        $dumpvars(0, instr_mem_tb);

        init();
        
        // Load some test instructions into memory
        IM.memory[0] = 32'h00500093; // addi x1, x0, 5
        IM.memory[1] = 32'h00A00113; // addi x2, x0, 10
        IM.memory[2] = 32'h002081B3; // add x3, x1, x2
        
        #10;
        
        // Test reading byte addresses (word-aligned)
        read_address = 32'h00000000;
        #10;
        $display("Test Case 1 - Instruction at 0x00: %h (Expected: 00500093)", instr_out);
        
        read_address = 32'h00000004;
        #10;
        $display("Test Case 2 - Instruction at 0x04: %h (Expected: 00A00113)", instr_out);

        // Test Case 3: Read instruction at address 0x08
        read_address = 32'h00000008;
        #10; // Wait for output to stabilize
        $display("Test Case 3 - Instruction at 0x08: %h (Expected: 002081B3)", instr_out);

        $finish;
    end
endmodule
