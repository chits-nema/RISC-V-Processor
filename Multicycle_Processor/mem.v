module mem #(parameter MEM_DEPTH = 1024)(
    input clk,
    input [31:0] A,
    input [31:0] WD,
    input we_mem,
    output reg [31:0] RD);


    //memory array of 1024 words (4KB), each word is 32bits
    reg [31:0] RAM [0: MEM_DEPTH];

    //convert byte address to word address
    wire [9:0] word_address = A[11:2];

    //read operation - combinational and asynchronous
    always @(word_address) begin
        RD = RAM[word_address];
    end

    //write operation - synchronous
    always @(posedge clk) begin
        if (we_mem) begin
            RAM[word_address] <= WD;
        end
    end

endmodule
