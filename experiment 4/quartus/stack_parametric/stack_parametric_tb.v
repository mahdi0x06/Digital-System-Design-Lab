`timescale 1ns/1ps

module stack_tb #(
    parameter WIDTH = 5,
    parameter DEPTH = 5
);

    reg Clk;
    reg RstN;
    reg push;
    reg pop;
    reg [WIDTH-1:0] Data_In;

    wire Full;
    wire Empty;
    wire [WIDTH-1:0] Data_Out;

    integer errors;
    integer checks;
    integer i;
    integer n;

    integer seed;
    integer rand_op;
    reg [WIDTH-1:0] rand_data;

    // Reference stack model
    reg [WIDTH-1:0] model_stack [0:DEPTH-1];
    integer model_count;


    // Generate test data
    function [WIDTH-1:0] test_value;
        input integer index;
    begin
        test_value = (index * 3) + 1;
    end
    endfunction


    // Device Under Test
    stack_parametric #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .Clk(Clk),
        .RstN(RstN),
        .push(push),
        .pop(pop),
        .Data_In(Data_In),
        .Full(Full),
        .Empty(Empty),
        .Data_Out(Data_Out)
    );


    // 10 ns clock
    initial begin
        Clk = 0;
        forever #5 Clk = ~Clk;
    end


    // Save main signals
    initial begin
        $dumpfile("stack_tb.vcd");

        $dumpvars(
            0,
            Clk,
            RstN,
            push,
            pop,
            Data_In,
            Data_Out,
            Full,
            Empty
        );
    end


    // Check status flags
    task check_flags;
        reg expected_empty;
        reg expected_full;
    begin

        expected_empty = (model_count == 0);
        expected_full  = (model_count == DEPTH);

        checks = checks + 2;

        if (Empty !== expected_empty) begin
            $display(
                "ERROR: Empty expected %b, got %b",
                expected_empty,
                Empty
            );
            errors = errors + 1;
        end

        if (Full !== expected_full) begin
            $display(
                "ERROR: Full expected %b, got %b",
                expected_full,
                Full
            );
            errors = errors + 1;
        end

        // Full and Empty must not be active together
        checks = checks + 1;

        if (Full === 1'b1 && Empty === 1'b1) begin
            $display("ERROR: Full and Empty are both active");
            errors = errors + 1;
        end

    end
    endtask


    // Reset stack
    task reset_stack;
    begin

        push = 0;
        pop = 0;
        Data_In = 0;

        // Assert reset between clock edges
        #1;
        RstN = 0;
        #1;

        model_count = 0;

        checks = checks + 3;

        if (Empty !== 1) begin
            $display("ERROR: Empty must be 1 after reset");
            errors = errors + 1;
        end

        if (Full !== 0) begin
            $display("ERROR: Full must be 0 after reset");
            errors = errors + 1;
        end

        if (Data_Out !== 0) begin
            $display("ERROR: Data_Out must be zero after reset");
            errors = errors + 1;
        end

        // Release reset safely
        @(negedge Clk);
        RstN = 1;
        #1;

    end
    endtask


    // Apply one stack operation
    task apply_operation;

        input do_push;
        input do_pop;
        input [WIDTH-1:0] value;

        integer old_count;

        reg [WIDTH-1:0] old_output;
        reg [WIDTH-1:0] expected_output;

    begin

        @(negedge Clk);

        old_count = model_count;
        old_output = Data_Out;

        Data_In = value;
        push = do_push;
        pop = do_pop;

        @(posedge Clk);
        #1;


        // Simultaneous push and pop
        if (do_push && do_pop) begin

            // Empty stack: push only
            if (old_count == 0) begin

                model_stack[0] = value;
                model_count = 1;

                checks = checks + 1;

                if (Data_Out !== old_output) begin
                    $display(
                        "ERROR: Push-Pop on empty changed Data_Out"
                    );
                    errors = errors + 1;
                end

            end

            // Non-empty stack: replace top
            else begin

                expected_output =
                    model_stack[old_count - 1];

                checks = checks + 1;

                if (Data_Out !== expected_output) begin
                    $display(
                        "ERROR: Push-Pop expected %0d, got %0d",
                        expected_output,
                        Data_Out
                    );
                    errors = errors + 1;
                end

                model_stack[old_count - 1] = value;

                // Element count stays unchanged
                model_count = old_count;

            end

        end


        // Push operation
        else if (do_push) begin

            // Valid push
            if (old_count < DEPTH) begin
                model_stack[old_count] = value;
                model_count = old_count + 1;
            end

            // Push must not change Data_Out
            checks = checks + 1;

            if (Data_Out !== old_output) begin
                $display("ERROR: Push changed Data_Out");
                errors = errors + 1;
            end

        end


        // Pop operation
        else if (do_pop) begin

            // Valid pop
            if (old_count > 0) begin

                expected_output =
                    model_stack[old_count - 1];

                checks = checks + 1;

                if (Data_Out !== expected_output) begin
                    $display(
                        "ERROR: Pop expected %0d, got %0d",
                        expected_output,
                        Data_Out
                    );
                    errors = errors + 1;
                end

                model_count = old_count - 1;

            end

            // Pop on empty
            else begin

                checks = checks + 1;

                if (Data_Out !== old_output) begin
                    $display(
                        "ERROR: Empty pop changed Data_Out"
                    );
                    errors = errors + 1;
                end

            end

        end


        // Idle operation
        else begin

            checks = checks + 1;

            if (Data_Out !== old_output) begin
                $display("ERROR: Idle changed Data_Out");
                errors = errors + 1;
            end

        end


        // Check Full and Empty
        check_flags();


        // Clear controls
        push = 0;
        pop = 0;
        Data_In = 0;

    end
    endtask


    // Fill entire stack
    task fill_stack;
        integer k;
    begin

        for (k = 0; k < DEPTH; k = k + 1) begin
            apply_operation(
                1'b1,
                1'b0,
                test_value(k)
            );
        end

    end
    endtask


    // Empty entire stack
    task drain_stack;
    begin

        while (model_count > 0) begin
            apply_operation(
                1'b0,
                1'b1,
                0
            );
        end

    end
    endtask


    initial begin

        errors = 0;
        checks = 0;
        model_count = 0;

        RstN = 1;
        push = 0;
        pop = 0;
        Data_In = 0;

        seed = 32'h13579BDF;


        // Validate parameters
        if (WIDTH < 1 || DEPTH < 1) begin
            $display("ERROR: WIDTH and DEPTH must be positive");
            $finish;
        end


        $display("========================================");
        $display(
            "STACK TEST: WIDTH=%0d DEPTH=%0d",
            WIDTH,
            DEPTH
        );
        $display("========================================");


        // -------------------------
        // Test 1: Reset
        // -------------------------
        $display("Test 1: Reset");

        reset_stack();


        // -------------------------
        // Test 2: Pop when empty
        // -------------------------
        $display("Test 2: Pop when empty");

        reset_stack();

        apply_operation(
            1'b0,
            1'b1,
            0
        );


        // -------------------------
        // Test 3: Push first element
        // -------------------------
        $display("Test 3: Push first element");

        reset_stack();

        apply_operation(
            1'b1,
            1'b0,
            test_value(0)
        );

        // Verify stored value
        apply_operation(
            1'b0,
            1'b1,
            0
        );


        // -------------------------
        // Test 4: Push-Pop when empty
        // -------------------------
        $display("Test 4: Push-Pop when empty");

        reset_stack();

        apply_operation(
            1'b1,
            1'b1,
            test_value(0)
        );

        // Verify pushed value
        apply_operation(
            1'b0,
            1'b1,
            0
        );


        // -------------------------
        // Test 5: Normal LIFO
        // -------------------------
        $display("Test 5: Normal LIFO");

        reset_stack();

        n = (DEPTH < 3) ? DEPTH : 3;

        for (i = 0; i < n; i = i + 1) begin
            apply_operation(
                1'b1,
                1'b0,
                test_value(i)
            );
        end

        drain_stack();


        // -------------------------
        // Test 6: Full boundary
        // -------------------------
        $display("Test 6: Full boundary");

        reset_stack();

        // Fill all except last entry
        for (i = 0; i < DEPTH - 1; i = i + 1) begin
            apply_operation(
                1'b1,
                1'b0,
                test_value(i)
            );
        end

        checks = checks + 1;

        if (Full !== 0) begin
            $display("ERROR: Full asserted too early");
            errors = errors + 1;
        end

        // Last push must set Full
        apply_operation(
            1'b1,
            1'b0,
            test_value(DEPTH - 1)
        );

        checks = checks + 1;

        if (Full !== 1) begin
            $display("ERROR: Full did not assert");
            errors = errors + 1;
        end


        // -------------------------
        // Test 7: Push when full
        // -------------------------
        $display("Test 7: Push when full");

        // Extra push must be ignored
        apply_operation(
            1'b1,
            1'b0,
            {WIDTH{1'b1}}
        );

        // Verify all stored data
        drain_stack();


        // -------------------------
        // Test 8: Pop from full
        // -------------------------
        $display("Test 8: Pop from full");

        reset_stack();
        fill_stack();

        apply_operation(
            1'b0,
            1'b1,
            0
        );

        checks = checks + 1;

        if (Full !== 0) begin
            $display("ERROR: Full did not clear after pop");
            errors = errors + 1;
        end

        drain_stack();


        // -------------------------
        // Test 9: Push-Pop when full
        // -------------------------
        $display("Test 9: Push-Pop when full");

        reset_stack();
        fill_stack();

        // Replace top while staying full
        apply_operation(
            1'b1,
            1'b1,
            {WIDTH{1'b1}}
        );

        checks = checks + 1;

        if (Full !== 1) begin
            $display(
                "ERROR: Stack must remain full after Push-Pop"
            );
            errors = errors + 1;
        end

        // Verify replaced top
        apply_operation(
            1'b0,
            1'b1,
            0
        );

        drain_stack();


        // -------------------------
        // Test 10: Push-Pop with one element
        // -------------------------
        $display("Test 10: Push-Pop with one element");

        reset_stack();

        apply_operation(
            1'b1,
            1'b0,
            test_value(0)
        );

        apply_operation(
            1'b1,
            1'b1,
            {WIDTH{1'b1}}
        );

        // Verify replacement
        apply_operation(
            1'b0,
            1'b1,
            0
        );


        // -------------------------
        // Test 11: Normal Push-Pop
        // -------------------------
        $display("Test 11: Normal Push-Pop");

        reset_stack();

        n = (DEPTH < 3) ? DEPTH : 3;

        for (i = 0; i < n; i = i + 1) begin
            apply_operation(
                1'b1,
                1'b0,
                test_value(i)
            );
        end

        // Replace current top
        apply_operation(
            1'b1,
            1'b1,
            {WIDTH{1'b1}}
        );

        drain_stack();


        // -------------------------
        // Test 12: Empty boundary
        // -------------------------
        $display("Test 12: Empty boundary");

        reset_stack();

        apply_operation(
            1'b1,
            1'b0,
            test_value(0)
        );

        // Last pop must set Empty
        apply_operation(
            1'b0,
            1'b1,
            0
        );

        checks = checks + 1;

        if (Empty !== 1) begin
            $display("ERROR: Empty did not assert");
            errors = errors + 1;
        end

        // Extra pop must be ignored
        apply_operation(
            1'b0,
            1'b1,
            0
        );


        // -------------------------
        // Test 13: Idle state
        // -------------------------
        $display("Test 13: Idle state");

        reset_stack();

        apply_operation(
            1'b1,
            1'b0,
            test_value(0)
        );

        if (DEPTH > 1) begin

            apply_operation(
                1'b1,
                1'b0,
                {WIDTH{1'b1}}
            );

            // Set a known Data_Out
            apply_operation(
                1'b0,
                1'b1,
                0
            );

        end

        // Stay idle for three clocks
        repeat (3) begin
            apply_operation(
                1'b0,
                1'b0,
                0
            );
        end

        drain_stack();


        // -------------------------
        // Test 14: Reset when non-empty
        // -------------------------
        $display("Test 14: Reset when non-empty");

        reset_stack();

        n = (DEPTH < 3) ? DEPTH : 3;

        for (i = 0; i < n; i = i + 1) begin
            apply_operation(
                1'b1,
                1'b0,
                test_value(i)
            );
        end

        reset_stack();


        // -------------------------
        // Test 15: Reset when full
        // -------------------------
        $display("Test 15: Reset when full");

        reset_stack();
        fill_stack();

        reset_stack();


        // -------------------------
        // Test 16: Random stress test
        // -------------------------
        $display("Test 16: Random stress test");

        reset_stack();

        for (i = 0; i < 200; i = i + 1) begin

            rand_op = $random(seed);
            rand_data = $random(seed);

            case (rand_op & 3)

                // Idle
                0:
                    apply_operation(
                        1'b0,
                        1'b0,
                        rand_data
                    );

                // Push
                1:
                    apply_operation(
                        1'b1,
                        1'b0,
                        rand_data
                    );

                // Pop
                2:
                    apply_operation(
                        1'b0,
                        1'b1,
                        rand_data
                    );

                // Push and Pop
                3:
                    apply_operation(
                        1'b1,
                        1'b1,
                        rand_data
                    );

            endcase

        end

        // Verify remaining data
        drain_stack();

        // Verify empty protection
        apply_operation(
            1'b0,
            1'b1,
            0
        );


        // -------------------------
        // Final result
        // -------------------------
        #10;

        $display("========================================");
        $display(
            "Configuration: WIDTH=%0d DEPTH=%0d",
            WIDTH,
            DEPTH
        );

        $display(
            "Checks performed: %0d",
            checks
        );

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display(
                "TEST FAILED: %0d error(s)",
                errors
            );

        $display("========================================");

        $finish;

    end

endmodule