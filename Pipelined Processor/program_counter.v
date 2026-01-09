module pc(
    input wire clk,
    input wire rst,
    input wire en, //stallf signal to hold pc value
    input [31:0] pc_in,
    output reg [31:0] out
);

    always @(posedge clk or negedge rst) begin
        if (rst) begin
            out <= 32'b0;
        end else if (!en) begin
            out <= pc_in;
        end
    end

endmodule