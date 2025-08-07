//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module fibonacci
(
  input               clk,
  input               rst,
  output logic [15:0] num
);

  logic [15:0] num2;

  always_ff @ (posedge clk)
    if (rst)
      { num, num2 } <= { 16'd1, 16'd1 };
    else
      { num, num2 } <= { num2, num + num2 };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module fibonacci_2
(
  input               clk,
  input               rst,
  output logic [15:0] num,
  output logic [15:0] num2
);

  // Task:
  // Implement a module that generates two fibonacci numbers per cycle

  always_ff @ (posedge clk)
    // The most intuitive thought that comes to mind is add new 3rd/4th
    // variables, however it's completely unnecessary in this case, since we
    // have enough context from any 2 sequenced numbers to generate next ones.
    if (rst) begin
      num  <= 16'd1;
      num2 <= 16'd1;
    end
    else begin
      num  <= num + num2;
      num2 <= num + { num2 [14:0], 1'b0 };
    end

endmodule
