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
// CREATED		"Sat Aug 08 12:03:43 2026"

module az2(
	IN,
	OUT,
	Ent,
	Clk,
	Reset,
	T,
	Open,
	Close
);


input wire	IN;
input wire	OUT;
input wire	Ent;
input wire	Clk;
input wire	Reset;
input wire	T;
output reg	Open;
output wire	Close;

wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_17;
wire	SYNTHESIZED_WIRE_18;
wire	SYNTHESIZED_WIRE_19;
wire	SYNTHESIZED_WIRE_20;
wire	SYNTHESIZED_WIRE_9;
wire	SYNTHESIZED_WIRE_10;
wire	SYNTHESIZED_WIRE_21;
wire	SYNTHESIZED_WIRE_13;
wire	SYNTHESIZED_WIRE_14;
wire	SYNTHESIZED_WIRE_15;
wire	SYNTHESIZED_WIRE_16;

assign	Close = SYNTHESIZED_WIRE_13;
assign	SYNTHESIZED_WIRE_9 = 1;




counter	b2v_inst(
	.U(IN),
	.Enable(SYNTHESIZED_WIRE_0),
	.Clk(Clk),
	.rst(Reset),
	.Q0(SYNTHESIZED_WIRE_17),
	.Q1(SYNTHESIZED_WIRE_19),
	.Q2(SYNTHESIZED_WIRE_20),
	.Q3(SYNTHESIZED_WIRE_18));

assign	SYNTHESIZED_WIRE_21 = ~(SYNTHESIZED_WIRE_17 & SYNTHESIZED_WIRE_18 & SYNTHESIZED_WIRE_19 & SYNTHESIZED_WIRE_20);

assign	SYNTHESIZED_WIRE_13 = ~(SYNTHESIZED_WIRE_17 | SYNTHESIZED_WIRE_20 | SYNTHESIZED_WIRE_19 | SYNTHESIZED_WIRE_18);


always@(posedge Clk or negedge Reset or negedge SYNTHESIZED_WIRE_9)
begin
if (!Reset)
	begin
	Open <= 0;
	end
else
	begin
if (!SYNTHESIZED_WIRE_9)
	begin
	Open <= 1;
	end
else
	begin
	Open <= ~Open & SYNTHESIZED_WIRE_10 | Open & ~IN;
	end
	end
end

assign	SYNTHESIZED_WIRE_10 = SYNTHESIZED_WIRE_21 & Ent & T;

assign	SYNTHESIZED_WIRE_16 = IN & SYNTHESIZED_WIRE_21;

assign	SYNTHESIZED_WIRE_14 =  ~SYNTHESIZED_WIRE_13;

assign	SYNTHESIZED_WIRE_15 = SYNTHESIZED_WIRE_14 & OUT;

assign	SYNTHESIZED_WIRE_0 = SYNTHESIZED_WIRE_15 ^ SYNTHESIZED_WIRE_16;



endmodule
