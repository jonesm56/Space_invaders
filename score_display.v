module score_display (
    input clk,
    input reset,
    input [9:0] x,
    input [9:0] y,
    input [7:0] score,
    input [7:0] high_score,
    input [1:0] game_state,
    output reg [15:0] font_addr,
    output reg font_active,
    output reg [7:0] progress_r,
    output reg [7:0] progress_g,
    output reg [7:0] progress_b
);
    // Display parameters for 640x480
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter SCORE_BAR_WIDTH = 140;
    parameter SCORE_BAR_HEIGHT = 32;
    parameter SCORE_X = 35;
    parameter SCORE_Y = 20;
    parameter HIGH_SCORE_X = 400;
    parameter HIGH_SCORE_Y = 440;
    parameter CHAR_WIDTH = 32;
    parameter CHAR_HEIGHT = 48;

    // ASCII codes
    parameter ASCII_0 = 8'h30;
    parameter ASCII_9 = 8'h39;
    parameter ASCII_S = 8'h53;
    parameter ASCII_C = 8'h43;
    parameter ASCII_O = 8'h4F;
    parameter ASCII_R = 8'h52;
    parameter ASCII_E = 8'h45;
    parameter ASCII_H = 8'h48;
    parameter ASCII_I = 8'h49;
    parameter ASCII_G = 8'h47;

    // Score conversion to digits
    wire [3:0] score_hundreds = score / 100;
    wire [3:0] score_tens = (score % 100) / 10;
    wire [3:0] score_ones = score % 10;
    
    wire [3:0] high_hundreds = high_score / 100;
    wire [3:0] high_tens = (high_score % 100) / 10;
    wire [3:0] high_ones = high_score % 10;

    // Progress bar calculation
    wire [7:0] progress_width = (score * SCORE_BAR_WIDTH) / 180;

    always @(posedge clk) begin
        if (reset) begin
            font_addr <= 0;
            font_active <= 0;
            progress_r <= 0;
            progress_g <= 0;
            progress_b <= 0;
        end else begin
            // Default values
            font_active <= 0;
            progress_r <= 0;
            progress_g <= 0;
            progress_b <= 0;

            // Draw score progress bar
            if (y >= SCORE_Y && y < SCORE_Y + SCORE_BAR_HEIGHT &&
                x >= SCORE_X && x < SCORE_X + progress_width) begin
                progress_g <= 8'hFF;
            end

            // Draw current score
            if (y >= SCORE_Y && y < SCORE_Y + CHAR_HEIGHT) begin
                if (x >= SCORE_X + SCORE_BAR_WIDTH + 20 && 
                    x < SCORE_X + SCORE_BAR_WIDTH + 20 + CHAR_WIDTH * 3) begin
                    font_active <= 1;
                    case ((x - (SCORE_X + SCORE_BAR_WIDTH + 20)) / CHAR_WIDTH)
                        0: font_addr <= (ASCII_0 + score_hundreds) * CHAR_HEIGHT + (y - SCORE_Y);
                        1: font_addr <= (ASCII_0 + score_tens) * CHAR_HEIGHT + (y - SCORE_Y);
                        2: font_addr <= (ASCII_0 + score_ones) * CHAR_HEIGHT + (y - SCORE_Y);
                    endcase
                end
            end

            // Draw high score
            if (game_state == 2'b00 || game_state == 2'b11) begin  // START or LOSE screen
                if (y >= HIGH_SCORE_Y && y < HIGH_SCORE_Y + CHAR_HEIGHT) begin
                    if (x >= HIGH_SCORE_X && x < HIGH_SCORE_X + CHAR_WIDTH * 12) begin
                        font_active <= 1;
                        case ((x - HIGH_SCORE_X) / CHAR_WIDTH)
                            0: font_addr <= ASCII_H * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            1: font_addr <= ASCII_I * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            2: font_addr <= ASCII_G * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            3: font_addr <= ASCII_H * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            4: font_addr <= ASCII_S * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            5: font_addr <= ASCII_C * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            6: font_addr <= ASCII_O * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            7: font_addr <= ASCII_R * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            8: font_addr <= ASCII_E * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            9: font_addr <= (ASCII_0 + high_hundreds) * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            10: font_addr <= (ASCII_0 + high_tens) * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                            11: font_addr <= (ASCII_0 + high_ones) * CHAR_HEIGHT + (y - HIGH_SCORE_Y);
                        endcase
                    end
                end
            end
        end
    end
endmodule