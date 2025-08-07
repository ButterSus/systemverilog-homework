//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Detection of the "1010" sequence

  // States (F — First, S — Second)
  enum logic[2:0]
  {
     IDLE = 3'b000,
     F1   = 3'b001,
     F0   = 3'b010,
     S1   = 3'b011,
     S0   = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      IDLE: if (  a) new_state = F1;
      F1:   if (~ a) new_state = F0;
      F0:   if (  a) new_state = S1;
            else     new_state = IDLE;
      S1:   if (~ a) new_state = S0;
            else     new_state = F1;
      S0:   if (  a) new_state = S1;
            else     new_state = IDLE;
    endcase

    // verilator lint_on CASEINCOMPLETE

  end

  // Output logic (depends only on the current state)
  assign detected = (state == S0);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Task:
  // Implement a module that detects the "110011" input sequence
  //
  // Hint: See Lecture 3 for details

  // It seems this FSM style is derived from here: http://www.sunburst-design.com/papers/CummingsSNUG2000Boston_FSM.pdf
  // two-always block coding style

  enum logic [2:0]
  {
    // H stands for high
    // L stands for low

    IDLE,  // st_idle
    H0,
    H1,
    L2,
    L3,
    H4,
    H5     // st_done
  }
  state, new_state;

  always_comb begin
    new_state = IDLE;

    // verilator lint_off CASEINCOMPLETE
    case (state)
      IDLE : if ( a) new_state = H0;  // x
      H0   : if ( a) new_state = H1;  // 1x
      H1   : if (~a) new_state = L2;  // 11x
        else new_state = H1;
      L2   : if (~a) new_state = L3;  // 110x
        else new_state = H0;
      L3   : if ( a) new_state = H4;  // 1100x
      H4   : if ( a) new_state = H5;  // 11001x
      H5   : if ( a) new_state = H1;  // 110011x
        else new_state = L2;
    endcase
    // verilator lint_on CASEINCOMPLETE
  end

  // Output logic
  assign detected = (state == H5);

  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule
