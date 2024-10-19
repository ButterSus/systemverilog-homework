//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_4_1_width_2
(
  input  [1:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [1:0] y
);

  assign y = sel [1] ? (sel [0] ? d3 : d2)
                     : (sel [0] ? d1 : d0);

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input  [3:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [3:0] y
);

  // Task:
  // Implement mux_4_1 with 4-bit data
  // using two instances of mux_4_1_width_2 with 2-bit data

  wire [1:0] mux00_out, mux10_out, mux01_out, mux11_out;

  mux_4_1_width_2 mux00 (.d0(d0[1:0]), .d1(d1[1:0]), .sel(sel[0]), .y(mux00_out));
  mux_4_1_width_2 mux10 (.d0(d2[1:0]), .d1(d3[1:0]), .sel(sel[0]), .y(mux10_out));
  mux_4_1_width_2 mux01 (.d0(d0[3:2]), .d1(d1[3:2]), .sel(sel[0]), .y(mux01_out));
  mux_4_1_width_2 mux11 (.d0(d2[3:2]), .d1(d3[3:2]), .sel(sel[0]), .y(mux11_out));

  mux_4_1_width_2 mux0 (.d0(mux00_out), .d1(mux10_out), .sel(sel[1]), .y(y[1:0]));
  mux_4_1_width_2 mux1 (.d0(mux01_out), .d1(mux11_out), .sel(sel[1]), .y(y[3:2]));

endmodule
