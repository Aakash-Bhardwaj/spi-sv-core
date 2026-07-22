# SPI SV Core Specification

## 1. Introduction

The SPI SV Core is a reusable, parameterized SystemVerilog implementation of the Serial Peripheral Interface (SPI) protocol. The design targets synthesizable RTL and follows a modular architecture consisting of independent SPI Master and SPI Slave modules with a top-level integration module for verification.

The design targets:

* FPGA implementation
* ASIC implementation
* Generic synthesis
* Sky130 HD technology mapping
* Educational and production-quality reusable IP

This project follows the documentation-driven development methodology established during the UART SV Core and FIFO SV Core projects.

---

## 2. Scope

This specification defines the functional and non-functional requirements for Version 1.0 of the SPI SV Core.

The initial implementation focuses on a standard SPI protocol supporting configurable transfer width, clock divider, clock polarity (CPOL), clock phase (CPHA), and bit ordering.

Version 1.0 implements:

* Independent SPI Master and SPI Slave modules
* Full-duplex communication
* Support for SPI Modes 0–3
* Runtime-configurable CPOL and CPHA
* Runtime-selectable MSB-first and LSB-first transmission
* Parameterized transfer width
* Parameterized master clock divider
* Active-low Chip Select (CS)

The following features are outside the scope of Version 1.0:

* Multi-master operation
* Multi-slave controller logic
* FIFOs
* DMA support
* Interrupt generation
* APB wrapper
* AXI4-Lite wrapper
* Quad SPI (QSPI)

---

## 3. Functional Requirements

### SPI Master

The SPI Master shall:

* Generate the SPI serial clock (`SCLK`).
* Generate the active-low Chip Select (`cs_n`) signal.
* Transmit serial data on `MOSI`.
* Receive serial data from `MISO`.
* Support all four SPI operating modes through runtime-configurable `CPOL` and `CPHA`.
* Support runtime-selectable MSB-first and LSB-first transmission.
* Support parameterized transfer width.
* Generate the SPI clock using a parameterized clock divider.
* Perform simultaneous transmission and reception (full-duplex).
* Accept a new transfer request only while idle.
* Generate a status indication when a transfer is in progress.
* Generate a transfer-complete indication after the final bit has been transferred.

### SPI Slave

The SPI Slave shall:

* Detect Chip Select (`cs_n`) assertion and deassertion.
* Receive serial data from `MOSI`.
* Transmit serial data on `MISO`.
* Support all four SPI operating modes through runtime-configurable `CPOL` and `CPHA`.
* Support runtime-selectable MSB-first and LSB-first transmission.
* Support parameterized transfer width.
* Perform simultaneous transmission and reception (full-duplex).
* Ignore bus activity while `cs_n` is deasserted.
* Generate a transfer-complete indication after the final bit has been transferred.

---

## 4. Parameters

| Parameter | Description |
|-----------|-------------|
| `DATA_WIDTH` | Number of bits transferred during each SPI frame. |
| `CLOCK_DIV` | Master clock divider used to generate the SPI serial clock. |

---

## 5. Interface

### SPI Master

#### Inputs

| Signal | Width | Description |
|--------|------:|-------------|
| `clk` | 1 | System clock |
| `rst_n` | 1 | Active-low reset |
| `start` | 1 | Transfer request |
| `tx_data` | `DATA_WIDTH` | Parallel transmit data |
| `miso` | 1 | Master In Slave Out |
| `cpol` | 1 | Clock polarity selection |
| `cpha` | 1 | Clock phase selection |
| `bit_order` | 1 | Bit transmission order |

#### Outputs

| Signal | Width | Description |
|--------|------:|-------------|
| `mosi` | 1 | Master Out Slave In |
| `sclk` | 1 | SPI serial clock |
| `cs_n` | 1 | Active-low Chip Select |
| `rx_data` | `DATA_WIDTH` | Received parallel data |
| `busy` | 1 | Transfer in progress |
| `done` | 1 | Transfer complete |

---

### SPI Slave

#### Inputs

| Signal | Width | Description |
|--------|------:|-------------|
| `clk` | 1 | System clock |
| `rst_n` | 1 | Active-low reset |
| `tx_data` | `DATA_WIDTH` | Parallel transmit data |
| `mosi` | 1 | Master Out Slave In |
| `sclk` | 1 | SPI serial clock |
| `cs_n` | 1 | Active-low Chip Select |
| `cpol` | 1 | Clock polarity selection |
| `cpha` | 1 | Clock phase selection |
| `bit_order` | 1 | Bit transmission order |

#### Outputs

| Signal | Width | Description |
|--------|------:|-------------|
| `miso` | 1 | Master In Slave Out |
| `rx_data` | `DATA_WIDTH` | Received parallel data |
| `done` | 1 | Transfer complete |

---

## 6. Operating Modes

The SPI SV Core shall support all four standard SPI operating modes.

| Mode | CPOL | CPHA | Clock Idle State | Data Sample Edge |
|------|:----:|:----:|------------------|------------------|
| 0 | 0 | 0 | Low | Rising |
| 1 | 0 | 1 | Low | Falling |
| 2 | 1 | 0 | High | Falling |
| 3 | 1 | 1 | High | Rising |

The selected operating mode shall remain unchanged throughout an active SPI transaction.

---

## 7. Timing Requirements

* All sequential logic shall operate on the rising edge of the system clock.
* The SPI Master shall generate `SCLK` using the parameterized clock divider.
* `cs_n` shall be asserted before the first transferred bit.
* `cs_n` shall remain asserted throughout the transaction.
* One bit shall be transmitted and one bit shall be received during each SPI clock period.
* Data shall be sampled according to the selected CPOL and CPHA configuration.
* No internally generated clocks other than the SPI serial clock shall be used.

---

## 8. Reset Behaviour

The SPI SV Core shall use an active-low synchronous reset.

Following reset:

### SPI Master

* `cs_n` shall return to its inactive state.
* `SCLK` shall return to its idle state according to `CPOL`.
* MOSI output shall return to its default state.
* Internal counters shall be cleared.
* Internal state machines shall return to their initial states.
* Status outputs shall return to their default values.

### SPI Slave

* Internal state machines shall return to their initial states.
* Receive logic shall return to the idle state.
* Status outputs shall return to their default values.
* MISO output shall return to its default state.

---

## 9. Parameter Validation

The implementation shall validate configuration parameters during elaboration whenever possible.

The following constraints apply:

* `DATA_WIDTH > 0`
* `CLOCK_DIV > 0`

---

## 10. Assumptions

The following assumptions apply to Version 1.0:

* A stable system clock is available.
* The SPI Master and SPI Slave operate correctly with their intended clocks. In the provided `spi_top` integration, the SPI Master generates `SCLK`, which is used by the SPI Slave during verification.
* Only one slave is selected during an SPI transaction.
* Runtime configuration (`CPOL`, `CPHA`, and `bit_order`) remains unchanged throughout an active transfer.
* External SPI signals satisfy setup and hold timing requirements.
* Parameter values are valid before synthesis.

---

## 11. Future Enhancements

Future versions of the SPI SV Core may include:

* Multi-slave controller support
* Multi-master arbitration
* Runtime-programmable clock divider
* FIFOs
* DMA support
* Interrupt generation
* APB wrapper
* AXI4-Lite wrapper
* Quad SPI (QSPI)
* Execute-In-Place (XIP)
* Formal verification