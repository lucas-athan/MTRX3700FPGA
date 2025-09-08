// Adapted display module
module display (
    input clk,
    input [11:0] value,
    output [3:0] display0, display1, display2, display3
);
    enum { Initialise, Add3, Shift, Result } next_state, current_state = Initialise;
    logic init, add, done;
    logic [3:0] count = 0;
    always_comb begin
        unique case (current_state)
            Initialise: next_state = Add3;
            Add3: next_state = Shift;
            Shift: next_state = (count == 4'd11) ? Result : Add3;
            Result: next_state = Initialise;
            default: next_state = Initialise;
        endcase
    end
    always_ff @(posedge clk) begin
        current_state <= next_state;
        if (current_state == Result)
            count <= 4'd0;
        else if (current_state == Shift)
            count <= count + 4'd1;
    end
    always_comb begin
        init = (current_state == Initialise);
        add = (current_state == Add3);
        done = (current_state == Result);
    end
    logic [3:0] bcd0, bcd1, bcd2, bcd3;
    logic [11:0] temp_value;
    always_ff @(posedge clk) begin
        if (init) begin
            {bcd3, bcd2, bcd1, bcd0, temp_value} <= {16'b0, value};
        end
        else begin
            if (add) begin
                bcd0 <= bcd0 > 4 ? bcd0 + 3 : bcd0;
                bcd1 <= bcd1 > 4 ? bcd1 + 3 : bcd1;
                bcd2 <= bcd2 > 4 ? bcd2 + 3 : bcd2;
                bcd3 <= bcd3 > 4 ? bcd3 + 3 : bcd3;
            end
            else begin
                {bcd3, bcd2, bcd1, bcd0, temp_value} <= {bcd3, bcd2, bcd1, bcd0, temp_value} << 1;
            end
        end
    end
    always_ff @(posedge clk) begin
        if (done) begin
            display0 <= bcd0;
            display1 <= bcd1;
            display2 <= bcd2;
            display3 <= bcd3;
        end
    end
endmodule