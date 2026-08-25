`timescale 1ns / 1ps

module tb_Mul;
    parameter WIDTH = 8;
    
    reg signed [WIDTH-1:0] a;
    reg signed [WIDTH-1:0] b;
    wire signed [(2*WIDTH)-1:0] result;
    
    Mul #(.WIDTH(WIDTH)) uut (
        .a(a), .b(b), .result(result)
    );
    
    initial begin
        $monitor("Time=%0t | a=%d, b=%d | result=%d", 
                 $time, a, b, result);
        
        // 1. Positive * Positive: 12 * 10 = 120
        a = 8'd12; b = 8'd10; #10;
        
        // 2. Positive * Negative: 15 * -4 = -60
        a = 8'd15; b = -8'd4; #10;
        
        // 3. Negative * Negative: -8 * -8 = 64
        a = -8'd8; b = -8'd8; #10;
        
        // 4. Max Positive * Max Positive: 127 * 127 = 16129
        a = 8'd127; b = 8'd127; #10;
        
        // 5. Max Negative * Max Negative: -128 * -128 = 16384
        a = -8'd128; b = -8'd128; #10;
        
        $stop;
    end
endmodule