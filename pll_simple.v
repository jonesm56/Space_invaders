module pll_simple (
    input wire refclk,
    input wire rst,
    output wire outclk_0,  // 25MHz for VGA
    output wire outclk_1,  // 50MHz for game logic
    output wire locked
);
    reg [0:0] clk_div;
    reg [2:0] lock_counter;
    
    // Clock divider for 25MHz
    always @(posedge refclk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
            lock_counter <= 0;
        end else begin
            clk_div <= ~clk_div;
            if (lock_counter < 3'b111)
                lock_counter <= lock_counter + 1;
        end
    end
    
    assign outclk_0 = clk_div;        // 25MHz
    assign outclk_1 = refclk;         // 50MHz
    assign locked = &lock_counter;     // Locked after 8 cycles
endmodule
