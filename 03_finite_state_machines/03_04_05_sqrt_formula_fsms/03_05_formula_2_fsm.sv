//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);
    // Task:
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    enum logic [2:0]
    {
        st_idle,
        st_wait_isqrt_c,
        st_comb_b,
        st_wait_isqrt_b,
        st_comb_a,
        st_wait_isqrt_a,
        st_done
    }
    state, new_state;

    // State logic

    always_comb begin
        new_state = state;

        // verilator lint_off CASEINCOMPLETE
        case (state)
            st_idle : if (arg_vld)
                new_state = st_wait_isqrt_c;
            st_wait_isqrt_c : if (isqrt_y_vld)
                new_state = st_comb_b;
            st_comb_b :
                new_state = st_wait_isqrt_b;
            st_wait_isqrt_b : if (isqrt_y_vld)
                new_state = st_comb_a;
            st_comb_a :
                new_state = st_wait_isqrt_a;
            st_wait_isqrt_a : if (isqrt_y_vld)
                new_state = st_done;
            st_done :
                new_state = st_idle;
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= new_state;

    // Datapath : Loading

    always_comb begin
        isqrt_x_vld = 1'b0;

        isqrt_x = 'x;

        // verilator lint_off CASEINCOMPLETE
        case (state)
            st_idle : begin
                isqrt_x_vld = arg_vld;

                isqrt_x = c;
            end
            st_comb_b : begin
                isqrt_x_vld = 1'b1;

                isqrt_x = 32'(res_reg) + b_reg;
            end
            st_comb_a : begin
                isqrt_x_vld = 1'b1;

                isqrt_x = 32'(res_reg) + a_reg;
            end
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    // Datapath : Storing

    logic [31:0] a_reg, b_reg;  // Also acts as registers for accumulation
    logic [15:0] res_reg;

    always_ff @ (posedge clk)
        // verilator lint_off CASEINCOMPLETE
        case (state)
            st_idle : if (arg_vld) begin
                a_reg <= a;
                b_reg <= b;
            end
            st_wait_isqrt_c : if (isqrt_y_vld)
                res_reg <= isqrt_y;
            st_wait_isqrt_b : if (isqrt_y_vld)
                res_reg <= isqrt_y;
            st_wait_isqrt_a : if (isqrt_y_vld)
                res_reg <= isqrt_y;
        endcase
        // verilator lint_on CASEINCOMPLETE

    // Output logic
    assign res = res_vld ? 32'(res_reg) : 'x;
    assign res_vld = (state == st_done);

endmodule
