// debounce.v
module debounce #(
    parameter DELAY_COUNTS = 2500 // 50us with clk=20ns
)(
    input  clk,
    input  button,
    output reg button_pressed
);

  // Synchronize async button signal
  wire button_sync;
  synchroniser button_synchroniser (.clk(clk), .x(button), .y(button_sync));

  reg prev_button;
  reg [11:0] count;   // 12-bit counter to cover up to 2500

  // Counter logic
  always @(posedge clk) begin
      if (button_sync != prev_button) begin
        count <= 0;                           // restart counter if input changes
      end
      else if (count == DELAY_COUNTS) begin
        count <= count;                       // hold when max reached
      end
      else begin
        count <= count + 1;                   // increment otherwise
      end
  end

  // Previous button storage
  always @(posedge clk) begin
    prev_button <= button_sync;               // always update synchronously
  end

  // Debounced output generation
  always @(posedge clk) begin
    if (button_sync == prev_button && count == DELAY_COUNTS) begin
      button_pressed <= button_sync;          // stable long enough → accept new value
    end
    else begin
      button_pressed <= button_pressed;       // hold previous debounced output
    end
  end

endmodule

// Synchroniser
module synchroniser (input clk, x, output y);
    reg x_q0, x_q1;
    always @(posedge clk)
    begin
        x_q0 <= x;    // Flip-flop #1
        x_q1 <= x_q0; // Flip-flop #2
    end
    assign y = x_q1;
endmodule