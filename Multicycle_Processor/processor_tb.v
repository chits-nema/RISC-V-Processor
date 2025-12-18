module testbench;
    // ... your testbench signals ...
    
    initial begin
        $dumpfile("controller.vcd");  // Creates VCD file
        $dumpvars(0, testbench);      // Dumps all signals
        
        // Your test cases here
        #1000 $finish;
    end
endmodule