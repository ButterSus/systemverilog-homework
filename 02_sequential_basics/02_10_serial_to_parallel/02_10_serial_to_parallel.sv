//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel #(
    parameter width = 8
) (
    input clk,
    input rst,

    input serial_valid,
    input serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
  // Task:
  // Implement a module that converts serial data to the parallel multibit value.
  //
  // The module should accept one-bit values with valid interface in a serial manner.
  // After accumulating 'width' bits, the module should assert the parallel_valid
  // output and set the data.
  //
  // Note:
  // Check the waveform diagram in the README for better understanding.

  localparam int cnt_width = $clog2(width);

  logic [    width-1:0] shift_reg;
  logic [cnt_width-1:0] bit_count;

  // Next state signals
  logic [cnt_width-1:0] next_count;
  logic                 word_complete;

  assign word_complete = (bit_count == width - 1) && serial_valid;
  assign next_count = word_complete ? '0 : (serial_valid ? bit_count + 1'b1 : bit_count);

  // Sequential logic
  always_ff @(posedge clk) begin
    if (rst) begin
      shift_reg      <= '0;
      bit_count      <= '0;
      parallel_valid <= '0;
      parallel_data  <= '0;
    end else begin
      bit_count <= next_count;

      if (serial_valid) begin
        shift_reg <= {serial_data, shift_reg[width-1:1]};
      end

      // Output logic
      parallel_valid <= word_complete;
      if (word_complete) begin
        parallel_data <= {serial_data, shift_reg[width-1:1]};
      end
    end
  end

endmodule
