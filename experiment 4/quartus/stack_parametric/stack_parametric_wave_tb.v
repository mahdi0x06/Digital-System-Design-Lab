`timescale 1ns/1ps

module stack_wave_tb #(
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

    integer i;


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
        $dumpfile("stack_parametric_wave.vcd");

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


    initial begin

        RstN = 0;
        push = 0;
        pop = 0;
        Data_In = 0;

        $display(
            "Waveform test: WIDTH=%0d DEPTH=%0d",
            WIDTH,
            DEPTH
        );


        // -------------------------
        // Reset
        // -------------------------
        #12;
        RstN = 1;


        // -------------------------
        // Fill stack
        // -------------------------
        for (i = 0; i < DEPTH; i = i + 1) begin

            @(negedge Clk);

            Data_In = i;
            push = 1;
            pop = 0;
        end

        @(negedge Clk);
        push = 0;


        // -------------------------
        // Push when full
        // -------------------------
        Data_In = {WIDTH{1'b1}};
        push = 1;

        @(negedge Clk);
        push = 0;


        // -------------------------
        // Pop all values
        // -------------------------
        pop = 1;

        repeat (DEPTH)
            @(posedge Clk);

        @(negedge Clk);
        pop = 0;


        // -------------------------
        // Pop when empty
        // -------------------------
        pop = 1;

        @(negedge Clk);
        pop = 0;


        // -------------------------
        // Reset again
        // -------------------------
        RstN = 0;
        #2;
        RstN = 1;


        // -------------------------
        // Push two values
        // -------------------------
        @(negedge Clk);
        Data_In = 1;
        push = 1;

        @(negedge Clk);
        Data_In = 2;

        @(negedge Clk);
        push = 0;


        // -------------------------
        // Simultaneous Push-Pop
        // -------------------------
        Data_In = 3;
        push = 1;
        pop = 1;

        @(negedge Clk);
        push = 0;
        pop = 0;


        // -------------------------
        // Pop replaced value
        // -------------------------
        pop = 1;

        @(negedge Clk);
        pop = 0;


        // End simulation
        #20;
        $finish;

    end

endmodule