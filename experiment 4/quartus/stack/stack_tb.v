`timescale 1ns/1ps

module stack_tb;

    reg Clk;
    reg RstN;
    reg push;
    reg pop;
    reg [3:0] Data_In;

    wire Full;
    wire Empty;
    wire [3:0] Data_Out;

    integer errors;
    integer i;

    // Device Under Test
    stack dut (
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
        $dumpfile("stack_tb.vcd");
        $dumpvars();
        Clk = 0;
        forever #5 Clk = ~Clk;
    end


    // Reset stack
    task reset_stack;
    begin
        RstN = 0;
        push = 0;
        pop = 0;
        Data_In = 0;

        #2;

        if (Empty !== 1 || Full !== 0) begin
            $display("ERROR: Reset failed");
            errors = errors + 1;
        end

        RstN = 1;
        #8;
    end
    endtask


    // Push one value
    task push_value;
        input [3:0] value;
    begin
        @(negedge Clk);

        Data_In = value;
        push = 1;
        pop = 0;

        @(posedge Clk);
        #1;

        push = 0;
        Data_In = 0;
    end
    endtask


    // Pop and check output
    task pop_value;
        input [3:0] expected;
    begin
        @(negedge Clk);

        push = 0;
        pop = 1;

        @(posedge Clk);
        #1;

        if (Data_Out !== expected) begin
            $display(
                "ERROR: Pop expected %d, got %d",
                expected,
                Data_Out
            );
            errors = errors + 1;
        end

        pop = 0;
    end
    endtask


    // Simultaneous push and pop
    task push_pop;
        input [3:0] value;
        input [3:0] expected_out;
    begin
        @(negedge Clk);

        Data_In = value;
        push = 1;
        pop = 1;

        @(posedge Clk);
        #1;

        if (Data_Out !== expected_out) begin
            $display(
                "ERROR: Push-Pop expected %d, got %d",
                expected_out,
                Data_Out
            );
            errors = errors + 1;
        end

        push = 0;
        pop = 0;
        Data_In = 0;
    end
    endtask


    initial begin

        errors = 0;
        RstN = 1;
        push = 0;
        pop = 0;
        Data_In = 0;


        // -------------------------
        // Test 1: Reset
        // -------------------------
        $display("Test 1: Reset");

        reset_stack();

        if (Data_Out !== 0) begin
            $display("ERROR: Data_Out must be zero after reset");
            errors = errors + 1;
        end


        // -------------------------
        // Test 2: Pop when empty
        // -------------------------
        $display("Test 2: Pop when empty");

        @(negedge Clk);
        pop = 1;

        @(posedge Clk);
        #1;

        if (Empty !== 1 || Full !== 0) begin
            $display("ERROR: Empty pop changed stack state");
            errors = errors + 1;
        end

        pop = 0;


        // -------------------------
        // Test 3: Push+Pop when empty
        // -------------------------
        $display("Test 3: Push-Pop when empty");

        @(negedge Clk);

        Data_In = 4'd10;
        push = 1;
        pop = 1;

        @(posedge Clk);
        #1;

        push = 0;
        pop = 0;

        if (Empty !== 0) begin
            $display("ERROR: Empty simultaneous operation failed");
            errors = errors + 1;
        end

        // Value 10 must have been pushed
        pop_value(4'd10);

        if (Empty !== 1) begin
            $display("ERROR: Stack must be empty");
            errors = errors + 1;
        end


        // -------------------------
        // Test 4: Normal LIFO
        // -------------------------
        $display("Test 4: Normal LIFO");

        push_value(4'd3);
        push_value(4'd6);
        push_value(4'd9);

        pop_value(4'd9);
        pop_value(4'd6);
        pop_value(4'd3);

        if (Empty !== 1) begin
            $display("ERROR: LIFO test did not end empty");
            errors = errors + 1;
        end


        // -------------------------
        // Test 5: Fill stack
        // -------------------------
        $display("Test 5: Fill stack");

        reset_stack();

        for (i = 1; i <= 8; i = i + 1) begin
            push_value(i);
        end

        if (Full !== 1 || Empty !== 0) begin
            $display("ERROR: Full flag is incorrect");
            errors = errors + 1;
        end


        // -------------------------
        // Test 6: Push when full
        // -------------------------
        $display("Test 6: Push when full");

        push_value(4'd15);

        if (Full !== 1) begin
            $display("ERROR: Full stack changed after extra push");
            errors = errors + 1;
        end

        // 15 must not overwrite 8
        pop_value(4'd8);


        // -------------------------
        // Test 7: Simultaneous at full
        // -------------------------
        $display("Test 7: Push-Pop when full");

        reset_stack();

        for (i = 1; i <= 8; i = i + 1) begin
            push_value(i);
        end

        // Pop 8 and replace it with 12
        push_pop(4'd12, 4'd8);

        if (Full !== 1) begin
            $display("ERROR: Stack must remain full");
            errors = errors + 1;
        end

        // New top must be 12
        pop_value(4'd12);


        // -------------------------
        // Test 8: Simultaneous normal
        // -------------------------
        $display("Test 8: Normal Push-Pop");

        reset_stack();

        push_value(4'd1);
        push_value(4'd2);
        push_value(4'd3);

        // Replace top 3 with 11
        push_pop(4'd11, 4'd3);

        // New top must be 11
        pop_value(4'd11);

        // Previous data must remain
        pop_value(4'd2);
        pop_value(4'd1);

        if (Empty !== 1) begin
            $display("ERROR: Stack should be empty");
            errors = errors + 1;
        end


        // -------------------------
        // Test 9: Idle state
        // -------------------------
        $display("Test 9: Idle state");

        reset_stack();

        push_value(4'd7);

        @(negedge Clk);
        push = 0;
        pop = 0;

        repeat(3) @(posedge Clk);

        // Value must still exist
        pop_value(4'd7);

        if (Empty !== 1) begin
            $display("ERROR: Idle state changed stack");
            errors = errors + 1;
        end


        // -------------------------
        // Test 10: Reset while non-empty
        // -------------------------
        $display("Test 10: Reset while non-empty");

        push_value(4'd4);
        push_value(4'd5);
        push_value(4'd6);

        // Asynchronous reset
        #2;
        RstN = 0;
        #1;

        if (Empty !== 1 || Full !== 0 || Data_Out !== 0) begin
            $display("ERROR: Async reset failed");
            errors = errors + 1;
        end

        RstN = 1;

        // -------------------------
        // Test 11: Push-Pop with one element
        // -------------------------
        $display("Test 11: Push-Pop with one element");

        reset_stack();

        push_value(4'd5);

        // Replace the only element
        push_pop(4'd9, 4'd5);

        if (Empty !== 0 || Full !== 0) begin
            $display("ERROR: Stack state changed incorrectly");
            errors = errors + 1;
        end

        // New top must be 9
        pop_value(4'd9);

        if (Empty !== 1) begin
            $display("ERROR: Stack should be empty");
            errors = errors + 1;
        end


        // -------------------------
        // Test 12: Reset while full
        // -------------------------
        $display("Test 12: Reset while full");

        reset_stack();

        for (i = 1; i <= 8; i = i + 1) begin
            push_value(i);
        end

        if (Full !== 1) begin
            $display("ERROR: Stack must be full before reset");
            errors = errors + 1;
        end

        // Asynchronous reset
        #2;
        RstN = 0;
        #1;

        if (Empty !== 1 || Full !== 0 || Data_Out !== 0) begin
            $display("ERROR: Reset while full failed");
            errors = errors + 1;
        end

        RstN = 1;
            // -------------------------
        // Final result
        // -------------------------
        #10;

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %d error(s)", errors);

        $finish;
        
    end

endmodule