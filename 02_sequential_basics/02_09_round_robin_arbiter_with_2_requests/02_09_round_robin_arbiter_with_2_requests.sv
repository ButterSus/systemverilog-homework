//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01

    enum logic
    {
        st_first,
        st_second
    }
    state, new_state;

    always_comb begin
        new_state = state;

        case (state)
            st_first  : if (grants[0]) new_state = st_second;
            st_second : if (grants[1]) new_state = st_first;
        endcase
    end

    // Output logic
    assign grants[0] = requests[0] & (~requests[1] || state == st_first);
    assign grants[1] = requests[1] & (~requests[0] || state == st_second);

    always_ff @ (posedge clk)
        if (rst)
            state <= st_first;
        else
            state <= new_state;

endmodule
