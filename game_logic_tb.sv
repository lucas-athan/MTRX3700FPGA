// ============================================================
// game_logic_tb.sv  (tests whac_a_mole_fsm)
// ============================================================

`timescale 1ns/1ps

module game_logic_tb;

  // Clock
  logic clk;

  // DUT inputs
  logic start_button_pressed;
  logic timeout;
  logic reset_button_pressed;
  logic level_select;       // Unused in FSM; driven 0.
  logic switchx;
  logic rng_ready;

  // DUT outputs
  logic ledx;
  logic ready_for_mole;
  logic timeout_start;
  logic [15:0] points;

  // State encodings (match DUT enum order)
  localparam logic [2:0]
    S0_Idle         = 3'd0,
    S1_Choose_Mole  = 3'd1,
    S2_Wait_For_Hit = 3'd2,
    S3_Hit          = 3'd3,
    S4_Miss         = 3'd4;

  // Loop index declared at module scope (Icarus-friendly)
  integer i;

  // ---------- Instantiate DUT (NAME MUST MATCH YOUR MODULE) ----------
  whac_a_mole_fsm dut (
    .clk                  (clk),
    .start_button_pressed (start_button_pressed),
    .timeout              (timeout),
    .reset_button_pressed (reset_button_pressed),
    .level_select         (level_select),
    .switchx              (switchx),
    .rng_ready            (rng_ready),
    .ledx                 (ledx),
    .ready_for_mole       (ready_for_mole),
    .timeout_start        (timeout_start),
    .points               (points)
  );

  // 100 MHz clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Defaults
  initial begin
    start_button_pressed = 0;
    reset_button_pressed = 0;
    timeout              = 1;  // 1 = time remaining, 0 = timed out
    level_select         = 0;
    switchx              = 0;
    rng_ready            = 0;
  end

  // --- Helpers ------------------------------------------------

  task automatic press_start();
    @(negedge clk); start_button_pressed = 1;
    @(negedge clk); start_button_pressed = 0;
  endtask

  task automatic press_reset();
    @(negedge clk); reset_button_pressed = 1;
    @(negedge clk); reset_button_pressed = 0;
  endtask

  // S1 -> S2 by pulsing rng_ready
  task automatic arm_mole();
    rng_ready = 1;
    @(negedge clk);
    rng_ready = 0;
  endtask

  // One HIT (S1->S2, then switchx=1)
  task automatic do_one_hit();
    arm_mole();
    switchx = 1;
    @(negedge clk);
    switchx = 0;
    @(negedge clk); // settle back to S1
  endtask

  // One MISS (S1->S2, then timeout=0)
  task automatic do_one_miss();
    arm_mole();
    timeout = 0;
    @(negedge clk);
    timeout = 1;
    @(negedge clk); // settle back to S1
  endtask

  // --- Wave dump ----------------------------------------------
  initial begin
    $dumpfile("game_logic_tb.vcd");
    $dumpvars(0, game_logic_tb);
  end

  // --- Tests --------------------------------------------------
  initial begin
    // Small settle
    repeat (3) @(negedge clk);

    // [T1] Idle defaults
    $display("[T1] Check Idle defaults");
    assert (dut.current_state == S0_Idle) else $fatal(1, "Not in Idle at reset!");
    assert (ledx == 0 && ready_for_mole == 0 && timeout_start == 0) else $fatal(1, "Idle outputs wrong");
    assert (points == 0) else $fatal(1, "Points not zero in Idle");

    // [T2] Start → S1
    $display("[T2] Start press → Choose_Mole");
    press_start();
    @(negedge clk);
    assert (dut.current_state == S1_Choose_Mole) else $fatal(1, "Did not enter S1 after start");
    assert (ready_for_mole == 1) else $fatal(1, "ready_for_mole should be 1 in S1");

    // [T3] RNG → S2
    $display("[T3] RNG ready → Wait_For_Hit");
    arm_mole();
    @(negedge clk);
    assert (dut.current_state == S2_Wait_For_Hit) else $fatal(1, "Did not enter S2");
    assert (ledx == 1 && timeout_start == 1) else $fatal(1, "S2 outputs not asserted");

    // [T4] HIT path
    $display("[T4] HIT: switchx=1");
    switchx = 1;
    @(negedge clk); // S3_Hit
    switchx = 0;
    @(negedge clk); // back to S1
    assert (dut.current_state == S1_Choose_Mole) else $fatal(1, "After HIT not back to S1");
    assert (points == 16'd1) else $fatal(1, "Points should be 1 after first hit");
    assert (ready_for_mole == 1) else $fatal(1, "ready_for_mole should be 1 in S1 after hit");

    // [T5] MISS path
    $display("[T5] MISS: timeout=0");
    do_one_miss();
    assert (dut.current_state == S1_Choose_Mole) else $fatal(1, "After MISS not back to S1");
    assert (points == 16'd1) else $fatal(1, "Points should hold after miss");

    // [T6] Reset during S2
    $display("[T6] Reset during S2");
    arm_mole(); @(negedge clk);
    assert (dut.current_state == S2_Wait_For_Hit);
    press_reset(); @(negedge clk);
    assert (dut.current_state == S0_Idle) else $fatal(1, "Did not return to Idle on reset");
    assert (points == 0) else $fatal(1, "Points not cleared by Idle logic");
    assert (ledx == 0 && ready_for_mole == 0 && timeout_start == 0);
 
    // Prep streak test
    press_start(); @(negedge clk);
    assert (dut.current_state == S1_Choose_Mole);

    // [T7] 11-hit streak → total +12 points
    $display("[T7] 11-hit streak to trigger multiplier doubling");
    for (i = 0; i < 11; i = i + 1) begin
      do_one_hit();
    end
    assert (points == 16'd12) else $fatal(1, "Expected 12 points after 11-hit streak (got %0d)", points);

    $display("All tests PASSED ✅");
    #20;
    $finish;
  end

endmodule
