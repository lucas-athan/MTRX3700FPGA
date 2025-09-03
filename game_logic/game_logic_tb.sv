// ============================================================
// game_logic_tb.sv  (tests whac_a_mole_fsm) + detailed prints
//  -- Updated expected scores for new scoring scheme
//     - First hit: +10
//     - 11th hit: +20 (multiplier=2)
//     - Total after 11 hits: 120
// ============================================================

`timescale 1ns/1ps

module game_logic_tb;

  // Clock
  logic clk;

  // DUT inputs
  logic start_button_pressed;
  logic timeout;
  logic reset_button_pressed;
  logic rng_ready;
  logic [17:0] toggle_switches;   // user toggles
  logic [3:0]  key_switches;      // level select inputs
  logic [17:0] led_number;        // which LED is "lit" (one-hot)

  // DUT outputs
  logic ledx;
  logic ready_for_mole;
  logic timeout_start;
  logic [15:0] points;
  logic [2:0]  level_select;      // 3-bit output from DUT

  // State encodings (match DUT enum order)
  localparam logic [2:0]
    S0_Idle         = 3'd0,
    S1_Choose_Mole  = 3'd1,
    S2_Wait_For_Hit = 3'd2,
    S3_Hit          = 3'd3,
    S4_Miss         = 3'd4;

  // Loop index
  integer i;

  // ---------- Instantiate DUT ----------
  whac_a_mole_fsm dut (
    .clk                  (clk),
    .start_button_pressed (start_button_pressed),
    .timeout              (timeout),
    .reset_button_pressed (reset_button_pressed),
    .level_select         (level_select),     // DUT 3-bit OUTPUT
    .rng_ready            (rng_ready),
    .toggle_switches      (toggle_switches),
    .key_switches         (key_switches),
    .led_number           (led_number),
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
    timeout              = 1;   // 1 = time remaining, 0 = timed out
    rng_ready            = 0;
    key_switches         = 4'd0;
    led_number           = 18'd0;   // no LED selected yet
    toggle_switches      = 18'd0;   // user not pressing any switch
  end

  // ---------- Print helpers ----------
  task automatic print_all(string tag);
    $display("%s | state=%0d  ledx=%0d  ready=%0d  to_start=%0d  points=%0d  level_sel=%b  led_num=%018b  toggles=%018b",
             tag, dut.current_state, ledx, ready_for_mole, timeout_start, points, level_select, led_number, toggle_switches);
  endtask

  task automatic print_expected(string tag,
                                int exp_state,
                                int exp_ledx,
                                int exp_ready,
                                int exp_to_start,
                                int exp_points);
    $display("%s (EXPECTED) -> state=%0d  ledx=%0d  ready=%0d  to_start=%0d  points=%0d",
             tag, exp_state, exp_ledx, exp_ready, exp_to_start, exp_points);
  endtask

  task automatic print_expected_level(string tag, logic [3:0] ks, logic [2:0] exp_lvl);
    $display("%s (EXPECTED) -> key_switches=%b  level_select=%b", tag, ks, exp_lvl);
  endtask

  // --- Helpers to drive DUT ---------------------------------

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
    // Choose a one-hot LED to "light" (e.g., bit 5).
    led_number = 18'b0000000000100000; // LED[5]
    rng_ready  = 1;
    @(negedge clk);
    rng_ready  = 0;
  endtask

  // One HIT (S1->S2, then match toggle_switches to led_number for one cycle)
  task automatic do_one_hit();
    arm_mole();                      // S1 -> S2 (ledx=1, timeout_start=1)
    toggle_switches = led_number;    // MATCH: this makes internal switchx == 1
    @(negedge clk);
    toggle_switches = '0;            // release after one cycle
    @(negedge clk);                  // settle back to S1
  endtask

  // One MISS (S1->S2, then timeout=0)
  task automatic do_one_miss();
    arm_mole();                      // S1 -> S2
    timeout = 0;                     // force miss
    @(negedge clk);
    timeout = 1;                     // restore
    @(negedge clk);                  // settle back to S1
  endtask

    // Helper to run a level case
  task automatic run_level_11_hits(input logic [3:0] ks, input int exp_total, input string tag);
    int j;
    // Reset to clear concurrent/points, then start and set level
    press_reset(); @(negedge clk);
    print_all({tag, " BEFORE start"});
    press_start(); @(negedge clk);
    key_switches = ks; @(negedge clk);
    $display("%s Using key_switches=%b (level_select=%b expected by mapping)", tag, ks, dut.level_select);

    // Perform 11 consecutive hits
    for (j = 0; j < 11; j = j + 1) begin
      do_one_hit();
      $display("%s After hit %0d -> points=%0d, multiplier=%0d",
              tag, j+1, points, dut.multiplier);
    end

    // Check final
    print_expected(tag, S1_Choose_Mole, /*ledx*/0, /*ready*/1, /*to*/0, /*pts*/exp_total);
    print_all     ({tag, " ACTUAL "});
    assert (points == exp_total)
      else $fatal(1, "%s Expected %0d points after 11-hit streak (got %0d)", tag, exp_total, points);
  endtask

      // -------- Ensure true reset-to-Idle helper sequence --------
    // (Reset only transitions to Idle in S2 per DUT, so enter S2 then pulse reset.)
  task automatic reset_to_idle_and_verify(string tag);
    // Enter S2
    arm_mole(); @(negedge clk);
    assert (dut.current_state == S2_Wait_For_Hit)
      else $fatal(1, "%s: Failed to reach S2 before reset", tag);
    // Pulse reset, then check Idle + cleared points
    press_reset(); @(negedge clk);
    assert (dut.current_state == S0_Idle)
      else $fatal(1, "%s: Not in Idle after reset", tag);
    assert (points == 16'd0)
      else $fatal(1, "%s: Points not cleared on Idle (got %0d)", tag, points);
    print_all({tag, " now in Idle"});
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
    $display("\n[T1] Check Idle defaults");
    print_expected("[T1]", S0_Idle, 0, 0, 0, 0);
    print_all     ("[T1] ACTUAL ");
    assert (dut.current_state == S0_Idle) else $fatal(1, "Not in Idle at reset!");
    assert (ledx == 0 && ready_for_mole == 0 && timeout_start == 0) else $fatal(1, "Idle outputs wrong");
    assert (points == 0) else $fatal(1, "Points not zero in Idle");

    // [T2] Start → S1
    $display("\n[T2] Start press → Choose_Mole");
    press_start();
    @(negedge clk);
    print_expected("[T2]", S1_Choose_Mole, /*ledx*/0, /*ready*/1, /*to*/0, /*pts*/0);
    print_all     ("[T2] ACTUAL ");
    assert (dut.current_state == S1_Choose_Mole) else $fatal(1, "Did not enter S1 after start");
    assert (ready_for_mole == 1) else $fatal(1, "ready_for_mole should be 1 in S1");

    // -------- TL: Level output checks --------
    $display("\n[TL] Level select output mapping");
    // 0001 -> 000
    key_switches = 4'b0001; @(negedge clk);
    print_expected_level("[TL-1]", 4'b0001, 3'b000);
    print_all            ("[TL-1] ACTUAL ");
    assert (level_select == 3'b000) else $fatal(1, "Level mapping fail: 0001 -> %b (exp 000)", level_select);
    // 0010 -> 001
    key_switches = 4'b0010; @(negedge clk);
    print_expected_level("[TL-2]", 4'b0010, 3'b001);
    print_all            ("[TL-2] ACTUAL ");
    assert (level_select == 3'b001) else $fatal(1, "Level mapping fail: 0010 -> %b (exp 001)", level_select);
    // 0100 -> 010
    key_switches = 4'b0100; @(negedge clk);
    print_expected_level("[TL-3]", 4'b0100, 3'b010);
    print_all            ("[TL-3] ACTUAL ");
    assert (level_select == 3'b010) else $fatal(1, "Level mapping fail: 0100 -> %b (exp 010)", level_select);
    // 1000 -> 100
    key_switches = 4'b1000; @(negedge clk);
    print_expected_level("[TL-4]", 4'b1000, 3'b100);
    print_all            ("[TL-4] ACTUAL ");
    assert (level_select == 3'b100) else $fatal(1, "Level mapping fail: 1000 -> %b (exp 100)", level_select);
    // default / invalid -> 000
    key_switches = 4'b0000; @(negedge clk);
    print_expected_level("[TL-5]", 4'b0000, 3'b000);
    print_all            ("[TL-5] ACTUAL ");
    assert (level_select == 3'b000) else $fatal(1, "Level mapping fail: 0000 -> %b (exp 000)", level_select);
    key_switches = 4'b0011; @(negedge clk);
    print_expected_level("[TL-6]", 4'b0011, 3'b000);
    print_all            ("[TL-6] ACTUAL ");
    assert (level_select == 3'b000) else $fatal(1, "Level mapping fail: 0011 -> %b (exp 000)", level_select);

    // [T3] RNG → S2
    $display("\n[T3] RNG ready → Wait_For_Hit");
    arm_mole();
    @(negedge clk);
    print_expected("[T3]", S2_Wait_For_Hit, /*ledx*/1, /*ready*/0, /*to*/1, /*pts*/0);
    print_all     ("[T3] ACTUAL ");
    assert (dut.current_state == S2_Wait_For_Hit) else $fatal(1, "Did not enter S2");
    assert (ledx == 1 && timeout_start == 1) else $fatal(1, "S2 outputs not asserted");

    // [T4] HIT path (vector match) -> now +10 points
    $display("\n[T4] HIT: toggle_switches == led_number");
    toggle_switches = led_number;
    @(negedge clk); // S3_Hit should occur
    toggle_switches = '0;
    @(negedge clk); // back to S1
    print_expected("[T4]", S1_Choose_Mole, /*ledx*/0, /*ready*/1, /*to*/0, /*pts*/10);
    print_all     ("[T4] ACTUAL ");
    assert (dut.current_state == S1_Choose_Mole) else $fatal(1, "After HIT not back to S1");
    assert (points == 16'd10) else $fatal(1, "Points should be 10 after first hit");
    assert (ready_for_mole == 1) else $fatal(1, "ready_for_mole should be 1 in S1 after hit");

    // [T5] MISS path -> points hold at 10
    $display("\n[T5] MISS: timeout=0");
    do_one_miss();
    print_expected("[T5]", S1_Choose_Mole, /*ledx*/0, /*ready*/1, /*to*/0, /*pts*/10);
    print_all     ("[T5] ACTUAL ");
    assert (dut.current_state == S1_Choose_Mole) else $fatal(1, "After MISS not back to S1");
    assert (points == 16'd10) else $fatal(1, "Points should hold at 10 after miss");

    // [T6] Reset during S2 -> points cleared to 0
    $display("\n[T6] Reset during S2");
    arm_mole(); @(negedge clk);
    print_all("[T6] BEFORE reset");
    assert (dut.current_state == S2_Wait_For_Hit);
    press_reset(); @(negedge clk);
    print_expected("[T6]", S0_Idle, /*ledx*/0, /*ready*/0, /*to*/0, /*pts*/0);
    print_all     ("[T6] ACTUAL ");
    assert (dut.current_state == S0_Idle) else $fatal(1, "Did not return to Idle on reset");
    assert (points == 0) else $fatal(1, "Points not cleared by Idle logic");
    assert (ledx == 0 && ready_for_mole == 0 && timeout_start == 0);

    // Prep streak test
    press_start(); @(negedge clk);
    assert (dut.current_state == S1_Choose_Mole);

    // [T7] 11-hit streak across levels (base depends on level; +1 every 5 hits)
    // Expected totals by level:
    //   key=0010 (level=001, base=1):  5*10 + 5*20 + 1*30 = 180
    //   key=0100 (level=010, base=3):  5*10 + 5*40 + 1*50 = 300
    //   key=1000 (level=100, base=5):  5*10 + 5*60 + 1*70 = 420
    $display("\n[T7] 11-hit streak across levels with true reset-to-Idle between tests");

    // -------- Level = 001 (key=0010) --------
    reset_to_idle_and_verify("[T7-L1] reset");
    press_start(); @(negedge clk);
    key_switches = 4'b0010; @(negedge clk);
    for (i = 0; i < 11; i = i + 1) begin
      do_one_hit();
      $display("[T7-L1] After hit %0d -> points=%0d, multiplier=%0d",
              i+1, points, dut.multiplier);
    end
    print_expected("[T7-L1]", S1_Choose_Mole, 0, 1, 0, 180);
    print_all     ("[T7-L1] ACTUAL ");
    assert (points == 16'd180)
      else $fatal(1, "[T7-L1] Expected 180 points after 11-hit streak (got %0d)", points);

    // -------- Level = 010 (key=0100) --------
    reset_to_idle_and_verify("[T7-L2] reset");
    press_start(); @(negedge clk);
    key_switches = 4'b0100; @(negedge clk);
    for (i = 0; i < 11; i = i + 1) begin
      do_one_hit();
      $display("[T7-L2] After hit %0d -> points=%0d, multiplier=%0d",
              i+1, points, dut.multiplier);
    end
    print_expected("[T7-L2]", S1_Choose_Mole, 0, 1, 0, 300);
    print_all     ("[T7-L2] ACTUAL ");
    assert (points == 16'd300)
      else $fatal(1, "[T7-L2] Expected 300 points after 11-hit streak (got %0d)", points);

    // -------- Level = 100 (key=1000) --------
    reset_to_idle_and_verify("[T7-L3] reset");
    press_start(); @(negedge clk);
    key_switches = 4'b1000; @(negedge clk);
    for (i = 0; i < 11; i = i + 1) begin
      do_one_hit();
      $display("[T7-L3] After hit %0d -> points=%0d, multiplier=%0d",
              i+1, points, dut.multiplier);
    end
    print_expected("[T7-L3]", S1_Choose_Mole, 0, 1, 0, 420);
    print_all     ("[T7-L3] ACTUAL ");
    assert (points == 16'd420)
      else $fatal(1, "[T7-L3] Expected 420 points after 11-hit streak (got %0d)", points);

    $display("\n[T7] All level-based streak tests PASSED ✅");




    $display("\nAll tests PASSED ✅");
    #20;
    $finish;
  end

endmodule
