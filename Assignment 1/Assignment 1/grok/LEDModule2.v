module led_output (
    input [3:0] led_number,
    output reg [9:0] LEDR
);

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
