module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1,
              buffer  = 1
)
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output logic        res_vld,
    output logic [31:0] res
);

    // Task:
    //
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    localparam fsm_1_impl_1_cycles = 130 / 10;
    localparam fsm_1_impl_2_cycles = 330 / 10;
    localparam fsm_2_cycles        = 490 / 10;

    // Amount of channels
    localparam N = formula == 1 
        ? (impl == 1 ? fsm_1_impl_1_cycles : fsm_1_impl_2_cycles)
        : fsm_2_cycles;

    localparam channel_width = $clog2(N);

    //----------------------------------------------------------------------------
    // Stage 1: Buffering demux output
    //----------------------------------------------------------------------------

    logic [31:0] fsm_a [N], fsm_b [N], fsm_c [N], fsm_res [N];
    logic        fsm_arg_vld [N], fsm_res_vld [N];

    logic [channel_width - 1:0] channel_idx;

    always_ff @ (posedge clk)
        if (rst)
            channel_idx <= '0;
        else
            channel_idx <= channel_idx < N - 1 ? channel_idx + 1 : '0;

    // We can put buffer after demux, based on whether you want
    // to decrease slack or decrease area and power consumption.

    // verilator lint_off VARHIDDEN
    generate
        if (buffer == 1) begin : gen_buffer_after_demux
            always_ff @(posedge clk) begin
                for (int i = 0; i < N; i ++) begin
                    fsm_arg_vld [i] <= '0;
                end

                fsm_a       [channel_idx] <= a;
                fsm_b       [channel_idx] <= b;
                fsm_c       [channel_idx] <= c;
                fsm_arg_vld [channel_idx] <= arg_vld;
            end
        end

        else if (buffer == 2) begin : gen_no_buffer_after_demux
            always_comb begin
                for (int i = 0; i < N; i ++) begin
                    fsm_a       [i] = 'x;
                    fsm_b       [i] = 'x;
                    fsm_c       [i] = 'x;
                    fsm_arg_vld [i] = '0;
                end

                fsm_a       [channel_idx] = a;
                fsm_b       [channel_idx] = b;
                fsm_c       [channel_idx] = c;
                fsm_arg_vld [channel_idx] = arg_vld;
            end
        end

        else begin : gen_invalid_buffer
            $error("Invalid buffer parameter: %d", buffer);
        end
    endgenerate
    // verilator lint_on VARHIDDEN

    //----------------------------------------------------------------------------
    // Stage 2: FSM
    //----------------------------------------------------------------------------

    // Module instantiations

    generate
        genvar i;

        if (formula == 1 && impl == 1) begin : gen_fsm_1_impl_1
            for (i = 0; i < fsm_1_impl_1_cycles; i ++) begin
                formula_1_impl_1_top i_fsm
                (
                    .clk     ( clk             ),
                    .rst     ( rst             ),
                    .arg_vld ( fsm_arg_vld [i] ),
                    .a       ( fsm_a       [i] ),
                    .b       ( fsm_b       [i] ),
                    .c       ( fsm_c       [i] ),
                    .res_vld ( fsm_res_vld [i] ),
                    .res     ( fsm_res     [i] )
                );
            end
        end
        else if (formula == 1 && impl == 2) begin : gen_fsm_1_impl_2
            for (i = 0; i < fsm_1_impl_2_cycles; i ++) begin
                formula_1_impl_2_top i_fsm
                (
                    .clk     ( clk             ),
                    .rst     ( rst             ),
                    .arg_vld ( fsm_arg_vld [i] ),
                    .a       ( fsm_a       [i] ),
                    .b       ( fsm_b       [i] ),
                    .c       ( fsm_c       [i] ),
                    .res_vld ( fsm_res_vld [i] ),
                    .res     ( fsm_res     [i] )
                );
            end
        end
        else if (formula == 2) begin : gen_fsm_2
            for (i = 0; i < fsm_2_cycles; i ++) begin
                formula_2_top i_fsm
                (
                    .clk     ( clk             ),
                    .rst     ( rst             ),
                    .arg_vld ( fsm_arg_vld [i] ),
                    .a       ( fsm_a       [i] ),
                    .b       ( fsm_b       [i] ),
                    .c       ( fsm_c       [i] ),
                    .res_vld ( fsm_res_vld [i] ),
                    .res     ( fsm_res     [i] )
                );
            end
        end
        else begin : gen_invalid_fsm
            $error("Invalid formula parameter: %d", formula);
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

    generate
        // https://www.consulting.amiq.com/2017/05/29/how-to-pack-data-using-systemverilog-streaming-operators/
        if (buffer == 1) begin : gen_buffer_after_mux
            always_ff @ (posedge clk)
                prev_channel_idx <= channel_idx;

            always_ff @ (posedge clk) begin
                // res_vld <= |{>>{fsm_res_vld}};
                res_vld <= |fsm_res_vld_packed;
                res     <= fsm_res [buffer == 1 ? prev_channel_idx : channel_idx];
            end
        end

        else if (buffer == 2) begin : gen_no_buffer_after_mux
            always_comb begin
                // res_vld = |{>>{fsm_res_vld}};
                res_vld = |fsm_res_vld_packed;
                res     = fsm_res [buffer == 1 ? prev_channel_idx : channel_idx];
            end
        end
    endgenerate

    // NOTE: if you set buffer = 2, testbench will fail due to
    // formula_1_impl_1_top not remembering input values (b, c)

endmodule
