// RNG (Modified to avoid truncation warnings)
module rng (
    input clk,
    input enable,
    output reg [3:0] random_value
);
    reg [9:0] counter = 10'd0;
    always @(posedge clk) begin
        if (enable) begin
            counter <= counter + 10'd1;
            random_value <= (counter[3:0] > 4'd9) ? counter[3:0] - 4'd10 : counter[3:0]; // 0-9
        end
    end
endmodule
