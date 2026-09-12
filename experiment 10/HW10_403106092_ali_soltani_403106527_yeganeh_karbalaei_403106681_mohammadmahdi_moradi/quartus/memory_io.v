module memory_io (
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] address,
    input  wire [7:0] write_data,
    input  wire       write_enable,
    output reg  [7:0] read_data,

    input  wire [7:0] input_x,

    output reg  [3:0] hex_low,
    output reg  [3:0] hex_high,
    output reg        error_led,
    output reg        done_led
);

    // ------------------------------------------------------------
    // Memory-mapped I/O addresses
    // ------------------------------------------------------------

    localparam [7:0] ADDR_INPUT_X  = 8'hF8;
    localparam [7:0] ADDR_HEX_LOW  = 8'hF9;
    localparam [7:0] ADDR_HEX_HIGH = 8'hFA;
    localparam [7:0] ADDR_ERROR    = 8'hFB;
    localparam [7:0] ADDR_DONE     = 8'hFC;


    // ------------------------------------------------------------
    // Program and data memory
    // ------------------------------------------------------------

    reg [7:0] memory [0:247];

    integer i;


    // ------------------------------------------------------------
    // Memory initialization
    // ------------------------------------------------------------

    initial begin

        // Clear memory
        for (i = 0; i < 248; i = i + 1)
            memory[i] = 8'h00;

        // Load machine-code program
        $readmemh("program.hex", memory);

        hex_low   = 4'h0;
        hex_high  = 4'h0;
        error_led = 1'b0;
        done_led  = 1'b0;

    end


    // ------------------------------------------------------------
    // Combinational read
    // ------------------------------------------------------------

    always @(*) begin

        case (address)

            ADDR_INPUT_X: begin
                // Read input switches
                read_data = input_x;
            end

            ADDR_HEX_LOW,
            ADDR_HEX_HIGH,
            ADDR_ERROR,
            ADDR_DONE,
            8'hFD,
            8'hFE,
            8'hFF: begin
                // Write-only or reserved ports
                read_data = 8'h00;
            end

            default: begin

                if (address < 8'hF8)
                    read_data = memory[address];
                else
                    read_data = 8'h00;

            end

        endcase

    end


    // ------------------------------------------------------------
    // Synchronous write
    // ------------------------------------------------------------

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            // Reset output ports only
            hex_low   <= 4'h0;
            hex_high  <= 4'h0;
            error_led <= 1'b0;
            done_led  <= 1'b0;

        end

        else if (write_enable) begin

            case (address)

                ADDR_HEX_LOW: begin
                    // Store low hexadecimal digit
                    hex_low <= write_data[3:0];
                end

                ADDR_HEX_HIGH: begin
                    // Store high hexadecimal digit
                    hex_high <= write_data[3:0];
                end

                ADDR_ERROR: begin
                    // Update error LED
                    error_led <= write_data[0];
                end

                ADDR_DONE: begin
                    // Update done LED
                    done_led <= write_data[0];
                end

                ADDR_INPUT_X,
                8'hFD,
                8'hFE,
                8'hFF: begin
                    // Ignore writes to read-only or reserved addresses
                end

                default: begin

                    if (address < 8'hF8)
                        memory[address] <= write_data;

                end

            endcase

        end

    end

endmodule