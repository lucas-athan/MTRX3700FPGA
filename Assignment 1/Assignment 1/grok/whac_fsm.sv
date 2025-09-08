// ---------------------------------------------------------------------
// FSM module: selects level after reset, runs gameplay, updates score.
// - KEY0 must be pressed to reset; then use KEY1/2/3 to choose level.
// - When gameplay is active, a mole appears for level-dependent ms
// - If corresponding SW pressed during mole -> +10 and new round.
// ---------------------------------------------------------------------
module whac_fsm (
    input  logic        clk,
    input  logic        rst,        // active-high reset (KEY0 press)
    input  logic        key1,       // active-high press pulses (KEY1)
    input  logic        key2,       // active-high press pulses (KEY2)
    input  logic        key3,       // active-high press pulses (KEY3)
    input  logic [9:0]  sw,         // debounced switches, 1 when ON
    input  logic [3:0]  rng_value,  // 0..9 source
    // outputs
    output logic [1:0]  level,      // 0..3
    output logic [13:0] score,      // binary score (0..9999)
    output logic [3:0]  active_mole,// valid when mole_valid==1
    output logic        mole_valid, // mole on/off
    output logic        start_new_round, // pulse when new mole chosen
    output logic        correct_hit_pulse // pulse on correct hit
);
    // state encoding
    typedef enum logic [1:0] {S_IDLE, S_LEVEL_SELECT, S_PLAY, S_SCORE_UPDATE} st_t;
    st_t state, next_state;

    // ms tick generation
    localparam int CLKS_PER_MS = 50000; // 50MHz -> 50k cycles per ms
    logic [15:0] clkms_cnt;
    logic tick_ms;
    always_ff @(posedge clk) begin
        if (clkms_cnt == CLKS_PER_MS - 1) begin
            clkms_cnt <= 0;
            tick_ms <= 1;
        end else begin
            clkms_cnt <= clkms_cnt + 1;
            tick_ms <= 0;
        end
    end

    // level -> mole duration in ms (you can tweak)
    function automatic int dur_ms(input logic [1:0] l);
        case (l)
            2'd0: dur_ms = 1000; // 1s
            2'd1: dur_ms = 700;  // 0.7s
            2'd2: dur_ms = 400;  // 0.4s
            2'd3: dur_ms = 200;  // 0.2s
            default: dur_ms = 1000;
        endcase
    endfunction

    // internal counters
    int ms_counter;
    logic [3:0] chosen_mole;
    logic start_pulse_reg;

    // edge detection for switch presses: create one-cycle pulses
    logic [9:0] sw_reg;
    logic [9:0] sw_posedge;
    always_ff @(posedge clk) begin
        sw_reg <= sw;
        sw_posedge <= sw & ~sw_reg;
    end

    // state machine next-state
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE: if (rst) next_state = S_LEVEL_SELECT;
            S_LEVEL_SELECT: if (key1 || key2 || key3) next_state = S_PLAY;
            S_PLAY: begin
                // either time expired or a switch was pressed
                if (ms_counter <= 0) next_state = S_SCORE_UPDATE;
                else if (|sw_posedge) next_state = S_SCORE_UPDATE;
            end
            S_SCORE_UPDATE: next_state = S_PLAY;
            default: next_state = S_IDLE;
        endcase
    end

    // state register
    always_ff @(posedge clk) begin
        if (rst) state <= S_LEVEL_SELECT;
        else state <= next_state;
    end

    // level & score updates
    always_ff @(posedge clk) begin
        // level selection when in level_select and a key is pressed
        if (rst) begin
            level <= 2'd0;
            score <= 14'd0;
        end else begin
            if (state == S_LEVEL_SELECT) begin
                if (key1) level <= 2'd1;
                else if (key2) level <= 2'd2;
                else if (key3) level <= 2'd3;
            end

            // on correct hit in S_SCORE_UPDATE we update score
            if (state == S_SCORE_UPDATE) begin
                // if user pressed the correct switch
                if (sw_posedge[chosen_mole]) begin
                    if (score <= 14'd9989) score <= score + 14'd10;
                    else score <= 14'd9999;
                end
            end
        end
    end

    // mole selection and timing
    always_ff @(posedge clk) begin
        // default pulses low
        start_pulse_reg <= 1'b0;
        correct_hit_pulse <= 1'b0;
        chosen_mole <= chosen_mole;

        if (state == S_LEVEL_SELECT) begin
            // stay idle until level chosen; no mole
            mole_valid <= 1'b0;
            ms_counter <= 0;
        end
        else if (state == S_PLAY) begin
            // when entering PLAY from LEVEL_SELECT or after score update, pick new mole
            if (next_state != state && state != S_PLAY) begin
                // choose RNG value 0..9, ensure <=9
                chosen_mole <= (rng_value < 10) ? rng_value : (rng_value % 10);
                ms_counter <= dur_ms(level);
                mole_valid <= 1'b1;
                start_pulse_reg <= 1'b1;
            end else begin
                // decrement ms_counter on tick_ms
                if (tick_ms) begin
                    if (ms_counter > 0) ms_counter <= ms_counter - 1;
                end
                // if user presses a switch, handle in SCORE_UPDATE transition
            end
        end
        else if (state == S_SCORE_UPDATE) begin
            // pulse correct_hit if user pressed correct switch this cycle
            if (sw_posedge[chosen_mole]) begin
                correct_hit_pulse <= 1'b1;
            end
            // clear current mole and prepare next round
            mole_valid <= 1'b0;
            ms_counter <= 0;
        end
        else begin
            mole_valid <= 1'b0;
            ms_counter <= 0;
        end
    end

    // hook outputs
    assign active_mole = chosen_mole[3:0];
    assign start_new_round = start_pulse_reg;

endmodule