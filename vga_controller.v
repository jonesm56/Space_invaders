// VGA Controller
module vga_controller (
    input wire pixel_clk,
    input wire reset,
    output reg hsync,
    output reg vsync,
    output reg [9:0] x,
    output reg [9:0] y,
    output reg display_on,
    output reg frame_tick
);
    // Timing parameters for 640x480 @60Hz
    parameter H_DISPLAY = 640;
    parameter H_FRONT = 16;
    parameter H_SYNC = 96;
    parameter H_BACK = 48;
    parameter H_TOTAL = 800;
    
    parameter V_DISPLAY = 480;
    parameter V_FRONT = 10;
    parameter V_SYNC = 2;
    parameter V_BACK = 33;
    parameter V_TOTAL = 525;
    
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
            hsync <= 1;
            vsync <= 1;
            x <= 0;
            y <= 0;
            display_on <= 0;
            frame_tick <= 0;
        end else begin
            // Horizontal counter
            if (h_count < H_TOTAL - 1)
                h_count <= h_count + 1;
            else begin
                h_count <= 0;
                if (v_count < V_TOTAL - 1)
                    v_count <= v_count + 1;
                else
                    v_count <= 0;
            end
            
            // Generate sync signals
            hsync <= ~((h_count >= H_DISPLAY + H_FRONT) && 
                      (h_count < H_DISPLAY + H_FRONT + H_SYNC));
            vsync <= ~((v_count >= V_DISPLAY + V_FRONT) && 
                      (v_count < V_DISPLAY + V_FRONT + V_SYNC));
            
            // Generate coordinates and display_on
            if (h_count < H_DISPLAY)
                x <= h_count;
            if (v_count < V_DISPLAY)
                y <= v_count;
                
            display_on <= (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
            
            // Generate frame tick
            frame_tick <= (h_count == 0) && (v_count == 0);
        end
    end
endmodule