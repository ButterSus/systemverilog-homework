//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

// A non-parameterized module
// that implements the signed multiplication of 4-bit numbers
// which produces 8-bit result

module signed_mul_4
(
  input  signed [3:0] a, b,
  output signed [7:0] res
);

  assign res = a * b;

endmodule

// A parameterized module
// that implements the unsigned multiplication of N-bit numbers
// which produces 2N-bit result

module unsigned_mul
# (
  parameter n = 8
)
(
  input  [    n - 1:0] a, b,
  output [2 * n - 1:0] res
);

  assign res = a * b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

// Task:
//
// Implement a parameterized module
// that produces either signed or unsigned result
// of the multiplication depending on the 'signed_mul' input bit.

module signed_or_unsigned_mul
# (
  parameter n = 8
)
(
  input  [    n - 1:0] a, b,
  input                signed_mul,
  output [2 * n - 1:0] res
);

  // Based on: https://en.wikipedia.org/wiki/Binary_multiplier#Signed_integers
  // I even needed some math with equations here lol.

  logic [2 * n - 1:0] tmp_prod;
  assign tmp_prod = a * b;

  assign res [    n - 1:0] = tmp_prod [n - 1:0];
  assign res [2 * n - 1:n] = 
    tmp_prod [2 * n - 1:n] - (
        (b & { n { a [n - 1] & signed_mul } }) 
      + (a & { n { b [n - 1] & signed_mul } })
    );

endmodule
