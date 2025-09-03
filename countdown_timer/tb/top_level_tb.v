`timescale 1ns/1ps

module top_level_tb;

    reg clk;
    reg rst;
    wire [6:0] HEX6, HEX7;

    // For simulation speed: shorten "1s" to 20 cycles
    localparam SIM_TICKS = 20;

    // Override countdown_timer parameter
    top_level uut (
        .clk(clk),
        .rst(rst),
        .HEX6(HEX6),
        .HEX7(HEX7)
    );

    // Clock gen
    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_level_tb.vcd");
        $dumpvars(0, top_level_tb);

        clk = 0;
        rst = 1;
        #20;
        rst = 0;

        // Run long enough to see full countdown
        #2000;
        $finish;
    end

endmodule