/*
Whac-A-Mole FSM in pure Verilog
*/

module whac_a_mole_fsm (
    input               clk,
    input               timeout,
    input       [17:0]  toggle_switches,
    input       [3:0]   key_switches,
    input       [17:0]  led_number,
    output reg          ledx,
    output reg          ready_for_mole,
    output reg          timeout_start,
    output reg [15:0]   points,
    output reg [1:0]    level_number
);

    // Internal values
    reg [8:0]  concurrent;
    reg [3:0]  multiplier; 
    wire       switchx; 
    reg        reset_button_pressed;       // Reset button
    reg        start_button_pressed;       // Start button

    // --- Level choose & start/reset requests from key_switches ---
    always @(*) begin : level_choose_from_keys
        // defaults
        level_number          = 2'b00;
        start_button_pressed  = 1'b0;
        reset_button_pressed  = 1'b0;

        case (key_switches)
            4'b0000: begin
                // RESET case
                level_number         = 2'b00;
                reset_button_pressed = 1'b1;
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
                level_number         = 2'b00;
            end
        endcase
    end

    // --- Toggle switches vs LED number (assumes led_number is one-hot) ---
    assign switchx = |(toggle_switches & led_number);

    // Start Button Synchroniser + rising edge detect 
    reg start_button, start_button_edge;
    always @(posedge clk) begin
        start_button <= start_button_pressed;
        start_button_edge <= start_button_pressed & ~start_button; // rising edge
    end

    // Reset Button Synchroniser + rising edge detect 
    reg reset_button, reset_button_edge;
    always @(posedge clk) begin
        reset_button <= reset_button_pressed;
        reset_button_edge <= reset_button_pressed & ~reset_button; // rising edge
    end

    // State Machine parameters
    parameter S0_Idle         = 3'b000;
    parameter S1_Choose_Mole  = 3'b001;
    parameter S2_Wait_For_Hit = 3'b010;
    parameter S3_Hit          = 3'b011;
    parameter S4_Miss         = 3'b100;

    reg [2:0] current_state, next_state;

    // Initial state
    initial current_state = S0_Idle;

    // Next State Logic
    always @(*) begin : whac_a_mole_next_state_logic
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
                if (reset_button_edge) next_state = S0_Idle;
                else if (!timeout)     next_state = S4_Miss;
                else if (switchx)      next_state = S3_Hit;
                else                   next_state = S2_Wait_For_Hit;
            end
            S3_Hit:  next_state = S1_Choose_Mole;
            S4_Miss: next_state = S1_Choose_Mole;
            default: next_state = S0_Idle;
        endcase
    end

    // State Register & Score Logic
    always @(posedge clk) begin : whac_a_mole_fsm_ff
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
            points     <= points + multiplier;
            concurrent <= concurrent + 1;
        end
        else if (current_state == S4_Miss) begin
            concurrent <= 0;
            multiplier <= 1;
            // points unchanged
        end
    end

    // Output Logic
    always @(*) begin : whac_a_mole_fsm_output
        ledx = 0;
        ready_for_mole = 0;
        timeout_start = 0;

        case (current_state)
            S0_Idle: begin
                ledx = 0;
                ready_for_mole = 0;
                timeout_start = 0;
            end
            S1_Choose_Mole: begin
                ledx = 0;
                ready_for_mole = 1;
                timeout_start = 0;
            end
            S2_Wait_For_Hit: begin
                ledx = 1;
                ready_for_mole = 0;
                timeout_start = 1;
            end
            S3_Hit: begin
                ledx = 0;
                ready_for_mole = 0;
                timeout_start = 0;
            end
            S4_Miss: begin
                ledx = 0;
                ready_for_mole = 0;
                timeout_start = 0;
            end
        endcase
    end

endmodule
