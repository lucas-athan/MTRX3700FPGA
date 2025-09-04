// This top-level module is for the video on slide 5.4 :).

//module top_level (
//    input  [17:0] SW,
//    output [6:0]  HEX0,
//    output [6:0]  HEX1,
//	 output [6:0]  HEX2,
//    output [6:0]  HEX3
//	 output [17:0] LEDR
//);

//    seven_seg seven_seg_u0 (
//        .bcd(SW[3:0]),
//        .segments(HEX0)
//    );
//
//    seven_seg seven_seg_u1 (
//        .bcd(SW[7:4]),
//        .segments(HEX1)
//    );
//	 
//	 seven_seg seven_seg_u2 (
//        .bcd(SW[11:8]),
//        .segments(HEX2)
//    );
//
//    seven_seg seven_seg_u3 (
//        .bcd(SW[15:12]),
//        .segments(HEX3)
//    );
//	 switch_to_led switch_led_u0 (
//        .switches(SW),
//        .leds(LEDR)
//    );


//endmodule

// This top-level module connects the timer and RNG modules
// to control the LEDs.
//
//module top_level (
//	input  [17:0] SW,
//	input  CLOCK_50,
//	output [17:0] LEDR
//);
//
//    // Internal signals to connect modules
//    wire [$clog2(2047)-1:0] timer_value;
//    wire [$clog2(1223)-1:0] random_value;
//    wire timer_enable_w;
//    wire timer_reset_w;
//
//    // Connect SW[0] as an active-low reset for the system.
//    wire reset_n = SW[0];
//
//    // Instantiate the timer module.
//    // The timer is configured to count up (up=1) and is enabled by the control module.
//    timer timer_u0 (
//        .clk(CLOCK_50),
//        .reset(timer_reset_w), // Controlled by random_led_sequencer
//        .up(1'b1),
//        .start_value(11'd0),
//        .enable(timer_enable_w), // Controlled by random_led_sequencer
//        .timer_value(timer_value)
//    );
//
//    // Instantiate the RNG module.
//    // The seed can be any non-zero value.
//    rng rng_u0 (
//        .clk(CLOCK_50),
//        .random_value(random_value)
//    );
//
//    // Instantiate the module that controls the sequence.
//    random_led_sequencer sequence_u0 (
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .timer_value(timer_value),
//        .random_value(random_value),
//        .leds(LEDR),
//        .timer_enable(timer_enable_w),
//        .timer_reset(timer_reset_w)
//    );
//
//endmodule

// This top-level module uses a push button to start and stop the
// random LED sequence.
//
// This top-level module uses a push button to start and stop the
// random LED sequence.

//module top_level (
//	input  [17:0] SW,
//	input  [3:0] KEY, // The DE2-115 has 4 push-buttons, we will use KEY[0]
//	input  CLOCK_50,
//	output [17:0] LEDR
//);
//
//    // Internal signals to connect modules
//    wire [$clog2(2047)-1:0] timer_value;
//    wire [$clog2(1223)-1:0] random_value;
//    wire timer_enable_w;
//    wire timer_reset_w;
//
//    // Signal for the debounced button press
//    wire button_debounced;
//
//    // A register to hold the state of the sequence: enabled or disabled
//    reg sequence_enabled;
//    // A register to detect the rising edge of the debounced button
//    reg prev_button_debounced;
//
//    // Use a debounce module to handle button presses from KEY[0]
//    // The DE2-115 has a 50MHz clock, so a 50us delay requires 2500 counts (50us / 20ns).
//    debounce debounce_u0 (
//        .clk(CLOCK_50),
//        .button(~KEY[0]),
//        .button_pressed(button_debounced)
//    );
//
//    // Logic to toggle the sequence_enabled state on each button press
//    always @(posedge CLOCK_50) begin
//        // Detect a rising edge on the debounced button signal
//        if (button_debounced == 1'b1 && prev_button_debounced == 1'b0) begin
//            sequence_enabled <= ~sequence_enabled;
//        end
//        prev_button_debounced <= button_debounced;
//    end
//
//    // Instantiate the timer module.
//    // The timer is configured to count up (up=1).
//    timer timer_u0 (
//        .clk(CLOCK_50),
//        .reset(timer_reset_w), 
//        .up(1'b1),
//        .start_value(11'd0),
//        .enable(timer_enable_w),
//        .timer_value(timer_value)
//    );
//
//    // Instantiate the RNG module.
//    // The seed can be any non-zero value.
//    rng rng_u0 (
//        .clk(CLOCK_50),
//        .random_value(random_value)
//    );
//
//    // Instantiate the module that controls the sequence.
//    random_led_sequencer sequence_u0 (
//        .clk(CLOCK_50),
//        .reset_n(sequence_enabled), // The overall enable signal is now the reset for the sequencer
//        .timer_value(timer_value),
//        .random_value(random_value),
//        .leds(LEDR),
//        .timer_enable(timer_enable_w),
//        .timer_reset(timer_reset_w)
//    );
//
//endmodule

// This top-level module uses a push button to start and stop the
// random LED sequence and adds hit/miss game logic.
// The FSM controls the game logic, transitioning between IDLE, PLAYING, and HIT states.
// This top-level module uses a push button to start and stop the
// random LED sequence and adds hit/miss game logic.
////
module top_level (
	input  [17:0] SW,
	input  [3:0] KEY, // The DE2-115 has 4 push-buttons, we will use KEY[0] and KEY[1]
	input  CLOCK_50,
    output [6:0]  HEX0,
    output [6:0]  HEX1,
	output [6:0]  HEX2,
    output [6:0]  HEX3,
	output [17:0] LEDR
);

    // Internal signals to connect modules
    wire [$clog2(2047)-1:0] timer_value;
    wire [$clog2(1223)-1:0] random_value;
    wire timer_enable_w;
    wire timer_reset_w;
    wire [17:0] leds_from_sequencer;
    wire reset_sequencer_fsm;

    // Score from the FSM
    wire [15:0] score;
    
    // Wire for the BCD representation of the score
    wire [15:0] score_bcd;
    
    // Timer expired signal
    wire timer_expired;
    assign timer_expired = (timer_value >= 500);

    // The KEY[0] is for start/stop. The KEY[1] is a game reset.
    wire start_stop_button_debounced;
    wire game_reset_button_debounced;

    // Use a debounce module for the start/stop button
    debounce debounce_start_stop (
        .clk(CLOCK_50),
        .button(~KEY[0]),
        .button_pressed(start_stop_button_debounced)
    );

//    // Use a debounce module for the game reset button
//    debounce debounce_game_reset (
//        .clk(CLOCK_50),
//        .button(~KEY[1]), // Corrected to use KEY[1] for reset
//        .button_pressed(game_reset_button_debounced)
//    );

    // FSM to toggle the sequence on each button press
    reg prev_start_stop_debounced;
    reg sequence_enabled;
    always @(posedge CLOCK_50) begin
        // Detect a rising edge on the start/stop button signal
        if (start_stop_button_debounced == 1'b1 && prev_start_stop_debounced == 1'b0) begin
            sequence_enabled <= ~sequence_enabled;
        end
        prev_start_stop_debounced <= start_stop_button_debounced;
    end
    
    // The FSM controls the sequencer reset
    wire sequencer_reset_n = sequence_enabled & ~reset_sequencer_fsm;


    // Instantiate the timer module.
    timer timer_u0 (
        .clk(CLOCK_50),
        .reset(timer_reset_w), 
        .up(1'b1),
        .start_value(11'd0),
        .enable(timer_enable_w),
        .timer_value(timer_value)
    );

    // Instantiate the RNG module.
    rng rng_u0 (
        .clk(CLOCK_50),
        .random_value(random_value)
    );

    // Instantiate the random LED sequencer
    random_led_sequencer sequence_u0 (
        .clk(CLOCK_50),
        .reset_n(sequencer_reset_n),
        .timer_value(timer_value),
        .random_value(random_value),
        .leds(leds_from_sequencer),
        .timer_enable(timer_enable_w),
        .timer_reset(timer_reset_w)
    );
    
    // Instantiate the game controller FSM
    fsm_test fsm_u0 (
        .clk(CLOCK_50),
        .reset_n(!game_reset_button_debounced), // Corrected to be active-low
		.game_start_in(sequence_enabled), // New connection to start the game
        .switches(SW),
        .leds_from_sequencer(leds_from_sequencer),
        .timer_expired_in(timer_expired),
        .reset_sequencer_out(reset_sequencer_fsm),
        .score_out(score)
    );

    // Instantiate the binary-to-BCD converter
    display bcd_converter (
        .clk(CLOCK_50),
        .reset(!game_reset_button_debounced), // Use same reset as FSM
        .binary_in(score),
        .bcd_out(score_bcd)
    );

    // Assign LED outputs
    // LEDs are only lit if the sequence is enabled
    assign LEDR = sequence_enabled ? leds_from_sequencer : 18'b0;

    // Instantiate seven-segment display drivers for the BCD score
    seven_seg seven_seg_u0 (
        .bcd(score_bcd[3:0]),
        .segments(HEX0)
    );

    seven_seg seven_seg_u1 (
        .bcd(score_bcd[7:4]),
        .segments(HEX1)
    );
	 
	 seven_seg seven_seg_u2 (
        .bcd(score_bcd[11:8]),
        .segments(HEX2)
    );

    seven_seg seven_seg_u3 (
        .bcd(score_bcd[15:12]),
        .segments(HEX3)
    );

endmodule

// Top-level module to instantiate and connect the simple_counter module.
// It uses a debounced key for reset and a switch for incrementing the counter.
 // This top-level module instantiates the simple_counter module.
// It debounces the reset and counter switches for reliable counting.
//module top_level (
//	input  [17:0] SW,
//	input  [3:0] KEY, 
//	input  CLOCK_50,
//    output [6:0]  HEX0,
//    output [6:0]  HEX1,
//	output [6:0]  HEX2,
//    output [6:0]  HEX3,
//	output [17:0] LEDR
//);
//    
//    // Internal wires for the debounced buttons and counter input
//    wire game_reset_button_debounced;
//    wire counter_sw_debounced;
//
//    // The count in BCD format
//    wire [15:0] count_bcd;
//
//    // Use a debounce module for the game reset button (KEY[1])
//    debounce debounce_game_reset (
//        .clk(CLOCK_50),
//        .button(~KEY[0]), 
//        .button_pressed(game_reset_button_debounced)
//    );
//
//    // Use a debounce module for the counter switch (SW[0])
//    debounce counter_debounce_u0 (
//        .clk(CLOCK_50),
//        .button(SW[0]), 
//        .button_pressed(counter_sw_debounced)
//    );
//
//    // Instantiate the simple_counter module
//    simple_counter counter_u0 (
//        .clk(CLOCK_50),
//        .rst(game_reset_button_debounced), // Use the debounced reset button
//        .switch_in(counter_sw_debounced), // Use the debounced switch signal
//        .count_bcd_out(count_bcd)
//    );
//    
//    // Assign LED outputs to be off since this is just a counter now
//    assign LEDR = 18'b0;
//
//    // Instantiate seven-segment display drivers for the BCD count
//    seven_seg seven_seg_u0 (
//        .bcd(count_bcd[3:0]),
//        .segments(HEX0)
//    );
//
//    seven_seg seven_seg_u1 (
//        .bcd(count_bcd[7:4]),
//        .segments(HEX1)
//    );
//	 
//	 seven_seg seven_seg_u2 (
//        .bcd(count_bcd[11:8]),
//        .segments(HEX2)
//    );
//
//    seven_seg seven_seg_u3 (
//        .bcd(count_bcd[15:12]),
//        .segments(HEX3)
//    );
//
//endmodule
