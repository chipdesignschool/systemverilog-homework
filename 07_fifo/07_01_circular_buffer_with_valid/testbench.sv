module testbench;

    localparam width = 8, depth = 8;

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic               clk;
    logic               rst;

    logic               in_vld;
    logic [width - 1:0] in_data;

    wire                out_vld;
    wire  [width - 1:0] out_data;

    wire                expected_out_vld;
    wire  [width - 1:0] expected_out_data;

    //--------------------------------------------------------------------------
    // Instantiating reference model

    one_bit_wide_circular_buffer
    # ( .depth (depth) )
    i_shift_reg_expected_vld
    (
        .clk      ( clk               ),
        .rst      ( rst               ),
        .in_data  ( in_vld            ),
        .out_data ( expected_out_vld  )
    );

    circular_buffer
    # ( .width (width), .depth (depth) )
    i_shift_reg_expected_data
    (
        .clk      ( clk                ),
        .rst      ( rst                ),
        .in_data  ( in_data            ),
        .out_data ( expected_out_data  )
    );

    //--------------------------------------------------------------------------
    // Instantiating DUT - Design under Test

    circular_buffer_with_valid
    # ( .width (width), .depth (depth) )
    i_shift_register_with_valid
    (
        .clk       ( clk      ),
        .rst       ( rst      ),
        .in_valid  ( in_vld   ),
        .in_data   ( in_data  ),
        .out_valid ( out_vld  ),
        .out_data  ( out_data )
    );

    //--------------------------------------------------------------------------
    // Driving clk

    initial
    begin
        clk = '1;

        forever #5 clk = ~ clk;
    end

    //------------------------------------------------------------------------
    // Reset

    task reset;

        rst <= 'x;
        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

    endtask

    //--------------------------------------------------------------------------
    // Test ID for error messages

    string test_id;

    initial $sformat (test_id, "%s", `__FILE__);

    //--------------------------------------------------------------------------
    // Driving stimulus

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        // We don't need direct tests here,
        // everything should be covered by randomization.
        //
        // However we do need to have multiple tests of the design behavior
        // immediately after the reset
        // to make sure there are Xs on valid coming.

        repeat (3 * depth)
        begin
            in_vld <= '0;
            reset ();

            repeat (3 * depth)
            begin
                in_data <= width' ($urandom());
                in_vld  <= 1'     ($urandom());

                @ (posedge clk);
            end
        end

        repeat (4 * depth) @ (posedge clk);

        $display ("PASS %s", test_id);
        $finish;
    end

    //--------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("%s time %7d cycle %5d", test_id, $time, cycle);
        cycle <= cycle + 1'b1;

        if (rst)
            $write (" rst");
        else
            $write ("    ");

        if (in_vld)
            $write (" in_data %8h", in_data);
        else
            $write ("                 ");

        if (out_vld)
            $write (" out_data %8h", out_data);

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    always @ (posedge clk)
    begin
        if (expected_out_vld !== 'x & out_vld !== expected_out_vld)
        begin
            $display ("FAIL %s: expected out_vld mismatch. Expected %b, actual %b",
                test_id, expected_out_vld, out_vld);

            $finish;
        end

        if (expected_out_vld & (out_data !== expected_out_data))
        begin
            $display ("FAIL %s: out_data mismatch. Expected %h, actual %h",
                test_id, expected_out_data, out_data);

            $finish;
        end
    end

    //----------------------------------------------------------------------
    // Setting timeout against hangs

    initial
    begin
        repeat (20_000) @ (posedge clk);
        $display ("Timeout!");
        $finish;
    end

endmodule
