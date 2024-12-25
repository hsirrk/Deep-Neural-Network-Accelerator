module dot(input logic clk, input logic rst_n,
           // slave (CPU-facing)
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,
           // master (memory-facing)
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata);

    // your code here
	 
	 enum {RST, SLAVEINPUT, READ_WEIGHT, READ_ACTIVATION, CALC_DOTPRODUCT, DONE, TEST_CALC, TEST_WRITE,TEST_WRITE2, WEIGHT_WRITE, ACTIVATION_WRITE, WEIGHT_ADS, ACTIVATION_ADS, WEIGHT_STALL, DATA_STALL} state;
	 logic [31:0] weightAds, activationAds, vecLength, i;
	 logic signed [31:0] weight, actVec;
	 logic signed [63:0] sumtemp, sum;
	 
	 
	 always_ff @(posedge clk) begin
		if (!rst_n) begin
			state <= RST;
		end
		else begin
			case(state)
				RST: begin
							state <= SLAVEINPUT;
							
							i <= 32'b0;
							weightAds <= 32'h00000000;
							activationAds <= 32'h00000000;
							vecLength <= 32'd0;
							sum <= 32'd0;
							weight <= 32'd5;
							actVec <= 32'd5;
					  end
				SLAVEINPUT: begin
									//state <= READ_WEIGHT; //start copy when CPU write value to word offset 0
									//i <= 32'b1;
									
									if (slave_write) begin
										case(slave_address)
											4'b0000: begin
															state <= READ_WEIGHT; //start copy when CPU write value to word offset 0
															i <= 32'd0;
														end
											4'd2: begin
															//word offset 2, write destination byte address
															weightAds <= slave_writedata;
														end
											4'd3: begin
															//word offset 3, write source byte address
															activationAds <= slave_writedata;
														end
											4'd5: begin
															//word offset 3, num of 32-bit words to copy
															vecLength <= slave_writedata;
														end
											default: begin
															state <= SLAVEINPUT;
														end
										endcase
									end
								end
				READ_WEIGHT: begin
									if (!master_waitrequest && master_readdatavalid) begin
										//state <= READ_ACTIVATION;
										state <= WEIGHT_STALL;
										weight <= master_readdata;
										//weight <= 32'd1;
									end
								 end
				WEIGHT_STALL: begin
										if (master_readdatavalid) begin
										//weight <= master_readdata;
										//weight <= 32'd1;
										//state <= DATA_STALL;
										state <= READ_ACTIVATION;
										end
									end
				DATA_STALL: begin
										if (master_readdatavalid) begin
											state <= READ_ACTIVATION;
										end
								end
				READ_ACTIVATION: begin
											if (!master_waitrequest && master_readdatavalid) begin
												state <= CALC_DOTPRODUCT;
												//state <= TEST_CALC;
												actVec <= master_readdata;
												//actVec <= 32'd9;
											end
									  end
				TEST_CALC: begin
									//if (!master_waitrequest && master_readdatavalid) begin
									sum <= sumtemp + sum;
									state <= TEST_WRITE;
									//actVec <= master_readdata;
									//state <= TEST_WRITE;
									//actVec <= 32'd9;
									//end
							  end
				CALC_DOTPRODUCT: begin
											//sum <= sum + ((weight*actVec) >>> 16);
											sum <= sum + sumtemp;
											
											if ( (i+32'b1) == vecLength) begin
													//state <= DONE;
													state <= WEIGHT_WRITE;
											end
											else begin
												//i <= i + 32'b1;
												//state <= READ_WEIGHT;
												
												//test
												//if (i == 32'b1) begin
													state <= TEST_WRITE;
												//end
												//else begin
													//state <= READ_WEIGHT;
													//i <= i + 32'b1;
												//end
											end
									  end
				TEST_WRITE: begin
											if (!master_waitrequest) begin
													state <= TEST_WRITE2;
											end
										 end
				TEST_WRITE2: begin
											if (!master_waitrequest) begin
													state <= READ_WEIGHT;
													i <= i + 32'b1;
											end
										 end
				WEIGHT_WRITE: begin
											if (!master_waitrequest) begin
													state <= ACTIVATION_WRITE;
											end
										 end
				ACTIVATION_WRITE: begin
											if (!master_waitrequest) begin
													state <= WEIGHT_ADS;
											end
										 end
				WEIGHT_ADS: begin
											if (!master_waitrequest) begin
													state <= ACTIVATION_ADS;
											end
										 end
				ACTIVATION_ADS: begin
											if (!master_waitrequest) begin
													state <= DONE;
											end
										 end
				DONE: begin
							if (slave_address == 4'b0 && slave_read) begin
								state <= SLAVEINPUT; //copy process finsihed when CPU read offset 0
								i <= 32'b0;
								weightAds <= 32'h00000000;
								activationAds <= 32'h00000000;
								vecLength <= 32'd0;
								sum <= 32'd0;
								weight <= 32'd5;
								actVec <= 32'd5;
							end
						end
				default: begin
				
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
			slave_readdata = 32'b0;
			sumtemp = 64'b0;
			
			case(state)
				RST: begin
				
					  end
				SLAVEINPUT: begin

								end
				READ_WEIGHT: begin
										slave_waitrequest = 1'b1;
										
										master_address = weightAds + i*32'd4;
										//master_address = 32'h09000004;
										master_read = 1'b1;
								 end
				WEIGHT_STALL: begin
										slave_waitrequest = 1'b1;
										
										//master_write = 1'b1;
										//		master_writedata = master_readdata;
										//		master_address = 32'h09000054;
									end
				DATA_STALL: begin
										slave_waitrequest = 1'b1;
								end
				READ_ACTIVATION: begin
											slave_waitrequest = 1'b1;
											
											master_address = activationAds + i*32'd4;
											//master_address = 32'h09000024;
											master_read = 1'b1;
									  end	
				TEST_CALC: begin
									slave_waitrequest = 1'b1;
									sumtemp = weight*actVec;
									//master_write = 1'b1;
									//			master_writedata = master_readdata;
									//			master_address = 32'h09000058;
							  end
				CALC_DOTPRODUCT: begin
											slave_waitrequest = 1'b1;
											sumtemp = weight*actVec;
											//sum <= sum + sumtemp[47:16];
										end
				TEST_WRITE: begin
											slave_waitrequest = 1'b1;
												master_write = 1'b1;
												master_writedata = sum[63:32];
												master_address = 32'h09000070 + i*32'd4;;
										 end	  
				TEST_WRITE2: begin
											slave_waitrequest = 1'b1;
												master_write = 1'b1;
												master_writedata = sum[31:0];
												//master_writedata = sum[47:16];
												master_address = 32'h09000090 + i*32'd4;;
										 end	
				WEIGHT_WRITE: begin
											slave_waitrequest = 1'b1;
												master_write = 1'b1;
												master_writedata = weight;
												master_address = 32'h09000054;
										 end
				ACTIVATION_WRITE: begin
											slave_waitrequest = 1'b1;
												master_write = 1'b1;
												master_writedata = actVec;
												master_address = 32'h09000058;
										 end
				WEIGHT_ADS: begin
											slave_waitrequest = 1'b1;
												master_write = 1'b1;
												master_writedata = weightAds + i*32'd4;
												master_address = 32'h09000064;
										 end
				ACTIVATION_ADS: begin
											slave_waitrequest = 1'b1;
												master_write = 1'b1;
												master_writedata = activationAds + i*32'd4;
												master_address = 32'h09000068;
										 end
				DONE: begin
							if (slave_address == 4'b0 && slave_read) begin
								//slave_readdata = {16'b0,sum[47:32]};
								slave_readdata = sum[47:16];
							end
						end
				default: begin
				
							end
			endcase
	 end

endmodule: dot
