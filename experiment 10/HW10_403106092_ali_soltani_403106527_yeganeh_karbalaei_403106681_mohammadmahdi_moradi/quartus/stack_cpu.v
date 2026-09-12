module stack_cpu (
    input  wire       clk,
    input  wire       reset,

    output reg  [7:0] memory_address,
    input  wire [7:0] memory_read_data,
    output reg  [7:0] memory_write_data,
    output reg        memory_write_enable
);

    // ------------------------------------------------------------
    // Opcodes
    // ------------------------------------------------------------

    localparam [3:0] OP_PUSHC = 4'b0000;
    localparam [3:0] OP_PUSH  = 4'b0001;
    localparam [3:0] OP_POP   = 4'b0010;
    localparam [3:0] OP_JUMP  = 4'b0011;
    localparam [3:0] OP_JZ    = 4'b0100;
    localparam [3:0] OP_JS    = 4'b0101;
    localparam [3:0] OP_ADD   = 4'b0110;
    localparam [3:0] OP_SUB   = 4'b0111;
    localparam [3:0] OP_SWAP  = 4'b1000;
    localparam [3:0] OP_SHL   = 4'b1001;
    localparam [3:0] OP_CMP   = 4'b1010;


    // ------------------------------------------------------------
    // FSM states
    // ------------------------------------------------------------

    localparam [3:0] STATE_FETCH         = 4'd0;
    localparam [3:0] STATE_DECODE        = 4'd1;
    localparam [3:0] STATE_FETCH_OPERAND = 4'd2;
    localparam [3:0] STATE_PUSHC         = 4'd3;
    localparam [3:0] STATE_PUSH          = 4'd4;
    localparam [3:0] STATE_POP           = 4'd5;
    localparam [3:0] STATE_JUMP          = 4'd6;
    localparam [3:0] STATE_JZ            = 4'd7;
    localparam [3:0] STATE_JS            = 4'd8;
    localparam [3:0] STATE_ADD           = 4'd9;
    localparam [3:0] STATE_SUB           = 4'd10;
    localparam [3:0] STATE_SWAP          = 4'd11;
    localparam [3:0] STATE_SHL           = 4'd12;
    localparam [3:0] STATE_CMP           = 4'd13;


    // ------------------------------------------------------------
    // CPU registers
    // ------------------------------------------------------------

    reg [7:0] program_counter;
    reg [7:0] instruction_register;
    reg [7:0] operand_register;

    reg [7:0] stack [0:7];
    reg [3:0] stack_pointer;

    reg zero_flag;
    reg sign_flag;

    reg [3:0] state;

    integer i;


    // ------------------------------------------------------------
    // Datapath signals
    // ------------------------------------------------------------

    wire [3:0] opcode;

    wire [7:0] stack_top;
    wire [7:0] stack_second;

    wire [7:0] add_result;
    wire [7:0] sub_result;


    assign opcode = instruction_register[3:0];

    // Stack pointer points to the next free location
    assign stack_top =
        (stack_pointer > 0)
        ? stack[stack_pointer - 4'd1]
        : 8'd0;

    assign stack_second =
        (stack_pointer > 1)
        ? stack[stack_pointer - 4'd2]
        : 8'd0;

    assign add_result = stack_second + stack_top;

    // SUB and CMP use B - A
    assign sub_result = stack_second - stack_top;


    // ------------------------------------------------------------
    // Memory interface
    // ------------------------------------------------------------

    always @(*) begin

        // Fetch instructions by default
        memory_address      = program_counter;
        memory_write_data   = 8'd0;
        memory_write_enable = 1'b0;

        case (state)

            STATE_PUSH: begin
                // Read data from memory or input port
                memory_address = operand_register;
            end

            STATE_POP: begin
                // Write stack top to memory or output port
                memory_address      = operand_register;
                memory_write_data   = stack_top;
                memory_write_enable = 1'b1;
            end

            default: begin
                memory_address = program_counter;
            end

        endcase
    end


    // ------------------------------------------------------------
    // Control unit
    // ------------------------------------------------------------

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            program_counter     <= 8'd0;
            instruction_register <= 8'd0;
            operand_register     <= 8'd0;

            stack_pointer <= 4'd0;

            zero_flag <= 1'b0;
            sign_flag <= 1'b0;

            state <= STATE_FETCH;

            // Clear stack registers
            for (i = 0; i < 8; i = i + 1)
                stack[i] <= 8'd0;

        end

        else begin

            case (state)

                // ------------------------------------------------
                // Fetch instruction
                // ------------------------------------------------

                STATE_FETCH: begin

                    instruction_register <= memory_read_data;
                    program_counter <= program_counter + 8'd1;

                    state <= STATE_DECODE;

                end


                // ------------------------------------------------
                // Decode instruction
                // ------------------------------------------------

                STATE_DECODE: begin

                    case (opcode)

                        OP_PUSHC,
                        OP_PUSH,
                        OP_POP:
                            state <= STATE_FETCH_OPERAND;

                        OP_JUMP:
                            state <= STATE_JUMP;

                        OP_JZ:
                            state <= STATE_JZ;

                        OP_JS:
                            state <= STATE_JS;

                        OP_ADD:
                            state <= STATE_ADD;

                        OP_SUB:
                            state <= STATE_SUB;

                        OP_SWAP:
                            state <= STATE_SWAP;

                        OP_SHL:
                            state <= STATE_SHL;

                        OP_CMP:
                            state <= STATE_CMP;

                        default:
                            state <= STATE_FETCH;

                    endcase

                end


                // ------------------------------------------------
                // Fetch instruction operand
                // ------------------------------------------------

                STATE_FETCH_OPERAND: begin

                    operand_register <= memory_read_data;
                    program_counter <= program_counter + 8'd1;

                    case (opcode)

                        OP_PUSHC:
                            state <= STATE_PUSHC;

                        OP_PUSH:
                            state <= STATE_PUSH;

                        OP_POP:
                            state <= STATE_POP;

                        default:
                            state <= STATE_FETCH;

                    endcase

                end


                // ------------------------------------------------
                // PUSHC
                // ------------------------------------------------

                STATE_PUSHC: begin

                    stack[stack_pointer] <= operand_register;
                    stack_pointer <= stack_pointer + 4'd1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // PUSH
                // ------------------------------------------------

                STATE_PUSH: begin

                    stack[stack_pointer] <= memory_read_data;
                    stack_pointer <= stack_pointer + 4'd1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // POP
                // ------------------------------------------------

                STATE_POP: begin

                    // Memory write occurs through combinational interface
                    stack_pointer <= stack_pointer - 4'd1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // JUMP
                // ------------------------------------------------

                STATE_JUMP: begin

                    program_counter <= stack_top;
                    stack_pointer <= stack_pointer - 4'd1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // JZ
                // ------------------------------------------------

                STATE_JZ: begin

                    // Jump target is always removed from stack
                    if (zero_flag)
                        program_counter <= stack_top;

                    stack_pointer <= stack_pointer - 4'd1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // JS
                // ------------------------------------------------

                STATE_JS: begin

                    // Jump target is always removed from stack
                    if (sign_flag)
                        program_counter <= stack_top;

                    stack_pointer <= stack_pointer - 4'd1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // ADD
                // ------------------------------------------------

                STATE_ADD: begin

                    // Replace B and A with B + A
                    stack[stack_pointer - 4'd2] <= add_result;
                    stack_pointer <= stack_pointer - 4'd1;

                    // Update status flags
                    zero_flag <= (add_result == 8'd0);
                    sign_flag <= add_result[7];

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // SUB
                // ------------------------------------------------

                STATE_SUB: begin

                    // Replace B and A with B - A
                    stack[stack_pointer - 4'd2] <= sub_result;
                    stack_pointer <= stack_pointer - 4'd1;

                    // Update status flags
                    zero_flag <= (sub_result == 8'd0);
                    sign_flag <= sub_result[7];

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // SWAP
                // ------------------------------------------------

                STATE_SWAP: begin

                    // Exchange the top two stack elements
                    stack[stack_pointer - 4'd1]
                        <= stack[stack_pointer - 4'd2];

                    stack[stack_pointer - 4'd2]
                        <= stack[stack_pointer - 4'd1];

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // SHL
                // ------------------------------------------------

                STATE_SHL: begin

                    // Shift stack top left by one bit
                    stack[stack_pointer - 4'd1]
                        <= stack_top << 1;

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // CMP
                // ------------------------------------------------

                STATE_CMP: begin

                    // Compare B and A without modifying stack
                    zero_flag <= (sub_result == 8'd0);
                    sign_flag <= sub_result[7];

                    state <= STATE_FETCH;

                end


                // ------------------------------------------------
                // Recovery
                // ------------------------------------------------

                default: begin
                    state <= STATE_FETCH;
                end

            endcase

        end

    end

endmodule