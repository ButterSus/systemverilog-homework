//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    enum logic [1:0]
    {
        st_idle,  // replaces st_comp_u0_le_u1
        st_comp_u0_le_u2,
        st_comp_u1_le_u2
    }
    state, new_state;

    // State logic

    always_comb begin
        new_state = state;

        case (state)
            st_idle :
                if (valid_in)
                    new_state = st_comp_u0_le_u2;

            st_comp_u0_le_u2 :
                new_state = st_comp_u1_le_u2;

            st_comp_u1_le_u2 :
                new_state = st_idle;
        endcase

        if (f_le_err)
            new_state = st_idle;
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= new_state;

    // Datapath : Loading

    always_comb begin
        f_le_a = 'x;
        f_le_b = 'x;

        case (state)
            st_idle : begin
                f_le_a = unsorted [0];
                f_le_b = unsorted [1];
            end

            st_comp_u0_le_u2 : begin
                f_le_a = tmp_reg [0];
                f_le_b = tmp_reg [2];
            end

            st_comp_u1_le_u2 : begin
                f_le_a = tmp_reg [1];
                f_le_b = tmp_reg [2];
            end
        endcase
    end

    // Datapath : Storing

    logic [0:2][FLEN - 1:0] tmp_reg;

    logic res_u0_le_u1_reg,
          res_u0_le_u2_reg;

    always_ff @ (posedge clk)
        case (state)
            st_idle : begin
                res_u0_le_u1_reg <= 'x;

                if (valid_in) begin
                    tmp_reg <= unsorted;
                    res_u0_le_u1_reg <= f_le_res;
                end
            end

            st_comp_u0_le_u2 : begin
                res_u0_le_u2_reg <= f_le_res;
            end

            st_comp_u1_le_u2 : begin
                tmp_reg [0] <= tmp_reg [sidx0];
                tmp_reg [1] <= tmp_reg [sidx1];
                tmp_reg [2] <= tmp_reg [sidx2];
            end
        endcase

    // Index sorting

    logic [1:0] sidx0, sidx1, sidx2;

    always_comb
        case ({ res_u0_le_u1_reg, res_u0_le_u2_reg, f_le_res })
            3'b000 : begin
                sidx0 = 2'd2;
                sidx1 = 2'd1;
                sidx2 = 2'd0;
            end

            3'b001 : begin
                sidx0 = 2'd1;
                sidx1 = 2'd2;
                sidx2 = 2'd0;
            end

            3'b011 : begin
                sidx0 = 2'd1;
                sidx1 = 2'd0;
                sidx2 = 2'd2;
            end

            3'b100 : begin
                sidx0 = 2'd2;
                sidx1 = 2'd0;
                sidx2 = 2'd1;
            end

            3'b110 : begin
                sidx0 = 2'd0;
                sidx1 = 2'd2;
                sidx2 = 2'd1;
            end

            3'b111 : begin
                sidx0 = 2'd0;
                sidx1 = 2'd1;
                sidx2 = 2'd2;
            end
        endcase

    // Output logic

    always_ff @ (posedge clk)
        if (state != st_idle || valid_in)
            err <= f_le_err;

    always_ff @ (posedge clk)
        if (rst)
            valid_out <= 1'b0;
        else
            valid_out <= (state == st_comp_u1_le_u2 || (state != st_idle || valid_in) && f_le_err);

    assign sorted = valid_out ? tmp_reg : 'x;
    assign busy = (state != st_idle);

endmodule
