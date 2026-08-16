module Top(
    input clk,
    input rst,
    input [3:0] M,
    input [3:0] Q_in,
    output done,
    output [7:0] result
);

    wire [2:0] shift_Q;
    wire [2:0] shift_M;
    wire op;
    wire valid; 
    wire [3:0] Q_wire;  

    ControlUnit control_unit (
        .clk(clk),
        .rst(rst),
        .Q(Q_wire),
        .done(done),
        .op(op),
        .valid(valid),
        .shift_Q(shift_Q),
        .shift_M(shift_M)
    );

    Datapath datapath (
        .clk(clk),
        .rst(rst),
        .done(done),
        .op(op),
        .valid(valid),
        .shift_Q(shift_Q),
        .shift_M(shift_M),
        .M(M),
        .Q_in(Q_in),
        .result(result),
        .Q_out(Q_wire) 
    );
    
endmodule