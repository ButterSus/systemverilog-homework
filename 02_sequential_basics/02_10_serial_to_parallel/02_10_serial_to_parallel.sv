//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

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

    logic [width - 1:0] shift_reg;

    always_ff @ (posedge clk)
        if (rst) begin
            shift_reg <= { 1'b1, { (width - 1) { 1'b0 } } };
        end
        else if (serial_valid) begin
            // There is some advice: Using indices like with cnt is pretty
            // expensive in terms of hardware (gates, e.t.c.), but like shift
            // register is a very common thing and optimized for both ASICs
            // and FPGAs. It's literally D triggers connected to each other,
            // so called 'Destructive Read'.

            shift_reg <= shift_reg [0] ? { 1'b1, { (width - 1) { 1'b0 } } } : { serial_data, shift_reg [width - 1:1] };
        end

    // Output logic
    assign parallel_valid = shift_reg [0] & serial_valid;
    assign parallel_data = { serial_data, shift_reg [width - 1:1] };

endmodule
