`timescale 1ns/1ps

module fsm_tb;

  logic clk;
  logic start_button_pressed, timeout, reset_button_pressed, level_select, switchx, rng_ready;
  logic ledx, ready_for_mole, timeout_start;
  logic [15:0] points;

  localparam S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4;

  // DUT
  fsm_design dut(
    .clk(clk),
    .start_button_pressed(start_button_pressed),
    .timeout(timeout),
    .reset_button_pressed(reset_button_pressed),
    .level_select(level_select),
    .switchx(switchx),
    .rng_ready(rng_ready),
    .ledx(ledx),
    .ready_for_mole(ready_for_mole),
    .timeout_start(timeout_start),
    .points(points)
  );

  // 100 MHz clock
  initial clk=0; 
  always #5 clk=~clk;

  initial begin
    start_button_pressed=0; timeout=1; reset_button_pressed=0; level_select=0; switchx=0; rng_ready=0;
    repeat(3) @(negedge clk);

    // Start -> S1
    @(negedge clk); start_button_pressed=1;
    @(negedge clk); start_button_pressed=0;
    @(negedge clk);
    $display("[TB] After start → S1, ready_for_mole=1: state=%0d, ready=%0d", dut.current_state, ready_for_mole);

    // rng_ready -> S2
    rng_ready=1; @(negedge clk); rng_ready=0;
    @(negedge clk);
    $display("[TB] After rng_ready → S2, ledx=1 timeout_start=1: state=%0d, led=%0d, tostart=%0d", dut.current_state, ledx, timeout_start);

    // Hit
    switchx=1; @(negedge clk); switchx=0; @(negedge clk);
    $display("[TB] Hit → back to S1, points=1: state=%0d, points=%0d", dut.current_state, points);

    // Miss
    rng_ready=1; @(negedge clk); rng_ready=0; @(negedge clk);
    timeout=0; @(negedge clk); timeout=1; @(negedge clk);
    $display("[TB] Miss → back to S1, points holds=1: state=%0d, points=%0d", dut.current_state, points);

    $finish;
  end

  // Wave dump
  initial begin
    $dumpfile("fsm_tb.vcd");
    $dumpvars(0, fsm_tb);
  end
endmodule
