module sign_extender(
    input [2:0] sel_ext,
    input [31:7] in,
    output reg [31:0] out
    );

    //gonna assume negative numbers are in 2's complement

    always @(*) begin
        case (sel_ext)
            //I-type: 12-bit signed immediate -> alu i type instructions and lw
            3'b000: out = {{20{in[31]}}, in[31:20]}; //{a,b} is concatenation so result is a 32 bit value with a followed by b
            //S-type: 12-bit signed immediate -> sw instruction
            3'b001: out = {{20{in[31]}}, in[31:25], in[11:7]};
            //B-type: 13-bit signed immediate -> beq instruction
            3'b010: out = {{20{in[31]}}, in[7], in[30:25], in[11:8], 1'b0};
            //J-type: 21-bit signed immediate -> jal instruction
            3'b011: out = {{12{in[31]}}, in[19:12], in[20], in[30:21], 1'b0};
            //U-type: 20 bit immediate -> lui instruction
            3'b100: out = {in[31:12],12'b0};
            default: out = 32'b0;
        endcase
    end



endmodule
