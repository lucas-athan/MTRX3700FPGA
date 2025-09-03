// This module orchestrates the timer and RNG to turn on a random LED for 0.5 seconds.
module random_led_sequencer (
    input wire clk,
    input wire reset_n, // Active-low reset
    input wire [$clog2(2047)-1:0] timer_value,
    input wire [$clog2(1223)-1:0] random_value,
    output reg [17:0] leds,
    output reg timer_enable,
    output reg timer_reset
);

    // State machine for controlling the sequence
    parameter IDLE = 2'b00;
    parameter WAIT_FOR_TIMER = 2'b01;

    reg [1:0] state;
    // The random index needs to be 5 bits to represent values up to 17.
    reg [4:0] selected_led_index; 

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            leds <= 18'b0;
            timer_enable <= 1'b0;
            timer_reset <= 1'b1;
            selected_led_index <= 5'd0;
        end else begin
            // Default assignments to avoid latches
            timer_reset <= 1'b0;
            timer_enable <= 1'b0;

            case (state)
                IDLE: begin
                    // When in idle, we are ready to start a new cycle.
                    // Map the random value to a valid LED index (0-17) using modulo.
                    selected_led_index <= random_value % 18; 
                    
                    // Reset the timer for a single clock cycle
                    timer_reset <= 1'b1;
                    
                    // Enable the timer to start counting up
                    timer_enable <= 1'b1;
                    
                    // Set the LEDs based on the selected index using one-hot encoding.
                    leds <= 18'b0;
                    leds[selected_led_index] <= 1'b1;
                    
                    // Transition to the next state
                    state <= WAIT_FOR_TIMER;
                end

                WAIT_FOR_TIMER: begin
                    // Keep the timer enabled and the LED on.
                    timer_enable <= 1'b1;
                    
                    // Check if 500ms have passed (MAX_MS for the timer is 2047)
                    if (timer_value >= 1000) begin
                        // Timer expired, return to IDLE state to pick a new LED.
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

