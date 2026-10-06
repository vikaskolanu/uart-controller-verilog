# Configurable UART Protocol Controller with Baud Generator

A full-duplex, synthesizable Universal Asynchronous Receiver-Transmitter (UART) protocol controller implemented in Verilog HDL.

## Architecture & Features
- **Configurable Baud Rate Generator:** Divides the system clock (e.g., 50 MHz) to generate 16x oversampling ticks for reception and 1x ticks for transmission (9600 to 115200 baud).
- **Transmitter (TX) FSM:** 8-N-1 standard frame generation (1 start bit, 8 data bits LSB first, 1 stop bit) with busy and transmission-complete handshaking.
- **Noise-Immune Receiver (RX) FSM:**
  - 16x oversampling architecture.
  - Middle-of-bit sampling (tick 7 for start-bit verification, tick 15 for data bits) to maximize noise margins.
  - Built-in frame error detection for invalid stop-bit framing.
- **2-Stage Input Synchronizer:** Mitigates metastability on the external asynchronous RX line.
- **Hardware Loopback Test Mode:** Supports loopback verification for automated self-checking.

## Directory Structure
```
├── uart_top.v    # Top-level UART integration
├── baud_gen.v    # Baud rate frequency divider
├── uart_tx.v     # Serial transmitter FSM
├── uart_rx.v     # 16x oversampled receiver FSM
└── tb_uart.v     # Automated self-checking loopback testbench
```

## Simulation & Verification
Compiled and verified using **Icarus Verilog**:
```bash
iverilog -o sim_uart tb_uart.v uart_top.v baud_gen.v uart_tx.v uart_rx.v
vvp sim_uart
```
Waveforms can be viewed using GTKWave:
```bash
gtkwave uart.vcd
```
