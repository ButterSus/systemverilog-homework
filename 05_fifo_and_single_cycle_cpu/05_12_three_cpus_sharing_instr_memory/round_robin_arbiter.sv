module round_robin_arbiter #(
    parameter N = 8
) (
    input                  clk,
    input                  rst,
    input        [N - 1:0] req,
    output logic [N - 1:0] gnt
);

  localparam PTR_WIDTH = $clog2(N);

  logic [PTR_WIDTH - 1:0] ptr;
  logic [PTR_WIDTH - 1:0] next_ptr;
  logic [        N - 1:0] shift_req;
  logic [        N - 1:0] shift_gnt;

  assign shift_req = (req >> ptr) | (req << (N - ptr));

  generate
    genvar i;

    for (i = 0; i < N; i++) begin : gen_shift_gnt
      always_comb begin
        if (i == 0) begin
          shift_gnt[i] = shift_req[i];
        end else begin
          shift_gnt[i] = shift_req[i] && !(|shift_req[i-1:0]);
        end
      end
    end
  endgenerate

  assign gnt = (shift_gnt << ptr) | (shift_gnt >> (N - ptr));

  // verilator lint_off VARHIDDEN
  always_comb begin
    next_ptr = ptr;

    for (int i = 0; i < N; i ++)
      if (gnt [i])
        next_ptr = i != N - 1 ? i + 1 : PTR_WIDTH' (0);
  end
  // verilator lint_on VARHIDDEN

  always_ff @ (posedge clk)
    if (rst)
      ptr <= PTR_WIDTH' (0);
    else
      ptr <= next_ptr;

endmodule
