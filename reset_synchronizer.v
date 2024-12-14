// Reset Synchronizer
module reset_synchronizer (
    input wire clk,
    input wire async_reset,
    output reg sync_reset
);
    reg [2:0] sync_stages;
    
    always @(posedge clk or posedge async_reset) begin
        if (async_reset) begin
            sync_stages <= 3'b111;
            sync_reset <= 1'b1;
        end else begin
            sync_stages <= {sync_stages[1:0], async_reset};
            sync_reset <= |sync_stages;
        end
    end
endmodule
