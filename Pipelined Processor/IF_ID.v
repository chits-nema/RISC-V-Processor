module if_id_reg(
    input clk, rst_n,
    input en, //F_stall
    input clr, //D_flush
    input [31:0] rd,
    input F_pc,
    input F_instr,
    input F_pc_plus_4,
    output reg D_pc,
    output reg D_instr,
    output reg D_pc_plus_4
);
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            //reset to NOP (addi x0, x0, 0)
            D_instr <= 32'h00000013;
            D_pc <= 32'h0;
            D_pc_plus_4 <= 32'h0;
        end else if (clr) begin
            //reset to NOP (addi x0, x0, 0)
            D_instr <= 32'h00000013;
            D_pc <= 32'h0;
            D_pc_plus_4 <= 32'h0;
        end else if (!en) begin
            D_instr <= F_instr;
            D_pc <= F_pc;
            D_pc_plus_4 <= F_pc_plus_4;
        end
        //else: Stall - keep current values(do nothing)
    end

endmodule