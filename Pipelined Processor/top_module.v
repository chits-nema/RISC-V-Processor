module rv_pl(
    input clk,
    input rst_n
);

//----------------------------------------------------FETCH-------------------------------------
wire [31:0] F_pc_next;
wire [31:0] F_pc;
wire [31:0] F_pc_plus_4;
wire [31:0] F_instr;
wire stallF;

//-----------------------------------------------------DECODE------------------------------------
wire [31:0] D_instr;
wire D_stall, D_flush;
wire [31:0] D_pc;
wire [4:0] D_Rs1; //19:15
wire [4:0] D_Rs2; //24:20
wire [4:0] D_Rd;  //11:7
wire [31:0] D_ImmExt;
wire [31:0] D_pc_plus_4;
wire [1:0] D_ResultSrc;
wire D_MemWrite;
wire D_Branch, D_ALUSrcBSel;
wire D_RegWrite, D_Jump;
wire [2:0] D_ImmSrc;
wire [3:0] D_ALUControl;
wire D_ALUSrcASel;
wire [31:0] D_RD1;
wire [31:0] D_RD2;

//-------------------------------------------------------EXECUTE---------------------------------------------
wire [31:0] E_pc;
wire [4:0] E_Rs1; //19:15
wire [4:0] E_Rs2; //24:20
wire [4:0] E_Rd;  //11:7
wire [31:0] E_ImmExt;
wire [31:0] E_pc_plus_4;
wire [1:0] E_ResultSrc;
wire E_MemWrite;
wire E_Branch, E_ALUSrcBSel;
wire E_RegWrite, E_Jump;
wire [3:0] E_ALUControl;
wire E_ALUSrcASel;
wire E_PCSrc;
wire E_Zero;
wire [31:0] E_SrcA, E_SrcB;
wire [31:0] E_WriteData;
wire E_pcTarget;
wire [31:0] E_ALUResult;
wire [1:0] E_ForwardA, E_ForwardB;
wire E_flush;

//---------------------------------------------------------MEMORY----------------------------------------------
wire M_RegWrite;
wire [1:0] M_ResultSrc;
wire M_MemWrite;
wire [31:0] M_ALUResult;
wire [31:0] M_WriteData;
wire [4:0] M_Rd;
wire [31:0] M_pc_plus_4;
wire [31:0] M_ReadDataW;

//-----------------------------------------------------------WRITEBACK----------------------------------------------------
wire W_RegWrite;
wire [1:0] W_ResultSrc;
wire [31:0] W_ALUResult;
wire [31:0] W_ReadData;
wire [4:0] W_Rd;
wire [31:0] W_Result;
wire [31:0] W_pc_plus_4;

//Hazard control sigsnals
wire [1:0] ForwardAE, ForwardBE;
wire PC_Src;




endmodule