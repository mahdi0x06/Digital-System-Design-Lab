`timescale 1ns/1ps

module Tester;

    parameter BIT_TICKS  = 4;
    parameter CLK_PERIOD = 10;

    reg             clk;
    reg             rstN;

    reg             new_data;
    reg     [6:0]   send_data;

    wire            tx;
    wire            busy;
    wire    [6:0]   rec_data;
    wire            rec_new_data;
    wire            correct_data;

    // A second receiver is used only for controlled error injection.
    reg             manual_rx;
    wire    [6:0]   manual_rec_data;
    wire            manual_rec_new_data;
    wire            manual_correct_data;

    // Testbench bookkeeping. test_id is intentionally dumped to the VCD so
    // each test has a clearly visible region in GTKWave.
    reg     [4:0]   test_id;
    reg             verbose;
    integer         errors;
    integer         checks;
    integer         top_rx_count;
    integer         manual_rx_count;
    integer         i;

    // ---------------------------------------------------------------------
    // DUTs
    // ---------------------------------------------------------------------

    UARTTop #(
        .BIT_TICKS(BIT_TICKS)
    ) top_dut (
        .clk            (clk),
        .rstN           (rstN),
        .new_data       (new_data),
        .send_data      (send_data),
        .tx             (tx),
        .busy           (busy),
        .rec_new_data   (rec_new_data),
        .rec_data       (rec_data),
        .correct_data   (correct_data)
    );

    UARTReceiver #(
        .BIT_TICKS(BIT_TICKS)
    ) manual_rx_dut (
        .clk            (clk),
        .rstN           (rstN),
        .rx             (manual_rx),
        .rec_data       (manual_rec_data),
        .rec_new_data   (manual_rec_new_data),
        .correct_data   (manual_correct_data)
    );

    // ---------------------------------------------------------------------
    // Clock, counters, VCD, watchdog
    // ---------------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    always @(posedge rec_new_data)
        top_rx_count = top_rx_count + 1;

    always @(posedge manual_rec_new_data)
        manual_rx_count = manual_rx_count + 1;

    // Dump only the signals useful for the report. Internal FSM registers are
    // intentionally omitted so the GTKWave view stays readable.
    initial begin
        $dumpfile("uart_tests.vcd");
        $dumpvars(0,
            Tester.test_id,
            Tester.clk,
            Tester.rstN,
            Tester.new_data,
            Tester.send_data,
            Tester.tx,
            Tester.busy,
            Tester.rec_data,
            Tester.rec_new_data,
            Tester.correct_data,
            Tester.manual_rx,
            Tester.manual_rec_data,
            Tester.manual_rec_new_data,
            Tester.manual_correct_data
        );
    end

    // Prevent an unnoticed design bug from hanging the simulation forever.
    initial begin
        #(CLK_PERIOD * BIT_TICKS * 6000);
        $display("FATAL: global testbench timeout");
        $finish;
    end

    // ---------------------------------------------------------------------
    // Common helper tasks
    // ---------------------------------------------------------------------

    task add_check;
        input condition;
        input [8*96-1:0] message;
    begin
        checks = checks + 1;
        if (condition !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: %0s", message);
        end
        else if (verbose) begin
            $display("PASS: %0s", message);
        end
    end
    endtask

    task reset_all;
    begin
        rstN       = 1'b0;
        new_data   = 1'b0;
        send_data  = 7'd0;
        manual_rx  = 1'b1;

        // Asynchronous reset should act without waiting for a clock edge.
        #1;
        add_check((tx === 1'b1) && (busy === 1'b0),
                  "sender returns to idle immediately during reset");
        add_check((rec_new_data === 1'b0) && (correct_data === 1'b0),
                  "receiver status outputs clear during reset");
        add_check((manual_rec_new_data === 1'b0) &&
                  (manual_correct_data === 1'b0),
                  "manual receiver status outputs clear during reset");

        repeat (3) @(posedge clk);
        @(negedge clk);
        rstN = 1'b1;
        repeat (3) @(posedge clk);
    end
    endtask

    // Creates a visible empty region between tests in GTKWave.
    task test_gap;
    begin
        test_id   = 5'd0;
        new_data  = 1'b0;
        send_data = 7'd0;
        manual_rx = 1'b1;
        repeat (4) @(posedge clk);
    end
    endtask

    task send_top_data;
        input [6:0] data;
    begin
        wait (busy === 1'b0);

        @(negedge clk);
        send_data = data;
        new_data  = 1'b1;

        @(negedge clk);
        new_data  = 1'b0;
    end
    endtask

    task check_top_data;
        input [6:0] expected;
    begin
        @(posedge rec_new_data);
        #1;

        checks = checks + 1;
        if ((rec_data !== expected) || (correct_data !== 1'b1)) begin
            errors = errors + 1;
            $display("FAIL: top expected data=%b correct=1, got data=%b correct=%b",
                     expected, rec_data, correct_data);
        end
        else if (verbose) begin
            $display("PASS: top received %b correctly", expected);
        end

        // The specification uses rec_new_data as a new-frame indication; make
        // sure the implementation generates a one-clock pulse rather than a
        // level that remains high.
        @(posedge clk);
        #1;
        add_check(rec_new_data === 1'b0,
                  "rec_new_data is a one-clock pulse");
    end
    endtask

    task drive_manual_bit;
        input bit_value;
    begin
        @(negedge clk);
        manual_rx = bit_value;
        repeat (BIT_TICKS - 1) @(negedge clk);
    end
    endtask

    task send_manual_frame;
        input [6:0] data;
        input       parity_bit;
        input       stop_bit;
        integer     k;
    begin
        drive_manual_bit(1'b0);        // Start
        drive_manual_bit(parity_bit);  // Parity

        for (k = 0; k < 7; k = k + 1)
            drive_manual_bit(data[k]); // D0 ... D6 (LSB first)

        drive_manual_bit(stop_bit);    // Stop
        drive_manual_bit(1'b1);        // Return to idle
    end
    endtask

    task check_manual_data;
        input [6:0] expected_data;
        input       expected_correct;
    begin
        @(posedge manual_rec_new_data);
        #1;

        checks = checks + 1;
        if ((manual_rec_data !== expected_data) ||
            (manual_correct_data !== expected_correct)) begin
            errors = errors + 1;
            $display("FAIL: manual expected data=%b correct=%b, got data=%b correct=%b",
                     expected_data, expected_correct,
                     manual_rec_data, manual_correct_data);
        end
        else if (verbose) begin
            $display("PASS: manual receiver data=%b correct=%b",
                     expected_data, expected_correct);
        end

        @(posedge clk);
        #1;
        add_check(manual_rec_new_data === 1'b0,
                  "manual rec_new_data is a one-clock pulse");
    end
    endtask

    // Check one complete serial frame directly on tx. This is important because
    // a loopback-only test could miss a matching sender/receiver bit-order bug.
    task check_tx_bit;
        input expected;
        integer k;
    begin
        for (k = 0; k < BIT_TICKS; k = k + 1) begin
            @(negedge clk);
            checks = checks + 1;
            if (tx !== expected) begin
                errors = errors + 1;
                $display("FAIL: tx bit mismatch at test_id=%0d expected=%b got=%b time=%0t",
                         test_id, expected, tx, $time);
            end

            checks = checks + 1;
            if (busy !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: busy dropped inside a frame at test_id=%0d time=%0t",
                         test_id, $time);
            end
        end
    end
    endtask

    task check_serial_frame;
        input [6:0] data;
        integer k;
        reg parity_bit;
    begin
        parity_bit = ^data;
        wait (busy === 1'b1);

        check_tx_bit(1'b0);       // Start
        check_tx_bit(parity_bit); // Parity

        for (k = 0; k < 7; k = k + 1)
            check_tx_bit(data[k]);

        check_tx_bit(1'b1);       // Stop

        @(posedge clk);
        #1;
        add_check((busy === 1'b0) && (tx === 1'b1),
                  "busy clears only after stop bit and tx returns to idle");
    end
    endtask

    // ---------------------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------------------

    initial begin
        errors          = 0;
        checks          = 0;
        top_rx_count    = 0;
        manual_rx_count = 0;
        test_id         = 0;
        verbose         = 1'b1;
        rstN            = 1'b0;
        new_data        = 1'b0;
        send_data       = 7'd0;
        manual_rx       = 1'b1;

        $display("============================================");
        $display("Starting comprehensive UART testbench");
        $display("BIT_TICKS=%0d, CLK_PERIOD=%0d ns", BIT_TICKS, CLK_PERIOD);
        $display("============================================");

        reset_all();

        // -------------------------------------------------------------
        // Test 1: reset and idle state
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd1;
        $display("\nTest 1: reset and idle state");
        add_check((rstN === 1'b1) && (tx === 1'b1) && (busy === 1'b0),
                  "idle line is high and sender is not busy");
        add_check(rec_new_data === 1'b0,
                  "no receive pulse is present while idle");

        // -------------------------------------------------------------
        // Test 2: required correct receive + direct frame format check
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd2;
        $display("\nTest 2: correct receive + frame format + busy timing");
        fork
            begin
                send_top_data(7'b1011001);
            end
            begin
                check_serial_frame(7'b1011001);
            end
            begin
                check_top_data(7'b1011001);
            end
        join

        // -------------------------------------------------------------
        // Test 3: required parity error
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd3;
        $display("\nTest 3: parity error");
        fork
            begin
                send_manual_frame(7'b1011001, ~(^7'b1011001), 1'b1);
            end
            begin
                check_manual_data(7'b1011001, 1'b0);
            end
        join

        // -------------------------------------------------------------
        // Test 4: required stop-bit error
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd4;
        $display("\nTest 4: stop-bit error");
        fork
            begin
                send_manual_frame(7'b1011001, ^7'b1011001, 1'b0);
            end
            begin
                check_manual_data(7'b1011001, 1'b0);
            end
        join

        // -------------------------------------------------------------
        // Test 5: required multiple back-to-back frames
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd5;
        $display("\nTest 5: multiple back-to-back frames");
        fork
            begin
                send_top_data(7'b1011001);
                wait (busy === 1'b1);
                wait (busy === 1'b0);
                send_top_data(7'b0101101);
            end
            begin
                check_top_data(7'b1011001);
                check_top_data(7'b0101101);
            end
        join

        // -------------------------------------------------------------
        // Test 6: minimum payload boundary (0000000, parity = 0)
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd6;
        $display("\nTest 6: minimum payload 0000000");
        fork
            send_top_data(7'b0000000);
            check_top_data(7'b0000000);
        join

        // -------------------------------------------------------------
        // Test 7: maximum payload boundary (1111111, parity = 1)
        // This also proves the valid-parity=1 path, which the PDF example
        // 1011001 does not exercise.
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd7;
        $display("\nTest 7: maximum payload 1111111 (valid parity = 1)");
        fork
            send_top_data(7'b1111111);
            check_top_data(7'b1111111);
        join

        // -------------------------------------------------------------
        // Test 8: new_data while busy must not corrupt or queue a frame.
        // send_data is changed at the same time to verify input latching.
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd8;
        $display("\nTest 8: new_data while busy is ignored + input data is latched");
        begin : busy_reject_test
            integer before_count;
            before_count = top_rx_count;

            send_top_data(7'b0010110);
            wait (busy === 1'b1);

            // Wait until the first frame is already in progress.
            repeat (BIT_TICKS + 1) @(posedge clk);

            // Illegal/repeated request during busy. It must not modify the
            // current frame and must not be queued as a second frame.
            @(negedge clk);
            send_data = 7'b1101001;
            new_data  = 1'b1;
            @(negedge clk);
            new_data  = 1'b0;

            check_top_data(7'b0010110);

            // Wait longer than one additional frame-start opportunity.
            repeat (2 * BIT_TICKS + 6) @(posedge clk);
            add_check(top_rx_count == before_count + 1,
                      "busy-time new_data created no extra received frame");
            add_check(busy === 1'b0,
                      "sender returns to idle after ignored busy-time request");
        end

        // -------------------------------------------------------------
        // Test 9: asynchronous reset in the middle of a transmission,
        // followed by a normal frame to prove recovery.
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd9;
        $display("\nTest 9: asynchronous reset during transmission + recovery");
        begin : reset_mid_frame_test
            integer before_count;
            before_count = top_rx_count;

            send_top_data(7'b0110101);
            wait (busy === 1'b1);
            repeat (BIT_TICKS + 2) @(posedge clk);

            @(negedge clk);
            rstN = 1'b0;
            #1;
            add_check((tx === 1'b1) && (busy === 1'b0),
                      "mid-frame asynchronous reset immediately aborts sender");
            add_check((rec_new_data === 1'b0) && (correct_data === 1'b0),
                      "mid-frame reset clears receiver status");

            repeat (2) @(posedge clk);
            @(negedge clk);
            rstN = 1'b1;
            repeat (3) @(posedge clk);

            add_check(top_rx_count == before_count,
                      "aborted frame does not produce a receive event");

            fork
                send_top_data(7'b1000011);
                check_top_data(7'b1000011);
            join
        end

        // -------------------------------------------------------------
        // Test 10: false/short start pulse. The receiver should reject it,
        // then still decode the next valid manual frame correctly.
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd10;
        $display("\nTest 10: false start rejection + receiver recovery");
        begin : false_start_test
            integer before_count;
            before_count = manual_rx_count;

            // One-clock low pulse is shorter than the confirmed start-bit
            // interval for BIT_TICKS=4.
            @(negedge clk);
            manual_rx = 1'b0;
            @(negedge clk);
            manual_rx = 1'b1;

            repeat (BIT_TICKS + 3) @(posedge clk);
            add_check(manual_rx_count == before_count,
                      "short false-start pulse is rejected");
            add_check(manual_correct_data === 1'b0,
                      "false start is never marked as correct data");

            fork
                send_manual_frame(7'b0000001, ^7'b0000001, 1'b1);
                check_manual_data(7'b0000001, 1'b1);
            join
        end

        // -------------------------------------------------------------
        // Test 11: exhaustive payload sweep (all 128 possible 7-bit values).
        // VCD dumping is disabled only for this repetitive stress test so the
        // waveform used in the report stays compact and readable.
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd11;
        $display("\nTest 11: exhaustive sweep of all 128 payload values");
        verbose = 1'b0;
        $dumpoff;

        begin : exhaustive_test
            integer errors_before;
            errors_before = errors;

            for (i = 0; i < 128; i = i + 1) begin
                fork
                    send_top_data(i);
                    check_top_data(i);
                join
            end

            if (errors == errors_before)
                $display("PASS: all 128 payload values received correctly");
            else
                $display("FAIL: exhaustive payload sweep found %0d new error(s)",
                         errors - errors_before);
        end

        $dumpon;
        verbose = 1'b1;

        // -------------------------------------------------------------
        // Final summary
        // -------------------------------------------------------------
        test_gap();
        test_id = 5'd31;
        $display("\n============================================");
        $display("UART TEST SUMMARY");
        $display("Checks performed : %0d", checks);
        $display("Errors found     : %0d", errors);
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTBENCH FAILED");
        $display("VCD file         : uart_tests.vcd");
        $display("============================================\n");

        #100;
        $finish;
    end

endmodule
