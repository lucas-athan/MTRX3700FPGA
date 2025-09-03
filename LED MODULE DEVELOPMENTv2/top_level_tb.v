`timescale 1ns / 1ps

module tb_top_level;

    reg CLOCK_50;
    wire [9:0] LEDR;

    // Instantiate the top-level module
    top_level uut (
        .CLOCK_50(CLOCK_50),
        .LEDR(LEDR)
    );

    // Clock generation: 50 MHz -> period = 20 ns
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;

    // Monitor LED outputs and print changes
    initial begin
        $display("Time(ns) | LEDR");
        $monitor("%8t | %b", $time, LEDR);
    end

    // Simulation runtime control
    initial begin
        // Run simulation long enough to see multiple updates
        #2000000; // adjust as needed (20,000,000 ns = 1 s scaled down)
        $display("Simulation finished.");
        $finish;
    end

endmodule
