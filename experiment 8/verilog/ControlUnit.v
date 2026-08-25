module ControlUnit (
    input clk,
    input rst,
    input start,
    input [2:0] opcode,

    output reg [2:0] sel_mul_1,
    output reg [2:0] sel_mul_2,
    output reg [2:0] sel_add_1,
    output reg [2:0] sel_add_2,
    output reg add_sub_ctrl, // 0 = add, 1 = sub
    output reg en_reg1, en_reg2, en_reg3, en_reg4,
    output reg en_addout_real, en_addout_imag, en_mulout_real, en_mulout_imag,
    output reg valid
);

localparam IDLE    = 5'd0;

localparam CADD1   = 5'd1;
localparam CADD2   = 5'd2;

localparam CSUB1   = 5'd3;
localparam CSUB2   = 5'd4;

localparam CONJ1   = 5'd5;
localparam CONJ2   = 5'd6;

localparam CMUL1   = 5'd7; 
localparam CMUL2   = 5'd8;
localparam CMUL3   = 5'd9;
localparam CMUL4   = 5'd10;
localparam CMUL5   = 5'd11;
localparam CMUL6   = 5'd12;
localparam CMUL7   = 5'd13;

localparam CMAG2_1 = 5'd14;
localparam CMAG2_2 = 5'd15;
localparam CMAG2_3 = 5'd16;
localparam CMAG2_4 = 5'd17;

reg [4:0] state;
reg [4:0] next_state;

always @(*) begin

    next_state = state; 
    
    case(state)
        IDLE: begin
            if(start) begin
                case(opcode)
                    3'b000: next_state = CADD1;
                    3'b001: next_state = CSUB1;
                    3'b010: next_state = CMUL1;
                    3'b011: next_state = CONJ1;
                    3'b100: next_state = CMAG2_1;
                    default: next_state = IDLE;
                endcase
            end else begin
                next_state = IDLE;
            end
        end
        
        CADD1:   next_state = CADD2;
        CADD2:   next_state = IDLE;
        
        CSUB1:   next_state = CSUB2;
        CSUB2:   next_state = IDLE;
        
        CONJ1:   next_state = CONJ2;
        CONJ2:   next_state = IDLE;
        
        CMUL1:   next_state = CMUL2;
        CMUL2:   next_state = CMUL3;
        CMUL3:   next_state = CMUL4;
        CMUL4:   next_state = CMUL5;
        CMUL5:   next_state = CMUL6;
        CMUL6:   next_state = CMUL7;
        CMUL7:   next_state = IDLE;
        
        CMAG2_1: next_state = CMAG2_2;
        CMAG2_2: next_state = CMAG2_3;
        CMAG2_3: next_state = CMAG2_4;
        CMAG2_4: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    sel_mul_1 = 3'b000; sel_mul_2 = 3'b000;
    sel_add_1 = 3'b000; sel_add_2 = 3'b000;
    add_sub_ctrl = 1'b0;
    en_reg1 = 1'b0; en_reg2 = 1'b0; en_reg3 = 1'b0; en_reg4 = 1'b0;
    en_addout_real = 1'b0; en_addout_imag = 1'b0;
    en_mulout_real = 1'b0; en_mulout_imag = 1'b0;
    valid = 1'b0;

    case(state)
        // add
        CADD1: begin // a + c
            sel_add_1 = 3'b000; // A_real_ext
            sel_add_2 = 3'b010; // B_real_ext
            add_sub_ctrl = 1'b0; // Add
            en_addout_real = 1'b1;
        end
        CADD2: begin // b + d
            sel_add_1 = 3'b001; // A_imag_ext
            sel_add_2 = 3'b011; // B_imag_ext
            add_sub_ctrl = 1'b0; // Add
            en_addout_imag = 1'b1;
            valid = 1'b1; 
        end
        
        // sub
        CSUB1: begin // a - c
            sel_add_1 = 3'b000; // A_real_ext
            sel_add_2 = 3'b010; // B_real_ext
            add_sub_ctrl = 1'b1; // Sub
            en_addout_real = 1'b1;
        end
        CSUB2: begin // b - d
            sel_add_1 = 3'b001; // A_imag_ext
            sel_add_2 = 3'b011; // B_imag_ext
            add_sub_ctrl = 1'b1; // Sub
            en_addout_imag = 1'b1;
            valid = 1'b1; 
        end

        // Conj
        CONJ1: begin // Pass A_real to output
            sel_add_1 = 3'b000;  // A_real_ext
            sel_add_2 = 3'b010;  // B_real_ext
            add_sub_ctrl = 1'b0; // Add
            en_addout_real = 1'b1;
        end
        CONJ2: begin // A_imag * (-1)
            sel_mul_1 = 3'b001;  // A_imag
            sel_mul_2 = 3'b100;  // -1
            en_mulout_imag = 1'b1;
            valid = 1'b1;
        end

        // Mul
        CMUL1: begin // a*c
            sel_mul_1 = 3'b000; // A_real
            sel_mul_2 = 3'b010; // B_real
            en_reg1 = 1'b1;
        end
        CMUL2: begin // b*d
            sel_mul_1 = 3'b001; // A_imag
            sel_mul_2 = 3'b011; // B_imag
            en_reg2 = 1'b1;
        end
        CMUL3: begin // a*d
            sel_mul_1 = 3'b000; // A_real
            sel_mul_2 = 3'b011; // B_imag
            en_reg3 = 1'b1;
        end
        CMUL4: begin // b*c
            sel_mul_1 = 3'b001; // A_imag
            sel_mul_2 = 3'b010; // B_real
            en_reg4 = 1'b1;
        end
        CMUL5: begin // ac - bd
            sel_add_1 = 3'b100;  // reg1 (ac)
            sel_add_2 = 3'b101;  // reg2 (bd)
            add_sub_ctrl = 1'b1; // Sub
            en_addout_real = 1'b1;
        end
        CMUL6: begin // ad + bc
            sel_add_1 = 3'b110;  // reg3 (ad)
            sel_add_2 = 3'b111;  // reg4 (bc)
            add_sub_ctrl = 1'b0; // Add
            en_addout_imag = 1'b1;
        end
        CMUL7: begin // Done
            valid = 1'b1;
        end

        // Mag2
        CMAG2_1: begin // a^2
            sel_mul_1 = 3'b000; // A_real
            sel_mul_2 = 3'b000; // A_real
            en_reg1 = 1'b1;
        end
        CMAG2_2: begin // b^2
            sel_mul_1 = 3'b001; // A_imag
            sel_mul_2 = 3'b001; // A_imag
            en_reg2 = 1'b1;
        end
        CMAG2_3: begin // a^2 + b^2
            sel_add_1 = 3'b100;  // reg1 (a^2)
            sel_add_2 = 3'b101;  // reg2 (b^2)
            add_sub_ctrl = 1'b0; // Add
            en_addout_real = 1'b1;
        end
        CMAG2_4: begin // Zero out imaginary part (reg1 - reg1 = 0)
            sel_add_1 = 3'b100;  // reg1
            sel_add_2 = 3'b100;  // reg1
            add_sub_ctrl = 1'b1; // Sub
            en_addout_imag = 1'b1;
            valid = 1'b1;
        end
    endcase
end

endmodule