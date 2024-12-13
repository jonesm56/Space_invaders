module debounce (
    input clk,
    input reset,
    input btn_in,
    output reg btn_out
);

    // Parameters for debounce timing
    parameter DEBOUNCE_LIMIT = 20'hFFFFF;
    
    reg [19:0] counter;
    reg btn_prev;
    reg [3:0] shift_reg;
    reg stable;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            btn_out <= 0;
            btn_prev <= 0;
            shift_reg <= 4'b0000;
            stable <= 0;
        end else begin
            // Sample input into shift register
            shift_reg <= {shift_reg[2:0], btn_in};
            
            // Check for input change
            if (btn_prev != btn_in) begin
                counter <= 20'd0;
                btn_prev <= btn_in;
                stable <= 0;
            end else begin
                if (!stable && counter < DEBOUNCE_LIMIT) begin
                    counter <= counter + 1;
                end else begin
                    stable <= 1;
                    // Check shift register for consistent value
                    if (shift_reg == 4'b1111) begin
                        btn_out <= 1'b1;
                    end else if (shift_reg == 4'b0000) begin
                        btn_out <= 1'b0;
                    end
                end
            end
        end
    end

endmodule