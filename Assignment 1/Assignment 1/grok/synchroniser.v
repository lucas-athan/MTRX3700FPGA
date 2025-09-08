// Unchanged modules
module synchroniser (input clk, x, output y);
    reg x_q0, x_q1;
    always @(posedge clk) begin
        x_q0 <= x;
        x_q1 <= x_q0;
    end
    assign y = x_q1;
endmodule
