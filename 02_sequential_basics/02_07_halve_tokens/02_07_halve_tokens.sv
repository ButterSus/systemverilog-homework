//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens (
    input  clk,
    input  rst,
    input  a,
    output b
);
  // Task:
  // Implement a serial module that reduces amount of incoming '1' tokens by half.
  //
  // Note:
  // Check the waveform diagram in the README for better understanding.
  //
  // Example:
  // a -> 110_011_101_000_1111
  // b -> 010_001_001_000_0101

  // States (for readability - can be replaced with logic cnt)
  enum logic {
    PASS_ONE = 1'b0,
    REPLACE_ONE = 1'b1
  } state;

  // Combinational output logic
  assign b = (a) & (state == PASS_ONE);

  // State transition logic
  always_ff @(posedge clk)
    if (rst) state <= REPLACE_ONE;
    else if (a) state <= state == REPLACE_ONE ? PASS_ONE : REPLACE_ONE;
  // ... Or we can do it with cases (I prefered ternary)

endmodule
