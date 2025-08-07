//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  logic a_n;

  mux i0_mux (
    .d0  ( 1'b1 ),  // 1 & ~A
    .d1  ( 1'b0 ),  // 0 & A
    .sel ( a    ),
    .y   ( a_n  )   // (1 & ~A) + (0 & A) = ~A
  );

  mux i1_mux (
    .d0  ( a   ),  //  A & ~B
    .d1  ( a_n ),  // ~A &  B
    .sel ( b   ),
    .y   ( o   )   // (A & ~B) + (~A & B) = A ^ B
  );

endmodule
