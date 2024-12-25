module dotopt(input logic clk, input logic rst_n,
           // slave (CPU-facing)
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,

           // master_* (SDRAM-facing): weights (anb biases for task7)
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata,

           // master2_* (SRAM-facing to bank0 and bank1): input activations (and output activations for task7)
           input logic master2_waitrequest,
           output logic [31:0] master2_address,
           output logic master2_read, input logic [31:0] master2_readdata, input logic master2_readdatavalid,
           output logic master2_write, output logic [31:0] master2_writedata);

    // your code: you may wish to start by copying code from your "dot" module, and then add control for master2_* port

	 enum {RST, SLAVEINPUT, READ_WEIGHT_ACTIVATION, CALC_DOTPRODUCT, CALC_WAIT, DONE} state;
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
															state <= READ_WEIGHT_ACTIVATION; //start copy when CPU write value to word offset 0
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
				READ_WEIGHT_ACTIVATION: begin
									if (!master_waitrequest && master_readdatavalid) begin
										state <= CALC_DOTPRODUCT;
										weight <= master_readdata;
										actVec <= master2_readdata;
									end
								 end
				CALC_DOTPRODUCT: begin
											sum <= sum + sumtemp;
												if ( (i+32'b1) == vecLength) begin
														state <= DONE;
												end
												else begin
													state <= CALC_WAIT;
												end
									  end
				CALC_WAIT: begin
											if (!master_waitrequest) begin
													state <= READ_WEIGHT_ACTIVATION;
													i <= i + 32'b1;
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
			master2_read = 1'b0;
			master2_address = 32'b0;
			
			case(state)
				RST: begin
				
					  end
				SLAVEINPUT: begin

								end
				READ_WEIGHT_ACTIVATION: begin
										slave_waitrequest = 1'b1;
										
										//weight from SDRAM
										master_address = weightAds + i*32'd4;
										master_read = 1'b1;
										
										//INPUT from SRAM
										master2_address = activationAds + i*32'd4;
										master2_read = 1'b1;
								 end
				CALC_DOTPRODUCT: begin
											slave_waitrequest = 1'b1;
											sumtemp = weight*actVec;
										end
				CALC_WAIT: begin
											slave_waitrequest = 1'b1;
										 end
				DONE: begin
							if (slave_address == 4'b0 && slave_read) begin
								slave_readdata = sum[47:16];
							end
						end
				default: begin
				
							end
			endcase
	 end
	 
endmodule: dotopt
