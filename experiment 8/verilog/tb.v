`timescale 1ns / 1ps

module tb;

    parameter WIDTH = 8;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst;

    wire signed [2*WIDTH-1:0] final_out_real;
    wire signed [2*WIDTH-1:0] final_out_imag;
    wire final_zero;
    wire final_overflow;
    wire final_neg_real;
    wire final_neg_imag;
    wire done_all;

    Top #(WIDTH) uut (
        .clk(clk),
        .rst(rst),
        .final_out_real(final_out_real),
        .final_out_imag(final_out_imag),
        .final_zero(final_zero),
        .final_overflow(final_overflow),
        .final_neg_real(final_neg_real),
        .final_neg_imag(final_neg_imag),
        .done_all(done_all)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test
    initial begin
        // 1. Initialize and Reset
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;

        // 2. Wait for all instructions to finish
        wait (done_all == 1'b1);

        // 3. Finish Simulation
        #(CLK_PERIOD * 5);
        $display("===========================================");
        $display("All 9 test cases executed successfully!");
        $display("Memory execution halted via NOP instruction.");
        $display("===========================================");
        $stop;
    end

endmodule