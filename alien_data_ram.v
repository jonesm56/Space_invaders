module alien_data_ram (
    input wire game_clk,          // Game logic clock domain
    input wire pixel_clk,         // Pixel clock domain
    input wire reset,
    // Game logic interface
    input wire [4:0] game_addr,
    input wire game_write_en,
    input wire [27:0] game_data_in,
    output reg [27:0] game_data_out,
    // Display interface
    input wire [4:0] display_addr,
    output reg [27:0] display_data_out,
    // Status signals
    output reg write_busy,
    output reg read_valid
);

    // Parameters
    parameter NUM_ALIENS = 18;
    parameter ALIEN_COLS = 6;
    parameter ALIEN_ROWS = 3;
    
    // Dual-port RAM
    reg [27:0] alien_data [0:NUM_ALIENS-1];
    
    // Write/read status tracking
    reg [2:0] write_state;
    reg [2:0] read_state;
    reg write_pending;
    reg read_pending;
    
    // Clock domain crossing
    reg [2:0] sync_write;
    reg [2:0] sync_read;
    
    // State definitions
    parameter IDLE = 3'd0;
    parameter WRITING = 3'd1;
    parameter READING = 3'd2;
    parameter SYNC_WAIT = 3'd3;
    parameter COMPLETE = 3'd4;
    
    // Initialize alien positions
    integer i;
    
    always @(posedge game_clk) begin
        if (reset) begin
            for (i = 0; i < NUM_ALIENS; i = i + 1) begin
                alien_data[i] <= {
                    10'd50 + ((i % ALIEN_COLS) * 40),  // x position
                    10'd50 + ((i / ALIEN_COLS) * 35),  // y position
                    2'b00,                             // type based on row
                    1'b1,                              // alive flag
                    5'd0                               // explosion timer
                };
            end
            write_state <= IDLE;
            write_busy <= 0;
            write_pending <= 0;
            sync_write <= 0;
        end else begin
            case (write_state)
                IDLE: begin
                    if (game_write_en && !write_busy) begin
                        write_state <= WRITING;
                        write_busy <= 1;
                        write_pending <= 1;
                    end
                end
                
                WRITING: begin
                    alien_data[game_addr] <= game_data_in;
                    write_state <= SYNC_WAIT;
                    sync_write <= sync_write + 1;
                end
                
                SYNC_WAIT: begin
                    if (sync_read == sync_write) begin
                        write_state <= COMPLETE;
                        write_pending <= 0;
                    end
                end
                
                COMPLETE: begin
                    write_busy <= 0;
                    write_state <= IDLE;
                end
                
                default: write_state <= IDLE;
            endcase
            
            // Read operation for game logic
            game_data_out <= alien_data[game_addr];
        end
    end
    
    // Display port (read-only)
    always @(posedge pixel_clk) begin
        if (reset) begin
            display_data_out <= 0;
            read_state <= IDLE;
            read_valid <= 0;
            read_pending <= 0;
            sync_read <= 0;
        end else begin
            case (read_state)
                IDLE: begin
                    if (!read_valid) begin
                        read_state <= READING;
                        read_pending <= 1;
                    end
                end
                
                READING: begin
                    display_data_out <= alien_data[display_addr];
                    read_state <= SYNC_WAIT;
                    sync_read <= sync_read + 1;
                end
                
                SYNC_WAIT: begin
                    if (sync_write == sync_read) begin
                        read_state <= COMPLETE;
                        read_pending <= 0;
                        read_valid <= 1;
                    end
                end
                
                COMPLETE: begin
                    read_state <= IDLE;
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end

endmodule