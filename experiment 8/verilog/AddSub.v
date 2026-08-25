module AddSub #(parameter WIDTH = 8) (
    input signed [WIDTH-1:0] a,
    input signed [WIDTH-1:0] b,
    input op, // 0: Add, 1: Sub
    output signed [WIDTH-1:0] result,
    output overflow
);
    assign result = (op == 1'b0) ? (a + b) : (a - b);
    
    wire sign_a = a[WIDTH-1];
    wire sign_b = b[WIDTH-1];
    wire sign_r = result[WIDTH-1];
    
    assign overflow = (op == 1'b0) ? 
                      (~sign_a & ~sign_b & sign_r) | (sign_a & sign_b & ~sign_r) :
                      (~sign_a & sign_b & sign_r) | (sign_a & ~sign_b & ~sign_r);
endmodule