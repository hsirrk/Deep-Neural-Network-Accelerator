module tb_rtl_dot();

    logic clk, rst_n, slave_waitrequest, slave_read, slave_write, err;
    logic [3:0] slave_address;
    logic [31:0] slave_readdata, slave_writedata;
    logic master_waitrequest, master_read, master_readdatavalid, master_write;
    logic [31:0] master_address, master_readdata, master_writedata;

    logic [63:0] mul;

    dot dut(.*);

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    initial begin
        err = 1'b0;

        #2 rst_n = 0;
        @(posedge clk); // do sync reset
        @(negedge clk);



        #2 rst_n = 1;
        master_waitrequest = 1'bx;

        // wait a bit
        @(negedge clk);
        @(negedge clk);

        slave_write = 1;

        // Write weight address to accelerator's address
        slave_address = 4'd2;
        slave_writedata = 32'h03;
        @(negedge clk);


        slave_write = 0;
        slave_writedata = 32'bx;
        @(negedge clk);
        @(negedge clk);

        slave_write = 1;

        // Write vector address
        slave_address = 4'd3;
        slave_writedata = 32'h12;
        @(negedge clk);


        // Write vector length
        slave_address = 4'd5;
        slave_writedata = 32'h3;
        @(negedge clk);
 
        
        // Write to word offset 0 to start calculation
        slave_address = 4'd0;
        slave_writedata = 32'haa;
        @(negedge clk);


        slave_write = 0;
        slave_writedata = 32'bx;
        // Read from dot product accelerator offset 0, should stall until slave_waitrequest = 0
        slave_read = 1;
        slave_address = 4'd0;

        // Start reading from weight address
        master_waitrequest = 1'b0;


        // Verify Q16.16 multiplication
        // 102236 is Q16.16 format for float number 1.56
        // 81265 is Q16.16 format for float number 1.24
        // mul = 102236 * 81265;
        // $display("%b", 1.56 * 1.24); // Should get 1 here
        // $display("%b", mul[63:32]); // Should be 1
        // $display("%b", mul[31:0]);  // Should be 0.934402...

        // mul = 65536 * -163185;
        // $display("%b", mul[63:32]); // Should be -2
        // $display("%b", mul[31:0]);  // Should be 0.49

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        master_readdata = 32'd102236;
        master_readdatavalid = 1;
        @(negedge clk);
        @(negedge clk);
        master_readdata = 32'd81265;
        master_readdatavalid = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        // Should produce int_prod = 2 and sum = 2
        master_readdata = 32'd65536;
        master_readdatavalid = 1;
        @(negedge clk);
        @(negedge clk);
        master_readdata = -163185;
        master_readdatavalid = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        master_readdata = -370934;
        master_readdatavalid = 1;
        @(negedge clk);
        @(negedge clk);
        master_readdata = 122552;
        master_readdatavalid = 1;
        @(negedge clk);
        @(negedge clk);
        // Should produce int_prod = -11 and sum = 11
        slave_write = 0;
        slave_writedata = 32'bx; @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        
        // Done calc, output slave_readdata value and deaasert waitrequest
        if (tb_rtl_dot.dut.slave_readdata !== -11) begin
            $display("ERROR 9: Expected slave_readdata is %d, actual slave_readdata is %d", -11, tb_rtl_dot.dut.slave_readdata);
            err = 1'b1;
        end
        if (tb_rtl_dot.dut.slave_waitrequest !== 1'b0) begin
            $display("ERROR 10: Expected slave_waitrequest is %d, actual slave_waitrequest is %d", 1'b0, tb_rtl_dot.dut.slave_waitrequest);
            err = 1'b1;
        end

        if (~err)
            $display("SUCCESS: All tests passed.");
        $stop;
    end

endmodule: tb_rtl_dot