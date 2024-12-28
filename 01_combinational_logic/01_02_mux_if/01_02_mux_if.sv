//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1
(
  input        [3:0] d0, d1,
  input              sel,
  output logic [3:0] y
);

  always_comb
    if (sel)
      y = d1;
    else
      y = d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input        [3:0] d0, d1, d2, d3,
  input        [1:0] sel,
  output logic [3:0] y
);
  // Task:
  // Using code for mux_2_1 as an example,
  // write code for 4:1 mux using the "if" statement
  always_comb begin
    if      ( sel == 2'd0) y <= d0;
    else if ( sel == 2'd1) y <= d1;
    else if ( sel == 2'd2) y <= d2;
    else if ( sel == 2'd3) y <= d3;
    else y <= 4'b0000;
  end

  // always_comb begin
  //   if(sel[1] == 1'b0) begin
  //     if(sel[0] == 1'b0) begin
  //       y <= d0;
  //     end else begin
  //       y <= d1;
  //     end
  //   end else begin 
  //     if(sel[0] == 1'b0) begin
  //       y <= d2;
  //     end else begin
  //       y <= d3;
  //     end
  //   end
  // end
  
endmodule
