module top_level (
    input CLOCK_50,
    output [9:0] LEDR
);

    wire update;
    wire [3:0] led_number;

    // Instantiate clock module
    clock_1s clk_inst (
        .clk(CLOCK_50),
        .update(update)
    );

    // Instantiate RNG module
    rng_lfsr rng_inst (
        .clk(CLOCK_50),
        .update(update),
        .led_number(led_number)
    );

    // Instantiate LED output module
    led_output led_inst (
        .led_number(led_number),
        .LEDR(LEDR)
    );

endmodule


//Demo to show functionality, not needed for final product 
/*
module top_level (
    input CLOCK_50,
    output reg [9:0] LEDR
);

    // ----------------------------
    // 1. Delay counter for ~1 sec
    // ----------------------------
    reg [25:0] delay_counter = 0;
    wire update;
    assign update = (delay_counter == 26'd50000000);

    always @(posedge CLOCK_50) begin
        if (delay_counter == 26'd50000000)
            delay_counter <= 0;
        else
            delay_counter <= delay_counter + 1;
    end

    // ----------------------------
    // 2. LFSR RNG
    // ----------------------------
    reg [10:1] lfsr = 10'b1010101010; // initial seed
    wire feedback = lfsr[10] ^ lfsr[7];
    reg [3:0] led_number;

    always @(posedge CLOCK_50) begin
        if (update) begin
            lfsr <= {lfsr[9:1], feedback};  // shift LFSR
            led_number <= (lfsr[4:1] % 10); // map to 0–9
        end
    end

    // ----------------------------
    // 3. Flash single LED
    // ----------------------------
    always @(*) begin
        case (led_number)
            4'd0: LEDR = 10'b0000000001;
            4'd1: LEDR = 10'b0000000010;
            4'd2: LEDR = 10'b0000000100;
            4'd3: LEDR = 10'b0000001000;
            4'd4: LEDR = 10'b0000010000;
            4'd5: LEDR = 10'b0000100000;
            4'd6: LEDR = 10'b0001000000;
            4'd7: LEDR = 10'b0010000000;
            4'd8: LEDR = 10'b0100000000;
            4'd9: LEDR = 10'b1000000000;
            default: LEDR = 10'b0000000000;
        endcase
    end

endmodule
*/
