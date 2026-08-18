module UARTTop (
	input wire			clk,
	input wire			rstN,
	input wire			new_data, 
	input wire 	[6:0]	send_data,

	output wire			tx, 
	output wire			busy, 
	output wire			rec_new_data,
	output wire	[6:0]	rec_data,
	output wire			correct_data
);
	
	parameter BIT_TICKS = 4;

	// Loopback line
	wire rx_line; 

	// Expose serial line
	assign tx = rx_line;

	// Sender instance
	UARTSender #(
		.BIT_TICKS(BIT_TICKS)
	) sender_inst (
		.clk			(clk),
		.rstN			(rstN),
		.new_data	(new_data),
		.send_data	(send_data),

		.tx			(rx_line),
		.busy			(busy)
	);

	// Receiver instance
	UARTReceiver #(
		.BIT_TICKS(BIT_TICKS)
	) receiver_inst (
		.clk				(clk),
		.rstN				(rstN),
		.rx				(rx_line),

		.rec_data		(rec_data),
		.rec_new_data	(rec_new_data),
		.correct_data	(correct_data)
	);

endmodule