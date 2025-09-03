module top_level (
    input         CLOCK_50,
    input  [3:0]  KEY,
    input  [17:0] SW,
    output [17:0] LEDR,
    output [6:0]  HEX0, HEX1, HEX2, HEX3
);
    wire [21:0] button_pressed;
    wire timer_reset, timer_up, timer_enable;
    wire [10:0] timer_value, random_value;
    debounce #(
        .DELAY_COUNTS(2500),
        .NUM_SWITCHES(22)
    ) u_debounce (
        .clk(CLOCK_50),
        .button({SW[17:0], KEY[3:0]}),
        .button_pressed(button_pressed)
    );
//    timer u_timer (
//        .clk(CLOCK_50),
//        .reset(timer_reset),
//        .up(timer_up),
//        .enable(timer_enable),
//        .start_value(random_value),
//        .timer_value(timer_value)
//    );
    // Add display, FSM, rng modules as needed
endmodule