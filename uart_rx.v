// ==============================================================================
// Module: uart_rx
// Description: UART Receiver (RX) module with 16x oversampling.
//              Detects falling edge of start bit, verifies start bit stability
//              at center of bit (tick 7), samples 8 data bits at center (tick 15),
//              and checks stop bit for frame errors.
// ==============================================================================

`timescale 1ns / 1ps

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,            // Serial input line
    input  wire       tick_16x,      // 16x oversampling baud tick
    output reg  [7:0] rx_data,       // Received byte
    output reg        rx_valid,      // 1-cycle pulse when data byte is valid
    output reg        frame_error    // High if stop bit was not sampled high
);

    // FSM State Encoding
    localparam [2:0]
        STATE_IDLE  = 3'b000,
        STATE_START = 3'b001,
        STATE_DATA  = 3'b010,
        STATE_STOP  = 3'b011,
        STATE_DONE  = 3'b100;

    reg [2:0] state;
    reg [3:0] sample_cnt;  // 0 to 15 counter for 16x oversampling
    reg [2:0] bit_index;
    reg [7:0] shift_reg;
    reg       rx_sync1, rx_sync2; // 2-stage input synchronizer to prevent metastability

    // Synchronize asynchronous RX line to system clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    // Receiver FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= STATE_IDLE;
            sample_cnt  <= 4'd0;
            bit_index   <= 3'd0;
            shift_reg   <= 8'd0;
            rx_data     <= 8'd0;
            rx_valid    <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            rx_valid    <= 1'b0; // Default pulse low
            frame_error <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    sample_cnt <= 4'd0;
                    bit_index  <= 3'd0;
                    // Detect falling edge of start bit
                    if (!rx_sync2) begin
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (tick_16x) begin
                        if (sample_cnt == 4'd7) begin
                            // Sample at middle of start bit (tick 7)
                            if (!rx_sync2) begin
                                sample_cnt <= 4'd0; // Valid start bit confirmed
                                state      <= STATE_DATA;
                            end else begin
                                state      <= STATE_IDLE; // False alarm/glitch
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end

                STATE_DATA: begin
                    if (tick_16x) begin
                        if (sample_cnt == 4'd15) begin
                            sample_cnt            <= 4'd0;
                            shift_reg[bit_index]  <= rx_sync2; // Sample data bit at center
                            if (bit_index == 3'd7) begin
                                state <= STATE_STOP;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end

                STATE_STOP: begin
                    if (tick_16x) begin
                        if (sample_cnt == 4'd15) begin
                            sample_cnt <= 4'd0;
                            if (rx_sync2) begin // Stop bit should be HIGH
                                rx_data  <= shift_reg;
                                rx_valid <= 1'b1;
                            end else begin
                                frame_error <= 1'b1;
                            end
                            state <= STATE_IDLE;
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
