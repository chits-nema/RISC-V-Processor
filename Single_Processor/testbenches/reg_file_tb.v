`include "../reg_file.v"
`timescale 1ns / 1ps

module reg_file_tb;
    reg clk;
    reg reset_n;  // Change from reset to reset_n
    reg rf_we;
    reg [4:0] read_reg1;
    reg [4:0] read_reg2;
    reg [4:0] write_reg;
    reg [31:0] write_data;
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Instantiate the reg_file module
    regfile RF (
        .clk(clk),
        .reset_n(reset_n),  // Change from reset to reset_n
        .we(rf_we),
        .a1(read_reg1),
        .a2(read_reg2),
        .a3(write_reg),
        .wd(write_data),
        .rd1(read_data1),
        .rd2(read_data2)
    );

    task init();
        begin
        // Initialize signals
        clk = 0;
        reset_n = 1;  // Active-low, so 1 = no reset, 0 = reset
        rf_we = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        end   
    endtask

    task reset_dut();
        begin
        // Apply reset (active low)
        reset_n = 0;
        #10;
        reset_n = 1;
        #10;
        end
    endtask

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("reg_file_tb.vcd");
        $dumpvars(0, reg_file_tb);

        init();
        reset_dut();

        // Test Case 1: Write data to register 1
        write_reg = 5'd1;
        write_data = 32'h12345678;
        rf_we = 1;
        #10; // Wait for clock edge

        // Test Case 2: Read back the data from register 1
        rf_we = 0;
        read_reg1 = 5'd1;
        #10; // Wait for clock edge
        $display("Test Case 2 - Read Data1: %h (Expected: 12345678)", read_data1);

        // Test Case 3: Write data to register 2
        write_reg = 5'd2;
        write_data = 32'h9ABCDEF0;
        rf_we = 1;
        #10; // Wait for clock edge

        // Test Case 4: Read back the data from register 2
        rf_we = 0;
        read_reg2 = 5'd2;
        #10; // Wait for clock edge
        $display("Test Case 4 - Read Data2: %h (Expected: 9ABCDEF0)", read_data2);      
        $finish;
    end 
endmodule