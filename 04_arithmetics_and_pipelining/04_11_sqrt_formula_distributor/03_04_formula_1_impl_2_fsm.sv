//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
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

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the formula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    enum logic [1:0]
    {
        // Technically, this is Moore machine
        // So its outputs are registered. More about coding conventions of
        // FSMs can be found here: http://www.sunburst-design.com/papers/CummingsSNUG2019SV_FSM1.pdf

        st_idle,
        st_wait_isqrt_ab,
        st_wait_isqrt_c
    }
    state, new_state;

    // State logic

    always_comb begin
        new_state = state;

        // verilator lint_off CASEINCOMPLETE
        case (state)
            st_idle : if (arg_vld)
                new_state = st_wait_isqrt_ab;
            st_wait_isqrt_ab : if (isqrt_1_y_vld && isqrt_2_y_vld)
                new_state = st_wait_isqrt_c;
            st_wait_isqrt_c : if (isqrt_1_y_vld)
                new_state = st_idle;
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= new_state;

    // Datapath: Loading

    always_comb begin
        // Make sure all used inputs are assigned to default value here
        isqrt_1_x_vld = 1'b0;
        isqrt_2_x_vld = 1'b0;

        // Without specifying 'x here, they do become latches
        isqrt_1_x = 'x;
        isqrt_2_x = 'x;

        // verilator lint_off CASEINCOMPLETE
        case (state)
            st_idle : begin
                isqrt_1_x_vld = arg_vld;
                isqrt_2_x_vld = arg_vld;

                isqrt_1_x = a;
                isqrt_2_x = b;
            end

            st_wait_isqrt_ab : begin
                isqrt_1_x_vld = isqrt_1_y_vld && isqrt_2_y_vld;

                isqrt_1_x = tmp_reg;
            end
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    // Datapath: Storing

    logic [31:0] tmp_reg;  // register for 'reg' and 'c'
    logic [15:0] isqrt_a_reg,
                 isqrt_b_reg;

    always_ff @ (posedge clk)
        // verilator lint_off CASEINCOMPLETE
        case (state)
            st_idle : if (arg_vld) begin
                tmp_reg <= c;
            end

            st_wait_isqrt_ab : if (isqrt_1_y_vld & isqrt_2_y_vld) begin
                isqrt_a_reg <= isqrt_1_y;
                isqrt_b_reg <= isqrt_2_y;
            end

            st_wait_isqrt_c : if (isqrt_1_y_vld) begin
                // We explicitly state that we want to use 18 bit width addition
                // Clarification: 17 < log2(3 * (2 ** 16 - 1)) <= 18
                tmp_reg <= {14'd0, 18'(isqrt_1_y) + 18'(isqrt_a_reg) + 18'(isqrt_b_reg)};
            end
        endcase
        // verilator lint_on CASEINCOMPLETE

    // Output logic

    always_ff @ (posedge clk)
        // We put res_vld here (and not in datapath storing) since it needs to be reset
        if (rst)
            res_vld <= 1'b0;
        else
            res_vld <= (state == st_wait_isqrt_c) && (isqrt_1_y_vld);

    assign res = res_vld ? tmp_reg : 'x;

endmodule
