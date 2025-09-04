///*
// * Finite State Machine for controlling the hit-or-miss game,
// * written in SystemVerilog.
// *
// * This module manages the game logic, detects hits and misses,
// * updates the score, and signals the main top-level module to
// * start a new round or end the game.
// */
//module fsm_test (
//    input logic clk,
//    input logic reset_n, // Main system reset
//    input logic [17:0] switches, // The switch inputs from the board
//    input logic [17:0] leds_from_sequencer, // The LEDs currently lit
//    input logic timer_expired_in, // A signal indicating the timer has expired
//    output logic reset_sequencer_out, // Signal to reset the random_led_sequencer
//    output logic [15:0] score_out // The game score
//);
//
//    // FSM State definitions using an enumerated type for clarity and safety.
//    typedef enum logic [2:0] {
//        IDLE,
//        PLAYING,
//        HIT,
//        MISS,
//        GAME_OVER
//    } state_t;
//
//    // FSM State registers
//    state_t current_state, next_state;
//
//    // A register to detect a hit
//    logic hit_detected;
//
//    // Sequential logic for state transitions and score updates
//    // This uses a non-blocking assignment (`<=`).
//    always_ff @(posedge clk or negedge reset_n) begin
//        if (!reset_n) begin
//            current_state <= IDLE;
//            score_out <= 16'd0;
//            reset_sequencer_out <= 1'b1;
//        end else begin
//            current_state <= next_state;
//            reset_sequencer_out <= 1'b0; // Default to not resetting
//
//            // Update outputs based on the next state
//            case (next_state)
//                IDLE: begin
//                    score_out <= 16'd0;
//                end
//                HIT: begin
//                    score_out <= score_out + 1;
//                    reset_sequencer_out <= 1'b1;
//                end
//                MISS: begin
//                    reset_sequencer_out <= 1'b1;
//                end
//                default: begin
//                    // Keep score and sequencer state
//                end
//            endcase
//        end
//    end
//
//    // Combinational logic for next-state determination
//    // This uses a blocking assignment (`=`).
//    always_comb begin
//        // Default outputs
//        next_state = current_state;
//        hit_detected = 1'b0;
//        
//        // Detect a hit if any switch corresponding to a lit LED is pressed
//        if (| (switches & leds_from_sequencer)) begin
//            hit_detected = 1'b1;
//        end
//        
//        // FSM State logic
//        case (current_state)
//            IDLE: begin
//                // Go to PLAYING state when reset is released and game is enabled
//                if (reset_n) begin
//                    next_state = PLAYING;
//                end
//            end
//
//            PLAYING: begin
//                // Check for a hit
//                if (hit_detected) begin
//                    next_state = HIT;
//                end
//                // Check for a miss (timer expired)
//                else if (timer_expired_in) begin
//                    next_state = MISS;
//                end
//            end
//
//            HIT: begin
//                // If max score is reached, go to GAME_OVER
//                if (score_out == 16'd9999) begin
//                    next_state = GAME_OVER;
//                end
//                // Otherwise, start a new round
//                else begin
//                    next_state = PLAYING;
//                end
//            end
//
//            MISS: begin
//                // Start a new round
//                next_state = PLAYING;
//            end
//
//            GAME_OVER: begin
//                // Stay in GAME_OVER until the user resets
//                if (!reset_n) begin
//                    next_state = IDLE;
//                end
//            end
//            
//            default: begin
//                next_state = IDLE;
//            end
//        endcase
//    end
//
//endmodule

/*
 * Finite State Machine for controlling the hit-or-miss game,
 * written in SystemVerilog.
 *
 * This module manages the game logic, detects hits and misses,
 * and updates the score.
 */
/*
 * Finite State Machine for controlling the hit-or-miss game,
 * written in SystemVerilog.
 *
 * This module manages the game logic, detects hits and misses,
 * and updates the score.
 */
// The FSM controls the game logic, transitioning between IDLE, PLAYING, and HIT states.
// The FSM controls the game logic, transitioning between IDLE, PLAYING, and HIT states.
module fsm_test (
	input logic clk,
	input logic reset_n, // Main game reset
	input logic game_start_in, // New input to start the game from top_level
	input logic [17:0] switches, // The switch inputs from the board
	input logic [17:0] leds_from_sequencer, // The LEDs currently lit
	input logic timer_expired_in, // Signal indicating the timer has expired
	output logic reset_sequencer_out, // Signal to reset the random_led_sequencer
	output logic [15:0] score_out // The game score
);

	// FSM State definitions
	typedef enum logic [1:0] {
		IDLE,
		PLAYING,
		HIT
	} state_t;

	// FSM State registers
	state_t current_state, next_state;

	// A register to detect a hit on the rising edge of the switch
	logic hit_detected;
	logic prev_hit_detected;
	logic hit_rising_edge;

	// Registers to detect a rising edge on the timer signal
	logic timer_expired_reg;
	logic timer_expired_rising_edge;

	// Sequential logic for state and score updates
	always_ff @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			current_state <= IDLE;
			score_out <= 16'd0;
			reset_sequencer_out <= 1'b1; // Reset sequencer on main game reset
			prev_hit_detected <= 1'b0;
			timer_expired_reg <= 1'b0;
		end else begin
			current_state <= next_state;

			// Capture the previous state of hit_detected for edge detection
			prev_hit_detected <= hit_detected;
			// Capture the previous state of the timer expired signal
			timer_expired_reg <= timer_expired_in;

			// Default output assignments
			reset_sequencer_out <= 1'b0;

			// Update outputs based on the next state
			case (next_state)
				IDLE: begin
//					score_out <= 16'd0;
				end
				HIT: begin
					score_out <= score_out + 1;
//					reset_sequencer_out <= 1'b1; // Reset sequencer on a successful hit
				end
				default: begin
					// Keep score and sequencer state
				end
			endcase
		end
	end

	// Combinational logic for next-state determination
	always_comb begin
		next_state = current_state;
		
		// Detect a hit if any switch corresponding to a lit LED is pressed
		hit_detected = switches & leds_from_sequencer;
		
		// Detect a rising edge of a hit
		hit_rising_edge = hit_detected && !prev_hit_detected;
		
		// Detect a rising edge of the timer expiring
		timer_expired_rising_edge = timer_expired_in && !timer_expired_reg;

		// FSM State logic
		case (current_state)
			IDLE: begin
				// Transition to PLAYING when the game is started
				if (game_start_in) begin
					next_state = PLAYING;
				end
			end

			PLAYING: begin
				if (hit_rising_edge) begin
					next_state = HIT;
				end
				else if (timer_expired_rising_edge) begin
					// Timer expired (a miss), continue playing by transitioning back to playing
					next_state = PLAYING;
				end
			end

			HIT: begin
				// After a hit, go back to playing to start a new round.
				next_state = PLAYING;
			end
			
			default: begin
				next_state = IDLE;
			end
		endcase
	end
endmodule
