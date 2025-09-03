module rng #(
    parameter LED_COUNT = 18,
    parameter SEED = 10,
    parameter LVL0 = 50_000_000,  // ~2.5s
    parameter LVL1 = 20_000_000,  // ~1s 
    parameter LVL2 = 10_000_000   // ~0.5s
)(
    input  wire clk,
    input  wire rst,
    input  wire [1:0] level,               // difficulty
    input  wire [$clog2(LED_COUNT):0] active_led_count, // number of LEDs currently on
    output reg  [$clog2(LED_COUNT)-1:0] led_index,
    output reg  led_request,
    output reg  game_over
);
    // LFSR
    reg [4:0] lfsr;  
    initial lfsr = SEED;
    wire feedback = lfsr[4] ^ lfsr[2];

    // Cycle counters
    reg [31:0] cycle_counter;
    reg [31:0] base_cycles;
    reg [31:0] current_cycles;

    // Speed-up timer
    reg [31:0] speed_counter;
    localparam SPEEDUP_INTERVAL = 100_000_000; // ~2s @ 50 MHz
    localparam MIN_CYCLES       = 5_000_000;   // don’t go faster than 0.1s

    // Difficulty selection
    always @(*) begin
        case(level)
            2'b01: base_cycles = LVL1;
            2'b10: base_cycles = LVL2;
            default: base_cycles = LVL0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr           <= SEED;
            cycle_counter  <= 0;
            speed_counter  <= 0;
            current_cycles <= LVL0;
            led_request    <= 0;
            led_index      <= 0;
            game_over      <= 0;
        end
        else begin
            led_request <= 0;

            // Check for game over
            if (active_led_count >= 15) begin
                game_over <= 1;
            end 
            else begin
                game_over <= 0;
            end

            // Progressive speed-up
            if (speed_counter >= SPEEDUP_INTERVAL) begin
                speed_counter <= 0;

                // shrink delay by ~1.2x
                current_cycles <= (current_cycles * 10) / 12; 
                if (current_cycles < MIN_CYCLES)
                    current_cycles <= MIN_CYCLES;
            end 
            else begin
                speed_counter <= speed_counter + 1;
            end

            // LED trigger logic
            if (cycle_counter >= current_cycles - 1) begin
                cycle_counter <= 0;

                // shift LFSR
                lfsr <= {lfsr[3:0], feedback};

                // map to LED range
                led_index <= lfsr % LED_COUNT;
                led_request <= 1;
            end 
            else begin
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

endmodule