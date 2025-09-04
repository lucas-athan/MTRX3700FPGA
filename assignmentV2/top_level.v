// For DE2-115
module top_level (
  input  wire CLOCK_50,            // 50 MHz system clock
  input  wire [3:0]  KEY,     // Pushbuttons
  input  wire [17:0] SW,      // Board Switches
  output wire [17:0] LEDR,    // Red LEDs
  output wire [6:0] HEX0,     // Seven seg 0 segment values
  output wire [6:0] HEX1,     // Seven seg 1 segment values
  output wire [6:0] HEX2,     // Seven seg 2 segment values
  output wire [6:0] HEX3,     // Seven seg 3 segment values
  output wire [6:0] HEX4,     // Seven seg 4 segment values
  output wire [6:0] HEX5,     // Seven seg 5 segment values
  output wire [6:0] HEX6,     // Seven seg 6 segment values
  output wire [6:0] HEX7      // Seven seg 7 segment values
);

  wire [4:0] rand_index;      // Dummy variable: for LED index
  wire rand_request;          // Dummy variable: send request to turn LED on
  reg [1:0] difficulty;       // Difficulty passed from button -> RNG module

  reg [17:0] leds;           // LEDs after switch logic
  reg [11:0] score;          // player score

  wire rst, but1, but2, but3;      // Wires for debounced button signals

  // Debounce Buttons
  debounce db0 (.clk(CLOCK_50), .button(~KEY[0]), .button_pressed(rst));
  debounce db1 (.clk(CLOCK_50), .button(~KEY[1]), .button_pressed(but1));
  debounce db2 (.clk(CLOCK_50), .button(~KEY[2]), .button_pressed(but2));
  debounce db3 (.clk(CLOCK_50), .button(~KEY[3]), .button_pressed(but3));

  // Difficulty logic
  always @(posedge CLOCK_50) begin
    if (rst)        difficulty <= 2'b00;
    else if (but1)  difficulty <= 2'b00;
    else if (but2)  difficulty <= 2'b01;
    else if (but3)  difficulty <= 2'b10;
    else            difficulty <= 2'b00;
  end

  // RNG module
  rng rng_inst (
    .clk(CLOCK_50),
    .rst(rst),
    .level(difficulty),
    .led_index(rand_index),
    .led_request(rand_request)
  );

  // LED timer controller
  leds_switches leds_inst (
    .clk(CLOCK_50),
    .rst(rst),
    .led_index(rand_index),
    .led_request(rand_request),
    .switches(SW),
    .leds(leds),
    .score(score)
  );

  assign LEDR = leds;

  // Score
  score_display score_inst (
    .score(score),
    .hex0(HEX0),
    .hex1(HEX1),
    .hex2(HEX2),
    .hex3(HEX3),
    .hex4(HEX4),
    .hex5(HEX5),
    .hex6(HEX6),
    .hex7(HEX7)
  );

endmodule