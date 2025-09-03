/*

Step 1:
To begin, the user presses the on button and the game goes into its initialise state.
The game then waits for the user to select which level to pick.

Step 2:
The user picks one of three levels by pressing one of three of the round buttons. 
The fourth button is the reset button and it takes the user back to the initalise state.
Once the user has selected their level.
We use the seven seg as a count down timer (maybe) before the game starts 

Step 3: 
The games starts and the user plays the level.
    Step 3.1: 
    The RNG module generates a random number and sends it to the LED module
    The LED module lights up one of the LEDs
    The timer begins counting down until the user hits the right switch or until the timer times out 
    Step 3.2: 
    The user hits the switch with the light
    If the user is succesful that light is turned off and some points are added to the score
    If the user is unsuccesful, the light turns off on a timer and no points are added 
    Alternatively, we have a light turn off and it counts as a mistake and the player loses a life too
    Step 3.3: 
    Go back to step 3.1
The game continues until the reset button is hit. 
Alternatively, the game continues until the user makes 3 mistakes. 
The score is then displayed until the user hits the reset button. 

*/

module whac_a_mole_fsm (
    input               clk,
    input               timeout,
    input               [17:0] toggle_switches
    input               [3:0]  key_switches
    input               [17:0] led_number
    output logic        ledx,
    output logic        ready_for_mole,
    output logic        timeout_start,
    output logic        [15:0] points
    output logic        [1:0] level_number
);

// Internal values
logic [8:0] concurrent;
logic [3:0] multiplier; 
logic switchx; 
logic reset_button_pressed = 0;       // Reset button
logic start_button_pressed = 0;


// --- Level choose & start/reset requests from key_switches ---
always_comb begin : level_choose_from_keys
  // defaults
  level_number          = 2'b00;
  start_button_pressed  = 1'b0;
  reset_button_pressed  = 1'b0;

  unique case (key_switches)
    4'b0000: begin
      // RESET case
      level_number         = 2'b00;
      reset_button_pressed = 1'b1;
      // start_button_pressed stays 0
    end
    4'b0010: begin
      level_number         = 2'b01;
      start_button_pressed = 1'b1;
    end
    4'b0100: begin
      level_number         = 2'b10;
      start_button_pressed = 1'b1;
    end
    4'b1000: begin
      level_number         = 2'b11;
      start_button_pressed = 1'b1;
    end
    default: begin
      // no valid selection -> keep defaults
      level_number         = 2'b00;
    end
  endcase
end

// --- Toggle switches vs LED number (assumes led_number is one-hot) ---
assign switchx = |(toggle_switches & led_number);
    
// Start Button Synchroniser + rising edge detect 
logic start_button, start_button_edge;
always_ff @(posedge clk) begin : start_edge_detect
    start_button <= start_button_pressed;
end : start_edge_detect
assign start_button_edge = (start_button_pressed > start_button);

// Reset Button Synchroniser + rising edge detect 
logic reset_button, reset_button_edge;
always_ff @(posedge clk) begin : reset_edge_detect
    reset_button <= reset_button_pressed;
end : reset_edge_detect
assign reset_button_edge = (reset_button_pressed > reset_button);


// State Machine Typedef
typedef enum logic [2:0] { S0_Idle, S1_Choose_Mole, S2_Wait_For_Hit, S3_Hit, S4_Miss } state_type;
state_type current_state, next_state;

// Initial states
initial current_state = S0_Idle;

// Next State Logic
always_comb begin : whac_a_mole_next_state_logic
    next_state = current_state;
    case (current_state)

        S0_Idle: begin
            if (start_button_edge) next_state = S1_Choose_Mole;
            else                   next_state = S0_Idle;
        end

        S1_Choose_Mole: begin
            next_state = S2_Wait_For_Hit;
        end

        S2_Wait_For_Hit: begin
            if (reset_button_edge == 1) begin
                next_state = S0_Idle;
            end
            else if (timeout == 0) begin
                next_state = S4_Miss;
            end
            else if (switchx == 1 && timeout != 0) begin
                next_state = S3_Hit;
            end
            else begin
                next_state = S2_Wait_For_Hit;
            end
        end

        S3_Hit:            next_state = S1_Choose_Mole;

        S4_Miss:           next_state = S1_Choose_Mole;
    endcase
end

// State Register
always_ff @(posedge clk) begin : whac_a_mole_fsm_ff
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
        // points holds unless you want to clear or subtract here
    end
end

// Output Logic
always_comb begin : whac_a_mole_fsm_output
    ledx = 0;
    ready_for_mole = 0;
    timeout_start = 0;

    if (current_state == S0_Idle) begin
        ledx = 0;
        ready_for_mole = 0;
        timeout_start = 0;
    end

    if (current_state == S1_Choose_Mole) begin
        ready_for_mole = 1;
        ledx = 0;
        timeout_start = 0;
    end

    

    else if (current_state == S2_Wait_For_Hit) begin
        ledx = 1; 
        timeout_start = 1;
        ready_for_mole = 0;
    end

    else if (current_state == S3_Hit) begin
        ledx = 0;
        timeout_start = 0;
        ready_for_mole = 0;
    end

    else if (current_state == S4_Miss) begin
        ledx = 0;
        timeout_start = 0;
        ready_for_mole = 0;
    end

end

endmodule





