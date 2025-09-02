`timescale 1ns/1ps
`default_nettype none

module fsm_design (
    input  logic        clk,
    input  logic        start_button_pressed,
    input  logic        timeout,
    input  logic        reset_button_pressed,
    input  logic        level_select,        // unused
    input  logic        switchx,
    input  logic        rng_ready,
    output logic        ledx,
    output logic        ready_for_mole,
    output logic        timeout_start,
    output logic [15:0] points
);

  // ---------------- Internal counters ----------------
  logic [8:0] concurrent;
  logic [3:0] multiplier; 

  // ---------------- Button sync + edge detect (all synchronous) ----------------
  logic start_sync, start_prev, start_button_edge;
  logic reset_sync, reset_prev, reset_button_edge;

  always_ff @(posedge clk) begin
    // 1-stage sync (you can make it 2 if you want)
    start_sync <= start_button_pressed;
    reset_sync <= reset_button_pressed;

    // store previous
    start_prev <= start_sync;
    reset_prev <= reset_sync;

    // 1-cycle rising-edge pulses
    start_button_edge <= start_sync & ~start_prev;
    reset_button_edge <= reset_sync & ~reset_prev;
  end

  // ---------------- State machine ----------------
  typedef enum logic [2:0] {
    S0_Idle, S1_Choose_Mole, S2_Wait_For_Hit, S3_Hit, S4_Miss
  } state_type;

  state_type current_state, next_state;

  // Initial state
  initial current_state = S0_Idle;

  // Next-state logic
  always_comb begin
    next_state = current_state;
    unique case (current_state)
      S0_Idle:            next_state = (start_button_edge) ? S1_Choose_Mole : S0_Idle;

      S1_Choose_Mole:     next_state = (rng_ready) ? S2_Wait_For_Hit : S1_Choose_Mole;

      S2_Wait_For_Hit: begin
        if      (reset_button_edge)   next_state = S0_Idle;
        else if (!timeout)            next_state = S4_Miss;
        else if (switchx && timeout)  next_state = S3_Hit;
        else                          next_state = S2_Wait_For_Hit;
      end

      S3_Hit:             next_state = S1_Choose_Mole;
      S4_Miss:            next_state = S1_Choose_Mole;
    endcase
  end

  // State / scoring registers
  always_ff @(posedge clk) begin
    current_state <= next_state;

    if (current_state == S0_Idle) begin
      points     <= 0;
      multiplier <= 1;
      concurrent <= 0;
    end
    else if (current_state == S3_Hit) begin
      if (concurrent > 10) begin
        multiplier <= multiplier * 2;
      end
      points     <= points + (multiplier * 1);
      concurrent <= concurrent + 1;
    end
    else if (current_state == S4_Miss) begin
      concurrent <= 0;
      multiplier <= 1;
      // points holds
    end
  end

  // Output logic
  always_comb begin
    ledx = 0;
    ready_for_mole = 0;
    timeout_start = 0;

    if (current_state == S1_Choose_Mole) begin
      ready_for_mole = 1;
    end
    else if (current_state == S2_Wait_For_Hit) begin
      ledx = 1;
      timeout_start = 1;
    end
  end

endmodule

`default_nettype wire
