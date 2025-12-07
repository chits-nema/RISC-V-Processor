`include "../multiplexer.v"
`timescale 1ns / 1ps

module multiplexer_tb;
    reg [31:0] in0;
    reg [31:0] in1;
    reg sel;
    wire [31:0] out;

    // Instantiate the multiplexer module
    mux1 MUX (
        .A1(in0),
        .B1(in1),
        .sel(sel),
        .mux_out(out)
    );

    task init();
        begin
        // Initialize signals
        in0 = 0;
        in1 = 0;
        sel = 0;
        end   
    endtask

    initial begin
        $dumpfile("multiplexer_tb.vcd");
        $dumpvars(0, multiplexer_tb);

        init();

        // Test Case 1: Select in0
        in0 = 32'hAAAAAAAA;
        in1 = 32'h55555555;
        sel = 0;
        #10; // Wait for output to stabilize
        $display("Test Case 1 - Output: %h (Expected: AAAAAAAA)", out);

        // Test Case 2: Select in1
        sel = 1;
        #10; // Wait for output to stabilize
        $display("Test Case 2 - Output: %h (Expected: 55555555)", out);

        $finish;
    end
endmodule
