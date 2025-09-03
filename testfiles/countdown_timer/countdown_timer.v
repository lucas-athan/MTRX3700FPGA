module countdown_timer #(
    parameter CLK_TICKS_S = 50_000_000
)(
    input wire clk,
    input wire rst,
    output reg one_second_pulse
);
    reg [31:0] cycle_counter;           // Counter for ticks

    // Timer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter <= 0;
            one_second_pulse <= 0;
        end
        else begin
            if (cycle_counter == CLK_TICKS_S - 1) begin
                cycle_counter <= 0;
                one_second_pulse <= 1;
            end

            else begin
                cycle_counter <= cycle_counter + 1;
                one_second_pulse <= 0;
            end
        end
    end
    
endmodule