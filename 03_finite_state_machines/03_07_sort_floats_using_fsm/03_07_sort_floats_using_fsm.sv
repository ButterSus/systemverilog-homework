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
        st_comp_u1_le_u2,
        st_done
    }
    state, new_state;

    // State logic

    always_comb begin
        new_state = state;

        case (state)
            st_idle :
                if (f_le_err)
                    new_state = st_done;
                else if (valid_in)
                    new_state = st_comp_u0_le_u2;

            st_comp_u0_le_u2 :
                if (f_le_err)
                    new_state = st_done;
                else
                    new_state = st_comp_u1_le_u2;

            st_comp_u1_le_u2 :
                if (f_le_err)
                    new_state = st_done;
                else
                    new_state = st_done;

            st_done :
                new_state = st_idle;
        endcase
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
                f_le_a = unsorted_reg [0];
                f_le_b = unsorted_reg [2];
            end

            st_comp_u1_le_u2 : begin
                f_le_a = unsorted_reg [1];
                f_le_b = unsorted_reg [2];
            end
        endcase
    end

    // Datapath : Storing

    logic [0:2][FLEN - 1:0] unsorted_reg;
    logic [0:2][FLEN - 1:0] sorted_reg;

    logic res_u0_le_u1_reg,
          res_u0_le_u2_reg;
          /* res_u1_le_u2_reg; */  // Not needed

    always_ff @ (posedge clk)
        case (state)
            st_idle : begin
                if (valid_in) begin
                    unsorted_reg <= unsorted;
                    res_u0_le_u1_reg <= f_le_res;

                    err <= f_le_err;
                end
            end

            st_comp_u0_le_u2 : begin
                res_u0_le_u2_reg <= f_le_res;

                err <= f_le_err;
            end

            st_comp_u1_le_u2 : begin
                sorted_reg [0] <= unsorted_reg [sidx0];
                sorted_reg [1] <= unsorted_reg [sidx1];
                sorted_reg [2] <= unsorted_reg [sidx2];

                err <= f_le_err;
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

    assign sorted = valid_out ? sorted_reg : 'x;
    assign valid_out = (state == st_done);
    assign busy = (state != st_idle);

endmodule
