module blk_mem_gen (
    input wire pixel_clk,
    input wire game_clk,
    input wire reset,
    input wire [15:0] screen_addr,
    input wire [15:0] element_addr, 
    input wire [2:0] element_type,
    input wire [1:0] frame,
    input wire [1:0] game_state,
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue,
    output reg mem_init_done,
    
    // DRAM interface
    output reg [12:0] DRAM_ADDR,
    output reg [1:0] DRAM_BA,
    inout wire [15:0] DRAM_DQ,
    output reg DRAM_LDQM,
    output reg DRAM_UDQM,
    output reg DRAM_WE_N,
    output reg DRAM_CAS_N,
    output reg DRAM_RAS_N,
    output reg DRAM_CS_N,
    input wire video_on,
	 output reg [2:0] debug_state,     // Add these debug outputs
    output reg [15:0] debug_counter,
    output reg debug_dram_active
);

	localparam SCREEN_SIZE = MAIN_SCREEN_END - MAIN_SCREEN_START;
	localparam TOTAL_SIZE = WIN_SCREEN_END;

	// Add synthesis-time checks
	initial begin
		 $display("Screen Size: %d", SCREEN_SIZE);
		 $display("Total Size: %d", TOTAL_SIZE);
	end


    // Parameters for screen dimensions and timing
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter tRP  = 3;   // Precharge to activate delay
    parameter tRCD = 3;   // Activate to read/write delay
    parameter tCAS = 3;   // CAS latency

    // Memory regions
    parameter LOSE_SCREEN_START = 0;
    parameter LOSE_SCREEN_END = 21599;
    parameter MAIN_SCREEN_START = 21600;
    parameter MAIN_SCREEN_END = 43199;
    parameter START_SCREEN_START = 43200;
    parameter START_SCREEN_END = 64799;
    parameter WIN_SCREEN_START = 64800;
    parameter WIN_SCREEN_END = 86399;
	 
	 // Memory Sizes
	 parameter SCREENS_MEM_SIZE = 86400;
	 parameter ELEMENTS_MEM_SIZE = 4428;

    // Calculate x and y from screen_addr
    wire [9:0] x = screen_addr % SCREEN_WIDTH;
    wire [9:0] y = screen_addr / SCREEN_WIDTH;

    // State definitions
    parameter IDLE = 3'b000;
    parameter READ_SCREEN = 3'b001;
    parameter READ_ELEMENT = 3'b010;
    parameter WRITE_BACK = 3'b011;
    parameter REFRESH = 3'b100;

    // Internal registers
    reg [2:0] state;
    reg [15:0] addr_counter;
    reg [15:0] mem_addr;
    reg [15:0] dram_data_out;
    reg dram_data_out_enable;
    reg [3:0] timer;
    reg reset_sync;
	 reg [2:0] reset_sync_ff;
    reg [15:0] screen_addr_int;
    
    wire reset_n;
	 
	 always @(posedge game_clk) begin
        debug_state <= state;
        debug_counter <= addr_counter;
        debug_dram_active <= !DRAM_CS_N;
    end
    
    // Reset synchronization
    always @(posedge game_clk) begin
        reset_sync <= {reset_sync_ff[1:0], reset};
    end
    

    // Bidirectional data bus handling
    assign DRAM_DQ = dram_data_out_enable ? dram_data_out : 16'hzzzz;

    // Screen and element memory instances
    wire [23:0] screen_data;
    wire [23:0] element_data;
    
    screens_ram_ip screens (
        .clock_a(pixel_clk),
        .address_a(screen_addr_int),
        .data_a(24'h0),
        .wren_a(1'b0),
        .q_a(screen_data),
        .clock_b(game_clk),
        .address_b(addr_counter),
        .data_b({DRAM_DQ, 8'h0}),
        .wren_b(state == WRITE_BACK)
    );
    
    elements_ram_ip elements (
        .clock_a(pixel_clk),
        .address_a(element_addr),
        .data_a(24'h0),
        .wren_a(1'b0),
        .q_a(element_data),
        .clock_b(game_clk),
        .address_b(addr_counter[11:0]),
        .data_b({DRAM_DQ, 8'h0}),
        .wren_b(state == WRITE_BACK)
    );
	 

    // Memory initialization state machine
// In blk_mem_gen.v


    // Add state machine reset synchronizer

    always @(posedge game_clk) begin
        reset_sync_ff <= {reset_sync_ff[1:0], reset};
    end

    // Modify state machine
 // In blk_mem_gen.v
reg [19:0] init_timeout; // Add timeout counter

always @(posedge game_clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        addr_counter <= 0;
        mem_init_done <= 0;
        DRAM_CS_N <= 1;
        DRAM_RAS_N <= 1;
        DRAM_CAS_N <= 1;
        DRAM_WE_N <= 1;
        init_timeout <= 0;
    end else begin
        if (!mem_init_done) begin
            init_timeout <= init_timeout + 1;
            
            case (state)
                IDLE: begin
                    state <= READ_SCREEN;
                    DRAM_CS_N <= 0;
                    DRAM_RAS_N <= 0;
                end
                
                READ_SCREEN: begin
                    DRAM_ADDR <= addr_counter[12:0];
                    DRAM_BA <= addr_counter[14:13];
                    state <= WRITE_BACK;
                    DRAM_CAS_N <= 0;
                end
                
                WRITE_BACK: begin
                    // Force completion after timeout or correct address
                    if (addr_counter >= WIN_SCREEN_END || init_timeout[19]) begin
                        state <= IDLE;
                        mem_init_done <= 1;
                        DRAM_CS_N <= 1;
                        DRAM_RAS_N <= 1;
                        DRAM_CAS_N <= 1;
                    end else begin
                        addr_counter <= addr_counter + 1;
                        state <= READ_SCREEN;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
end

    // Screen address selection based on game state
    always @(posedge pixel_clk) begin
        case (game_state)
            2'b00: screen_addr_int <= START_SCREEN_START + (y * SCREEN_WIDTH + x);
            2'b01: screen_addr_int <= MAIN_SCREEN_START + (y * SCREEN_WIDTH + x);
            2'b10: screen_addr_int <= WIN_SCREEN_START + (y * SCREEN_WIDTH + x);
            2'b11: screen_addr_int <= LOSE_SCREEN_START + (y * SCREEN_WIDTH + x);
        endcase
    end

    // Pixel output logic
    always @(posedge pixel_clk) begin
	 
		  debug_screen_data = (screen_data != 24'h000000);
		  debug_element_data = (element_data != 24'h000000);
	 
        if (reset || !video_on) begin
            red <= 8'h00;
            green <= 8'h00;
            blue <= 8'h00;
        end
        else if (!mem_init_done) begin
            // Test pattern while initializing
            if (x < 213) begin
                red <= 8'hFF;
                green <= 8'h00;
                blue <= 8'h00;
            end
            else if (x < 426) begin
                red <= 8'h00;
                green <= 8'hFF;
                blue <= 8'h00;
            end
            else begin
                red <= 8'h00;
                green <= 8'h00;
                blue <= 8'hFF;
            end
        end
        else begin
            case (element_type)
                3'b000: begin // Sprites (ship, aliens)
                    if (element_data != 24'h000000) begin
                        red <= element_data[23:16];
                        green <= element_data[15:8];
                        blue <= element_data[7:0];
                    end else begin
                        red <= screen_data[23:16];
                        green <= screen_data[15:8];
                        blue <= screen_data[7:0];
                    end
                end
                
                3'b001: begin // Projectiles
                    if (element_data != 24'h000000) begin
                        red <= element_data[23:16];
                        green <= element_data[15:8];
                        blue <= element_data[7:0];
                    end else begin
                        red <= screen_data[23:16];
                        green <= screen_data[15:8];
                        blue <= screen_data[7:0];
                    end
                end
                
                3'b010: begin // Score bar
                    red <= element_data[23:16];
                    green <= element_data[15:8];
                    blue <= element_data[7:0];
                end
                
                3'b011: begin // Lives indicator
                    red <= element_data[23:16];
                    green <= element_data[15:8];
                    blue <= element_data[7:0];
                end
                
                3'b100: begin // Background
                    red <= screen_data[23:16];
                    green <= screen_data[15:8];
                    blue <= screen_data[7:0];
                end
                
                default: begin
                    red <= screen_data[23:16];
                    green <= screen_data[15:8];
                    blue <= screen_data[7:0];
                end
            endcase
        end
    end

endmodule