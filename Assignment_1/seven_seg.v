// Seven_seg
module seven_seg (
    input [3:0] bcd,
    output reg [6:0] segments
);
    always @(bcd) begin
        case (bcd)
            4'd0: segments = 7'b1000000;
            4'd1: segments = 7'b1111001;
            4'd2: segments = 7'b0100100;
            4'd3: segments = 7'b0110000;
            4'd4: segments = 7'b0011001;
            4'd5: segments = 7'b0010010;
            4'd6: segments = 7'b0000010;
            4'd7: segments = 7'b1111000;
            4'd8: segments = 7'b0000000;
            4'd9: segments = 7'b0010000;
            4'd10: segments = 7'b1000111; // L
            default: segments = 7'b1111111;
        endcase
    end
endmodule

