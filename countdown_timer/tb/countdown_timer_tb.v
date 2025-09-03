`timescale 1ns/1ps

module countdown_timer_tb;

    reg clk;
    reg rst;
    wire one_second_pulse;

    // Shorten the parameter for simulation speed (use 20 ticks = "1s")
    localparam SIM_TICKS = 20;

    countdown_timer #(.CLK_TICKS_S(SIM_TICKS)) dut (
        .clk(clk),
        .rst(rst),
        .one_second_pulse(one_second_pulse)
    );

    // Generate clock: 10 ns period = 100 MHz
    always #5 clk = ~clk;

    initial begin
        $dumpfile("countdown_timer_tb.vcd");
        $dumpvars(0, countdown_timer_tb);

        clk = 0;
        rst = 1;
        #20;
        rst = 0;

        // Run enough cycles to see several pulses
        #(SIM_TICKS*10*10);  // ~10 "seconds"
        $finish;
    end

endmodule