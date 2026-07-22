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

*(To be completed.)*

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

### SPI Master

*(To be completed.)*

---

### SPI Slave

*(To be completed.)*

---

### SPI Top-Level

*(To be completed.)*

---

## 6. Assertions

Immediate SystemVerilog assertions will be implemented to verify key SPI design invariants during simulation.

Planned assertions include:

- Parameter validation
- FSM state validity
- Counter bounds
- Chip-select behaviour
- Clock generation correctness
- Busy/done signal consistency
- Detection of unknown (`X/Z`) values
- Protocol-specific design invariants

Assertion results will be documented after verification.

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