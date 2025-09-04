module display (
    input wire clk, // Added clock input
    input wire reset, // Added reset input
    input wire [15:0] binary_in,
    output wire [15:0] bcd_out
);
    // Intermediate registers for the double-dabble algorithm
    reg [3:0] bcd [3:0];
    reg [15:0] binary;
    reg [4:0] count;
    reg [15:0] temp_binary;

    // Output assignment from the internal registers
    assign bcd_out = {bcd[3], bcd[2], bcd[1], bcd[0]};

    // Main conversion logic
    always @(posedge clk) begin
        if (reset) begin
            bcd[0] <= 4'd0;
            bcd[1] <= 4'd0;
            bcd[2] <= 4'd0;
            bcd[3] <= 4'd0;
            binary <= binary_in;
            count <= 5'd0;
        end else if (count < 16) begin
            // Check each BCD digit and add 3 if it's greater than 4
            if (bcd[0] > 4) bcd[0] <= bcd[0] + 3;
            if (bcd[1] > 4) bcd[1] <= bcd[1] + 3;
            if (bcd[2] > 4) bcd[2] <= bcd[2] + 3;
            if (bcd[3] > 4) bcd[3] <= bcd[3] + 3;
            
            // Shift the entire value left by one bit
            {bcd[3], bcd[2], bcd[1], bcd[0], temp_binary} <= {bcd[3], bcd[2], bcd[1], bcd[0], binary} << 1;
            binary <= temp_binary;
            count <= count + 1;
        end
    end
endmodule