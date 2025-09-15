//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module flip_flop_fifo_with_counter
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,
    input                push,
    input                pop,
    input  [width - 1:0] write_data,
    output [width - 1:0] read_data,
    output               empty,
    output               full
);

    // Even though this is not task, I just discovered
    // that counter here is used only to reduce output latency after posedge.
    // So we can remove counter completely just for fun!

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth);
    localparam max_ptr = pointer_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr, wr_ptr_next;
    logic [pointer_width - 1:0] rd_ptr, rd_ptr_next;

    logic [width - 1:0] data [0: depth - 1];

    logic empty_flag;

    //------------------------------------------------------------------------

    always_comb begin
        wr_ptr_next = wr_ptr == max_ptr ? '0 : wr_ptr + 1'b1;
        rd_ptr_next = rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;
    end

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            wr_ptr <= '0;
        else if (push)
            wr_ptr <= wr_ptr_next;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            rd_ptr <= '0;
        else if (pop)
            rd_ptr <= rd_ptr_next;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            empty_flag <= 1'b1;
        else if (pop)
            empty_flag <= rd_ptr_next == wr_ptr;
        else if (push)
            empty_flag <= 1'b0;

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

    //------------------------------------------------------------------------

    assign empty = (wr_ptr == rd_ptr) &  empty_flag;
    assign full  = (wr_ptr == rd_ptr) & ~empty_flag;

endmodule
