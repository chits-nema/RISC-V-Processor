`include "datapath.v"
`include "controller.v"

module riscvsingle(
    input clk, reset,
    output [31:0] PC,
    input [31:0] Instr,
    output MemWrite,
    output [31:0] ALUResult, WriteData, 
    input [31:0] ReadData
);

wire ALUSrcBSel, RegWrite, Jump, Zero, PCSrc, ALUSrcASel, Branch;
wire MemWrite_ctrl;  // Control signal from controller
wire [1:0] ResultSrc;
wire [2:0] ImmSrc;
wire [3:0] ALUControl;
wire [31:0] InstrID;  // Instruction in ID stage

// Controller decodes the instruction in the ID stage (InstrID)
controller c(InstrID[6:0], InstrID[14:12], InstrID[30], Zero, ResultSrc, MemWrite_ctrl, Branch, ALUSrcBSel, RegWrite, Jump, ImmSrc, ALUControl, ALUSrcASel, PCSrc);

// Datapath with integrated pipeline registers
datapath dp(clk, reset, ResultSrc, Branch, ALUSrcBSel, RegWrite, Jump, MemWrite_ctrl, ImmSrc, ALUControl, ALUSrcASel, Zero, PC, Instr, ALUResult, WriteData, MemWrite, ReadData, InstrID);

endmodule

