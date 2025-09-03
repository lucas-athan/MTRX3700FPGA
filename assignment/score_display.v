// score_display.v
module score_display (
    input  wire [7:0] SCORE,     // 0–255 from switches.v
    output wire [6:0] HEX0,      // ones digit
    output wire [6:0] HEX1,      // tens digit
    output wire [6:0] HEX2,      // hundreds digit
    output reg  [6:0] HEX3,      // 'E'
    output reg  [6:0] HEX4,      // 'R'
    output reg  [6:0] HEX5,      // 'O'
    output reg  [6:0] HEX6,      // 'C'
    output reg  [6:0] HEX7       // 'S'
);

    // Seven seg wires
    wire [6:0] hex0_segments;
    wire [6:0] hex1_segments;
    wire [6:0] hex2_segments;

    // Split score into decimal digits
    reg [3:0] ones;
    reg [3:0] tens;
    reg [3:0] hundreds;

    always @(*) begin
        ones     = SCORE % 10;
        tens     = (SCORE / 10) % 10;
        hundreds = (SCORE / 100) % 10;

        // Static "SCORE"
        HEX7 = 7'b0010010; // S
        HEX6 = 7'b1000110; // C
        HEX5 = 7'b1000000; // O
        HEX4 = 7'b1001110; // R
        HEX3 = 7'b0000110; // E
    end

    // Instantiate three 7-seg drivers
    seven_seg seg0 (.bcd(ones),     .segments(hex0_segments));
    seven_seg seg1 (.bcd(tens),     .segments(hex1_segments));
    seven_seg seg2 (.bcd(hundreds), .segments(hex2_segments));

    assign HEX0 = hex0_segments;
    assign HEX1 = hex1_segments;
    assign HEX2 = hex2_segments;

endmodule

module seven_seg (
    input      [3:0]  bcd,
    output reg [6:0]  segments // Must be reg to set in always block!!
);

    always @(*) begin
        case (bcd)
            4'b0000: segments = 7'b1000000; // 0
            4'b0001: segments = 7'b1111001; // 1
            4'b0010: segments = 7'b0100100; // 2
            4'b0011: segments = 7'b0110000; // 3
            4'b0100: segments = 7'b0011001; // 4
            4'b0101: segments = 7'b0010010; // 5
            4'b0110: segments = 7'b0000010; // 6
            4'b0111: segments = 7'b1111000; // 7
            4'b1000: segments = 7'b0000000; // 8
            4'b1001: segments = 7'b0010000; // 9
            default: segments = 7'b1111111; // OFF
        endcase
    end

endmodule