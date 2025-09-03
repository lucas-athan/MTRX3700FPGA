`timescale 1ns/1ns /* This directive (`) specifies simulation <time unit>/<time precision>. */

module timer #(
    parameter MAX_MS = 2047,            // Maximum millisecond value
    parameter CLKS_PER_MS = 50000 // What is the number of clock cycles in a millisecond?
) (
    input                       clk,
    input                       stop,
    input  [$clog2(MAX_MS)-1:0] start_value, // What does the $clog2() function do here?
    input                       enable,
    output  [$clog2(MAX_MS)-1:0] timer_value,
);
    reg [$clog2(CLKS_PER_MS)-1:0] count_cycles;
    reg [$clog2(MAX_MS)-1:0]      count;
    reg over;
    reg [$clog2(MAX_MS)-1:0] timer;

    assign timer_value = count;


    always @(posedge clk) begin

        if (stop)  begin 
            count <= start_value ;
            count_cycles <=0 ;
        end 

        else if (enable && count != 0) begin 
            count_cycles <= count_cycles + 1; 

            if (count_cycles >= CLKS_PER_MS - 1 ) begin 
                count_cycles <= 0; 
                count <= count - 1;
            end 
        end 
    end
endmodule 







