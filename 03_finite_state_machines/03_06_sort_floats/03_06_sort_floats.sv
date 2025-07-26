//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic res_u0_le_u1,
          res_u0_le_u2,
          res_u1_le_u2;

    logic [2:0] res_err;

    f_less_or_equal i0_floe
    (
        .a   ( unsorted [0] ),
        .b   ( unsorted [1] ),
        .res ( res_u0_le_u1 ),
        .err ( res_err [0]  )
    );

    f_less_or_equal i1_floe
    (
        .a   ( unsorted [0] ),
        .b   ( unsorted [2] ),
        .res ( res_u0_le_u2 ),
        .err ( res_err [1]  )
    );

    f_less_or_equal i2_floe
    (
        .a   ( unsorted [1] ),
        .b   ( unsorted [2] ),
        .res ( res_u1_le_u2 ),
        .err ( res_err [2]  )
    );

    // Index sorting

    logic [1:0] sidx0, sidx1, sidx2;

    always_comb begin
        case ({ res_u0_le_u1, res_u0_le_u2, res_u1_le_u2 })
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
    end

    // Output logic

    assign err = ( |res_err );

    assign sorted [0] = unsorted [sidx0];
    assign sorted [1] = unsorted [sidx1];
    assign sorted [2] = unsorted [sidx2];

endmodule
