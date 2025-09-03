module display_timer (
    input wire clk,
    input wire rst,
    input wire one_second_pulse,
    output reg game_finished,
    output reg [6:0] HEX6,      // Ones
    output reg [6:0] HEX7       // Tens
);

    reg [3:0] ones;
    reg [3:0] tens;

    wire [6:0] hex6_segments;
    wire [6:0] hex7_segments;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_finished <= 0;
            ones <= 4'b0000;
            tens <= 4'b0011;
        end
        else if (one_second_pulse) begin
            if (tens == 0 && ones == 0) begin
                game_finished <= 1;
            end
            else if (ones == 0) begin
                ones <= 9;
                tens <= tens - 1;
            end
            else begin
                ones <= ones - 1;
            end
        end
    end

    // Instantiate three 7-seg drivers
    seven_seg seg6 (.bcd(ones), .segments(hex6_segments));
    seven_seg seg7 (.bcd(tens), .segments(hex7_segments));

    assign HEX6 = hex6_segments;
    assign HEX7 = hex7_segments;

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