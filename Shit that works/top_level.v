`timescale 1ns/1ns

module top_level (
    input               clk,                // System clock
    input       [17:0]  toggle_switches,    // Player switches
    input       [3:0]   key_switches,       // Start/reset/level buttons
    output      [17:0]  leds,               // LED outputs
    output      [6:0]   seg,                // 7-segment display for points
    output reg  [3:0]   an                   // 7-segment anodes (if multiplexed)
);

    // -------------------------------
    // Debounce start/reset/level buttons
    // -------------------------------
    wire [3:0] debounced_keys;
    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin : debounce_keys
            debounce #(.DELAY_COUNTS(2500)) db_inst ( // example 50us debounce at 20ns clk
                .clk(clk),
                .button(key_switches[i]),
                .button_pressed(debounced_keys[i])
            );
        end
    endgenerate

    // -------------------------------
    // Random Number Generator
    // -------------------------------
    wire [$clog2(1223)-1:0] random_value;
    rng #(
        .OFFSET(200),
        .MAX_VALUE(1223),
        .SEED(1)
    ) rng_inst (
        .clk(clk),
        .random_value(random_value)
    );

    // -------------------------------
    // Timer Module
    // -------------------------------
    wire [$clog2(2047)-1:0] timer_value;
    wire timer_enable, timer_reset;
    wire [1:0] level_number; // from FSM

    timer #(
        .MAX_MS(2047),
        .CLKS_PER_MS(50000) // adjust according to your clock frequency
    ) timer_inst (
        .clk(clk),
        .level(level_number),
        .enable(timer_enable),
        .timer_value(timer_value)
    );

    // -------------------------------
    // Whac-A-Mole FSM
    // -------------------------------
    wire [17:0] fsm_leds;
    wire ready_for_mole, timeout_start;
    wire [15:0] points;

    whac_a_mole_fsm fsm_inst (
        .clk(clk),
        .timeout(timer_value == 0),
        .toggle_switches(toggle_switches),
        .key_switches(debounced_keys),
        .led_number(fsm_leds),
        .ledx(),              // optional: unused
        .ready_for_mole(ready_for_mole),
        .timeout_start(timer_enable),
        .points(points),
        .level_number(level_number)
    );

    // -------------------------------
    // Switch to LED Validation
    // -------------------------------
    wire [17:0] valid_hit;
    assign valid_hit = toggle_switches & fsm_leds;

    // -------------------------------
    // LED Output Logic
    // -------------------------------
    assign leds = fsm_leds; // Display currently active mole

    // -------------------------------
    // 7-Segment Display Logic (points)
    // -------------------------------
    // Example: just display the lowest 4 bits of points on a single 7-segment digit
    seven_seg seg_inst (
        .bcd(points[3:0]),
        .segments(seg)
    );

    // Optional: simple single-digit anode enable
    always @(posedge clk) begin
        an <= 4'b1110; // activate first digit only
    end

endmodule
