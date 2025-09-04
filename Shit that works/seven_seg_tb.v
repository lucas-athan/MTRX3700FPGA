module seven_seg_tb;

    reg  [3:0] bcd;   // Need to use `reg` here (set in always block).
    wire [6:0] segments;

    seven_seg seven_seg_u0 (
        .bcd(bcd),
        .segments(segments)
    );

    initial begin  // Run the following code starting from the beginning of the simulation.
        $dumpfile("waveform.vcd");  // Tell the simulator to dump variables into the 'waveform.vcd' file during the simulation.
        $dumpvars();
        
        repeat(10) begin
            // Assign random values to inputs (then cast to 4 bits):
            bcd = $urandom();  // Remove the 4' if using Quartus!!!
            
            // Log input and output values:
            $display("bcd=%d",bcd);

            #10; // Delay for 10 time units to ensure outputs are evaluated before the next $display.
            $display("segments=%07b",segments);
            #10; // Delay for 10 time units to provide a 20 time-unit gap before the next input.
            
        end

        $finish();  // Finish the simulation.
    end
    
endmodule
