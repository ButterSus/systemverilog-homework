module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4,
              depth    = 2
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output logic                     down_vld,
    output logic [ width   - 1 : 0 ] down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    // Minimal FIFO implementation
    logic [width-1:0] data_buffer [n_inputs][depth];
    logic             data_valid  [n_inputs][depth];
    
    // Write pointers for each channel (where to store next incoming data)
    logic [$clog2(depth)-1:0] wr_ptr [n_inputs];
    // Read pointers for each channel (which buffer to read next)
    logic [$clog2(depth)-1:0] rd_ptr [n_inputs];
    
    // One-hot: which channel we're waiting for next
    logic [n_inputs-1:0] channel_idx;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            channel_idx <= 1'b1;  // One-hot: waiting for input[0]

            for (int i = 0; i < n_inputs; i++) begin
                wr_ptr[i] <= '0;
                rd_ptr[i] <= '0;
                for (int j = 0; j < depth; j++) begin
                    data_valid[i][j] <= 1'b0;
                end
            end
        end else begin
            // Store incoming data in buffers
            for (int i = 0; i < n_inputs; i++) begin
                if (up_vlds[i]) begin
                    // Store in the next available buffer slot
                    data_buffer[i][wr_ptr[i]] <= up_data[i];
                    data_valid[i][wr_ptr[i]]  <= 1'b1;
                    
                    // Advance write pointer (circular)
                    if (wr_ptr[i] == depth - 1)
                        wr_ptr[i] <= '0;
                    else
                        wr_ptr[i] <= wr_ptr[i] + 1;
                end
            end
            
            // Check if we can output the next expected result
            for (int i = 0; i < n_inputs; i++) begin
                if (channel_idx[i] && data_valid[i][rd_ptr[i]]) begin
                    // Mark current buffer slot as consumed
                    data_valid[i][rd_ptr[i]] <= 1'b0;
                    
                    // Advance read pointer (circular)
                    if (rd_ptr[i] == depth - 1)
                        rd_ptr[i] <= '0;
                    else
                        rd_ptr[i] <= rd_ptr[i] + 1;
                    
                    // Move to next channel in round-robin fashion
                    if (i == n_inputs - 1) begin
                        channel_idx <= 1'b1;
                    end else begin
                        channel_idx <= channel_idx << 1;
                    end
                end
            end
        end
    end
    
    // Output logic - combinational
    always_comb begin
        down_vld  = 1'b0;
        down_data = '0;
        
        // Check if the data we're waiting for is available
        // Since channel_idx is one-hot, only one condition can be true
        for (int i = 0; i < n_inputs; i++) begin
            if (channel_idx[i] && data_valid[i][rd_ptr[i]]) begin
                down_vld  = 1'b1;
                down_data = data_buffer[i][rd_ptr[i]];
            end
        end
    end

endmodule
