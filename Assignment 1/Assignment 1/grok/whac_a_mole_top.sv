// whac_a_mole_de1.sv
// SystemVerilog single-file implementation for Whac-a-Mole (DE1-SoC)
// - Uses KEY[0] reset (must press reset then KEY1/2/3 to set level)
// - SW[0..9] are whack inputs; LEDR[0..9] show moles (one-hot)
// - Score displayed as: HEX5='L', HEX4=level, HEX3..HEX0 = 4-digit BCD score
// - Score increments by 10 for correct hit.

module whac_a_mole_top (
    input  logic        CLOCK_50,      // 50 MHz
    input  logic [3:0]  KEY,           // active-low buttons KEY0..KEY3
    input  logic [9:0]  SW,            // switches SW0..SW9
    output logic [9:0]  LEDR,          // LEDs
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    // -----------------------------------------------------------------
    // 1) Synchronize + debounce all keys and switches
    // -----------------------------------------------------------------
    logic [3:0] key_sync;
    logic [3:0] key_db;    // debounced (still active-low)
    logic [3:0] key_press; // active-high pressed signals
    logic [9:0] sw_sync;
    logic [9:0] sw_db;     // debounced switches (1 = pressed/on)

    genvar gi;
    // synchronise keys
    generate for (gi = 0; gi < 4; gi = gi + 1) begin : KEY_SYNC
        synchroniser uks(.clk(CLOCK_50), .x(KEY[gi]), .y(key_sync[gi]));
    end endgenerate
    // synchronise switches
    generate for (gi = 0; gi < 10; gi = gi + 1) begin : SW_SYNC
        synchroniser usw(.clk(CLOCK_50), .x(SW[gi]), .y(sw_sync[gi]));
    end endgenerate

    // debounce keys (active-low) and switches (assume plain toggles active-high)
    generate for (gi = 0; gi < 4; gi = gi + 1) begin : KEY_DB
        debounce #(.DELAY_COUNTS(2500)) dkb (.clk(CLOCK_50), .button(key_sync[gi]), .button_pressed(key_db[gi]));
    end endgenerate

    generate for (gi = 0; gi < 10; gi = gi + 1) begin : SW_DB
        debounce #(.DELAY_COUNTS(2500)) dsw (.clk(CLOCK_50), .button(sw_sync[gi]), .button_pressed(sw_db[gi]));
    end endgenerate

    // convert key_db (active-low) -> active-high edgeable press signals
    // key_db == 1 means button released (since KEY is active-low), so pressed = ~key_db
    // We'll create single-cycle edge pulses inside FSM using these levels.
    assign key_press = ~key_db;

    // -----------------------------------------------------------------
    // 2) RNG (0..9) for selecting a mole index
    // -----------------------------------------------------------------
    logic [3:0] rng_value;
    rng_0to9 u_rng(.clk(CLOCK_50), .random_value(rng_value));

    // -----------------------------------------------------------------
    // 3) FSM: game logic
    // -----------------------------------------------------------------
    logic [1:0] level;          // 0..3
    logic [13:0] score;         // binary score (we'll clamp to 9999)
    logic [3:0] active_mole;    // index 0..9 (we'll only use 0..9)
    logic mole_valid;           // 1 when a mole currently ON
    logic [31:0] mole_period_ms; // period in milliseconds for current level
    logic start_new_round;      // pulse to pick new mole
    logic correct_hit_pulse;    // single-cycle pulse when a correct hit happens

    whac_fsm u_whac_fsm (
        .clk(CLOCK_50),
        .rst(key_press[0]),    // active-high reset when KEY0 pressed (user required)
        .key1(key_press[1]),
        .key2(key_press[2]),
        .key3(key_press[3]),
        .sw(sw_db),
        .rng_value(rng_value),
        .level(level),
        .score(score),
        .active_mole(active_mole),
        .mole_valid(mole_valid),
        .start_new_round(start_new_round),
        .correct_hit_pulse(correct_hit_pulse)
    );

    // LED mapping: show mole only if mole_valid
    always_comb begin
        LEDR = 10'b0;
        if (mole_valid && active_mole < 10)
            LEDR[active_mole] = 1'b1;
    end

    // -----------------------------------------------------------------
    // 4) Score -> display: convert to 4 BCD digits
    // -----------------------------------------------------------------
    logic [3:0] d0, d1, d2, d3; // BCD digits (least to most significant)
    bin2bcd_4digits u_bcd(.bin(score > 9999 ? 14'd9999 : score[13:0]), .bcd({d3,d2,d1,d0}));

    // HEX mapping: HEX5 = 'L', HEX4 = level digit (0..3)
    seven_seg u_hex0(.bcd(d0), .segments(HEX0));
    seven_seg u_hex1(.bcd(d1), .segments(HEX1));
    seven_seg u_hex2(.bcd(d2), .segments(HEX2));
    seven_seg u_hex3(.bcd(d3), .segments(HEX3));
    seven_seg u_hex4(.bcd({2'b00, level}), .segments(HEX4)); // level 0..3 fits in 4 bits
    // HEX5: show 'L' glyph. We'll pass code 4'b1010 to indicate 'L' in seven_seg module.
    seven_seg u_hex5(.bcd(4'b1010), .segments(HEX5));

endmodule