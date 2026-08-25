`timescale 1ns / 1ps

module tb_AddSub;
    parameter WIDTH = 8;
    
    reg signed [WIDTH-1:0] a;
    reg signed [WIDTH-1:0] b;
    reg op;
    wire signed [WIDTH-1:0] result;
    wire overflow;
    
    AddSub #(.WIDTH(WIDTH)) uut (
        .a(a), .b(b), .op(op),
        .result(result), .overflow(overflow)
    );
    
    initial begin
        $monitor("Time=%0t | op=%b | a=%d, b=%d | result=%d | overflow=%b", 
                 $time, op, a, b, result, overflow);
        
        // 1. Normal Addition: 10 + 15 = 25
        a = 8'd10; b = 8'd15; op = 1'b0; #10;
        
        // 2. Normal Subtraction: 20 - 5 = 15
        a = 8'd20; b = 8'd5; op = 1'b1; #10;
        
        // 3. Negative Addition: -10 + (-15) = -25
        a = -8'd10; b = -8'd15; op = 1'b0; #10;
        
        // 4. Positive Overflow Addition: 100 + 50 = 150 (Max is 127)
        a = 8'd100; b = 8'd50; op = 1'b0; #10;
        
        // 5. Negative Overflow Subtraction: -100 - 50 = -150 (Min is -128)
        a = -8'd100; b = 8'd50; op = 1'b1; #10;
        
        $stop;
    end
endmodule