//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    // I'll prioritize using least amount of inner modules.
    // Need one instance for each float operation of all kinds:
    // multiplication, subtraction: respectively f_mult and f_sub.

    // I suppose we shouldn't instantiate wally_fpu, even though f_mult and
    // f_sub are just wally_fpu wrappers.

    // Computation steps:
    // 1. Compute b * b.
    // 2. Compute 4 * a * c. Multiplication by 4 is easy as long as we are
    // able to shift exponent. But we know exact bits slice of exponent so
    // that's okay.
    // 3. Compute (b * b) - (4 * a * c).
    
    // Since modules are pipelined, it'll make sense to use request-track FSMs
    // design, meaning additional FSM is needed.

    // The idea is that we need 2 FSMs: One will send requests when possible,
    // independent on whether we received packets or not.
    // Other will receive packets.

    // I decided to simplify task, by ignoring `busy` output of FPU.
    // Even though initial solution was, therefore, much more complex

    // Instead of creating separate FSM for requesting packets, we'll merge its
    // states into main FSM, also note that one request state is merged with
    // IDLE state. Also for this specific case I decided to use uppercase enum
    // values convention since otherwise names will be too long.

    // Main (+Request) FSM states
    enum logic [1:0]
    {
        IDLE,  // replaces REQ_MULT_BB
        REQ_MULT_AC,
        WAIT_MULT,
        WAIT_SUB
    }
    state, new_state;

    // Track FSM states for pipelined multiplication
    enum logic [1:0]
    {
        TRACK_IDLE,
        TRACK_MULT_BB,
        TRACK_MULT_AC
    }
    track_mult_state, new_track_mult_state;

    // Error logic

    logic next_err;
    assign next_err = f_mult_vld && (f_mult_err === 1'b1) || f_sub_vld && (f_sub_err === 1'b1);

    // State logic

    always_comb begin
        new_state = state;

        case (state)
            IDLE : if (arg_vld)
                new_state = REQ_MULT_AC;

            REQ_MULT_AC :
                new_state = WAIT_MULT;

            WAIT_MULT : if ((track_mult_state == TRACK_MULT_AC) && f_mult_vld)
                new_state = WAIT_SUB;

            WAIT_SUB : if (f_sub_vld)
                new_state = IDLE;
        endcase

        if (next_err)
            new_state = IDLE;
    end

    always_comb begin
        new_track_mult_state = track_mult_state;

        case (track_mult_state)
            TRACK_IDLE : if ((state == IDLE) && arg_vld)
                new_track_mult_state = TRACK_MULT_BB;

            TRACK_MULT_BB : if (f_mult_vld)
                new_track_mult_state = TRACK_MULT_AC;

            TRACK_MULT_AC : if (f_mult_vld)
                new_track_mult_state = TRACK_IDLE;
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= IDLE;
        else
            state <= new_state;

    always_ff @ (posedge clk)
        if (rst)
            track_mult_state <= TRACK_IDLE;
        else
            track_mult_state <= new_track_mult_state;

    // Module instantiations

    logic [FLEN - 1:0] f_mult_a, f_mult_b, f_mult_res;
    logic f_mult_arg_vld, f_mult_vld, /* f_mult_busy, */ f_mult_err;

    f_mult i_fmult
    (
        .clk        ( clk            ),
        .rst        ( rst            ),
        .a          ( f_mult_a       ),
        .b          ( f_mult_b       ),
        .up_valid   ( f_mult_arg_vld ),
        .res        ( f_mult_res     ),
        .down_valid ( f_mult_vld     ),
        /* .busy       ( f_mult_busy    ), */
        .error      ( f_mult_err     )
    );

    logic [FLEN - 1:0] f_sub_a, f_sub_b, f_sub_res;
    logic f_sub_arg_vld, f_sub_vld, /* f_sub_busy, */ f_sub_err;

    f_sub i_fsub
    (
        .clk        ( clk           ),
        .rst        ( rst           ),
        .a          ( f_sub_a       ),
        .b          ( f_sub_b       ),
        .up_valid   ( f_sub_arg_vld ),
        .res        ( f_sub_res     ),
        .down_valid ( f_sub_vld     ),
        /* .busy       ( f_sub_busy    ), */
        .error      ( f_sub_err     )
    );

    // Datapath : Loading

    // My verilator tells me it can't find definition of variable NE, NF
    // So it doesn't dump me any warnings

    logic            ac_sign,     ac4_sign;
    logic [NE - 1:0] ac_exponent, ac4_exponent;
    logic [NF - 1:0] ac_fraction, ac4_fraction;

    always_comb begin
        { ac_sign, ac_exponent, ac_fraction } = ((track_mult_state == TRACK_MULT_AC) && f_mult_vld)
            ? { f_mult_res [FLEN - 1], f_mult_res [FLEN - 2:NF], f_mult_res [NF - 1:0] }
            : { 'x, 'x, 'x };
    end

    always_comb begin
        ac4_sign     = ac_sign;
        ac4_exponent = ac_exponent;
        ac4_fraction = ac_fraction;

        // Handle special cases
        if (ac_exponent == { NE {1'b0} }) begin
            // Zero
            if (ac_fraction == { NF {1'b0} }) /* ac4_exponent = ac_exponent */;  // Default

            // Denormalized (Undefined)
            else begin
                ac4_exponent = { NF {1'bx} };
                ac4_fraction = { NF {1'bx} };
            end
        end
        else if (ac_exponent == { NE {1'b1} }) begin
            // Infinity
            if (ac_fraction == { NF {1'b0} }) /* ac4_exponent = ac_exponent */;  // Default

            // NAN
            else /* ac4_exponent = ac_exponent */;  // Propagate
        end
        else begin
            logic [NE:0] temp_exponent;

            temp_exponent = { 1'b0, ac_exponent } + 2'd2;

            if (temp_exponent >= { NE {1'b1} }) begin
                // Overflow to infinity
                ac4_exponent = { NE {1'b1} };
                ac4_fraction = { NF {1'b0} };
            end
            else ac4_exponent = temp_exponent [NE - 1:0];
        end
    end

    assign ac4 = { ac4_sign, ac4_exponent, ac4_fraction };

    always_comb begin
        f_mult_a = 'x;
        f_mult_b = 'x;

        f_mult_arg_vld = 1'b0;

        case (state)
            IDLE : begin
                f_mult_a = b;
                f_mult_b = b;

                f_mult_arg_vld = arg_vld;
            end

            REQ_MULT_AC : begin
                f_mult_a = a_reg;
                f_mult_b = c_reg;

                f_mult_arg_vld = 1'b1;
            end
        endcase
    end

    always_comb begin
        f_sub_a = 'x;
        f_sub_b = 'x;

        f_sub_arg_vld = 1'b0;

        case (state)
            WAIT_MULT : begin
                f_sub_a = bb_or_res_reg;
                f_sub_b = ac4;

                f_sub_arg_vld = (track_mult_state == TRACK_MULT_AC) && f_mult_vld;
            end
        endcase
    end

    // Datapath : Storing

    logic [FLEN - 1:0] a_reg, c_reg, bb_or_res_reg, ac4;

    always_ff @ (posedge clk)
        case (state)
            IDLE : if (arg_vld) begin
                a_reg <= a;
                c_reg <= c;
            end

            WAIT_SUB : if (f_sub_vld) begin
                bb_or_res_reg <= f_sub_res;
            end
        endcase

    always_ff @ (posedge clk)
        case (track_mult_state)
            TRACK_MULT_BB : if (f_mult_vld) begin
                bb_or_res_reg <= f_mult_res;
            end
        endcase

    // Output logic

    always_ff @ (posedge clk)
        if (state != IDLE || arg_vld)
            err <= next_err;

    always_ff @ (posedge clk)
        if (rst)
            res_vld <= 1'b0;
        else
            res_vld <= ((state == WAIT_SUB) && f_sub_vld
                || (state != IDLE || arg_vld) && next_err);

    assign res = res_vld ? bb_or_res_reg : 'x;
    assign res_negative = res_vld ? bb_or_res_reg [FLEN - 1] : 'x;
    assign busy = (state != IDLE);

endmodule
