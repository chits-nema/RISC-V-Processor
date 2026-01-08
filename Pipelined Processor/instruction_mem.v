module imem(
    input [5:0] a,
    output [31:0] rd
);
reg [31:0] RAM[0:63];

assign rd = RAM[a]; //a represents address in imem

endmodule