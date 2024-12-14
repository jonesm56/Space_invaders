module pixel_graphics (
    input wire pixel_clk,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [1:0] game_state,
    input wire [2:0] element_type,
    input wire [9:0] element_x,
    input wire [9:0] element_y,
    input wire [1:0] frame,
    input wire [7:0] score,
    input wire [7:0] high_score,
    input wire [1:0] sprite_color,
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue
);

    // Screen parameters
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;

    // Color definitions
    parameter [23:0] BLACK = 24'h000000;
    parameter [23:0] WHITE = 24'hFFFFFF;
    parameter [23:0] RED = 24'hFF0000;
    parameter [23:0] GREEN = 24'h00FF00;
    parameter [23:0] BLUE = 24'h0000FF;
    parameter [23:0] YELLOW = 24'hFFFF00;
    parameter [23:0] ORANGE = 24'hFFA500;
    parameter [23:0] DARK_ORANGE = 24'hFF4500;
    
    reg [23:0] pixel_color;
    
    // Text display signals
    reg [7:0] char_code;
    wire [7:0] char_row_data;
    reg [3:0] char_row;
    reg [2:0] char_col;
    wire char_pixel;
    
    // Sprite display signals
    reg [3:0] sprite_type;
    wire [31:0] sprite_row_data;
    reg [5:0] sprite_row;
    wire sprite_pixel;
    
    // Star pattern generation
    wire is_star;
    assign is_star = ((x + y) % 48 == 0) && ((x * y) % 67 == 0);
    wire is_big_star;
    assign is_big_star = ((x + y) % 96 == 0) && ((x * y) % 79 == 0);
    
    // ROM instances
    char_rom char_rom_inst (
        .char_code(char_code),
        .row(char_row),
        .row_data(char_row_data)
    );
    
    sprite_rom sprite_rom_inst (
        .sprite_type(sprite_type),
        .frame(frame),
        .row(y - element_y),
        .row_data(sprite_row_data)
    );
    
    // Helper assignments
    assign char_pixel = char_row_data[7-char_col];
    assign sprite_pixel = sprite_row_data[31 - (x - element_x)];
    
    // Score to ASCII conversion
    function [7:0] hex_to_ascii;
        input [3:0] hex;
        begin
            hex_to_ascii = (hex < 10) ? (8'h30 + hex) : (8'h41 + hex - 10);
        end
    endfunction

    // Main rendering logic
    always @(posedge pixel_clk) begin
        // Calculate text position
        char_row = y[3:0];
        char_col = x[2:0];
        sprite_type = element_type;
        
        // Default black background with stars
        pixel_color = BLACK;
        if (is_big_star) 
            pixel_color = WHITE;
        else if (is_star)
            pixel_color = 24'hA0A0A0; 
        
        case (game_state)
            2'b00: begin // START_SCREEN
                // Title "SPACE INVADERS"
                if (y >= SCREEN_HEIGHT/2-48 && y < SCREEN_HEIGHT/2-32) begin
                    case ((x - (SCREEN_WIDTH/2-100))/8)
                        0: char_code = "S";
                        1: char_code = "P";
                        2: char_code = "A";
                        3: char_code = "C";
                        4: char_code = "E";
                        5: char_code = " ";
                        6: char_code = "I";
                        7: char_code = "N";
                        8: char_code = "V";
                        9: char_code = "A";
                        10: char_code = "D";
                        11: char_code = "E";
                        12: char_code = "R";
                        13: char_code = "S";
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = x[0] && y[0] ? DARK_ORANGE : ORANGE;
                end

                // "PRESS START"
                if (y >= SCREEN_HEIGHT/2+16 && y < SCREEN_HEIGHT/2+32) begin
                    case ((x - (SCREEN_WIDTH/2-60))/8)
                        0: char_code = "P";
                        1: char_code = "R";
                        2: char_code = "E";
                        3: char_code = "S";
                        4: char_code = "S";
                        5: char_code = " ";
                        6: char_code = "S";
                        7: char_code = "T";
                        8: char_code = "A";
                        9: char_code = "R";
                        10: char_code = "T";
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = WHITE;
                end
            end

            2'b01: begin // MAIN_SCREEN
                // Game elements
                if (sprite_pixel) begin
                    case (element_type)
                        3'b000: pixel_color = WHITE;  // Ship
                        3'b001, 3'b010, 3'b011: begin // Aliens
                            case (sprite_color)
                                2'b00: pixel_color = GREEN;
                                2'b01: pixel_color = BLUE;
                                2'b10: pixel_color = YELLOW;
                                2'b11: pixel_color = RED;
                            endcase
                        end
                        3'b100: pixel_color = WHITE;  // Explosion
                        3'b101: begin // Rocket  
                            case (sprite_color)
                                2'b00: pixel_color = WHITE;  // Ship's rocket
                                2'b01, 2'b10, 2'b11: begin  // Aliens' rockets
                                    case (sprite_color)
                                        2'b01: pixel_color = GREEN;
                                        2'b10: pixel_color = BLUE; 
                                        2'b11: pixel_color = YELLOW;
                                        default: pixel_color = WHITE;
                                    endcase
                                end
                                default: pixel_color = WHITE; 
                            endcase
                        end
                        default: pixel_color = WHITE;
                    endcase
                end

                // Score display
                if (y < 16) begin
                    case ((x)/8)
                        0: char_code = "S";
                        1: char_code = "C";
                        2: char_code = "O";
                        3: char_code = "R";
                        4: char_code = "E";
                        5: char_code = ":";
                        6: char_code = hex_to_ascii(score[7:4]);
                        7: char_code = hex_to_ascii(score[3:0]);
                        8: char_code = " ";
                        9: char_code = "H";
                        10: char_code = "I";
                        11: char_code = ":";
                        12: char_code = hex_to_ascii(high_score[7:4]);
                        13: char_code = hex_to_ascii(high_score[3:0]);
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = WHITE;
                end
            end

            2'b10: begin // WIN_SCREEN
                // "VICTORY!"
                if (y >= SCREEN_HEIGHT/2-16 && y < SCREEN_HEIGHT/2) begin
                    case ((x - (SCREEN_WIDTH/2-40))/8)
                        0: char_code = "V";
                        1: char_code = "I";
                        2: char_code = "C";
                        3: char_code = "T";
                        4: char_code = "O";
                        5: char_code = "R";
                        6: char_code = "Y";
                        7: char_code = "!";
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = frame[1] ? YELLOW : GREEN;
                end

                // "PRESS START TO CONTINUE"
                if (y >= SCREEN_HEIGHT/2+16 && y < SCREEN_HEIGHT/2+32) begin
                    case ((x - (SCREEN_WIDTH/2-100))/8)
                        0: char_code = "P";
                        1: char_code = "R";
                        2: char_code = "E";
                        3: char_code = "S";
                        4: char_code = "S";
                        5: char_code = " ";
                        6: char_code = "S";
                        7: char_code = "T";
                        8: char_code = "A";
                        9: char_code = "R";
                        10: char_code = "T";
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = WHITE;
                end
            end

            2'b11: begin // LOSE_SCREEN
                // "GAME OVER"
                if (y >= SCREEN_HEIGHT/2-16 && y < SCREEN_HEIGHT/2) begin
                    case ((x - (SCREEN_WIDTH/2-50))/8)
                        0: char_code = "G";
                        1: char_code = "A";
                        2: char_code = "M";
                        3: char_code = "E";
                        4: char_code = " ";
                        5: char_code = "O";
                        6: char_code = "V";
                        7: char_code = "E";
                        8: char_code = "R";
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = frame[1] ? RED : DARK_ORANGE;
                end

                // "PRESS FIRE TO RETRY" 
                if (y >= SCREEN_HEIGHT/2+16 && y < SCREEN_HEIGHT/2+32) begin
                    case ((x - (SCREEN_WIDTH/2-80))/8)  
                        0: char_code = "P";
                        1: char_code = "R";
                        2: char_code = "E";
                        3: char_code = "S";
                        4: char_code = "S";
                        5: char_code = " ";
                        6: char_code = "F";
                        7: char_code = "I";
                        8: char_code = "R";
                        9: char_code = "E";
                        10: char_code = " ";
                        11: char_code = "T";
                        12: char_code = "O";
                        13: char_code = " ";
                        14: char_code = "R";
                        15: char_code = "E";
                        16: char_code = "T";
                        17: char_code = "R";
                        18: char_code = "Y";
                        default: char_code = " ";
                    endcase
                    if (char_pixel)
                        pixel_color = WHITE;
                end
            end 
        endcase

        // Assign RGB outputs
        red = pixel_color[23:16];
        green = pixel_color[15:8];
        blue = pixel_color[7:0];
    end

endmodule