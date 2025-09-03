`timescale 1ns/1ps

module display_timer_tb;

    reg clk;
    reg rst;
    reg one_second_pulse;
    wire game_finished;
    wire [6:0] HEX6, HEX7;

    display_timer dut (
        .clk(clk),
        .rst(rst),
        .one_second_pulse(one_second_pulse),
        .game_finished(game_finished),
        .HEX6(HEX6),
        .HEX7(HEX7)
    );

    // Generate clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("display_timer_tb.vcd");
        $dumpvars(0, display_timer_tb);

        clk = 0;
        rst = 1;
        one_second_pulse = 0;
        #20;
        rst = 0;

        // Feed 35 pulses to simulate 35 seconds
        repeat(35) begin
            #100;
            one_second_pulse = 1;
            #10;
            one_second_pulse = 0;
        end

        $finish;
    end

endmodule