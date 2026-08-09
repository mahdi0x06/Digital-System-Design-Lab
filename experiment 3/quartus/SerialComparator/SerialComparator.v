module SerialComparator (
    input serial_a,     
    input serial_b,     
    input clk,          
    input rst,           
    output out_greater, 
    output out_equal,   
    output out_smaller  
);

   
    wire master_greater, prev_greater;
    wire master_equal,   prev_equal;
    wire master_smaller, prev_smaller;


    wire next_greater, next_equal, next_smaller;

    assign next_greater = prev_greater | (prev_equal &  serial_a & ~serial_b);
    assign next_smaller = prev_smaller | (prev_equal & ~serial_a &  serial_b);
    assign next_equal   = prev_equal   & ~(serial_a ^ serial_b);

    
    wire d_gt = rst ? 1'b0 : next_greater;
    assign master_greater = clk  ? d_gt : master_greater;
    assign prev_greater   = ~clk ? master_greater : prev_greater;

   
    wire d_eq = rst ? 1'b1 : next_equal;
    assign master_equal = clk  ? d_eq : master_equal;
    assign prev_equal   = ~clk ? master_equal : prev_equal;

    wire d_sm = rst ? 1'b0 : next_smaller;
    assign master_smaller = clk  ? d_sm : master_smaller;
    assign prev_smaller   = ~clk ? master_smaller : prev_smaller;

  
    assign out_greater = prev_greater;
    assign out_equal   = prev_equal;
    assign out_smaller = prev_smaller;

endmodule