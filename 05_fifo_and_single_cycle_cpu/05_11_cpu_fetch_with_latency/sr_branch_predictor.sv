//
// Modified in 2025 by Eduard Krivosapkin
// for systemverilog-homework solution.
//

`include "sr_cpu.svh"

module sr_branch_predictor (
    input               clk,
    input               rst,
    input        [31:0] pc,
    input        [31:0] pcPlus4,
    output       [31:0] predicted_pc,   // in this case: PC + 4
    output logic        use_prediction  // mux select: 0 = PC, 1 = predicted PC
);

  assign predicted_pc = pcPlus4;
  assign use_prediction = (last_address == pc) && pc_vld;

  // Previous cycle tracking for comparison
  logic [31:0] last_address;

  always_ff @ (posedge clk)
    last_address <= use_prediction ? predicted_pc : pc;

  // Initial PC state
  logic pc_vld;

  always_ff @ (posedge clk)
    if (rst)
      pc_vld <= 1'b0;
    else
      pc_vld <= 1'b1;

endmodule
