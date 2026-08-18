module UARTReceiver (
	input wire			clk,
	input wire			rstN,
	input wire			rx, 

	output reg [6:0]	rec_data, 
	output reg			rec_new_data, 
	output reg			correct_data 	
); 
	
	parameter  BIT_TICKS = 4;

	// Receiver states
	localparam IDLE 	= 3'b000;
	localparam START	= 3'b001;
	localparam PARITY = 3'b010;
	localparam DATA 	= 3'b011;
	localparam STOP 	= 3'b100;

	localparam HALF_BIT_TICKS = (BIT_TICKS >= 2) ? (BIT_TICKS / 2) : 1;

	// Current state
	reg [2:0]	state;

	// Data bit index
	reg [2:0]	bit_idx;

	// Received data buffer
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
		// Reset receiver
		state				<= IDLE;
		rec_data			<= 7'b0;
		rec_new_data	<= 1'b0;
		correct_data	<= 1'b0;
		bit_idx			<= 3'd0;
		data_reg			<= 7'd0;
		parity_reg		<= 1'b0;
		tick_count		<= 0;
	  end
	  else
	  begin
		// Default pulse low
		rec_new_data	<= 1'b0;

		case (state)

			IDLE: 
			begin
			  // Wait for start
			  tick_count	<= 0;
			  bit_idx		<= 3'd0;

			  // Detect start bit
			  if (rx == 1'b0)
			  begin
				correct_data	<= 1'b0;
				state			<= START;		
			  end	
			end

			START:
			begin
			// Check start near center
			if (tick_count == HALF_BIT_TICKS - 1)
			begin
				tick_count <= 0;

				if (rx == 1'b0)
				begin
				state <= PARITY;
				end
				else
				begin
				state <= IDLE;
				end
			end
			else
			begin
				tick_count <= tick_count + 1;
			end
			end

			PARITY: 
			begin
			  // Sample parity bit
			  if (tick_count == BIT_TICKS - 1)
			  begin
				tick_count	<= 0; 
				parity_reg	<= rx; 
				bit_idx		<= 3'd0;
				state			<= DATA;
			  end
			  else 
			  begin
				tick_count <= tick_count + 1;
			  end
			end

			DATA: 
			begin
			  // Sample D0 to D6
			  if (tick_count == BIT_TICKS - 1)
			  begin
				tick_count			<= 0;
				data_reg[bit_idx]	<= rx; 

				// Move to stop bit
				if (bit_idx == 3'd6)
				begin
				  state	<= STOP; 
				end
				else 
				begin
				  bit_idx <= bit_idx + 3'd1;
				end
			  end
			  else 
			  begin
				tick_count <= tick_count + 1;
			  end
			end

			STOP: 
			begin
			  // Check stop bit
			  if (tick_count == BIT_TICKS - 1)
			  begin
				tick_count 		<= 0;
				rec_data			<= data_reg;
				rec_new_data	<= 1'b1;

				// Validate frame
				if ((rx == 1'b1) && ((^data_reg) == parity_reg))
				begin
				  correct_data	<= 1'b1;
				end
				else 
				begin
				  correct_data	<= 1'b0;
				end

				// Return to idle
				state <= IDLE;
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
			  rec_new_data	<= 1'b0;
			  correct_data	<= 1'b0;
			  bit_idx		<= 3'd0;
			  tick_count	<= 0;
			end

		endcase
	  end
	end

endmodule