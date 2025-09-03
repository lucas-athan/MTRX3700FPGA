module whac_a_mole_fsm (
    input               clk,
    input               start_button_pressed,         // Start button
    input               timeout,
    input               reset_button_pressed,         // Reset button
    input               level_select,
    input               switchx,
    input               rng_ready,
    output logic        ledx,
    output logic        ready_for_mole,
    output logic        timeout_start,
    output logic        [15:0] points
);

// Internal values
logic [8:0] concurrent;
logic [3:0] multiplier; 

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