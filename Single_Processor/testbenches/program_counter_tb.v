`include "../program_counter.v"
`timescale 1ns / 1ps

module program_counter_tb;
    reg clk;
    reg [31:0] present_val;
    reg load_en;
    reg reset_n;
    wire [31:0] pc_out;

    // Instantiate the program_counter module
    program_counter PC (
        .clk(clk),
        .present_val(present_val),
        .load_en(load_en),
        .reset_n(reset_n),
        .pc_out(pc_out)
    );

    task init();
        begin
        // Initialize signals
        clk = 0;
        present_val = 0;
        load_en = 0;
        end   
    endtask

    task reset_dut();
        begin
        // Apply reset
        reset_n = 0;
        #10;
        reset_n = 1;
        #10;
        end
    endtask

    initial begin
        $dumpfile("program_counter_tb.vcd");
        $dumpvars(0, program_counter_tb);

        init();
        reset_dut();

        // Test Case 1: Normal increment
        present_val = 32'h00000000;
        load_en = 0;
        #10; // Wait for clock edge
        $display("Test Case 1 - PC: %h (Expected: 00000004)", pc_out);

        // Test Case 2: Load new value
        present_val = 32'h00000010;
        load_en = 1;
        #10; // Wait for clock edge
        $display("Test Case 2 - PC: %h (Expected: 00000010)", pc_out);

        // Test Case 3: Increment after load
        load_en = 0;
        #10; // Wait for clock edge
        $display("Test Case 3 - PC: %h (Expected: 00000014)", pc_out);

        // Test Case 4: Another increment
        #10; // Wait for clock edge
        $display("Test Case 4 - PC: %h (Expected: 00000018)", pc_out);

        $finish;
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
endmodule
