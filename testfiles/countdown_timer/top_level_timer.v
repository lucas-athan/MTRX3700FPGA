module top_level (
  input  wire clk,            // 50 MHz system clock
  input  wire rst,            // reset
  output wire [6:0] HEX6,     // Seven seg 2 segment values
  output wire [6:0] HEX7      // Seven seg 2 segment values
);
    wire one_second_pulse;
    wire game_finished;

    countdown_timer countdown_timer_inst(
        .clk(clk),
        .rst(rst),
        .one_second_pulse(one_second_pulse)
    )

    display_timer display_timer_inst (
        .clk(clk),
        .rst(rst),
        .one_second_pulse(one_second_pulse),
        .game_finished(game_finished),
        .HEX6(HEX6),
        .HEX7(HEX7)
    );

endmodule