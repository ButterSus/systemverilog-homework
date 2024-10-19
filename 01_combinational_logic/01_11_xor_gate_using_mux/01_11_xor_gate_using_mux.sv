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

  wire mux0_out;  // negated a

  mux mux0(.d0(1'b1), .d1(1'b0), .sel(a), .y(mux0_out));
  mux mux1(.d0(a), .d1(mux0_out), .sel(b), .y(o));

endmodule
