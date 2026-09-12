`timescale 1ns/1ps

module stack_processor_top_tb;

    reg clk;
    reg reset;

    reg [7:0] input_x;

    wire [6:0] seven_segment_low;
    wire [6:0] seven_segment_high;

    wire error_led;
    wire done_led;

    integer passed_tests;
    integer failed_tests;

    integer x;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    stack_processor_top dut (
        .clk                (clk),
        .reset              (reset),

        .input_x            (input_x),

        .seven_segment_low  (seven_segment_low),
        .seven_segment_high (seven_segment_high),

        .error_led          (error_led),
        .done_led           (done_led)
    );


    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ------------------------------------------------------------
    // Seven-segment reference decoder
    // ------------------------------------------------------------

    function [6:0] expected_segments;

        input [3:0] digit;

        begin

            case (digit)

                4'h0: expected_segments = 7'b1000000;
                4'h1: expected_segments = 7'b1111001;
                4'h2: expected_segments = 7'b0100100;
                4'h3: expected_segments = 7'b0110000;
                4'h4: expected_segments = 7'b0011001;
                4'h5: expected_segments = 7'b0010010;
                4'h6: expected_segments = 7'b0000010;
                4'h7: expected_segments = 7'b1111000;
                4'h8: expected_segments = 7'b0000000;
                4'h9: expected_segments = 7'b0010000;

                4'hA: expected_segments = 7'b0001000;
                4'hB: expected_segments = 7'b0000011;
                4'hC: expected_segments = 7'b1000110;
                4'hD: expected_segments = 7'b0100001;
                4'hE: expected_segments = 7'b0000110;
                4'hF: expected_segments = 7'b0001110;

                default:
                    expected_segments = 7'b1111111;

            endcase

        end

    endfunction


    // ------------------------------------------------------------
    // Run one complete program test
    // ------------------------------------------------------------

    task run_test;

        input [7:0] x_value;
        input       verbose;

        integer expected_y;
        integer timeout;

        reg expected_error;

        reg [3:0] expected_low;
        reg [3:0] expected_high;

        begin

            // ----------------------------------------------------
            // Reference result
            // ----------------------------------------------------

            expected_y = 0;
            expected_error = 1'b0;

            if (x_value[7] == 1'b1) begin

                // Negative signed input
                expected_error = 1'b1;
                expected_y = 0;

            end

            else if (x_value < 8'd32) begin

                // Y = 3X + 5
                expected_y =
                    x_value +
                    x_value +
                    x_value +
                    5;

            end

            else if (x_value < 8'd64) begin

                // Y = 2X + 20
                expected_y =
                    x_value +
                    x_value +
                    20;

                if (expected_y > 127) begin
                    expected_error = 1'b1;
                    expected_y = 0;
                end

            end

            else begin

                // Y = X - 40
                expected_y = x_value - 40;

            end


            expected_low  = expected_y[3:0];
            expected_high = expected_y[7:4];


            // ----------------------------------------------------
            // Reset processor
            // ----------------------------------------------------

            input_x = x_value;

            reset = 1'b1;

            repeat (2)
                @(posedge clk);

            @(negedge clk);
            reset = 1'b0;


            // ----------------------------------------------------
            // Wait for done
            // ----------------------------------------------------

            timeout = 0;

            while (
                (done_led !== 1'b1) &&
                (timeout < 2000)
            ) begin

                @(posedge clk);
                #1;

                timeout = timeout + 1;

            end


            // ----------------------------------------------------
            // Timeout
            // ----------------------------------------------------

            if (timeout >= 2000) begin

                $display(
                    "FAIL: X=%0d -> timeout",
                    x_value
                );

                failed_tests = failed_tests + 1;

            end

            else begin

                // ------------------------------------------------
                // Check outputs
                // ------------------------------------------------

                if (
                    (error_led == expected_error) &&

                    (dut.hex_low == expected_low) &&
                    (dut.hex_high == expected_high) &&

                    (seven_segment_low ==
                        expected_segments(expected_low)) &&

                    (seven_segment_high ==
                        expected_segments(expected_high))
                ) begin

                    passed_tests = passed_tests + 1;

                    if (verbose) begin

                        $display(
                            "PASS: X=%0d | HEX=%1h%1h | error=%b",
                            x_value,
                            dut.hex_high,
                            dut.hex_low,
                            error_led
                        );

                    end

                end

                else begin

                    failed_tests = failed_tests + 1;

                    $display(
                        "FAIL: X=%0d | expected HEX=%1h%1h error=%b | actual HEX=%1h%1h error=%b",
                        x_value,
                        expected_high,
                        expected_low,
                        expected_error,
                        dut.hex_high,
                        dut.hex_low,
                        error_led
                    );

                end

            end

        end

    endtask


    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------

    initial begin

        reset = 1'b1;
        input_x = 8'd0;

        passed_tests = 0;
        failed_tests = 0;


        // --------------------------------------------------------
        // Mandatory boundary tests
        // --------------------------------------------------------

        $display("\n================================");
        $display("MANDATORY PROGRAM TESTS");
        $display("================================");

        run_test(8'd0,   1'b1);
        run_test(8'd31,  1'b1);
        run_test(8'd32,  1'b1);
        run_test(8'd53,  1'b1);
        run_test(8'd54,  1'b1);
        run_test(8'd63,  1'b1);
        run_test(8'd64,  1'b1);
        run_test(8'd127, 1'b1);
        run_test(8'd128, 1'b1);
        run_test(8'd255, 1'b1);


        // --------------------------------------------------------
        // Exhaustive test
        // --------------------------------------------------------

        $display("\n================================");
        $display("EXHAUSTIVE TEST: X = 0..255");
        $display("================================");

        for (x = 0; x < 256; x = x + 1)
            run_test(x[7:0], 1'b0);


        // --------------------------------------------------------
        // Summary
        // --------------------------------------------------------

        $display("\n================================");
        $display("SYSTEM TEST SUMMARY");
        $display("Passed: %0d", passed_tests);
        $display("Failed: %0d", failed_tests);
        $display("================================");

        if (failed_tests == 0)
            $display("ALL SYSTEM TESTS PASSED");
        else
            $display("SYSTEM TESTS FAILED");


        #20;
        $finish;

    end


    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------

    initial begin
        $dumpfile("stack_processor_top_tb.vcd");
        $dumpvars(0, stack_processor_top_tb);
    end

endmodule