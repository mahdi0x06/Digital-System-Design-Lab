`timescale 1ns / 1ps

module tb_Mag2;
    parameter WIDTH = 8;
    
    reg signed [2*WIDTH-1:0] a2;
    reg signed [2*WIDTH-1:0] b2;
    reg signed [2*WIDTH-1:0] shared_add_sum;
    
    wire signed [2*WIDTH-1:0] result;
    wire overflow;
    
    Mag2 #(.WIDTH(WIDTH)) uut (
        .a2(a2), .b2(b2), .shared_add_sum(shared_add_sum),
        .result(result), .overflow(overflow)
    );
    
    initial begin
        $monitor("Time=%0t | a^2=%d, b^2=%d | result=%d | Overflow=%b", 
                 $time, a2, b2, result, overflow);
        
        // 1. Normal Magnitude: |3 + 4j|^2 = 9 + 16 = 25
        a2 = 16'd9; b2 = 16'd16; 
        shared_add_sum = 16'd25; // Simulating adder output
        #10;
        
        // 2. Normal Magnitude: |10 - 10j|^2 = 100 + 100 = 200
        a2 = 16'd100; b2 = 16'd100; 
        shared_add_sum = 16'd200; 
        #10;
        
        // 3. Overflow Case: 16-bit max is 32767. 
        // 20000 + 20000 = 40000 (Causes overflow in 16-bit signed)
        a2 = 16'd20000; b2 = 16'd20000; 
        shared_add_sum = -16'd25536; // 40000 in 16-bit two's complement appears negative
        #10;
        
        $stop;
    end
endmodule