`timescale 1ns/1ns /* This directive (`) specifies simulation <time unit>/<time precision>. */

module timer #(
    parameter MAX_MS = 2047,            // Maximum millisecond value
    parameter CLKS_PER_MS = 50000  // What is the number of clock cycles in a millisecond?
) (
    input                       clk,
    input                       reset,
    input                       up,
    input  [$clog2(MAX_MS)-1:0] start_value, // What does the $clog2() function do here?
    input                       enable,
    output [$clog2(MAX_MS)-1:0] timer_value
);

    // Your code here!
    reg [$clog2(CLKS_PER_MS)-1:0] clk_counter;
    reg [$clog2(MAX_MS)-1:0] ms_counter;
    reg count_up;

    assign timer_value = ms_counter;
    
    always @(posedge clk) begin
        if (reset) begin
            clk_counter <= 0;
            if (up == 1) begin
                ms_counter <= 0;
                count_up <= 1;
            end
            else begin
                ms_counter <= start_value;
                count_up <= 0;
            end
        end
        else if (enable) begin
            if (clk_counter >= CLKS_PER_MS-1) begin
                clk_counter <= 0;
                if (count_up == 1) begin
                    ms_counter <= ms_counter + 1;
                end
                else begin
                    ms_counter <= ms_counter - 1;
                end
            end
            else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

endmodule
