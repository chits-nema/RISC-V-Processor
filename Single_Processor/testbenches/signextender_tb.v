`include "../sign_extender.v"
`timescale 1ns / 1ps

module signextender_tb;
    reg [31:0] instr_in;
    reg [2:0] ext_type;
    wire [31:0] instr_out;

    // Instantiate the sign_extender module
    sign_extender SE (
        .in(instr_in[31:7]),
        .sel_ext(ext_type),
        .out(instr_out)
    );

    task init();
        begin
        // Initialize signals
        instr_in = 0;
        ext_type = 0;
        end   
    endtask

    initial begin
        $dumpfile("signextender_tb.vcd");
        $dumpvars(0, signextender_tb);

        init();

        // Test Case 1: I-type immediate (positive: +5)
        // I-type: imm[11:0] is in bits [31:20]
        instr_in = 32'h00500093; // addi x1, x0, 5 -> imm = 5
        ext_type = 3'b000; // I-type
        #10;
        $display("Test Case 1 (I-type +5) - Output: %h (Expected: 00000005)", instr_out);

        // Test Case 2: I-type immediate (negative: -1)
        // I-type: imm[11:0] = 0xFFF (all 1s for -1)
        instr_in = 32'hFFF00093; // addi x1, x0, -1
        ext_type = 3'b000; // I-type
        #10;
        $display("Test Case 2 (I-type -1) - Output: %h (Expected: FFFFFFFF)", instr_out);

        // Test Case 3: S-type immediate
        // S-type: imm[11:5] in bits [31:25], imm[4:0] in bits [11:7]
        instr_in = 32'h00112223; // sw x1, 4(x2) -> imm = 4
        ext_type = 3'b001; // S-type
        #10;
        $display("Test Case 3 (S-type +4) - Output: %h (Expected: 00000004)", instr_out);

        // Test Case 4: B-type immediate
        // B-type: imm[12|10:5] in bits [31:25], imm[4:1|11] in bits [11:7]
        instr_in = 32'h00208463; // beq x1, x2, 8
        ext_type = 3'b010; // B-type
        #10;
        $display("Test Case 4 (B-type +8) - Output: %h (Expected: 00000008)", instr_out);

        // Test Case 5: U-type immediate (LUI)
        // U-type: imm[31:12] in bits [31:12], lower 12 bits are 0
        instr_in = 32'h12345037; // lui x0, 0x12345
        ext_type = 3'b011; // U-type
        #10;
        $display("Test Case 5 (U-type) - Output: %h (Expected: 12345000)", instr_out);

        // Test Case 6: J-type immediate (JAL)
        // J-type: imm[20|10:1|11|19:12] in bits [31:12]
        instr_in = 32'h008000EF; // jal x1, 8
        ext_type = 3'b100; // J-type
        #10;
        $display("Test Case 6 (J-type +8) - Output: %h (Expected: 00000008)", instr_out);

        $finish;
    end
endmodule