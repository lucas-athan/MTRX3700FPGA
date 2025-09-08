// Score Manager (Simplified for DE1-SoC)
module score_manager #(
    parameter MAX_SCORE = 9999,
    parameter NUM_LEDS = 10
)(
    input  logic                        clk,
    input  logic                        reset_n,
    input  logic                        enable,
    input  logic [NUM_LEDS-1:0]         sw_edge,              // Switch toggle edges from FSM
    input  logic [$clog2(NUM_LEDS)-1:0] random_led,           // Index of active LED
    input  logic                        miss,                 // Timeout signal
    output logic [$clog2(MAX_SCORE):0]  score                 // Current score
);
    // Correct hit detection
    logic correct_hit;
    always_comb begin
        correct_hit = (random_led < NUM_LEDS) && sw_edge[random_led];
    end

    // Score update
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            score <= 12'd0;
        end
        else if (enable) begin
            if (correct_hit) begin
                if (score <= MAX_SCORE - 12'd10)
                    score <= score + 12'd10;
                else
                    score <= MAX_SCORE;
            end
            // No change for wrong hits or misses
        end
    end
endmodule
