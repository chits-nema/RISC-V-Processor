//Data memory module
module data_mem(
    input clk,
    input reset_n,
    input we,
    input [31:0] addr,
    input [31:0] wd,
    output [31:0] rd
    );

    //making memory
    reg [31:0] memory [0:31]; //mem consists of 32 registers each 32 bit wide
    integer k;

    //read operation
    assign rd = memory[addr]; //assign what is placed at memory address to rd

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Clear all memory on reset
            for (k = 0; k < 32; k = k + 1) begin
                memory[k] <= 32'h00000000;
            end
        end else if (we) begin
            //write operation
            memory[addr] <= wd;
        end
    end
endmodule