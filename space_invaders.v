module space_invaders (
    // Clock and Reset
    input              CLOCK_50,
    input       [3:0]  KEY,          // Active LOW push buttons
    input       [9:0]  SW,           // Switches
    
    // VGA
    output            VGA_CLK,
    output            VGA_HS,
    output            VGA_VS,
    output            VGA_BLANK_N,
    output            VGA_SYNC_N,
    output     [7:0]  VGA_R,
    output     [7:0]  VGA_G,
    output     [7:0]  VGA_B,
    
    // SDRAM Interface
    output     [12:0] DRAM_ADDR,
    output     [1:0]  DRAM_BA,
    output            DRAM_CAS_N,
    output            DRAM_CKE,
    output            DRAM_CS_N,
    inout      [15:0] DRAM_DQ,
    output     [1:0]  DRAM_DQM,
    output            DRAM_RAS_N,
    output            DRAM_WE_N,
    output            DRAM_CLK,
    
    // LED Indicators
    output      [9:0] LEDR,         // Red LEDs
    
    // 7-Segment Displays
    output      [6:0] HEX0,
    output      [6:0] HEX1,
    output      [6:0] HEX2,
    output      [6:0] HEX3,
    output      [6:0] HEX4,
    output      [6:0] HEX5
);

    // Button mapping (active LOW to active HIGH conversion)
    wire reset = ~SW[0];           // Reset button
    wire start_button = ~KEY[3];    // Start button
    wire fire_button = ~KEY[2];     // Fire button
    wire right_button = ~KEY[0];    // Right movement
    wire left_button = ~KEY[1];       // Left movement using SW[0] since we're out of keys
	 
	 // VGA
    reg [7:0] vga_r_reg, vga_g_reg, vga_b_reg;
    reg [7:0] vga_r, vga_g, vga_b; // Add these declarations
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;
    wire [7:0] vga_red;
    wire [7:0] vga_green;
    wire [7:0] vga_blue;
    
    // Clock domains
    wire pixel_clk;    // 25MHz for VGA
    wire game_clk;     // 100MHz for game logic
    wire mem_clk;      // Memory clock
    wire pixel_locked;
    wire game_locked;
    wire mem_locked;

    // Game state signals
    wire [1:0] game_state;
    wire game_reset;
    wire [7:0] score;
    wire [7:0] high_score;
    wire game_over;
    wire game_win;
    wire mem_init_done;

    // VGA signals
    wire [9:0] pixel_x, pixel_y;
    wire video_on;
    wire frame_tick;
    wire [15:0] screen_addr;
    wire [15:0] element_addr;
    wire [2:0] element_type;
    wire [1:0] frame;

    // Debounced button signals
    wire start_btn, fire_btn, left_btn, right_btn;
	 
	 wire hsync_from_ctrl, vsync_from_ctrl;
	 
	 // In space_invaders.v
	reg [2:0] init_state;
	reg mem_ready;
	reg [2:0] mem_init_sync;
	reg mem_init_stable;
	reg vga_blank_n;
	reg vga_hsync, vga_vsync;
	
	always @(posedge pixel_clk) begin
		 if (reset)
			  vga_blank_n <= 1'b0;
		 else
			  vga_blank_n <= video_on && mem_ready;
	end

	assign VGA_BLANK_N = vga_blank_n;


	always @(posedge game_clk or posedge reset) begin
		 if (reset) begin
			  init_state <= 0;
			  mem_init_sync <= 3'b000;
			  mem_init_stable <= 1'b0;
		 end else begin
			  // Synchronize mem_init_done across clock domains
			  mem_init_sync <= {mem_init_sync[1:0], mem_init_done};
			  mem_init_stable <= &mem_init_sync;
			  
			  case (init_state)
					0: if (mem_locked) init_state <= 1;
					1: if (mem_init_stable) init_state <= 2;
					default: init_state <= init_state;
			  endcase
		 end
	end
	
	always @(posedge game_clk or posedge reset) begin
    if (reset) begin
        mem_ready <= 0;
    end else if (mem_init_done || pixel_locked) begin // Change condition
        mem_ready <= 1;
    end
end

	 

    // Reset synchronization
    wire sync_reset;
    reset_synchronizer reset_sync (
        .clk(CLOCK_50),
        .async_reset(reset),
        .sync_reset(sync_reset)
    );

    // Clock management
    clock_manager clk_mgr (
        .clk_50mhz(CLOCK_50),
        .reset(sync_reset),
        .pixel_clk(pixel_clk),
        .game_clk(game_clk),
        .mem_clk(mem_clk),
        .pixel_locked(pixel_locked),
        .game_locked(game_locked),
        .mem_locked(mem_locked)
    );

    // Button debouncers
    debounce start_debounce (
        .clk(game_clk),
        .reset(sync_reset),
        .btn_in(start_button),
        .btn_out(start_btn)
    );

    debounce fire_debounce (
        .clk(game_clk),
        .reset(sync_reset),
        .btn_in(fire_button),
        .btn_out(fire_btn)
    );

    debounce left_debounce (
        .clk(game_clk),
        .reset(sync_reset),
        .btn_in(left_button),
        .btn_out(left_btn)
    );

    debounce right_debounce (
        .clk(game_clk),
        .reset(sync_reset),
        .btn_in(right_button),
        .btn_out(right_btn)
    );

    // Game FSM controller
    game_fsm game_controller (
        .clk(game_clk),
        .reset(sync_reset || !mem_ready),
        .start_button(start_btn),
        .fire_button(fire_btn),
        .game_win(game_win),
        .game_over(game_over),
        .game_state(game_state),
        .game_reset(game_reset)
		  );

    // VGA controller
    vga_controller vga_ctrl (
        .pixel_clk(pixel_clk),
        .reset(sync_reset || !mem_ready),
        .hsync(hsync_from_ctrl),
        .vsync(vsync_from_ctrl),
        .x(pixel_x),
        .y(pixel_y),
        .display_on(video_on),
        .frame_tick(frame_tick),
    );

    // Game logic
    game_logic game_logic_inst (
        .clk(game_clk),
        .reset(sync_reset || game_reset || !mem_ready),
        .fire(fire_btn),
        .left(left_btn),
        .right(right_btn),
        .x(pixel_x),
        .y(pixel_y),
        .game_state(game_state),
        .game_over(game_over),
        .game_win(game_win),
        .red(red),
        .green(green),
        .blue(blue),
        .score(score),
        .high_score(high_score),
        .screen_addr(screen_addr),
        .element_addr(element_addr),
        .element_type(element_type),
        .frame(frame)
    );

	 wire [2:0] debug_state;
    wire [15:0] debug_counter;
    wire debug_dram_active;
	 
    // Block memory interface
	blk_mem_gen mem_interface (
		 .pixel_clk(pixel_clk),
		 .game_clk(game_clk),
		 .reset(sync_reset || !mem_locked),
		 .screen_addr(screen_addr),
		 .element_addr(element_addr),
		 .element_type(element_type),
		 .frame(frame),
		 .red(vga_red),
		 .green(vga_green),
		 .blue(vga_blue),
		 .mem_init_done(mem_init_done),
		 .DRAM_ADDR(DRAM_ADDR),
		 .DRAM_BA(DRAM_BA),
		 .DRAM_DQ(DRAM_DQ),
		 .DRAM_LDQM(DRAM_DQM[0]),
		 .DRAM_UDQM(DRAM_DQM[1]),
		 .DRAM_WE_N(DRAM_WE_N),
		 .DRAM_CAS_N(DRAM_CAS_N),
		 .DRAM_RAS_N(DRAM_RAS_N),
		 .DRAM_CS_N(DRAM_CS_N),
		 .video_on(video_on),
		 .game_state(game_state),
		  .debug_state(debug_state),
        .debug_counter(debug_counter),
        .debug_dram_active(debug_dram_active)
	);
		 

    // Score display on 7-segment displays
    seg7_display score_display_low (
        .bin(score[3:0]),
        .seg(HEX0)
    );

    seg7_display score_display_high (
        .bin(score[7:4]),
        .seg(HEX1)
    );

    seg7_display high_score_display_low (
        .bin(high_score[3:0]),
        .seg(HEX2)
    );

    seg7_display high_score_display_high (
        .bin(high_score[7:4]),
        .seg(HEX3)
    );
	 
	 wire init_done = mem_init_done;

    // Status display on HEX4-5
    assign HEX4 = (game_state == 2'b00) ? 7'b1000000 : // "0" for START
                  (game_state == 2'b01) ? 7'b1111001 : // "1" for MAIN
                  (game_state == 2'b10) ? 7'b0100100 : // "2" for WIN
                                        7'b0110000;  // "3" for LOSE
    assign HEX5 = 7'b1111111; // OFF

    // LED indicators
	assign LEDR[2:0] = game_state;              
	assign LEDR[3] = debug_dram_active;     
	assign LEDR[4] = mem_init_done;        
	assign LEDR[5] = pixel_locked;         
	assign LEDR[6] = game_locked;          
	assign LEDR[7] = debug_screen_data;    // Changed to show if screen data is non-zero
	assign LEDR[8] = debug_element_data;   // Changed to show if element data is non-zero
	assign LEDR[9] = mem_ready;

    // VGA clock and sync assignments
    assign VGA_CLK = pixel_clk;
    assign VGA_SYNC_N = 1'b0;
    assign DRAM_CLK = mem_clk;
    assign DRAM_CKE = 1'b1;
	 
	always @(posedge pixel_clk) begin
		 if (reset) begin
			  vga_hsync <= 1'b1;
			  vga_vsync <= 1'b1;
			  vga_r <= 8'h00;
			  vga_g <= 8'h00;
			  vga_b <= 8'h00;
	    end else begin
        vga_hsync <= hsync_from_ctrl;
        vga_vsync <= vsync_from_ctrl;
        if (video_on && mem_ready) begin  // This condition might be the issue
            vga_r <= red;
            vga_g <= green;
            vga_b <= blue;
        end else begin
            vga_r <= 8'h00;
            vga_g <= 8'h00;
            vga_b <= 8'h00;
        end
		 end
	end
	
	// Assign final VGA outputs
	assign VGA_HS = vga_hsync;
	assign VGA_VS = vga_vsync;
	assign VGA_R = vga_r;
	assign VGA_G = vga_g;
	assign VGA_B = vga_b;
		 

endmodule