// space_invaders.v
module space_invaders (
    input wire CLOCK_50,
    input wire [3:0] KEY,
    input wire [9:0] SW,
    
    // VGA outputs
    output wire VGA_CLK,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire VGA_BLANK_N,
    output wire VGA_SYNC_N,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    
    // Status outputs
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5
);
    // Input mapping
    wire reset = SW[9];
    wire start_button = ~KEY[3];
    wire fire_button = ~KEY[2];
    wire right_button = ~KEY[0];
    wire left_button = ~KEY[1];

    // Internal signals
    wire pixel_clk, game_clk, clk_locked;
    wire [9:0] pixel_x, pixel_y;
    wire video_on, frame_tick;
    wire [1:0] game_state;
    wire [2:0] element_type;
    wire [9:0] element_x, element_y;
    wire [7:0] score, high_score;
    wire [1:0] frame;
    wire game_over, game_win;
    wire [1:0] sprite_color;

    // Clock generation
    pll_simple pll (
        .refclk(CLOCK_50),
        .rst(reset),
        .outclk_0(pixel_clk),  // 25MHz for VGA
        .outclk_1(game_clk),   // 50MHz for game logic
        .locked(clk_locked)
    );

    // Game state controller
    game_fsm game_ctrl (
        .clk(game_clk),
        .reset(reset),
        .start_button(start_button),
        .fire_button(fire_button),
        .game_win(game_win),
        .game_over(game_over),
        .game_state(game_state)
    );

    // VGA controller
    vga_controller vga_ctrl (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .x(pixel_x),
        .y(pixel_y),
        .display_on(video_on),
        .frame_tick(frame_tick)
    );

    // Game logic
    game_logic game_logic_inst (
        .clk(game_clk),
        .reset(reset),
        .fire(fire_button),
        .left(left_button),
        .right(right_button),
        .x(pixel_x),
        .y(pixel_y),
        .game_state(game_state),
        .game_over(game_over),
        .game_win(game_win),
        .score(score),
        .high_score(high_score),
        .element_type(element_type),
        .element_x(element_x),
        .element_y(element_y),
        .frame(frame),
        .sprite_color(sprite_color)
    );

    // Graphics renderer
    pixel_graphics graphics (
        .pixel_clk(pixel_clk),
        .x(pixel_x),
        .y(pixel_y),
        .game_state(game_state),
        .element_type(element_type),
        .element_x(element_x),
        .element_y(element_y),
        .frame(frame),
        .score(score),
        .high_score(high_score),
        .sprite_color(sprite_color),
        .red(VGA_R),
        .green(VGA_G),
        .blue(VGA_B)
    );

    // Score displays
    score_hex_display score_low (
        .bin(score[3:0]),
        .seg(HEX0)
    );
    
    score_hex_display score_high (
        .bin(score[7:4]),
        .seg(HEX1)
    );
    
    score_hex_display high_score_low (
        .bin(high_score[3:0]),
        .seg(HEX2)
    );
    
    score_hex_display high_score_high (
        .bin(high_score[7:4]),
        .seg(HEX3)
    );

    // Status display on HEX4-5
    assign HEX4 = (game_state == 2'b00) ? 7'b1000000 :  // 0
                  (game_state == 2'b01) ? 7'b1111001 :  // 1
                  (game_state == 2'b10) ? 7'b0100100 :  // 2
                                        7'b0110000;   // 3
    assign HEX5 = 7'b1111111; // Off

    // VGA control signals
    assign VGA_CLK = pixel_clk;
    assign VGA_BLANK_N = video_on;
    assign VGA_SYNC_N = 1'b0;

    // Debug LEDs
    assign LEDR = {clk_locked, game_state, game_over, game_win, video_on, 4'b0};

endmodule