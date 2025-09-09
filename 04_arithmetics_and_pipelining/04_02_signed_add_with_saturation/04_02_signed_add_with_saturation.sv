//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module add
(
  input  [3:0] a, b,
  output [3:0] sum
);

  assign sum = a + b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module signed_add_with_saturation
(
  input  [3:0] a, b,
  output [3:0] sum
);

  // Task:
  //
  // Implement a module that adds two signed numbers with saturation.
  //
  // "Adding with saturation" means:
  //
  // When the result does not fit into 4 bits,
  // and the arguments are positive,
  // the sum should be set to the maximum positive number.
  //
  // When the result does not fit into 4 bits,
  // and the arguments are negative,
  // the sum should be set to the minimum negative number.

  logic [3:0] tmp_sum;
  logic last_bit_cin, last_bit_cout, overflow;

  assign { last_bit_cin, tmp_sum [2:0] } = a [2:0] + b [2:0];
  assign { last_bit_cout, tmp_sum [3] } = 2'(a [3] + b [3] + last_bit_cin);

  // Last bit cout always shows "correct" sign bit
  assign overflow = last_bit_cin ^ last_bit_cout;

  // Saturation mux
  assign sum = overflow ? { last_bit_cout, { 3 { last_bit_cin } } } : tmp_sum;

  // Explanation in RTL diagram:
  // https://forum.digikey.com/t/n-bit-saturated-math-carry-look-ahead-combinational-adder-design-in-verilog/13364

endmodule
