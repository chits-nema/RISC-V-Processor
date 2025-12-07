`include "../data_mem.v"
`timescale 1ns / 1ps
module data_mem_tb;
    reg clk;
    reg reset_n;
    reg dmem_we;
    reg [31:0] address;
    reg [31:0] write_data;
    wire [31:0] read_data;

    // Instantiate the data_mem module
    data_mem DM (
        .clk(clk),
        .reset_n(reset_n),
        .we(dmem_we),
        .addr(address),
        .wd(write_data),
        .rd(read_data)
    );

    task init();
        begin
        // Initialize signals
        clk = 0;
        reset_n = 1;
        dmem_we = 0;
        address = 0;
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

    initial begin
        $dumpfile("data_mem_tb.vcd");
        $dumpvars(0, data_mem_tb);

        init();
        reset_dut();

        // Test Case 1: Write data to memory
        address = 32'h00000000;
        write_data = 32'hDEADBEEF;
        dmem_we = 1;
        #10; // Wait for clock edge

        // Test Case 2: Read back the data
        dmem_we = 0;
        #10; // Wait for clock edge
        $display("Test Case 2 - Read Data: %h (Expected: DEADBEEF)", read_data);

        // Test Case 3: Write another data to different address
        address = 32'h00000004;
        write_data = 32'hCAFEBABE;
        dmem_we = 1;
        #10; // Wait for clock edge

        // Test Case 4: Read back the new data
        dmem_we = 0;
        address = 32'h00000004;
        #10; // Wait for clock edge
        $display("Test Case 4 - Read Data: %h (Expected: CAFEBABE)", read_data);

        $finish;
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
endmodule

