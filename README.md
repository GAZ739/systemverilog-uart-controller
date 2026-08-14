# SystemVerilog UART Controller

A parameterized UART controller designed and verified in SystemVerilog. The design implements UART transmission and reception with configurable clock and baud-rate parameters, even parity, framing-error detection, and support for back-to-back data transmission.

## Features

- Parameterized clock frequency and baud rate
- UART transmitter (TX)
- UART receiver (RX)
- 8-bit data transmission
- 1 start bit
- Even parity
- 1 stop bit
- RX/TX synchronization
- Framing-error detection
- Parity-error detection
- Back-to-back byte transmission
- Self-checking SystemVerilog testbench
- VCD waveform generation for simulation analysis

## UART Configuration

| Parameter | Value |
|---|---|
| Data bits | 8 |
| Start bits | 1 |
| Parity | Even |
| Stop bits | 1 |
| Clock frequency | 10 MHz |
| Baud rate | 1 Mbps |

## Project Structure

```text
systemverilog-uart-controller/
├── uart_tx.sv
├── uart_rx.sv
└── testbench.sv
