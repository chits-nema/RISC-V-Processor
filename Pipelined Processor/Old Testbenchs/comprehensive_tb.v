`include "top_module.v"

module comprehensive_tb;

reg clk;
reg reset;
wire [31:0] WriteData, DataAdr;
wire MemWrite;

// Test status
integer test_count;
integer pass_count;
integer fail_count;

// Instantiate DUT
top dut(clk, reset, WriteData, DataAdr, MemWrite);

// Clock generation
always begin
    clk = 1; #5;
    clk = 0; #5;
end

// Task to initialize test
task init_test;
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        reset = 1;
        #22;
        reset = 0;
        #10; // Let processor stabilize
    end
endtask

// Task to check register value
task check_register;
    input [4:0] reg_num;
    input [31:0] expected_value;
    input [255:0] test_name;
    reg [31:0] actual_value;
    begin
        test_count = test_count + 1;
        actual_value = dut.rvsingle.dp.rf.rf[reg_num];
        if (actual_value === expected_value) begin
            $display("[PASS] Test %0d: %s - x%0d = %0d", test_count, test_name, reg_num, actual_value);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %s - x%0d = %0d (expected %0d)", 
                     test_count, test_name, reg_num, actual_value, expected_value);
            fail_count = fail_count + 1;
        end
    end
endtask

// Task to check memory value
task check_memory;
    input [31:0] addr;
    input [31:0] expected_value;
    input [255:0] test_name;
    reg [31:0] actual_value;
    begin
        test_count = test_count + 1;
        actual_value = dut.dmem.RAM[addr[31:2]];
        if (actual_value === expected_value) begin
            $display("[PASS] Test %0d: %s - MEM[%0d] = %0d", test_count, test_name, addr, actual_value);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %s - MEM[%0d] = %0d (expected %0d)", 
                     test_count, test_name, addr, actual_value, expected_value);
            fail_count = fail_count + 1;
        end
    end
endtask

// Task to wait N clock cycles
task wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            @(posedge clk);
        end
    end
endtask

// Task to print test summary
task print_summary;
    begin
        $display("\n========================================");
        $display("TEST SUMMARY");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("========================================");
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("========================================\n");
    end
endtask

initial begin
    $dumpfile("comprehensive_tb.vcd");
    $dumpvars(0, comprehensive_tb);
    
    // Load test program
    $readmemh("comprehensive_test.hex", dut.imem.RAM);
    
    init_test();
    
    $display("\n========================================");
    $display("RISC-V ISA COMPREHENSIVE TEST");
    $display("========================================\n");
    
    // Wait 1 cycle per instruction, check after register update
    wait_cycles(1); check_register(10, 32'h12345000, "LUI: x10 = 0x12345000");
    wait_cycles(1); check_register(2, 5, "ADDI: x2 = x0 + 5");
    wait_cycles(1); check_register(3, 12, "ADDI: x3 = x0 + 12");
    wait_cycles(1); check_register(7, 3, "ADDI: x7 = x3 + (-9)");
    wait_cycles(1); check_register(4, 7, "OR: x4 = x7 | x2");
    wait_cycles(1); check_register(5, 4, "AND: x5 = x3 & x4");
    wait_cycles(1); check_register(5, 11, "ADD: x5 = x5 + x4");
    wait_cycles(1); check_register(6, 10, "ADDI: x6 = 10 (before BEQ)");
    wait_cycles(1); // BEQ not taken, continues
    wait_cycles(1); check_register(6, 20, "BEQ NOT TAKEN: x6 = 20");
    wait_cycles(1); check_register(4, 0, "SLT: x4 = (x3 < x4)");
    wait_cycles(1); check_register(17, 10, "ADDI: x17 = 10 (before BEQ)");
    wait_cycles(1); // BEQ taken, skips next instruction
    wait_cycles(1); check_register(17, 10, "BEQ TAKEN: x17 still 10");
    wait_cycles(1); check_register(4, 1, "SLT: x4 = (x7 < x2)");
    wait_cycles(1); // ADD: x7 = x4 + x5 = 1 + 11 = 12
    wait_cycles(1); check_register(7, 7, "SUB: x7 = x7 - x2 (12-5=7)");
    wait_cycles(1); check_memory(96, 7, "SW: Store x7 to mem[96]");
    wait_cycles(1); check_register(2, 7, "LW: Load mem[96] to x2");
    wait_cycles(1); check_register(9, 18, "ADD: x9 = x2 + x5");
    wait_cycles(1); check_register(28, 30, "ADDI: x28 = 30 (before JAL)");
    wait_cycles(1); // JAL, skips next
    wait_cycles(1); check_register(28, 30, "JAL: x28 still 30 (next skipped)");
                    check_register(3, 32'h58, "JAL: x3 = return address");
    wait_cycles(1); check_register(2, 25, "ADD: x2 = x2 + x9");
    wait_cycles(1); check_memory(120, 25, "SW: Store x2 to mem[120] (0x58+0x20)");
    
    print_summary();
    
    $finish;
end

// Timeout
initial begin
    #10000;
    $display("\n[ERROR] Test timeout!");
    print_summary();
    $finish;
end

endmodule
