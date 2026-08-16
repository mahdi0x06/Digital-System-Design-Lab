`timescale 1ns/1ns
module Incubator_Control_Testbench;

    reg clk, rst;
    reg  signed [7:0] temp_in;
    wire heater, cooler;
    wire [1:0] fan_speed;
    wire error_sensor;

    Incubator_Control dut (
        .clk(clk),
        .rst(rst),
        .temp(temp_in),
        .heater(heater),
        .cooler(cooler),
        .fan_speed(fan_speed),
        .error_sensor(error_sensor)
    );

    initial clk = 0;
    always #2 clk = ~clk;   

    real temperature_real;

    parameter real HEAT_RATE  = 4.0;
    parameter real COOL_LOW   = 2.0;  
    parameter real COOL_MED   = 5.0;  
    parameter real COOL_HIGH  = 8.0;  
    parameter real T_INIT     = 20.0;

    real delta;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            temperature_real <= T_INIT;
        end else begin
            delta = 0.0;
            if (heater) delta = delta + HEAT_RATE;
            if (cooler) begin
                case (fan_speed)
                    2'b01: delta = delta - COOL_LOW;
                    2'b10: delta = delta - COOL_MED;
                    2'b11: delta = delta - COOL_HIGH;
                    default: delta = delta;
                endcase
            end
            temperature_real <= temperature_real + delta;
        end
    end

    integer temp_int;
    always @(*) begin
        temp_int = temperature_real;              
        if (temp_int > 127)  temp_int = 127;
        if (temp_int < -128) temp_int = -128;
        temp_in = temp_int[7:0];
    end

    initial begin
        rst = 1;
        #12  rst = 0;

        force temperature_real = 100.0;
        #20;
        release temperature_real;

        #40; 

       
        force temperature_real = 10.0;
        #20;
        release temperature_real;

        #200; 

        $stop;
    end

    always @(posedge clk) begin
        $display("t=%0t  T=%0d  Heater=%b  Cooler=%b  Fan=%b  Err=%b",
                  $time, $signed(temp_in), heater, cooler, fan_speed, error_sensor);
    end

endmodule
