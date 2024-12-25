`timescale 1ns/1ps

module tb_vga_avalon();

    // Declare signals
    logic clk;
    logic reset_n;
    logic [3:0] address;
    logic read;
    logic write;
    logic [31:0] writedata;
    logic [31:0] readdata;
    logic [7:0] vga_red, vga_grn, vga_blu;
    logic vga_hsync, vga_vsync, vga_clk;


    // Instantiate the DUT (Device Under Test)
    vga_avalon dut (
        .clk(clk),
        .reset_n(reset_n),
        .address(address),
        .read(read),
        .readdata(readdata),
        .write(write),
        .writedata(writedata),
        .vga_red(vga_red),
        .vga_grn(vga_grn),
        .vga_blu(vga_blu),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_clk(vga_clk)
    );

    // Clock generation: 50 MHz
    always #10 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        address = 4'd0;
        read = 0;
        write = 0;
        writedata = 32'd0;

        // Reset pulse
        #20 reset_n = 1;

        // Write valid pixel within bounds (x=10, y=20, brightness=128)
        writedata = {7'd20, 8'd10, 8'd128};  // y=20, x=10, brightness=128
        write = 1;
        #20 write = 0;

        // Write invalid pixel out of bounds (x=200, y=150)
        writedata = {7'd150, 8'd200, 8'd255};  // y=150, x=200, brightness=255
        write = 1;
        #20 write = 0;

        // Write another valid pixel (x=50, y=100, brightness=255)
        writedata = {7'd100, 8'd50, 8'd255};  // y=100, x=50, brightness=255
        write = 1;
        #20 write = 0;

        // End simulation
        #100 $stop;
    end

endmodule
