`include "generic_building_blocks.v"
`include "multiplexer.v"
`include "extend_unit.v"
`include "alu.v"
`include "reg_file.v"
`include "hazard_unit.v"

module datapath (
   input clk, reset,
   input [1:0] ResultSrc,
   input Branch, ALUSrcBSel, RegWrite, Jump, MemWrite_ctrl,
   input [2:0] ImmSrc,
   input [3:0] ALUControl,
   input ALUSrcASel,
   output Zero,
   output [31:0] PC,
   input [31:0] Instr,
   output [31:0] ALUResult, WriteData,
   output MemWrite,
   input [31:0] ReadData,
   output [31:0] InstrID);

   // Hazard detection signals
   wire stallF, stallD, ForwardAD, ForwardBD, flush_e;
   wire [1:0] ForwardAE, ForwardBE;
   
   // Forward declarations for signals needed in earlier stages
   wire [31:0] ALUOutM;  // Used for forwarding in decode stage

   // ============================= FETCH STAGE =============================
   wire [31:0] PCF, PCPlus4F, PCNext;
   wire [31:0] pcen, pcen2;
   wire [31:0] PCBranchD, PCJumpD;
   wire PCSrcD;
   
   assign PCPlus4F = PCF + 4;

   // PC selection muxes
   mux #(32) pc_branch_mux(PCPlus4F, PCBranchD, PCSrcD, pcen);
   mux #(32) pc_jump_mux(pcen, PCJumpD, Jump, pcen2);
   
   // PC register
   flopenr #(32) pc_reg(clk, reset, ~stallF, pcen2, PCF);
   
   assign PC = PCF;

   // ======================= IF/ID PIPELINE REGISTER =======================
   wire [31:0] instrD, PCPlus4D;
   wire PCSrcD_ext;
   
   flopenr #(32) ifid_instr (clk, reset | PCSrcD_ext, ~stallD, Instr, instrD);
   flopenr #(32) ifid_pcplus4 (clk, reset | PCSrcD_ext, ~stallD, PCPlus4F, PCPlus4D);
   flopenr #(1)  flush_reg (~clk, reset, 1'b1, PCSrcD | Jump, PCSrcD_ext);
   
   assign InstrID = instrD;

   // ============================= DECODE STAGE =============================
   wire [31:0] RD1, RD2, SignImmD;
   wire [4:0] RsD, RtD, RdD;
   wire [31:0] rd1_comp, rd2_comp;
   wire EqualD;
   wire [4:0] WriteRegW;
   wire [31:0] ResultW;
   wire RegWriteW;
   
   // Instruction fields
   assign RsD = instrD[25:21];
   assign RtD = instrD[20:16];
   assign RdD = instrD[15:11];
   
   // Register file
   regfile rf(clk, RegWriteW, RsD, RtD, WriteRegW, ResultW, RD1, RD2);
   
   // Extend unit
   extend ext(instrD[31:7], ImmSrc, SignImmD);
   
   // Branch comparison with forwarding
   mux2 #(32) forward_ad_mux(RD1, ALUOutM, ForwardAD, rd1_comp);
   mux2 #(32) forward_bd_mux(RD2, ALUOutM, ForwardBD, rd2_comp);
   assign EqualD = (rd1_comp == rd2_comp);
   assign PCSrcD = EqualD & Branch;
   
   // Branch and jump target calculation
   assign PCBranchD = (SignImmD << 2) + PCPlus4D;
   assign PCJumpD = {PCPlus4D[31:28], instrD[25:0], 2'b00};

   // ======================= ID/EX PIPELINE REGISTER =======================
   wire RegWriteE, MemtoRegE, MemWriteE, ALUSrcE, RegDstE;
   wire [3:0] ALUControlE;
   wire [31:0] RD1_E, RD2_E, SignImmE;
   wire [4:0] RsE, RtE, RdE;
   wire Jump2;
   
   // Control signals
   flopenr #(1) idex_regwrite (clk, reset | flush_e | Jump2, 1'b1, RegWrite, RegWriteE);
   flopenr #(1) idex_memtoreg (clk, reset, 1'b1, ResultSrc[0], MemtoRegE);
   flopenr #(1) idex_memwrite (clk, reset | flush_e | Jump2, 1'b1, MemWrite_ctrl, MemWriteE);
   flopenr #(4) idex_alucontrol (clk, reset, 1'b1, ALUControl, ALUControlE);
   flopenr #(1) idex_alusrc (clk, reset, 1'b1, ALUSrcBSel, ALUSrcE);
   flopenr #(1) idex_regdst (clk, reset, 1'b1, ResultSrc[1], RegDstE);
   flopenr #(1) idex_jump (clk, reset, 1'b1, Jump, Jump2);
   
   // Data signals
   flopenr #(32) idex_rd1 (clk, reset, 1'b1, RD1, RD1_E);
   flopenr #(32) idex_rd2 (clk, reset, 1'b1, RD2, RD2_E);
   flopenr #(32) idex_signimm (clk, reset, 1'b1, SignImmD, SignImmE);
   flopenr #(5) idex_rs (clk, reset | flush_e | Jump2, 1'b1, RsD, RsE);
   flopenr #(5) idex_rt (clk, reset | flush_e | Jump2, 1'b1, RtD, RtE);
   flopenr #(5) idex_rd (clk, reset | flush_e | Jump2, 1'b1, RdD, RdE);

   // ============================ EXECUTE STAGE =============================
   wire [31:0] SrcAE, SrcBE, WriteDataE, ALUOutE;
   wire [4:0] WriteRegE;
   wire zero;
   
   // Forwarding muxes
   mux4 #(32) forward_ae_mux(RD1_E, ResultW, ALUOutM, 32'b0, ForwardAE, SrcAE);
   mux4 #(32) forward_be_mux(RD2_E, ResultW, ALUOutM, 32'b0, ForwardBE, WriteDataE);
   
   // ALU source mux (immediate vs register)
   mux2 #(32) alusrc_mux(WriteDataE, SignImmE, ALUSrcE, SrcBE);
   
   // ALU
   alu alu_inst(SrcAE, SrcBE, ALUControlE, ALUOutE, zero);
   assign Zero = zero;
   
   // Write register mux (rt vs rd)
   mux2 #(5) writereg_mux(RtE, RdE, RegDstE, WriteRegE);

   // ====================== EX/MEM PIPELINE REGISTER =======================
   wire RegWriteM, MemtoRegM, MemWriteM;
   wire [31:0] WriteDataM;
   wire [4:0] WriteRegM;
   
   // Control signals
   flopenr #(1) exmem_regwrite (clk, reset, 1'b1, RegWriteE, RegWriteM);
   flopenr #(1) exmem_memtoreg (clk, reset, 1'b1, MemtoRegE, MemtoRegM);
   flopenr #(1) exmem_memwrite (clk, reset, 1'b1, MemWriteE, MemWriteM);
   
   // Data signals
   flopenr #(32) exmem_aluout (clk, reset, 1'b1, ALUOutE, ALUOutM);
   flopenr #(32) exmem_writedata (clk, reset, 1'b1, WriteDataE, WriteDataM);
   flopenr #(5) exmem_writereg (clk, reset, 1'b1, WriteRegE, WriteRegM);
   
   assign ALUResult = ALUOutM;
   assign WriteData = WriteDataM;
   assign MemWrite = MemWriteM;

   // ============================= MEMORY STAGE =============================
   // Data memory is external to datapath

   // ====================== MEM/WB PIPELINE REGISTER =======================
   wire MemtoRegW;
   wire [31:0] ReadDataW, ALUOutW;
   
   // Control signals
   flopenr #(1) memwb_regwrite (clk, reset, 1'b1, RegWriteM, RegWriteW);
   flopenr #(1) memwb_memtoreg (clk, reset, 1'b1, MemtoRegM, MemtoRegW);
   
   // Data signals
   flopenr #(32) memwb_readdata (clk, reset, 1'b1, ReadData, ReadDataW);
   flopenr #(32) memwb_aluout (clk, reset, 1'b1, ALUOutM, ALUOutW);
   flopenr #(5) memwb_writereg (clk, reset, 1'b1, WriteRegM, WriteRegW);

   // ========================== WRITEBACK STAGE ============================
   mux2 #(32) result_mux(ALUOutW, ReadDataW, MemtoRegW, ResultW);

   // ========================= HAZARD CONTROL UNIT =========================
   hazard haz(
      Branch, MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW,
      RsD, RtD, RsE, RtE, WriteRegE, WriteRegM, WriteRegW,
      stallF, stallD, ForwardAD, ForwardBD, flush_e, ForwardAE, ForwardBE,
      clk, reset);

endmodule