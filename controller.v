module controller(
    input [6:0] opcode,
    input [2:0] funct3,
    input funct7_5,
    output reg [3:0] alu_control,
    output reg [2:0] sel_ext,
    output reg sel_alu_src_b,
    output reg rf_we,
    output reg dmem_we,
    output reg [1:0] sel_result);

    reg [1:0] alu_op;

    //first level decoder
    always @(*) begin
        alu_op = 2'b00;
        sel_ext = 3'b000;
        sel_alu_src_b = 1'b0;
        rf_we = 1'b0;
        dmem_we = 1'b0;
        sel_result = 2'b00;
        
        case (opcode)
            7'b0110011: begin //R-type
                alu_op = 2'b01;
                rf_we = 1'b1;
            end
            7'b0010011: begin //I-type
                alu_op = 2'b10;
                sel_alu_src_b = 1'b1;
                rf_we = 1'b1;
            end
            7'b0000011: begin //Load
                alu_op = 2'b00;
                sel_alu_src_b = 1'b1;
                sel_ext = 3'b000;
                rf_we = 1'b1;
                sel_result = 2'b01; //Select data memory
            end
            7'b0100011: begin //Store
                alu_op = 2'b00;
                sel_alu_src_b = 1'b1;
                sel_ext = 3'b001;
                dmem_we = 1'b1;
            end
            7'b1100011: begin //Branch
                alu_op = 2'b01; //Use SUB for comparison
                sel_ext = 3'b010;
                sel_alu_src_b = 1'b0; //Compare two registers (rs1 - rs2)
            end
            7'b1101111: begin //JAL
                alu_op = 2'b00;
                sel_ext = 3'b100;
                rf_we = 1'b1;
                sel_result = 2'b10; //Select PC+4
            end
            7'b0110111: begin //LUI
                sel_ext = 3'b011;      // U-type format
                rf_we = 1'b1;          // Write to register
                sel_result = 2'b11;    // Select sign extender output directly (bypass ALU)
            end
            default: begin
                //NOP or unsupported instruction
                
            end
        endcase
    end

    //second level decoder
    always @(*)begin
        alu_control = 4'b0000; //default NOP
        case (alu_op)
            2'b00: begin //Load/Store/JAL
                alu_control = 4'b0010; //ADD
            end
            2'b01: begin //R-type and Branch
                // For branches (opcode 1100011), always use SUB to set Zero flag
                if (opcode == 7'b1100011) begin
                    alu_control = 4'b0110; //SUB for all branches
                end else begin
                    // R-type instructions
                    case ({funct7_5, funct3})
                        4'b0000: alu_control = 4'b0010; //ADD
                        4'b1000: alu_control = 4'b0110; //SUB
                        4'b0111: alu_control = 4'b1110; //AND
                        4'b0110: alu_control = 4'b0001; //OR
                        4'b0100: alu_control = 4'b0011; //XOR
                        4'b0001: alu_control = 4'b0100; //SLL
                        4'b0101: alu_control = 4'b0101; //SRL
                        4'b1101: alu_control = 4'b1000; //SRA
                        4'b0010: alu_control = 4'b0111; //SLT
                        default: alu_control = 4'b0000; //NOP
                    endcase
                end
            end
            2'b10: begin //I-type
                case (funct3)
                    3'b000: alu_control = 4'b0010; //ADD (ADDI)
                    3'b111: alu_control = 4'b1110; //AND (ANDI)
                    3'b110: alu_control = 4'b0001; //OR (ORI)
                    3'b100: alu_control = 4'b0011; //XOR (XORI)
                    3'b001: alu_control = 4'b0100; //SLL (SLLI)
                    3'b101: begin
                        if (funct7_5 == 1'b0)
                            alu_control = 4'b0101; //SRL (SRLI)
                        else
                            alu_control = 4'b1000; //SRA (SRAI)
                    end
                    3'b010: alu_control = 4'b0111; //SLT (SLTI)
                    default: alu_control = 4'b0000; //NOP
                endcase
            end
            2'b11: begin //LUI (pass-through B)
                alu_control = 4'b1111; //Pass-through
            end
            default: begin
                alu_control = 4'b0000; //NOP
            end
        endcase
    end
endmodule