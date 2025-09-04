// rng.v
module rng #(
    parameter LED_COUNT = 18,
    parameter SEED = 5'b01010,
    parameter LVL0 = 50_000_000,  // 2.5s
    parameter LVL1 = 20_000_000,  // 1s 
    parameter LVL2 = 10_000_000  // 0.5s
)(
    input  wire clk,
    input  wire rst,
    input  wire [1:0] level,   // 00 -> LVL0, 01 -> LVL1, 10 -> LVL2
    output reg  [4:0] led_index,
    output reg  led_request
);
    // 5-bit LFSR
    reg [4:0] lfsr;  // seed = 10 (must not be zero)
    wire feedback = lfsr[4] ^ lfsr[2];  // Feedback

    reg [31:0] cycle_counter;           // Counter for when to send random number
    reg [31:0] number_of_cycles;        // Number of cycles to count too

    always @(posedge clk) begin
        case(level)
            2'b00: number_of_cycles = LVL0;
            2'b01: number_of_cycles = LVL1;
            2'b10: number_of_cycles = LVL2;
            default: number_of_cycles = LVL0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr          <= SEED;
            cycle_counter <= 0;
            led_request   <= 0;
            led_index     <= 0;
        end 
        else begin
            led_request <= 0;  // default low
            lfsr <= {lfsr[3:0], feedback}; // update lfsr



            // If cycle_counter has reached trigger_cycle send signal out
            if (cycle_counter == number_of_cycles - 1) begin
                cycle_counter <= 0;                
                led_index <= lfsr % LED_COUNT;
                led_request <= 1;
            end

            else begin
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

endmodule