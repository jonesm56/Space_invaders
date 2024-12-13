module seg7_display (
    input      [3:0] bin,    // 4-bit binary input
    output reg [6:0] seg     // 7-segment display output (active low)
);

    // 7-segment encoding for DE1-SoC:
    // seg = 6543210
    //       gfedcba
    //        666
    //       5   4
    //       5   4
    //        333
    //       2   1
    //       2   1
    //        000

    always @(*) begin
        case (bin)
            //              gfedcba
            4'h0: seg = 7'b1000000;  // 0
            4'h1: seg = 7'b1111001;  // 1
            4'h2: seg = 7'b0100100;  // 2
            4'h3: seg = 7'b0110000;  // 3
            4'h4: seg = 7'b0011001;  // 4
            4'h5: seg = 7'b0010010;  // 5
            4'h6: seg = 7'b0000010;  // 6
            4'h7: seg = 7'b1111000;  // 7
            4'h8: seg = 7'b0000000;  // 8
            4'h9: seg = 7'b0010000;  // 9
            4'ha: seg = 7'b0001000;  // A
            4'hb: seg = 7'b0000011;  // b
            4'hc: seg = 7'b1000110;  // C
            4'hd: seg = 7'b0100001;  // d
            4'he: seg = 7'b0000110;  // E
            4'hf: seg = 7'b0001110;  // F
            default: seg = 7'b1111111; // All segments off
        endcase
    end

endmodule