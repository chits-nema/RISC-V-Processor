module hazard(
    input reg branchD, MemToRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW,
    input reg [4:0] RsD, RtD, Rs1E, WriteRegE, WriteRegE, WriteRegE, RegWriteM, RegWriteW,
    output reg stallF, stallD, ForwardAD, ForwardBD, FlushE,
    output logic [1:0] ForwardAE, ForwardBE,
    input clk, reset
);

    wire lwstall, branchStall;

    //---------------------forwarding logic for data hazard----------------------------------
    //forward from Memory stage
    always @(*)begin
        if (RegWriteM & (Rs1E != 0) & (Rs1E == RegWriteM)) begin
            ForwardAE = 2'b10;
        end else if (RegWriteW & (Rs1E != 0) & (Rs1E == RegWriteW))begin
            ForwardAE = 2'b01;
        end else begin
            ForwardAE = 2'b00;
        end
    end

    //forward from Writeback stage
    always @(*)begin
        if (RegWriteM & (Rs2E != 0) & (Rs2E == RegWriteM)) begin
            ForwardBE = 2'b10;
        end else if (RegWriteW & (Rs2E != 0) & (Rs2E == RegWriteW)) begin
            ForwardBE = 2'b01;
        end else ForwardBE = 2'b00;
    end

    //Data Hazards using stalls 

    //----------------------------Control hazard Logic---------------------------
    assign ForwardAD = RegWriteM & (RsD == RegWriteM) & (RsD!=0);
    assign ForwardBD = RegWriteM & (RtD == RegWriteM) &(RtD!=0);
    //----------------------------------Stalling Logic----------------------------------------
    assign lwstall = MemToRegE & ((Rs2E == RsD) | (Rs2E == RtD)); //for lw commands

    flopenr #(1) regHaz1(~clk,reset, 1'b1, lwstall | branchStall, stallF);  //stallF = lwstall | branchStall
    flopenr #(1) regHaz2(~clk,reset, 1'b1, lwstall | branchStall, stallD);  //stallD = lwstall | branchSTall

    reg FlushE1;
    flopenr #(1) regHaz3(~clk,reset, 1'b1, lwstall | branchStall, FlushE1);
    flopenr #(1) regHaz6(~clk, reset, 1'b1, FlushE1, FlushE); //FlushE = lwstall | branchStall

    flopenr #(2) regHaz4(~clk,reset, 1'b1, ForwardAE_t, ForwardAE);
    flopenr #(2) regHaz5(~clk, reset, 1'b1, ForwardBE_t, ForwardBE);



endmodule