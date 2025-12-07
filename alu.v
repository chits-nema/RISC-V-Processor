module alu(
    input [31:0] A,
    input [31:0] B,
    input [3:0] alu_control,
    output reg [31:0] alu_out,
    output reg Zero
    );

    always @(*) begin
        case (alu_control)
        
            4'b0001: begin
                alu_out = A | B;               //OR
            end
            4'b0010: begin
                alu_out = A + B;               //ADD
            end
            4'b0011: begin
                alu_out = A ^ B;               //XOR
            end
            4'b0100: begin
                alu_out = A << B[4:0];         //SLL
            end
            4'b0101: begin
                alu_out = A >> B[4:0];        //SRL
            end
            4'b0110: begin
                alu_out = A - B;               //SUB
            end
            4'b0111: begin
                alu_out = (A < B) ? 32'b1 : 32'b0; //SLT
            end
            4'b1000: begin
                alu_out = A >>> B[4:0];       //SRA
            end
            4'b1100: begin
                alu_out = ~(A | B);            //NOR
            end
            4'b1110: begin
                alu_out = A & B;               //AND
            end
            4'b1111: begin
                alu_out = B;                   //Pass-through B (for LUI)
            end
            default: begin
                alu_out = 32'b0;
            end
        endcase

        //Set Zero flag
        if (alu_out == 32'b0)
            Zero = 1'b1;
        else
            Zero = 1'b0;
    end

endmodule