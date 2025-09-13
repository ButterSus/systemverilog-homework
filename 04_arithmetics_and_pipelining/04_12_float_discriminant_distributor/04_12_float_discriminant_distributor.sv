module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.

    localparam N = 80 / 10;
    localparam channel_width = $clog2(N);

    //----------------------------------------------------------------------------
    // Stage 1: Buffering demux output
    //----------------------------------------------------------------------------

    logic [63:0] fsm_a [N], fsm_b [N], fsm_c [N], fsm_res [N];
    logic        fsm_arg_vld [N], fsm_res_vld [N], fsm_res_negative [N],
                 fsm_err [N]/* , fsm_busy [N] */;

    logic [channel_width - 1:0] channel_idx;

    always_ff @ (posedge clk)
        if (rst)
            channel_idx <= '0;
        else
            channel_idx <= channel_idx < N - 1 ? channel_idx + 1 : '0;

    // verilator lint_off VARHIDDEN
    always_ff @(posedge clk) begin
        for (int i = 0; i < N; i ++) begin
            fsm_arg_vld [i] <= '0;
        end

        fsm_a       [channel_idx] <= a;
        fsm_b       [channel_idx] <= b;
        fsm_c       [channel_idx] <= c;
        fsm_arg_vld [channel_idx] <= arg_vld;
    end
    // verilator lint_on VARHIDDEN

    //----------------------------------------------------------------------------
    // Stage 2: FSM
    //----------------------------------------------------------------------------

    // Module instantiations

    generate
        genvar i;

        for (i = 0; i < N; i ++) begin
            float_discriminant i_fsm
            (
                .clk          ( clk                  ),
                .rst          ( rst                  ),
                .arg_vld      ( fsm_arg_vld      [i] ),
                .a            ( fsm_a            [i] ),
                .b            ( fsm_b            [i] ),
                .c            ( fsm_c            [i] ),
                .res_vld      ( fsm_res_vld      [i] ),
                .res          ( fsm_res          [i] ),
                .res_negative ( fsm_res_negative [i] ),
                .err          ( fsm_err          [i] )
                /* .busy         ( fsm_busy         [i] ) */
            );
        end
    endgenerate

    //----------------------------------------------------------------------------
    // Stage 3: Buffering mux output
    //----------------------------------------------------------------------------

    // Again: Optional

    logic [N - 1:0] fsm_res_vld_packed;

    // verilator lint_off VARHIDDEN
    always_comb
        for (int i = 0; i < N; i++) begin
            fsm_res_vld_packed[i] = fsm_res_vld[i];
        end
    // verilator lint_on VARHIDDEN

    logic [channel_width - 1:0] prev_channel_idx;

    always_ff @ (posedge clk)
        prev_channel_idx <= channel_idx;

    // Output logic

    always_ff @ (posedge clk) begin
        res_vld      <= |fsm_res_vld_packed;
        res          <= fsm_res          [prev_channel_idx];
        res_negative <= fsm_res_negative [prev_channel_idx];
        err          <= fsm_err          [prev_channel_idx];
    end

    assign busy = '0;

endmodule
