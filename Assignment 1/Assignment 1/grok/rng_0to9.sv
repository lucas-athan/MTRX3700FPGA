// ---------------------------------------------------------------------
// RNG 0..9 using a small LFSR and modulus mapping (fair for demo)
// ---------------------------------------------------------------------
module rng_0to9 (
    input  logic clk,
    output logic [3:0] random_value
);
    logic [15:0] lfsr;
    always_ff @(posedge clk) begin
        // simple LFSR; seed nonzero
        if (lfsr == 0) lfsr <= 16'hACE1;
        else lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end
    // Map to 0..9 with simple remainder (ok for demo)
    assign random_value = (lfsr % 10);
endmodule