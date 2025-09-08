// FSM:
module whac_a_mole_fsm (
    input clk,
    input [3:0] key_pressed,
    input [9:0] sw_pressed,
    input [3:0] random_led,
    input [11:0] timer_value,
    output reg [1:0] level,
    output reg [11:0] score,
    output reg timer_reset,
    output reg timer_enable,
    output reg rng_enable,
    output reg [9:0] ledr
);
    // Edge detection
    logic [3:0] key_d;
    logic [9:0] sw_d;
    always_ff @(posedge clk) begin
        key_d <= key_pressed;
        sw_d <= sw_pressed;
    end
    wire [3:0] key_edge = key_pressed & ~key_d;
    wire [9:0] sw_edge = sw_pressed & ~sw_d;

    // State machine
    typedef enum logic [1:0] {S1_LevelSelect = 2'b01, S2_Gameplay = 2'b10, S3_ScoreUpdate = 2'b11} state_t;
    state_t current_state = S1_LevelSelect, next_state;

    // Timer thresholds
    localparam [11:0] TIME_L0 = 12'd3000;
    localparam [11:0] TIME_L1 = 12'd2000;
    localparam [11:0] TIME_L2 = 12'd1000;
    localparam [11:0] TIME_L3 = 12'd500;
    localparam [11:0] LED_TOGGLE = 12'd2000; // 2 seconds for LED toggle
    reg [11:0] timer_threshold;

    // Next-state logic
    always_comb begin
        next_state = current_state;
        if (key_edge[0]) next_state = S1_LevelSelect; // Reset to LevelSelect from any state
        else case (current_state)
            S1_LevelSelect: if (key_edge[1] || key_edge[2] || key_edge[3]) next_state = S2_Gameplay;
            S2_Gameplay: if (timer_value >= timer_threshold || |sw_edge) next_state = S3_ScoreUpdate;
            S3_ScoreUpdate: next_state = S2_Gameplay;
            default: next_state = S1_LevelSelect;
        endcase
    end

    // State register
    always_ff @(posedge clk) begin
        current_state <= next_state;
    end

    // Output logic (all timer_reset assignments here)
    always_comb begin
        timer_reset = 1'b0;
        timer_enable = 1'b0;
        rng_enable = 1'b0;
        ledr = 10'b0;
        timer_threshold = TIME_L0;
        case (level)
            2'd0: timer_threshold = TIME_L0;
            2'd1: timer_threshold = TIME_L1;
            2'd2: timer_threshold = TIME_L2;
            2'd3: timer_threshold = TIME_L3;
        endcase
        case (current_state)
            S1_LevelSelect: begin
                timer_reset = 1'b1;
                ledr[9:8] = 2'b01;
                ledr[7:4] = {key_edge[3], key_edge[2], key_edge[1], key_edge[0]};
                ledr[3:0] = random_led;
            end
            S2_Gameplay: begin
                timer_enable = 1'b1;
                if (random_led < 10) ledr[random_led] = 1'b1;
                ledr[9:8] = 2'b10;
                ledr[7:6] = level;
                ledr[3:0] = random_led;
                if (timer_value >= LED_TOGGLE) begin
                    timer_reset = 1'b1;
                    rng_enable = 1'b1;
                end
            end
            S3_ScoreUpdate: begin
                timer_reset = 1'b1;
                rng_enable = 1'b1;
                ledr[9:8] = 2'b11;
                ledr[7:6] = level;
                ledr[3:0] = random_led;
            end
        endcase
    end

    // Level and score update
    always_ff @(posedge clk) begin
        if (key_edge[0]) begin
            level <= 2'd0;
            score <= 12'd0;
        end
        else if (current_state == S1_LevelSelect) begin
            if (key_edge[1]) level <= 2'd1;
            else if (key_edge[2]) level <= 2'd2;
            else if (key_edge[3]) level <= 2'd3;
        end
        else if (current_state == S3_ScoreUpdate && |sw_edge && random_led < 10) begin
            if (sw_edge[random_led]) score <= (score <= 12'd9989) ? score + 12'd10 : score;
        end
    end
endmodule


