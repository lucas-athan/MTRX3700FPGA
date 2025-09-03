`timescale 1ns / 1ps

module led_output_tb;

    // Testbench signals
    reg [3:0] led_number;
    wire [9:0] LEDR;

    // Instantiate the LED module
    led_output uut (
        .led_number(led_number),
        .LEDR(LEDR)
    );

    integer i;

    initial begin
        // Display header
        $display("Time(ns) | led_number | LEDR");

        // Test all possible led_number values 0–9
        for (i = 0; i < 10; i = i + 1) begin
            led_number = i;
            #10; // wait 10 ns for combinational logic to propagate
            $display("%8t |     %0d     | %b", $time, led_number, LEDR);
        end

        // Finish simulation
        $display("Test completed.");
        $finish;
    end

endmodule
