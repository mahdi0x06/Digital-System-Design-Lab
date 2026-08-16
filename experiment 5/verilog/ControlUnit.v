module ControlUnit(
    input clk,
    input rst,
    input [3:0] Q,
    output done,
    output op,  // 0: add, 1: sub
    output valid,
    output [2:0] shift_Q,
    output reg [2:0] shift_M
);

    wire [2:0] first_one;
    wire [2:0] first_zero;

    assign first_one = (Q[0] == 1) ? 3'b000 :
                       (Q[1] == 1) ? 3'b001 :
                       (Q[2] == 1) ? 3'b010 :
                       (Q[3] == 1) ? 3'b011 : 3'b100;

    assign first_zero = (Q[0] == 0) ? 3'b000 :
                        (Q[1] == 0) ? 3'b001 :
                        (Q[2] == 0) ? 3'b010 :
                        (Q[3] == 0) ? 3'b011 : 3'b100;

    assign op = (Q[0] == 0) ? 0 : 1; 
    
    assign valid = ~((shift_M == 0) && (Q[0] == 0));

    assign shift_Q = (Q[0] == 0) ? first_one - first_zero : first_zero - first_one; // Calculate shift amount

    always @(posedge clk) begin
        if (rst) begin
            shift_M <= 0;
        end else begin
            if (!done) begin
                shift_M <= shift_M + shift_Q;
            end
        end
    end

    assign done = (shift_M >= 3'b100) ? 1 : 0;  // if shift_M reaches 4 --> done

endmodule