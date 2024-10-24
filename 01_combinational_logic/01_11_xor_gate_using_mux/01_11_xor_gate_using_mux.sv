//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  mux notgate(
    .d0(1'b1),
    .d1(1'b0),
    .sel(a),
    .y(not_a)
  );
  mux inst(
    .d0(a),
    .d1(not_a),
    .sel(b),
    .y(o)
  );




endmodule
