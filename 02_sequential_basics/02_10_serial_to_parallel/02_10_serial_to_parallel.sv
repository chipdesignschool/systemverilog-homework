//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel #(
    parameter width = 8
) (
    input clk,
    input rst,

    input serial_valid,
    input serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts serial data to the parallel multibit value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits, the module should assert the parallel_valid
    // output and set the data.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    // logic [$clog2(width):0] counter;
    logic [width-1:0] shift_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            parallel_data <= '0;
            parallel_valid <= '0;
            shift_reg <= 'b1;
        end else begin
            if (serial_valid) begin
                // Shift in serial data
                parallel_data <= {serial_data, parallel_data[width-1:1]};
                shift_reg[width-1:0] <= {shift_reg[width-2:0], shift_reg[width-1]};
                if (shift_reg[width-1]) begin
                    parallel_valid <= 1;
                    shift_reg <= 'b1;                
                end else begin 
                    parallel_valid <= 0;
                end
            end else begin
                parallel_valid <= 0;  // Make sure parallel_valid is de-asserted when no serial data
            end
        end
    end

endmodule
