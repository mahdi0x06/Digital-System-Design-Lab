module Datapath #(parameter WIDTH = 8) (
    input clk,
    input rst,
    input [2:0] opcode, // Added so datapath knows when to use Conj and Mag2
    input signed [WIDTH-1:0] A_real,
    input signed [WIDTH-1:0] A_imag,
    input signed [WIDTH-1:0] B_real,
    input signed [WIDTH-1:0] B_imag,

    input [2:0] sel_mul_1,
    input [2:0] sel_mul_2,
    input [2:0] sel_add_1,
    input [2:0] sel_add_2,
    
    input add_sub_ctrl, 
    
    input en_reg1, en_reg2, en_reg3, en_reg4,
    input en_addout_real, en_addout_imag, en_mulout_real, en_mulout_imag,

    output reg signed [2*WIDTH-1:0] out_real,
    output reg signed [2*WIDTH-1:0] out_imag,
    output zero,
    output overflow,
    output negative_real,
    output negative_imag
);

    wire signed [2*WIDTH-1:0] A_real_ext = {{WIDTH{A_real[WIDTH-1]}}, A_real};
    wire signed [2*WIDTH-1:0] A_imag_ext = {{WIDTH{A_imag[WIDTH-1]}}, A_imag};
    wire signed [2*WIDTH-1:0] B_real_ext = {{WIDTH{B_real[WIDTH-1]}}, B_real};
    wire signed [2*WIDTH-1:0] B_imag_ext = {{WIDTH{B_imag[WIDTH-1]}}, B_imag};

    reg signed [2*WIDTH-1:0] reg1, reg2, reg3, reg4;

    // Multiplexers for Multiplier
    reg signed [WIDTH-1:0] mul_in1, mul_in2;
    always @(*) begin
        case(sel_mul_1)
            3'b000: mul_in1 = A_real;
            3'b001: mul_in1 = A_imag;
            3'b010: mul_in1 = B_real;
            3'b011: mul_in1 = B_imag;
            3'b100: mul_in1 = {WIDTH{1'b1}}; // -1 
            default: mul_in1 = 0;
        endcase

        case(sel_mul_2)
            3'b000: mul_in2 = A_real;
            3'b001: mul_in2 = A_imag;
            3'b010: mul_in2 = B_real;
            3'b011: mul_in2 = B_imag;
            3'b100: mul_in2 = {WIDTH{1'b1}}; // -1 
            default: mul_in2 = 0;
        endcase
    end

    wire signed [2*WIDTH-1:0] mul_out;
    Mul #(.WIDTH(WIDTH)) mult_unit (
        .a(mul_in1), .b(mul_in2), .result(mul_out)
    );

    // Multiplexers for Adder/Subtractor
    reg signed [2*WIDTH-1:0] add_in1, add_in2;
    always @(*) begin
        case(sel_add_1)
            3'b000: add_in1 = A_real_ext;
            3'b001: add_in1 = A_imag_ext;
            3'b010: add_in1 = B_real_ext;
            3'b011: add_in1 = B_imag_ext;
            3'b100: add_in1 = reg1;
            3'b101: add_in1 = reg2;
            3'b110: add_in1 = reg3;
            3'b111: add_in1 = reg4;
            default: add_in1 = 0;
        endcase

        case(sel_add_2)
            3'b000: add_in2 = A_real_ext;
            3'b001: add_in2 = A_imag_ext;
            3'b010: add_in2 = B_real_ext;
            3'b011: add_in2 = B_imag_ext;
            3'b100: add_in2 = reg1;
            3'b101: add_in2 = reg2;
            3'b110: add_in2 = reg3;
            3'b111: add_in2 = reg4;
            default: add_in2 = 0;
        endcase
    end

    wire signed [2*WIDTH-1:0] add_out;
    wire add_overflow;
    AddSub #(.WIDTH(2*WIDTH)) addsub_unit (
        .a(add_in1), .b(add_in2), .op(add_sub_ctrl), 
        .result(add_out), .overflow(add_overflow)
    );

    wire signed [2*WIDTH-1:0] conj_real, conj_imag;
    wire conj_overflow;
    Conj #(.WIDTH(WIDTH)) conj_unit (
        .A_real(A_real), .A_imag(A_imag), .shared_mul_neg_imag(mul_out),
        .result_real(conj_real), .result_imag(conj_imag), .overflow_imag(conj_overflow)
    );

    wire signed [2*WIDTH-1:0] mag2_result;
    wire mag2_overflow;
    Mag2 #(.WIDTH(WIDTH)) mag2_unit (
        .a2(reg1), .b2(reg2), .shared_add_sum(add_out),
        .result(mag2_result), .overflow(mag2_overflow)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg1 <= 0; reg2 <= 0; reg3 <= 0; reg4 <= 0;
            out_real <= 0; out_imag <= 0;
        end else begin
            if (en_reg1) reg1 <= mul_out;
            if (en_reg2) reg2 <= mul_out;
            if (en_reg3) reg3 <= mul_out;
            if (en_reg4) reg4 <= mul_out;

            if (en_addout_real) begin
                if (opcode == 3'b011) out_real <= conj_real;
                else if (opcode == 3'b100) out_real <= mag2_result;
                else out_real <= add_out;
            end
            else if (en_mulout_real) out_real <= mul_out;

            if (en_addout_imag) out_imag <= add_out;
            else if (en_mulout_imag) begin
                if (opcode == 3'b011) out_imag <= conj_imag;
                else out_imag <= mul_out;
            end
        end
    end

    // Flags
    assign zero = (out_real == 0 && out_imag == 0) ? 1'b1 : 1'b0;
    assign negative_real = out_real[2*WIDTH-1]; 
    assign negative_imag = out_imag[2*WIDTH-1];
    
    assign overflow = (opcode == 3'b011) ? conj_overflow :
                      (opcode == 3'b100) ? mag2_overflow :
                      add_overflow;

endmodule