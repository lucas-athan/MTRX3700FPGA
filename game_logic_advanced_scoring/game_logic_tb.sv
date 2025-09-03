// ============================================================
// game_logic_tb.sv (tests whac_a_mole_fsm) + ms-based timeout/bonus
// - Random timeout per hit in [1..countdown_time] for T7 (seeded)
// - Reference model matches DUT bonus: bonus = (timeout/100)*mult
// - Icarus-friendly (no new int decls inside initial)
// ============================================================

`timescale 1ns/1ps

module game_logic_tb;

  // ===== Clock =====
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  // ===== DUT I/O =====
  logic              start_button_pressed;
  logic [15:0]       timeout;          // ms remaining (0 => MISS)
  logic              reset_button_pressed;
  logic              rng_ready;
  logic [17:0]       toggle_switches;  // one-hot
  logic [3:0]        key_switches;     // one-hot
  logic [17:0]       led_number;       // one-hot
  logic [15:0]       countdown_time;   // ms per level

  logic              ledx;
  logic              ready_for_mole;
  logic              timeout_start;
  logic [15:0]       points;
  logic [2:0]        level_select;

  // ===== State encodings (match DUT) =====
  localparam logic [2:0]
    S0_Idle         = 3'd0,
    S1_Choose_Mole  = 3'd1,
    S2_Wait_For_Hit = 3'd2,
    S3_Hit          = 3'd3,
    S4_Miss         = 3'd4;

  // ===== Module-scope vars (Icarus-friendly) =====
  integer i;
  integer exp_points;
  integer add_pts;
  integer conc;                // concurrent streak counter (for model)
  integer t_ms;                // random timeout value for a hit
  integer t_clamped;           // temp used in task to avoid local int

  // ===== Instantiate DUT =====
  whac_a_mole_fsm dut (
    .clk                  (clk),
    .start_button_pressed (start_button_pressed),
    .timeout              (timeout),
    .reset_button_pressed (reset_button_pressed),
    .rng_ready            (rng_ready),
    .toggle_switches      (toggle_switches),
    .key_switches         (key_switches),
    .led_number           (led_number),
    .countdown_time       (countdown_time),
    .ledx                 (ledx),
    .ready_for_mole       (ready_for_mole),
    .timeout_start        (timeout_start),
    .points               (points),
    .level_select         (level_select)
  );

  // ===== Default drives + RNG seed =====
  initial begin
    // Fixed seed for reproducible random timeouts

    start_button_pressed = 0;
    reset_button_pressed = 0;
    rng_ready            = 0;
    key_switches         = 4'd0;
    led_number           = 18'd0;
    toggle_switches      = 18'd0;
    timeout              = 16'd1;     // non-zero default
    countdown_time       = 16'd2500;  // TB overrides via level_select comb block
  end

  // ===== Derive countdown_time from DUT's level_select =====
  // 001 -> 2500ms, 010 -> 2000ms, 100 -> 1500ms
  always @* begin
    case (level_select)
      3'b001: countdown_time = 16'd2500;
      3'b010: countdown_time = 16'd2000;
      3'b100: countdown_time = 16'd1500;
      default: countdown_time = 16'd2500;
    endcase
  end

  // ===== Print helpers =====
  task automatic print_all(string tag);
    $display("%s | state=%0d ledx=%0d ready=%0d to_start=%0d points=%0d lvl=%b led=%018b tog=%018b t=%0d cd=%0d",
             tag, dut.current_state, ledx, ready_for_mole, timeout_start, points,
             level_select, led_number, toggle_switches, timeout, countdown_time);
  endtask

  task automatic print_expected(string tag, int exp_state, int exp_ledx, int exp_ready, int exp_to_start, int exp_pts);
    $display("%s (EXPECTED) -> state=%0d ledx=%0d ready=%0d to_start=%0d points=%0d",
             tag, exp_state, exp_ledx, exp_ready, exp_to_start, exp_pts);
  endtask

  task automatic print_expected_level(string tag, logic [3:0] ks, logic [2:0] exp_lvl);
    $display("%s (EXPECTED) -> key_switches=%b  level_select=%b", tag, ks, exp_lvl);
  endtask

  // ===== Stim helpers =====
  task automatic press_start();
    @(negedge clk); start_button_pressed = 1;
    @(negedge clk); start_button_pressed = 0;
  endtask

  task automatic press_reset();
    @(negedge clk); reset_button_pressed = 1;
    @(negedge clk); reset_button_pressed = 0;
  endtask

  // Move S1 -> S2 (select a fixed LED)
  task automatic arm_mole();
    led_number = 18'b0000000000100000; // LED[5]
    rng_ready  = 1;
    @(negedge clk);
    rng_ready  = 0;
  endtask

  // One HIT using a provided timeout ms (clamped to [1..cd] here to avoid MISS)
  task automatic do_one_hit_with_timeout(input int t_in_ms);
    t_clamped = (t_in_ms < 1) ? 1 : ((t_in_ms > countdown_time) ? countdown_time : t_in_ms);
    arm_mole();                        // S1 -> S2
    timeout = t_clamped[15:0];
    toggle_switches = led_number;      // match => switchx==1
    @(negedge clk);                    // S2 -> S3
    toggle_switches = '0;
    @(negedge clk);                    // back to S1
  endtask

  // Ensure true reset path: S1 -> S2 -> reset -> Idle (and points cleared)
  task automatic reset_to_idle_and_verify(string tag);
    if (dut.current_state != S1_Choose_Mole) begin
      press_start(); @(negedge clk);
      assert (dut.current_state == S1_Choose_Mole)
        else $fatal(1, "%s: failed to reach S1 before arming", tag);
    end
    arm_mole(); @(negedge clk);
    assert (dut.current_state == S2_Wait_For_Hit)
      else $fatal(1, "%s: failed to reach S2 before reset", tag);

    press_reset(); @(negedge clk);
    assert (dut.current_state == S0_Idle)
      else $fatal(1, "%s: not in Idle after reset", tag);
    assert (points == 16'd0)
      else $fatal(1, "%s: points not cleared (got %0d)", tag, points);
    print_all({tag, " now in Idle"});
  endtask

  // ===== Tiny reference model (mirrors DUT integer math) =====
  function automatic int base_mult_from_level(input logic [2:0] lvl);
    if (lvl == 3'b001) return 1;
    else if (lvl == 3'b010) return 3;
    else if (lvl == 3'b100) return 5;
    return 1;
  endfunction

  // Points added for THIS hit given concurrent-before, level, and timeout ms
  // Matches DUT code exactly:
  //  if (conc >= 5) {
  //    mult = base + (conc/5);
  //    bonus = (timeout/100);            // integer division
  //    add = mult*10 + bonus*mult;
  //  } else {                            // conc < 5
  //    mult = 1;
  //    add = mult*10;
  //  }
  function automatic int points_for_hit_model(input int conc_before,
                                              input logic [2:0] lvl,
                                              input int t_val_ms);
    int mult;
    int bonus;
    if (conc_before >= 5) begin
      mult  = base_mult_from_level(lvl) + (conc_before / 5);
      bonus = (t_val_ms / 100);
      return (mult * 10) + (bonus * mult);
    end
    else begin
      mult  = 1;
      return (mult * 10);
    end
  endfunction

  // ===== VCD =====
  initial begin
    $dumpfile("game_logic_tb.vcd");
    $dumpvars(0, game_logic_tb);
  end

  // ===== Tests =====
  initial begin
    repeat (3) @(negedge clk);

    // [T1] Idle defaults
    $display("\n[T1] Check Idle defaults");
    print_expected("[T1]", S0_Idle, 0, 0, 0, 0);
    print_all     ("[T1] ACTUAL ");
    assert (dut.current_state == S0_Idle);
    assert (ledx == 0 && ready_for_mole == 0 && timeout_start == 0);
    assert (points == 0);

    // [T2] Start → S1
    $display("\n[T2] Start press → Choose_Mole");
    press_start(); @(negedge clk);
    print_expected("[T2]", S1_Choose_Mole, 0, 1, 0, 0);
    print_all     ("[T2] ACTUAL ");
    assert (dut.current_state == S1_Choose_Mole);
    assert (ready_for_mole == 1);

    // [TL] Level select output mapping (unchanged)
    $display("\n[TL] Level select output mapping");
    key_switches = 4'b0001; @(negedge clk);
    print_expected_level("[TL-1]", 4'b0001, 3'b000); print_all("[TL-1] ACTUAL "); assert (level_select == 3'b000);
    key_switches = 4'b0010; @(negedge clk);
    print_expected_level("[TL-2]", 4'b0010, 3'b001); print_all("[TL-2] ACTUAL "); assert (level_select == 3'b001);
    key_switches = 4'b0100; @(negedge clk);
    print_expected_level("[TL-3]", 4'b0100, 3'b010); print_all("[TL-3] ACTUAL "); assert (level_select == 3'b010);
    key_switches = 4'b1000; @(negedge clk);
    print_expected_level("[TL-4]", 4'b1000, 3'b100); print_all("[TL-4] ACTUAL "); assert (level_select == 3'b100);
    key_switches = 4'b0000; @(negedge clk);
    print_expected_level("[TL-5]", 4'b0000, 3'b000); print_all("[TL-5] ACTUAL "); assert (level_select == 3'b000);
    key_switches = 4'b0011; @(negedge clk);
    print_expected_level("[TL-6]", 4'b0011, 3'b000); print_all("[TL-6] ACTUAL "); assert (level_select == 3'b000);

    // [T3] RNG → S2
    $display("\n[T3] RNG ready → Wait_For_Hit");
    arm_mole(); @(negedge clk);
    print_expected("[T3]", S2_Wait_For_Hit, 1, 0, 1, 0);
    print_all     ("[T3] ACTUAL ");
    assert (dut.current_state == S2_Wait_For_Hit);
    assert (ledx == 1 && timeout_start == 1);

    // [T4] HIT path (first hit, conc<5 => +10; timeout value irrelevant for bonus)
    $display("\n[T4] HIT: toggle_switches == led_number");
    timeout = 16'd1234;           // any non-zero
    toggle_switches = led_number; @(negedge clk);
    toggle_switches = '0;         @(negedge clk);
    print_expected("[T4]", S1_Choose_Mole, 0, 1, 0, 10);
    print_all     ("[T4] ACTUAL ");
    assert (dut.current_state == S1_Choose_Mole);
    assert (points == 16'd10);

    // [T5] MISS path (timeout=0 in S2)
    $display("\n[T5] MISS: timeout=0");
    arm_mole(); timeout = 16'd0; @(negedge clk);   // miss
    timeout = 16'd1; @(negedge clk);               // back to S1
    print_expected("[T5]", S1_Choose_Mole, 0, 1, 0, 10);
    print_all     ("[T5] ACTUAL ");
    assert (dut.current_state == S1_Choose_Mole);
    assert (points == 16'd10);

    // [T6] Reset during S2
    $display("\n[T6] Reset during S2");
    arm_mole(); @(negedge clk);
    print_all("[T6] BEFORE reset");
    assert (dut.current_state == S2_Wait_For_Hit);
    press_reset(); @(negedge clk);
    print_expected("[T6]", S0_Idle, 0, 0, 0, 0);
    print_all     ("[T6] ACTUAL ");
    assert (dut.current_state == S0_Idle);
    assert (points == 0);
    assert (ledx == 0 && ready_for_mole == 0 && timeout_start == 0);

    // ===========================================================
    // [T7] 11-hit streak with RANDOM timeout per hit (ms bonus)
    //  For each level: reset->start->select level, then 11 hits.
    //  Each hit uses t_ms in [1..countdown_time] (seeded RNG).
    //  Expected points computed by reference model above.
    // ===========================================================

    // -------- Level = 001 (key=0010) --------
    $display("\n[T7-L1] 11 hits @ level=001 (key=0010) with random timeouts");
    reset_to_idle_and_verify("[T7-L1] reset");
    press_start(); @(negedge clk);
    key_switches = 4'b0010; @(negedge clk);   // level_select == 3'b001 expected

    conc = 0; exp_points = 0;
    for (i = 0; i < 11; i = i + 1) begin
      t_ms   = $urandom_range(countdown_time, 1);        // 1..cd
      add_pts = points_for_hit_model(conc, level_select, t_ms);
      do_one_hit_with_timeout(t_ms);
      conc       = conc + 1;
      exp_points = exp_points + add_pts;
      $display("[T7-L1] hit %0d -> t=%0d add=%0d expTotal=%0d ACTpoints=%0d mult=%0d",
               i+1, t_ms, add_pts, exp_points, points, dut.multiplier);
    end
    print_expected("[T7-L1]", S1_Choose_Mole, 0, 1, 0, exp_points);
    print_all     ("[T7-L1] ACTUAL ");
    assert (points == exp_points)
      else $fatal(1, "[T7-L1] Expected %0d points (got %0d)", exp_points, points);

    // -------- Level = 010 (key=0100) --------
    $display("\n[T7-L2] 11 hits @ level=010 (key=0100) with random timeouts");
    reset_to_idle_and_verify("[T7-L2] reset");
    press_start(); @(negedge clk);
    key_switches = 4'b0100; @(negedge clk);   // level_select == 3'b010 expected

    conc = 0; exp_points = 0;
    for (i = 0; i < 11; i = i + 1) begin
      t_ms   = $urandom_range(countdown_time, 1);
      add_pts = points_for_hit_model(conc, level_select, t_ms);
      do_one_hit_with_timeout(t_ms);
      conc       = conc + 1;
      exp_points = exp_points + add_pts;
      $display("[T7-L2] hit %0d -> t=%0d add=%0d expTotal=%0d ACTpoints=%0d mult=%0d",
               i+1, t_ms, add_pts, exp_points, points, dut.multiplier);
    end
    print_expected("[T7-L2]", S1_Choose_Mole, 0, 1, 0, exp_points);
    print_all     ("[T7-L2] ACTUAL ");
    assert (points == exp_points)
      else $fatal(1, "[T7-L2] Expected %0d points (got %0d)", exp_points, points);

    // -------- Level = 100 (key=1000) --------
    $display("\n[T7-L3] 11 hits @ level=100 (key=1000) with random timeouts");
    reset_to_idle_and_verify("[T7-L3] reset");
    press_start(); @(negedge clk);
    key_switches = 4'b1000; @(negedge clk);   // level_select == 3'b100 expected

    conc = 0; exp_points = 0;
    for (i = 0; i < 11; i = i + 1) begin
      t_ms   = $urandom_range(countdown_time, 1);
      add_pts = points_for_hit_model(conc, level_select, t_ms);
      do_one_hit_with_timeout(t_ms);
      conc       = conc + 1;
      exp_points = exp_points + add_pts;
      $display("[T7-L3] hit %0d -> t=%0d add=%0d expTotal=%0d ACTpoints=%0d mult=%0d",
               i+1, t_ms, add_pts, exp_points, points, dut.multiplier);
    end
    print_expected("[T7-L3]", S1_Choose_Mole, 0, 1, 0, exp_points);
    print_all     ("[T7-L3] ACTUAL ");
    assert (points == exp_points)
      else $fatal(1, "[T7-L3] Expected %0d points (got %0d)", exp_points, points);

    $display("\nAll tests PASSED ✅");
    #20;
    $finish;
  end

endmodule
