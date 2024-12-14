// Button Debouncer
module debounce (
    input wire clk,
    input wire reset,
    input wire btn_in,
    output reg btn_out
);
    parameter DEBOUNCE_LIMIT = 20'd50000;  // 1ms at 50MHz
    
    reg [19:0] counter;
    reg btn_prev;
    reg [2:0] btn_sync;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            btn_out <= 0;
            btn_prev <= 0;
            btn_sync <= 3'b000;
        end else begin
            btn_sync <= {btn_sync[1:0], btn_in};
            
            if (btn_prev != btn_sync[2]) begin
                counter <= 20'd0;
                btn_prev <= btn_sync[2];
            end else if (counter < DEBOUNCE_LIMIT) begin
                counter <= counter + 1;
            end else begin
                btn_out <= btn_sync[2];
            end
        end
    end
endmodule