//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens
(
    input  clk,
    input  rst,
    input  a,
    output b
);
    // Task:
    // Implement a serial module that reduces amount of incoming '1' tokens by half.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 110_011_101_000_1111
    // b -> 010_001_001_000_0101

    enum logic
    {
        st_consume,
        st_output
    }
    state, new_state;

    always_comb begin
        new_state = state;

        case (state)
            st_consume : if (a) new_state = st_output;
            st_output  : if (a) new_state = st_consume;
        endcase
    end

    // Output logic
    assign b = (state == st_output) && a;
    
    always_ff @ (posedge clk)
        if (rst)
            state <= st_output;
        else
            state <= new_state;

endmodule
