module flash_lights(
	input [3:0] number,
	output reg [9:0] led_num
);
	
	always @(*) begin
		case(number)
			4'd0: led_num = 10'b0000000001; 
			4'd1: led_num = 10'b0000000010; 
			4'd2: led_num = 10'b0000000100;  
			4'd3: led_num = 10'b0000001000;
			4'd4: led_num = 10'b0000010000;
			4'd5: led_num = 10'b0000100000;
			4'd6: led_num = 10'b0001000000;
			4'd7: led_num = 10'b0010000000;
			4'd8: led_num = 10'b0100000000;
			4'd9: led_num = 10'b1000000000;
			default: led_num = 10'b0000000000; 
		endcase
	end
	

endmodule 