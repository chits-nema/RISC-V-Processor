`include "generic_building_blocks.v"
`include "multiplexer.v"
`include "extend_unit.v"
`include "alu.v"
`include "reg_file.v"

module datapath (
    input clk, reset,
    input [1:0] ResultSrc,
    input PCSrc, ALUSrc,
    input RegWrite,
    input [2:0] ImmSrc,
    input [3:0] ALUControl,
    input ALUSrcA,
    output Zero,
    output [31:0] PC,
    input [31:0] Instr,
    output [31:0] ALUResult, WriteData,
    input [31:0] ReadData
);

    wire [31:0] PCNext, PCPlus4,PCTarget;
    wire [31:0] ImmExt;
    wire [31:0] SrcA, SrcB;
    wire [31:0] Result;
    wire [31:0] SrcA_ALU;

    //next PC logic
    flopr #(32) pcreg(clk, reset, PCNext, PC);
    adder pcadd4(PC, 32'd4, PCPlus4);
    adder pcaddbranch(PC, ImmExt, PCTarget);
    mux2 #(32) pcmux(PCPlus4, PCTarget, PCSrc, PCNext);

    //register file logic
    regfile rf(clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
    extend ext(Instr[31:7], ImmSrc, ImmExt);

    //ALU logic
    mux2 #(32) srcamux(SrcA, 32'b0, ALUSrcA, SrcA_ALU);
    mux2 #(32) srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
    alu        alu(SrcA_ALU, SrcB, ALUControl, ALUResult, Zero);
    mux3 #(32) resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);


endmodule