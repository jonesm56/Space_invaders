module clock_manager (
    input wire clk_50mhz,      // 50MHz input clock
    input wire reset,
    output wire pixel_clk,     // 25MHz for VGA
    output wire game_clk,      // 100MHz game logic clock
    output wire mem_clk,       // Memory clock
    output reg pixel_locked,   // PLL lock indicators
    output reg game_locked,
    output reg mem_locked
);

    // Internal signals
    wire pll_locked;
    reg [3:0] lock_count;
    
    // Clock crossing signals
    reg [2:0] lock_sync;   // Single synchronization register
    
    // PLL instance
    pll_main pll (
        .refclk(clk_50mhz),
        .rst(reset),
        .outclk_0(pixel_clk),    // 25MHz
        .outclk_1(game_clk),     // 100MHz
        .outclk_2(mem_clk),      // 100MHz with phase shift
        .locked(pll_locked)
    );
    
    // Lock detection and synchronization
    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            lock_count <= 0;
            pixel_locked <= 0;
            game_locked <= 0;
            mem_locked <= 0;
            lock_sync <= 3'b000;
        end else begin
            lock_sync <= {lock_sync[1:0], pll_locked};
            
            if (&lock_sync) begin
                if (lock_count < 4'hF)
                    lock_count <= lock_count + 1;
                else begin
                    pixel_locked <= 1;
                    game_locked <= 1;
                    mem_locked <= 1;
                end
            end else begin
                lock_count <= 0;
                pixel_locked <= 0;
                game_locked <= 0;
                mem_locked <= 0;
            end
        end
    end

endmodule