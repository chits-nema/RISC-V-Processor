module regfile(
    input clk,
    input we_rf,
    input [4:0] a1,
    input [4:0] a2,
    input [4:0] a3,
    input [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
    );

    //32 registers because rd(a3) is 5 bits
    reg [31:0] registers [0:31];


    //register 0 is always 0
    assign rd1 = (a1 == 5'b00000) ? 32'b0 : registers[a1];
    assign rd2 = (a2 == 5'b00000) ? 32'b0 : registers[a2];

    always @(posedge clk) begin
        registers[0] = 32'd0;

        //register 0 is read-only
        if (we_rf && (a3 != 5'b00000)) begin
            registers[a3] <= wd;
        end
    end
endmodule
