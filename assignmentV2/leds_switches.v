// leds_switches.v
module leds_switches #(
    parameter CLK_PERIOD_NS = 50,
    parameter ON_TIME_SEC   = 5
)(
    input  wire         clk,
    input  wire         rst,
    input  wire [4:0]   led_index,      // which LED to turn on
    input  wire         led_request,    // Enable signal: turn on LED
    input  wire [17:0]  switches,       // Switches
    output reg  [17:0]  leds,           // LED outputs
    output reg  [11:0]  score           // Score
);
    localparam integer CYCLES = (ON_TIME_SEC * 1_000_000_000) / CLK_PERIOD_NS;

    reg [31:0] counters [0:17];   // 18 counters, each large enough for 100,000,000
    integer i;
    integer j;

    // Led Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            score <= 0;
            leds <= 18'b0;
            for (i = 0; i < 18; i = i + 1) begin
                counters[i] <= 0;   // Set counters to 0
            end
        end

        else begin
            // Decrement Counters
            for (i = 0; i < 18; i = i + 1) begin
                if (counters[i] > 0) begin
                    counters[i] <= counters[i] - 1;
                    leds[i] <= 1'b1;
                end
                else begin
                    leds[i] <= 1'b0;
                end
            end

            // Check switch hits
            for (j = 0; j < 18; j = j + 1) begin
                if (leds[j] && switches[j]) begin
                    leds[j] <= 1'b0;    // Turn led off
                    counters[j] <= 0;   // Reset Counter
                    score <= score + 1; // Increment score
                end
            end

            // Handle new request
            if (led_request && (led_index < 18)) begin
                if (counters[led_index] == 0) begin  // Check an existing timer isn't running
                    counters[led_index] <= CYCLES;   // load 5s timer
                end
            end
        end
    end

endmodule