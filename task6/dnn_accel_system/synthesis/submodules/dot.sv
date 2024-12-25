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

    // Local variables
    logic [31:0] weight; // to store the weight address base
    logic [31:0] input_act; // to store the input activation address base 
    logic [3:0] vec_length; // how many times to loop
    logic [3:0] i; // counter for number of words
    logic [31:0] temp1; // to store temp weight
    logic [31:0] temp2; // to storeinput_act

    logic signed [63:0] sum; // to store the sum
    logic signed [63:0] temp3; // to store the product

    //logic [31:0] sum_address = 32'h8809000;

    typedef enum logic [3:0] {IDLE, READ1, READ2, CALC, INC, DONE, STALL1, STALL2} state_t;
    state_t ps;


    // State machine with sequential logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin

            weight <= 0;
            input_act <= 0;
            vec_length <= 0;
            i <= 0;
            temp1 <= 0;
            temp2 <= 0;
            temp3 <= 0;
            sum <= 0;
            ps <= IDLE;

        end else begin
            case (ps)
                IDLE: begin // Starts the process when slave_address == 0

                    i <= 0;
                    temp1 <= 0;
                    temp2 <= 0;
                    temp3 <= 0;
                    sum <= 0;

                    if (slave_write == 1) begin
                        ps <= IDLE;
                        case (slave_address)
                            4'b0000: ps <= READ1;
                            4'b0010: weight <= slave_writedata;
                            4'b0011: input_act <= slave_writedata;
                            4'b0101: vec_length <= slave_writedata;
                            default: ps <= IDLE;
                        endcase
                    end 
                end

                READ1: begin // Reads the values from weight address
                    if (master_readdatavalid && !master_waitrequest) begin
                        temp1 <= master_readdata;
                        ps <= STALL1;
                    end
                end

                STALL1: begin
                    if (master_readdatavalid) begin
                        ps <= READ2;
                    end
                end

                READ2: begin // Reads the values from input activation address
                    if (master_readdatavalid && !master_waitrequest) begin
                        temp2 <= master_readdata;
                        ps <= STALL2;
                    end
                end

                STALL2: begin
                    if (master_readdatavalid) begin
                        temp3 <= temp1 * temp2;
                        ps <= CALC;
                    end
                end

                CALC: begin // Calculate the dot product
                    
                    sum <= sum + temp3; // Accumulate product in Q16.16
                    if (i + 1 < vec_length) begin
                        //i <= i + 1; // Increment counter
                        ps <= INC; // Go back to read the next pair
                    end else begin
                        ps <= DONE; // Move to write the final sum
                    end
                
                end

                INC: begin

                    i <= i + 1;
                    ps <= READ1;
                    
                end
/*

                WRITE_SUM: begin // Write the final dot product sum
                    if (!master_waitrequest) begin
                        ps <= DONE; // Transition to DONE state
                    end
                end
*/

                DONE: begin
                    if (slave_read == 1 && slave_address == 0) begin
                        ps <= IDLE;
                    end                end
                default: ps <= IDLE;
            endcase
        end
    end

    // Combinational logic block to control outputs
    always_comb begin
        // Default assignments
        slave_waitrequest = 0;
        slave_readdata = 0;
        master_address = 0;
        master_read = 0;
        master_write = 0;
        master_writedata = 0;

        case (ps)
            IDLE: begin
                // Outputs remain as default
                slave_waitrequest = 0;
                slave_readdata = 0;
                master_address = 0;
                master_read = 0;
                master_write = 0;
                master_writedata = 0;
            end

            READ1: begin // Reads data from weight
                slave_waitrequest = 1;

                slave_readdata = 0;
                master_write = 0;
                master_writedata = 0;

                master_address = weight + i * 4; // Address increment by word size (4 bytes)
                master_read = 1;
            end

            STALL1: begin
                slave_waitrequest = 1;
                master_read = 0;
                //same outputs
            end

            READ2: begin // Reads data from input activation
                slave_waitrequest = 1;

                slave_readdata = 0;
                master_write = 0;
                master_writedata = 0;

                master_address = input_act + i * 4; // Address increment by word size (4 bytes)
                master_read = 1;
            end

            STALL2: begin
                slave_waitrequest = 1;
                master_read = 0;
                //same outputs
            end

            CALC: begin // calculates dot product
                slave_waitrequest = 1;
                master_read = 0;
                //same outputs
            end

            INC: begin
                slave_waitrequest = 1;
                master_read = 0;
                //same outputs
            end

/*
            WRITE_SUM: begin // Writes data to destination
                slave_waitrequest = 1;

                slave_readdata = 0;
                master_read = 0;

                master_address = sum_address;
                master_write = 1;
                master_writedata = sum[31:0]; // Truncate sum to 32 bits
            end

*/

            DONE: begin
                //other outputs are same outputs
                slave_waitrequest = 0;
                master_read = 0;
                if (slave_read == 1 && slave_address == 0) begin
                    slave_readdata = sum[47:16]; // Truncate sum to 32 bits, outputting it for the C file to read;
                end
            end
        endcase
    end

endmodule: dot
