//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module fibonacci (
    input               clk,
    input               rst,
    output logic [15:0] num
);

  logic [15:0] num2;

  always_ff @(posedge clk)
    if (rst) {num, num2} <= {16'd1, 16'd1};
    else {num, num2} <= {num2, num + num2};

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module fibonacci_2 (
    input               clk,
    input               rst,
    output logic [15:0] num,
    output logic [15:0] num2
);

  // Task:
  // Implement a module that generates two fibonacci numbers per cycle

  logic [15:0] num3, num4;

  always_ff @(posedge clk)
    if (rst) {num, num2, num3, num4} <= {16'd1, 16'd1, 16'd2, 16'd3};
    else {num, num2, num3, num4} <= {num3, num4, num3 + num4, num3 + (num4 << 1)};

endmodule
