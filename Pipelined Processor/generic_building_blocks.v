module adder(
    input [31:0] a,b,
    output [31:0] y
);

    assign y = a+b;
endmodule

//resettable Flipflop
module flopr #(parameter WIDTH = 8)(
    input clk, reset,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk, posedge reset)begin
        if (reset) begin
            q<= 0;
        end else begin
            q<=d;
        end
    end

endmodule

//resettable flipflop with enable
module flopenr #(parameter WIDTH = 8)(
    input clk, reset,en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk, posedge reset)begin
        if (reset) begin
            q<= 0;
        end else if(en) begin
            q<=d;
        end
    end

endmodule