// ---------------------------------------------------------------------
// Synchroniser module (2-FF)
// ---------------------------------------------------------------------
module synchroniser (input logic clk, input logic x, output logic y);
    logic ff0, ff1;
    always_ff @(posedge clk) begin
        ff0 <= x;
        ff1 <= ff0;
    end
    assign y = ff1;
endmodule