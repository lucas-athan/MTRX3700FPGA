module clock_1s (
    input clk,
    output reg update
);

    reg [25:0] delay_counter = 0;

    always @(posedge clk) begin
        if (delay_counter == 26'd50000000) begin
            delay_counter <= 0;
            update <= 1;
        end else begin
            delay_counter <= delay_counter + 1;
            update <= 0;
        end
    end

endmodule
