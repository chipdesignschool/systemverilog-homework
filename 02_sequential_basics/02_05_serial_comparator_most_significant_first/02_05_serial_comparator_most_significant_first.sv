//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_comparator_least_significant_first (
    input  clk,
    input  rst,
    input  a,
    input  b,
    output a_less_b,
    output a_eq_b,
    output a_greater_b
);

  logic prev_a_eq_b, prev_a_less_b;

  assign a_eq_b      = prev_a_eq_b & (a == b);
  assign a_less_b    = (~a & b) | (a == b & prev_a_less_b);
  assign a_greater_b = (~a_eq_b) & (~a_less_b);

  always_ff @(posedge clk)
    if (rst) begin
      prev_a_eq_b   <= '1;
      prev_a_less_b <= '0;
    end else begin
      prev_a_eq_b   <= a_eq_b;
      prev_a_less_b <= a_less_b;
    end

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_comparator_most_significant_first (
    input  clk,
    input  rst,
    input  a,
    input  b,
    output a_less_b,
    output a_eq_b,
    output a_greater_b
);

  // Task:
  // Implement a module that compares two numbers in a serial manner.
  // The module inputs a and b are 1-bit digits of the numbers
  // and most significant bits are first.
  // The module outputs a_less_b, a_eq_b, and a_greater_b
  // should indicate whether a is less than, equal to, or greater than b, respectively.
  // The module should also use the clk and rst inputs.
  //
  // See the testbench for the output format ($display task).
  

  logic prev_a_eq_b, prev_a_less_b, prev_a_greater_b;

  assign a_eq_b      = prev_a_eq_b & (a == b);
  // once comparison happen, result is valid until reset
  assign a_less_b    = ((~a & b) | (prev_a_less_b)) & (~a_greater_b);
  assign a_greater_b = (~a_eq_b) & (~a_less_b);

  always_ff @(posedge clk)
    if (rst) begin
      prev_a_eq_b   <= '1;
      prev_a_less_b <= '0;
      prev_a_greater_b <= '0;
    end else begin
      prev_a_eq_b   <= a_eq_b;
      prev_a_less_b <= a_less_b;
      prev_a_greater_b <= a_greater_b;
    end


  // // compare current result
  // logic a_eq_b_cur, a_greater_b_cur, a_less_b_cur, comp_happened;
  // // store first inequlaty happen
  // logic a_less_b_end, a_eq_b_end, a_greater_b_end;
  // assign a_eq_b_end = a_eq_b_cur && ~(a_less_b_end || a_greater_b_end);

  // assign a_eq_b      = a_eq_b_end;
  // assign a_less_b    = a_less_b_end;
  // assign a_greater_b = a_greater_b_end;

  // // compare cuurent bit
  // assign a_less_b_cur = (~a & b);
  // assign a_eq_b_cur = (a == b);
  // assign a_greater_b_cur = (~a_less_b_cur) & (~a_eq_b_cur);
  // // since comparison is MSB first, first comp_happen has to be last comp_happened
  // assign comp_happened = a_less_b_cur || a_greater_b_cur;
  // logic comp_last;

  // always_latch begin
  //   if (rst) begin
  //     a_less_b_end    <= 'b0;
  //     a_greater_b_end <= 'b0;
  //     comp_last <= 'b0;
  //   end else begin
  //     if (comp_happened && ~comp_last) begin
  //       a_less_b_end <= a_less_b_cur;
  //       a_greater_b_end <= a_greater_b_cur;
  //       comp_last <= 1;
  //     end
  //   end
  // end

endmodule
