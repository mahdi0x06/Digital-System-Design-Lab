module UARTSender (
	input wire			clk,
	input wire			rstN,
	input wire			new_data,
	input wire	[6:0]	send_data,

	output reg	tx,
	output reg	busy
);
 
	parameter BIT_TICKS = 4;

	// Sender states
	localparam IDLE		= 3'b000;
	localparam START		= 3'b001;
	localparam PARITY		= 3'b010;
	localparam DATA		= 3'b011;
	localparam STOP		= 3'b100;

	// Current state
	reg [2:0]	state;

	// Data bit index
	reg [2:0]	bit_idx;

	// Saved input data
	reg [6:0]	data_reg;

	// Saved parity bit
	reg			parity_reg;

	// Bit timing counter
	integer tick_count;

	// Main sequential block
	always @(posedge clk or negedge rstN)
	begin
	  if (rstN == 1'b0)
	  begin
		// Reset sender
		state			<= IDLE;
		tx				<= 1'b1;
		busy			<= 1'b0;
		bit_idx		<= 3'd0;
		data_reg		<= 7'd0;
		parity_reg	<= 1'b0;
		tick_count	<= 0;
	  end
	  else
	  begin
		case (state)

			IDLE:
			begin
			  // Keep line idle high
			  tx			<= 1'b1;

			  // Sender is idle
			  busy		<= 1'b0;

			  // Clear frame counters
			  bit_idx		<= 3'd0;
			  tick_count	<= 0;

			  // Start on new data
			  if (new_data)
			  begin
				// Save input data
				data_reg	<= send_data;

				// Compute parity
				parity_reg	<= ^send_data;

				// Start transmission
				busy		<= 1'b1;
				tx			<= 1'b0;
				state		<= START;
			  end
			end

			START:
			begin
			  // Send start bit
			  busy	<= 1'b1;
			  tx		<= 1'b0;

			  // Keep start bit
			  if (tick_count == BIT_TICKS - 1)
			  begin
				// Go to parity
				tick_count	<= 0;
				tx				<= parity_reg;
				state			<= PARITY;
			  end
			  else
			  begin
				tick_count <= tick_count + 1;
			  end
			end

			PARITY:
			begin
			  // Send parity bit
			  busy	<= 1'b1;
			  tx		<= parity_reg;

			  // Keep parity bit
			  if (tick_count == BIT_TICKS - 1)
			  begin
				// Start with D0
				tick_count	<= 0;
				bit_idx		<= 3'd0;
				tx				<= data_reg[0];
				state			<= DATA;
			  end
			  else
			  begin
				tick_count <= tick_count + 1;
			  end
			end

			DATA:
			begin
			  // Send current bit
			  busy	<= 1'b1;
			  tx		<= data_reg[bit_idx];

			  // Keep each data bit
			  if (tick_count == BIT_TICKS - 1)
			  begin
				tick_count	<= 0;

				// Finish after D6
				if (bit_idx == 3'd6)
				begin
				  tx		<= 1'b1;
				  state	<= STOP;
				end
				else
				begin
				  // Select next bit
				  bit_idx	<= bit_idx + 3'd1;
				  tx			<= data_reg[bit_idx + 3'd1];
				end
			  end
			  else
			  begin
				tick_count <= tick_count + 1;
			  end
			end

			STOP:
			begin
			  // Send stop bit
			  busy	<= 1'b1;
			  tx		<= 1'b1;

			  // Keep stop bit
			  if (tick_count == BIT_TICKS - 1)
			  begin
				// Frame complete
				tick_count	<= 0;
				busy			<= 1'b0;
				state			<= IDLE;
			  end
			  else
			  begin
				tick_count <= tick_count + 1;
			  end
			end

			default:
			begin
			  // Recover to idle
			  state			<= IDLE;
			  tx				<= 1'b1;
			  busy			<= 1'b0;
			  bit_idx		<= 3'd0;
			  tick_count	<= 0;
			end

		endcase
	  end
	end

endmodule