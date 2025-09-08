module timer #(
    parameter MAX_MS = 3000,
    parameter CLKS_PER_MS = 50000
)(
    input clk, reset, up, enable,
    input [$clog2(MAX_MS)-1:0] start_value,
    output reg [$clog2(MAX_MS)-1:0] timer_value
);
    reg [$clog2(CLKS_PER_MS)-1:0] clk_counter;
    reg count_up;
    always @(posedge clk) begin
        if (reset) begin
            clk_counter <= 0;
            if (up) begin
                timer_value <= 0;
                count_up <= 1;
            end else begin
                timer_value <= start_value;
                count_up <= 0;
            end
        end else if (enable) begin
            if (clk_counter == CLKS_PER_MS - 1) begin
                clk_counter <= 0;
                if (count_up) begin
                    if (timer_value < MAX_MS)
                        timer_value <= timer_value + 1;
                end else begin
                    if (timer_value > 0)
                        timer_value <= timer_value - 1;
                end
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end
endmodule
