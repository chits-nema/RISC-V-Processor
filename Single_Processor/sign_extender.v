module sign_extender(
    input [2:0] sel_ext,
    input [31:7] in,
    output reg [31:0] out
    );

    //gonna assume negative numbers are in 2's complement

    always @(*) begin
        case (sel_ext)
            3'b000: begin //I-type: 12 bit immediate
                out = {{20{in[31]}}, in[31:20]}; //{a,b} is concatenation so result is a 32 bit value with a followed by b
            end
            3'b001: begin //S-type: 12 bit immediate
                out = {{20{in[31]}}, in[31:25], in[11:7]}; //{20{in[31]}} replicates the sign bit 20 times
            end
            3'b010: begin //B-type: 13 bit immediate
                out = {{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1'b0};
            end
            3'b011: begin //U-type: 20 bit immediate
                out = {in[31:12], 12'b0};
            end
            3'b100: begin //J-type: 21 bit immediate
                out = {{11{in[31]}}, in[31], in[19:12], in[20], in[30:21], 1'b0};
            end
            default: begin
                out = 32'b0;
            end
        endcase
    end
endmodule