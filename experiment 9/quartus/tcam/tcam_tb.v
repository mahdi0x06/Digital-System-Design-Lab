`timescale 1ns/1ps

module tcam_tb;

    localparam WIDTH  = 16;
    localparam WORDS  = 16;
    localparam ADDR_W = 4;

    reg                   clk;
    reg                   rst_n;
    reg                   wr_en;
    reg  [ADDR_W-1:0]     wr_addr;
    reg  [WIDTH-1:0]      wr_data;
    reg  [WIDTH-1:0]      wr_mask;
    reg  [WIDTH-1:0]      search_data;

    wire [WORDS-1:0]      match;
    wire                  match_found;
    wire [ADDR_W-1:0]     match_addr;

    tcam #(
        .WIDTH (WIDTH),
        .WORDS (WORDS)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .wr_en       (wr_en),
        .wr_addr     (wr_addr),
        .wr_data     (wr_data),
        .wr_mask     (wr_mask),
        .search_data (search_data),
        .match       (match),
        .match_found (match_found),
        .match_addr  (match_addr)
    );

    always #5 clk = ~clk;

    task write_entry;
        input [ADDR_W-1:0] addr;
        input [WIDTH-1:0]  data;
        input [WIDTH-1:0]  mask;
        begin
            @(negedge clk);
            wr_en   = 1'b1;
            wr_addr = addr;
            wr_data = data;
            wr_mask = mask;
            @(negedge clk);
            wr_en   = 1'b0;
        end
    endtask

    task do_search;
        input [WIDTH-1:0] pattern;
        input [127:0]      label;
        begin
            search_data = pattern;
            #1; 
            $display("[%0t] %0s : search=%b -> match=%b  found=%b  addr=%0d",
                       $time, label, pattern, match, match_found, match_addr);
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        wr_en       = 1'b0;
        wr_addr     = {ADDR_W{1'b0}};
        wr_data     = {WIDTH{1'b0}};
        wr_mask     = {WIDTH{1'b0}};
        search_data = {WIDTH{1'b0}};

        #12 rst_n = 1'b1;

        write_entry(0, 16'h006E /*0000000001101110*/, 16'h00FF /* 7 bit*/);

        write_entry(1, 16'h0060 /*0000000001100000*/, 16'h00F0);

        write_entry(2, 16'h000E /*0000000000001110*/, 16'h000F);

        write_entry(3, 16'h0000, 16'h0000);

        #10;

        do_search(16'h006E, "test1(=01101110)");

        do_search(16'h0065, "test2(0110_0101)");

        do_search(16'h000E, "test3(0000_1110)");

        do_search(16'h00FF, "test4(1111_1111)");

        do_search(16'hABCD, "test5(unwritten regs must stay 0)");

        #20;
        $display("finished");
        $finish;
    end

endmodule
