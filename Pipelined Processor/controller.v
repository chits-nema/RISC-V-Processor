`include "ALU_Decoder.v"
`include "main_decoder.v"

module controller(
    input [6:0] op,
    input [2:0] funct3,
    input funct7b5,
    input Zero,
    output [1:0] ResultSrc,
    output MemWrite,
    output PCSrc, ALUSrc,
    output RegWrite, Jump,
    output [2:0] ImmSrc,
    output [3:0] ALUControl,
    output ALUSrcA
);

    wire [1:0] ALUOp;
    wire Branch;

    maindec md(.op(op), .ResultSrc(ResultSrc), .MemWrite(MemWrite), .Branch(Branch), .ALUSrc(ALUSrc), .RegWrite(RegWrite), .Jump(Jump), .ImmSrc(ImmSrc), .ALUOp(ALUOp), .ALUSrcA(ALUSrcA));
    aludec ad(op[5], funct3, funct7b5, ALUOp, ALUControl);
    assign PCSrc = Branch & Zero | Jump;


endmodule