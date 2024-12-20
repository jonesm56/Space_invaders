// Game State Controller
module game_fsm (
    input wire clk,
    input wire reset,
    input wire start_button,
    input wire fire_button,
    input wire game_win,
    input wire game_over,
    output reg [1:0] game_state
);
    // Game states
    parameter START_SCREEN = 2'b00;
    parameter MAIN_SCREEN = 2'b01;
    parameter WIN_SCREEN = 2'b10;
    parameter LOSE_SCREEN = 2'b11;
    
    // Debounced button inputs
    wire start_debounced, fire_debounced;
    
    // Debounce instances
    debounce start_deb (
        .clk(clk),
        .reset(reset),
        .btn_in(start_button),
        .btn_out(start_debounced)
    );
    
    debounce fire_deb (
        .clk(clk),
        .reset(reset),
        .btn_in(fire_button),
        .btn_out(fire_debounced)
    );
    
    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            game_state <= START_SCREEN;
        end else begin
            case (game_state)
                START_SCREEN: begin
                    if (start_debounced)
                        game_state <= MAIN_SCREEN;
                end
                
                MAIN_SCREEN: begin
                    if (game_win)
                        game_state <= WIN_SCREEN;
                    else if (game_over)
                        game_state <= LOSE_SCREEN;
                end
                
                WIN_SCREEN: begin
                    if (start_debounced)
                        game_state <= START_SCREEN;
                end
                
                LOSE_SCREEN: begin
                    if (start_debounced || fire_debounced)
                        game_state <= START_SCREEN;
                end
            endcase
        end
    end
endmodule