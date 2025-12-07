//top module is where all the submodules are instantiated like a testbench
`include "program_counter.v"
`include "instr_mem.v"
`include "reg_file.v"
`include "data_mem.v"
`include "alu.v"
`include "controller.v"
`include "sign_extender.v"
`include "multiplexer.v"
module riscv_single_cycle(
    input clk,
    input reset

);
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] mux_out1;
    wire [31:0] mux_out2;
    wire [31:0] alu_out;
    wire [31:0] rd1;
    wire [31:0] rd2;    
    wire [31:0] rd;
    wire [3:0] alu_control;
    wire [2:0] sel_ext;
    wire [31:0] se_out;
    wire sel_alu_src_b;
    wire rf_we;
    wire dmem_we;
    wire [1:0] sel_result;
    wire Zero;

    // PC + 4 calculation
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = pc_out + 32'd4;

    // Branch logic
    wire branch_taken;
    assign branch_taken = (instr_out[6:0] == 7'b1100011) && Zero; // Branch opcode AND Zero flag

    wire [31:0] pc_target;
    assign pc_target = pc_out + se_out; // PC + branch/jump offset

    wire [31:0] pc_next;
    assign pc_next = branch_taken ? pc_target : pc_plus_4;

    //Instantiate Program Counter
    program_counter PC ( .clk(clk),
                         .present_val(pc_next),
                         .load_en(branch_taken),
                         .reset_n(reset),
                         .pc_out(pc_out)
                       );

    
    //Instantiate Instruction Memory
    instruction_mem IM (.read_address(pc_out),
                   .instr_out(instr_out)
                 );

    // 4-input mux for register write data
    reg [31:0] result_to_rf;
    always @(*) begin
        case (sel_result)
            2'b00: result_to_rf = alu_out;      // ALU result (normal ops)
            2'b01: result_to_rf = rd;           // Data memory (loads)
            2'b10: result_to_rf = pc_plus_4;    // PC+4 (JAL)
            2'b11: result_to_rf = se_out;       // Sign extender (LUI)
            default: result_to_rf = alu_out;
        endcase
    end

    //Instantiate register File
    regfile RF ( .clk(clk),
                     .reset_n(reset),
                     .we(rf_we),
                     .a1(instr_out[19:15]),
                     .a2(instr_out[24:20]),
                     .a3(instr_out[11:7]),
                     .wd(result_to_rf),          // Write data selected by mux
                     .rd1(rd1),
                     .rd2(rd2)
                   );

    //Instantiate Sign Extender
    sign_extender SE ( .sel_ext(sel_ext),
                       .in(instr_out[31:7]),
                       .out(se_out)
                     );
                    
    //Instantiate ALU Mux
    mux1 ALU_MUX ( .sel(sel_alu_src_b),
                        .A1(rd2),
                        .B1(se_out),
                        .mux_out(mux_out1)
                    );

    //Instantiate ALU
    alu ALU_UNIT ( .A(rd1),
                   .B(mux_out1),
                   .alu_control(alu_control),
                   .alu_out(alu_out),
                   .Zero(Zero)
                 );

    //Instantiate Data Memory
    data_mem DM ( .clk(clk),
                  .reset_n(reset),
                  .we(dmem_we),
                  .addr(alu_out),
                  .wd(rd2),
                  .rd(rd)
                );

    //Instantiate Controller
    controller CTRL ( .opcode(instr_out[6:0]),
                      .funct3(instr_out[14:12]),
                      .funct7_5(instr_out[30]),
                      .alu_control(alu_control),
                      .sel_ext(sel_ext),
                      .sel_alu_src_b(sel_alu_src_b),
                      .rf_we(rf_we),
                      .dmem_we(dmem_we),
                      .sel_result(sel_result)
                    );

endmodule