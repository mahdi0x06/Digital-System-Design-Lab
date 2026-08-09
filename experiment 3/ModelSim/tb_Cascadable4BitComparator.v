
`timescale 1ns / 1ps

module tb_Cascadable4BitComparator;
    reg [3:0] A, B;
    reg A_gt_B_in, A_lt_B_in, A_eq_B_in;
    wire A_gt_B_out, A_lt_B_out, A_eq_B_out;

    Cascadable4BitComparator uut (
        .A(A), .B(B),
        .A_gt_B_in(A_gt_B_in), .A_lt_B_in(A_lt_B_in), .A_eq_B_in(A_eq_B_in),
        .A_gt_B_out(A_gt_B_out), .A_lt_B_out(A_lt_B_out), .A_eq_B_out(A_eq_B_out)
    );

    initial begin
        
        A_gt_B_in = 0; A_lt_B_in = 0; A_eq_B_in = 1;

     
        A = 4'b1111; B = 4'b1111; #10;

        
        A = 4'b1111; B = 4'b1110; #10;

       
        A = 4'b0011; B = 4'b1110; #10;

       
        A = 4'b0101; B = 4'b0001; #10;

        $stop;
    end
endmodule