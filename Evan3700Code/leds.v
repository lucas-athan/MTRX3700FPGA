module leds #(
    parameter CLK_PERIOD_NS = 50,
    parameter LED_COUNT     = 18,
    parameter ON_TIME_SEC   = 5
)(
    input  wire              clk,
    input  wire              rst,
    input  wire [4:0]        led_index,    // which LED to turn on
    input  wire              led_request,  // enable signal: turn on LED
    output wire [LED_COUNT-1:0] LEDR       // LED outputs
);

    // Calculate clock cycles needed for ON_TIME_SEC parameter
    localparam integer CYCLES = (ON_TIME_SEC * 1_000_000_000) / CLK_PERIOD_NS;

    reg [31:0] counters [0:LED_COUNT-1];   // 18 counters, each large enough for 100,000,000
    integer i;

    // LED outputs are "on if counter > 0"
    genvar k;
    generate
        for (k = 0; k < LED_COUNT; k = k + 1) begin : led_assign
            assign LEDR[k] = (counters[k] != 0);
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        // If rst is triggered, turn all the LED counters off
        if (rst) begin
            for (i = 0; i < LED_COUNT; i = i + 1) begin
                counters[i] <= 0;
            end
        end

        else begin
            // Each cycle decrement active LED counters
            for (i = 0; i < LED_COUNT; i = i + 1) begin
                if (counters[i] > 0)
                    counters[i] <= counters[i] - 1;
            end

            // Handle new request: If LED is turned on start counter but only if counter is 0 (not already on)
            if (led_request && (led_index < LED_COUNT)) begin
                if (counters[led_index] == 0)       // Check an existing timer isn't running
                    counters[led_index] <= CYCLES;  // load 5s timer
            end
        end
    end

endmodule