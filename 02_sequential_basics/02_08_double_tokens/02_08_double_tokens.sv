//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens (
    input        clk,
    input        rst,
    input        a,
    output       b,
    output logic overflow  // It can be used as a register
);
  // Task:
  // Implement a serial module that doubles each incoming token '1' two times.
  // The module should handle doubling for at least 200 tokens '1' arriving in a row.
  //
  // In case module detects more than 200 sequential tokens '1', it should assert
  // an overflow error. The overflow error should be sticky. Once the error is on,
  // the only way to clear it is by using the "rst" reset signal.
  //
  // Note:
  // Check the waveform diagram in the README for better understanding.
  //
  // Example:
  // a -> 10010011000110100001100100
  // b -> 11011011110111111001111110

  // It's not a good idea to use enum here, instead using logic [8:0]
  logic [8:0] ones_cnt;

  assign b = (~overflow) & ((a) | (ones_cnt != 8'd0));

  always_ff @(posedge clk) begin
    if (rst) begin
      overflow <= 1'b0;
      ones_cnt <= 8'd0;
    end
    if (ones_cnt == 8'd200) overflow <= 1'b1;  // Sticky
    else if (a) ones_cnt <= ones_cnt + 1;
    else if (~a & ones_cnt) ones_cnt <= ones_cnt - 1;
  end
endmodule
