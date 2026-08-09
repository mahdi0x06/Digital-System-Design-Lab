// Copyright (C) 1991-2013 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, Altera MegaCore Function License 
// Agreement, or other applicable license agreement, including, 
// without limitation, that your use is for the sole purpose of 
// programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the 
// applicable agreement for further details.

// PROGRAM		"Quartus II 64-Bit"
// VERSION		"Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"
// CREATED		"Sat Aug 08 04:44:58 2026"

module counter(
	Clk,
	Enable,
	U,
	rst,
	Q0,
	Q1,
	Q2,
	Q3
);


input wire	Clk;
input wire	Enable;
input wire	U;
input wire	rst;
output wire	Q0;
output wire	Q1;
output wire	Q2;
output reg	Q3;

wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_1;
reg	SYNTHESIZED_WIRE_19;
wire	SYNTHESIZED_WIRE_2;
wire	SYNTHESIZED_WIRE_3;
wire	SYNTHESIZED_WIRE_20;
wire	SYNTHESIZED_WIRE_21;
reg	SYNTHESIZED_WIRE_22;
wire	SYNTHESIZED_WIRE_8;
wire	SYNTHESIZED_WIRE_23;
wire	SYNTHESIZED_WIRE_24;
reg	SYNTHESIZED_WIRE_25;
wire	SYNTHESIZED_WIRE_13;
wire	SYNTHESIZED_WIRE_14;
wire	SYNTHESIZED_WIRE_15;
wire	SYNTHESIZED_WIRE_16;
wire	SYNTHESIZED_WIRE_17;
wire	SYNTHESIZED_WIRE_18;

assign	Q0 = SYNTHESIZED_WIRE_19;
assign	Q1 = SYNTHESIZED_WIRE_22;
assign	Q2 = SYNTHESIZED_WIRE_25;




always@(posedge Clk or negedge rst)
begin
if (!rst)
	begin
	Q3 <= 0;
	end
else
	Q3 <= Q3 ^ SYNTHESIZED_WIRE_0;
end


always@(posedge Clk or negedge rst)
begin
if (!rst)
	begin
	SYNTHESIZED_WIRE_25 <= 0;
	end
else
	SYNTHESIZED_WIRE_25 <= SYNTHESIZED_WIRE_25 ^ SYNTHESIZED_WIRE_1;
end

assign	SYNTHESIZED_WIRE_3 =  ~SYNTHESIZED_WIRE_19;

assign	SYNTHESIZED_WIRE_21 = SYNTHESIZED_WIRE_2 & SYNTHESIZED_WIRE_3;

assign	SYNTHESIZED_WIRE_14 = SYNTHESIZED_WIRE_20 | SYNTHESIZED_WIRE_21;

assign	SYNTHESIZED_WIRE_23 = SYNTHESIZED_WIRE_20 & SYNTHESIZED_WIRE_22;

assign	SYNTHESIZED_WIRE_8 =  ~SYNTHESIZED_WIRE_22;

assign	SYNTHESIZED_WIRE_24 = SYNTHESIZED_WIRE_21 & SYNTHESIZED_WIRE_8;

assign	SYNTHESIZED_WIRE_1 = SYNTHESIZED_WIRE_23 | SYNTHESIZED_WIRE_24;

assign	SYNTHESIZED_WIRE_16 = SYNTHESIZED_WIRE_25 & SYNTHESIZED_WIRE_23;

assign	SYNTHESIZED_WIRE_15 = SYNTHESIZED_WIRE_24 & SYNTHESIZED_WIRE_13;

assign	SYNTHESIZED_WIRE_13 =  ~SYNTHESIZED_WIRE_25;


always@(posedge Clk or negedge rst)
begin
if (!rst)
	begin
	SYNTHESIZED_WIRE_22 <= 0;
	end
else
	SYNTHESIZED_WIRE_22 <= SYNTHESIZED_WIRE_22 ^ SYNTHESIZED_WIRE_14;
end

assign	SYNTHESIZED_WIRE_0 = SYNTHESIZED_WIRE_15 | SYNTHESIZED_WIRE_16;


always@(posedge Clk or negedge rst)
begin
if (!rst)
	begin
	SYNTHESIZED_WIRE_19 <= 0;
	end
else
	SYNTHESIZED_WIRE_19 <= SYNTHESIZED_WIRE_19 ^ Enable;
end

assign	SYNTHESIZED_WIRE_18 = U & Enable;

assign	SYNTHESIZED_WIRE_2 = SYNTHESIZED_WIRE_17 & Enable;

assign	SYNTHESIZED_WIRE_17 =  ~U;

assign	SYNTHESIZED_WIRE_20 = SYNTHESIZED_WIRE_18 & SYNTHESIZED_WIRE_19;


endmodule
