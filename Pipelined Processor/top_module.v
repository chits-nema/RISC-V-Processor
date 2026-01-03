`include "riscv_single.v"
`include "data_mem.v"
`include "instruction_mem.v"
module top(
    input clk, reset,
    output [31:0] WriteData, DataAdr,
    output MemWrite
);

wire [31:0] PC;
wire [31:0] Instr, ReadData;
wire MemWrite;

//instantiate processor and memories
riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData);

imem imem(PC,Instr);
dmem dmem(clk,MemWrite,DataAdr,WriteData,ReadData);
endmodule