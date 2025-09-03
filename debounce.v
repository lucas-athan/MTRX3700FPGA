//module debounce #(
//  parameter DELAY_COUNTS = 2500 /*FILL-IN*/ // 50us with clk period 20ns totals in ____ counts
//  // 20ns = 50MHz and then 50MHz x 50us = 2500 Counts.
//) (
//    input wire clk, button,
//    output reg button_pressed
//);
//
//  // Use a synchronizer to synchronize `button`.
//  wire button_sync; // Output of the synchronizer. Input to your debounce logic.
//
//
//  synchroniser button_synchroniser (.clk(clk), .x(button), .y(button_sync));
//
//  // Note: Use the synchronized `button_sync` wire as the input signal to the debounce logic.
//  /*** Fill in the following scaffold: ***/
//  /* FILL-IN TYPE */ reg prev_button;
//  reg [$clog2(DELAY_COUNTS+1)-1:0] count;
//  // Set the count flip-flop:
//  always @(posedge clk) begin
//      if (button_sync != prev_button) begin
//        count <= {($clog2(DELAY_COUNTS+1)){1'b0}};      // 0
//      end
//      else if (count == DELAY_COUNTS) begin
//        count <= {($clog2(DELAY_COUNTS+1)){1'b0}};      // 0
//      end
//      else begin
//        count <= count + 1'b1;
//      end
//  end
//
//  // Set the prev_button flip-flop:
//  always @(posedge clk) begin
//    if (button_sync != prev_button) begin
//      prev_button <= button_sync;
//    end
//    else begin
//      prev_button <= prev_button; //for hold
//    end
//  end
//
//  //reg button_pressed;
//  // Set the button_pressed flip-flop:
//  always @(posedge clk) begin
//    if (button_sync == prev_button && count == DELAY_COUNTS) begin
//      button_pressed <= prev_button;  // 1 for a stable press, 0 for release
//    end
//    else begin
//      button_pressed <= button_pressed; //(we wanna pput it on hold not the og "1'b0")
//    end
//  end
//
//endmodule






module debounce #(
    parameter DELAY_COUNTS = 2500, // 50us with 20ns clock period (50MHz)
    parameter NUM_SWITCHES = 22     // 18 SW + 4 KEY
) (
    input wire clk,                           // 50MHz clock
    input wire [NUM_SWITCHES-1:0] button,     // Input switches (SW[17:0], KEY[3:0])
    output reg [NUM_SWITCHES-1:0] button_pressed // Debounced outputs
);
    wire [NUM_SWITCHES-1:0] button_sync;
    genvar i;
    generate
        for (i = 0; i < NUM_SWITCHES; i = i + 1) begin : sync_loop
            synchroniser button_synchroniser (
                .clk(clk),
                .x(button[i]),
                .y(button_sync[i])
            );
        end
    endgenerate
    reg [NUM_SWITCHES-1:0] prev_button;
    reg [$clog2(DELAY_COUNTS+1)-1:0] count [NUM_SWITCHES-1:0];
    integer j;
    always @(posedge clk) begin
        for (j = 0; j < NUM_SWITCHES; j = j + 1) begin
            if (button_sync[j] != prev_button[j]) begin
                count[j] <= 0;
            end
            else if (count[j] == DELAY_COUNTS) begin
                count[j] <= 0;
            end
            else begin
                count[j] <= count[j] + 1;
            end
            prev_button[j] <= button_sync[j];
            if (button_sync[j] == prev_button[j] && count[j] == DELAY_COUNTS) begin
                button_pressed[j] <= prev_button[j];
            end
        end
    end
endmodule