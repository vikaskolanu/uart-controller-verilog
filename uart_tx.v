// ==============================================================================
// Module: uart_tx
// Description: UART Transmitter (TX) module.
//              Serializes 8-bit parallel data into UART frame format:
//              1 Start Bit (0) -> 8 Data Bits (LSB first) -> 1 Stop Bit (1).
// ==============================================================================

`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,      // Trigger transmission
    input  wire       baud_tick,     // 1x Baud rate tick
    input  wire [7:0] tx_data,       // Data byte to transmit
    output reg        tx,            // Serial output line
    output reg        tx_busy,       // High while transmission in progress
    output reg        tx_done        // 1-cycle pulse upon completion
);

    // FSM State Encoding
    localparam [2:0]
        STATE_IDLE  = 3'b000,
        STATE_START = 3'b001,
        STATE_DATA  = 3'b010,
        STATE_STOP  = 3'b011,
        STATE_DONE  = 3'b100;

    reg [2:0] state;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= STATE_IDLE;
            tx        <= 1'b1; // Idle line is HIGH in UART
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            bit_index <= 3'd0;
            data_reg  <= 8'd0;
        end else begin
            tx_done <= 1'b0; // Default pulse low

            case (state)
                STATE_IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        data_reg  <= tx_data;
                        tx_busy   <= 1'b1;
                        state     <= STATE_START;
                    end
                end

                STATE_START: begin
                    tx <= 1'b0; // Drive Start Bit (LOW)
                    if (baud_tick) begin
                        bit_index <= 3'd0;
                        state     <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    tx <= data_reg[bit_index]; // Transmit LSB first
                    if (baud_tick) begin
                        if (bit_index == 3'd7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                end

                STATE_STOP: begin
                    tx <= 1'b1; // Drive Stop Bit (HIGH)
                    if (baud_tick) begin
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
                    state   <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
