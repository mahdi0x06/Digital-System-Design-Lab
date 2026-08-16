module stack (
    input Clk,
    input RstN,
    input push,
    input pop,
    input [3:0] Data_In,
    output Full,
    output Empty,
    output reg [3:0] Data_Out
);

    // 8 entries, each 4 bits wide
    reg [3:0] stack [0:7];

    // Number of stored elements (0 to 8)
    reg [3:0] pointer;

    integer i;

    // Stack status flags
    assign Empty = (pointer == 0);
    assign Full  = (pointer == 8);

    // Stack operations
    always @(posedge Clk or negedge RstN) begin

        // Active-low asynchronous reset
        if (!RstN) begin
            pointer  <= 4'd0;
            Data_Out <= 4'd0;

            // Clear stack memory
            for (i = 0; i < 8; i = i + 1) begin
                stack[i] <= 4'd0;
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