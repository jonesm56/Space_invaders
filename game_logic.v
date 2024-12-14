module game_logic (
    input wire clk,
    input wire reset,
    input wire fire,
    input wire left,
    input wire right,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [1:0] game_state,
    output reg game_over,
    output reg game_win,
    output reg [7:0] score,
    output reg [7:0] high_score,
    output reg [2:0] element_type,
    output reg [9:0] element_x,
    output reg [9:0] element_y,
    output reg [1:0] frame,
    output reg [1:0] sprite_color
);

    // Screen parameters
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter NUM_ALIENS = 18;
    parameter ALIEN_COLS = 6;
    parameter ALIEN_ROWS = 3;
    parameter ALIEN_SIZE = 16;      // Smaller aliens
    parameter SHIP_SIZE = 32;       // Larger ship
    parameter SHIP_SPEED = 1;       // Slower ship movement
    parameter ROCKET_SIZE = 8;
    parameter ALIEN_SPACING_X = 40;
    parameter ALIEN_SPACING_Y = 32;
    parameter ALIEN_START_Y = 40;   // Start higher
    
    // Fixed point parameters for alien movement
    parameter [13:0] ALIEN_SPEED = 14'd8;  // 0.5 pixels per move (4.10 fixed point)
    parameter ALIEN_DROP_AMOUNT = 16;      // One sprite height
    
    // Timing parameters
    parameter MOVE_INTERVAL = 20'd166666;    // Movement update rate (~3ms at 50MHz)
    parameter FRAME_INTERVAL = 20'd833333;   // Animation frame rate (60Hz)
    parameter EXPLOSION_DURATION = 20'd50000000; // 1 second at 50MHz
    
    // Game state registers
    reg [9:0] ship_x;
    reg [9:0] ship_y;
    reg [9:0] alien_x [0:NUM_ALIENS-1];
    reg [13:0] alien_subx [0:NUM_ALIENS-1];  // 4.10 fixed point positions
    reg [9:0] alien_y [0:NUM_ALIENS-1];
    reg [NUM_ALIENS-1:0] alien_alive;
    reg alien_direction;
    reg [9:0] rocket_x;
    reg [9:0] rocket_y;
    reg rocket_active;
    reg [19:0] frame_counter;
    reg [19:0] move_counter;
    reg [15:0] random_seed;
    reg [5:0] aliens_killed;
    reg processing_hit;
    reg explosion_active;
    reg [19:0] explosion_timer;
    reg [9:0] explosion_x;
    reg [9:0] explosion_y;
    reg hit_edge;
    reg should_drop;  // New flag for group movement
    
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ship_x <= (SCREEN_WIDTH - SHIP_SIZE) / 2;
            ship_y <= SCREEN_HEIGHT - SHIP_SIZE - 20;
            score <= 0;
            game_over <= 0;
            game_win <= 0;
            rocket_active <= 0;
            frame_counter <= 0;
            move_counter <= 0;
            frame <= 0;
            alien_direction <= 1;
            processing_hit <= 0;
            explosion_active <= 0;
            explosion_timer <= 0;
            aliens_killed <= 0;
            random_seed <= 16'hACE1;
            hit_edge <= 0;
            should_drop <= 0;

            // Initialize aliens
            for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                alien_x[i] <= (i % ALIEN_COLS) * ALIEN_SPACING_X + 80;
                alien_subx[i] <= ((i % ALIEN_COLS) * ALIEN_SPACING_X + 80) << 4;
                alien_y[i] <= (i / ALIEN_COLS) * ALIEN_SPACING_Y + ALIEN_START_Y;
                alien_alive[i] <= 1;
            end
        end else begin
            // Frame and animation update
            frame_counter <= frame_counter + 1;
            if (frame_counter >= FRAME_INTERVAL) begin
                frame_counter <= 0;
                frame <= frame + 1;
            end

            // Update explosion timer
            if (explosion_active) begin
                if (explosion_timer >= EXPLOSION_DURATION) begin
                    explosion_active <= 0;
                    explosion_timer <= 0;
                end else begin
                    explosion_timer <= explosion_timer + 1;
                end
            end

            if (game_state == 2'b01) begin // MAIN_SCREEN
                // Ship movement
                if (left && ship_x > SHIP_SPEED)
                    ship_x <= ship_x - SHIP_SPEED;
                if (right && ship_x < SCREEN_WIDTH - SHIP_SIZE - SHIP_SPEED)
                    ship_x <= ship_x + SHIP_SPEED;

                // Rocket control
                if (fire && !rocket_active) begin
                    rocket_active <= 1;
                    rocket_x <= ship_x + (SHIP_SIZE/2) - (ROCKET_SIZE/2);
                    rocket_y <= ship_y;
                end

                if (rocket_active) begin
                    if (rocket_y <= ROCKET_SIZE)
                        rocket_active <= 0;
                    else
                        rocket_y <= rocket_y - 4; // Faster rocket

                    // Collision detection
                    if (!processing_hit) begin
                        for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                            if (alien_alive[i] &&
                                rocket_x + ROCKET_SIZE >= alien_x[i] &&
                                rocket_x <= alien_x[i] + ALIEN_SIZE &&
                                rocket_y >= alien_y[i] &&
                                rocket_y <= alien_y[i] + ALIEN_SIZE) begin
                                alien_alive[i] <= 0;
                                rocket_active <= 0;
                                processing_hit <= 1;
                                aliens_killed <= aliens_killed + 1;
                                score <= score + (3'd7 - alien_y[i][8:6]);
                                
                                explosion_active <= 1;
                                explosion_timer <= 0;
                                explosion_x <= alien_x[i];
                                explosion_y <= alien_y[i];
                            end
                        end
                    end
                end

                // Alien movement
                move_counter <= move_counter + 1;
                if (move_counter >= MOVE_INTERVAL) begin
                    move_counter <= 0;
                    hit_edge <= 0;
                    should_drop <= 0;
                    
                    // Check if any alien hits the edge
                    for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                        if (alien_alive[i]) begin
                            if ((alien_direction && alien_subx[i][13:4] >= SCREEN_WIDTH - ALIEN_SIZE - 1) ||
                                (!alien_direction && alien_subx[i][13:4] <= 1)) begin
                                should_drop <= 1;
                                hit_edge <= 1;
                            end
                        end
                    end

                    // Move all aliens together
                    for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                        if (alien_alive[i]) begin
                            if (should_drop) begin
                                alien_y[i] <= alien_y[i] + ALIEN_DROP_AMOUNT;
                            end else begin
                                if (alien_direction) begin
                                    alien_subx[i] <= alien_subx[i] + ALIEN_SPEED;
                                end else begin
                                    alien_subx[i] <= alien_subx[i] - ALIEN_SPEED;
                                end
                                alien_x[i] <= alien_subx[i][13:4];
                            end
                        end
                    end

                    // Change direction after all aliens have moved
                    if (should_drop) begin
                        alien_direction <= !alien_direction;
                    end

                    // Check for game over
                    for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                        if (alien_alive[i] && alien_y[i] + ALIEN_SIZE >= ship_y) begin
                            game_over <= 1;
                        end
                    end
                end

                // Win condition
                if (aliens_killed == NUM_ALIENS)
                    game_win <= 1;
            end

            // Update high score
            if (score > high_score)
                high_score <= score;
        end
    end

    // Rendering logic
    always @* begin
        element_type = 3'b100;  // Default background
        element_x = 0;
        element_y = 0;
        sprite_color = 2'b00;   // Default white

        // Ship
        if (x >= ship_x && x < ship_x + SHIP_SIZE &&
            y >= ship_y && y < ship_y + SHIP_SIZE) begin
            element_type = 3'b000;
            element_x = ship_x;
            element_y = ship_y;
            sprite_color = 2'b00;  // White ship
        end

        // Aliens
        for (i = 0; i < NUM_ALIENS; i = i + 1) begin
            if (alien_alive[i] &&
                x >= alien_x[i] && x < alien_x[i] + ALIEN_SIZE &&
                y >= alien_y[i] && y < alien_y[i] + ALIEN_SIZE) begin
                element_type = {1'b0, 2'b01};  // Always type 1 alien
                element_x = alien_x[i];
                element_y = alien_y[i];
                sprite_color = 2'b01;  // Green aliens
            end
        end

        // Explosion
        if (explosion_active &&
            x >= explosion_x && x < explosion_x + ALIEN_SIZE &&
            y >= explosion_y && y < explosion_y + ALIEN_SIZE) begin
            element_type = 3'b100;
            element_x = explosion_x;
            element_y = explosion_y;
            sprite_color = 2'b11;
        end

        // Rocket (larger and color-matched to ship)
        if (rocket_active &&
            x >= rocket_x && x < rocket_x + ROCKET_SIZE &&
            y >= rocket_y && y < rocket_y + ROCKET_SIZE*2) begin
            element_type = 3'b101;
            element_x = rocket_x;
            element_y = rocket_y;
            sprite_color = 2'b00;  // White like the ship
        end
    end

endmodule