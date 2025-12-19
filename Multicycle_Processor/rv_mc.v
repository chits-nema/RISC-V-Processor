`include "controller.v"
`include "mem.v"
`include "multiplexer.v"
`include "register_file.v"
`include "sign_extender.v"
`include "alu.v"

module rv_mc (
    input clk,
    input rst
);

    //declaration of non-architectural registers
    reg [31:0] PC_reg;
    reg [31:0] instr_reg;
    reg [31:0] data_reg;
    reg [31:0] rd1_reg;
    reg [31:0] rd2_reg;
    reg [31:0] alu_reg;
    reg [31:0] old_pc_reg;
    
    

    //control unit wires (outputs that connect controller to other units)
    wire we_pc;
    wire sel_mem_addr;
    wire we_mem;
    wire we_ir;
    wire [1:0] sel_result;
    wire [3:0] alu_control;
    wire [1:0] sel_alu_src_a;
    wire [1:0] sel_alu_src_b;
    wire [2:0] sel_ext;
    wire we_rf;

    //other wires connecting componnents -> Usually outputs of components
    //mem
    wire [31:0] RD;
    //reg file
    wire [31:0] rd1;
    wire [31:0] rd2;
    //multiplexer outs
    wire [31:0] addr;
    wire [31:0] SrcA;
    wire [31:0] SrcB;
    wire [31:0] Result;
    //alu outs
    wire [31:0] AluResult;
    wire  Zero;
    //sign extender output
    wire [31:0] ImmExt;

    //mutiplexer implemetations
    //srcA multiplexer (4:1)
    mux_4 SRCA(
        .sel(sel_alu_src_a),
        .A(PC_reg),
        .B(old_pc_reg),
        .C(rd1_reg),
        .D(32'd0),
        .out(SrcA)
    );
    
    //srcB multiplexer (3:1)
    mux SRCB(
        .sel(sel_alu_src_b),
        .A(rd2_reg),
        .B(ImmExt),
        .C(32'd4),
        .out(SrcB)
    );

    //initialisation of ALU
    alu ALU(
        .A(SrcA),
        .B(SrcB),
        .alu_control(alu_control),
        .alu_out(AluResult),
        .Zero(Zero)
    );

    //result multiplexer (3:1)
    mux RESULTMUX(
        .sel(sel_result),
        .A(alu_reg),
        .B(data_reg),
        .C(AluResult),  //direct result from wire(alu)
        .out(Result)
    );

    //memory multiplexer
    assign addr = sel_mem_addr ? Result : PC_reg;
    
    //mem initialisation
    mem MEM(
        .clk(clk),
        .A(addr),
        .WD(rd2_reg),
        .we_mem(we_mem),
        .RD(RD)
    );

    //register file initialisation
    regfile REGFILE(
        .clk(clk),
        .we_rf(we_rf),
        .a1(instr_reg[19:15]),
        .a2(instr_reg[24:20]),
        .a3(instr_reg[11:7]),
        .wd(Result),
        .rd1(rd1),
        .rd2(rd2)
    );

    //sign extender initialisation
    sign_extender SIGEXT(
        .sel_ext(sel_ext),
        .in(instr_reg[31:7]),
        .out(ImmExt)
    );

    controller CTRL(
        .op(instr_reg[6:0]),
        .funct3(instr_reg[14:12]),
        .funct7_5(instr_reg[30]),
        .clk(clk),
        .reset(rst),
        .Zero(Zero),
        .we_pc(we_pc),
        .sel_mem_addr(sel_mem_addr),
        .we_mem(we_mem),
        .we_ir(we_ir),
        .sel_result(sel_result),
        .alu_control(alu_control),
        .sel_alu_src_a(sel_alu_src_a),
        .sel_alu_src_b(sel_alu_src_b),
        .sel_ext(sel_ext),
        .we_rf(we_rf)
    );

    //updating of non-architectural registers
    always @(posedge clk) begin
        //controller enabled updating
        if (we_ir) begin
            instr_reg <= RD;
            old_pc_reg <= PC_reg;  //capture PC of the instruction being fetched
        end 
        //clock dependant updating
        data_reg <= RD;
        alu_reg <= AluResult;
        rd1_reg <= rd1;
        rd2_reg <= rd2;
    end

    //PC updating
    always @(posedge clk) begin
        if (rst) begin
            PC_reg = 32'd0;
        end else if (we_pc) begin
            PC_reg <= Result;
        end
    end

endmodule
