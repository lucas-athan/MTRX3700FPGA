/*
 * Synchronizers: Double-Register Incoming Data!
 *   When travelling through different clock-domains,
 *   it is good practice to always "double-register" ("double-flop")
 *   the signals once they have crossed over to the new domain
 *   (using the new domain's clock signal). This is called a "Synchronizer".
 *
 *   This prevents metastability, which can cause serious failures.
*/
module synchroniser (input clk, x, output y);
    reg x_q0, x_q1;
    always @(posedge clk)
    begin
        x_q0 <= x;    // Flip-flop #1
        x_q1 <= x_q0; // Flip-flop #2
    end
    assign y = x_q1;
endmodule