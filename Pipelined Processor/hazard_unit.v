module hazard(
    input wire RegWriteE, RegWriteM, RegWriteW, ResultSrcE, PcSrcE,  
    input wire [4:0] Rs1E, Rs2E, Rs1D, RdE, Rs2D,
    output reg stallF, stallD, FlushD, FlushE,
    output reg [1:0] ForwardAE, ForwardBE,
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

    //Data Hazards using stalls for load word instr
    assign lwstall = ResultSrcE & ((Rs1D == RdE)|(Rs2D==RdE));

    //stall control logic
    always @(*) begin
        if (lwstall) begin
            //load-use hazard: stall Fetch and Decode stages
            stallF = 1'b1;
            stallD = 1'b1;
        end else begin
            //no stall
            stallF = 1'b0;
            stallD = 1'b0;
        end
    end

    //Flush control logic
    always @(*) begin
        //Flush Decode when branch is taken
        FlushD = PcSrcE;

        //Flush Execute when:
        //- Load-use hazard occurs (insert buddle)
        //- Branch is taken (clear incorrectly fetched instruction)
        FlushE = lwstall | PcSrcE;

    end

endmodule