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

    // I'll prioritize using as least inner modules as possible. Therefore,
    // we'll need one instance for each float operation of all kinds:
    // multiplication, subtraction, respectively f_mult and f_sub.

    // (I suppose we shouldn't instantiate wally_fpu, even though it could
    // have saved resources.)

    // Algorithm steps:
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

    // Instead of creating separate FSM for requesting packets, we'll merge its
    // states into main FSM, also note that one request state is merged with
    // IDLE state. Also for this specific case I decided to use uppercase enum
    // values convention since otherwise names will be too long.

    // Main (+Request) FSM states
    enum logic [2:0]
    {
        IDLE,  // replaces REQ_MULT_BB
        REQ_MULT_AC,  // also waits for BB and AC
        WAIT_SUB,
        DONE
    }
    state, new_state;

    // Track FSM states for pipelined multiplication
    enum logic [1:0]
    {
        TRACK_MULT_BB,
        TRACK_MULT_AC,
        TRACK_DONE
    }
    track_mult_state, new_track_mult_state;

    // State logic

    always_comb begin : new_state_logic
        new_state = state;

        case (state)
            // We need to check if we received valid arguments before or now,
            // and if multiplier is not busy.
            IDLE : 
                if ((
                    valid_captured_flag || arg_vld
                ) && !f_mult_busy)
                    new_state = REQ_MULT_AC;

            // We need to check if we finish tracking multiplier output now
            // finished it before, and if subtractor is not busy.
            REQ_MULT_AC :
                if (f_mult_vld && (
                    (track_mult_state == TRACK_MULT_BB) ||
                    (track_mult_state == TRACK_MULT_AC)
                ) && f_mult_err)
                    new_state = DONE;
                else if ((
                    (track_mult_state == TRACK_MULT_AC) && f_mult_vld ||
                    (track_mult_state == TRACK_DONE)
                ) && !f_sub_busy)
                    new_state = WAIT_SUB;

            // We don't need to check if anything is not busy, so transition
            // is always possible and there is no need in latching.
            WAIT_SUB :
                if (f_sub_vld && f_sub_err)
                    new_state = DONE;
                else if (f_sub_vld)
                    new_state = DONE;

            DONE :
                new_state = IDLE;
        endcase
    end

    always_comb begin : new_track_mult_state_logic
        new_track_mult_state = track_mult_state;

        case (track_mult_state)
            TRACK_MULT_BB : if (f_mult_vld)
                new_track_mult_state = TRACK_MULT_AC;
            TRACK_MULT_AC : if (f_mult_vld)
                new_track_mult_state = TRACK_DONE;
            TRACK_DONE : if ((state == IDLE) && (
                valid_captured_flag || arg_vld
            ) && !f_mult_busy)
                new_track_mult_state = TRACK_MULT_BB;
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= IDLE;
        else
            state <= new_state;

    always_ff @ (posedge clk)
        if (rst)
            track_mult_state <= TRACK_DONE;
        else
            track_mult_state <= new_track_mult_state;

    // Module instantiations

    logic [FLEN - 1:0] f_mult_a, f_mult_b, f_mult_res;
    logic f_mult_arg_vld, f_mult_vld, f_mult_busy, f_mult_err;

    f_mult i_fmult
    (
        .clk        ( clk            ),
        .rst        ( rst            ),
        .a          ( f_mult_a       ),
        .b          ( f_mult_b       ),
        .up_valid   ( f_mult_arg_vld ),
        .res        ( f_mult_res     ),
        .down_valid ( f_mult_vld     ),
        .busy       ( f_mult_busy    ),
        .error      ( f_mult_err     )
    );

    logic [FLEN - 1:0] f_sub_a, f_sub_b, f_sub_res;
    logic f_sub_arg_vld, f_sub_vld, f_sub_busy, f_sub_err;

    f_sub i_fsub
    (
        .clk        ( clk           ),
        .rst        ( rst           ),
        .a          ( f_sub_a       ),
        .b          ( f_sub_b       ),
        .up_valid   ( f_sub_arg_vld ),
        .res        ( f_sub_res     ),
        .down_valid ( f_sub_vld     ),
        .busy       ( f_sub_busy    ),
        .error      ( f_sub_err     )
    );

    // Luckily, there is no need for FIFO to handle back pressure since this
    // is FSM.

    // Datapath : Loading

    logic valid_emitted_flag;

    always_ff @ (posedge clk)
        if (rst)
            valid_emitted_flag <= 1'b0;
        else 
            case (state)
                DONE :
                    valid_emitted_flag <= 1'b0;
                REQ_MULT_AC : if (!f_mult_busy)
                    valid_emitted_flag <= 1'b1;
            endcase

    // My verilator tells me it can't find definition of variable NE, NF
    // So it doesn't dump me any warnings

    logic            ac_l_sign,     ac4_l_sign;
    logic [NE - 1:0] ac_l_exponent, ac4_l_exponent;
    logic [NF - 1:0] ac_l_fraction, ac4_l_fraction;

    always_comb begin : ac_l_extract
        ac_l_sign     = ac_l [FLEN - 1];
        ac_l_exponent = ac_l [FLEN - 2:NF];
        ac_l_fraction = ac_l [NF - 1:0];
    end

    always_comb begin : ac4_l_logic
        ac4_l_sign     = ac_l_sign;
        ac4_l_exponent = ac_l_exponent;
        ac4_l_fraction = ac_l_fraction;

        // Handle special cases
        if (ac_l_exponent == { NE{1'b0} }) begin
            if (ac_l_fraction == { NF{1'b0} })
                // Zero
                /* ac4_l_exponent = ac_l_exponent */;  // Default
            else begin
                // Denormalized (Undefined)
                ac4_l_exponent = { NF{1'bx} };
                ac4_l_fraction = { NF{1'bx} };
            end
        end else if (ac_l_exponent == { NE{1'b1} }) begin
            if (ac_l_fraction == { NF{1'b0} })
                // Infinity
                /* ac4_l_exponent = ac_l_exponent */;  // Default
            else
                // NAN
                /* ac4_l_exponent = ac_l_exponent */;  // Propagate
        end else begin
            logic [NE:0] temp_exponent;

            temp_exponent = { 1'b0, ac_l_exponent } + 2'd2;

            if (temp_exponent >= { NE{1'b1} }) begin
                // Overflow to infinity
                ac4_l_exponent = { NE{1'b1} };
                ac4_l_fraction = { NF{1'b0} };
            end else
                ac4_l_exponent = temp_exponent [NE - 1:0];
        end
    end

    assign ac4_l = { ac4_l_sign, ac4_l_exponent, ac4_l_fraction };

    always_comb begin : f_mult_load
        f_mult_a = 'x;
        f_mult_b = 'x;

        f_mult_arg_vld = 1'b0;

        case (state)
            IDLE : begin
                f_mult_a = b_l;
                f_mult_b = b_l;

                f_mult_arg_vld = (valid_captured_flag || arg_vld)
                                 && !f_mult_busy;
            end

            REQ_MULT_AC : begin
                f_mult_a = a_reg;
                f_mult_b = c_reg;

                // Emitted flag prevents from sending multiple requests
                f_mult_arg_vld = !valid_emitted_flag && !f_mult_busy;
            end
        endcase
    end

    always_comb begin : f_sub_load
        f_sub_a = 'x;
        f_sub_b = 'x;

        f_sub_arg_vld = 1'b0;

        case (state)
            REQ_MULT_AC : begin
                f_sub_a = bb_l;
                f_sub_b = ac4_l;

                f_sub_arg_vld = (
                    (track_mult_state == TRACK_MULT_AC) && f_mult_vld ||
                    (track_mult_state == TRACK_DONE)
                ) && !f_sub_busy;
            end
        endcase
    end

    // Datapath : Storing

    logic [FLEN - 1:0] a_reg, b_l, c_reg,
                       bb_l, ac_l, ac4_l,  // l stands for latch
                       res_reg;
    logic valid_captured_flag;

    always_ff @ (posedge clk)
        if (rst)
            valid_captured_flag <= 1'b0;
        else
            case (state)
                // We need it only in IDLE state, but it's just a coincidence and
                // if formula was more complex, there would be more states.
                IDLE : if (arg_vld)
                    valid_captured_flag <= f_mult_busy;
            endcase

    // NOTE: Friendly reminder why SystemVerilog developers generally
    // prefer always_ff over always_latch when possible :

    // "In ASIC design, latches are generally not cheaper than flip-flops.
    // While latches can use fewer gates and potentially require less area, 
    // making them theoretically cheaper, the complexities of testing and 
    // timing closure in a latch-based design often negate any initial cost 
    // savings. Flip-flops are preferred in most ASIC designs due to their 
    // synchronous nature, which simplifies timing analysis and testing".

    // In this case, I intentionally want to store and use output at the same
    // time. Latches are perfect for this.

    always_ff @ (posedge clk)
        case (state)
            IDLE : if (arg_vld) begin
                a_reg <= a;
                c_reg <= c;
            end
        endcase

    always_latch
        case (state)
            IDLE : if (arg_vld)
                b_l = b;
            REQ_MULT_AC : if (f_mult_vld)
                case (track_mult_state)
                    TRACK_MULT_BB : begin
                        bb_l = f_mult_res;
                        err = f_mult_err;
                    end
                    TRACK_MULT_AC : begin
                        ac_l = f_mult_res;
                        err = f_mult_err;
                    end
                endcase
            WAIT_SUB : if (f_sub_vld) begin
                res_reg = f_sub_res;
                err = f_sub_err;
            end
        endcase

    // Output logic

    assign res = res_vld ? res_reg : 'x;
    assign res_negative = res_vld ? res_reg [FLEN - 1] : 'x;
    assign res_vld = (state == DONE);
    assign busy = (state != IDLE) && !valid_captured_flag;

endmodule
