// This module increments a counter when a switch is pressed high.
// The count is converted to BCD for seven-segment display.
module simple_counter (
    input wire clk,
    input wire rst,
    input wire switch_in,
    output wire [15:0] count_bcd_out
);
    
    // --- Debounce Logic ---
    // A counter to wait for the switch to settle.
    localparam DEBOUNCE_DELAY_COUNT = 2499999; // Adjust as needed
    reg [24:0] debounce_count;
    reg debounced_switch;
    reg prev_debounced_switch;
    wire debounced_switch_rising_edge;

    // Detect the rising edge of the switch press
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_debounced_switch <= 1'b0;
            debounced_switch <= 1'b0;
            debounce_count <= 0;
        end else begin
            if (switch_in != debounced_switch) begin
                debounce_count <= debounce_count + 1;
            end else begin
                debounce_count <= 0;
            end

            if (debounce_count == DEBOUNCE_DELAY_COUNT) begin
                debounced_switch <= switch_in;
                prev_debounced_switch <= debounced_switch;
            end
        end
    end
    
    assign debounced_switch_rising_edge = debounced_switch && !prev_debounced_switch;

    // --- Counter Logic ---
    reg [15:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 16'd0;
        end else if (debounced_switch_rising_edge) begin
            count <= count + 1;
        end
    end

    // --- Binary to BCD converter (16-bit -> 4-digit BCD) ---
    function [15:0] bin2bcd (input [15:0] bin);
        integer i;
        reg [31:0] shift_reg;
        begin
            shift_reg = {16'b0, bin}; 
            for (i = 0; i < 16; i = i + 1) begin
                if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
                if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
                if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;
                if (shift_reg[31:28] >= 5) shift_reg[31:28] = shift_reg[31:28] + 3;
                shift_reg = shift_reg << 1;
            end
            bin2bcd = shift_reg[31:16];
        end
    endfunction
    
    assign count_bcd_out = bin2bcd(count);

endmodule
