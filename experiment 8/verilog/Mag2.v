module Mag2 #(parameter WIDTH = 8) (
    input signed [2*WIDTH-1:0] a2, // from Datapath reg1
    input signed [2*WIDTH-1:0] b2, // from Datapath reg2
    input signed [2*WIDTH-1:0] shared_add_sum, // from shared AddSub
    output signed [2*WIDTH-1:0] result,
    output overflow
);
    assign result = shared_add_sum;
    // Overflow check for addition of two positive numbers
    assign overflow = (~a2[2*WIDTH-1] & ~b2[2*WIDTH-1] & shared_add_sum[2*WIDTH-1]);
endmodule