//PC counter works like this -> new instruction...Pc + 4
module program_counter(
    input clk,
    input [31:0] present_val,
    input load_en,
    input reset_n,
    output reg [31:0] pc_out
);

    wire[31:0] sum; 

    always@(posedge clk or negedge reset_n)
    begin
        if (~reset_n)begin
            pc_out <= 32'h00000000;
        end   else begin
            pc_out <= present_val; // present_val is already PC+4 or branch target
        end
    end

endmodule