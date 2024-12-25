`timescale 1ps / 1ps
module tb_rtl_wordcopy();

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Slave (CPU-facing) signals
    logic slave_waitrequest;
    logic [3:0] slave_address;
    logic slave_read;
    logic [31:0] slave_readdata;
    logic slave_write;
    logic [31:0] slave_writedata;

    // Master (SDRAM-facing) signals
    logic master_waitrequest;
    logic [31:0] master_address;
    logic master_read;
    logic [31:0] master_readdata;
    logic master_readdatavalid;
    logic master_write;
    logic [31:0] master_writedata;

    // Instantiate the DUT
    wordcopy dut (
        .clk(clk),
        .rst_n(rst_n),
        .slave_waitrequest(slave_waitrequest),
        .slave_address(slave_address),
        .slave_read(slave_read),
        .slave_readdata(slave_readdata),
        .slave_write(slave_write),
        .slave_writedata(slave_writedata),
        .master_waitrequest(master_waitrequest),
        .master_address(master_address),
        .master_read(master_read),
        .master_readdata(master_readdata),
        .master_readdatavalid(master_readdatavalid),
        .master_write(master_write),
        .master_writedata(master_writedata)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test variables
    logic [31:0] mem [0:255]; // Simulated SDRAM memory
    integer i;

    // SDRAM behavior (move `master_readdatavalid` here)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            master_readdatavalid <= 0;
        end else begin
            if (master_read && !master_waitrequest) begin
                master_readdata <= mem[master_address >> 2];
                master_readdatavalid <= 1;
            end else begin
                master_readdatavalid <= 0;
            end

            if (master_write && !master_waitrequest) begin
                mem[master_address >> 2] <= master_writedata;
            end
        end
    end

    // Test sequence
    initial begin
        // Initialize variables
        clk = 0;
        rst_n = 0;
        slave_address = 0;
        slave_read = 0;
        slave_write = 0;
        slave_writedata = 0;
        master_waitrequest = 0;

        // Reset the DUT
        #10 rst_n = 1;

        // Initialize SDRAM memory
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'h0;
        end
        // Load source memory with test data
        mem[8] = 32'hDEADBEEF;
        mem[9] = 32'hCAFEBABE;
        mem[10] = 32'h12345678;
        mem[11] = 32'hABCDEF01;

        // Set destination address, source address, and number of words
        #10 slave_write = 1; slave_address = 1; slave_writedata = 32'h20; // dest_ad = 32
        #10 slave_write = 1; slave_address = 2; slave_writedata = 32'h20; // src_ad = 32
        #10 slave_write = 1; slave_address = 3; slave_writedata = 4;      // no_words = 4
        #10 slave_write = 0; slave_address = 0;                           // Start the FSM

        // Wait for FSM to complete
        wait (slave_waitrequest == 0);

        // Verify data in the destination memory
        #10;
        for (i = 8; i < 12; i = i + 1) begin
            $display("mem[%0d] = %h, copied to mem[%0d] = %h", i, mem[i], i + 4, mem[i + 4]);
            if (mem[i] !== mem[i + 4]) begin
                $error("Data mismatch at destination address %0d", i + 4);
            end
        end

        // Finish simulation
        #10 $stop;
    end

endmodule: tb_rtl_wordcopy
