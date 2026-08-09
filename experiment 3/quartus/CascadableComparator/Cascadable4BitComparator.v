module Cascadable4BitComparator (
    input [3:0] A,
    input [3:0] B,
    input A_gt_B_in,   
    input A_lt_B_in,   
    input A_eq_B_in,   
    output A_gt_B_out,
    output A_lt_B_out,
    output A_eq_B_out
);

    
    wire [3:0] w_gt;
    wire [3:0] w_lt;
    wire [3:0] w_eq;

   
    Cascadable1BitComparator comp3 (
        .a(A[3]), .b(B[3]),
        .A_gt_B_in(A_gt_B_in), .A_lt_B_in(A_lt_B_in), .A_eq_B_in(A_eq_B_in),
        .A_gt_B_out(w_gt[3]), .A_lt_B_out(w_lt[3]), .A_eq_B_out(w_eq[3])
    );

   
    Cascadable1BitComparator comp2 (
        .a(A[2]), .b(B[2]),
        .A_gt_B_in(w_gt[3]), .A_lt_B_in(w_lt[3]), .A_eq_B_in(w_eq[3]),
        .A_gt_B_out(w_gt[2]), .A_lt_B_out(w_lt[2]), .A_eq_B_out(w_eq[2])
    );

 
    Cascadable1BitComparator comp1 (
        .a(A[1]), .b(B[1]),
        .A_gt_B_in(w_gt[2]), .A_lt_B_in(w_lt[2]), .A_eq_B_in(w_eq[2]),
        .A_gt_B_out(w_gt[1]), .A_lt_B_out(w_lt[1]), .A_eq_B_out(w_eq[1])
    );

   
    Cascadable1BitComparator comp0 (
        .a(A[0]), .b(B[0]),
        .A_gt_B_in(w_gt[1]), .A_lt_B_in(w_lt[1]), .A_eq_B_in(w_eq[1]),
        .A_gt_B_out(A_gt_B_out), .A_lt_B_out(A_lt_B_out), .A_eq_B_out(A_eq_B_out)
    );

endmodule