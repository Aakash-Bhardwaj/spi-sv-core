# SPI SV Core Architecture

## 1. Design Overview

The SPI SV Core follows a modular architecture consisting of independent SPI Master and SPI Slave modules integrated through a top-level module for verification and system integration.

The design supports configurable data width, SPI operating modes, bit ordering, and master clock generation while maintaining a reusable and synthesizable RTL implementation suitable for both FPGA and ASIC targets.

Version 1 provides independent SPI Master and SPI Slave modules together with a top-level integration module for full-duplex communication, verification, synthesis, and timing analysis

---

## 2. Design Philosophy

The SPI SV Core is designed according to the following principles:

- Modular design
- Parameterization
- Reusability
- Synthesizable RTL
- Vendor-independent implementation
- Clear separation between datapath and control
- Documentation-driven development

The implementation avoids vendor-specific primitives wherever possible, allowing the same RTL to target FPGA and ASIC technologies through standard synthesis flows.

---

## 3. Module Hierarchy

```text
               spi_top
              /       \
             /         \
      spi_master    spi_slave
```

| Module | Description |
|---------|-------------|
| `spi_master` | Generates the SPI clock and controls SPI transactions. |
| `spi_slave` | Responds to SPI transactions initiated by the master. |
| `spi_top` | Integrates the master and slave modules for verification and system-level testing. |

---

## 4. Data Flow

### Master Transmit Path

```text
tx_data
   │
   ▼
SPI Master
   │
   ▼
MOSI
```

Parallel transmit data is serialized by the SPI Master and transmitted over the MOSI line.

### Slave Receive Path

```text
MOSI
   │
   ▼
SPI Slave
   │
   ▼
rx_data
```

Incoming serial data is received by the SPI Slave and reconstructed into parallel data.

### Slave Transmit Path

```text
tx_data
   │
   ▼
SPI Slave
   │
   ▼
MISO
```

Parallel transmit data is serialized by the SPI Slave and transmitted over the MISO line.

### Master Receive Path

```text
MISO
   │
   ▼
SPI Master
   │
   ▼
rx_data
```

Incoming serial data is received by the SPI Master and reconstructed into parallel data.

---

## 5. SPI Master

### Architectural Decisions

The SPI Master follows a synchronous single-clock architecture. All sequential logic operates exclusively on the system clock (`clk`).

The SPI serial clock (`SCLK`) is generated internally from the system clock using a parameterized clock divider. Rather than creating a separate clock domain, the divider generates one-cycle edge indicators (`sclk_rise` and `sclk_fall`) that synchronize all SPI protocol operations.

Configuration inputs (`CPOL`, `CPHA`, and `bit_order`) are sampled only when a new transaction begins and remain constant until the transaction completes. This ensures that protocol behaviour remains deterministic throughout an active SPI transaction, even if the external configuration inputs change.

The transmit and receive datapaths use independent shift registers to support full-duplex communication while maintaining a modular and reusable architecture.

The SPI Master uses a transaction-oriented finite-state machine consisting of the following states:

- IDLE
- START
- TRANSFER
- STOP

The START state initializes a new SPI transaction by:

- Latching the transmit data and runtime configuration
- Initializing internal registers and counters
- Asserting `CS_N`
- Initializing `SCLK` to the configured idle level
- Preloading the first transmit bit when `CPHA = 0`

During the TRANSFER state, SPI communication is performed using generalized protocol events derived from the latched configuration:

- `sample_edge`
- `shift_edge`

This abstraction enables a single datapath implementation to support all four SPI modes without duplicating protocol logic.

All externally visible outputs (`MOSI`, `SCLK`, `CS_N`, `busy`, and `done`) are implemented as registered outputs to provide predictable timing behaviour and simplify synthesis, timing analysis, and verification.

### Datapath Overview

The SPI Master datapath consists of the following major functional blocks:

```text
                    clk
                     │
              Clock Divider
                     │
      ┌──────────────┴──────────────┐
      ▼                             ▼
   sclk_reg                Edge Detection
                                     │
                      sample_edge / shift_edge
                                     │
                                     ▼
                             Transaction FSM
                                     │
         ┌───────────────┬───────────────┐
         ▼               ▼               ▼
  TX Shift Register  RX Shift Register  Bit Counter
         │               ▲
         ▼               │
      MOSI Register     MISO
```

### Internal Registers

The SPI Master maintains the following primary internal registers:

| Register | Purpose |
|----------|---------|
| `cpol_reg` | Latched clock polarity |
| `cpha_reg` | Latched clock phase |
| `bit_order_reg` | Latched bit transmission order |
| `tx_shift_reg` | Transmit shift register |
| `rx_shift_reg` | Receive shift register |
| `clk_div_counter` | SPI clock divider counter |
| `bit_count` | Tracks transmitted bits |
| `sclk_reg` | Registered SPI clock output |
| `mosi_reg` | Registered MOSI output |
| `cs_n_reg` | Registered chip-select output |
| `busy_reg` | Registered busy status |
| `done_reg` | Registered completion pulse |

---

## 6. SPI Slave

*The SPI Slave architecture will be documented after implementation.*

---

## 7. Top-Level Integration

The `spi_top` module integrates the SPI Master and SPI Slave into a reusable verification platform.

The top-level module is responsible for:

- Instantiating the SPI Master and SPI Slave modules.
- Passing configuration parameters.
- Connecting the SPI interface signals (`MOSI`, `MISO`, `SCLK`, and `cs_n`).
- Providing a clean system interface for simulation and verification.

The top-level module contains no protocol-specific datapath or control logic.

*Additional implementation details will be documented after the top-level module is completed.*

---

## 8. Future Architecture Extensions

Future versions of the SPI SV Core may include:

- Multi-chip-select SPI Master
- Multi-slave controller
- Multi-master arbitration
- Runtime-programmable clock divider
- FIFOs
- DMA support
- Interrupt generation
- APB wrapper
- AXI4-Lite wrapper
- Quad SPI (QSPI)
- Execute-In-Place (XIP)
- Formal verification