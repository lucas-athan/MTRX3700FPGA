//module debounce_switch_tb (
//    input         CLOCK_50,   // 50 MHz FPGA clock
//    input  [3:0]  KEY,        // Push buttons (active-low)
//    input  [17:0] SW,         // Toggle switches = whack inputs
//    output [17:0] LEDR,       // Red LEDs = moles
//    output [6:0]  HEX0, HEX1, HEX2, HEX3 // Score display
//);
//
//    // --- Intermediate wires ---
//    wire reset_n;                  // active-low reset from KEY[0]
//    wire [17:0] sw_debounced;      // debounced switch inputs
//    wire [3:0]  digit0, digit1, digit2, digit3; // BCD score digits
//    wire [17:0] moles;             // FSM mole outputs
//    wire [15:0] score;             // binary score
//
//    // --- Debounce all 18 switches ---
//    genvar i;
//    generate
//        for (i=0; i<18; i=i+1) begin : debounce_switches
//            debounce u_db (
//                .clk(CLOCK_50),
//                .button(SW[i]),
//                .button_pressed(sw_debounced[i])
//            );
//        end
//    endgenerate
//
//    // --- Debounce reset button (KEY[0]) ---
//    debounce u_db_reset (
//        .clk(CLOCK_50),
//        .button(KEY[0]),
//        .button_pressed(reset_n)
//    );
//
//    // --- Whac-a-Mole FSM ---
////    whac_a_mole_fsm u_fsm (
////        .clk(CLOCK_50),
////        .reset(~reset_n),         // active-high reset
////        .whack_inputs(sw_debounced),
////        .mole_outputs(moles),     // drives LEDR
////        .score(score)             // updates score
////    );
//
//    // --- Drive LEDs with mole activity ---
//    assign LEDR = moles;
//
//    // --- Score Display ---
////    display u_display (
////        .clk(CLOCK_50),
////        .value(score),       // assumes score is 11-bit max, like reaction game
////        .display0(HEX0),
////        .display1(HEX1),
////        .display2(HEX2),
////        .display3(HEX3)
////    );
//
//endmodule


module debounce_switch_tb;
    parameter NUM_SWITCHES = 22;
    parameter CLK_PERIOD = 20;
	 parameter DELAY_COUNTS = 2500;
    reg clk;
    reg [NUM_SWITCHES-1:0] button;
    wire [NUM_SWITCHES-1:0] button_pressed;
    debounce #(
        .DELAY_COUNTS(2500),
        .NUM_SWITCHES(NUM_SWITCHES)
    ) dut (
        .clk(clk),
        .button(button),
        .button_pressed(button_pressed)
    );
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, debounce_switch_tb);
        button = 0;
        #100;
        button[0] = 1; // SW[0] press
        #20 button[0] = 0;
        #20 button[0] = 1;
        #20 button[0] = 0;
        #20 button[0] = 1;
        #(DELAY_COUNTS * CLK_PERIOD);
        $display("SW[0] pressed: %b", button_pressed[0]);
        #100;
        button[18] = 1; // KEY[0] press
        #(DELAY_COUNTS * CLK_PERIOD);
        $display("KEY[0] pressed: %b", button_pressed[18]);
        button[18] = 0;
        #20 button[18] = 1;
        #20 button[18] = 0;
        #(DELAY_COUNTS * CLK_PERIOD);
        $display("KEY[0] released: %b", button_pressed[18]);
        #100;
        button[1] = 1; // SW[1]
        button[19] = 1; // KEY[1]
        #20 button[1] = 0;
        #20 button[1] = 1;
        #(DELAY_COUNTS * CLK_PERIOD);
        $display("SW[1] pressed: %b, KEY[1] pressed: %b", button_pressed[1], button_pressed[19]);
        #100;
        $display("SW[2] no change: %b", button_pressed[2]);
        #100;
        $finish();
    end
endmodule