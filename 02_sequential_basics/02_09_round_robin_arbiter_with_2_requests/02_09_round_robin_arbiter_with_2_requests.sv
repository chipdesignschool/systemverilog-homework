//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------
module fixed_arbiter # (
  parameter N = 2 // request width
) (
  input  [N-1:0] requests,
  output [N-1:0] grants
);
  //`define SLOW
  `define FAST

  `ifdef SLOW
  logic [N-1:0] higher_pri_reqs;
  assign higher_pri_reqs[N-1:1] = higher_pri_reqs[N-2:0] | requests[N-2:0];
  assign higher_pri_reqs[0] = 1'b0;
  assign grants[N-1:0] = requests[N-1:0] & ~higher_pri_reqs[N-1:0];
  `endif

  `ifdef FAST
  // Generate tree-based OR reduction for higher-priority requests
    wire [N-1:0] mask;
    genvar i, j;

    generate
        for (i = 0; i < N; i = i + 1) begin : mask_gen
            if (i == 0) begin
                assign mask[i] = 1'b1;
            end else begin
                // Use a tree to compute the OR of higher-priority requests
                wire [$clog2(i):0] or_tree;
                assign or_tree[0] = requests[i-1];
                for (j = 1; j <= $clog2(i); j = j + 1) begin : or_tree_gen
                    assign or_tree[j] = or_tree[j-1] | ((i - (1 << (j-1)) >= 0) ? requests[i - (1 << (j-1))] : 1'b0);
                end
                assign mask[i] = ~or_tree[$clog2(i)];
            end
            assign grants[i] = requests[i] & mask[i];
        end
    endgenerate

    // // Function to calculate the ceiling of log base 2
    // function integer clog2;
    //     input integer value;
    //     integer temp;
    //     begin
    //         temp = value - 1;
    //         for (clog2 = 0; temp > 0; clog2 = clog2 + 1)
    //             temp = temp >> 1;
    //     end
    // endfunction
  `endif

endmodule


module round_robin_arbiter_with_2_requests # (
  parameter N = 2  // request width
)
(
  input        clk,
  input        rst,
  input  [N-1:0] requests,
  output [N-1:0] grants
);
  // Task:
  // Implement a "arbiter" module that accepts up to two requests
  // and grants one of them to operate in a round-robin manner.
  //
  // The module should maintain an internal register
  // to keep track of which requester is next in line for a grant.
  //
  // Note:
  // Check the waveform diagram in the README for better understanding.
  //
  // Example:
  // requests -> 01 00 10 11 11 00 11 00 11 11
  // grants   -> 01 00 10 01 10 00 01 00 10 01
  localparam HI = N - 1;
  
  logic[HI:0] pointerMask, nextPointerMask, maskedReq;
  logic[HI:0] maskedGrant, unmaskedGrant;

  // step 1 mask request
  assign maskedReq = requests & pointerMask;

  // Unmask Grant
  fixed_arbiter #(
      .N(N)
  ) unmaskedArbiter(
      .requests(requests),
      .grants(unmaskedGrant)
  );
  // Mask Grant
  fixed_arbiter #(
      .N(N)
  ) maskedArbiter(
      .requests(maskedReq),
      .grants(maskedGrant)
  );

  assign grants = (maskedReq == 'b0) ?  unmaskedGrant : maskedGrant;

  always_comb begin
    reg found;
    if (grants == 'd0) begin
        nextPointerMask = pointerMask;
    end else begin
        nextPointerMask = { N { 1'b1 } };
        found = 0;
        for (int i = 0; i < N; i++) begin
          if(!found)begin 
            nextPointerMask[i] = 1'b0;
            if (grants[i]) found = 1;
          end
        end
    end
  end

  // always @(*) begin
  //     integer i;
  //     reg found;
  //     if (grants == 'd0) begin
  //         nextPointerMask = pointerMask;
  //     end else begin
  //         nextPointerMask = { N { 1'b1 } };
  //         found = 0;
  //         for (i = 0; i < N; i = i + 1) begin
  //             if (!found) begin
  //                 nextPointerMask[i] = 1'b0;
  //                 if (grants[i]) begin
  //                     found = 1;
  //                 end
  //             end
  //         end
  //     end
  // end


  always_ff @(posedge clk) begin
  if (rst) pointerMask <= '1;
  else pointerMask <= nextPointerMask;
  end  

endmodule
