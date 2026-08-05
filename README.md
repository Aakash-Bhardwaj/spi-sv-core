# SPI SV Core

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-RTL-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Stable-success)

A reusable, parameterized **SystemVerilog Serial Peripheral Interface (SPI) IP Core** consisting of independent SPI Master and SPI Slave modules together with a top-level integration wrapper for FPGA and ASIC implementations.

This project follows a structured documentation-driven RTL engineering workflow, progressing from specification and architecture through implementation, verification, synthesis, and static timing analysis. The goal is to develop a reusable SPI IP core while emphasizing good engineering practices, documentation, and reproducibility.

Each design decision is documented, verified, synthesized, and analyzed before integration.

---

# Objectives

- Design reusable SPI Master and SPI Slave IP cores.
- Follow modern SystemVerilog coding practices.
- Support configurable SPI operating modes (Mode 0–3).
- Support parameterized transfer width.
- Support parameterized SPI clock generation.
- Support runtime-selectable bit ordering.
- Develop comprehensive self-checking SystemVerilog testbenches.
- Verify functionality using self-checking testbenches and immediate assertions.
- Perform generic synthesis using Yosys.
- Perform technology-mapped synthesis using the Sky130 HDLL standard-cell library.
- Perform static timing analysis using OpenSTA.
- Maintain clear documentation throughout development.

---

# Planned Features

## Version 1.0.0

- [x] Independent SPI Master module
- [x] Independent SPI Slave module
- [x] Top-level Master–Slave integration
- [x] Parameterized data width
- [x] Parameterized SPI clock divider
- [x] Full-duplex communication
- [x] Runtime-selectable CPOL
- [x] Runtime-selectable CPHA
- [x] Runtime-selectable MSB/LSB transmission
- [x] Active-low Chip Select (`CS_N`)

## Future Roadmap

- [ ] Multi-chip-select SPI Master
- [ ] Multi-slave controller
- [ ] Multi-master arbitration
- [ ] Runtime-programmable clock divider
- [ ] FIFOs
- [ ] DMA support
- [ ] Interrupt generation
- [ ] APB wrapper
- [ ] AXI4-Lite wrapper
- [ ] Quad SPI (QSPI)
- [ ] Execute-In-Place (XIP)
- [ ] Formal verification

---

# Repository Structure

```text
rtl/             Synthesizable SystemVerilog RTL
tb/              Self-checking testbenches
assertions/      Immediate SystemVerilog assertions
constraints/     OpenSTA timing constraints
scripts/         Synthesis and timing scripts
reports/         Synthesis and timing reports
docs/            Project documentation
docs/images/     Architecture, FSM, datapath, waveform and timing figures
```

---

# Documentation

The project documentation is organized into the following documents.

| Document | Description |
|----------|-------------|
| [Specification](docs/specification.md) | Functional requirements, interfaces, timing requirements, reset behavior, assumptions, and future enhancements. |
| [Architecture](docs/architecture.md) | Design philosophy, module hierarchy, architectural organization, datapath, and control flow. |
| [Implementation](docs/implementation.md) | RTL implementation details, algorithms, design decisions, synthesis, and timing analysis. |
| [Verification](docs/verification.md) | Verification methodology, test cases, assertions, coverage goals, and timing validation. |

---

# Toolchain

| Tool | Purpose |
|------|---------|
| SystemVerilog | RTL Design |
| Icarus Verilog | RTL Simulation |
| GTKWave | Waveform Viewing |
| Yosys | Generic RTL Synthesis |
| Sky130 HDLL | Technology Mapping |
| OpenSTA | Static Timing Analysis |
| Git | Version Control |

---

# Development Workflow

```text
Specification
      ↓
Architecture
      ↓
RTL Implementation
      ↓
Architecture Update
      ↓
Implementation Documentation
      ↓
Verification
      ↓
Verification Documentation
      ↓
Generic Synthesis
      ↓
Technology Mapping
      ↓
Static Timing Analysis
      ↓
Final Documentation Review
```

---

# Project Status

- [x] Repository initialized
- [x] Project specification
- [x] Architecture
- [x] SPI Master RTL
- [x] SPI Master Verification
- [x] SPI Master Synthesis
- [x] SPI Slave RTL
- [x] SPI Slave Verification
- [x] SPI Slave Synthesis
- [x] Top-level integration
- [x] Verification
- [x] Generic synthesis
- [x] Technology-mapped synthesis
- [x] Static timing analysis

---

# Results

- All self-checking testbenches passed
- Generic synthesis completed successfully using Yosys
- Technology-mapped synthesis completed using Sky130 HDLL
- Static timing analysis passed using OpenSTA
- No setup timing violations observed

## Generic RTL Synthesis

| Module | Cells |
|---------|------:|
| SPI Master | 313 |
| SPI Slave | 296 |
| SPI Top | 609 |

## Technology-Mapped Synthesis (Sky130 HDLL)

| Module | Area (µm²) |
|---------|-----------:|
| SPI Master | 2159.5712 |
| SPI Slave | 2335.9904 |
| SPI Top | 4495.5616 |

## Static Timing Analysis

| Metric | Value |
|---------|------:|
| Worst Setup Slack | 16.03 ns |
| Worst Hold Slack | 0.32 ns |
| WNS | 0.00 ns |
| TNS | 0.00 ns |
| Timing Closure | PASS |

---

# License

This project is licensed under the MIT License.