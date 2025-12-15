# I2C Verification Test Plan

## 1. Introduction
This document defines the verification strategy for the I2C (Inter-Integrated Circuit) UVM Verification IP (VIP). The goal is to ensure the VIP is compliant with the **NXP I2C-bus specification (UM10204)** and robust enough to verify compliant DUTs (Device Under Test).

### 1.1 Scope
The initial release targets the following features:
*   **Roles**: Single Master, Multi-Slave.
*   **Speeds**:
    *   Standard-mode (Sm): 100 kbit/s.
    *   Fast-mode (Fm): 400 kbit/s.
    *   Fast-mode Plus (Fm+): 1 Mbit/s.
*   **Addressing**: 7-bit and 10-bit addressing.
*   **Features**: Clock Stretching, Repeated Start, ACK/NACK handling.

### 1.2 Out of Scope (Future Work)
The following features are designed into the architecture for high availability but are **not** currently verified in the active test suite:
*   **Multi-Master Arbitration**: Logic for arbitration loss and back-off.
*   **High-Speed Mode (Hs-mode)**: 3.4 Mbit/s signaling and master code logic.
*   **Ultra Fast-mode (UFm)**: Unidirectional 5 Mbit/s.

---

## 2. Verification Strategy
Verification will be performed using a **UVM-based constrained random environment**.
*   **Stimulus**: UVM Sequences driving the Agent (acting as Master or Slave).
*   **Checking**: Protocol Monitor for bus compliance checks and Scoreboard for data integrity.
*   **Coverage**: 
    *   **Functional Coverage**: Explicit covergroups for protocol states, address ranges, and transaction types.
    *   **Code Coverage**: Line, Toggle, FSM, Condition, and Branch coverage enabled in simulation.

---

## 3. Test Cases

### 3.1 Basic Transport Tests (Sanity)
| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_001** | `sanity_wr_7bit` | Master writes 1 byte to a 7-bit Slave. Verify ACK and Stop. | **P0** | Basic Write, Addr Low Range |
| **TP_002** | `sanity_rd_7bit` | Master reads 1 byte from a 7-bit Slave. Verify ACK and Stop. | **P0** | Basic Read |
| **TP_003** | `sanity_wr_10bit` | Master writes 1 byte to a 10-bit Slave (2-byte address sequence). | **P1** | 10-bit Address |
| **TP_004** | `sanity_rd_10bit` | Master reads 1 byte from a 10-bit Slave (Write Address -> Sr -> Read). | **P1** | 10-bit Read path |

### 3.2 Transaction Types
| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_101** | `burst_write` | Master writes N bytes (random 2-128) in a single transaction. | **P1** | Burst Write, Size Bins |
| **TP_102** | `burst_read` | Master reads N bytes (random 2-128) in a single transaction. | **P1** | Burst Read |
| **TP_103** | `repeated_start` | Write transfer followed immediately by a Repeated Start (Sr) and another transfer. | **P1** | Repeated Start |
| **TP_104** | `mixed_transfers` | Random mix of Writes, Reads, and Repeated Starts without releasing the bus. | **P2** | Stress Test, Cross Coverage |

### 3.3 Protocol Features & Corner Cases
| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_201** | `clk_stretch_slave` | Slave holds SCL Low before ACK/Data. Master must wait indefinitely. | **P1** | Clock Synchronization |
| **TP_202** | `nack_addr` | Master addresses a non-existent Slave. Verify NACK on address byte and Stop generation. | **P1** | Address NACK, Status Bins |
| **TP_203** | `nack_data` | Slave NACKs a data byte (e.g., buffer full). Master must Abort or Stop. | **P2** | Data NACK flow |
| **TP_204** | `gen_call_req` | Master sends General Call address (`0000000`). Verify all capable slaves ACK. | **P2** | General Call Bin |
| **TP_205** | `zero_byte_seq` | Master sends Address + R/W bit, gets ACK, then immediately Stops. | **P3** | Empty Payload Bin |

### 3.4 Timing & Configuration
| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_301** | `speed_change` | Configure bus to Fm (400kHz) and Fm+ (1MHz). Verify timing parameters (tLOW, tHIGH). | **P2** | Speed Config Bins |
| **TP_302** | `min_timings` | Drive SCL/SDA with minimum allowed setup/hold times. Verify robustness. | **P3** | Timing Margin |

---

## 4. Coverage Model (Implemented)

The `i2c_coverage` class implements the following covergroups matching the specification:

### 4.1 `i2c_protocol_cg`
*   **Address 7-bit**: Bins for `0` (General Call), Low `[1:15]`, Mid `[16:111]`, High `[112:126]`, Max `127`.
*   **Direction**: `Write`, `Read`.
*   **Status**: `OK`, `ADDR_NACK`, `DATA_NACK`.
*   **Payload Size**: `1`, `Small Burst [2:8]`, `Large Burst [9:128]`.
*   **Repeated Start**: Toggle coverage for Stop vs Repeated Start.
*   **Cross Coverage**: 
    *   Direction x Status
    *   Direction x Size
    *   Direction x Repeated Start

### 4.2 `i2c_config_cg`
*   **Speed Modes**: `Standard`, `Fast`, `Fast+`.

---

## 5. Directory Structure Plan
```text
i2c_uvm/
├── docs/                 # Specifications and Testplans
├── rtl/                  # Dummy DUT for self-testing the VIP
├── scripts/              # Run scripts (Makefiles, Python)
└── src/                  # UVM Source Code
    ├── i2c_pkg.sv        # Top-level package
    ├── i2c_if.sv         # SystemVerilog Interface
    ├── common/           # Shared types and defines
    ├── agent/            # UVM Agent (Driver, Monitor, Sequencer)
    ├── env/              # UVM Environment and Scoreboard
    └── seq/              # Sequence Library
```
