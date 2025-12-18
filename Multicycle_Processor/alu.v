module alu(
    input [31:0] A,
    input [31:0] B,
    input [3:0] alu_control,
    output reg [31:0] alu_out,
    output reg Zero
    );

    always @(*) begin
        case (alu_control)
            //ADD
            4'b0000: alu_out = A + B;
            //SUB
            4'b0001: alu_out = A - B;
            //AND
            4'b0010: alu_out = A & B;
            //OR
            4'b0011: alu_out = A | B;
            //XOR
            4'b0100: alu_out = A ^ B;
            //SLT
            4'b0101: alu_out = (A < B) ? 32'b1 : 32'b0;
            //SLTU
            4'b1001: alu_out = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
            //SLL
            4'b0110: alu_out = A << B[4:0]; 
            //SRL
            4'b0111: alu_out = A >> B[4:0];  
            //SRA
            4'b1000: alu_out = A >>> B[4:0];
            endcase
        
        //set to zero when the output is zero for beq 
        Zero = (alu_out == 32'b0);
        end


endmodule