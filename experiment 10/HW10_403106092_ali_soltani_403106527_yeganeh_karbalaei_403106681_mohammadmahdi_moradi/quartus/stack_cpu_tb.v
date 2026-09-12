`timescale 1ns/1ps

module stack_cpu_tb;

    reg clk;
    reg reset;

    wire [7:0] memory_address;
    reg  [7:0] memory [0:255];
    wire [7:0] memory_read_data;
    wire [7:0] memory_write_data;
    wire       memory_write_enable;

    integer i;
    integer passed_tests;
    integer failed_tests;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    stack_cpu dut (
        .clk                 (clk),
        .reset               (reset),
        .memory_address      (memory_address),
        .memory_read_data    (memory_read_data),
        .memory_write_data   (memory_write_data),
        .memory_write_enable (memory_write_enable)
    );


    // ------------------------------------------------------------
    // Simple memory model
    // ------------------------------------------------------------

    assign memory_read_data = memory[memory_address];

    always @(posedge clk) begin
        if (memory_write_enable)
            memory[memory_address] <= memory_write_data;
    end


    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ------------------------------------------------------------
    // Utility tasks
    // ------------------------------------------------------------

    task clear_memory;
        begin
            for (i = 0; i < 256; i = i + 1)
                memory[i] = 8'h00;
        end
    endtask


    task start_cpu;
        begin
            reset = 1'b1;

            repeat (2)
                @(posedge clk);

            @(negedge clk);
            reset = 1'b0;
        end
    endtask


    task wait_for_fetch;
        input [7:0] expected_pc;

        integer timeout;

        begin
            timeout = 0;

            while (
                !((dut.state == 4'd0) &&
                  (dut.program_counter == expected_pc))
                &&
                (timeout < 100)
            ) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display(
                    "ERROR: Timeout waiting for PC = %02h",
                    expected_pc
                );

                failed_tests = failed_tests + 1;
            end
        end
    endtask


    // ------------------------------------------------------------
    // SWAP test
    // ------------------------------------------------------------

    task test_swap;
        begin
            $display("\n--- SWAP test ---");

            reset = 1'b1;
            clear_memory();

            // PUSHC 12
            memory[8'h00] = 8'h00;
            memory[8'h01] = 8'h12;

            // PUSHC A5
            memory[8'h02] = 8'h00;
            memory[8'h03] = 8'hA5;

            // SWAP
            memory[8'h04] = 8'h08;

            start_cpu();

            wait_for_fetch(8'h05);

            if (
                (dut.stack_pointer == 4'd2) &&
                (dut.stack[0] == 8'hA5) &&
                (dut.stack[1] == 8'h12)
            ) begin

                $display("PASS: SWAP");
                passed_tests = passed_tests + 1;

            end
            else begin

                $display(
                    "FAIL: SWAP | stack[0]=%02h stack[1]=%02h SP=%0d",
                    dut.stack[0],
                    dut.stack[1],
                    dut.stack_pointer
                );

                failed_tests = failed_tests + 1;

            end
        end
    endtask


    // ------------------------------------------------------------
    // SHL test
    // ------------------------------------------------------------

    task test_shl;
        input [7:0] input_value;
        input [7:0] expected_value;

        begin
            reset = 1'b1;
            clear_memory();

            // PUSHC input_value
            memory[8'h00] = 8'h00;
            memory[8'h01] = input_value;

            // SHL
            memory[8'h02] = 8'h09;

            start_cpu();

            wait_for_fetch(8'h03);

            if (
                (dut.stack_pointer == 4'd1) &&
                (dut.stack[0] == expected_value)
            ) begin

                $display(
                    "PASS: SHL %0d -> %0d",
                    input_value,
                    expected_value
                );

                passed_tests = passed_tests + 1;

            end
            else begin

                $display(
                    "FAIL: SHL %0d | expected=%0d actual=%0d",
                    input_value,
                    expected_value,
                    dut.stack[0]
                );

                failed_tests = failed_tests + 1;

            end
        end
    endtask


    // ------------------------------------------------------------
    // CMP test
    // ------------------------------------------------------------

    task test_cmp;
        input [7:0] value_b;
        input [7:0] value_a;
        input       expected_zero;
        input       expected_sign;

        begin
            reset = 1'b1;
            clear_memory();

            // Push B first
            memory[8'h00] = 8'h00;
            memory[8'h01] = value_b;

            // Push A second
            memory[8'h02] = 8'h00;
            memory[8'h03] = value_a;

            // CMP -> B - A
            memory[8'h04] = 8'h0A;

            start_cpu();

            wait_for_fetch(8'h05);

            if (
                (dut.stack_pointer == 4'd2) &&
                (dut.stack[0] == value_b) &&
                (dut.stack[1] == value_a) &&
                (dut.zero_flag == expected_zero) &&
                (dut.sign_flag == expected_sign)
            ) begin

                $display(
                    "PASS: CMP B=%0d A=%0d | Z=%b S=%b",
                    value_b,
                    value_a,
                    dut.zero_flag,
                    dut.sign_flag
                );

                passed_tests = passed_tests + 1;

            end
            else begin

                $display(
                    "FAIL: CMP B=%0d A=%0d | Z=%b S=%b SP=%0d",
                    value_b,
                    value_a,
                    dut.zero_flag,
                    dut.sign_flag,
                    dut.stack_pointer
                );

                failed_tests = failed_tests + 1;

            end
        end
    endtask


    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------

    initial begin

        reset = 1'b1;

        passed_tests = 0;
        failed_tests = 0;

        clear_memory();


        // SWAP
        test_swap();


        // SHL mandatory values
        $display("\n--- SHL tests ---");

        test_shl(8'd0,   8'd0);
        test_shl(8'd1,   8'd2);
        test_shl(8'd63,  8'd126);
        test_shl(8'd127, 8'd254);


        // CMP mandatory conditions
        $display("\n--- CMP tests ---");

        // B < A
        test_cmp(
            8'd5,
            8'd9,
            1'b0,
            1'b1
        );

        // B = A
        test_cmp(
            8'd7,
            8'd7,
            1'b1,
            1'b0
        );

        // B > A
        test_cmp(
            8'd9,
            8'd5,
            1'b0,
            1'b0
        );


        // --------------------------------------------------------
        // Summary
        // --------------------------------------------------------

        $display("\n================================");
        $display("CPU TEST SUMMARY");
        $display("Passed: %0d", passed_tests);
        $display("Failed: %0d", failed_tests);
        $display("================================");

        if (failed_tests == 0)
            $display("ALL CPU TESTS PASSED");
        else
            $display("CPU TESTS FAILED");

        #20;
        $finish;

    end


    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------

    initial begin
        $dumpfile("stack_cpu_tb.vcd");
        $dumpvars(0, stack_cpu_tb);
    end

endmodule