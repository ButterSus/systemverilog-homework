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

module or_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:

  // Implement or gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  mux inst0 (
    .d0 (a),     // A & ~B
    .d1 (1'b1),  // 1 &  B
    .sel (b),
    .y (o)       // (A & ~B) + (1 & B) = A + B
  );

endmodule
