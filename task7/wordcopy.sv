module wordcopy(input logic clk, input logic rst_n,
                // slave (CPU-facing)
                output logic slave_waitrequest,
                input logic [3:0] slave_address,
                input logic slave_read, output logic [31:0] slave_readdata,
                input logic slave_write, input logic [31:0] slave_writedata,
                // master (SDRAM-facing)
                input logic master_waitrequest,
                output logic [31:0] master_address,
                output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
                output logic master_write, output logic [31:0] master_writedata);

    // your code here
	 
	 logic [31:0] accelatorBaseAddress = 32'h00001040;
	 //localparam accelatorBaseAddress = 32'h08FFFFF0;
	 logic [31:0] destAds, srceAds, numWords, i, tempdata;
	 
	 enum {RST, SLAVEINPUT, EXECUTECOPY_WRITE, EXECUTECOPY_READ, DONE, INITIALIZEVALUES, INITIALIZEVALUES_WRITE} state;
	 
	 always_ff @(posedge clk) begin
		if (!rst_n) begin
			state <= RST;
		end
		else begin
			case(state)
				RST: begin
							state <= SLAVEINPUT;
							//state <= EXECUTECOPY_READ;
							i <= 32'b0;
							
							destAds <= 32'h00000000;
							srceAds <= 32'h08800000;
							numWords <= 32'd0;
					  end
				SLAVEINPUT: begin
									if (slave_write) begin
										case(slave_address)
											4'b0000: begin
															state <= EXECUTECOPY_READ; //start copy when CPU write value to word offset 0
															//i <= 32'b0;
															//state <= INITIALIZEVALUES_WRITE;
															//numWords <= slave_writedata;
														end
											4'd1: begin
															//word offset 1, write destination byte address
															destAds <= slave_writedata;
											//				state <= SLAVEINPUT;
															//i <= 32'd4;
														end
											4'd2: begin
															//word offset 2, write source byte address
															srceAds <= slave_writedata;
											//				state <= SLAVEINPUT;
															//i <= 32'd2;
														end
											4'd3: begin
															//word offset 3, num of 32-bit words to copy
															numWords <= slave_writedata;
											//				state <= SLAVEINPUT;
															//i <= 32'd12;
														end
											default: begin
															state <= SLAVEINPUT;
															//i <= i + 32'b1;
														end
										endcase
									end
								end
				INITIALIZEVALUES: begin
											if (!master_waitrequest && master_readdatavalid) begin
												if (i == 32'd3) begin
													state <= DONE;
												end
												else begin
													i <= i + 32'b1;
													state <= INITIALIZEVALUES;
												end
											end
										end
				INITIALIZEVALUES_WRITE: begin
											if (!master_waitrequest) begin
												if (i == 32'd3) begin
													state <= DONE;
												end
												else begin
													i <= i + 32'b1;
													state <= INITIALIZEVALUES_WRITE;
												end
											end
										end
				
				EXECUTECOPY_WRITE: begin
											//if (!master_waitrequest && master_readdatavalid) begin
											if (!master_waitrequest) begin
												if ( (i+32'b1) == numWords) begin
													state <= DONE;
												end
												else begin
													i <= i + 32'b1;
													state <= EXECUTECOPY_READ;
												end
											end
										 end
				EXECUTECOPY_READ: begin
											if (!master_waitrequest && master_readdatavalid) begin
												state <= EXECUTECOPY_WRITE;
												tempdata <= master_readdata;
											end
										end
				DONE: begin
							if (slave_address == 4'b0 && slave_read) begin
								state <= SLAVEINPUT; //copy process finsihed when CPU read offset 0
								i <= 32'b0;
							end
						end
			endcase
		
		
		end
	 
	 end
	 
	 
	 always_comb begin
			master_writedata = 32'b0;
			master_address = 32'b0;
			master_write = 1'b0;
			master_read = 1'b0;
			slave_waitrequest = 1'b0;
			
			//master_write = 1'b1;
			//master_address = 32'h09000000;
			//master_writedata = 32'h25;
			
			case(state)
				RST: begin
					  end
				SLAVEINPUT: begin
									//if(master_waitrequest) begin
										//if sdram is busy, can't write to address, so must hold slave
										//input to ensure address and data are not missed
									//	slave_waitrequest = 1'b1;
									//end
				/*
									if (slave_write) begin
										case(slave_address)
											4'b0000: begin
															//begin copy, read data at source address
															master_address = srceAds;
															master_read = 1'b0;
														end
											4'd4: begin
															//word offset 1, write destination byte address
															master_writedata = slave_writedata;
															master_address = accelatorBaseAddress + 32'd4;
															//master_write = 1'b1;
														end
											4'd8: begin
															//word offset 2, write source byte address
															master_writedata = slave_writedata;
															master_address = accelatorBaseAddress + 32'd8;
															//master_write = 1'b1;
														end
											4'd12: begin
															//word offset 3, num of 32-bit words to copy
															master_writedata = slave_writedata;
															master_address = accelatorBaseAddress + 32'd12;
															//master_write = 1'b1;
														end
											default: begin
															master_writedata = 8'h35;
															master_address = 8'h09000004;
															master_write = 1'b0;
														end
										endcase
									end
				*/
								end
				INITIALIZEVALUES: begin
											slave_waitrequest = 1'b1;
									
											//if (!master_waitrequest) begin
												master_address = accelatorBaseAddress + i*32'd4;
												master_read = 1'b1;
												//master_write = 1'b1;
												//master_writedata = 32'h55;
											//end
										end
				INITIALIZEVALUES_WRITE: begin
												slave_waitrequest = 1'b1;
									
												master_address = accelatorBaseAddress + i*32'd4;
												master_write = 1'b1;
												master_writedata = 32'h55;
										end
				EXECUTECOPY_WRITE: begin
											slave_waitrequest = 1'b1;
											
											//if (!master_waitrequest && master_readdatavalid) begin
											//if (master_readdatavalid) begin
												master_write = 1'b1;
												//master_address = destAds;
												//master_writedata = 32'h5;
												master_writedata = tempdata;
												master_address = destAds + i*32'd4;
												//master_write = 1'b1;
											//end
										 end
				EXECUTECOPY_READ: begin
											slave_waitrequest = 1'b1;
									
											//if (!master_waitrequest) begin
												master_address = srceAds + i*32'd4;
												master_read = 1'b1;
												//master_write = 1'b1;
												//master_writedata = 32'h55;
											//end
										end
				DONE: begin
							//testing
							//master_writedata = 8'h35;
							//master_address = 8'h09000004;
							//master_write = 1'b1;
						end
			endcase
	 end

endmodule: wordcopy
