module tcam #(
    parameter WIDTH   = 16,                
    parameter WORDS   = 16,               
    parameter ADDR_W  = $clog2(WORDS)       
)(
    input  wire                  clk,
    input  wire                  rst_n,     

    input  wire                  wr_en,
    input  wire [ADDR_W-1:0]     wr_addr,
    input  wire [WIDTH-1:0]      wr_data,  
    input  wire [WIDTH-1:0]      wr_mask, 

    input  wire [WIDTH-1:0]      search_data,

    output wire [WORDS-1:0]      match,      
    output wire                  match_found, 
    output wire [ADDR_W-1:0]     match_addr  
);

    reg [WIDTH-1:0] data_mem [0:WORDS-1];
    reg [WIDTH-1:0] mask_mem [0:WORDS-1];
    reg             valid_mem[0:WORDS-1];   

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < WORDS; i = i + 1) begin
                data_mem[i]  <= {WIDTH{1'b0}};
                mask_mem[i]  <= {WIDTH{1'b0}};
                valid_mem[i] <= 1'b0;
            end
        end
        else if (wr_en) begin
            data_mem[wr_addr]  <= wr_data;
            mask_mem[wr_addr]  <= wr_mask;
            valid_mem[wr_addr] <= 1'b1;
        end
    end

    genvar g;
    generate
        for (g = 0; g < WORDS; g = g + 1) begin : gen_match
            assign match[g] = valid_mem[g] &
                               ( &( ~mask_mem[g] | ~(data_mem[g] ^ search_data) ) );
        end
    endgenerate

    assign match_found = |match;

    function [ADDR_W-1:0] priority_encode;
        input [WORDS-1:0] m;
        integer k;
        begin
            priority_encode = {ADDR_W{1'b0}};
            for (k = WORDS-1; k >= 0; k = k - 1) begin
                if (m[k])
                    priority_encode = k[ADDR_W-1:0];
            end
        end
    endfunction

    assign match_addr = priority_encode(match);

endmodule
