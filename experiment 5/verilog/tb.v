module tb;
    reg clk;
    reg rst;
    reg signed [3:0] M;
    reg signed [3:0] Q_in;
    wire done;
    wire signed [7:0] result;

    Top uut (
        .clk(clk),
        .rst(rst),
        .M(M),
        .Q_in(Q_in),
        .done(done),
        .result(result)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        
        // Test Case 1: M=7, Q_in=5, result=35
        rst = 1;
        M = 7;
        Q_in = 5;
        #10;
        rst = 0;
        wait (done);
        #20;

        // Test Case 2: M=-4, Q_in=-6, result=24
        rst = 1;
        M = -4;
        Q_in = -6;
        #10;
        rst = 0;
        wait (done);
        #20;

        // Test Case 3: M=7, Q_in=-3, result=-21
        rst = 1;
        M = 7;
        Q_in = -3;
        #10;
        rst = 0;
        wait (done);
        #20;

        // Test Case 4: M=-5, Q_in=3, result=-15
        rst = 1;
        M = -5;
        Q_in = 3;
        #10;
        rst = 0;
        wait (done);
        #20;

        // Test Case 5: M=0, Q_in=-7, result=0
        rst = 1;
        M = 0;
        Q_in = -7;
        #10;
        rst = 0;
        wait (done);
        #20;

        // Test Case 6: M=-8, Q_in=7, result=-56
        rst = 1;
        M = -8;
        Q_in = 7;
        #10;
        rst = 0;
        wait (done);
        #20;

        // Test Case 7: M=5, Q_in=-1, result=-5
        rst = 1;
        M = 5;
        Q_in = -1;
        #10;
        rst = 0;
        wait (done);
        #20;

        $stop;
    end
endmodule