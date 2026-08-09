
`timescale 1ns / 1ps

module tb_SerialComparator;
    reg serial_a;
    reg serial_b;
    reg clk;
    reg rst;

    wire out_greater;
    wire out_equal;
    wire out_smaller;

    SerialComparator uut (
        .serial_a(serial_a),
        .serial_b(serial_b),
        .clk(clk),
        .rst(rst),
        .out_greater(out_greater),
        .out_equal(out_equal),
        .out_smaller(out_smaller)
    );

    
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        serial_a = 0;
        serial_b = 0;

        #12 rst = 0; 

        
        
        serial_a = 1; serial_b = 1; #10;
        
        serial_a = 0; serial_b = 0; #10;

        serial_a = 1; serial_b = 0; #10;

        serial_a = 0; serial_b = 1; #10;

        #20;
        $stop;
    end
endmodule