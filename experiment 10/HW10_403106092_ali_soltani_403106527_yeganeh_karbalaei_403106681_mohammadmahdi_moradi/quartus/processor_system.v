module processor_system (
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] input_x,

    output wire [3:0] hex_low,
    output wire [3:0] hex_high,
    output wire       error_led,
    output wire       done_led
);

    // ------------------------------------------------------------
    // CPU-memory interface
    // ------------------------------------------------------------

    wire [7:0] memory_address;
    wire [7:0] memory_read_data;
    wire [7:0] memory_write_data;
    wire       memory_write_enable;


    // ------------------------------------------------------------
    // CPU core
    // ------------------------------------------------------------

    stack_cpu cpu (
        .clk                 (clk),
        .reset               (reset),

        .memory_address      (memory_address),
        .memory_read_data    (memory_read_data),
        .memory_write_data   (memory_write_data),
        .memory_write_enable (memory_write_enable)
    );


    // ------------------------------------------------------------
    // Memory and memory-mapped I/O
    // ------------------------------------------------------------

    memory_io memory_unit (
        .clk          (clk),
        .reset        (reset),

        .address      (memory_address),
        .write_data   (memory_write_data),
        .write_enable (memory_write_enable),
        .read_data    (memory_read_data),

        .input_x      (input_x),

        .hex_low      (hex_low),
        .hex_high     (hex_high),
        .error_led    (error_led),
        .done_led     (done_led)
    );

endmodule