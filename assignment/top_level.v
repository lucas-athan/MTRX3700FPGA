// For DE2-115
module top_level (
  input  wire clk,            // 50 MHz system clock
  input  wire rst,            // reset
  input  wire [3:0]  KEY,     // Pushbuttons
  input  wire [17:0] SW,      // Board Switches
  output wire [17:0] LEDR,    // Red LEDs
  output wire [6:0] HEX0,     // Seven seg 0 segment values
  output wire [6:0] HEX1,     // Seven seg 1 segment values
  output wire [6:0] HEX2,     // Seven seg 2 segment values
  output wire [6:0] HEX3,     // Seven seg 1 segment values
  output wire [6:0] HEX4,     // Seven seg 2 segment values
  output wire [6:0] HEX5,     // Seven seg 1 segment values
  output wire [6:0] HEX6,     // Seven seg 2 segment values
  output wire [6:0] HEX7      // Seven seg 2 segment values
);

  wire [4:0] rand_index;      // Dummy variable: for LED index
  wire rand_request;          // Dummy variable: send request to turn LED on
  reg [1:0] difficulty;       // Difficulty passed from button -> RNG module

  wire [17:0] led_from_leds;  // raw LEDs from leds.v
  wire [17:0] led_final;      // LEDs after switch logic
  wire [7:0]  score;          // player score

  wire but1, but2, but3;      // Wires for debounced button signals

  // Debounce Buttons
  debounce db1 (.clk(clk), .button(~KEY[1]), .button_pressed(but1));
  debounce db2 (.clk(clk), .button(~KEY[2]), .button_pressed(but2));
  debounce db3 (.clk(clk), .button(~KEY[3]), .button_pressed(but3));

  // Difficulty logic
  always @(posedge clk) begin
    if (rst)       difficulty <= 2'b00;
    else if (but1) difficulty <= 2'b00;
    else if (but2) difficulty <= 2'b01;
    else if (but3) difficulty <= 2'b10;
  end

  // RNG module
  rng rng_inst (
    .clk(clk),
    .rst(rst),
    .level(difficulty),
    .led_index(rand_index),
    .led_request(rand_request)
  );

  // LED timer controller
  leds leds_inst (
    .clk(clk),
    .rst(rst),
    .led_index(rand_index),
    .led_request(rand_request),
    .LEDR(led_from_leds)
  );

  // Switch Logic
  switches switches_inst (
    .clk(clk),
    .rst(rst),
    .led_in(led_from_leds),
    .sw(SW),
    .led_out(led_final),
    .score(score)
  );

  assign LEDR = led_final;

  // Score
  score_display score_inst (
    .SCORE(score),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .HEX6(HEX6),
    .HEX7(HEX7)
  );

endmodule