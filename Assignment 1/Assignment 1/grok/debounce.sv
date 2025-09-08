// ---------------------------------------------------------------------
// Debounce: counter-based, uses synchroniser inside
// - parameter DELAY_COUNTS = number of clk cycles to confirm stability
// ---------------------------------------------------------------------
module debounce #(
    parameter int DELAY_COUNTS = 2500
) (
    input  logic clk,
    input  logic button,           // raw (synchronised) input
    output logic button_pressed    // debounced output (logic level of button)
);
    logic btn_sync;
    // use synchroniser to be safe even if caller didn't call one
    synchroniser u_s(.clk(clk), .x(button), .y(btn_sync));

    logic prev;
    logic [$clog2(DELAY_COUNTS+1)-1:0] count;

    // count stability
    always_ff @(posedge clk) begin
        if (btn_sync != prev) begin
            count <= '0;
            prev  <= btn_sync; // update immediate tracked level
        end else if (count < DELAY_COUNTS) begin
            count <= count + 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (count == DELAY_COUNTS)
            button_pressed <= prev;
    end
endmodule