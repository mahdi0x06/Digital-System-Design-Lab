module Cascadable1BitComparator (
    input a,          
    input b,          
    input A_gt_B_in,   
    input A_lt_B_in,  
    input A_eq_B_in,   
    output A_gt_B_out, 
    output A_lt_B_out, 
    output A_eq_B_out  
);

    
    assign A_gt_B_out = A_gt_B_in | (A_eq_B_in & a & ~b);
    assign A_lt_B_out = A_lt_B_in | (A_eq_B_in & ~a & b);
    assign A_eq_B_out = A_eq_B_in & ~(a ^ b);

endmodule