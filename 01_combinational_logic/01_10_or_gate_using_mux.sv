`include "../util.sv"

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------

module or_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // TODO

  // Implement or gate using instance(s) of mux,
  // constants 0 and 1, and wire connections


endmodule

//----------------------------------------------------------------------------

module testbench;

  logic a, b, o;
  int i, j;

  or_gate_using_mux inst (a, b, o);

  initial
    begin
      for (i = 0; i <= 1; i++)
      for (j = 0; j <= 1; j++)
      begin
        a = i;
        b = j;

        # 1;

        $display ("TEST %b | %b = %b", a, b, o);

        if (o !== (a | b))
          begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s, %s, %s, %s}", `PH(a), `PH(b), `PH(i), `PH(j));
            $display("++ EXPECTED => {%s}", `PH(a|b));
            $display("++ ACTUAL   => {%s}", `PH(o));
            $finish(1);
          end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

endmodule
