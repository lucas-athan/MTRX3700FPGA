module debounce #(
    parameter DELAY_COUNTS = 50000 // 1 ms
) (
    input wire clk, button,
    output reg button_pressed
);
    wire button_sync;
    synchroniser button_synchroniser (.clk(clk), .x(button), .y(button_sync));
    reg prev_button;
    reg [$clog2(DELAY_COUNTS+1)-1:0] count;
    always @(posedge clk) begin
        if (button_sync != prev_button) begin
            count <= {($clog2(DELAY_COUNTS+1)){1'b0}};
        end
        else if (count == DELAY_COUNTS) begin
            count <= {($clog2(DELAY_COUNTS+1)){1'b0}};
        end
        else begin
            count <= count + 1'b1;
        end
    end
    always @(posedge clk) begin
        if (button_sync != prev_button) begin
            prev_button <= button_sync;
        end
    end
    always @(posedge clk) begin
        if (button_sync == prev_button && count == DELAY_COUNTS) begin
            button_pressed <= prev_button;
        end
    end
endmodule
