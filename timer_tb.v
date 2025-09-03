`timescale 1ns/1ns

module timer_tb;

    // Parameters (shorten CLKS_PER_MS for fast simulation)
    localparam MAX_MS      = 16;
    localparam CLKS_PER_MS = 10;   // 10 clock cycles = 1 "ms" in simulation

    // DUT signals
    reg clk;
    reg enable;
    reg [$clog2(MAX_MS)-1:0] start_value;
    wire [$clog2(MAX_MS)-1:0] timer_value;

    // Instantiate DUT
    timer #(
        .MAX_MS(MAX_MS),
        .CLKS_PER_MS(CLKS_PER_MS)
    ) dut (
        .clk(clk),
        .start_value(start_value),
        .enable(enable),
        .timer_value(timer_value)
    );

    // Clock generation: 20 ns period
    initial clk = 0;
    always #10 clk = ~clk;

    // Stimulus
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_timer);

        // Start with enable=0 (loads start_value)
        start_value = 5;  // countdown from 5
        enable      = 0;
        #40;             // give it a couple of cycles

        // Run countdown
        enable = 1;
        #1200;           // let it tick down to 0

        // Reload with new value
        enable      = 0;
        start_value = 3;
        #40;

        // Run countdown again
        enable = 1;
        #800;

        $finish;
    end

    // Monitor
    /* verilator lint_off SYNCASYNCNET */
    initial begin
        $monitor("t=%0t | enable=%b | start_value=%0d | timer_value=%0d",
                  $time, enable, start_value, timer_value);
    end
    /* verilator lint_on SYNCASYNCNET */

endmodule
