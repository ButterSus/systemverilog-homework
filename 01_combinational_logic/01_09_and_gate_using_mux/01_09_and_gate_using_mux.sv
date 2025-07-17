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

module and_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement and gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  mux inst0 (
    .d0 (1'b0),  // 0 * ~B
    .d1 (a),     // A *  B
    .sel (b),
    .y (o)       // (0 * ~B) + (A * B) = A * B
  );

endmodule
