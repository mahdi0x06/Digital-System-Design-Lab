module Conj #(parameter WIDTH = 8) (
    input signed [WIDTH-1:0] A_real,
    input signed [WIDTH-1:0] A_imag,
    input signed [2*WIDTH-1:0] shared_mul_neg_imag, // Taking A_imag * -1 from shared Mul
    output signed [2*WIDTH-1:0] result_real,
    output signed [2*WIDTH-1:0] result_imag,
    output overflow_imag
);
    assign result_real = {{WIDTH{A_real[WIDTH-1]}}, A_real}; // Sign extended real
    assign result_imag = shared_mul_neg_imag;
    
    // Overflow if imaginary is the most negative value
    assign overflow_imag = (A_imag[WIDTH-1] == 1'b1) && (result_imag[2*WIDTH-1] == 1'b1) && (A_imag != 0);
endmodule