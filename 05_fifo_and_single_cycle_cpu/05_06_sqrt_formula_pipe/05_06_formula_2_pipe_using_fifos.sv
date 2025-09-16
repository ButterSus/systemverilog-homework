//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
# (
    // Amount of stages per isqrt module
    parameter N = 4
)
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
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
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 04_10_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    //----------------------------------------------------------------------------
    // Stage 1: isqrt c
    //----------------------------------------------------------------------------

    logic        isqrt_c_vld;
    logic [15:0] isqrt_c_res;

    isqrt #(.n_pipe_stages(N)) i_isqrt_c
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .x_vld ( arg_vld     ),
        .x     ( c           ),
        .y_vld ( isqrt_c_vld ),
        .y     ( isqrt_c_res )
    );

    // Pipelined variables

    logic [31:0] fifo_b_data;

    flip_flop_fifo_with_counter #(.width(32), .depth(N)) i_fifo_b
    (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .push       ( arg_vld     ),
        .pop        ( isqrt_c_vld ),
        .write_data ( b           ),
        .read_data  ( fifo_b_data )
        // .empty      (),
        // .full       (),
    );

    //----------------------------------------------------------------------------
    // Stage 2: isqrt b
    //----------------------------------------------------------------------------

    logic        isqrt_bc_vld;
    logic [15:0] isqrt_bc_res;

    isqrt #(.n_pipe_stages(N)) i_isqrt_bc
    (
        .clk   ( clk                       ),
        .rst   ( rst                       ),
        .x_vld ( isqrt_c_vld               ),
        .x     ( fifo_b_data + isqrt_c_res ),
        .y_vld ( isqrt_bc_vld              ),
        .y     ( isqrt_bc_res              )
    );

    // Pipelined variables

    logic [31:0] fifo_a_data;

    flip_flop_fifo_with_counter #(.width(32), .depth(2 * N)) i_fifo_a
    (
        .clk        ( clk          ),
        .rst        ( rst          ),
        .push       ( arg_vld      ),
        .pop        ( isqrt_bc_vld ),
        .write_data ( a            ),
        .read_data  ( fifo_a_data  )
        // .empty      (),
        // .full       (),
    );

    //----------------------------------------------------------------------------
    // Stage 3: isqrt a
    //----------------------------------------------------------------------------

    logic        isqrt_abc_vld;
    logic [15:0] isqrt_abc_res;

    isqrt #(.n_pipe_stages(N)) i_isqrt_abc
    (
        .clk   ( clk                        ),
        .rst   ( rst                        ),
        .x_vld ( isqrt_bc_vld               ),
        .x     ( fifo_a_data + isqrt_bc_res ),
        .y_vld ( isqrt_abc_vld              ),
        .y     ( isqrt_abc_res              )
    );

    // Output logic

    assign res = res_vld ? isqrt_abc_res : 'x;
    assign res_vld = isqrt_abc_vld;

endmodule
