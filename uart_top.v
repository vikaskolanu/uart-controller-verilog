// ==============================================================================
// Module: uart_top
// Description: Top-level Full-Duplex UART Controller.
//              Integrates Baud Rate Generator, Transmitter (TX), and
//              Receiver (RX) with optional internal loopback mode.
// ==============================================================================

`timescale 1ns / 1ps

module uart_top #(
    parameter CLK_FREQ  = 50000000, // 50 MHz
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst_n,

    // Transmitter Interface
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_busy,
    output wire       tx_done,
    output wire       uart_tx_pin,

    // Receiver Interface
    input  wire       uart_rx_pin,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       frame_error,

    // Test Control
    input  wire       loopback_en // Connect TX directly to RX internally
);

    wire tick_16x;
    wire tick_1x;
    wire tx_serial;
    wire rx_serial;

    // Route RX signal: select external pin or internal loopback
    assign rx_serial   = loopback_en ? tx_serial : uart_rx_pin;
    assign uart_tx_pin = tx_serial;

    // Baud Rate Generator
    baud_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_gen (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick_16x (tick_16x),
        .tick_1x  (tick_1x)
    );

    // UART Transmitter
    uart_tx u_uart_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_start  (tx_start),
        .baud_tick (tick_1x),
        .tx_data   (tx_data),
        .tx        (tx_serial),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );

    // UART Receiver
    uart_rx u_uart_rx (
        .clk         (clk),
        .rst_n       (rst_n),
        .rx          (rx_serial),
        .tick_16x    (tick_16x),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .frame_error (frame_error)
    );

endmodule
