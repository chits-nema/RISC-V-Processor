module instruction_mem(
    read_address, instr_out
);

    input [31:0] read_address;
    output [31:0] instr_out;

    //making memory
    reg [31:0] memory [0:31]; //mem consists of 32 registers each 32 bit wide

    assign instr_out = memory[read_address[31:2]]; //Divide byte address by 4 to get word address

    
endmodule