module hazard(
    input reg branchD, MemToRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW,
    input reg [4:0] RsD, RtD, RsE, WriteRegE, WriteRegE, WriteRegE, WriteRegM, WriteRegW,
    output reg stallF, stallD, ForwardAD, ForwardBD, FlushE,
    output logic [1:0] ForwardAE, ForwardBE,
    input clk, reset
);

    wire lwstall, branchStall;

    //---------------------forwarding logic----------------------------------
    wire [1:0] ForwardAE_t, ForwardBE_t;

    always @(*)begin
        if (RegWriteM & (RsE != 0) & (RsE == WriteRegM)) begin
            ForwardAE_t = 2'b10;
        end else if (RegWriteW & (RsE != 0) & (RsE == WriteRegW))begin
            ForwardAE_t = 2'b01;
        end else begin
            ForwardAE_t = 2'b00;
        end
    end

    always @(*)begin
        if (RegWriteM & (RtE != 0) & (RtE == WriteRegM)) begin
            ForwardBE_t = 2'b10;
        end else if (RegWriteW & (RtE != 0) & (RtE == WriteRegW)) begin
            ForwardBE_t = 2'b01;
        end else ForwardBE_t = 2'b00;
    end

    //----------------------------Control hazard Logic---------------------------
    assign ForwardAD = RegWriteM & (RsD == WriteRegM) & (RsD!=0);
    assign ForwardBD = RegWriteM & (RtD == WriteRegM) &(RtD!=0);

    //----------------------------------Stalling Logic----------------------------------------
    assign lwstall = MemToRegE & ((RtE == RsD) | (RtE == RtD)); //for lw commands

    flopenr #(1) regHaz1(~clk,reset, 1'b1, lwstall | branchStall, stallF);  //stallF = lwstall | branchStall
    flopenr #(1) regHaz2(~clk,reset, 1'b1, lwstall | branchStall, stallD);  //stallD = lwstall | branchSTall

    reg FlushE1;
    flopenr #(1) regHaz3(~clk,reset, 1'b1, lwstall | branchStall, FlushE1);
    flopenr #(1) regHaz6(~clk, reset, 1'b1, FlushE1, FlushE); //FlushE = lwstall | branchStall

    flopenr #(2) regHaz4(~clk,reset, 1'b1, ForwardAE_t, ForwardAE);
    flopenr #(2) regHaz5(~clk, reset, 1'b1, ForwardBE_t, ForwardBE);



endmodule