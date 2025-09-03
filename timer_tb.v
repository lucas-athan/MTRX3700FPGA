`timescale 1ns/1ns

module timer_tb;

    // Testbench signals
    reg clk;
    reg stop;
    reg enable;
    reg [10:0] start_value;        // supports up to MAX_MS=2047
    wire [10:0] timer_value;
    wire game_over;

    // Instantiate DUT
    timer #(
        .MAX_MS(2047),
        .CLKS_PER_MS(10)           // keep small for faster sim
    ) DUT (
        .clk(clk),
        .stop(stop),
        .start_value(start_value),
        .enable(enable),
        .timer_value(timer_value),
        .game_over(game_over)
    );

    // Clock generator (20 ns period = 50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // Stimulus
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_timer);

        // Initialise
        stop        = 1;
        enable      = 0;
        start_value = 5;   // expire after 5 ms
        #40;

        // Release reset/stop
        stop   = 0;
        enable = 1;

        // Run until game_over goes high
        #1000;

        // Pause timer
        enable = 0;
        #100;

        // Resume timer
        enable = 1;
        #500;

        // Reset again
        stop = 1;
        #40;
        stop = 0;

        #500;
        $finish;
    end

    // Monitor outputs (with lint control to silence Verilator warnings)
    /* verilator lint_off SYNCASYNCNET */
    initial begin
        $monitor("t=%0t | stop=%b enable=%b | timer_value=%d game_over=%b",
                  $time, stop, enable, timer_value, game_over);
    end
    /* verilator lint_on SYNCASYNCNET */

endmodule
