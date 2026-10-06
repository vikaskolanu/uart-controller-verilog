# Configurable UART Protocol Controller with Baud Generator

A full-duplex, synthesizable Universal Asynchronous Receiver-Transmitter (UART) protocol controller implemented in Verilog HDL.

---

## Block Architecture

```mermaid
flowchart TD
    clk["50 MHz System Clock"] --> baud_gen["Baud Rate Generator<br/>baud_gen.v"]
    baud_gen -->|tick_1x: 115200 Baud| tx["UART Transmitter<br/>uart_tx.v"]
    baud_gen -->|tick_16x: 16x Oversample| rx["UART Receiver<br/>uart_rx.v"]
    
    subgraph Transmission ["Transmitter Path"]
        tx_data["tx_data[7:0]"] --> tx
        tx_start["tx_start"] --> tx
        tx -->|Serial Stream| uart_tx_pin["UART TX Pin"]
    end
    
    subgraph Reception ["Receiver Path"]
        uart_rx_pin["UART RX Pin"] --> rx_sync["2-Stage D-FF Sync"]
        rx_sync --> rx
        rx --> rx_data["rx_data[7:0]"]
        rx --> rx_valid["rx_valid pulse"]
        rx --> frame_error["frame_error flag"]
    end
```

---

## Receiver (RX) 16x Oversampling State Machine

```mermaid
stateDiagram-v2
    [*] --> STATE_IDLE
    STATE_IDLE --> STATE_START : rx falling edge detected
    
    STATE_START --> STATE_DATA : tick 7 confirmed (sample center == 0)
    STATE_START --> STATE_IDLE : false alarm / line glitch
    
    STATE_DATA --> STATE_DATA : sample at tick 15, shift into register
    STATE_DATA --> STATE_STOP : all 8 data bits received
    
    STATE_STOP --> STATE_IDLE : valid stop bit (assert rx_valid)
    STATE_STOP --> STATE_IDLE : invalid stop bit (assert frame_error)
```

---

## Key Hardware Design Features

1. **Configurable Baud Rate Generation:** Implements an integer divider counter generating 16$\times$ oversampling ticks from a $50\text{ MHz}$ master clock:
   $$\text{Divider}_{16\times} = \frac{f_{\text{system\_clk}}}{\text{Baud Rate} \times 16} = \frac{50,000,000}{115200 \times 16} \approx 27$$
2. **Noise-Immune 16$\times$ Oversampling:** Rejects transient line glitches by validating the start bit at the exact middle of the bit period (tick 7), and samples each data bit at tick 15 to maximize eye-diagram noise margins.
3. **Framing & Error Detection:** Validates stop bit framing and asserts `frame_error` upon protocol violations.
4. **Hardware Loopback Test Mode:** Enables built-in automated loopback testing for self-checking verification.

---

## Directory Structure

```
├── uart_top.v    # Top-level module integrating TX, RX, and Baud Gen
├── baud_gen.v    # Parameterized frequency divider
├── uart_tx.v     # 8-N-1 Serial transmitter FSM
├── uart_rx.v     # 16x oversampled serial receiver FSM
└── tb_uart.v     # Automated self-checking loopback testbench
```

---

## Simulation & Verification

The controller is compiled and tested with **Icarus Verilog**:

```bash
# Compile and run simulation
iverilog -o sim_uart tb_uart.v uart_top.v baud_gen.v uart_tx.v uart_rx.v
vvp sim_uart
```

### Simulation Output
```text
------------------------------------------------------------
   STARTING UART CONTROLLER VERIFICATION TESTBENCH          
------------------------------------------------------------
>>> Testing Loopback Transmissions across 4 distinct data patterns...
[PASS] Byte successfully transmitted and received: 0xa5
[PASS] Byte successfully transmitted and received: 0x3c
[PASS] Byte successfully transmitted and received: 0xff
[PASS] Byte successfully transmitted and received: 0x00
------------------------------------------------------------
   ALL UART CONTROLLER TESTS PASSED WITH ZERO ERRORS!       
------------------------------------------------------------
```

Waveforms can be inspected via GTKWave:
```bash
gtkwave uart.vcd
```
