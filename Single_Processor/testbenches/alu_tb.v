`include "../alu.v"
`timescale 1ns / 1ps
module alu_tb;
    reg [31:0] operand_a;
    reg [31:0] operand_b;
    reg [3:0] alu_control;
    wire [31:0] alu_result;
    wire zero_flag;

    // Instantiate the ALU module
    alu ALU (
        .A(operand_a),
        .B(operand_b),
        .alu_control(alu_control),
        .alu_out(alu_result),
        .Zero(zero_flag)
    );

    task init();
        begin
        // Initialize signals
        operand_a = 0;
        operand_b = 0;
        alu_control = 0;
        end   
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        init();

        // Test Case 1: Addition
        operand_a = 32'h00000005;
        operand_b = 32'h00000003;
        alu_control = 4'b0010; // ADD
        #10; // Wait for output to stabilize
        $display("Test Case 1 (ADD) - Result: %h (Expected: 00000008)", alu_result);

        // Test Case 2: Subtraction
        operand_a = 32'h00000005;
        operand_b = 32'h00000003;
        alu_control = 4'b0110; // SUB
        #10; // Wait for output to stabilize
        $display("Test Case 2 (SUB) - Result: %h (Expected: 00000002)", alu_result);

        // Test Case 3: AND
        operand_a = 32'h0000000F;
        operand_b = 32'h00000003;
        alu_control = 4'b1110; // AND
        #10; // Wait for output to stabilize
        $display("Test Case 3 (AND) - Result: %h (Expected: 00000003)", alu_result);

        // Test Case 4: OR
        operand_a = 32'h0000000C;
        operand_b = 32'h00000003;
        alu_control = 4'b0001; // OR
        #10;
        $display("Test Case 4 (OR) - Result: %h (Expected: 0000000F)", alu_result);

        // Test Case 5: XOR
        operand_a = 32'h0000000F;
        operand_b = 32'h00000003;
        alu_control = 4'b0011; // XOR
        #10;
        $display("Test Case 5 (XOR) - Result: %h (Expected: 0000000C)", alu_result);

        // Test Case 6: SLL (Shift Left Logical)
        operand_a = 32'h00000001;
        operand_b = 32'h00000004;
        alu_control = 4'b0100; // SLL
        #10;
        $display("Test Case 6 (SLL) - Result: %h (Expected: 00000010)", alu_result);

        // Test Case 7: SRL (Shift Right Logical)
        operand_a = 32'h00000010;
        operand_b = 32'h00000002;
        alu_control = 4'b0101; // SRL
        #10;
        $display("Test Case 7 (SRL) - Result: %h (Expected: 00000004)", alu_result);

        // Test Case 8: SLT (Set Less Than)
        operand_a = 32'h00000002;
        operand_b = 32'h00000005;
        alu_control = 4'b0111; // SLT
        #10;
        $display("Test Case 8 (SLT) - Result: %h (Expected: 00000001)", alu_result);

        $finish;
    end
endmodule