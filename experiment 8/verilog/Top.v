module Top #(parameter WIDTH = 8) (
    input clk,
    input rst,
    output reg signed [2*WIDTH-1:0] final_out_real,
    output reg signed [2*WIDTH-1:0] final_out_imag,
    output reg final_zero,
    output reg final_overflow,
    output reg final_neg_real,
    output reg final_neg_imag,
    output reg done_all // 1 when all instructions in memory are executed
);

    // A_real, A_imag, B_real, B_imag, opcode
    localparam INST_WIDTH = (4 * WIDTH) + 3;

    // Memory: 32 words, dynamically sized
    reg [INST_WIDTH-1:0] memory [0:31];
    reg [4:0] pc; // Program Counter (0 to 31)
    reg [INST_WIDTH-1:0] ir; // Instruction Register

    // Pipeline States
    localparam FETCH   = 3'd0;
    localparam DECODE  = 3'd1;
    localparam EXECUTE = 3'd2;
    localparam UPDATE  = 3'd3;
    localparam STALL   = 3'd4;

    reg [2:0] pipe_state;

    reg start_alu;
    reg [2:0] opcode_reg;
    reg signed [WIDTH-1:0] A_real_reg, A_imag_reg, B_real_reg, B_imag_reg;

    wire [2:0] sel_mul_1, sel_mul_2;
    wire [2:0] sel_add_1, sel_add_2;
    wire add_sub_ctrl;
    wire en_reg1, en_reg2, en_reg3, en_reg4;
    wire en_addout_real, en_addout_imag, en_mulout_real, en_mulout_imag;
    wire valid;
    
    wire signed [2*WIDTH-1:0] dp_out_real, dp_out_imag;
    wire dp_zero, dp_overflow, dp_neg_real, dp_neg_imag;

    ControlUnit cu (
        .clk(clk),
        .rst(rst),
        .start(start_alu),
        .opcode(opcode_reg),
        .sel_mul_1(sel_mul_1),
        .sel_mul_2(sel_mul_2),
        .sel_add_1(sel_add_1),
        .sel_add_2(sel_add_2),
        .add_sub_ctrl(add_sub_ctrl),
        .en_reg1(en_reg1),
        .en_reg2(en_reg2),
        .en_reg3(en_reg3),
        .en_reg4(en_reg4),
        .en_addout_real(en_addout_real),
        .en_addout_imag(en_addout_imag),
        .en_mulout_real(en_mulout_real),
        .en_mulout_imag(en_mulout_imag),
        .valid(valid)
    );

    Datapath #(WIDTH) dp (
        .clk(clk),
        .rst(rst),
        .opcode(opcode_reg),
        .A_real(A_real_reg),
        .A_imag(A_imag_reg),
        .B_real(B_real_reg),
        .B_imag(B_imag_reg),
        .sel_mul_1(sel_mul_1),
        .sel_mul_2(sel_mul_2),
        .sel_add_1(sel_add_1),
        .sel_add_2(sel_add_2),
        .add_sub_ctrl(add_sub_ctrl),
        .en_reg1(en_reg1),
        .en_reg2(en_reg2),
        .en_reg3(en_reg3),
        .en_reg4(en_reg4),
        .en_addout_real(en_addout_real),
        .en_addout_imag(en_addout_imag),
        .en_mulout_real(en_mulout_real),
        .en_mulout_imag(en_mulout_imag),
        .out_real(dp_out_real),
        .out_imag(dp_out_imag),
        .zero(dp_zero),
        .overflow(dp_overflow),
        .negative_real(dp_neg_real),
        .negative_imag(dp_neg_imag)
    );

    initial begin
        $readmemh("E:/az8/verilog/memory.txt", memory);
    end

    // Pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 5'd0;
            pipe_state <= FETCH;
            start_alu <= 1'b0;
            done_all <= 1'b0;
            
            final_out_real <= 0;
            final_out_imag <= 0;
            final_zero <= 0;
            final_overflow <= 0;
            final_neg_real <= 0;
            final_neg_imag <= 0;
        end else begin
            case (pipe_state)
                FETCH: begin // Read instruction from memory
                    ir <= memory[pc];
                    pipe_state <= DECODE;
                end
                
                DECODE: begin // Decode and read operands
                    opcode_reg <= ir[INST_WIDTH-1 : 4*WIDTH];
                    A_real_reg <= ir[4*WIDTH-1  : 3*WIDTH];
                    A_imag_reg <= ir[3*WIDTH-1  : 2*WIDTH];
                    B_real_reg <= ir[2*WIDTH-1  : WIDTH];
                    B_imag_reg <= ir[WIDTH-1    : 0];
                    
                    if (ir[INST_WIDTH-1 : 4*WIDTH] == 3'b101) begin // NOP opcode
                        pipe_state <= STALL;
                    end else begin
                        start_alu <= 1'b1;
                        pipe_state <= EXECUTE;
                    end
                end
                
                EXECUTE: begin // Execute in ALU and wait for completion
                    start_alu <= 1'b0;
                    if (valid) begin
                        pipe_state <= UPDATE;
                    end
                end
                
                UPDATE: begin // Update flags and prepare for next instruction
                    final_out_real <= dp_out_real;
                    final_out_imag <= dp_out_imag;
                    final_zero <= dp_zero;
                    final_overflow <= dp_overflow;
                    final_neg_real <= dp_neg_real;
                    final_neg_imag <= dp_neg_imag;
                    
                    pc <= pc + 1; // Increment Program Counter
                    
                    if (pc == 5'd31) begin
                        pipe_state <= STALL; // Stop if memory is fully read
                    end else begin
                        pipe_state <= FETCH; // Go to next instruction
                    end
                end
                
                STALL: begin // Stop execution
                    done_all <= 1'b1;
                end
                
                default: pipe_state <= FETCH;
            endcase
        end
    end

endmodule