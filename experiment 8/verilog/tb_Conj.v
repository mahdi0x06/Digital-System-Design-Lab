`timescale 1ns / 1ps

module tb_Conj;
    parameter WIDTH = 8;
    
    reg signed [WIDTH-1:0] A_real;
    reg signed [WIDTH-1:0] A_imag;
    reg signed [2*WIDTH-1:0] shared_mul_neg_imag;
    
    wire signed [2*WIDTH-1:0] result_real;
    wire signed [2*WIDTH-1:0] result_imag;
    wire overflow_imag;
    
    Conj #(.WIDTH(WIDTH)) uut (
        .A_real(A_real), .A_imag(A_imag), 
        .shared_mul_neg_imag(shared_mul_neg_imag),
        .result_real(result_real), .result_imag(result_imag), 
        .overflow_imag(overflow_imag)
    );
    
    initial begin
        $monitor("Time=%0t | A=(%d + %dj) | Result=(%d + %dj) | Overflow=%b", 
                 $time, A_real, A_imag, result_real, result_imag, overflow_imag);
        
        // 1. Normal Conjugate: (5 + 10j) -> (5 - 10j)
        A_real = 8'd5; A_imag = 8'd10; 
        shared_mul_neg_imag = -16'd10; // Simulating multiplier output
        #10;
        
        // 2. Normal Conjugate: (-15 - 20j) -> (-15 + 20j)
        A_real = -8'd15; A_imag = -8'd20; 
        shared_mul_neg_imag = 16'd20; // Simulating multiplier output
        #10;
        
        // 3. Overflow Case: Imaginary is -128 (Cannot be positive 128 in 8-bit)
        A_real = 8'd50; A_imag = -8'd128; 
        shared_mul_neg_imag = 16'd128; // Multiplier successfully calculates 128 in 16-bit
        #10;
        
        $stop;
    end
endmodule