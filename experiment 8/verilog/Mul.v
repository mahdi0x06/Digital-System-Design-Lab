module Mul #(parameter WIDTH = 8) (
    input signed [WIDTH-1:0] a,
    input signed [WIDTH-1:0] b,
    output signed [(2*WIDTH)-1:0] result
);
    assign result = a * b;
endmodule