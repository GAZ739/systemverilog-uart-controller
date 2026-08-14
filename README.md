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
└── testbench.sv\
## Simulation and Verification

The UART controller was simulated using Icarus Verilog with a 10 MHz system clock and 1 Mbps baud rate.

### Functional Tests

| Test | Result |
|---|---|
| TX/RX 0xA5 | PASS |
| TX/RX 0x55 | PASS |
| TX/RX 0x00 | PASS |
| TX/RX 0xFF | PASS |
| TX/RX 0x3C | PASS |
| Framing-error detection | PASS |
| Parity-error detection | PASS |
| Back-to-back transmission | PASS |

### Verification Features

The self-checking testbench verifies:

- Correct 8-bit UART data transmission and reception
- Even-parity generation and checking
- Detection of incorrect parity bits
- Detection of invalid stop bits
- Continuous back-to-back byte transmission
- RX synchronization
- `rx_valid`, `framing_error`, and `parity_error` status pulses

### Simulation Result

All functional and error-injection tests completed successfully.

======================================
BACK-TO-BACK UART TEST
======================================
PASS : Byte 1 TX=0xa5 RX=0xa5
PASS : Byte 2 TX=0x55 RX=0x55
PASS : Byte 3 TX=0x3c RX=0x3c

======================================
ALL UART TESTS COMPLETED
======================================

