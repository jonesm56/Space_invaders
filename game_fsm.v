module game_fsm (
    input clk,
    input reset,
    input start_button,
    input fire_button,
    input game_win,
    input game_over,
    output reg [1:0] game_state,
    output reg game_reset
);
    // Game states
    parameter START_SCREEN = 2'b00;
    parameter MAIN_SCREEN = 2'b01;
    parameter WIN_SCREEN = 2'b10;
    parameter LOSE_SCREEN = 2'b11;

    // State transition timing
    parameter TRANSITION_DELAY = 20'd50000000;  // About 1 second at 50MHz
    reg [19:0] state_timer;

    // Button edge detection with hysteresis
    reg [2:0] start_shift;
    reg [2:0] fire_shift;
    wire start_pressed = (start_shift == 3'b011);
    wire fire_pressed = (fire_shift == 3'b011);

    // Edge detection shift registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_shift <= 3'b000;
            fire_shift <= 3'b000;
        end else begin
            start_shift <= {start_shift[1:0], start_button};
            fire_shift <= {fire_shift[1:0], fire_button};
        end
    end

    // Main FSM logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            game_state <= START_SCREEN;
            game_reset <= 1'b1;
            state_timer <= 20'd0;
        end else begin
            // Default state for game_reset
            game_reset <= 1'b0;
            
            case (game_state)
                START_SCREEN: begin
                    if (start_pressed) begin
                        game_state <= MAIN_SCREEN;
                        game_reset <= 1'b1;
                        state_timer <= 20'd0;
                    end
                end
                
                MAIN_SCREEN: begin
                    if (game_win) begin
                        game_state <= WIN_SCREEN;
                        state_timer <= 20'd0;
                    end else if (game_over) begin
                        game_state <= LOSE_SCREEN;
                        state_timer <= 20'd0;
                    end
                end
                
                WIN_SCREEN: begin
                    if (state_timer < TRANSITION_DELAY) begin
                        state_timer <= state_timer + 1'b1;
                    end else if (start_pressed) begin
                        game_state <= START_SCREEN;
                        game_reset <= 1'b1;
                        state_timer <= 20'd0;
                    end
                end
                
                LOSE_SCREEN: begin
                    if (state_timer < TRANSITION_DELAY) begin
                        state_timer <= state_timer + 1'b1;
                    end else begin
                        if (start_pressed) begin
                            game_state <= START_SCREEN;
                            game_reset <= 1'b1;
                            state_timer <= 20'd0;
                        end else if (fire_pressed) begin
                            game_state <= MAIN_SCREEN;
                            game_reset <= 1'b1;
                            state_timer <= 20'd0;
                        end
                    end
                end
                
                default: begin
                    game_state <= START_SCREEN;
                    game_reset <= 1'b1;
                    state_timer <= 20'd0;
                end
            endcase
        end
    end
endmodule