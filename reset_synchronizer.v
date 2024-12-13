module reset_synchronizer (
    input clk,
    input async_reset,    // Asynchronous reset input (active high)
    output reg sync_reset // Synchronized reset output
);
    // Two-stage synchronizer with additional filtering
    reg [2:0] meta_stages;
    
    always @(posedge clk or posedge async_reset) begin
        if (async_reset) begin
            // Asynchronous reset sets all stages
            meta_stages <= 3'b111;
            sync_reset <= 1'b1;
        end else begin
            // Synchronous shift register with majority voting
            meta_stages <= {meta_stages[1:0], async_reset};
            sync_reset <= (meta_stages[2] & meta_stages[1]) | 
                         (meta_stages[1] & meta_stages[0]) | 
                         (meta_stages[2] & meta_stages[0]);
        end
    end
endmodule