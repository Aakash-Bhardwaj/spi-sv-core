# SPI SV Core Verification Plan

## 1. Verification Objectives

The objective of verification is to ensure that the SPI SV Core satisfies all functional requirements defined in the project specification.

Verification confirms correct functionality through simulation, self-checking testbenches, assertions, synthesis, and static timing analysis.

---

## 2. Verification Methodology

Verification follows a layered approach consisting of:

- Directed testing
- Self-checking SystemVerilog testbenches
- Immediate SystemVerilog assertions
- Waveform analysis
- Generic RTL synthesis using Yosys
- Technology-mapped synthesis using Sky130 HDLL
- Static timing analysis using OpenSTA

---

## 3. Verification Environment

| Tool | Use |
|------|-----|
| Icarus Verilog | RTL simulation |
| GTKWave | Waveform viewing |
| Yosys | Generic RTL synthesis |
| Yosys + Sky130 HDLL | Technology mapping |
| OpenSTA | Static timing analysis |

---

## 4. Module Verification

### 4.1 SPI Master

Verified using a self-checking SystemVerilog testbench.

Verified properties:

- Reset behaviour
- All four SPI operating modes (CPOL/CPHA)
- MSB-first transmission
- LSB-first transmission
- Full-duplex data transfer
- Runtime configuration latching
- Mid-transaction configuration stability
- All-zeros data pattern
- All-ones data pattern
- Alternating data patterns
- Back-to-back transactions
- Randomized stress testing
- Parameterized data width

---

### 4.2 SPI Slave

Verified using a self-checking SystemVerilog testbench.

Verified properties:

*(To be completed.)*

---

### 4.3 SPI Top-Level

Verifies end-to-end communication between the SPI Master and SPI Slave modules using a self-checking SystemVerilog integration testbench.

Verified properties:

*(To be completed.)*

---

## 5. Functional Test Cases

The following test cases were implemented during verification.

### 5.1 SPI Master

Verified using a self-checking SystemVerilog testbench.

Verified properties:

- Reset behaviour
- All SPI operating modes
- MSB-first transfers
- LSB-first transfers
- Full-duplex communication
- Runtime configuration latching
- Mid-transaction configuration stability
- All-zeros transmission
- All-ones transmission
- Alternating data patterns
- Back-to-back transfers
- Randomized stress testing
- Parameterized operation

### Test Summary

| Test Case | Status |
|-----------|:------:|
| Reset | ✓ |
| SPI Mode 0 | ✓ |
| SPI Mode 1 | ✓ |
| SPI Mode 2 | ✓ |
| SPI Mode 3 | ✓ |
| MSB-First Transfer | ✓ |
| LSB-First Transfer | ✓ |
| All Zeros Pattern | ✓ |
| All Ones Pattern | ✓ |
| Alternating Patterns | ✓ |
| Back-to-Back Transfers | ✓ |
| Random Stress Testing | ✓ |

---

### 5.2 SPI Slave

*(To be completed.)*

---

### 5.3 SPI Top-Level

*(To be completed.)*

---

## 6. Assertions

### 6.1 SPI Master

Immediate SystemVerilog assertions were implemented to verify key SPI Master design invariants during simulation.

Verified properties:

- Chip-select (`cs_n`) and busy (`busy`) remain complementary throughout a transaction.
- `busy` and `done` are never asserted simultaneously.
- Output signals (`mosi`, `sclk`, `cs_n`, `rx_data`, `busy`, and `done`) never contain unknown (`X/Z`) values after reset.

All assertions passed during simulation.

### 6.2 SPI Slave

*To be completed.*

### 6.3 SPI Top-Level

*To be completed.*

---

## 7. Coverage Goals

The verification process aims to:

- Verify all FSM states
- Verify all FSM transitions
- Verify all SPI operating modes
- Verify runtime bit-order selection
- Verify parameter configurations
- Verify reset behaviour
- Verify boundary conditions
- Verify full-duplex operation

---

## 8. Success Criteria

Verification is considered complete when:

- All planned tests pass.
- All assertions pass.
- No simulation errors remain.
- Generic RTL synthesis completes successfully.
- Technology-mapped synthesis completes successfully.
- Static timing analysis reports no timing violations.

---

## 9. Static Timing Analysis Results

*To be completed after timing analysis.*

---

## 10. Future Verification Enhancements

Future versions of the verification environment may include:

- UVM
- Cocotb
- Constrained-random verification
- Functional coverage
- Formal verification