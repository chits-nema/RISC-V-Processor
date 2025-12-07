module regfile(
    input clk,
    input reset_n,
    input we,
    input [4:0] a1,
    input [4:0] a2,
    input [4:0] a3,
    input [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
    );

    reg [31:0] registers [0:31];
    integer k;

    assign rd1 = registers[a1];
    assign rd2 = registers[a2];

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Clear all registers on reset
            for (k = 0; k < 32; k = k + 1) begin
                registers[k] <= 32'h00000000;
            end
        end else if (we) begin
            registers[a3] <= wd;
        end
    end
endmodule