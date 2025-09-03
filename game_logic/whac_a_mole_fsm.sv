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
    input               start_button_pressed,         // Start button
    input               timeout,
    input               reset_button_pressed,         // Reset button
    input               rng_ready,
    input               [17:0] toggle_switches,
    input               [3:0] key_switches,
    input               [17:0] led_number,
    output logic        ledx,
    output logic        ready_for_mole,
    output logic        timeout_start,
    output logic        [15:0] points,
    output logic        [2:0] level_select
);

// Internal values
logic [8:0] concurrent;
logic [3:0] multiplier; 
logic [2:0] level_number;
logic switchx;

assign switchx = |(toggle_switches & led_number);

always_comb begin : level_select_logic
    level_number = 3'b000;

    case (key_switches)
    4'b0001: begin            // Reset case
        level_number = 3'b000;
    end
    4'b0010: begin            // Reset case
        level_number = 3'b001;
    end
    4'b0100: begin            // Reset case
        level_number = 3'b010;
    end
    4'b1000: begin            // Reset case
        level_number = 3'b100;
    end
    default: begin
        level_number = 3'b000;
    end
    endcase
end



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
            if (rng_ready)        next_state = S2_Wait_For_Hit;
            else                  next_state = S1_Choose_Mole;
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
        if (level_number == 3'b001)
            multiplier = 1;
        else if (level_number == 3'b010)
            multiplier = 3;
        else if (level_number == 3'b100)
            multiplier = 5;

        if (concurrent >= 5) begin
            multiplier = multiplier + (concurrent/5) ;
            points     <= points + (multiplier * 10);
            concurrent <= concurrent + 1;
        end
        else if (concurrent < 10) begin
            multiplier = 1;
            points     <= points + (multiplier * 10);
            concurrent <= concurrent + 1;
        end
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
    level_select = level_number;

    if (current_state == S0_Idle) begin
        ledx = 0;
        ready_for_mole = 0;
        timeout_start = 0;
        level_select = level_number;
    end

    if (current_state == S1_Choose_Mole) begin
        ready_for_mole = 1;
        level_select = level_number;
    end

    else if (current_state == S2_Wait_For_Hit) begin
        ledx = 1;
        timeout_start = 1;
        ready_for_mole = 0;
        level_select = level_number;
    end

    else if (current_state == S3_Hit) begin
        ledx = 0;
        timeout_start = 0;
        ready_for_mole = 0;
        level_select = level_number;
    end

    else if (current_state == S4_Miss) begin
        ledx = 0;
        timeout_start = 0;
        ready_for_mole = 0;
        level_select = level_number;
    end

end

endmodule

