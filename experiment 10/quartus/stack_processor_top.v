module stack_processor_top (
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] input_x,

    output wire [6:0] seven_segment_low,
    output wire [6:0] seven_segment_high,

    output wire       error_led,
    output wire       done_led
);

    // ------------------------------------------------------------
    // Internal hexadecimal digits
    // ------------------------------------------------------------

    wire [3:0] hex_low;
    wire [3:0] hex_high;


    // ------------------------------------------------------------
    // Processor system
    // ------------------------------------------------------------

    processor_system processor (
        .clk       (clk),
        .reset     (reset),

        .input_x   (input_x),

        .hex_low   (hex_low),
        .hex_high  (hex_high),
        .error_led (error_led),
        .done_led  (done_led)
    );


    // ------------------------------------------------------------
    // Low hexadecimal digit
    // ------------------------------------------------------------

    seven_segment_decoder low_decoder (
        .digit    (hex_low),
        .segments (seven_segment_low)
    );


    // ------------------------------------------------------------
    // High hexadecimal digit
    // ------------------------------------------------------------

    seven_segment_decoder high_decoder (
        .digit    (hex_high),
        .segments (seven_segment_high)
    );

endmodule