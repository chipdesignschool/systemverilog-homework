module fixed_arbiter #(
    parameter N = 2  // request width
) (
    input  [N-1:0] requests,
    output [N-1:0] grants
);
    // ============================================================
    // ====================== select variant ======================
    // ============================================================
    // takes up to N steps, as needs previous req to 
    // generate next req. May result to big WNS, though looks tidy
    //`define SLOW_BUT_CONCISE 

    // takes from log2(N)+1 up to N steps, depending on
    // how multiple ors are generated 
    `define FAST


`ifdef SLOW_BUT_CONCISE
    logic [N-1:0] higher_pri_reqs;
    assign higher_pri_reqs[N-1:1] = higher_pri_reqs[N-2:0] | requests[N-2:0];
    assign higher_pri_reqs[0] = 1'b0;
    assign grants[N-1:0] = requests[N-1:0] & ~higher_pri_reqs[N-1:0];
`endif

`ifdef FAST
    // ================== Generate with OR ==================
    // assign grant[0] = req[0];
    // assign grant[1] = req[1] & ~req[0];
    // assign grant[2] = req[2] & ~(req[0] | req[1]);
    // assign grant[3] = req[3] & ~(req[0] | req[1] | req[2]);
    // ================== Generate with AND ==================
    // assign grant[0] = req[0];
    // assign grant[1] = req[1] & ~req[0];
    // assign grant[2] = req[2] & ~req[0] & ~req[1];
    // assign grant[3] = req[2] & ~req[0] & ~req[1] & ~req[2];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin
            if (i == 0) begin
                assign grants[i] = requests[i];
            end else begin
                assign grants[i] = requests[i] & (&(~requests[i-1:0]));  // 
                // assign grants[i] = requests[i] & ~(|requests[i-1:0]); // less area, 1 step more for WNS
            end
        end
    endgenerate
`endif


endmodule


module round_robin_arbiter_with_2_requests #(
    parameter N = 2  // request width
) (
    input          clk,
    input          rst,
    input  [N-1:0] requests,
    output logic [N-1:0] grants
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
    `define EXACT
    // `define UNIVERSAL

`ifdef EXACT
    logic pointer_req, next_pointer_req;

    always_comb begin
        case (pointer_req)
            1'b0: begin
                if (requests[0]) grants         = 2'b01;
                else if (requests[1]) grants    = 2'b10;
                else grants                     = 2'b00;
            end
            1'b1: begin
                if (requests[1]) grants         = 2'b10;
                else if (requests[0]) grants    = 2'b01;
                else grants                     = 2'b00;
            end
        endcase
    end
    // pointer change logic
    always @(posedge clk) begin
        if (rst) pointer_req <= '0;
        else pointer_req <= next_pointer_req;
    end

    always_comb begin
        next_pointer_req = 2'b00;
        case (grants)
            2'b01: next_pointer_req   = 1'b1;
            2'b10: next_pointer_req   = 1'b0;
            default: next_pointer_req = 1'b0;
        endcase 
    end
`endif

`ifdef UNIVERSAL
    localparam HI = N - 1;

    logic [HI:0] pointerMask, nextPointerMask, maskedReq;
    logic [HI:0] maskedGrant, unmaskedGrant;

    // step 1 mask request
    assign maskedReq = requests & pointerMask;

    // Unmask Grant
    fixed_arbiter #(
        .N(N)
    ) unmaskedArbiter (
        .requests(requests),
        .grants  (unmaskedGrant)
    );
    // Mask Grant
    fixed_arbiter #(
        .N(N)
    ) maskedArbiter (
        .requests(maskedReq),
        .grants  (maskedGrant)
    );
    // MUX output
    assign grants = (maskedReq == 'b0) ? unmaskedGrant : maskedGrant;

    // shift pointer (change pointer mask directly, without using external pointer)
    always_comb begin
        reg found;
        if (grants == 'd0) begin
            nextPointerMask = pointerMask;
        end else begin
            nextPointerMask = {N{1'b1}};
            found = 0;
            for (int i = 0; i < N; i++) begin
                if (!found) begin
                    nextPointerMask[i] = 1'b0;
                    if (grants[i]) found = 1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) pointerMask <= '1;
        else pointerMask <= nextPointerMask;
    end
`endif

endmodule
