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

    // Local variables
    logic [31:0] dest_ad; // to store the destination address
    logic [31:0] src_ad; // to store the source 
    logic [3:0] no_words; // to store the number of words
    logic [3:0] i; // counter for number of words
    logic [31:0] temp; // temporary value to be copied

    typedef enum logic [2:0] {IDLE, READ, WRITE, DONE} state_t;
    state_t ps;


    // State machine with sequential logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin

            dest_ad <= 0;
            src_ad <= 0;
            no_words <= 0;
            i <= 0;
            temp <= 0;
            ps <= IDLE;

        end else begin
            case (ps)
                IDLE: begin // Starts the process when slave_address == 0

                    i <= 0;
                    temp <= 0;

                    if (slave_write == 1) begin
                        ps <= IDLE;
                        case (slave_address)
                            4'b0000: ps <= READ;
                            4'b0001: dest_ad <= slave_writedata;
                            4'b0010: src_ad <= slave_writedata;
                            4'b0011: no_words <= slave_writedata;
                            default: ps <= IDLE;
                        endcase
                    end 
                end

                READ: begin // Reads the values from source address
                    if (master_readdatavalid && !master_waitrequest) begin
                        temp <= master_readdata;
                        ps <= WRITE;
                    end
                end

                WRITE: begin // Writes the values to destination address
                    if (!master_waitrequest) begin
                        if (i < no_words) begin
                            i <= i + 1;
                            ps <= READ;
                        end else begin
                            ps <= DONE;
                        end
                    end
                end
                DONE: begin
                    if (slave_read == 1) begin
                        if (slave_address == 0) begin
                            ps <= IDLE;
                        end
                    end
                end
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

            READ: begin // Reads data from source
                slave_waitrequest = 1;

                slave_readdata = 0;
                master_write = 0;
                master_writedata = 0;

                master_address = src_ad + i * 4; // Address increment by word size (4 bytes)
                master_read = 1;
            end

            WRITE: begin // Writes data to destination
                slave_waitrequest = 1;

                slave_readdata = 0;
                master_read = 0;

                master_address = dest_ad + i * 4; // Address increment by word size (4 bytes)
                master_write = 1;
                master_writedata = temp;
            end
            DONE: begin
                //same outputs
            end
        endcase
    end


endmodule: wordcopy