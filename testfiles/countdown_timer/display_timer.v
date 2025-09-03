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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_finished <= 0;
            ones <= 4'b0000;
            tens <= 4'b0011;
        end
        else begin
            if (ones == 4'b0000) begin
                if (tens == 4'b0000) begin
                    game_finished <= 1;
                end
                else begin
                    case (tens)
                        4'b0011: tens <= 4'b0010;
                        4'b0010: tens <= 4'b0001;
                    endcase
                end
            end
            else begin
                case (ones)
                    4'b1001: ones <= 4'b1000;  // 9 -> 8
                    4'b1000: ones <= 4'b0111;  // 8 -> 7
                    4'b0111: ones <= 4'b0110;  // 7 -> 6
                    4'b0110: ones <= 4'b0101;  // 6 -> 5
                    4'b0101: ones <= 4'b0100;  // 5 -> 4
                    4'b0100: ones <= 4'b0011;  // 4 -> 3
                    4'b0011: ones <= 4'b0010;  // 3 -> 2
                    4'b0010: ones <= 4'b0001;  // 2 -> 1
                    4'b0001: ones <= 4'b0000;  // 1 -> 0
                endcase
            end
        end
    end

    // Instantiate three 7-seg drivers
    seven_seg seg6 (.bcd(ones), .segments(HEX6));
    seven_seg seg7 (.bcd(tens), .segments(HEX7));

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