`timescale 1ns/1ns

module timer_tb;

    // Parameters (smaller CLKS_PER_MS for faster sim)
    localparam MAX_MS      = 16;
    localparam CLKS_PER_MS = 10;   // 10 cycles = 1 "ms" in simulation

    // DUT signals
    reg clk;
    reg stop;
    reg enable;
    reg [$clog2(MAX_MS)-1:0] start_value;
    wire [$clog2(MAX_MS)-1:0] timer_value;

    // Instantiate DUT
    timer #(
        .MAX_MS(MAX_MS),
        .CLKS_PER_MS(CLKS_PER_MS)
    ) dut (
        .clk(clk),
        .stop(stop),
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

        // Initialise
        stop        = 1;      // load start_value
        enable      = 0;
        start_value = 5;      // start countdown at 5
        #40;

        stop   = 0;           // release reset
        enable = 1;           // start countdown

        // Let it run until it hits 0
        #1000;

        // Reload with a new value
        stop        = 1;
        start_value = 3;
        #40;
        stop        = 0;
        enable      = 1;

        #500;

        $finish;
    end

    // Monitor
    /* verilator lint_off SYNCASYNCNET */
    initial begin
        $monitor("t=%0t | stop=%b enable=%b | timer_value=%0d",
                $time, stop, enable, timer_value);
    end
    /* verilator lint_on SYNCASYNCNET */


endmodule
