// Top-level module for Whac-a-Mole game on DE1-SoC
module whac_a_mole_top_level (
    input         CLOCK_50,              // PIN_AF14
    input  [3:0]  KEY,                   // KEY[0-3]: PIN_AA14, PIN_AA15, PIN_W15, PIN_Y16 (active-low)
    input  [9:0]  SW,                    // SW[0-9]: PIN_AB12, PIN_AC12, ..., PIN_AE12
    output [9:0]  LEDR,                  // LEDR[0-9]: PIN_V16, PIN_W16, ..., PIN_Y21
    output [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 // HEX displays
);

    // Intermediate wires
    wire [3:0] key_pressed;
    wire [9:0] sw_pressed;
    wire [3:0] random_led;
    wire [11:0] score;
    wire [1:0] level;
    wire timer_reset, timer_enable;
    wire [11:0] timer_value;
    wire [3:0] bcd0, bcd1, bcd2, bcd3;
    wire rng_enable;

    // Invert KEY inputs (active-low)
    wire [3:0] key_inverted = ~KEY;

    // Synchronizers
    wire [3:0] key_sync;
    wire [9:0] sw_sync;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : key_sync_gen
            synchroniser u_key_sync (.clk(CLOCK_50), .x(key_inverted[i]), .y(key_sync[i]));
        end
        for (i = 0; i < 10; i = i + 1) begin : sw_sync_gen
            synchroniser u_sw_sync (.clk(CLOCK_50), .x(SW[i]), .y(sw_sync[i]));
        end
    endgenerate

    // Debouncers
    generate
        for (i = 0; i < 4; i = i + 1) begin : key_debounce_gen
            debounce #(.DELAY_COUNTS(100000)) u_key_debounce (.clk(CLOCK_50), .button(key_sync[i]), .button_pressed(key_pressed[i]));
        end
        for (i = 0; i < 10; i = i + 1) begin : sw_debounce_gen
            debounce #(.DELAY_COUNTS(100000)) u_sw_debounce (.clk(CLOCK_50), .button(sw_sync[i]), .button_pressed(sw_pressed[i]));
        end
    endgenerate

    // RNG
    rng u_rng (
        .clk(CLOCK_50),
        .enable(rng_enable),
        .random_value(random_led)
    );

    // Timer
    timer u_timer (
        .clk(CLOCK_50),
        .reset(timer_reset),
        .up(1'b1),
        .enable(timer_enable),
        .start_value(12'd0),
        .timer_value(timer_value)
    );

    // FSM
    whac_a_mole_fsm u_fsm (
        .clk(CLOCK_50),
        .key_pressed(key_pressed),
        .sw_pressed(sw_pressed),
        .random_led(random_led),
        .timer_value(timer_value),
        .level(level),
        .score(score),
        .timer_reset(timer_reset),
        .timer_enable(timer_enable),
        .rng_enable(rng_enable),
        .ledr(LEDR)
    );

    // Display
    display u_display (
        .clk(CLOCK_50),
        .value(score),
        .display0(bcd0),
        .display1(bcd1),
        .display2(bcd2),
        .display3(bcd3)
    );

    // Seven-segment displays
    seven_seg u_hex0 (.bcd(bcd0), .segments(HEX0));
    seven_seg u_hex1 (.bcd(bcd1), .segments(HEX1));
    seven_seg u_hex2 (.bcd(bcd2), .segments(HEX2));
    seven_seg u_hex3 (.bcd(bcd3), .segments(HEX3));
    seven_seg u_hex4 (.bcd({2'b0, level}), .segments(HEX4));
    seven_seg u_hex5 (.bcd(4'd10), .segments(HEX5)); // 'L'
endmodule
