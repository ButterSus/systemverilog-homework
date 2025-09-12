//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    // Request FSM
    // ===========

    enum logic [1:0]
    {
        IDLE,  // replaces TX_ISQRT_A
        TX_ISQRT_B,
        TX_ISQRT_C
    }
    state, new_state;

    // State logic

    always_comb begin
        new_state = state;

        // verilator lint_off CASEINCOMPLETE
        case (state)
            IDLE : if (arg_vld)
                new_state = TX_ISQRT_B;
            TX_ISQRT_B :
                new_state = TX_ISQRT_C;
            TX_ISQRT_C :
                new_state = IDLE;
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= IDLE;
        else
            state <= new_state;

    // Datapath : Loading

    always_comb begin
        isqrt_x = 'x;

        isqrt_x_vld = 1'b0;

        // verilator lint_off CASEINCOMPLETE
        case (state)
            IDLE : begin
                isqrt_x = a;
                
                isqrt_x_vld = arg_vld;
            end

            TX_ISQRT_B : begin
                isqrt_x = b_reg;

                isqrt_x_vld = 1'b1;
            end

            TX_ISQRT_C : begin
                isqrt_x = c_reg;

                isqrt_x_vld = 1'b1;
            end
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    // Datapath : Storing

    logic [31:0] b_reg, c_reg;

    always_ff @ (posedge clk)
        // verilator lint_off CASEINCOMPLETE
        case (state)
            IDLE : if (arg_vld) begin
                b_reg <= b;
                c_reg <= c;
            end
        endcase
        // verilator lint_on CASEINCOMPLETE

    // Receive FSM
    // ===========

    enum logic [1:0]
    {
        RX_ISQRT_A,
        RX_ISQRT_B,
        RX_ISQRT_C
    }
    rx_state, new_rx_state;

    // State logic

    always_comb begin
        new_rx_state = rx_state;

        // verilator lint_off CASEINCOMPLETE
        case (rx_state)
            RX_ISQRT_A : if (isqrt_y_vld)
                new_rx_state = RX_ISQRT_B;
            RX_ISQRT_B : if (isqrt_y_vld)
                new_rx_state = RX_ISQRT_C;
            RX_ISQRT_C : if (isqrt_y_vld)
                new_rx_state = RX_ISQRT_A;
        endcase
        // verilator lint_on CASEINCOMPLETE
    end

    always_ff @ (posedge clk)
        if (rst)
            rx_state <= RX_ISQRT_A;
        else
            rx_state <= new_rx_state;

    // Datapath : Storing

    logic [15:0] isqrt_a_reg,
                 isqrt_b_reg;
                 /* isqrt_c_reg; */

    always_ff @ (posedge clk)
        // verilator lint_off CASEINCOMPLETE
        case (rx_state)
            RX_ISQRT_A : if (isqrt_y_vld)
                isqrt_a_reg <= isqrt_y;

            RX_ISQRT_B : if (isqrt_y_vld)
                isqrt_b_reg <= isqrt_y;
        endcase
        // verilator lint_on CASEINCOMPLETE

    logic [17:0] res_reg;

    always_ff @ (posedge clk)
        if ((rx_state == RX_ISQRT_C) && isqrt_y_vld)
            res_reg <= 18'(isqrt_a_reg) + 18'(isqrt_b_reg) + 18'(isqrt_y);

    // Output logic

    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            res_vld <= (rx_state == RX_ISQRT_C) && isqrt_y_vld;

    assign res = res_vld ? 32'(res_reg) : 'x;

endmodule
