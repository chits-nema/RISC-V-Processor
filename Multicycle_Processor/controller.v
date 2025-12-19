`include "main_fsm.v"
module controller(
    input [6:0] op,
    input [2:0] funct3,
    input funct7_5,
    input clk,
    input reset,
    input Zero,
    output wire we_pc,
    output wire sel_mem_addr,
    output wire we_mem,
    output wire we_ir,
    output wire [1:0] sel_result,
    output reg [3:0] alu_control,
    output wire [1:0] sel_alu_src_a,
    output wire [1:0] sel_alu_src_b,
    output reg [2:0] sel_ext,
    output wire we_rf
);

    //intermediate wires from FSM
    wire [1:0] alu_op;
    wire branch, pc_update;

    
    //instantiate main FSM
    main_fsm fsm(
        .op(op),
        .clk(clk),
        .reset(reset),
        .Zero(Zero),
        .alu_op(alu_op),
        .branch(branch),
        .pc_update(pc_update),
        .we_pc(we_pc),
        .sel_mem_addr(sel_mem_addr),
        .we_mem(we_mem),
        .we_ir(we_ir),
        .sel_result(sel_result),
        .sel_alu_src_a(sel_alu_src_a),
        .sel_alu_src_b(sel_alu_src_b),
        .we_rf(we_rf)
    );


    //alu_op to alu_control decoding
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0000; //add
            2'b01: alu_control = 4'b0001; //sub
            2'b10: begin //R-type and I-type
                case (funct3)
                    3'b000: begin
                        // For I-type (op=0010011), always ADD. For R-type (op=0110011), check funct7_5
                        if (op == 7'b0010011) // I-type ADDI
                            alu_control = 4'b0000; // ADD
                        else // R-type ADD/SUB
                            alu_control = funct7_5 ? 4'b0001 : 4'b0000; // SUB or ADD
                    end
                    3'b001: alu_control = 4'b0110; //sll
                    3'b010: alu_control = 4'b0101; //slt
                    3'b011: alu_control = 4'b1001; //sltu
                    3'b100: alu_control = 4'b0100; //xor
                    3'b110: alu_control = 4'b0011; //or
                    3'b111: alu_control = 4'b0010; //and
                    3'b101: begin
                        // For both I-type and R-type shifts, use funct7_5/bit[30] to select SRA vs SRL
                        alu_control = funct7_5 ? 4'b1000 : 4'b0111; // SRA/SRAI or SRL/SRLI
                    end
                    default: alu_control = 4'b0000;
                endcase
            end
            default: alu_control = 4'bXXXX;
        endcase
    end

    //instruction decoding for immediate selection
    //5 cases therefore 3 bits
    always @(*) begin
        case (op)
            7'b0000011: sel_ext = 3'b000; //lw - I-type
            7'b0100011: sel_ext = 3'b001; //sw - S-type
            7'b1100011: sel_ext = 3'b010; //beq - B-type
            7'b0010011: sel_ext = 3'b000; //I-type
            7'b1101111: sel_ext = 3'b011; //jal - J-type
            7'b0110111: sel_ext = 3'b100; //lui - U-type
            default: sel_ext = 3'bXXX;
        endcase
    end

endmodule
