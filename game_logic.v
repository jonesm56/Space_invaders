module game_logic (
    input clk,
    input reset,
    input fire,
    input left,
    input right,
    input [9:0] x,
    input [9:0] y,
    input [1:0] game_state,
    output reg game_over,
    output reg game_win,
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue,
    output reg [7:0] score,
    output reg [7:0] high_score,
    output reg [15:0] screen_addr,
    output reg [15:0] element_addr,
    output reg [2:0] element_type,
    output reg [1:0] frame
);

    // Screen and sprite parameters
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter NUM_ALIENS = 18;
    parameter ALIEN_COLS = 6;
    parameter ALIEN_ROWS = 3;
	 
	 // Game states
	 parameter START_SCREEN = 2'b00;
    parameter MAIN_SCREEN = 2'b01;
    parameter WIN_SCREEN = 2'b10;
    parameter LOSE_SCREEN = 2'b11;

    // Sprite sizes (actual dimensions)
    parameter ALIEN1_WIDTH = 16;
    parameter ALIEN1_HEIGHT = 16;
    parameter ALIEN2_WIDTH = 16;
    parameter ALIEN2_HEIGHT = 22;
    parameter ALIEN3_WIDTH = 16;
    parameter ALIEN3_HEIGHT = 24;
    parameter LASER_WIDTH = 7;
    parameter LASER_HEIGHT = 3;
    parameter ROCKET_WIDTH = 7;
    parameter ROCKET_HEIGHT = 3;
    parameter SHIP_WIDTH = 16;
    parameter SHIP_HEIGHT = 30;
    parameter LIFE_WIDTH = 20;
    parameter LIFE_HEIGHT = 30;

    // Memory regions
    parameter ALIEN_1_1_START = 0;
    parameter ALIEN_1_2_START = 136;
    parameter ALIEN_2_1_START = 280;
    parameter ALIEN_2_2_START = 568;
    parameter ALIEN_3_1_START = 848;
    parameter ALIEN_3_2_START = 1190;
    parameter ALIEN_EXPLOSION_START = 1538;
    parameter LASER_1_START = 1802;
    parameter LASER_2_START = 1823;
    parameter LASER_3_START = 1844;
    parameter LASER_4_START = 1865;
    parameter LIFE_START = 1886;
    parameter ROCKET_1_START = 2786;
    parameter ROCKET_2_START = 2805;
    parameter ROCKET_3_START = 2824;
    parameter ROCKET_4_START = 2843;
    parameter SPACESHIP_START = 2862;
    parameter SHIP_EXPLOSION_START = 2989;
	parameter LOSE_SCREEN_START = 0;
	parameter MAIN_SCREEN_START = 21600;
	parameter START_SCREEN_START = 43200;
	parameter WIN_SCREEN_START = 64800;
    // Game timing parameters
    parameter EXPLOSION_DURATION = 35;
    parameter INITIAL_ALIEN_SPEED = 1;
    parameter ALIEN_SPEED_INCREMENT = 1;
    parameter SHIP_SPEED = 1;
    parameter ROCKET_SPEED = 2;
    parameter LASER_SPEED = 1;
    parameter ALIEN_DROP_DISTANCE = 20;
    parameter FRAME_RATE = 25000000 / 60;
	 
	 // Alien initialize parameters
	parameter ALIEN_START_Y = 50;        // Starting Y position of alien grid
	parameter ALIEN_H_SPACING = 60;      // Horizontal spacing between aliens
	parameter ALIEN_V_SPACING = 45; 

	reg blank_n;
	
	// Vertical spacing between alien rows 
    
    // Internal game state registers
    reg [7:0] score_reg;
    reg [7:0] high_score_reg;
    reg [1:0] lives_reg;
    reg [7:0] aliens_destroyed;
    
    // Ship variables
    reg [9:0] ship_x;
    reg [9:0] ship_y;
    reg [5:0] ship_explosion_timer;
    
    // Alien variables
    reg [9:0] alien_x [0:NUM_ALIENS-1];
    reg [9:0] alien_y [0:NUM_ALIENS-1];
    reg [1:0] alien_type [0:NUM_ALIENS-1];
    reg alien_alive [0:NUM_ALIENS-1];
    reg [5:0] alien_explosion_timer [0:NUM_ALIENS-1];
    reg alien_direction;
    reg [7:0] alien_speed;
    reg [7:0] alien_move_counter;
    
    // Projectile variables
    reg [9:0] rocket_x;
    reg [9:0] rocket_y;
    reg rocket_active;
    reg [9:0] laser_x;
    reg [9:0] laser_y;
    reg laser_active;
    reg [4:0] shooting_alien;
    
    // Animation controls
    reg [15:0] animation_counter;
    reg [1:0] projectile_frame_counter;
    
    // LFSR for random number generation
    reg [15:0] lfsr;
    wire random_bit = lfsr[0];
    
    integer i;

    // LFSR update logic
    always @(posedge clk) begin
        if (reset)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end

    // Consolidated game initialization and state management
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize all game state variables
        score_reg <= 0;
        high_score_reg <= 0;
        lives_reg <= 3;
        aliens_destroyed <= 0;
        
        ship_x <= SCREEN_WIDTH/2;
        ship_y <= SCREEN_HEIGHT - SHIP_HEIGHT - 10;
        ship_explosion_timer <= 0;
        
        alien_direction <= 1;
        alien_speed <= INITIAL_ALIEN_SPEED;
        alien_move_counter <= 0;
        
        game_over <= 0;
        game_win <= 0;
        
        rocket_active <= 0;
        rocket_x <= 0;
        rocket_y <= 0;
        
        laser_active <= 0;
        laser_x <= 0;
        laser_y <= 0;
        
        animation_counter <= 0;
        frame <= 0;
        projectile_frame_counter <= 0;
        
        shooting_alien <= 0;

        // Initialize aliens
        for (i = 0; i < NUM_ALIENS; i = i + 1) begin
            alien_alive[i] <= 1;
            alien_explosion_timer[i] <= 0;
            alien_x[i] <= 50 + (i % ALIEN_COLS) * ALIEN_H_SPACING;
            alien_y[i] <= 50 + (i / ALIEN_COLS) * ALIEN_V_SPACING;
            alien_type[i] <= i / ALIEN_COLS;
        end
    end else begin
        // Animation and frame update
        if (animation_counter >= FRAME_RATE / 4) begin
            animation_counter <= 0;
            frame <= frame + 1;
            projectile_frame_counter <= projectile_frame_counter + 1;
        end else begin
            animation_counter <= animation_counter + 1;
        end
        
        // Update high score
        if (score_reg > high_score_reg)
            high_score_reg <= score_reg;

        // Main game logic for active game state
        if (game_state == MAIN_SCREEN) begin
            // Ship movement
            if (left && ship_x > SHIP_SPEED)
                ship_x <= ship_x - SHIP_SPEED;
            if (right && ship_x < SCREEN_WIDTH - SHIP_WIDTH - SHIP_SPEED)
                ship_x <= ship_x + SHIP_SPEED;

            // Rocket handling
            if (fire && !rocket_active && ship_explosion_timer == 0) begin
                rocket_active <= 1;
                rocket_x <= ship_x + (SHIP_WIDTH - ROCKET_WIDTH)/2;
                rocket_y <= ship_y - ROCKET_HEIGHT;
            end

            if (rocket_active) begin
                rocket_y <= rocket_y - ROCKET_SPEED;
                if (rocket_y <= 0)
                    rocket_active <= 0;

                // Check collision with aliens
                for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                    if (alien_alive[i] &&
                        rocket_x < alien_x[i] + ALIEN1_WIDTH &&
                        rocket_x + ROCKET_WIDTH > alien_x[i] &&
                        rocket_y < alien_y[i] + ALIEN1_HEIGHT &&
                        rocket_y + ROCKET_HEIGHT > alien_y[i]) begin
                        alien_alive[i] <= 0;
                        alien_explosion_timer[i] <= EXPLOSION_DURATION;
                        rocket_active <= 0;
                        score_reg <= score_reg + 10;
                        aliens_destroyed <= aliens_destroyed + 1;
                        if ((aliens_destroyed + 1) % 3 == 0)
                            alien_speed <= alien_speed + ALIEN_SPEED_INCREMENT;
                    end
                end
            end

            // Alien movement and shooting
            if (alien_move_counter >= alien_speed) begin
                alien_move_counter <= 0;
                for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                    if (alien_alive[i]) begin
                        // Horizontal movement
                        if (alien_direction)
                            alien_x[i] <= alien_x[i] + 2;
                        else
                            alien_x[i] <= alien_x[i] - 2;

                        // Check for direction change and drop
                        if ((alien_direction && alien_x[i] >= SCREEN_WIDTH - ALIEN1_WIDTH) ||
                            (!alien_direction && alien_x[i] <= 2)) begin
                            alien_direction <= !alien_direction;
                            alien_y[i] <= alien_y[i] + ALIEN_DROP_DISTANCE;
                        end

                        // Check for reaching bottom
                        if (alien_y[i] + ALIEN1_HEIGHT >= (ship_y - 50))
                            game_over <= 1;
                    end
                end
            end else begin
                alien_move_counter <= alien_move_counter + 1;
            end

            // Alien shooting logic
            if (!laser_active && shooting_alien < NUM_ALIENS) begin
                if (alien_alive[shooting_alien]) begin
                    reg clear_path;
                    clear_path = 1;
                    
                    // Check for clear path
                    for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                        if (alien_alive[i] && i != shooting_alien &&
                            alien_y[i] > alien_y[shooting_alien] &&
                            alien_x[i] + ALIEN1_WIDTH > alien_x[shooting_alien] &&
                            alien_x[i] < alien_x[shooting_alien] + ALIEN1_WIDTH) begin
                            clear_path = 0;
                        end
                    end

                    // Initiate laser if path is clear
                    if (clear_path && random_bit) begin  // Added randomness
                        laser_active <= 1;
                        laser_x <= alien_x[shooting_alien] + ALIEN1_WIDTH/2;
                        laser_y <= alien_y[shooting_alien] + ALIEN1_HEIGHT;
                    end
                end
                shooting_alien <= shooting_alien + 1;
            end else if (!laser_active) begin
                shooting_alien <= 0;
            end

            // Laser movement and collision
            if (laser_active) begin
                laser_y <= laser_y + LASER_SPEED;
                if (laser_y >= SCREEN_HEIGHT)
                    laser_active <= 0;

                // Check collision with ship
                if (laser_x < ship_x + SHIP_WIDTH &&
                    laser_x + LASER_WIDTH > ship_x &&
                    laser_y < ship_y + SHIP_HEIGHT &&
                    laser_y + LASER_HEIGHT > ship_y) begin
                    lives_reg <= lives_reg - 1;
                    ship_explosion_timer <= EXPLOSION_DURATION;
                    laser_active <= 0;
                    if (lives_reg == 1)
                        game_over <= 1;
                end
            end

            // Update timers
            if (ship_explosion_timer > 0)
                ship_explosion_timer <= ship_explosion_timer - 1;

            for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                if (alien_explosion_timer[i] > 0)
                    alien_explosion_timer[i] <= alien_explosion_timer[i] - 1;
            end

            // Game-ending condition checks
            if (aliens_destroyed == NUM_ALIENS)
                game_win <= 1;
            
            // Ensure game over if no lives left
            if (lives_reg == 0)
                game_over <= 1;
        end
    end
end
    // Display logic
    always @(posedge clk) begin
        // Default background
        element_type <= 3'b100;

        case (game_state)
            2'b00: screen_addr <= START_SCREEN_START + (y * SCREEN_WIDTH + x);
            2'b01: screen_addr <= MAIN_SCREEN_START + (y * SCREEN_WIDTH + x);
            2'b10: screen_addr <= WIN_SCREEN_START + (y * SCREEN_WIDTH + x);
            2'b11: screen_addr <= LOSE_SCREEN_START + (y * SCREEN_WIDTH + x);
        endcase

        if (game_state == MAIN_SCREEN) begin
            // Draw score bar
            if (y < 20 && x < 160) begin
                element_type <= 3'b010;
                element_addr <= x + y * 160;
            end

            // Draw lives
            if (y < LIFE_HEIGHT && x >= SCREEN_WIDTH - 100) begin
                for (i = 0; i < lives_reg; i = i + 1) begin
                    if (x >= SCREEN_WIDTH - 90 + i*(LIFE_WIDTH + 2) && x < SCREEN_WIDTH - 90 + i*(LIFE_WIDTH + 2) + LIFE_WIDTH) begin
                        element_type <= 3'b011;
                        element_addr <= LIFE_START + (y * LIFE_WIDTH + (x - (SCREEN_WIDTH - 90 + i*(LIFE_WIDTH + 2))));
                    end
                end
            end

            // Draw ship
            if (x >= ship_x && x < ship_x + SHIP_WIDTH && y >= ship_y && y < ship_y + SHIP_HEIGHT) begin
                element_type <= 3'b000;
                if (ship_explosion_timer > 0) begin
                    element_addr <= SHIP_EXPLOSION_START + (y - ship_y) * SHIP_WIDTH + (x - ship_x);
                end else begin
                    element_addr <= SPACESHIP_START + (y - ship_y) * SHIP_WIDTH + (x - ship_x);
                end
            end

            // Draw aliens
            for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                if (alien_alive[i] || alien_explosion_timer[i] > 0) begin
                    if (x >= alien_x[i] && x < alien_x[i] + ALIEN1_WIDTH) begin
                        case (alien_type[i])
                            2'b00: begin // Type 1
                                if (y >= alien_y[i] && y < alien_y[i] + ALIEN1_HEIGHT) begin
                                    element_type <= 3'b000;
                                    if (alien_explosion_timer[i] > 0)
                                        element_addr <= ALIEN_EXPLOSION_START + (y - alien_y[i]) * ALIEN1_WIDTH + (x - alien_x[i]);
                                    else
                                        element_addr <= (frame[0] ? ALIEN_1_2_START : ALIEN_1_1_START) + (y - alien_y[i]) * ALIEN1_WIDTH + (x - alien_x[i]);
                                end
                            end
                            2'b01: begin // Type 2
                                if (y >= alien_y[i] && y < alien_y[i] + ALIEN2_HEIGHT) begin
                                    element_type <= 3'b000;
                                    if (alien_explosion_timer[i] > 0)
                                        element_addr <= ALIEN_EXPLOSION_START + (y - alien_y[i]) * ALIEN1_WIDTH + (x - alien_x[i]);
                                    else
                                        element_addr <= (frame[0] ? ALIEN_2_2_START : ALIEN_2_1_START) + (y - alien_y[i]) * ALIEN2_WIDTH + (x - alien_x[i]);
                                end
                            end
                            2'b10: begin // Type 3
                                if (y >= alien_y[i] && y < alien_y[i] + ALIEN3_HEIGHT) begin
                                    element_type <= 3'b000;
                                    if (alien_explosion_timer[i] > 0)
                                        element_addr <= ALIEN_EXPLOSION_START + (y - alien_y[i]) * ALIEN1_WIDTH + (x - alien_x[i]);
                                    else
                                        element_addr <= (frame[0] ? ALIEN_3_2_START : ALIEN_3_1_START) + (y - alien_y[i]) * ALIEN3_WIDTH + (x - alien_x[i]);
                                end
                            end
                        endcase
                    end
                end
            end

            // Draw projectiles
            if (rocket_active && x >= rocket_x && x < rocket_x + ROCKET_WIDTH && y >= rocket_y && y < rocket_y + ROCKET_HEIGHT) begin
                element_type <= 3'b001;
                element_addr <= (ROCKET_1_START + projectile_frame_counter * (ROCKET_WIDTH * ROCKET_HEIGHT)) + (y - rocket_y) * ROCKET_WIDTH + (x - rocket_x);
            end
            if (laser_active && x >= laser_x && x < laser_x + LASER_WIDTH && y >= laser_y && y < laser_y + LASER_HEIGHT) begin
                element_type <= 3'b001;
                element_addr <= (LASER_1_START + projectile_frame_counter * (LASER_WIDTH * LASER_HEIGHT)) + (y - laser_y) * LASER_WIDTH + (x - laser_x);
            end
        end
    end

    // Output assignments
    always @(posedge clk) begin
        score <= score_reg;
        high_score <= high_score_reg;
    end

endmodule