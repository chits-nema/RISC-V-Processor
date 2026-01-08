`include "top_module.v"
module testbench;

reg clk;
reg reset;
wire [31:0] WriteData, DataAdr;
wire MemWrite;

//instantiate device to be tested
top dut(clk, reset, WriteData, DataAdr, MemWrite);

//initialise test
initial begin
    // Load test instructions BEFORE reset
    $readmemh("riscvtest.hex", dut.imem.RAM);
    
    reset<=1;
    #22; 
    reset<=0;
end
initial begin
    $dumpfile("sc_tb.vcd");
    $dumpvars(0, testbench);
end
//generate clock to sequence tests
always
 begin
    clk <=1;
    #5;
    clk<=0;
    #5;
 end


 //check results
 always @(negedge clk)
  begin
    $display("PC=%h, Instr=%h, ImmExt=%d, ALUSrc=%b, SrcB=%d, ALURes=%d | x2=%d x3=%d x4=%d x5=%d x7=%d", 
             dut.rvsingle.PC, dut.rvsingle.Instr, $signed(dut.rvsingle.dp.ImmExt), dut.rvsingle.dp.ALUSrc,
             $signed(dut.rvsingle.dp.SrcB), $signed(DataAdr),
             dut.rvsingle.dp.rf.rf[2], dut.rvsingle.dp.rf.rf[3], dut.rvsingle.dp.rf.rf[4], 
             dut.rvsingle.dp.rf.rf[5], dut.rvsingle.dp.rf.rf[7]);
    if(MemWrite) begin
        $display("MemWrite: DataAdr=%d, WriteData=%d", DataAdr, WriteData);
        if(DataAdr == 100 & WriteData ==25) begin
            $display("Simulation succeeded");
            $finish;
        end else if (DataAdr!=96) begin
            $display("Simulation failed");
            $finish;
        end
    end
end

// Timeout to prevent infinite simulation
initial begin
    #10000;
    $display("Simulation timeout");
    $finish;
end

endmodule