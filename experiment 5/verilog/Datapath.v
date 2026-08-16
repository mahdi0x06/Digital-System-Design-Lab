module Datapath(
    input clk,
    input rst,
    input done,
    input op,
    input valid, 
    input [2:0] shift_Q,
    input [2:0] shift_M,
    input [3:0] M,
    input [3:0] Q_in,
    output reg [7:0] result,
    output reg [3:0] Q_out
);

    reg [7:0] M_extended;

    always @(posedge clk) begin
        if (rst) begin
            result <= 8'b0;
            Q_out <= Q_in;
            M_extended <= {{4{M[3]}}, M};   // sign extend M to 8 bits
        end else begin
            if (!done) begin
                Q_out <= Q_out >> shift_Q;  // shift Q by shift_Q bits right
                
                if (valid) begin
                    if (op == 0) begin
                        result <= result + (M_extended << shift_M); // op = 0 --> add
                    end else begin
                        result <= result - (M_extended << shift_M); // op = 1 --> sub
                    end
                end
                
            end
        end
    end

endmodule