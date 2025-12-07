`include "../controller.v"
`timescale 1ns / 1ps

module controller_tb;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg funct7_5;
    wire [3:0] alu_control;
    wire [2:0] sel_ext;
    wire sel_alu_src_b;
    wire rf_we;
    wire dmem_we;
    wire [1:0] sel_result;

    // Instantiate the controller module
    controller CTRL (
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .alu_control(alu_control),
        .sel_ext(sel_ext),
        .sel_alu_src_b(sel_alu_src_b),
        .rf_we(rf_we),
        .dmem_we(dmem_we),
        .sel_result(sel_result)
    );

    task init();
        begin
        opcode = 7'b0000000;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        end   
    endtask

    initial begin
        $dumpfile("controller_tb.vcd");
        $dumpvars(0, controller_tb);

        init();
        #10;

        // Test R-type instructions
        $display("\n=== R-Type Instructions ===");
        
        // ADD (R-type)
        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #10;
        $display("ADD: alu_ctrl=%b (exp:0010), rf_we=%b, sel_alu_src_b=%b", 
                 alu_control, rf_we, sel_alu_src_b);

        // SUB (R-type)
        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7_5 = 1'b1;
        #10;
        $display("SUB: alu_ctrl=%b (exp:0110), rf_we=%b", alu_control, rf_we);

        // AND (R-type)
        opcode = 7'b0110011;
        funct3 = 3'b111;
        funct7_5 = 1'b0;
        #10;
        $display("AND: alu_ctrl=%b (exp:1110), rf_we=%b", alu_control, rf_we);

        // OR (R-type)
        opcode = 7'b0110011;
        funct3 = 3'b110;
        funct7_5 = 1'b0;
        #10;
        $display("OR: alu_ctrl=%b (exp:0001), rf_we=%b", alu_control, rf_we);

        // Test I-type instructions
        $display("\n=== I-Type Instructions ===");
        
        // ADDI
        opcode = 7'b0010011;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #10;
        $display("ADDI: alu_ctrl=%b (exp:0010), rf_we=%b, sel_alu_src_b=%b, sel_ext=%b", 
                 alu_control, rf_we, sel_alu_src_b, sel_ext);

        // ORI
        opcode = 7'b0010011;
        funct3 = 3'b110;
        funct7_5 = 1'b0;
        #10;
        $display("ORI: alu_ctrl=%b (exp:0001), rf_we=%b, sel_alu_src_b=%b", 
                 alu_control, rf_we, sel_alu_src_b);

        // ANDI
        opcode = 7'b0010011;
        funct3 = 3'b111;
        funct7_5 = 1'b0;
        #10;
        $display("ANDI: alu_ctrl=%b (exp:1110), rf_we=%b", alu_control, rf_we);

        // Test Load instruction
        $display("\n=== Load Instructions ===");
        opcode = 7'b0000011;
        funct3 = 3'b010; // LW
        funct7_5 = 1'b0;
        #10;
        $display("LW: alu_ctrl=%b (exp:0010), rf_we=%b, dmem_we=%b, sel_result=%b, sel_alu_src_b=%b, sel_ext=%b", 
                 alu_control, rf_we, dmem_we, sel_result, sel_alu_src_b, sel_ext);

        // Test Store instruction
        $display("\n=== Store Instructions ===");
        opcode = 7'b0100011;
        funct3 = 3'b010; // SW
        funct7_5 = 1'b0;
        #10;
        $display("SW: alu_ctrl=%b (exp:0010), dmem_we=%b, rf_we=%b, sel_alu_src_b=%b, sel_ext=%b", 
                 alu_control, dmem_we, rf_we, sel_alu_src_b, sel_ext);

        // Test Branch instruction
        $display("\n=== Branch Instructions ===");
        opcode = 7'b1100011;
        funct3 = 3'b000; // BEQ
        funct7_5 = 1'b0;
        #10;
        $display("BEQ: alu_ctrl=%b (exp:0110 for SUB), rf_we=%b, sel_ext=%b", 
                 alu_control, rf_we, sel_ext);

        // Test JAL instruction
        $display("\n=== Jump Instructions ===");
        opcode = 7'b1101111;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #10;
        $display("JAL: rf_we=%b, sel_result=%b, sel_ext=%b", 
                 rf_we, sel_result, sel_ext);

        // Test LUI instruction
        $display("\n=== Upper Immediate Instructions ===");
        opcode = 7'b0110111;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #10;
        $display("LUI: rf_we=%b, sel_alu_src_b=%b, sel_result=%b, sel_ext=%b", 
                 rf_we, sel_alu_src_b, sel_result, sel_ext);

        $finish;
    end
endmodule
