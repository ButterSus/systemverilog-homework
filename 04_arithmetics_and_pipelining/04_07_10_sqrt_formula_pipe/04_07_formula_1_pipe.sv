//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output       [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    //----------------------------------------------------------------------------
    // Stage 1: Input Latching & isqrt Launch
    //----------------------------------------------------------------------------

    logic isqrt_a_vld,
          isqrt_b_vld,
          isqrt_c_vld;

    logic [15:0] isqrt_a_res,
                 isqrt_b_res,
                 isqrt_c_res;

    isqrt i_isqrt_a
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .x_vld ( arg_vld     ),
        .x     ( a           ),
        .y_vld ( isqrt_a_vld ),
        .y     ( isqrt_a_res )
    );

    isqrt i_isqrt_b
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .x_vld ( arg_vld     ),
        .x     ( b           ),
        .y_vld ( isqrt_b_vld ),
        .y     ( isqrt_b_res )
    );

    isqrt i_isqrt_c
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .x_vld ( arg_vld     ),
        .x     ( c           ),
        .y_vld ( isqrt_c_vld ),
        .y     ( isqrt_c_res )
    );

    //----------------------------------------------------------------------------
    // Stage 2: Result Summing & Output Validity Register
    //----------------------------------------------------------------------------

    logic isqrts_vld, sum_vld;
    assign isqrts_vld = isqrt_a_vld && isqrt_b_vld && isqrt_c_vld;

    logic [17:0] res_reg;

    always_ff @ (posedge clk)
        if (isqrts_vld)
            res_reg <= 18'(isqrt_a_res) + 18'(isqrt_b_res) + 18'(isqrt_c_res);

    // Output logic

    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            res_vld <= isqrts_vld;

    assign res = res_vld ? 32'(res_reg) : 'x;

endmodule
