module sprite_rom (
    input wire [3:0] sprite_type,
    input wire [1:0] frame,
    input wire [5:0] row,
    output reg [31:0] row_data
);
    localparam SHIP = 4'd0;
    localparam ALIEN1 = 4'd1;
    localparam ALIEN2 = 4'd2;
    localparam ALIEN3 = 4'd3;
    localparam EXPLOSION = 4'd4;
    localparam ROCKET = 4'd5;
    
    reg [31:0] sprite_patterns [0:511];  // 16 sprites * 32 rows
    
    initial begin
        // Ship pattern (32x24 pixels, centered)
        sprite_patterns[0]  = 32'h00018000;
        sprite_patterns[1]  = 32'h0003C000;
        sprite_patterns[2]  = 32'h0003C000;
        sprite_patterns[3]  = 32'h0007E000;
        sprite_patterns[4]  = 32'h0007E000;
        sprite_patterns[5]  = 32'h000FF000;
        sprite_patterns[6]  = 32'h000FF000;
        sprite_patterns[7]  = 32'h001FF800;
        sprite_patterns[8]  = 32'h00FFFF00;
        sprite_patterns[9]  = 32'h00FFFF00;
        sprite_patterns[10] = 32'h0FFFFFF0;
        sprite_patterns[11] = 32'h0FFFFFF0;
        
        // Alien Type 1 - Frame 1 (16x16 pixels)
        sprite_patterns[32]  = 32'h00111100;
        sprite_patterns[33]  = 32'h01111110;
        sprite_patterns[34]  = 32'h11111111;
        sprite_patterns[35]  = 32'h11011011;
        sprite_patterns[36]  = 32'h11111111;
        sprite_patterns[37]  = 32'h00111100;
        sprite_patterns[38]  = 32'h01011010;
        sprite_patterns[39]  = 32'h10100101;

        // Alien Type 1 - Frame 2
        sprite_patterns[40]  = 32'h00111100;
        sprite_patterns[41]  = 32'h01111110;
        sprite_patterns[42]  = 32'h11111111;
        sprite_patterns[43]  = 32'h11011011;
        sprite_patterns[44]  = 32'h11111111;
        sprite_patterns[45]  = 32'h00111100;
        sprite_patterns[46]  = 32'h01100110;
        sprite_patterns[47]  = 32'h00100100;

        // Alien Type 2 - Frame 1
        sprite_patterns[64]  = 32'h00100100;
        sprite_patterns[65]  = 32'h00111100;
        sprite_patterns[66]  = 32'h01111110;
        sprite_patterns[67]  = 32'h11011011;
        sprite_patterns[68]  = 32'h11111111;
        sprite_patterns[69]  = 32'h00111100;
        sprite_patterns[70]  = 32'h01011010;
        sprite_patterns[71]  = 32'h10000001;

        // Alien Type 2 - Frame 2
        sprite_patterns[72]  = 32'h00100100;
        sprite_patterns[73]  = 32'h00111100;
        sprite_patterns[74]  = 32'h01111110;
        sprite_patterns[75]  = 32'h11011011;
        sprite_patterns[76]  = 32'h11111111;
        sprite_patterns[77]  = 32'h00111100;
        sprite_patterns[78]  = 32'h01100110;
        sprite_patterns[79]  = 32'h01000010;

        // Alien Type 3 - Frame 1
        sprite_patterns[96]  = 32'h00011000;
        sprite_patterns[97]  = 32'h01111110;
        sprite_patterns[98]  = 32'h11111111;
        sprite_patterns[99]  = 32'h11011011;
        sprite_patterns[100] = 32'h11111111;
        sprite_patterns[101] = 32'h00111100;
        sprite_patterns[102] = 32'h01011010;
        sprite_patterns[103] = 32'h01100110;

        // Alien Type 3 - Frame 2
        sprite_patterns[104] = 32'h00011000;
        sprite_patterns[105] = 32'h01111110;
        sprite_patterns[106] = 32'h11111111;
        sprite_patterns[107] = 32'h11011011;
        sprite_patterns[108] = 32'h11111111;
        sprite_patterns[109] = 32'h00111100;
        sprite_patterns[110] = 32'h01011010;
        sprite_patterns[111] = 32'h10100101;

        // Explosion pattern
        sprite_patterns[128] = 32'h10100101;
        sprite_patterns[129] = 32'h01011010;
        sprite_patterns[130] = 32'h10100101;
        sprite_patterns[131] = 32'h01011010;
        sprite_patterns[132] = 32'h10100101;
        sprite_patterns[133] = 32'h01011010;
        sprite_patterns[134] = 32'h10100101;
        sprite_patterns[135] = 32'h01011010;

        // Rocket pattern (8x12 pixels)
        sprite_patterns[160] = 32'h00FF0000;
        sprite_patterns[161] = 32'h00FF0000;
        sprite_patterns[162] = 32'h00FF0000;
        sprite_patterns[163] = 32'h00FF0000;
        sprite_patterns[164] = 32'h00FF0000;
        sprite_patterns[165] = 32'h00FF0000;
    end
    
    always @* begin
        case (sprite_type)
            SHIP: row_data = sprite_patterns[row[3:0]];
            ALIEN1: row_data = sprite_patterns[32 + {frame[0], row[3:0]}];
            ALIEN2: row_data = sprite_patterns[64 + {frame[0], row[3:0]}];
            ALIEN3: row_data = sprite_patterns[96 + {frame[0], row[3:0]}];
            EXPLOSION: row_data = sprite_patterns[128 + row[3:0]];
            ROCKET: row_data = sprite_patterns[160 + row[2:0]];
            default: row_data = 32'h0;
        endcase
    end
endmodule