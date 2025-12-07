//mutiplexer module for immediate selection
module mux1(sel, A1, B1, mux_out);
    input sel;
    input [31:0] A1, B1;
    output [31:0] mux_out;

    assign mux_out = (sel == 1'b0)? A1 : B1;
endmodule

//multiplexer module for register file write address selection
module mux2(sel, A2, B2, mux_out2);
    input sel;
    input [4:0] A2, B2;
    output [4:0] mux_out2;

    assign mux_out2 = (sel == 1'b0)? A2 : B2;
endmodule