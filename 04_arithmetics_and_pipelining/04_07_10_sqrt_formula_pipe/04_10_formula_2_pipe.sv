//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
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

    // We can't solve this task without revealing amount of stages in isqrt
    // module, even though it's supposed to be "black box".

    //----------------------------------------------------------------------------
    // Stage 1: isqrt c
    //----------------------------------------------------------------------------

    logic        isqrt_c_vld;
    logic [15:0] isqrt_c_res;

    isqrt #(.n_pipe_stages(4)) i_isqrt_c
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .x_vld ( arg_vld     ),
        .x     ( c           ),
        .y_vld ( isqrt_c_vld ),
        .y     ( isqrt_c_res )
    );

    // Pipelined variables

    logic [31:0] stage_1_a [0:3];
    logic [31:0] stage_1_b [0:3];

    always_ff @ (posedge clk) begin
        if (arg_vld) begin
            stage_1_a [0] <= a;
            stage_1_b [0] <= b;
        end

        for (int i = 1; i < 4; i ++) begin
            stage_1_a [i] <= stage_1_a [i - 1];
            stage_1_b [i] <= stage_1_b [i - 1];
        end
    end

    //----------------------------------------------------------------------------
    // Stage 2: isqrt b
    //----------------------------------------------------------------------------

    logic        isqrt_bc_vld;
    logic [15:0] isqrt_bc_res;

    isqrt #(.n_pipe_stages(4)) i_isqrt_bc
    (
        .clk   ( clk                         ),
        .rst   ( rst                         ),
        .x_vld ( isqrt_c_vld                 ),
        .x     ( stage_1_b [3] + isqrt_c_res ),
        .y_vld ( isqrt_bc_vld                ),
        .y     ( isqrt_bc_res                )
    );

    // Pipelined variables

    logic [31:0] stage_2_a [0:3];

    always_ff @ (posedge clk) begin
        if (isqrt_c_vld) begin
            stage_2_a [0] <= stage_1_a [3];
        end

        for (int i = 1; i < 4; i ++) begin
            stage_2_a [i] <= stage_2_a [i - 1];
        end
    end

    //----------------------------------------------------------------------------
    // Stage 3: isqrt a
    //----------------------------------------------------------------------------

    logic        isqrt_abc_vld;
    logic [15:0] isqrt_abc_res;

    isqrt #(.n_pipe_stages(4)) i_isqrt_abc
    (
        .clk   ( clk                          ),
        .rst   ( rst                          ),
        .x_vld ( isqrt_bc_vld                 ),
        .x     ( stage_2_a [3] + isqrt_bc_res ),
        .y_vld ( isqrt_abc_vld                ),
        .y     ( isqrt_abc_res                )
    );

    // Output logic

    assign res = res_vld ? isqrt_abc_res : 'x;
    assign res_vld = isqrt_abc_vld;

endmodule
