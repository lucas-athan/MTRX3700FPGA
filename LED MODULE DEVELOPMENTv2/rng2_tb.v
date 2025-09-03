module rng_tb;

    // Inputs to the DUT (Device Under Test)
    reg clk;

    // Outputs from the DUT
    wire [10:0] random_value; // 11-bit output, as MAX_VALUE is 1223

    // Instantiate the rng module with specific parameters
    rng #(
        .OFFSET(200),
        .MAX_VALUE(1223),
        .SEED(340) // Choose your seed value here
    ) dut (
        .clk(clk),
        .random_value(random_value)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 20ns clock period (50 MHz)
    end

    // Initial conditions and stimulus
    initial begin
        // Dump the waveform to a VCD file
        $dumpfile("waveform.vcd");
        $dumpvars();

        // Display header
        $display("Time\tRandom Value");
        $monitor("%0d\t%b", $time, random_value);

        // Run the simulation for a specified time
        #1000 $finish();
    end

endmodule