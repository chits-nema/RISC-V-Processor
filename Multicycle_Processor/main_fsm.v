module main_fsm(
    input [6:0] op,
    input clk,
    input reset,
    input Zero,
    output reg [1:0] alu_op,
    output reg branch,
    output reg pc_update,
    output reg we_pc,
    output reg sel_mem_addr,
    output reg we_mem,
    output reg we_ir,
    output reg [1:0] sel_result,
    output reg [1:0] sel_alu_src_a,
    output reg [1:0] sel_alu_src_b,
    output reg we_rf
);

    //main FSM for control unit

    //state encoding
    localparam FETCH = 4'd0;
    localparam DECODE = 4'd1;
    localparam MEMADR = 4'd2;
    localparam MEMREAD = 4'd3;
    localparam MEMWRITE = 4'd4;
    localparam MEMWB = 4'd5;
    localparam EXECUTER = 4'd6;
    localparam EXECUTEI = 4'd7;
    localparam ALUWB = 4'd8;
    localparam BEQ = 4'd9;
    localparam JAL = 4'd10;
    localparam LUI = 4'd11;
    //next state logic
    reg [3:0] state, next_state;


    //state transition
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    //using moore machine model
    always @(*) begin
        //control signal defaults
        we_pc = 1'b0;
        pc_update = 1'b0;
        branch = 1'b0;
        sel_mem_addr = 1'b0;
        we_mem = 1'b0;
        we_ir = 1'b0;
        sel_result = 2'b00;
        alu_op = 2'b00;
        sel_alu_src_a = 2'b00;
        sel_alu_src_b = 2'b00;
        we_rf = 1'b0;
        next_state = state; 

        case (state)
            FETCH: begin
                next_state = DECODE;
                sel_mem_addr = 1'b0; //pc
                we_ir = 1'b1;
                sel_alu_src_a = 2'b00; //pc
                sel_alu_src_b = 2'b10; //4
                alu_op = 2'b00; //add
                sel_result = 2'b10; //alu result
                pc_update = 1'b1;
            end
            DECODE: begin
                sel_alu_src_a = 2'b01; //old pc
                sel_alu_src_b = 2'b01; //selects imm as source b
                alu_op = 2'b00; //add
                if (op == 7'b0000011) //lw
                    next_state = MEMADR;
                else if (op == 7'b0100011) //sw
                    next_state = MEMADR;
                else if (op == 7'b1100011) //beq
                    next_state = BEQ;
                else if (op == 7'b0010011) //I-type
                    next_state = EXECUTEI;
                else if (op == 7'b0110011) //R-type
                    next_state = EXECUTER;
                else if (op == 7'b1101111) //jal
                    next_state = JAL;
                else if (op == 7'b0110111) //lui
                    next_state = LUI;
            end
            MEMADR: begin
                sel_alu_src_a = 2'b10; //rs1
                sel_alu_src_b = 2'b01; //imm
                alu_op = 2'b00; //add
                if (op == 7'b0000011) //lw
                    next_state = MEMREAD;
                else if (op == 7'b0100011) //sw
                    next_state = MEMWRITE;
            end
            MEMREAD: begin
                next_state = MEMWB;
                sel_result = 2'b00; //mem data
                sel_mem_addr = 1'b1; //alu result
            end
            MEMWB: begin
                next_state = FETCH;
                sel_result = 2'b01; //mem data
                we_rf = 1'b1;
            end
            MEMWRITE: begin
                next_state = FETCH;
                sel_mem_addr = 1'b1; //alu result
                we_mem = 1'b1;
                sel_result = 2'b00; //alu out(non architectural register)
            end
            EXECUTER: begin
                next_state = ALUWB;
                sel_alu_src_a = 2'b10;
                sel_alu_src_b = 2'b00;
                alu_op = 2'b10; //R-type
            end
            LUI: begin
                next_state = ALUWB;
                sel_alu_src_a = 2'b11; //zero
                sel_alu_src_b = 2'b01; //imm
                alu_op = 2'b00; //add (0 + imm = imm)
                sel_result = 2'b00; //alu out register
            end
            EXECUTEI: begin
                next_state = ALUWB;
                sel_alu_src_a = 2'b10;
                sel_alu_src_b = 2'b01;
                alu_op = 2'b10; //I-type and R-type share same alu_op
            end
            JAL: begin
                next_state = ALUWB;
                sel_alu_src_a = 2'b01; //old pc
                sel_alu_src_b = 2'b10; //imm
                sel_result = 2'b00;
                alu_op = 2'b00; //add
                pc_update = 1'b1;
            end
            ALUWB: begin
                next_state = FETCH;
                we_rf = 1'b1;
                sel_result = 2'b00;
            end
            BEQ: begin
                next_state = FETCH;
                sel_alu_src_a = 2'b10; //rs1
                sel_alu_src_b = 2'b00; 
                alu_op = 2'b01; //sub
                branch = 1'b1;
            end
            default: begin
                next_state = FETCH;
            end
        endcase
        
        // Compute we_pc from branch and pc_update
        we_pc = (Zero & branch) | pc_update;
    end

endmodule
