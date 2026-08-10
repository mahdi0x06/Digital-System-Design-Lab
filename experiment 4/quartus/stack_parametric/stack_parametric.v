module stack_parametric #(
	parameter WIDTH = 4,
	parameter DEPTH = 8
)
(
    input Clk,
    input RstN,
    input push,
    input pop,
    input [WIDTH - 1:0] Data_In,
    output Full,
    output Empty,
    output reg [WIDTH - 1:0] Data_Out
);

    // DEPTH entries, each WIDTH bits wide
    reg [WIDTH - 1:0] stack [0:DEPTH - 1];

    // Number of stored elements (0 to DEPTH)
    localparam PTR_WIDTH = $clog2(DEPTH + 1);
    reg [PTR_WIDTH - 1:0] pointer;
    integer i;

    // Stack status flags
    assign Empty = (pointer == 0);
    assign Full  = (pointer == DEPTH);

    // Stack operations
    always @(posedge Clk or negedge RstN) begin

        // Active-low asynchronous reset
        if (!RstN) begin
            pointer  <= 0;
            Data_Out <= 0;

            // Clear stack memory
            for (i = 0; i < DEPTH; i = i + 1) begin
                stack[i] <= 0;
            end
        end

        else begin

            // Simultaneous push and pop
            if (push && pop) begin

                // If empty, only push the new data
                if (Empty) begin
                    stack[pointer] <= Data_In;
                    pointer <= pointer + 1;
                end

                // Replace the top element
                else begin
                    Data_Out <= stack[pointer - 1];
                    stack[pointer - 1] <= Data_In;
                end
            end

            // Push operation
            else if (push) begin
                if (!Full) begin
                    stack[pointer] <= Data_In;
                    pointer <= pointer + 1;
                end
            end

            // Pop operation
            else if (pop) begin
                if (!Empty) begin
                    Data_Out <= stack[pointer - 1];
                    pointer <= pointer - 1;
                end
            end

        end
    end

endmodule