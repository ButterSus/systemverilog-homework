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

module signed_add_with_overflow
(
  input  [3:0] a, b,
  output [3:0] sum,
  output       overflow
);

  // Task:
  //
  // Implement a module that adds two signed numbers
  // and detects an overflow.
  //
  // By "signed" we mean "two's complement numbers".
  // See https://en.wikipedia.org/wiki/Two%27s_complement for details.
  //
  // The 'overflow' output bit should be set to 1
  // when the sum (either positive or negative)
  // of two input arguments does not fit into 4 bits.
  // Otherwise the 'overflow' should be set to 0.

  // "Overflow condition is determined by exclusive or of the carry-in and the
  // carry-out of the most significant bit."

  logic [2:0] partial_sum;
  logic last_bit_cin, last_bit_cout;

  assign { last_bit_cin, partial_sum } = a [2:0] + b [2:0];

  assign { last_bit_cout, sum } = { 2'(a [3] + b [3] + last_bit_cin), partial_sum };
  assign overflow = last_bit_cin ^ last_bit_cout;

endmodule
