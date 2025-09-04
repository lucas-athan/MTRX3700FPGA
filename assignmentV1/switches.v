// switches.v
module switches (
    input  wire        clk,         // system clock
    input  wire        rst,         // active-high reset
    input  wire [17:0] led_in,      // LED pattern from leds.v
    input  wire [17:0] sw,          // physical switches SW[17:0]
    output reg  [17:0] led_out,     // updated LED pattern (after hits)
    output reg  [11:0] score        // score counter (0–255 for now)
);

    integer i;
    reg [17:0] sw_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            score    <= 0;
            led_out  <= 18'b0;
            sw_prev  <= 18'b0;
        end
        else begin
            // start with LED state from leds.v
            led_out <= led_in;

            // check each switch vs LED
            for (i = 0; i < 18; i = i + 1) begin
                if (led_in[i] && sw[i] && !sw_prev[i]) begin
                    led_out[i] <= 1'b0;   // "hit" -> turn off LED
                    score      <= score + 1;
                end
            end

            sw_prev <= sw;  // store switches for edge detection
        end
    end

endmodule