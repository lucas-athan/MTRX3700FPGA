module rng_lfsr (
    input clk,
    input update,
    output reg [3:0] led_number
);

    reg [10:1] lfsr = 10'b1010101010; // initial seed
    wire feedback = lfsr[10] ^ lfsr[7];

    always @(posedge clk) begin
        if (update) begin
            lfsr <= {lfsr[9:1], feedback};  // shift LFSR
            led_number <= (lfsr[4:1] % 10); // map to 0–9
        end
    end

endmodule
