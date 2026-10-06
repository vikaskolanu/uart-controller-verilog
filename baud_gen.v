// ==============================================================================
// Module: baud_gen
// Description: Parameterized Baud Rate Generator.
//              Generates a 16x oversampling tick for the UART Receiver (RX)
//              and a 1x baud tick for the UART Transmitter (TX).
//
// Calculation:
//   ACC_LIMIT_16X = CLK_FREQ / (BAUD_RATE * 16)
//   Example: 50 MHz clock, 115200 baud:
//   50,000,000 / (115200 * 16) = 27.12 -> 27 cycles
// ==============================================================================

`timescale 1ns / 1ps

module baud_gen #(
    parameter CLK_FREQ  = 50000000, // 50 MHz
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_16x,           // 16x oversampling tick for RX
    output reg  tick_1x             // 1x baud tick for TX
);

    localparam LIMIT_16X = CLK_FREQ / (BAUD_RATE * 16);
    localparam COUNT_WIDTH = 16;

    reg [COUNT_WIDTH-1:0] count_16x;
    reg [3:0]             count_1x;

    // 16x Baud Tick Generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_16x <= 0;
            tick_16x  <= 0;
        end else if (count_16x == LIMIT_16X - 1) begin
            count_16x <= 0;
            tick_16x  <= 1'b1;
        end else begin
            count_16x <= count_16x + 1'b1;
            tick_16x  <= 1'b0;
        end
    end

    // 1x Baud Tick Generator (divide 16x tick by 16)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_1x <= 0;
            tick_1x  <= 0;
        end else if (tick_16x) begin
            if (count_1x == 4'd15) begin
                count_1x <= 0;
                tick_1x  <= 1'b1;
            end else begin
                count_1x <= count_1x + 1'b1;
                tick_1x  <= 1'b0;
            end
        end else begin
            tick_1x <= 1'b0;
        end
    end

endmodule
