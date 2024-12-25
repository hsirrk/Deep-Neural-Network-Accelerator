module vga_avalon(input logic clk, input logic reset_n,
                  input logic [3:0] address,
                  input logic read, output logic [31:0] readdata,
                  input logic write, input logic [31:0] writedata,
                  output logic [7:0] vga_red, output logic [7:0] vga_grn, output logic [7:0] vga_blu,
                  output logic vga_hsync, output logic vga_vsync, output logic vga_clk);



    // your Avalon slave implementation goes here
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [7:0] vga_colour;
    logic vga_plot;

    logic [9:0] VGA_RED,VGA_GRN,VGA_BLU;
    logic VGA_HS,VGA_VS,VGA_BLANK,VGA_SYNC,VGA_CLK;
    assign vga_red = VGA_RED[9:2];
    assign vga_grn = VGA_GRN[9:2];
    assign vga_blu = VGA_BLU[9:2];
    assign vga_hsync=VGA_HS;
    assign vga_vsync=VGA_VS;
    assign vga_clk=VGA_CLK;
    assign vga_colour   = writedata[7:0];
    assign vga_x        = writedata[23:16];
    assign vga_y        = writedata[30:24];



    vga_adapter #( .RESOLUTION("160x120"), .MONOCHROME("TRUE"), .BITS_PER_COLOUR_CHANNEL(8) )
    vga (
        .resetn(reset_n),
        .clock(clk),
        .colour(vga_colour),
        .x(vga_x),
        .y(vga_y),
        .plot(vga_plot),
        .VGA_R(VGA_RED),
        .VGA_G(VGA_GRN),
        .VGA_B(VGA_BLU),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK(VGA_BLANK),
        .VGA_SYNC(VGA_SYNC),
        .VGA_CLK(VGA_CLK)
    );


    always_comb begin
        if (~reset_n) 
            vga_plot<=1'b0;
        else begin 
            if ((vga_x < 160 && vga_y<120) && address==4'b0 && write)
                vga_plot<=1'b1;
            else 
                vga_plot<=1'b0;
        end 
    end 

    // NOTE: We will ignore the VGA_SYNC and VGA_BLANK signals.
    //       Either don't connect them or connect them to dangling wires.
    //       In addition, the VGA{R,G,B} should be the upper 8 bits of the VGA module outputs.
endmodule
