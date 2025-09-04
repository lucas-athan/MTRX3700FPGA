// score_display.v
module score_display (
    input  wire [11:0] score,     // 0–255 from switches.v
    output reg [6:0] hex0,      // ones digit
    output reg [6:0] hex1,      // tens digit
    output reg [6:0] hex2,      // hund digit
    output reg [6:0] hex3,      // 'E'
    output reg [6:0] hex4,      // 'R'
    output reg [6:0] hex5,      // 'O'
    output reg [6:0] hex6,      // 'C'
    output reg [6:0] hex7       // 'S'
);

    // Seven seg wires
    wire [6:0] hex0_segments;
    wire [6:0] hex1_segments;
    wire [6:0] hex2_segments;

    // Split score into decimal digits
    reg [3:0] ones;
    reg [3:0] tens;
    reg [3:0] hund;

    always @(*) begin
        ones = score [3:0];
        tens = score [7:4];
        hund = score [11:8];

        // Static "score"
        hex7 = 7'b0010010; // S
        hex6 = 7'b1000110; // C
        hex5 = 7'b1000000; // O
        hex4 = 7'b1001110; // R
        hex3 = 7'b0000110; // E
    end

    // Instantiate three 7-seg drivers
    seven_seg seg0 (.bcd(ones), .segments(hex0_segments));
    seven_seg seg1 (.bcd(tens), .segments(hex1_segments));
    seven_seg seg2 (.bcd(hund), .segments(hex2_segments));

    assign hex0 = hex0_segments;
    assign hex1 = hex1_segments;
    assign hex2 = hex2_segments;

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