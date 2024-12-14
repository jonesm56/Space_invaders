// Character ROM for text display
module char_rom (
    input wire [7:0] char_code,
    input wire [3:0] row,
    output reg [7:0] row_data
);
    reg [7:0] char_array [0:4095];  // 256 characters * 16 rows
    
    initial begin
        // Load character patterns - example for key characters
        // Space
        char_array[32*16+0]  = 8'b00000000;
        char_array[32*16+1]  = 8'b00000000;
        char_array[32*16+2]  = 8'b00000000;
        char_array[32*16+3]  = 8'b00000000;
        char_array[32*16+4]  = 8'b00000000;
        char_array[32*16+5]  = 8'b00000000;
        char_array[32*16+6]  = 8'b00000000;
        char_array[32*16+7]  = 8'b00000000;
        
        // Letter A
        char_array[65*16+0]  = 8'b00111100;
        char_array[65*16+1]  = 8'b01100110;
        char_array[65*16+2]  = 8'b01100110;
        char_array[65*16+3]  = 8'b01111110;
        char_array[65*16+4]  = 8'b01100110;
        char_array[65*16+5]  = 8'b01100110;
        char_array[65*16+6]  = 8'b01100110;
        char_array[65*16+7]  = 8'b00000000;
        
        // Additional characters...
        // (Add patterns for other needed characters)
    end
    
    always @* begin
        row_data = char_array[char_code * 16 + row];
    end
endmodule